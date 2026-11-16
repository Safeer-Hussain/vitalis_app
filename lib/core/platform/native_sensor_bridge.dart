import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeSensorBridge {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.safeer.vitalis/medical_devices',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.safeer.vitalis/clinical_telemetry',
  );

  // Standard Bluetooth SIG Clinical Service UUIDs
  static const String uuidHeartRate = '0x180D';
  static const String uuidBloodPressure = '0x1810';
  static const String uuidGlucose = '0x1808';

  String _currentSensorType = 'CARDIO_CUFF';
  bool _isPaired = true;
  bool _autoReconnectEnabled = true;
  bool _backgroundTelemetryEnabled = false;
  String _connectionStatus = 'CONNECTED';
  int _reconnectAttempts = 0;
  int _currentBackoffMs = 1000;

  StreamController<Map<String, dynamic>>? _fallbackController;
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();
  Timer? _fallbackTimer;
  Timer? _reconnectTimer;

  bool get _isNativeMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  String get currentConnectionStatus => _connectionStatus;
  bool get isAutoReconnectEnabled => _autoReconnectEnabled;
  bool get isBackgroundTelemetryEnabled => _backgroundTelemetryEnabled;
  int get reconnectAttempts => _reconnectAttempts;

  Future<List<Map<String, dynamic>>> scanClinicalSensors() async {
    if (_isNativeMobile) {
      try {
        final List<dynamic>? result = await _methodChannel.invokeListMethod(
          'scanClinicalSensors',
        );
        if (result != null) {
          return result
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
      } catch (e) {
        debugPrint('Native scan error, using simulated fallback: $e');
      }
    }

    // Reliable fallback for tests and desktop
    return [
      {
        'id': 'DEV-CC-9041',
        'name': 'CardioCuff Pro',
        'model': 'CC-PRO-V2',
        'type': 'CARDIO_CUFF',
        'batteryLevel': 88,
        'rssi': -54,
        'connected': _currentSensorType == 'CARDIO_CUFF' && _isPaired,
      },
      {
        'id': 'DEV-GS-2018',
        'name': 'GlucoSense CGM',
        'model': 'GS-CGM-4X',
        'type': 'GLUCO_SENSE',
        'batteryLevel': 94,
        'rssi': -48,
        'connected': _currentSensorType == 'GLUCO_SENSE' && _isPaired,
      },
      {
        'id': 'DEV-OP-5523',
        'name': 'OxyPulse Clinical',
        'model': 'OP-CLIN-9',
        'type': 'OXY_PULSE',
        'batteryLevel': 76,
        'rssi': -62,
        'connected': _currentSensorType == 'OXY_PULSE' && _isPaired,
      },
    ];
  }

  /// Sprint 23: Direct BLE GATT Peripheral Discovery with Service UUID Filtering
  Future<List<Map<String, dynamic>>> scanGattPeripherals({
    List<String>? serviceUuids,
  }) async {
    final activeFilters =
        serviceUuids ?? [uuidHeartRate, uuidBloodPressure, uuidGlucose];

    if (_isNativeMobile) {
      try {
        final List<dynamic>? result = await _methodChannel.invokeListMethod(
          'scanGattPeripherals',
          {'serviceUuids': activeFilters},
        );
        if (result != null) {
          return result
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
      } catch (e) {
        debugPrint('Native GATT scan error, using simulated fallback: $e');
      }
    }

    // Deterministic simulation for tests & desktop with UUID filtering
    final allGattPeripherals = [
      {
        'id': 'GATT-CC-8821',
        'name': 'CardioCuff Pro BLE-GATT',
        'model': 'CC-PRO-GATT-V3',
        'type': 'CARDIO_CUFF',
        'macAddress': 'C4:D3:58:AA:11:42',
        'batteryLevel': 92,
        'rssi': -52,
        'serviceUuids': [uuidBloodPressure, uuidHeartRate],
        'isGattDevice': true,
        'connectionStatus': (_currentSensorType == 'CARDIO_CUFF' && _isPaired)
            ? _connectionStatus
            : 'DISCONNECTED',
      },
      {
        'id': 'GATT-GS-4190',
        'name': 'GlucoSense CGM Direct',
        'model': 'GS-CGM-DIRECT-X',
        'type': 'GLUCO_SENSE',
        'macAddress': 'E1:8B:22:90:3F:8A',
        'batteryLevel': 96,
        'rssi': -46,
        'serviceUuids': [uuidGlucose],
        'isGattDevice': true,
        'connectionStatus': (_currentSensorType == 'GLUCO_SENSE' && _isPaired)
            ? _connectionStatus
            : 'DISCONNECTED',
      },
      {
        'id': 'GATT-OP-7734',
        'name': 'OxyPulse Clinical Wireless',
        'model': 'OP-CLIN-GATT-2',
        'type': 'OXY_PULSE',
        'macAddress': 'F0:24:6D:77:C8:19',
        'batteryLevel': 81,
        'rssi': -59,
        'serviceUuids': [uuidHeartRate],
        'isGattDevice': true,
        'connectionStatus': (_currentSensorType == 'OXY_PULSE' && _isPaired)
            ? _connectionStatus
            : 'DISCONNECTED',
      },
    ];

    final uppercaseFilters = activeFilters.map((u) => u.toUpperCase()).toSet();
    return allGattPeripherals.where((device) {
      final services =
          (device['serviceUuids'] as List<String>?)?.map(
            (s) => s.toUpperCase(),
          ) ??
          [];
      return services.any(uppercaseFilters.contains);
    }).toList();
  }

  Future<bool> pairMedicalDevice(String sensorType) async {
    _currentSensorType = sensorType;
    _isPaired = true;
    _setConnectionStatus('CONNECTED');
    _reconnectAttempts = 0;
    _currentBackoffMs = 1000;

    if (_isNativeMobile) {
      try {
        final bool? success = await _methodChannel.invokeMethod<bool>(
          'pairMedicalDevice',
          {'sensorType': sensorType},
        );
        return success ?? true;
      } catch (e) {
        debugPrint('Native pair error: $e');
      }
    }
    return true;
  }

  Future<bool> disconnectDevice() async {
    _isPaired = false;
    _setConnectionStatus('DISCONNECTED');
    _reconnectTimer?.cancel();

    if (_isNativeMobile) {
      try {
        final bool? success = await _methodChannel.invokeMethod<bool>(
          'disconnectDevice',
        );
        return success ?? true;
      } catch (e) {
        debugPrint('Native disconnect error: $e');
      }
    }
    return true;
  }

  Future<Map<String, dynamic>> triggerCalibration(String sensorType) async {
    if (_isNativeMobile) {
      try {
        final Map<dynamic, dynamic>? res = await _methodChannel.invokeMapMethod(
          'triggerCalibration',
          {'sensorType': sensorType},
        );
        if (res != null) {
          return Map<String, dynamic>.from(res);
        }
      } catch (e) {
        debugPrint('Native calibration error: $e');
      }
    }
    return {
      'status': 'CALIBRATED',
      'sensorType': sensorType,
      'zeroOffset': 0.12,
      'referenceVoltage': 3.298,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Sprint 23: Toggle automatic reconnection with exponential backoff
  Future<bool> enableAutoReconnect({required bool enabled}) async {
    _autoReconnectEnabled = enabled;
    if (_isNativeMobile) {
      try {
        final bool? res = await _methodChannel.invokeMethod<bool>(
          'enableAutoReconnect',
          {'enabled': enabled},
        );
        return res ?? true;
      } catch (e) {
        debugPrint('Native enableAutoReconnect error: $e');
      }
    }
    return true;
  }

  /// Sprint 23: Toggle background telemetry ingestion & Android foreground notification
  Future<bool> toggleBackgroundTelemetry({required bool enabled}) async {
    _backgroundTelemetryEnabled = enabled;
    if (_isNativeMobile) {
      try {
        final bool? res = await _methodChannel.invokeMethod<bool>(
          'toggleBackgroundTelemetry',
          {'enabled': enabled},
        );
        return res ?? true;
      } catch (e) {
        debugPrint('Native toggleBackgroundTelemetry error: $e');
      }
    }
    return true;
  }

  /// Sprint 23: Retrieve native connection state and backoff metrics
  Future<Map<String, dynamic>> getConnectionState() async {
    if (_isNativeMobile) {
      try {
        final Map<dynamic, dynamic>? res = await _methodChannel.invokeMapMethod(
          'getConnectionState',
        );
        if (res != null) {
          return Map<String, dynamic>.from(res);
        }
      } catch (e) {
        debugPrint('Native getConnectionState error: $e');
      }
    }

    return {
      'connectionStatus': _connectionStatus,
      'autoReconnectEnabled': _autoReconnectEnabled,
      'backgroundTelemetryEnabled': _backgroundTelemetryEnabled,
      'reconnectAttempt': _reconnectAttempts,
      'maxReconnectAttempts': 5,
      'currentBackoffMs': _currentBackoffMs,
    };
  }

  /// Sprint 23: Simulate a connection drop to trigger and verify exponential backoff
  Future<void> simulateConnectionDrop() async {
    if (!_isPaired || !_autoReconnectEnabled) return;

    _setConnectionStatus('RECONNECTING');
    _reconnectAttempts = 1;
    _currentBackoffMs = 1000;

    if (_isNativeMobile) {
      try {
        await _methodChannel.invokeMethod('simulateConnectionDrop');
        return;
      } catch (e) {
        debugPrint('Native simulateConnectionDrop error: $e');
      }
    }

    _scheduleSimulatedBackoff();
  }

  void _scheduleSimulatedBackoff() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _currentBackoffMs), () {
      if (!_autoReconnectEnabled) return;

      if (_reconnectAttempts >= 3) {
        // Reconnection succeeded
        _setConnectionStatus('CONNECTED');
        _reconnectAttempts = 0;
        _currentBackoffMs = 1000;
      } else {
        _reconnectAttempts++;
        _currentBackoffMs = (_currentBackoffMs * 2).clamp(1000, 16000);
        _scheduleSimulatedBackoff();
      }
    });
  }

  void _setConnectionStatus(String status) {
    _connectionStatus = status;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
  }

  Stream<Map<String, dynamic>> get clinicalTelemetryStream {
    if (_isNativeMobile) {
      try {
        return _eventChannel.receiveBroadcastStream().map(
          (dynamic event) => Map<String, dynamic>.from(event as Map),
        );
      } catch (e) {
        debugPrint('Native telemetry stream error, using fallback stream: $e');
      }
    }

    _fallbackController?.close();
    _fallbackTimer?.cancel();
    _fallbackController = StreamController<Map<String, dynamic>>.broadcast();

    _fallbackTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_isPaired ||
          _connectionStatus != 'CONNECTED' ||
          _fallbackController == null ||
          _fallbackController!.isClosed) {
        return;
      }
      _fallbackController!.add(_generateSimulatedPacket(_currentSensorType));
    });

    return _fallbackController!.stream;
  }

  Map<String, dynamic> _generateSimulatedPacket(String sensorType) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random();

    switch (sensorType) {
      case 'CARDIO_CUFF':
        final systolic = 118 + rand.nextInt(9) - 4;
        final diastolic = 78 + rand.nextInt(7) - 3;
        final map = ((2 * diastolic) + systolic) / 3.0;
        final pulse = 72 + rand.nextInt(7) - 3;
        return {
          'timestamp': now,
          'sensorType': 'CARDIO_CUFF',
          'deviceName': 'CardioCuff Pro',
          'systolic': systolic,
          'diastolic': diastolic,
          'meanArterialPressure': double.parse(map.toStringAsFixed(1)),
          'pulseRate': pulse,
          'irregularHeartbeat': rand.nextInt(100) < 5,
          'batteryLevel': 88,
          'signalQuality': 'OPTIMAL',
          'connectionStatus': _connectionStatus,
          'autoReconnectActive': _autoReconnectEnabled,
        };
      case 'GLUCO_SENSE':
        final glucoseMgDl = 108 + rand.nextInt(15) - 7;
        final mmol = double.parse((glucoseMgDl / 18.0182).toStringAsFixed(1));
        return {
          'timestamp': now,
          'sensorType': 'GLUCO_SENSE',
          'deviceName': 'GlucoSense CGM',
          'glucoseMgDl': glucoseMgDl,
          'glucoseMmolL': mmol,
          'trendArrow': glucoseMgDl > 112
              ? 'RISING'
              : (glucoseMgDl < 104 ? 'FALLING' : 'STABLE'),
          'timeInRangePercentage': 94.6,
          'sensorLifetimeDaysLeft': 11,
          'signalQuality': 'EXCELLENT',
          'connectionStatus': _connectionStatus,
          'autoReconnectActive': _autoReconnectEnabled,
        };
      case 'OXY_PULSE':
        final spO2 = 98 + rand.nextInt(3) - 1;
        const pi = 4.3;
        const tempC = 36.8;
        const tempF = (tempC * 9 / 5) + 32;
        return {
          'timestamp': now,
          'sensorType': 'OXY_PULSE',
          'deviceName': 'OxyPulse Clinical',
          'oxygenSaturation': spO2.clamp(95, 100),
          'perfusionIndex': pi,
          'temperatureCelsius': tempC,
          'temperatureFahrenheit': tempF,
          'crc32Checksum': '8F3A2B1C',
          'signalQuality': 'NOMINAL',
          'connectionStatus': _connectionStatus,
          'autoReconnectActive': _autoReconnectEnabled,
        };
      default:
        return {'timestamp': now, 'sensorType': 'UNKNOWN'};
    }
  }

  void dispose() {
    _fallbackTimer?.cancel();
    _reconnectTimer?.cancel();
    _fallbackController?.close();
    _connectionStatusController.close();
  }
}
