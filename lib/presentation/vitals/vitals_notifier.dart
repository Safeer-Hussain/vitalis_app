import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/injection_container.dart';
import '../../core/platform/native_sensor_bridge.dart';
import '../../data/models/medical_device_model.dart';
import '../../data/models/vital_reading_model.dart';
import '../../domain/repositories/vitals_repository.dart';

class VitalsState {
  final bool isLoading;
  final List<MedicalDeviceModel> devices;
  final List<MedicalDeviceModel> gattPeripherals;
  final bool isScanningGatt;
  final List<String> activeGattUuidFilters;
  final String selectedSensorType; // 'CARDIO_CUFF', 'GLUCO_SENSE', 'OXY_PULSE'
  final VitalReadingModel? currentTelemetry;
  final List<VitalReadingModel> historicalVitals;
  final bool simulatedAbnormalInjected;
  final bool autoReconnectEnabled;
  final bool backgroundTelemetryEnabled;
  final String connectionStatus; // 'CONNECTED', 'RECONNECTING', 'DISCONNECTED'
  final int reconnectAttempts;
  final int currentBackoffMs;
  final String? errorMessage;

  const VitalsState({
    this.isLoading = false,
    this.devices = const [],
    this.gattPeripherals = const [],
    this.isScanningGatt = false,
    this.activeGattUuidFilters = const [
      NativeSensorBridge.uuidHeartRate,
      NativeSensorBridge.uuidBloodPressure,
      NativeSensorBridge.uuidGlucose,
    ],
    this.selectedSensorType = 'CARDIO_CUFF',
    this.currentTelemetry,
    this.historicalVitals = const [],
    this.simulatedAbnormalInjected = false,
    this.autoReconnectEnabled = true,
    this.backgroundTelemetryEnabled = false,
    this.connectionStatus = 'CONNECTED',
    this.reconnectAttempts = 0,
    this.currentBackoffMs = 1000,
    this.errorMessage,
  });

  VitalsState copyWith({
    bool? isLoading,
    List<MedicalDeviceModel>? devices,
    List<MedicalDeviceModel>? gattPeripherals,
    bool? isScanningGatt,
    List<String>? activeGattUuidFilters,
    String? selectedSensorType,
    VitalReadingModel? currentTelemetry,
    List<VitalReadingModel>? historicalVitals,
    bool? simulatedAbnormalInjected,
    bool? autoReconnectEnabled,
    bool? backgroundTelemetryEnabled,
    String? connectionStatus,
    int? reconnectAttempts,
    int? currentBackoffMs,
    String? errorMessage,
  }) {
    return VitalsState(
      isLoading: isLoading ?? this.isLoading,
      devices: devices ?? this.devices,
      gattPeripherals: gattPeripherals ?? this.gattPeripherals,
      isScanningGatt: isScanningGatt ?? this.isScanningGatt,
      activeGattUuidFilters:
          activeGattUuidFilters ?? this.activeGattUuidFilters,
      selectedSensorType: selectedSensorType ?? this.selectedSensorType,
      currentTelemetry: currentTelemetry ?? this.currentTelemetry,
      historicalVitals: historicalVitals ?? this.historicalVitals,
      simulatedAbnormalInjected:
          simulatedAbnormalInjected ?? this.simulatedAbnormalInjected,
      autoReconnectEnabled: autoReconnectEnabled ?? this.autoReconnectEnabled,
      backgroundTelemetryEnabled:
          backgroundTelemetryEnabled ?? this.backgroundTelemetryEnabled,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      currentBackoffMs: currentBackoffMs ?? this.currentBackoffMs,
      errorMessage: errorMessage,
    );
  }
}

class VitalsNotifier extends Notifier<VitalsState> {
  late final VitalsRepository _repository;
  StreamSubscription<VitalReadingModel>? _telemetrySub;
  StreamSubscription<String>? _connectionStatusSub;

  @override
  VitalsState build() {
    _repository = sl<VitalsRepository>();
    ref.onDispose(() {
      _telemetrySub?.cancel();
      _connectionStatusSub?.cancel();
    });
    // Start listening
    _initStream();
    Future.microtask(_loadData);
    return const VitalsState(isLoading: true);
  }

  void _initStream() {
    _telemetrySub?.cancel();
    _telemetrySub = _repository.liveTelemetryStream.listen((reading) {
      if (state.simulatedAbnormalInjected) return;
      state = state.copyWith(currentTelemetry: reading);
    });

    _connectionStatusSub?.cancel();
    _connectionStatusSub = _repository.connectionStatusStream.listen((status) {
      state = state.copyWith(connectionStatus: status);
    });
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final history = await _repository.getHistoricalVitals(limit: 30);
      final devices = await _repository.scanDevices();
      final gattDevices = await _repository.scanGattPeripherals(
        serviceUuids: state.activeGattUuidFilters,
      );
      final connState = await _repository.getConnectionState();
      final latest = history.isNotEmpty ? history.first : null;

      state = state.copyWith(
        isLoading: false,
        historicalVitals: history,
        devices: devices,
        gattPeripherals: gattDevices,
        currentTelemetry: latest,
        connectionStatus:
            connState['connectionStatus'] as String? ?? 'CONNECTED',
        autoReconnectEnabled:
            connState['autoReconnectEnabled'] as bool? ?? true,
        backgroundTelemetryEnabled:
            connState['backgroundTelemetryEnabled'] as bool? ?? false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }

  /// Sprint 23: Direct BLE GATT Peripheral Discovery with Service UUID Filtering
  Future<void> scanGattPeripherals() async {
    state = state.copyWith(isScanningGatt: true);
    try {
      final gattDevices = await _repository.scanGattPeripherals(
        serviceUuids: state.activeGattUuidFilters,
      );
      state = state.copyWith(
        gattPeripherals: gattDevices,
        isScanningGatt: false,
      );
    } catch (e) {
      state = state.copyWith(isScanningGatt: false, errorMessage: e.toString());
    }
  }

  /// Sprint 23: Toggle specific GATT Service UUID filters
  Future<void> toggleGattUuidFilter(String uuid) async {
    final updatedFilters = List<String>.from(state.activeGattUuidFilters);
    if (updatedFilters.contains(uuid)) {
      if (updatedFilters.length > 1) {
        updatedFilters.remove(uuid);
      }
    } else {
      updatedFilters.add(uuid);
    }
    state = state.copyWith(activeGattUuidFilters: updatedFilters);
    await scanGattPeripherals();
  }

  /// Sprint 23: Toggle automatic reconnection with exponential backoff
  Future<void> toggleAutoReconnect(bool enabled) async {
    await _repository.setAutoReconnect(enabled: enabled);
    state = state.copyWith(autoReconnectEnabled: enabled);
  }

  /// Sprint 23: Toggle background telemetry ingestion & Android foreground notification
  Future<void> toggleBackgroundTelemetry(bool enabled) async {
    await _repository.setBackgroundTelemetry(enabled: enabled);
    state = state.copyWith(backgroundTelemetryEnabled: enabled);
  }

  /// Sprint 23: Simulate a connection drop to demonstrate exponential backoff recovery
  Future<void> simulateConnectionDrop() async {
    state = state.copyWith(
      connectionStatus: 'RECONNECTING',
      reconnectAttempts: 1,
      currentBackoffMs: 1000,
    );
    await _repository.simulateConnectionDrop();
  }

  Future<void> selectDevice(String sensorType) async {
    await _repository.pairDevice(sensorType);
    final updatedDevices = state.devices.map((d) {
      return d.copyWith(connected: d.type == sensorType);
    }).toList();

    state = state.copyWith(
      selectedSensorType: sensorType,
      devices: updatedDevices,
      connectionStatus: 'CONNECTED',
      reconnectAttempts: 0,
      simulatedAbnormalInjected: false,
    );
  }

  Future<void> disconnectCurrentDevice() async {
    await _repository.disconnectDevice();
    final updatedDevices = state.devices.map((d) {
      return d.copyWith(connected: false);
    }).toList();
    state = state.copyWith(
      devices: updatedDevices,
      connectionStatus: 'DISCONNECTED',
    );
  }

  Future<Map<String, dynamic>> calibrateCurrentDevice() async {
    return await _repository.calibrateDevice(state.selectedSensorType);
  }

  Future<void> logManualVital({
    int? systolic,
    int? diastolic,
    int? pulseRate,
    int? glucoseMgDl,
    int? oxygenSaturation,
    double? temperatureCelsius,
    String? notes,
  }) async {
    const uuid = Uuid();
    final now = DateTime.now();
    double? map;
    if (systolic != null && diastolic != null) {
      map = double.parse(
        (((2 * diastolic) + systolic) / 3.0).toStringAsFixed(1),
      );
    }

    final reading = VitalReadingModel(
      id: uuid.v4(),
      timestamp: now,
      sensorType: 'MANUAL',
      systolic: systolic,
      diastolic: diastolic,
      meanArterialPressure: map,
      pulseRate: pulseRate,
      glucoseMgDl: glucoseMgDl,
      glucoseMmolL: glucoseMgDl != null
          ? double.parse((glucoseMgDl / 18.0182).toStringAsFixed(1))
          : null,
      trendArrow: glucoseMgDl != null ? 'STABLE' : null,
      oxygenSaturation: oxygenSaturation,
      perfusionIndex: 4.0,
      temperatureCelsius: temperatureCelsius,
      temperatureFahrenheit: temperatureCelsius != null
          ? double.parse(((temperatureCelsius * 9 / 5) + 32).toStringAsFixed(1))
          : null,
      irregularHeartbeat: false,
      crc32Checksum: 'MANUAL-LOG',
      notes: notes ?? 'Manually recorded vital reading',
    );

    await _repository.saveVitalReading(reading);
    state = state.copyWith(
      historicalVitals: [reading, ...state.historicalVitals],
      currentTelemetry: reading,
    );
  }

  void injectSimulatedAbnormalAlert() {
    final abnormal = VitalReadingModel(
      id: 'sim_abnormal_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      sensorType: state.selectedSensorType,
      systolic: 158,
      diastolic: 102,
      meanArterialPressure: 120.6,
      pulseRate: 114,
      glucoseMgDl: 228,
      glucoseMmolL: 12.6,
      trendArrow: 'RISING',
      oxygenSaturation: 91,
      perfusionIndex: 1.8,
      temperatureCelsius: 38.6,
      temperatureFahrenheit: 101.5,
      irregularHeartbeat: true,
      crc32Checksum: 'ERR-CRITICAL',
      notes: 'Simulated Recruiter Debug Abnormal Alert - Stage 2 Hypertensive Spike',
    );

    state = state.copyWith(
      currentTelemetry: abnormal,
      simulatedAbnormalInjected: true,
      historicalVitals: [abnormal, ...state.historicalVitals],
    );
  }
}

final vitalsNotifierProvider = NotifierProvider<VitalsNotifier, VitalsState>(
  () {
    return VitalsNotifier();
  },
);
