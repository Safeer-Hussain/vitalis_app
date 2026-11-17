import '../../core/fhir/fhir_r4_service.dart';
import '../../domain/repositories/fhir_repository.dart';
import '../../domain/repositories/lab_repository.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../../domain/repositories/vitals_repository.dart';
import '../models/fhir_bundle_model.dart';

class FhirRepositoryImpl implements FhirRepository {
  final VitalsRepository _vitalsRepository;
  final LabRepository _labRepository;
  final PrescriptionRepository _prescriptionRepository;
  final FhirR4Service _fhirService;

  FhirRepositoryImpl(
    this._vitalsRepository,
    this._labRepository,
    this._prescriptionRepository,
    this._fhirService,
  );

  @override
  Future<FhirBundleModel> exportPatientFhirBundle() async {
    final vitals = await _vitalsRepository.getHistoricalVitals(limit: 20);
    final labs = await _labRepository.getLabReports();
    final prescriptions = await _prescriptionRepository.getPrescriptions();

    return _fhirService.exportBundle(
      vitals: vitals,
      labs: labs,
      prescriptions: prescriptions,
    );
  }

  @override
  Future<List<FhirResourceModel>> exportObservations() async {
    final vitals = await _vitalsRepository.getHistoricalVitals(limit: 20);
    return vitals.map((v) => _fhirService.createVitalObservation(v)).toList();
  }

  @override
  Future<List<FhirResourceModel>> exportDiagnosticReports() async {
    final labs = await _labRepository.getLabReports();
    final List<FhirResourceModel> reports = [];
    for (final lab in labs) {
      reports.addAll(_fhirService.createDiagnosticReportWithObservations(lab));
    }
    return reports;
  }

  @override
  Future<List<FhirResourceModel>> exportMedicationStatements() async {
    final prescriptions = await _prescriptionRepository.getPrescriptions();
    return prescriptions
        .map((p) => _fhirService.createMedicationStatement(p))
        .toList();
  }

  @override
  FhirValidationReport validateBundle(FhirBundleModel bundle) {
    return _fhirService.validateBundle(bundle);
  }

  @override
  bool verifyCryptographicSignature(FhirBundleModel bundle) {
    return _fhirService.verifyBundleSignature(bundle);
  }
}
