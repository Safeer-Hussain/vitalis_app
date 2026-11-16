import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/native_sensor_bridge.dart';
import '../../../core/utils/app_feedback.dart';
import '../vitals_notifier.dart';

class DevicePairingSheet extends ConsumerWidget {
  const DevicePairingSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final vitalsState = ref.watch(vitalsNotifierProvider);
    final vitalsNotifier = ref.read(vitalsNotifierProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bluetooth_searching_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Sensor Platform Bridge',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Native BLE GATT Telemetry Hub & Reconnection Policy',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Paired Devices Section
            Text(
              'ACTIVE CLINICAL SENSORS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            ...vitalsState.devices.map((device) {
              final isSelected =
                  vitalsState.selectedSensorType == device.type &&
                  device.connected &&
                  vitalsState.connectionStatus == 'CONNECTED';

              IconData icon = Icons.monitor_heart_outlined;
              if (device.type == 'GLUCO_SENSE') {
                icon = Icons.water_drop_outlined;
              } else if (device.type == 'OXY_PULSE') {
                icon = Icons.air_outlined;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isSelected
                      ? colorScheme.primaryContainer.withAlpha(50)
                      : colorScheme.surfaceContainer,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                device.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isSelected ? 'STREAMING' : 'IDLE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Model: ${device.model} • RSSI: ${device.rssi} dBm • Battery: ${device.batteryLevel}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        await vitalsNotifier.selectDevice(device.type);
                        if (context.mounted) {
                          AppFeedback.showSuccess(
                            context,
                            'Paired to ${device.name}. Live clinical telemetry streaming.',
                          );
                        }
                      },
                      child: Text(isSelected ? 'Active' : 'Pair'),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),
            // Sprint 23 BLE GATT Direct Peripheral Discovery
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.surfaceContainerLow,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DIRECT BLE GATT PERIPHERAL SCAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Filtered by Bluetooth SIG standard clinical service UUIDs',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (vitalsState.isScanningGatt)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      else
                        IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          onPressed: () => vitalsNotifier.scanGattPeripherals(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Service UUID Filter Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildUuidFilterChip(
                        context,
                        label: '0x180D (Heart Rate)',
                        uuid: NativeSensorBridge.uuidHeartRate,
                        isSelected: vitalsState.activeGattUuidFilters.contains(
                          NativeSensorBridge.uuidHeartRate,
                        ),
                        onToggle: () => vitalsNotifier.toggleGattUuidFilter(
                          NativeSensorBridge.uuidHeartRate,
                        ),
                      ),
                      _buildUuidFilterChip(
                        context,
                        label: '0x1810 (Blood Pressure)',
                        uuid: NativeSensorBridge.uuidBloodPressure,
                        isSelected: vitalsState.activeGattUuidFilters.contains(
                          NativeSensorBridge.uuidBloodPressure,
                        ),
                        onToggle: () => vitalsNotifier.toggleGattUuidFilter(
                          NativeSensorBridge.uuidBloodPressure,
                        ),
                      ),
                      _buildUuidFilterChip(
                        context,
                        label: '0x1808 (Glucose)',
                        uuid: NativeSensorBridge.uuidGlucose,
                        isSelected: vitalsState.activeGattUuidFilters.contains(
                          NativeSensorBridge.uuidGlucose,
                        ),
                        onToggle: () => vitalsNotifier.toggleGattUuidFilter(
                          NativeSensorBridge.uuidGlucose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Discovered GATT Devices List
                  if (vitalsState.gattPeripherals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No GATT peripherals discovered matching selected UUID filters.',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...vitalsState.gattPeripherals.map((gatt) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(
                            80,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.devices_other_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gatt.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'MAC: ${gatt.macAddress ?? 'N/A'} • RSSI: ${gatt.rssi} dBm',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: gatt.serviceUuids.map((uuid) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          uuid,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              onPressed: () async {
                                await vitalsNotifier.selectDevice(gatt.type);
                                if (context.mounted) {
                                  AppFeedback.showSuccess(
                                    context,
                                    'Connected to ${gatt.name} via BLE GATT peripheral.',
                                  );
                                }
                              },
                              child: const Text('Connect'),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Reconnect Policy & Background Telemetry Controls
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: colorScheme.surfaceContainer,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECONNECTION & BACKGROUND POLICIES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Exponential Backoff Auto-Reconnect',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Recovers dropped signals: 1s, 2s, 4s, 8s, up to 16s delay',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: vitalsState.autoReconnectEnabled,
                    onChanged: (val) => vitalsNotifier.toggleAutoReconnect(val),
                  ),
                  const Divider(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Background Telemetry Ingestion',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Android foreground service & notification for continuous vitals',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: vitalsState.backgroundTelemetryEnabled,
                    onChanged: (val) =>
                        vitalsNotifier.toggleBackgroundTelemetry(val),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () async {
                      await vitalsNotifier.simulateConnectionDrop();
                      if (context.mounted) {
                        AppFeedback.showWarning(
                          context,
                          'Simulated connection drop. Auto-reconnect backoff initiated.',
                        );
                      }
                    },
                    icon: const Icon(Icons.sync_problem_rounded, size: 16),
                    label: const Text('Simulate Drop & Exponential Recovery'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final cal = await vitalsNotifier.calibrateCurrentDevice();
                      if (context.mounted) {
                        AppFeedback.showSuccess(
                          context,
                          'Sensor Calibrated. Zero Offset: ${cal['zeroOffset']} mV',
                        );
                      }
                    },
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Calibrate Sensor'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withAlpha(120)),
                    ),
                    onPressed: () async {
                      await vitalsNotifier.disconnectCurrentDevice();
                      if (context.mounted) {
                        AppFeedback.showInfo(
                          context,
                          'Clinical sensor disconnected.',
                        );
                      }
                    },
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUuidFilterChip(
    BuildContext context, {
    required String label,
    required String uuid,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      selected: isSelected,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      checkmarkColor: colorScheme.onPrimaryContainer,
      onSelected: (_) => onToggle(),
    );
  }
}
