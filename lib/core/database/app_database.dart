import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static const String _databaseName = 'vitalis_clinical_vault.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (kIsWeb) {
      dbPath = _databaseName;
    } else {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        dbPath = p.join(docsDir.path, _databaseName);
      } catch (_) {
        final dbDir = await getDatabasesPath();
        dbPath = p.join(dbDir, _databaseName);
      }
    }

    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vitals (
        id TEXT PRIMARY KEY,
        timestamp INTEGER NOT NULL,
        sensor_type TEXT NOT NULL,
        systolic INTEGER,
        diastolic INTEGER,
        mean_arterial_pressure REAL,
        pulse_rate INTEGER,
        glucose_mg_dl INTEGER,
        glucose_mmol_l REAL,
        trend_arrow TEXT,
        oxygen_saturation INTEGER,
        perfusion_index REAL,
        temperature_celsius REAL,
        temperature_fahrenheit REAL,
        irregular_heartbeat INTEGER DEFAULT 0,
        crc32_checksum TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE telehealth_doctors (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        subspecialty TEXT,
        hospital TEXT,
        rating REAL,
        review_count INTEGER,
        consultation_fee REAL,
        available_today INTEGER DEFAULT 1,
        avatar_path TEXT,
        bio TEXT,
        experience_years INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE telehealth_appointments (
        id TEXT PRIMARY KEY,
        doctor_id TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        scheduled_time INTEGER NOT NULL,
        consultation_mode TEXT NOT NULL,
        symptom_notes TEXT,
        status TEXT NOT NULL,
        live_vital_sharing INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE lab_reports (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        panel_code TEXT NOT NULL,
        category TEXT NOT NULL,
        collection_date INTEGER NOT NULL,
        ordering_physician TEXT,
        status TEXT NOT NULL,
        is_bookmarked INTEGER DEFAULT 0,
        clinical_notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE biomarkers (
        id TEXT PRIMARY KEY,
        report_id TEXT NOT NULL,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        min_range REAL NOT NULL,
        max_range REAL NOT NULL,
        clinical_status TEXT NOT NULL,
        historical_value REAL,
        interpretation TEXT,
        FOREIGN KEY (report_id) REFERENCES lab_reports (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE prescriptions (
        id TEXT PRIMARY KEY,
        medication_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        instructions TEXT,
        frequency TEXT NOT NULL,
        pills_remaining INTEGER NOT NULL,
        total_pills INTEGER NOT NULL,
        doses_taken_today INTEGER DEFAULT 0,
        daily_target_doses INTEGER DEFAULT 1,
        prescribing_doctor TEXT,
        refill_status TEXT DEFAULT 'NORMAL',
        last_taken_timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_triage_messages (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        clinical_summary TEXT
      )
    ''');
  }

  static Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
