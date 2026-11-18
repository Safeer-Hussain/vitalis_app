import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/slm/clinical_safety_classifier.dart';
import '../../core/slm/gemma_clinical_slm_engine.dart';
import '../../domain/repositories/ai_triage_repository.dart';
import '../models/ai_triage_model.dart';
import '../models/lab_report_model.dart';
import '../models/prescription_model.dart';
import '../models/vital_reading_model.dart';

class AiTriageRepositoryImpl implements AiTriageRepository {
  final GemmaClinicalSlmEngine _slmEngine;

  AiTriageRepositoryImpl([GemmaClinicalSlmEngine? slmEngine])
    : _slmEngine = slmEngine ?? GemmaClinicalSlmEngine();

  Future<Database> get _db => AppDatabase.instance;

  @override
  Future<List<AiTriageMessageModel>> getChatHistory() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_triage_messages',
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => AiTriageMessageModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveMessage(AiTriageMessageModel message) async {
    final db = await _db;
    await db.insert(
      'ai_triage_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearHistory() async {
    final db = await _db;
    await db.delete('ai_triage_messages');
  }

  @override
  Stream<String> generateClinicalTriageResponse({
    required String userPrompt,
    required List<VitalReadingModel> recentVitals,
    required List<LabReportModel> labReports,
    required List<PrescriptionModel> prescriptions,
  }) {
    return _slmEngine.generateClinicalInference(
      userPrompt: userPrompt,
      recentVitals: recentVitals,
      labReports: labReports,
      prescriptions: prescriptions,
    );
  }

  @override
  GemmaSlmMetrics getSlmMetrics() => _slmEngine.metrics;

  @override
  Future<void> setSlmExecutionDelegate(String delegate) async {
    await _slmEngine.setExecutionDelegate(delegate);
  }

  @override
  ClinicalSafetyResult evaluateInputSafety(String prompt) {
    return _slmEngine.evaluateSafety(prompt);
  }
}
