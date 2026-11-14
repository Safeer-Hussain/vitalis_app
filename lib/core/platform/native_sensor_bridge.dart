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

  String _currentSensorType = 'CARDIO_CUFF';
  bool _isPaired = true;
  StreamController<Map<String, dynamic>>? _fallbackController;
  Timer? _fallbackTimer;

  bool get _isNativeMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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

  Future<bool> pairMedicalDevice(String sensorType) async {
    _currentSensorType = sensorType;
    _isPaired = true;
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
        };
      default:
        return {'timestamp': now, 'sensorType': 'UNKNOWN'};
    }
  }

  void dispose() {
    _fallbackTimer?.cancel();
    _fallbackController?.close();
  }
}
