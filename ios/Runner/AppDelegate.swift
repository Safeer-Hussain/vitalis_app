import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private let methodChannelName = "com.safeer.vitalis/medical_devices"
  private let eventChannelName = "com.safeer.vitalis/clinical_telemetry"

  private var selectedSensorType = "CARDIO_CUFF"
  private var isPaired = true
  private var telemetryTimer: Timer?
  private var eventSink: FlutterEventSink?

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
        let devices: [[String: Any]] = [
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
        result(devices)
      case "pairMedicalDevice":
        if let args = call.arguments as? [String: Any], let sensorType = args["sensorType"] as? String {
          self.selectedSensorType = sensorType
        }
        self.isPaired = true
        result(true)
      case "disconnectDevice":
        self.isPaired = false
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
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
      guard let self = self, self.isPaired, let sink = self.eventSink else { return }
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
        "signalQuality": "OPTIMAL"
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
        "signalQuality": "EXCELLENT"
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
        "signalQuality": "NOMINAL"
      ]
    default:
      return ["timestamp": now, "sensorType": "UNKNOWN"]
    }
  }
}
