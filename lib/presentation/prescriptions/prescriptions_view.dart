import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_feedback.dart';
import '../../data/models/prescription_model.dart';
import 'prescriptions_notifier.dart';
import 'widgets/adherence_ring_widget.dart';
import 'widgets/add_prescription_modal.dart';
import 'widgets/prescription_card.dart';
import 'widgets/request_refill_sheet.dart';

class PrescriptionsView extends ConsumerWidget {
  const PrescriptionsView({super.key});

  void _openAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddPrescriptionModal(),
    );
  }

  void _openRefillSheet(BuildContext context, PrescriptionModel prescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RequestRefillSheet(prescription: prescription),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prescriptionsNotifierProvider);
    final notifier = ref.read(prescriptionsNotifierProvider.notifier);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_rx_add_med',
        onPressed: () => _openAddModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Rx'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: isLandscape
                  ? _buildLandscapeLayout(context, state, notifier)
                  : _buildPortraitLayout(context, state, notifier),
            ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    PrescriptionsState state,
    PrescriptionsNotifier notifier,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        AdherenceRingWidget(
          adherenceRatio: state.overallAdherence,
          totalPills: state.totalRemainingPills,
        ),
        const SizedBox(height: 16),
        _buildRxHeader(context, state.prescriptions.length),
        const SizedBox(height: 8),
        ...state.prescriptions.map(
          (rx) => PrescriptionCard(
            prescription: rx,
            onMarkDoseTaken: () async {
              await notifier.markDoseTaken(rx.id);
              if (context.mounted) {
                AppFeedback.showSuccess(
                  context,
                  'Dose recorded for ${rx.medicationName}. Remaining: ${(rx.pillsRemaining - 1).clamp(0, 999)} pills.',
                );
              }
            },
            onRequestRefill: () => _openRefillSheet(context, rx),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    PrescriptionsState state,
    PrescriptionsNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Pane: Adherence ring & Summary
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdherenceRingWidget(
                  adherenceRatio: state.overallAdherence,
                  totalPills: state.totalRemainingPills,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medication Adherence Protocol',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tracking active prescriptions against prescribed dosing windows. SQLite updates immediately upon checkbox tap.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Pane: Active Medications List
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRxHeader(context, state.prescriptions.length),
                const SizedBox(height: 8),
                ...state.prescriptions.map(
                  (rx) => PrescriptionCard(
                    prescription: rx,
                    onMarkDoseTaken: () async {
                      await notifier.markDoseTaken(rx.id);
                      if (context.mounted) {
                        AppFeedback.showSuccess(
                          context,
                          'Dose recorded for ${rx.medicationName}. Remaining: ${(rx.pillsRemaining - 1).clamp(0, 999)} pills.',
                        );
                      }
                    },
                    onRequestRefill: () => _openRefillSheet(context, rx),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRxHeader(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.medication_outlined, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Active Clinical Prescriptions ($count)',
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
}
