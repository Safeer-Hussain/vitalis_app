package com.safeer.vitalis

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.zip.CRC32
import kotlin.random.Random

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.safeer.vitalis/medical_devices"
    private val EVENT_CHANNEL = "com.safeer.vitalis/clinical_telemetry"

    private var selectedSensorType = "CARDIO_CUFF"
    private var isPaired = true
    private var telemetryHandler: Handler? = null
    private var telemetryRunnable: Runnable? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanClinicalSensors" -> {
                    val devices = listOf(
                        mapOf(
                            "id" to "DEV-CC-9041",
                            "name" to "CardioCuff Pro",
                            "model" to "CC-PRO-V2",
                            "type" to "CARDIO_CUFF",
                            "batteryLevel" to 88,
                            "rssi" to -54,
                            "connected" to (selectedSensorType == "CARDIO_CUFF" && isPaired)
                        ),
                        mapOf(
                            "id" to "DEV-GS-2018",
                            "name" to "GlucoSense CGM",
                            "model" to "GS-CGM-4X",
                            "type" to "GLUCO_SENSE",
                            "batteryLevel" to 94,
                            "rssi" to -48,
                            "connected" to (selectedSensorType == "GLUCO_SENSE" && isPaired)
                        ),
                        mapOf(
                            "id" to "DEV-OP-5523",
                            "name" to "OxyPulse Clinical",
                            "model" to "OP-CLIN-9",
                            "type" to "OXY_PULSE",
                            "batteryLevel" to 76,
                            "rssi" to -62,
                            "connected" to (selectedSensorType == "OXY_PULSE" && isPaired)
                        )
                    )
                    result.success(devices)
                }
                "pairMedicalDevice" -> {
                    val sensorType = call.argument<String>("sensorType") ?: "CARDIO_CUFF"
                    selectedSensorType = sensorType
                    isPaired = true
                    result.success(true)
                }
                "disconnectDevice" -> {
                    isPaired = false
                    result.success(true)
                }
                "triggerCalibration" -> {
                    val sensorType = call.argument<String>("sensorType") ?: selectedSensorType
                    val response = mapOf(
                        "status" to "CALIBRATED",
                        "sensorType" to sensorType,
                        "zeroOffset" to 0.12,
                        "referenceVoltage" to 3.298,
                        "timestamp" to System.currentTimeMillis()
                    )
                    result.success(response)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startTelemetryStream()
                }

                override fun onCancel(arguments: Any?) {
                    stopTelemetryStream()
                    eventSink = null
                }
            }
        )
    }

    private fun startTelemetryStream() {
        stopTelemetryStream()
        telemetryHandler = Handler(Looper.getMainLooper())
        telemetryRunnable = object : Runnable {
            override fun run() {
                if (isPaired && eventSink != null) {
                    val packet = generateClinicalPacket(selectedSensorType)
                    eventSink?.success(packet)
                }
                telemetryHandler?.postDelayed(this, 2000L)
            }
        }
        telemetryHandler?.post(telemetryRunnable!!)
    }

    private fun stopTelemetryStream() {
        telemetryRunnable?.let { telemetryHandler?.removeCallbacks(it) }
        telemetryRunnable = null
        telemetryHandler = null
    }

    private fun generateClinicalPacket(sensorType: String): Map<String, Any> {
        val now = System.currentTimeMillis()
        val random = Random.Default

        return when (sensorType) {
            "CARDIO_CUFF" -> {
                val systolic = 118 + random.nextInt(-4, 7)
                val diastolic = 78 + random.nextInt(-3, 5)
                val map = ((2 * diastolic) + systolic) / 3.0
                val pulse = 72 + random.nextInt(-4, 5)
                val irregular = random.nextInt(100) < 5

                mapOf(
                    "timestamp" to now,
                    "sensorType" to "CARDIO_CUFF",
                    "deviceName" to "CardioCuff Pro",
                    "systolic" to systolic,
                    "diastolic" to diastolic,
                    "meanArterialPressure" to Math.round(map * 10.0) / 10.0,
                    "pulseRate" to pulse,
                    "irregularHeartbeat" to irregular,
                    "batteryLevel" to 87,
                    "signalQuality" to "OPTIMAL"
                )
            }
            "GLUCO_SENSE" -> {
                val glucoseMgDl = 108 + random.nextInt(-6, 8)
                val glucoseMmol = Math.round((glucoseMgDl / 18.0182) * 10.0) / 10.0
                val trend = when {
                    glucoseMgDl > 112 -> "RISING"
                    glucoseMgDl < 104 -> "FALLING"
                    else -> "STABLE"
                }
                val tir = 94.5 + (random.nextDouble(-1.0, 1.0))

                mapOf(
                    "timestamp" to now,
                    "sensorType" to "GLUCO_SENSE",
                    "deviceName" to "GlucoSense CGM",
                    "glucoseMgDl" to glucoseMgDl,
                    "glucoseMmolL" to glucoseMmol,
                    "trendArrow" to trend,
                    "timeInRangePercentage" to Math.round(tir * 10.0) / 10.0,
                    "sensorLifetimeDaysLeft" to 11,
                    "signalQuality" to "EXCELLENT"
                )
            }
            "OXY_PULSE" -> {
                val spO2 = 98 + random.nextInt(-1, 2)
                val pi = 4.2 + (random.nextDouble(-0.3, 0.4))
                val tempC = 36.8 + (random.nextDouble(-0.2, 0.3))
                val tempF = (tempC * 9.0 / 5.0) + 32.0

                val payload = "SPO2:$spO2;PI:${Math.round(pi * 10.0) / 10.0};TEMPC:${Math.round(tempC * 10.0) / 10.0};TIME:$now"
                val crc = CRC32()
                crc.update(payload.toByteArray())
                val checksum = crc.value.toString(16).uppercase()

                mapOf(
                    "timestamp" to now,
                    "sensorType" to "OXY_PULSE",
                    "deviceName" to "OxyPulse Clinical",
                    "oxygenSaturation" to spO2.coerceIn(95, 100),
                    "perfusionIndex" to Math.round(pi * 10.0) / 10.0,
                    "temperatureCelsius" to Math.round(tempC * 10.0) / 10.0,
                    "temperatureFahrenheit" to Math.round(tempF * 10.0) / 10.0,
                    "crc32Checksum" to checksum,
                    "signalQuality" to "NOMINAL"
                )
            }
            else -> mapOf("timestamp" to now, "sensorType" to "UNKNOWN")
        }
    }
}
