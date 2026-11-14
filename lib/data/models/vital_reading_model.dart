class VitalReadingModel {
  final String id;
  final DateTime timestamp;
  final String
  sensorType; // 'CARDIO_CUFF', 'GLUCO_SENSE', 'OXY_PULSE', 'MANUAL'
  final int? systolic;
  final int? diastolic;
  final double? meanArterialPressure;
  final int? pulseRate;
  final int? glucoseMgDl;
  final double? glucoseMmolL;
  final String? trendArrow; // 'RISING', 'STABLE', 'FALLING'
  final int? oxygenSaturation;
  final double? perfusionIndex;
  final double? temperatureCelsius;
  final double? temperatureFahrenheit;
  final bool irregularHeartbeat;
  final String? crc32Checksum;
  final String? notes;

  const VitalReadingModel({
    required this.id,
    required this.timestamp,
    required this.sensorType,
    this.systolic,
    this.diastolic,
    this.meanArterialPressure,
    this.pulseRate,
    this.glucoseMgDl,
    this.glucoseMmolL,
    this.trendArrow,
    this.oxygenSaturation,
    this.perfusionIndex,
    this.temperatureCelsius,
    this.temperatureFahrenheit,
    this.irregularHeartbeat = false,
    this.crc32Checksum,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'sensor_type': sensorType,
      'systolic': systolic,
      'diastolic': diastolic,
      'mean_arterial_pressure': meanArterialPressure,
      'pulse_rate': pulseRate,
      'glucose_mg_dl': glucoseMgDl,
      'glucose_mmol_l': glucoseMmolL,
      'trend_arrow': trendArrow,
      'oxygen_saturation': oxygenSaturation,
      'perfusion_index': perfusionIndex,
      'temperature_celsius': temperatureCelsius,
      'temperature_fahrenheit': temperatureFahrenheit,
      'irregular_heartbeat': irregularHeartbeat ? 1 : 0,
      'crc32_checksum': crc32Checksum,
      'notes': notes,
    };
  }

  factory VitalReadingModel.fromMap(Map<String, dynamic> map) {
    return VitalReadingModel(
      id: map['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      sensorType: map['sensor_type'] as String,
      systolic: map['systolic'] as int?,
      diastolic: map['diastolic'] as int?,
      meanArterialPressure: (map['mean_arterial_pressure'] as num?)?.toDouble(),
      pulseRate: map['pulse_rate'] as int?,
      glucoseMgDl: map['glucose_mg_dl'] as int?,
      glucoseMmolL: (map['glucose_mmol_l'] as num?)?.toDouble(),
      trendArrow: map['trend_arrow'] as String?,
      oxygenSaturation: map['oxygen_saturation'] as int?,
      perfusionIndex: (map['perfusion_index'] as num?)?.toDouble(),
      temperatureCelsius: (map['temperature_celsius'] as num?)?.toDouble(),
      temperatureFahrenheit: (map['temperature_fahrenheit'] as num?)
          ?.toDouble(),
      irregularHeartbeat: (map['irregular_heartbeat'] as int? ?? 0) == 1,
      crc32Checksum: map['crc32_checksum'] as String?,
      notes: map['notes'] as String?,
    );
  }

  factory VitalReadingModel.fromTelemetryPacket(Map<String, dynamic> map) {
    final type = map['sensorType'] as String? ?? 'CARDIO_CUFF';
    final ts =
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    return VitalReadingModel(
      id: 'telemetry_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      sensorType: type,
      systolic: map['systolic'] as int?,
      diastolic: map['diastolic'] as int?,
      meanArterialPressure: (map['meanArterialPressure'] as num?)?.toDouble(),
      pulseRate: map['pulseRate'] as int?,
      glucoseMgDl: map['glucoseMgDl'] as int?,
      glucoseMmolL: (map['glucoseMmolL'] as num?)?.toDouble(),
      trendArrow: map['trendArrow'] as String?,
      oxygenSaturation: map['oxygenSaturation'] as int?,
      perfusionIndex: (map['perfusionIndex'] as num?)?.toDouble(),
      temperatureCelsius: (map['temperatureCelsius'] as num?)?.toDouble(),
      temperatureFahrenheit: (map['temperatureFahrenheit'] as num?)?.toDouble(),
      irregularHeartbeat: map['irregularHeartbeat'] as bool? ?? false,
      crc32Checksum: map['crc32Checksum'] as String?,
      notes: map['signalQuality'] != null
          ? 'Telemetry signal: ${map['signalQuality']}'
          : null,
    );
  }
}
