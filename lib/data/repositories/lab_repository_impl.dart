import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/repositories/lab_repository.dart';
import '../models/biomarker_model.dart';
import '../models/lab_report_model.dart';

class LabRepositoryImpl implements LabRepository {
  Future<Database> get _db => AppDatabase.instance;

  @override
  Future<List<LabReportModel>> getLabReports() async {
    final db = await _db;
    final List<Map<String, dynamic>> reportMaps = await db.query(
      'lab_reports',
      orderBy: 'collection_date DESC',
    );

    final List<LabReportModel> reports = [];
    for (final rMap in reportMaps) {
      final reportId = rMap['id'] as String;
      final List<Map<String, dynamic>> bmMaps = await db.query(
        'biomarkers',
        where: 'report_id = ?',
        whereArgs: [reportId],
      );
      final biomarkers = bmMaps.map((b) => BiomarkerModel.fromMap(b)).toList();
      reports.add(LabReportModel.fromMap(rMap, biomarkers: biomarkers));
    }
    return reports;
  }

  @override
  Future<void> toggleBookmark(String reportId, bool isBookmarked) async {
    final db = await _db;
    await db.update(
      'lab_reports',
      {'is_bookmarked': isBookmarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  @override
  Future<void> saveLabReport(LabReportModel report) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        'lab_reports',
        report.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final bm in report.biomarkers) {
        await txn.insert(
          'biomarkers',
          bm.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
