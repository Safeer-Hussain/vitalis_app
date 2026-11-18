import '../../core/slm/clinical_safety_classifier.dart';
import '../../core/slm/gemma_clinical_slm_engine.dart';
import '../../data/models/ai_triage_model.dart';
import '../../data/models/lab_report_model.dart';
import '../../data/models/prescription_model.dart';
import '../../data/models/vital_reading_model.dart';

abstract class AiTriageRepository {
  Future<List<AiTriageMessageModel>> getChatHistory();
  Future<void> saveMessage(AiTriageMessageModel message);
  Stream<String> generateClinicalTriageResponse({
    required String userPrompt,
    required List<VitalReadingModel> recentVitals,
    required List<LabReportModel> labReports,
    required List<PrescriptionModel> prescriptions,
  });
  GemmaSlmMetrics getSlmMetrics();
  Future<void> setSlmExecutionDelegate(String delegate);
  ClinicalSafetyResult evaluateInputSafety(String prompt);
  Future<void> clearHistory();
}
