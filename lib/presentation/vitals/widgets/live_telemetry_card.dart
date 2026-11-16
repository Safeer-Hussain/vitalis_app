import 'package:flutter/material.dart';

import '../../../data/models/vital_reading_model.dart';

class LiveTelemetryCard extends StatelessWidget {
  final VitalReadingModel? reading;
  final String selectedSensorType;
  final String connectionStatus;
  final VoidCallback onOpenPairingSheet;

  const LiveTelemetryCard({
    super.key,
    required this.reading,
    required this.selectedSensorType,
    this.connectionStatus = 'CONNECTED',
    required this.onOpenPairingSheet,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String sensorTitle = 'CardioCuff Pro BLE';
    IconData sensorIcon = Icons.monitor_heart_outlined;
    if (selectedSensorType == 'GLUCO_SENSE') {
      sensorTitle = 'GlucoSense Continuous CGM';
      sensorIcon = Icons.water_drop_outlined;
    } else if (selectedSensorType == 'OXY_PULSE') {
      sensorTitle = 'OxyPulse Clinical SpO2';
      sensorIcon = Icons.air_outlined;
    }

    final isAbnormal =
        (reading?.systolic != null && reading!.systolic! > 140) ||
        (reading?.glucoseMgDl != null && reading!.glucoseMgDl! > 180) ||
        (reading?.oxygenSaturation != null &&
            reading!.oxygenSaturation! < 94) ||
        (reading?.irregularHeartbeat ?? false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAbnormal
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    sensorIcon,
                    color: isAbnormal ? colorScheme.error : colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensorTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: connectionStatus == 'CONNECTED'
                                  ? colorScheme.primary
                                  : (connectionStatus == 'RECONNECTING'
                                        ? colorScheme.error
                                        : colorScheme.outline),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              connectionStatus == 'CONNECTED'
                                  ? 'Live Native Telemetry (2s interval)'
                                  : (connectionStatus == 'RECONNECTING'
                                        ? 'Reconnecting (Backoff Active)...'
                                        : 'Sensor Disconnected'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenPairingSheet,
                  icon: const Icon(Icons.sensors_rounded, size: 16),
                  label: const Text('Sensors', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (connectionStatus == 'RECONNECTING') ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reconnecting: Exponential backoff recovery in progress...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isAbnormal) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.onErrorContainer,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention Needed: Physiological Parameter Spike Detected',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _buildTelemetryDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedSensorType == 'CARDIO_CUFF') {
      final sys = reading?.systolic ?? 120;
      final dia = reading?.diastolic ?? 80;
      final map = reading?.meanArterialPressure ?? 93.3;
      final pulse = reading?.pulseRate ?? 72;
      final irregular = reading?.irregularHeartbeat ?? false;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildMetricColumn(
              context,
              label: 'BP',
              value: '$sys/$dia',
              unit: 'mmHg',
              status: sys < 130
                  ? 'Optimal'
                  : (sys < 140 ? 'Elevated' : 'Attention'),
              isAlert: sys >= 140,
            ),
          ),
          Container(width: 1, height: 48, color: colorScheme.outlineVariant),
          Expanded(
            child: _buildMetricColumn(
              context,
              label: 'MAP',
              value: '$map',
              unit: 'mmHg',
              status: 'Normal',
              isAlert: false,
            ),
          ),
          Container(width: 1, height: 48, color: colorScheme.outlineVariant),
          Expanded(
            child: _buildMetricColumn(
              context,
              label: 'PULSE',
              value: '$pulse',
              unit: 'bpm',
              status: irregular ? 'Arrhythmia' : 'Sinus',
              isAlert: irregular || pulse > 100,
            ),
          ),
        ],
      );
    } else if (selectedSensorType == 'GLUCO_SENSE') {
      final mgdl = reading?.glucoseMgDl ?? 108;
      final mmol = reading?.glucoseMmolL ?? 6.0;
      final trend = reading?.trendArrow ?? 'STABLE';

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildMetricColumn(
              context,
              label: 'GLUCOSE',
              value: '$mgdl',
              unit: 'mg/dL',
              status: mgdl < 140 ? 'In-Range' : 'High',
              isAlert: mgdl >= 180,
            ),
          ),
          Container(width: 1, height: 48, color: colorScheme.outlineVariant),
          Expanded(
            child: _buildMetricColumn(
              context,
              label: 'SI UNITS',
              value: '$mmol',
              unit: 'mmol/L',
              status: 'Fasting',
              isAlert: false,
            ),
          ),
          Container(width: 1, height: 48, color: colorScheme.outlineVariant),
          Expanded(
            child: _buildMetricColumn(
              context,
              label: 'TREND',
              value: trend,
              unit: 'Trend',
              status: trend == 'STABLE' ? 'Steady' : 'Shift',
              isAlert: trend == 'RISING' && mgdl > 140,
            ),
          ),
        ],
      );
    } else {
      final spo2 = reading?.oxygenSaturation ?? 98;
      final tempC = reading?.temperatureCelsius ?? 36.8;
      final tempF = reading?.temperatureFahrenheit ?? 98.2;
      final pi = reading?.perfusionIndex ?? 4.2;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildMetricColumn(
              context,
              label: 'SPO2',
              value: '$spo2',
              unit: '%',
              status: spo2 >= 95 ? 'Optimal' : 'Low',
              isAlert: spo2 < 95,
            ),
          ),
          Container(width: 1, height: 48, color: colorScheme.outlineVariant),
          Expanded(
            child: _buildMetricColumn(
              context,
              label: 'CORE TEMP',
              value: '$tempC°C',
              unit: '$tempF°F',
              status: tempC <= 37.5 ? 'Afebrile' : 'Pyrexia',
              isAlert: tempC > 37.8,
            ),
          ),
          Container(width: 1, height: 48, color: colorScheme.outlineVariant),
          Expanded(
            child: _buildMetricColumn(
              context,
              label: 'PERFUSION',
              value: '$pi',
              unit: 'PI %',
              status: 'OK',
              isAlert: false,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildMetricColumn(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required String status,
    required bool isAlert,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isAlert ? colorScheme.error : colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isAlert
                ? colorScheme.errorContainer
                : colorScheme.primaryContainer.withAlpha(90),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isAlert
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
