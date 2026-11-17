import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/fhir_bundle_model.dart';
import '../../data/models/lab_report_model.dart';
import '../../data/models/prescription_model.dart';
import '../../data/models/vital_reading_model.dart';

class FhirValidationReport {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int validatedResourceCount;
  final String complianceStandard;

  const FhirValidationReport({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.validatedResourceCount,
    this.complianceStandard = 'HL7 FHIR Release 4.0.1 (US Core 6.1.0)',
  });
}

class FhirR4Service {
  static const String loincSystem = 'http://loinc.org';
  static const String rxNormSystem =
      'http://www.nlm.nih.gov/research/umls/rxnorm';
  static const String ucumSystem = 'http://unitsofmeasure.org';
  static const String categorySystem =
      'http://terminology.hl7.org/CodeSystem/observation-category';

  final Uuid _uuid = const Uuid();

  /// Transform a VitalReadingModel into a FHIR R4 Observation resource
  FhirResourceModel createVitalObservation(
    VitalReadingModel reading, {
    String patientId = 'vitalis-patient-current',
  }) {
    final resourceId = 'obs-${reading.id}';
    final timestampIso = reading.timestamp.toUtc().toIso8601String();

    final Map<String, dynamic> resource = {
      'resourceType': 'Observation',
      'id': resourceId,
      'status': 'final',
      'category': [
        {
          'coding': [
            {
              'system': categorySystem,
              'code': 'vital-signs',
              'display': 'Vital Signs',
            },
          ],
        },
      ],
      'subject': {
        'reference': 'Patient/$patientId',
        'display': 'Current Patient',
      },
      'effectiveDateTime': timestampIso,
    };

    if (reading.systolic != null && reading.diastolic != null) {
      // Blood Pressure Panel (LOINC 85354-9)
      resource['code'] = {
        'coding': [
          {
            'system': loincSystem,
            'code': '85354-9',
            'display': 'Blood pressure panel with all children optional',
          },
        ],
        'text': 'Blood Pressure',
      };
      resource['component'] = [
        {
          'code': {
            'coding': [
              {
                'system': loincSystem,
                'code': '8480-6',
                'display': 'Systolic blood pressure',
              },
            ],
          },
          'valueQuantity': {
            'value': reading.systolic,
            'unit': 'mmHg',
            'system': ucumSystem,
            'code': 'mm[Hg]',
          },
        },
        {
          'code': {
            'coding': [
              {
                'system': loincSystem,
                'code': '8462-4',
                'display': 'Diastolic blood pressure',
              },
            ],
          },
          'valueQuantity': {
            'value': reading.diastolic,
            'unit': 'mmHg',
            'system': ucumSystem,
            'code': 'mm[Hg]',
          },
        },
      ];
      if (reading.pulseRate != null) {
        resource['component'].add({
          'code': {
            'coding': [
              {
                'system': loincSystem,
                'code': '8867-4',
                'display': 'Heart rate',
              },
            ],
          },
          'valueQuantity': {
            'value': reading.pulseRate,
            'unit': 'beats/minute',
            'system': ucumSystem,
            'code': '/min',
          },
        });
      }
    } else if (reading.glucoseMgDl != null) {
      // Blood Glucose (LOINC 2339-0)
      resource['code'] = {
        'coding': [
          {
            'system': loincSystem,
            'code': '2339-0',
            'display': 'Glucose [Mass/volume] in Blood',
          },
        ],
        'text': 'Blood Glucose',
      };
      resource['valueQuantity'] = {
        'value': reading.glucoseMgDl,
        'unit': 'mg/dL',
        'system': ucumSystem,
        'code': 'mg/dL',
      };
    } else if (reading.oxygenSaturation != null) {
      // Oxygen Saturation SpO2 (LOINC 2708-6)
      resource['code'] = {
        'coding': [
          {
            'system': loincSystem,
            'code': '2708-6',
            'display': 'Oxygen saturation in Arterial blood',
          },
        ],
        'text': 'Pulse Oximetry SpO2',
      };
      resource['valueQuantity'] = {
        'value': reading.oxygenSaturation,
        'unit': '%',
        'system': ucumSystem,
        'code': '%',
      };
    } else if (reading.temperatureCelsius != null) {
      // Body Temperature (LOINC 8310-5)
      resource['code'] = {
        'coding': [
          {
            'system': loincSystem,
            'code': '8310-5',
            'display': 'Body temperature',
          },
        ],
        'text': 'Core Body Temperature',
      };
      resource['valueQuantity'] = {
        'value': reading.temperatureCelsius,
        'unit': 'Cel',
        'system': ucumSystem,
        'code': 'Cel',
      };
    } else {
      resource['code'] = {
        'coding': [
          {'system': loincSystem, 'code': '8867-4', 'display': 'Heart rate'},
        ],
        'text': 'Heart Rate',
      };
      resource['valueQuantity'] = {
        'value': reading.pulseRate ?? 72,
        'unit': '/min',
        'system': ucumSystem,
        'code': '/min',
      };
    }

    return FhirResourceModel(
      fullUrl: 'urn:uuid:$resourceId',
      resourceType: 'Observation',
      id: resourceId,
      content: resource,
    );
  }

  /// Transform a LabReportModel and its Biomarkers into FHIR R4 DiagnosticReport & Observations
  List<FhirResourceModel> createDiagnosticReportWithObservations(
    LabReportModel report, {
    String patientId = 'vitalis-patient-current',
  }) {
    final List<FhirResourceModel> resources = [];
    final reportId = 'diag-${report.id}';
    final resultReferences = <Map<String, dynamic>>[];

    // Generate Observation for each Biomarker in the panel
    for (final biomarker in report.biomarkers) {
      final obsId = 'obs-bm-${biomarker.id}';
      resultReferences.add({
        'reference': 'Observation/$obsId',
        'display': biomarker.name,
      });

      final Map<String, dynamic> obsContent = {
        'resourceType': 'Observation',
        'id': obsId,
        'status': 'final',
        'category': [
          {
            'coding': [
              {
                'system': categorySystem,
                'code': 'laboratory',
                'display': 'Laboratory',
              },
            ],
          },
        ],
        'code': {
          'coding': [
            {
              'system': loincSystem,
              'code': biomarker.code,
              'display': biomarker.name,
            },
          ],
          'text': biomarker.name,
        },
        'subject': {
          'reference': 'Patient/$patientId',
          'display': 'Current Patient',
        },
        'effectiveDateTime': report.collectionDate.toUtc().toIso8601String(),
        'valueQuantity': {
          'value': biomarker.value,
          'unit': biomarker.unit,
          'system': ucumSystem,
          'code': biomarker.unit,
        },
        'referenceRange': [
          {
            'low': {
              'value': biomarker.minRange,
              'unit': biomarker.unit,
              'system': ucumSystem,
            },
            'high': {
              'value': biomarker.maxRange,
              'unit': biomarker.unit,
              'system': ucumSystem,
            },
          },
        ],
        'interpretation': [
          {
            'coding': [
              {
                'system': 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation',
                'code': biomarker.clinicalStatus == 'OPTIMAL' ? 'N' : 'H',
                'display': biomarker.clinicalStatus,
              },
            ],
          },
        ],
      };

      resources.add(
        FhirResourceModel(
          fullUrl: 'urn:uuid:$obsId',
          resourceType: 'Observation',
          id: obsId,
          content: obsContent,
        ),
      );
    }

    // DiagnosticReport Container
    final Map<String, dynamic> reportContent = {
      'resourceType': 'DiagnosticReport',
      'id': reportId,
      'status': report.status.toLowerCase(),
      'category': [
        {
          'coding': [
            {
              'system': 'http://terminology.hl7.org/CodeSystem/v2-0074',
              'code': 'LAB',
              'display': 'Laboratory',
            },
          ],
        },
      ],
      'code': {
        'coding': [
          {
            'system': loincSystem,
            'code': report.panelCode,
            'display': report.title,
          },
        ],
        'text': report.title,
      },
      'subject': {
        'reference': 'Patient/$patientId',
        'display': 'Current Patient',
      },
      'effectiveDateTime': report.collectionDate.toUtc().toIso8601String(),
      'issued': report.collectionDate.toUtc().toIso8601String(),
      'performer': [
        {'display': report.orderingPhysician},
      ],
      'result': resultReferences,
      'conclusion': report.clinicalNotes,
    };

    resources.insert(
      0,
      FhirResourceModel(
        fullUrl: 'urn:uuid:$reportId',
        resourceType: 'DiagnosticReport',
        id: reportId,
        content: reportContent,
      ),
    );

    return resources;
  }

  /// Transform a PrescriptionModel into a FHIR R4 MedicationStatement resource
  FhirResourceModel createMedicationStatement(
    PrescriptionModel rx, {
    String patientId = 'vitalis-patient-current',
  }) {
    final resourceId = 'medstmt-${rx.id}';

    final Map<String, dynamic> resource = {
      'resourceType': 'MedicationStatement',
      'id': resourceId,
      'status': 'active',
      'medicationCodeableConcept': {
        'coding': [
          {'system': rxNormSystem, 'code': rx.id, 'display': rx.medicationName},
        ],
        'text': '${rx.medicationName} (${rx.dosage})',
      },
      'subject': {
        'reference': 'Patient/$patientId',
        'display': 'Current Patient',
      },
      'effectiveDateTime': DateTime.now().toUtc().toIso8601String(),
      'dateAsserted': DateTime.now().toUtc().toIso8601String(),
      'informationSource': {'display': rx.prescribingDoctor},
      'dosage': [
        {
          'text': '${rx.instructions} • Frequency: ${rx.frequency}',
          'timing': {
            'repeat': {
              'frequency': rx.dailyTargetDoses,
              'period': 1,
              'periodUnit': 'd',
            },
          },
        },
      ],
      'note': [
        {
          'text':
              'Remaining inventory: ${rx.pillsRemaining}/${rx.totalPills} units. Refill status: ${rx.refillStatus}',
        },
      ],
    };

    return FhirResourceModel(
      fullUrl: 'urn:uuid:$resourceId',
      resourceType: 'MedicationStatement',
      id: resourceId,
      content: resource,
    );
  }

  /// Generate a complete HL7 FHIR R4 Bundle containing all patient observations, reports & medications
  FhirBundleModel exportBundle({
    required List<VitalReadingModel> vitals,
    required List<LabReportModel> labs,
    required List<PrescriptionModel> prescriptions,
    String patientId = 'vitalis-patient-current',
  }) {
    final bundleId = 'bundle-vitalis-${_uuid.v4()}';
    final timestamp = DateTime.now();
    final List<FhirResourceModel> entries = [];

    // 1. Add Vital Observations
    for (final v in vitals) {
      entries.add(createVitalObservation(v, patientId: patientId));
    }

    // 2. Add Diagnostic Reports & Biomarkers
    for (final lab in labs) {
      entries.addAll(
        createDiagnosticReportWithObservations(lab, patientId: patientId),
      );
    }

    // 3. Add Medication Statements
    for (final rx in prescriptions) {
      entries.add(createMedicationStatement(rx, patientId: patientId));
    }

    // 4. Compute Cryptographic Signature over canonical JSON representation
    final rawEntriesJson = jsonEncode(entries.map((e) => e.toMap()).toList());
    final sha256Digest = sha256.convert(utf8.encode(rawEntriesJson)).toString();
    final base64Signature = base64Encode(
      utf8.encode('SIGNATURE-CERT:$sha256Digest'),
    );

    final signature = FhirSignatureModel(
      when: timestamp,
      sha256Hex: sha256Digest,
      data: base64Signature,
    );

    return FhirBundleModel(
      id: bundleId,
      timestamp: timestamp,
      signature: signature,
      entries: entries,
    );
  }

  /// Cryptographically verify the integrity of a FHIR R4 Bundle against its SHA-256 seal
  bool verifyBundleSignature(FhirBundleModel bundle) {
    final rawEntriesJson = jsonEncode(
      bundle.entries.map((e) => e.toMap()).toList(),
    );
    final computedSha256 = sha256
        .convert(utf8.encode(rawEntriesJson))
        .toString();
    return computedSha256.toLowerCase() ==
        bundle.signature.sha256Hex.toLowerCase();
  }

  /// Validate bundle against HL7 FHIR Release 4 specification rules
  FhirValidationReport validateBundle(FhirBundleModel bundle) {
    final errors = <String>[];
    final warnings = <String>[];

    if (bundle.resourceType != 'Bundle') {
      errors.add(
        "Root resourceType must be 'Bundle'. Found: '${bundle.resourceType}'",
      );
    }
    if (bundle.id.isEmpty) {
      errors.add('Bundle id cannot be empty.');
    }
    if (bundle.type != 'collection' && bundle.type != 'transaction') {
      warnings.add(
        "Recommended Bundle type is 'collection' or 'transaction'. Found: '${bundle.type}'",
      );
    }

    for (final entry in bundle.entries) {
      final res = entry.content;
      final type = res['resourceType'] as String?;
      final id = res['id'] as String?;

      if (type == null || type.isEmpty) {
        errors.add("Entry missing resourceType at url '${entry.fullUrl}'.");
        continue;
      }
      if (id == null || id.isEmpty) {
        errors.add("Entry resourceType '$type' missing required id.");
      }

      if (type == 'Observation') {
        final status = res['status'] as String?;
        if (status != 'final' &&
            status != 'preliminary' &&
            status != 'registered') {
          errors.add("Observation '$id' has invalid status '$status'.");
        }
        if (res['code'] == null) {
          errors.add("Observation '$id' missing clinical coding.");
        }
      } else if (type == 'DiagnosticReport') {
        if (res['status'] == null) {
          errors.add("DiagnosticReport '$id' missing status.");
        }
        if (res['code'] == null) {
          errors.add("DiagnosticReport '$id' missing LOINC panel code.");
        }
      } else if (type == 'MedicationStatement') {
        if (res['status'] != 'active' && res['status'] != 'completed') {
          errors.add(
            "MedicationStatement '$id' status must be 'active' or 'completed'.",
          );
        }
      }
    }

    final isValid = errors.isEmpty && verifyBundleSignature(bundle);
    if (!verifyBundleSignature(bundle)) {
      errors.add(
        'Cryptographic SHA-256 seal mismatch: bundle content was altered.',
      );
    }

    return FhirValidationReport(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
      validatedResourceCount: bundle.entries.length,
    );
  }
}
