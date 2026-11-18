import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalis_app/core/di/injection_container.dart';
import 'package:vitalis_app/core/fhir/fhir_r4_service.dart';
import 'package:vitalis_app/core/slm/clinical_safety_classifier.dart';
import 'package:vitalis_app/core/slm/gemma_clinical_slm_engine.dart';
import 'package:vitalis_app/data/models/ai_triage_model.dart';
import 'package:vitalis_app/data/models/biomarker_model.dart';
import 'package:vitalis_app/data/models/fhir_bundle_model.dart';
import 'package:vitalis_app/data/models/lab_report_model.dart';
import 'package:vitalis_app/data/models/medical_device_model.dart';
import 'package:vitalis_app/data/models/prescription_model.dart';
import 'package:vitalis_app/data/models/telehealth_appointment_model.dart';
import 'package:vitalis_app/data/models/telehealth_doctor_model.dart';
import 'package:vitalis_app/data/models/vital_reading_model.dart';
import 'package:vitalis_app/domain/repositories/ai_triage_repository.dart';
import 'package:vitalis_app/domain/repositories/fhir_repository.dart';
import 'package:vitalis_app/domain/repositories/lab_repository.dart';
import 'package:vitalis_app/domain/repositories/prescription_repository.dart';
import 'package:vitalis_app/domain/repositories/telehealth_repository.dart';
import 'package:vitalis_app/domain/repositories/vitals_repository.dart';

class FakeVitalsRepository implements VitalsRepository {
  final List<VitalReadingModel> vitals = [];
  final StreamController<VitalReadingModel> _controller =
      StreamController<VitalReadingModel>.broadcast();

  @override
  Future<List<VitalReadingModel>> getHistoricalVitals({int limit = 30}) async {
    return List.from(vitals.take(limit));
  }

  @override
  Future<void> saveVitalReading(VitalReadingModel reading) async {
    vitals.insert(0, reading);
  }

  @override
  Future<List<MedicalDeviceModel>> scanDevices() async {
    return [
      const MedicalDeviceModel(
        id: 'DEV-CC-9041',
        name: 'CardioCuff Pro',
        model: 'CC-PRO-V2',
        type: 'CARDIO_CUFF',
        batteryLevel: 88,
        rssi: -54,
        connected: true,
      ),
      const MedicalDeviceModel(
        id: 'DEV-GS-2018',
        name: 'GlucoSense CGM',
        model: 'GS-CGM-4X',
        type: 'GLUCO_SENSE',
        batteryLevel: 94,
        rssi: -48,
        connected: false,
      ),
    ];
  }

  @override
  Future<List<MedicalDeviceModel>> scanGattPeripherals({
    List<String>? serviceUuids,
  }) async {
    final activeFilters = (serviceUuids ?? ['0x180D', '0x1810', '0x1808'])
        .map((s) => s.toUpperCase())
        .toSet();

    final allGatt = [
      const MedicalDeviceModel(
        id: 'GATT-CC-8821',
        name: 'CardioCuff Pro BLE-GATT',
        model: 'CC-PRO-GATT-V3',
        type: 'CARDIO_CUFF',
        batteryLevel: 92,
        rssi: -52,
        connected: true,
        macAddress: 'C4:D3:58:AA:11:42',
        serviceUuids: ['0x1810', '0x180D'],
        isGattDevice: true,
        connectionStatus: 'CONNECTED',
      ),
      const MedicalDeviceModel(
        id: 'GATT-GS-4190',
        name: 'GlucoSense CGM Direct',
        model: 'GS-CGM-DIRECT-X',
        type: 'GLUCO_SENSE',
        batteryLevel: 96,
        rssi: -46,
        connected: false,
        macAddress: 'E1:8B:22:90:3F:8A',
        serviceUuids: ['0x1808'],
        isGattDevice: true,
        connectionStatus: 'DISCONNECTED',
      ),
      const MedicalDeviceModel(
        id: 'GATT-OP-7734',
        name: 'OxyPulse Clinical Wireless',
        model: 'OP-CLIN-GATT-2',
        type: 'OXY_PULSE',
        batteryLevel: 81,
        rssi: -59,
        connected: false,
        macAddress: 'F0:24:6D:77:C8:19',
        serviceUuids: ['0x180D'],
        isGattDevice: true,
        connectionStatus: 'DISCONNECTED',
      ),
    ];

    return allGatt.where((device) {
      final u = device.serviceUuids.map((s) => s.toUpperCase()).toSet();
      return u.intersection(activeFilters).isNotEmpty;
    }).toList();
  }

  bool autoReconnectActive = true;
  bool backgroundTelemetryActive = false;
  String currentStatus = 'CONNECTED';
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  @override
  Future<bool> setAutoReconnect({required bool enabled}) async {
    autoReconnectActive = enabled;
    return true;
  }

  @override
  Future<bool> setBackgroundTelemetry({required bool enabled}) async {
    backgroundTelemetryActive = enabled;
    return true;
  }

  @override
  Future<Map<String, dynamic>> getConnectionState() async {
    return {
      'connectionStatus': currentStatus,
      'autoReconnectEnabled': autoReconnectActive,
      'backgroundTelemetryEnabled': backgroundTelemetryActive,
      'reconnectAttempt': 0,
      'maxReconnectAttempts': 5,
      'currentBackoffMs': 1000,
    };
  }

  @override
  Future<void> simulateConnectionDrop() async {
    currentStatus = 'RECONNECTING';
    _statusController.add('RECONNECTING');
    await Future.delayed(const Duration(milliseconds: 50));
    currentStatus = 'CONNECTED';
    _statusController.add('CONNECTED');
  }

  @override
  Stream<String> get connectionStatusStream => _statusController.stream;

  @override
  Future<bool> pairDevice(String sensorType) async => true;

  @override
  Future<bool> disconnectDevice() async => true;

  @override
  Future<Map<String, dynamic>> calibrateDevice(String sensorType) async {
    return {
      'status': 'CALIBRATED',
      'sensorType': sensorType,
      'zeroOffset': 0.12,
    };
  }

  @override
  Stream<VitalReadingModel> get liveTelemetryStream => _controller.stream;

  void emitTelemetry(VitalReadingModel reading) {
    _controller.add(reading);
  }
}

class FakeTelehealthRepository implements TelehealthRepository {
  final List<TelehealthDoctorModel> doctors = [
    const TelehealthDoctorModel(
      id: 'doc_01',
      name: 'Dr. Sarah Chen, MD, FACC',
      specialty: 'Cardiology',
      rating: 4.96,
      reviewCount: 342,
      consultationFee: 180.0,
      availableToday: true,
      avatarPath: 'assets/images/doctors/dr_sarah_chen.png',
      bio: 'Board-certified cardiologist',
      experienceYears: 14,
    ),
  ];

  final List<TelehealthAppointmentModel> appointments = [];

  @override
  Future<List<TelehealthDoctorModel>> getDoctors() async => List.from(doctors);

  @override
  Future<List<TelehealthAppointmentModel>> getAppointments() async =>
      List.from(appointments);

  @override
  Future<void> bookAppointment(TelehealthAppointmentModel appointment) async {
    appointments.add(appointment);
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    final idx = appointments.indexWhere((a) => a.id == appointmentId);
    if (idx != -1) {
      appointments[idx] = appointments[idx].copyWith(status: 'CANCELLED');
    }
  }

  @override
  Future<void> updateAppointment(TelehealthAppointmentModel appointment) async {
    final idx = appointments.indexWhere((a) => a.id == appointment.id);
    if (idx != -1) {
      appointments[idx] = appointment;
    }
  }
}

class FakeLabRepository implements LabRepository {
  final List<LabReportModel> reports = [
    LabReportModel(
      id: 'lab_cbc_01',
      title: 'Complete Blood Count (CBC)',
      panelCode: 'CBC-DIFF-W8',
      category: 'Hematology',
      collectionDate: DateTime.now(),
      orderingPhysician: 'Dr. Elena Rostova',
      status: 'FINAL',
      isBookmarked: false,
      clinicalNotes: 'Normal range',
      biomarkers: const [
        BiomarkerModel(
          id: 'bm_01',
          reportId: 'lab_cbc_01',
          name: 'White Blood Cells',
          code: 'WBC',
          value: 6.8,
          unit: 'x10^3/uL',
          minRange: 4.5,
          maxRange: 11.0,
          clinicalStatus: 'OPTIMAL',
        ),
      ],
    ),
  ];

  @override
  Future<List<LabReportModel>> getLabReports() async => List.from(reports);

  @override
  Future<void> toggleBookmark(String reportId, bool isBookmarked) async {
    final idx = reports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      reports[idx] = reports[idx].copyWith(isBookmarked: isBookmarked);
    }
  }

  @override
  Future<void> saveLabReport(LabReportModel report) async {
    reports.add(report);
  }
}

class FakePrescriptionRepository implements PrescriptionRepository {
  final List<PrescriptionModel> prescriptions = [
    const PrescriptionModel(
      id: 'rx_01',
      medicationName: 'Lisinopril',
      dosage: '10 mg Oral Tablet',
      instructions: 'Take 1 tablet every morning',
      frequency: 'Morning',
      pillsRemaining: 24,
      totalPills: 30,
      dosesTakenToday: 0,
      dailyTargetDoses: 1,
      prescribingDoctor: 'Dr. Sarah Chen, MD',
      refillStatus: 'NORMAL',
    ),
  ];

  @override
  Future<List<PrescriptionModel>> getPrescriptions() async =>
      List.from(prescriptions);

  @override
  Future<void> savePrescription(PrescriptionModel prescription) async {
    prescriptions.add(prescription);
  }

  @override
  Future<void> recordDoseTaken(String prescriptionId) async {
    final idx = prescriptions.indexWhere((p) => p.id == prescriptionId);
    if (idx != -1) {
      final cur = prescriptions[idx];
      prescriptions[idx] = cur.copyWith(
        dosesTakenToday: cur.dosesTakenToday + 1,
        pillsRemaining: (cur.pillsRemaining - 1).clamp(0, 999),
      );
    }
  }

  @override
  Future<void> requestRefill(String prescriptionId) async {
    final idx = prescriptions.indexWhere((p) => p.id == prescriptionId);
    if (idx != -1) {
      prescriptions[idx] = prescriptions[idx].copyWith(
        refillStatus: 'REFILL_REQUESTED',
      );
    }
  }
}

class FakeAiTriageRepository implements AiTriageRepository {
  final List<AiTriageMessageModel> history = [];
  GemmaSlmMetrics _metrics = const GemmaSlmMetrics();
  final ClinicalSafetyClassifier _classifier = ClinicalSafetyClassifier();

  @override
  Future<List<AiTriageMessageModel>> getChatHistory() async =>
      List.from(history);

  @override
  Future<void> saveMessage(AiTriageMessageModel message) async {
    history.add(message);
  }

  @override
  Future<void> clearHistory() async {
    history.clear();
  }

  @override
  GemmaSlmMetrics getSlmMetrics() => _metrics;

  @override
  Future<void> setSlmExecutionDelegate(String delegate) async {
    _metrics = _metrics.copyWith(activeDelegate: delegate);
  }

  @override
  ClinicalSafetyResult evaluateInputSafety(String prompt) {
    return _classifier.evaluateInput(prompt);
  }

  @override
  Stream<String> generateClinicalTriageResponse({
    required String userPrompt,
    required List<VitalReadingModel> recentVitals,
    required List<LabReportModel> labReports,
    required List<PrescriptionModel> prescriptions,
  }) async* {
    yield 'Clinical ';
    yield 'triage ';
    yield 'assessment.';
  }
}

class FakeFhirRepository implements FhirRepository {
  final FhirR4Service _service = FhirR4Service();

  @override
  Future<FhirBundleModel> exportPatientFhirBundle() async {
    return _service.exportBundle(
      vitals: [
        VitalReadingModel(
          id: 'v_test_01',
          timestamp: DateTime.now(),
          sensorType: 'CARDIO_CUFF',
          systolic: 120,
          diastolic: 80,
          pulseRate: 72,
        ),
      ],
      labs: [
        LabReportModel(
          id: 'l_test_01',
          title: 'Complete Blood Count',
          panelCode: '58410-2',
          category: 'Hematology',
          collectionDate: DateTime.now(),
          orderingPhysician: 'Dr. Sarah Chen',
          status: 'FINAL',
          clinicalNotes: 'Normal CBC range',
          isBookmarked: false,
          biomarkers: const [
            BiomarkerModel(
              id: 'bm_01',
              reportId: 'l_test_01',
              name: 'WBC',
              code: '6690-2',
              value: 6.5,
              unit: '10*3/uL',
              minRange: 4.5,
              maxRange: 11.0,
              clinicalStatus: 'OPTIMAL',
            ),
          ],
        ),
      ],
      prescriptions: [
        const PrescriptionModel(
          id: 'rx_test_01',
          medicationName: 'Lisinopril',
          dosage: '10mg',
          instructions: 'Take 1 daily',
          frequency: 'Morning',
          pillsRemaining: 28,
          totalPills: 30,
          dosesTakenToday: 1,
          dailyTargetDoses: 1,
          prescribingDoctor: 'Dr. Chen',
          refillStatus: 'NORMAL',
        ),
      ],
    );
  }

  @override
  Future<List<FhirResourceModel>> exportObservations() async {
    final bundle = await exportPatientFhirBundle();
    return bundle.entries
        .where((e) => e.resourceType == 'Observation')
        .toList();
  }

  @override
  Future<List<FhirResourceModel>> exportDiagnosticReports() async {
    final bundle = await exportPatientFhirBundle();
    return bundle.entries
        .where((e) => e.resourceType == 'DiagnosticReport')
        .toList();
  }

  @override
  Future<List<FhirResourceModel>> exportMedicationStatements() async {
    final bundle = await exportPatientFhirBundle();
    return bundle.entries
        .where((e) => e.resourceType == 'MedicationStatement')
        .toList();
  }

  @override
  FhirValidationReport validateBundle(FhirBundleModel bundle) {
    return _service.validateBundle(bundle);
  }

  @override
  bool verifyCryptographicSignature(FhirBundleModel bundle) {
    return _service.verifyBundleSignature(bundle);
  }
}

void registerTestDependencies({
  FakeVitalsRepository? vitals,
  FakeTelehealthRepository? telehealth,
  FakeLabRepository? labs,
  FakePrescriptionRepository? prescriptions,
  FakeAiTriageRepository? triage,
  FakeFhirRepository? fhir,
}) {
  SharedPreferences.setMockInitialValues({});
  if (sl.isRegistered<VitalsRepository>()) {
    sl.unregister<VitalsRepository>();
  }
  if (sl.isRegistered<TelehealthRepository>()) {
    sl.unregister<TelehealthRepository>();
  }
  if (sl.isRegistered<LabRepository>()) {
    sl.unregister<LabRepository>();
  }
  if (sl.isRegistered<PrescriptionRepository>()) {
    sl.unregister<PrescriptionRepository>();
  }
  if (sl.isRegistered<AiTriageRepository>()) {
    sl.unregister<AiTriageRepository>();
  }
  if (sl.isRegistered<FhirRepository>()) {
    sl.unregister<FhirRepository>();
  }

  sl.registerSingleton<VitalsRepository>(vitals ?? FakeVitalsRepository());
  sl.registerSingleton<TelehealthRepository>(
    telehealth ?? FakeTelehealthRepository(),
  );
  sl.registerSingleton<LabRepository>(labs ?? FakeLabRepository());
  sl.registerSingleton<PrescriptionRepository>(
    prescriptions ?? FakePrescriptionRepository(),
  );
  sl.registerSingleton<AiTriageRepository>(triage ?? FakeAiTriageRepository());
  sl.registerSingleton<FhirRepository>(fhir ?? FakeFhirRepository());
}
