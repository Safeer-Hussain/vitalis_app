import 'package:flutter/material.dart';

import '../../../data/models/prescription_model.dart';

class PrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback onMarkDoseTaken;
  final VoidCallback onRequestRefill;

  const PrescriptionCard({
    super.key,
    required this.prescription,
    required this.onMarkDoseTaken,
    required this.onRequestRefill,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowStock = prescription.pillsRemaining <= 10;
    final isRefillRequested = prescription.refillStatus == 'REFILL_REQUESTED';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(90),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.medication_liquid_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescription.medicationName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${prescription.dosage} • ${prescription.frequency}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 1-Tap Mark Dose Taken Checkbox / Action
                IconButton(
                  tooltip: 'Mark Dose Taken',
                  icon: Icon(
                    prescription.isCompletedToday
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: prescription.isCompletedToday
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 26,
                  ),
                  onPressed: onMarkDoseTaken,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              prescription.instructions,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? colorScheme.errorContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isLowStock
                        ? 'Low: ${prescription.pillsRemaining} left'
                        : '${prescription.pillsRemaining}/${prescription.totalPills} pills',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isLowStock
                          ? colorScheme.error
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Today: ${prescription.dosesTakenToday}/${prescription.dailyTargetDoses}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isRefillRequested)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Refill Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber[800],
                      ),
                    ),
                  )
                else if (isLowStock)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onRequestRefill,
                    icon: const Icon(Icons.refresh_rounded, size: 12),
                    label: const Text('Refill', style: TextStyle(fontSize: 10)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
