import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../models/prescription_model.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  Future<Database> get _db => AppDatabase.instance;

  @override
  Future<List<PrescriptionModel>> getPrescriptions() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'prescriptions',
      orderBy: 'medication_name ASC',
    );
    return maps.map((m) => PrescriptionModel.fromMap(m)).toList();
  }

  @override
  Future<void> savePrescription(PrescriptionModel prescription) async {
    final db = await _db;
    await db.insert(
      'prescriptions',
      prescription.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> recordDoseTaken(String prescriptionId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'prescriptions',
      where: 'id = ?',
      whereArgs: [prescriptionId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final current = PrescriptionModel.fromMap(maps.first);
      final newDoses = current.dosesTakenToday + 1;
      final newPills = (current.pillsRemaining - 1).clamp(0, 999);
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.update(
        'prescriptions',
        {
          'doses_taken_today': newDoses,
          'pills_remaining': newPills,
          'last_taken_timestamp': now,
        },
        where: 'id = ?',
        whereArgs: [prescriptionId],
      );
    }
  }

  @override
  Future<void> requestRefill(String prescriptionId) async {
    final db = await _db;
    await db.update(
      'prescriptions',
      {'refill_status': 'REFILL_REQUESTED'},
      where: 'id = ?',
      whereArgs: [prescriptionId],
    );
  }
}
