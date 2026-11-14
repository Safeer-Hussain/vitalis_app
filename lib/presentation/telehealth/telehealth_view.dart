import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_feedback.dart';
import '../../data/models/telehealth_appointment_model.dart';
import '../../data/models/telehealth_doctor_model.dart';
import 'telehealth_notifier.dart';
import 'widgets/active_appointment_tile.dart';
import 'widgets/book_appointment_modal.dart';
import 'widgets/simulated_consultation_sheet.dart';
import 'widgets/specialist_card.dart';

class TelehealthView extends ConsumerWidget {
  const TelehealthView({super.key});

  void _openBookingModal(BuildContext context, TelehealthDoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookAppointmentModal(doctor: doctor),
    );
  }

  void _joinCall(BuildContext context, TelehealthAppointmentModel appointment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SimulatedConsultationSheet(appointment: appointment),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(telehealthNotifierProvider);
    final notifier = ref.read(telehealthNotifierProvider.notifier);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final activeAppointments = state.appointments
        .where((a) => a.status == 'SCHEDULED')
        .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_telehealth_book',
        onPressed: () {
          if (state.allDoctors.isNotEmpty) {
            _openBookingModal(context, state.allDoctors.first);
          }
        },
        icon: const Icon(Icons.video_call_rounded),
        label: const Text('Book Specialist'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: isLandscape
                  ? _buildLandscapeLayout(
                      context,
                      ref,
                      state,
                      notifier,
                      activeAppointments,
                    )
                  : _buildPortraitLayout(
                      context,
                      ref,
                      state,
                      notifier,
                      activeAppointments,
                    ),
            ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    WidgetRef ref,
    TelehealthState state,
    TelehealthNotifier notifier,
    List<TelehealthAppointmentModel> activeAppointments,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildSearchBar(context, notifier),
        const SizedBox(height: 10),
        _buildSpecialtyChips(context, state, notifier),
        if (activeAppointments.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildActiveHeader(context, activeAppointments.length),
          const SizedBox(height: 8),
          ...activeAppointments.map(
            (apt) => ActiveAppointmentTile(
              appointment: apt,
              onJoinCall: () => _joinCall(context, apt),
              onCancel: () {
                notifier.cancelAppointment(apt.id);
                AppFeedback.showInfo(context, 'Appointment cancelled.');
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildDirectoryHeader(context, state.filteredDoctors.length),
        const SizedBox(height: 8),
        ...state.filteredDoctors.map(
          (doc) => SpecialistCard(
            doctor: doc,
            onBookTap: () => _openBookingModal(context, doc),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    WidgetRef ref,
    TelehealthState state,
    TelehealthNotifier notifier,
    List<TelehealthAppointmentModel> activeAppointments,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Pane: Filters & Active Appointments
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(context, notifier),
                const SizedBox(height: 10),
                _buildSpecialtyChips(context, state, notifier),
                const SizedBox(height: 16),
                _buildActiveHeader(context, activeAppointments.length),
                const SizedBox(height: 8),
                if (activeAppointments.isEmpty)
                  Text(
                    'No active telehealth visits scheduled today.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...activeAppointments.map(
                    (apt) => ActiveAppointmentTile(
                      appointment: apt,
                      onJoinCall: () => _joinCall(context, apt),
                      onCancel: () {
                        notifier.cancelAppointment(apt.id);
                        AppFeedback.showInfo(context, 'Appointment cancelled.');
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Right Pane: Specialist Directory
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDirectoryHeader(context, state.filteredDoctors.length),
                const SizedBox(height: 8),
                ...state.filteredDoctors.map(
                  (doc) => SpecialistCard(
                    doctor: doc,
                    onBookTap: () => _openBookingModal(context, doc),
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

  Widget _buildSearchBar(BuildContext context, TelehealthNotifier notifier) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search 20+ board-certified specialists...',
        prefixIcon: Icon(Icons.search_rounded),
        isDense: true,
      ),
      onChanged: (val) => notifier.setSearchQuery(val),
    );
  }

  Widget _buildSpecialtyChips(
    BuildContext context,
    TelehealthState state,
    TelehealthNotifier notifier,
  ) {
    final specialties = [
      'All',
      'Cardiology',
      'Endocrinology',
      'Internal Medicine',
      'Neurology',
      'Dermatology',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...specialties.map((spec) {
            final isSelected =
                (state.selectedSpecialty == null && spec == 'All') ||
                state.selectedSpecialty == spec;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(spec, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (_) {
                  notifier.setSpecialtyFilter(spec == 'All' ? null : spec);
                },
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          FilterChip(
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.today_rounded, size: 14),
                SizedBox(width: 4),
                Text('Today Only', style: TextStyle(fontSize: 11)),
              ],
            ),
            selected: state.onlyAvailableToday,
            onSelected: (val) => notifier.toggleAvailableToday(val),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveHeader(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.video_camera_front_rounded,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Active Telehealth Sessions ($count)',
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

  Widget _buildDirectoryHeader(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.medical_services_outlined,
          size: 18,
          color: colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Board-Certified Specialists ($count)',
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
