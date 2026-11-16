import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private let methodChannelName = "com.safeer.vitalis/medical_devices"
  private let eventChannelName = "com.safeer.vitalis/clinical_telemetry"

  // Standard Bluetooth SIG Clinical Service UUIDs
  private let uuidHeartRate = "0x180D"
  private let uuidBloodPressure = "0x1810"
  private let uuidGlucose = "0x1808"

  private var selectedSensorType = "CARDIO_CUFF"
  private var isPaired = true
  private var telemetryTimer: Timer?
  private var eventSink: FlutterEventSink?

  // Sprint 23 BLE GATT Direct Peripheral & Reconnect state
  private var autoReconnectEnabled = true
  private var backgroundTelemetryEnabled = false
  private var connectionStatus = "CONNECTED"
  private var reconnectAttempt = 0
  private let maxReconnectAttempts = 5
  private var currentBackoffMs: Double = 1000.0

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: controller.binaryMessenger)
    methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      switch call.method {
      case "scanClinicalSensors":
        let devices = self.getDiscoveredSensors()
        result(devices)
      case "scanGattPeripherals":
        var requestedUuids = [self.uuidHeartRate, self.uuidBloodPressure, self.uuidGlucose]
        if let args = call.arguments as? [String: Any], let customUuids = args["serviceUuids"] as? [String] {
          requestedUuids = customUuids
        }
        let gattDevices = self.getGattPeripherals(filterUuids: requestedUuids)
        result(gattDevices)
      case "pairMedicalDevice":
        if let args = call.arguments as? [String: Any], let sensorType = args["sensorType"] as? String {
          self.selectedSensorType = sensorType
        }
        self.isPaired = true
        self.connectionStatus = "CONNECTED"
        self.reconnectAttempt = 0
        self.currentBackoffMs = 1000.0
        result(true)
      case "disconnectDevice":
        self.isPaired = false
        self.connectionStatus = "DISCONNECTED"
        result(true)
      case "triggerCalibration":
        let response: [String: Any] = [
          "status": "CALIBRATED",
          "sensorType": self.selectedSensorType,
          "zeroOffset": 0.12,
          "referenceVoltage": 3.298,
          "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        result(response)
      case "enableAutoReconnect":
        if let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool {
          self.autoReconnectEnabled = enabled
        }
        result(true)
      case "toggleBackgroundTelemetry":
        if let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool {
          self.backgroundTelemetryEnabled = enabled
        }
        result(true)
      case "getConnectionState":
        let state: [String: Any] = [
          "connectionStatus": self.connectionStatus,
          "autoReconnectEnabled": self.autoReconnectEnabled,
          "backgroundTelemetryEnabled": self.backgroundTelemetryEnabled,
          "reconnectAttempt": self.reconnectAttempt,
          "maxReconnectAttempts": self.maxReconnectAttempts,
          "currentBackoffMs": self.currentBackoffMs
        ]
        result(state)
      case "simulateConnectionDrop":
        if self.isPaired && self.autoReconnectEnabled {
          self.connectionStatus = "RECONNECTING"
          self.reconnectAttempt = 1
          self.currentBackoffMs = 1000.0
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.connectionStatus = "CONNECTED"
            self.reconnectAttempt = 0
          }
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func getDiscoveredSensors() -> [[String: Any]] {
    return [
      [
        "id": "DEV-CC-9041",
        "name": "CardioCuff Pro",
        "model": "CC-PRO-V2",
        "type": "CARDIO_CUFF",
        "batteryLevel": 88,
        "rssi": -54,
        "connected": self.selectedSensorType == "CARDIO_CUFF" && self.isPaired
      ],
      [
        "id": "DEV-GS-2018",
        "name": "GlucoSense CGM",
        "model": "GS-CGM-4X",
        "type": "GLUCO_SENSE",
        "batteryLevel": 94,
        "rssi": -48,
        "connected": self.selectedSensorType == "GLUCO_SENSE" && self.isPaired
      ],
      [
        "id": "DEV-OP-5523",
        "name": "OxyPulse Clinical",
        "model": "OP-CLIN-9",
        "type": "OXY_PULSE",
        "batteryLevel": 76,
        "rssi": -62,
        "connected": self.selectedSensorType == "OXY_PULSE" && self.isPaired
      ]
    ]
  }

  private func getGattPeripherals(filterUuids: [String]) -> [[String: Any]] {
    let allDevices: [[String: Any]] = [
      [
        "id": "GATT-CC-8821",
        "name": "CardioCuff Pro BLE-GATT",
        "model": "CC-PRO-GATT-V3",
        "type": "CARDIO_CUFF",
        "macAddress": "C4:D3:58:AA:11:42",
        "batteryLevel": 92,
        "rssi": -52,
        "serviceUuids": [self.uuidBloodPressure, self.uuidHeartRate],
        "isGattDevice": true,
        "connectionStatus": (self.selectedSensorType == "CARDIO_CUFF" && self.isPaired) ? self.connectionStatus : "DISCONNECTED"
      ],
      [
        "id": "GATT-GS-4190",
        "name": "GlucoSense CGM Direct",
        "model": "GS-CGM-DIRECT-X",
        "type": "GLUCO_SENSE",
        "macAddress": "E1:8B:22:90:3F:8A",
        "batteryLevel": 96,
        "rssi": -46,
        "serviceUuids": [self.uuidGlucose],
        "isGattDevice": true,
        "connectionStatus": (self.selectedSensorType == "GLUCO_SENSE" && self.isPaired) ? self.connectionStatus : "DISCONNECTED"
      ],
      [
        "id": "GATT-OP-7734",
        "name": "OxyPulse Clinical Wireless",
        "model": "OP-CLIN-GATT-2",
        "type": "OXY_PULSE",
        "macAddress": "F0:24:6D:77:C8:19",
        "batteryLevel": 81,
        "rssi": -59,
        "serviceUuids": [self.uuidHeartRate],
        "isGattDevice": true,
        "connectionStatus": (self.selectedSensorType == "OXY_PULSE" && self.isPaired) ? self.connectionStatus : "DISCONNECTED"
      ]
    ]

    let normalizedFilters = filterUuids.map { $0.uppercased() }
    return allDevices.filter { device in
      let services = (device["serviceUuids"] as? [String])?.map { $0.uppercased() } ?? []
      return services.contains { normalizedFilters.contains($0) }
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    startTelemetryTimer()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopTelemetryTimer()
    self.eventSink = nil
    return nil
  }

  private func startTelemetryTimer() {
    stopTelemetryTimer()
    telemetryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      guard let self = self, self.isPaired, self.connectionStatus == "CONNECTED", let sink = self.eventSink else { return }
      let packet = self.generateClinicalPacket(sensorType: self.selectedSensorType)
      sink(packet)
    }
  }

  private func stopTelemetryTimer() {
    telemetryTimer?.invalidate()
    telemetryTimer = nil
  }

  private func generateClinicalPacket(sensorType: String) -> [String: Any] {
    let now = Int64(Date().timeIntervalSince1970 * 1000)
    switch sensorType {
    case "CARDIO_CUFF":
      let systolic = 120 + Int.random(in: -4...6)
      let diastolic = 79 + Int.random(in: -3...4)
      let mapVal = (Double(2 * diastolic + systolic) / 3.0 * 10).rounded() / 10
      let pulse = 72 + Int.random(in: -4...4)
      return [
        "timestamp": now,
        "sensorType": "CARDIO_CUFF",
        "deviceName": "CardioCuff Pro",
        "systolic": systolic,
        "diastolic": diastolic,
        "meanArterialPressure": mapVal,
        "pulseRate": pulse,
        "irregularHeartbeat": false,
        "batteryLevel": 88,
        "signalQuality": "OPTIMAL",
        "connectionStatus": self.connectionStatus,
        "autoReconnectActive": self.autoReconnectEnabled
      ]
    case "GLUCO_SENSE":
      let glucose = 108 + Int.random(in: -6...8)
      let mmol = (Double(glucose) / 18.0182 * 10).rounded() / 10
      return [
        "timestamp": now,
        "sensorType": "GLUCO_SENSE",
        "deviceName": "GlucoSense CGM",
        "glucoseMgDl": glucose,
        "glucoseMmolL": mmol,
        "trendArrow": glucose > 112 ? "RISING" : (glucose < 104 ? "FALLING" : "STABLE"),
        "timeInRangePercentage": 94.6,
        "sensorLifetimeDaysLeft": 11,
        "signalQuality": "EXCELLENT",
        "connectionStatus": self.connectionStatus,
        "autoReconnectActive": self.autoReconnectEnabled
      ]
    case "OXY_PULSE":
      let spo2 = 98 + Int.random(in: -1...1)
      let pi = 4.3
      let tempC = 36.8
      let tempF = (tempC * 9.0 / 5.0) + 32.0
      return [
        "timestamp": now,
        "sensorType": "OXY_PULSE",
        "deviceName": "OxyPulse Clinical",
        "oxygenSaturation": spo2,
        "perfusionIndex": pi,
        "temperatureCelsius": tempC,
        "temperatureFahrenheit": tempF,
        "crc32Checksum": "8F3A2B1C",
        "signalQuality": "NOMINAL",
        "connectionStatus": self.connectionStatus,
        "autoReconnectActive": self.autoReconnectEnabled
      ]
    default:
      return ["timestamp": now, "sensorType": "UNKNOWN"]
    }
  }
}
