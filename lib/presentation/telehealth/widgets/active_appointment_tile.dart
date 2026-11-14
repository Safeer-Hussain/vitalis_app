import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/telehealth_appointment_model.dart';

class ActiveAppointmentTile extends StatelessWidget {
  final TelehealthAppointmentModel appointment;
  final VoidCallback onJoinCall;
  final VoidCallback onCancel;

  const ActiveAppointmentTile({
    super.key,
    required this.appointment,
    required this.onJoinCall,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('EEE, MMM d • h:mm a')
        .format(appointment.scheduledTime);
    final isCancelled = appointment.status == 'CANCELLED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCancelled
              ? colorScheme.outlineVariant
              : colorScheme.primary.withAlpha(100),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primaryContainer.withAlpha(90),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  appointment.consultationMode == 'VIDEO_CALL'
                      ? Icons.videocam_rounded
                      : Icons.local_hospital_rounded,
                  color: isCancelled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${appointment.specialty} • ${appointment.consultationMode == "VIDEO_CALL" ? "HD Tele-Video" : "In-Person Clinic"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? colorScheme.errorContainer.withAlpha(100)
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  appointment.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isCancelled
                        ? colorScheme.error
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (appointment.liveVitalSharing)
                Row(
                  children: [
                    Icon(
                      Icons.monitor_heart_rounded,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Vitals Stream Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (appointment.symptomNotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Complaint: ${appointment.symptomNotes}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (!isCancelled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onJoinCall,
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: const Text(
                      'Join Call Room',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error.withAlpha(120)),
                  ),
                  onPressed: onCancel,
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
