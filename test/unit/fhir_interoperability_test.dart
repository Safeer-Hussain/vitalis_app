import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis_app/core/fhir/fhir_r4_service.dart';
import 'package:vitalis_app/data/models/biomarker_model.dart';
import 'package:vitalis_app/data/models/fhir_bundle_model.dart';
import 'package:vitalis_app/data/models/lab_report_model.dart';
import 'package:vitalis_app/data/models/prescription_model.dart';
import 'package:vitalis_app/data/models/vital_reading_model.dart';
import 'package:vitalis_app/presentation/fhir/fhir_notifier.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FhirR4Service fhirService;
  late FakeFhirRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fhirService = FhirR4Service();
    fakeRepo = FakeFhirRepository();
    registerTestDependencies(fhir: fakeRepo);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Sprint 24: HL7 FHIR R4 Clinical Interoperability Tests', () {
    test('createVitalObservation maps blood pressure to LOINC 85354-9 with components', () {
      final vital = VitalReadingModel(
        id: 'vital_bp_01',
        timestamp: DateTime.now(),
        sensorType: 'CARDIO_CUFF',
        systolic: 122,
        diastolic: 82,
        pulseRate: 74,
      );

      final obs = fhirService.createVitalObservation(vital);

      expect(obs.resourceType, 'Observation');
      expect(obs.id, 'obs-vital_bp_01');
      expect(obs.content['status'], 'final');

      final coding = (obs.content['code'] as Map)['coding'] as List;
      expect(coding.first['code'], '85354-9');
      expect(coding.first['system'], FhirR4Service.loincSystem);

      final components = (obs.content['component'] as List);
      expect(components.length, 3); // systolic, diastolic, pulse

      // Systolic component
      final sysComp = components[0] as Map;
      expect((sysComp['valueQuantity'] as Map)['value'], 122);
      expect((sysComp['valueQuantity'] as Map)['unit'], 'mmHg');

      // Diastolic component
      final diaComp = components[1] as Map;
      expect((diaComp['valueQuantity'] as Map)['value'], 82);
    });

    test('createDiagnosticReport maps laboratory panel with child biomarker Observations', () {
      final report = LabReportModel(
        id: 'lab_lipid_01',
        title: 'Lipid Standard Profile',
        panelCode: '24331-1',
        category: 'Lipids',
        collectionDate: DateTime.now(),
        orderingPhysician: 'Dr. Sarah Chen',
        status: 'FINAL',
        clinicalNotes: 'Normal lipid levels',
        isBookmarked: false,
        biomarkers: const [
          BiomarkerModel(
            id: 'bm_tc_01',
            reportId: 'lab_lipid_01',
            name: 'Total Cholesterol',
            code: '2093-3',
            value: 182.0,
            unit: 'mg/dL',
            minRange: 125.0,
            maxRange: 200.0,
            clinicalStatus: 'OPTIMAL',
          ),
          BiomarkerModel(
            id: 'bm_hdl_01',
            reportId: 'lab_lipid_01',
            name: 'HDL Cholesterol',
            code: '2085-9',
            value: 54.0,
            unit: 'mg/dL',
            minRange: 40.0,
            maxRange: 60.0,
            clinicalStatus: 'OPTIMAL',
          ),
        ],
      );

      final resources = fhirService.createDiagnosticReportWithObservations(
        report,
      );

      expect(resources.length, 3); // 1 DiagnosticReport + 2 Observations
      final diagReport = resources.first;
      expect(diagReport.resourceType, 'DiagnosticReport');
      expect(diagReport.content['status'], 'final');
      expect(
        ((diagReport.content['code'] as Map)['coding'] as List)[0]['code'],
        '24331-1',
      );

      final resultRefs = (diagReport.content['result'] as List);
      expect(resultRefs.length, 2);

      // Verify child analyte observation
      final analyteObs = resources[1];
      expect(analyteObs.resourceType, 'Observation');
      expect(
        ((analyteObs.content['code'] as Map)['coding'] as List)[0]['code'],
        '2093-3',
      );
      expect((analyteObs.content['valueQuantity'] as Map)['value'], 182.0);
    });

    test(
      'createMedicationStatement maps prescription with RxNorm ontology',
      () {
        const rx = PrescriptionModel(
          id: 'rx_metformin_01',
          medicationName: 'Metformin HCl',
          dosage: '500 mg Oral Tablet',
          instructions: 'Take 1 tablet with evening meal',
          frequency: 'Evening',
          pillsRemaining: 56,
          totalPills: 60,
          dosesTakenToday: 0,
          dailyTargetDoses: 1,
          prescribingDoctor: 'Dr. Elena Rostova',
          refillStatus: 'NORMAL',
        );

        final medStmt = fhirService.createMedicationStatement(rx);

        expect(medStmt.resourceType, 'MedicationStatement');
        expect(medStmt.content['status'], 'active');
        final coding =
            (medStmt.content['medicationCodeableConcept'] as Map)['coding']
                as List;
        expect(coding[0]['system'], FhirR4Service.rxNormSystem);
        expect(coding[0]['display'], 'Metformin HCl');
      },
    );

    test('Cryptographic SHA-256 seal generation and tamper detection', () {
      final bundle = fhirService.exportBundle(
        vitals: [
          VitalReadingModel(
            id: 'v_crypt_01',
            timestamp: DateTime.now(),
            sensorType: 'CARDIO_CUFF',
            systolic: 118,
            diastolic: 78,
          ),
        ],
        labs: [],
        prescriptions: [],
      );

      // Verify signature on authentic bundle
      expect(bundle.signature.sha256Hex, isNotEmpty);
      expect(bundle.signature.data, isNotEmpty);
      expect(fhirService.verifyBundleSignature(bundle), isTrue);

      // Validate schema
      final report = fhirService.validateBundle(bundle);
      expect(report.isValid, isTrue);
      expect(report.errors, isEmpty);
      expect(report.validatedResourceCount, 1);

      // Create a tampered bundle with altered blood pressure value
      final alteredEntries = List<FhirResourceModel>.from(bundle.entries);
      final alteredContent = Map<String, dynamic>.from(
        alteredEntries[0].content,
      );
      alteredContent['status'] = 'tampered_status';
      alteredEntries[0] = FhirResourceModel(
        fullUrl: alteredEntries[0].fullUrl,
        resourceType: alteredEntries[0].resourceType,
        id: alteredEntries[0].id,
        content: alteredContent,
      );

      final tamperedBundle = FhirBundleModel(
        id: bundle.id,
        timestamp: bundle.timestamp,
        signature: bundle.signature,
        entries: alteredEntries,
      );

      // Verification MUST fail on tampered payload
      expect(fhirService.verifyBundleSignature(tamperedBundle), isFalse);
      final tamperedReport = fhirService.validateBundle(tamperedBundle);
      expect(tamperedReport.isValid, isFalse);
      expect(
        tamperedReport.errors,
        contains(contains('Cryptographic SHA-256 seal mismatch')),
      );
    });

    test(
      'FhirNotifier builds bundle, filters resources and simulates EHR export',
      () async {
        container.read(fhirNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));
        final notifier = container.read(fhirNotifierProvider.notifier);

        final state = container.read(fhirNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.bundle, isNotNull);
        expect(state.isSignatureVerified, isTrue);
        expect(state.validationReport?.isValid, isTrue);

        // Test filtering
        expect(state.filteredEntries.length, state.bundle!.totalResources);

        notifier.filterByType('Observation');
        final obsFiltered = container
            .read(fhirNotifierProvider)
            .filteredEntries;
        expect(
          obsFiltered.every((e) => e.resourceType == 'Observation'),
          isTrue,
        );

        notifier.filterByType('DiagnosticReport');
        final diagFiltered = container
            .read(fhirNotifierProvider)
            .filteredEntries;
        expect(
          diagFiltered.every((e) => e.resourceType == 'DiagnosticReport'),
          isTrue,
        );

        notifier.filterByType('MedicationStatement');
        final medFiltered = container
            .read(fhirNotifierProvider)
            .filteredEntries;
        expect(
          medFiltered.every((e) => e.resourceType == 'MedicationStatement'),
          isTrue,
        );

        // Test EHR simulated dispatch
        await notifier.simulateEhrExport('Epic Systems MyChart');
        expect(
          container.read(fhirNotifierProvider).simulatedEhrDestination,
          'Epic Systems MyChart',
        );
      },
    );
  });
}
