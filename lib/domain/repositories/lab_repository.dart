import '../../data/models/lab_report_model.dart';

abstract class LabRepository {
  Future<List<LabReportModel>> getLabReports();
  Future<void> toggleBookmark(String reportId, bool isBookmarked);
  Future<void> saveLabReport(LabReportModel report);
}
