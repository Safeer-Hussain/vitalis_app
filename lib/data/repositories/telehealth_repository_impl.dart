import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/repositories/telehealth_repository.dart';
import '../models/telehealth_appointment_model.dart';
import '../models/telehealth_doctor_model.dart';

class TelehealthRepositoryImpl implements TelehealthRepository {
  Future<Database> get _db => AppDatabase.instance;

  @override
  Future<List<TelehealthDoctorModel>> getDoctors() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'telehealth_doctors',
      orderBy: 'rating DESC, review_count DESC',
    );
    return maps.map((m) => TelehealthDoctorModel.fromMap(m)).toList();
  }

  @override
  Future<List<TelehealthAppointmentModel>> getAppointments() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'telehealth_appointments',
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((m) => TelehealthAppointmentModel.fromMap(m)).toList();
  }

  @override
  Future<void> bookAppointment(TelehealthAppointmentModel appointment) async {
    final db = await _db;
    await db.insert(
      'telehealth_appointments',
      appointment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    final db = await _db;
    await db.update(
      'telehealth_appointments',
      {'status': 'CANCELLED'},
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  @override
  Future<void> updateAppointment(TelehealthAppointmentModel appointment) async {
    final db = await _db;
    await db.update(
      'telehealth_appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }
}
