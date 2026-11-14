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
  Future<void> clearHistory();
}
