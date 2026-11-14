import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/app_feedback.dart';
import 'vitals_notifier.dart';
import 'widgets/device_pairing_sheet.dart';
import 'widgets/live_telemetry_card.dart';
import 'widgets/log_manual_vital_modal.dart';
import 'widgets/vitals_trend_chart.dart';

class VitalsView extends ConsumerWidget {
  const VitalsView({super.key});

  void _openPairingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const DevicePairingSheet(),
    );
  }

  void _openLogManualModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LogManualVitalModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsState = ref.watch(vitalsNotifierProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_vitals_sync',
        onPressed: () => _openLogManualModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Vital'),
      ),
      body: vitalsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(vitalsNotifierProvider.notifier).refresh(),
              child: isLandscape
                  ? _buildLandscapeLayout(context, vitalsState)
                  : _buildPortraitLayout(context, vitalsState),
            ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, VitalsState state) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        LiveTelemetryCard(
          reading: state.currentTelemetry,
          selectedSensorType: state.selectedSensorType,
          onOpenPairingSheet: () => _openPairingSheet(context),
        ),
        const SizedBox(height: 12),
        VitalsTrendChart(vitals: state.historicalVitals),
        const SizedBox(height: 12),
        _buildHistoricalLogsHeader(context),
        const SizedBox(height: 8),
        ...state.historicalVitals
            .take(6)
            .map((v) => _buildVitalHistoryTile(context, v)),
        const SizedBox(height: 80), // Fab clearance
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, VitalsState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Pane (Telemetry & Device status)
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LiveTelemetryCard(
                  reading: state.currentTelemetry,
                  selectedSensorType: state.selectedSensorType,
                  onOpenPairingSheet: () => _openPairingSheet(context),
                ),
                const SizedBox(height: 12),
                _buildHistoricalLogsHeader(context),
                const SizedBox(height: 8),
                ...state.historicalVitals
                    .take(4)
                    .map((v) => _buildVitalHistoryTile(context, v)),
              ],
            ),
          ),
        ),
        // Right Pane (14-Day Charts & Metrics)
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VitalsTrendChart(vitals: state.historicalVitals),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalLogsHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.history_rounded, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Telemetry History & Clinical Log',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalHistoryTile(BuildContext context, dynamic vital) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('MMM d, h:mm a').format(vital.timestamp);

    String metricsText = '';
    if (vital.systolic != null) {
      metricsText += 'BP: ${vital.systolic}/${vital.diastolic} mmHg ';
    }
    if (vital.glucoseMgDl != null) {
      metricsText += 'Gluc: ${vital.glucoseMgDl} mg/dL ';
    }
    if (vital.oxygenSaturation != null) {
      metricsText += 'SpO2: ${vital.oxygenSaturation}% ';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              vital.sensorType == 'MANUAL'
                  ? Icons.edit_note_rounded
                  : Icons.sensors_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metricsText.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$timeStr • ${vital.sensorType} • ${vital.notes ?? "Verified"}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            onPressed: () {
              AppFeedback.showInfo(
                context,
                'Packet Checksum: ${vital.crc32Checksum ?? "N/A"} | MAP: ${vital.meanArterialPressure ?? "N/A"} mmHg',
              );
            },
          ),
        ],
      ),
    );
  }
}
