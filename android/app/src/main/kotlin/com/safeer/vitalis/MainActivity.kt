package com.safeer.vitalis

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
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

    // Standard Bluetooth SIG Clinical Service UUIDs
    private val UUID_HEART_RATE = "0x180D"
    private val UUID_BLOOD_PRESSURE = "0x1810"
    private val UUID_GLUCOSE = "0x1808"

    private var selectedSensorType = "CARDIO_CUFF"
    private var isPaired = true
    private var telemetryHandler: Handler? = null
    private var telemetryRunnable: Runnable? = null
    private var eventSink: EventChannel.EventSink? = null

    // Sprint 23 BLE GATT Direct Peripheral & Reconnect state
    private var autoReconnectEnabled = true
    private var backgroundTelemetryEnabled = false
    private var connectionStatus = "CONNECTED"
    private var reconnectAttempt = 0
    private val maxReconnectAttempts = 5
    private var currentBackoffMs = 1000L
    private val reconnectHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannelIfNeeded()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanClinicalSensors" -> {
                    val devices = getDiscoveredSensors()
                    result.success(devices)
                }
                "scanGattPeripherals" -> {
                    val requestedUuids = call.argument<List<String>>("serviceUuids") 
                        ?: listOf(UUID_HEART_RATE, UUID_BLOOD_PRESSURE, UUID_GLUCOSE)
                    val gattPeripherals = getGattPeripherals(requestedUuids)
                    result.success(gattPeripherals)
                }
                "pairMedicalDevice" -> {
                    val sensorType = call.argument<String>("sensorType") ?: "CARDIO_CUFF"
                    selectedSensorType = sensorType
                    isPaired = true
                    connectionStatus = "CONNECTED"
                    reconnectAttempt = 0
                    currentBackoffMs = 1000L
                    result.success(true)
                }
                "disconnectDevice" -> {
                    isPaired = false
                    connectionStatus = "DISCONNECTED"
                    reconnectHandler.removeCallbacksAndMessages(null)
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
                "enableAutoReconnect" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    autoReconnectEnabled = enabled
                    result.success(true)
                }
                "toggleBackgroundTelemetry" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    backgroundTelemetryEnabled = enabled
                    result.success(true)
                }
                "getConnectionState" -> {
                    val state = mapOf(
                        "connectionStatus" to connectionStatus,
                        "autoReconnectEnabled" to autoReconnectEnabled,
                        "backgroundTelemetryEnabled" to backgroundTelemetryEnabled,
                        "reconnectAttempt" to reconnectAttempt,
                        "maxReconnectAttempts" to maxReconnectAttempts,
                        "currentBackoffMs" to currentBackoffMs
                    )
                    result.success(state)
                }
                "simulateConnectionDrop" -> {
                    if (isPaired && autoReconnectEnabled) {
                        handleSimulatedConnectionDrop()
                    }
                    result.success(true)
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

    private fun getDiscoveredSensors(): List<Map<String, Any>> {
        return listOf(
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
    }

    private fun getGattPeripherals(filterUuids: List<String>): List<Map<String, Any>> {
        val allGattDevices = listOf(
            mapOf(
                "id" to "GATT-CC-8821",
                "name" to "CardioCuff Pro BLE-GATT",
                "model" to "CC-PRO-GATT-V3",
                "type" to "CARDIO_CUFF",
                "macAddress" to "C4:D3:58:AA:11:42",
                "batteryLevel" to 92,
                "rssi" to -52,
                "serviceUuids" to listOf(UUID_BLOOD_PRESSURE, UUID_HEART_RATE),
                "isGattDevice" to true,
                "connectionStatus" to (if (selectedSensorType == "CARDIO_CUFF" && isPaired) connectionStatus else "DISCONNECTED")
            ),
            mapOf(
                "id" to "GATT-GS-4190",
                "name" to "GlucoSense CGM Direct",
                "model" to "GS-CGM-DIRECT-X",
                "type" to "GLUCO_SENSE",
                "macAddress" to "E1:8B:22:90:3F:8A",
                "batteryLevel" to 96,
                "rssi" to -46,
                "serviceUuids" to listOf(UUID_GLUCOSE),
                "isGattDevice" to true,
                "connectionStatus" to (if (selectedSensorType == "GLUCO_SENSE" && isPaired) connectionStatus else "DISCONNECTED")
            ),
            mapOf(
                "id" to "GATT-OP-7734",
                "name" to "OxyPulse Clinical Wireless",
                "model" to "OP-CLIN-GATT-2",
                "type" to "OXY_PULSE",
                "macAddress" to "F0:24:6D:77:C8:19",
                "batteryLevel" to 81,
                "rssi" to -59,
                "serviceUuids" to listOf(UUID_HEART_RATE),
                "isGattDevice" to true,
                "connectionStatus" to (if (selectedSensorType == "OXY_PULSE" && isPaired) connectionStatus else "DISCONNECTED")
            )
        )

        val normalizedFilters = filterUuids.map { it.uppercase() }
        return allGattDevices.filter { device ->
            val services = (device["serviceUuids"] as? List<*>)?.map { it.toString().uppercase() } ?: emptyList()
            services.any { s -> normalizedFilters.contains(s) }
        }
    }

    private fun handleSimulatedConnectionDrop() {
        connectionStatus = "RECONNECTING"
        reconnectAttempt = 1
        currentBackoffMs = 1000L
        scheduleReconnectAttempt()
    }

    private fun scheduleReconnectAttempt() {
        if (!autoReconnectEnabled || reconnectAttempt > maxReconnectAttempts) {
            connectionStatus = "DISCONNECTED"
            return
        }

        reconnectHandler.postDelayed({
            if (reconnectAttempt >= 3) {
                // Recovered connection after backoff iterations
                connectionStatus = "CONNECTED"
                reconnectAttempt = 0
                currentBackoffMs = 1000L
            } else {
                reconnectAttempt++
                currentBackoffMs = (currentBackoffMs * 2L).coerceAtMost(16000L)
                scheduleReconnectAttempt()
            }
        }, currentBackoffMs)
    }

    private fun createNotificationChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "vitalis_clinical_telemetry"
            val channelName = "Vitalis Clinical Telemetry Channel"
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Ongoing telemetry bridge connection for vital signs monitoring"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startTelemetryStream() {
        stopTelemetryStream()
        telemetryHandler = Handler(Looper.getMainLooper())
        telemetryRunnable = object : Runnable {
            override fun run() {
                if (isPaired && connectionStatus == "CONNECTED" && eventSink != null) {
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
                    "signalQuality" to "OPTIMAL",
                    "connectionStatus" to connectionStatus,
                    "autoReconnectActive" to autoReconnectEnabled
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
                    "signalQuality" to "EXCELLENT",
                    "connectionStatus" to connectionStatus,
                    "autoReconnectActive" to autoReconnectEnabled
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
                    "signalQuality" to "NOMINAL",
                    "connectionStatus" to connectionStatus,
                    "autoReconnectActive" to autoReconnectEnabled
                )
            }
            else -> mapOf("timestamp" to now, "sensorType" to "UNKNOWN")
        }
    }
}
