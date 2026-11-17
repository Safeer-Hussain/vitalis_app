import '../../core/fhir/fhir_r4_service.dart';
import '../../data/models/fhir_bundle_model.dart';

abstract class FhirRepository {
  Future<FhirBundleModel> exportPatientFhirBundle();
  Future<List<FhirResourceModel>> exportObservations();
  Future<List<FhirResourceModel>> exportDiagnosticReports();
  Future<List<FhirResourceModel>> exportMedicationStatements();
  FhirValidationReport validateBundle(FhirBundleModel bundle);
  bool verifyCryptographicSignature(FhirBundleModel bundle);
}
