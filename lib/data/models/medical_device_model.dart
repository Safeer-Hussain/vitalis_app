class MedicalDeviceModel {
  final String id;
  final String name;
  final String model;
  final String type; // 'CARDIO_CUFF', 'GLUCO_SENSE', 'OXY_PULSE'
  final int batteryLevel;
  final int rssi;
  final bool connected;

  const MedicalDeviceModel({
    required this.id,
    required this.name,
    required this.model,
    required this.type,
    required this.batteryLevel,
    required this.rssi,
    required this.connected,
  });

  factory MedicalDeviceModel.fromMap(Map<String, dynamic> map) {
    return MedicalDeviceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      model: map['model'] as String,
      type: map['type'] as String,
      batteryLevel: map['batteryLevel'] as int? ?? 100,
      rssi: map['rssi'] as int? ?? -60,
      connected: map['connected'] as bool? ?? false,
    );
  }

  MedicalDeviceModel copyWith({
    String? id,
    String? name,
    String? model,
    String? type,
    int? batteryLevel,
    int? rssi,
    bool? connected,
  }) {
    return MedicalDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      type: type ?? this.type,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      rssi: rssi ?? this.rssi,
      connected: connected ?? this.connected,
    );
  }
}
