import '../../data/models/medical_device_model.dart';
import '../../data/models/vital_reading_model.dart';

abstract class VitalsRepository {
  Future<List<VitalReadingModel>> getHistoricalVitals({int limit = 30});
  Future<void> saveVitalReading(VitalReadingModel reading);
  Future<List<MedicalDeviceModel>> scanDevices();
  Future<List<MedicalDeviceModel>> scanGattPeripherals({
    List<String>? serviceUuids,
  });
  Future<bool> pairDevice(String sensorType);
  Future<bool> disconnectDevice();
  Future<Map<String, dynamic>> calibrateDevice(String sensorType);
  Future<bool> setAutoReconnect({required bool enabled});
  Future<bool> setBackgroundTelemetry({required bool enabled});
  Future<Map<String, dynamic>> getConnectionState();
  Future<void> simulateConnectionDrop();
  Stream<VitalReadingModel> get liveTelemetryStream;
  Stream<String> get connectionStatusStream;
}
