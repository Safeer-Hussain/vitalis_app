import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/platform/native_sensor_bridge.dart';
import '../../domain/repositories/vitals_repository.dart';
import '../models/medical_device_model.dart';
import '../models/vital_reading_model.dart';

class VitalsRepositoryImpl implements VitalsRepository {
  final NativeSensorBridge _bridge;

  VitalsRepositoryImpl(this._bridge);

  Future<Database> get _db => AppDatabase.instance;

  @override
  Future<List<VitalReadingModel>> getHistoricalVitals({int limit = 30}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'vitals',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => VitalReadingModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveVitalReading(VitalReadingModel reading) async {
    final db = await _db;
    await db.insert(
      'vitals',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<MedicalDeviceModel>> scanDevices() async {
    final list = await _bridge.scanClinicalSensors();
    return list.map((m) => MedicalDeviceModel.fromMap(m)).toList();
  }

  @override
  Future<bool> pairDevice(String sensorType) async {
    return await _bridge.pairMedicalDevice(sensorType);
  }

  @override
  Future<bool> disconnectDevice() async {
    return await _bridge.disconnectDevice();
  }

  @override
  Future<Map<String, dynamic>> calibrateDevice(String sensorType) async {
    return await _bridge.triggerCalibration(sensorType);
  }

  @override
  Stream<VitalReadingModel> get liveTelemetryStream {
    return _bridge.clinicalTelemetryStream.map(
      (packet) => VitalReadingModel.fromTelemetryPacket(packet),
    );
  }
}
