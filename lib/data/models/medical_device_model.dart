class MedicalDeviceModel {
  final String id;
  final String name;
  final String model;
  final String type; // 'CARDIO_CUFF', 'GLUCO_SENSE', 'OXY_PULSE'
  final int batteryLevel;
  final int rssi;
  final bool connected;
  final List<String> serviceUuids;
  final String? macAddress;
  final bool isGattDevice;
  final String connectionStatus; // 'CONNECTED', 'RECONNECTING', 'DISCONNECTED'
  final int reconnectAttempts;
  final bool autoReconnect;

  const MedicalDeviceModel({
    required this.id,
    required this.name,
    required this.model,
    required this.type,
    required this.batteryLevel,
    required this.rssi,
    required this.connected,
    this.serviceUuids = const [],
    this.macAddress,
    this.isGattDevice = false,
    this.connectionStatus = 'DISCONNECTED',
    this.reconnectAttempts = 0,
    this.autoReconnect = true,
  });

  factory MedicalDeviceModel.fromMap(Map<String, dynamic> map) {
    return MedicalDeviceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      model: map['model'] as String,
      type: map['type'] as String,
      batteryLevel: map['batteryLevel'] as int? ?? 100,
      rssi: map['rssi'] as int? ?? -60,
      connected:
          map['connected'] as bool? ?? (map['connectionStatus'] == 'CONNECTED'),
      serviceUuids:
          (map['serviceUuids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      macAddress: map['macAddress'] as String?,
      isGattDevice: map['isGattDevice'] as bool? ?? false,
      connectionStatus:
          map['connectionStatus'] as String? ??
          (map['connected'] == true ? 'CONNECTED' : 'DISCONNECTED'),
      reconnectAttempts: map['reconnectAttempts'] as int? ?? 0,
      autoReconnect: map['autoReconnect'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'type': type,
      'batteryLevel': batteryLevel,
      'rssi': rssi,
      'connected': connected,
      'serviceUuids': serviceUuids,
      'macAddress': macAddress,
      'isGattDevice': isGattDevice,
      'connectionStatus': connectionStatus,
      'reconnectAttempts': reconnectAttempts,
      'autoReconnect': autoReconnect,
    };
  }

  MedicalDeviceModel copyWith({
    String? id,
    String? name,
    String? model,
    String? type,
    int? batteryLevel,
    int? rssi,
    bool? connected,
    List<String>? serviceUuids,
    String? macAddress,
    bool? isGattDevice,
    String? connectionStatus,
    int? reconnectAttempts,
    bool? autoReconnect,
  }) {
    return MedicalDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      type: type ?? this.type,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      rssi: rssi ?? this.rssi,
      connected: connected ?? this.connected,
      serviceUuids: serviceUuids ?? this.serviceUuids,
      macAddress: macAddress ?? this.macAddress,
      isGattDevice: isGattDevice ?? this.isGattDevice,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }
}
