import 'package:flutter/material.dart';

import '../../../data/models/biomarker_model.dart';

class BiomarkerRangeBar extends StatelessWidget {
  final BiomarkerModel biomarker;

  const BiomarkerRangeBar({super.key, required this.biomarker});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final rangeSpan = biomarker.maxRange - biomarker.minRange;
    final totalSpan = rangeSpan > 0 ? rangeSpan * 1.5 : 1.0;
    final startRange = (biomarker.minRange - (rangeSpan * 0.25)).clamp(
      0.0,
      99999.0,
    );

    final ratio = ((biomarker.value - startRange) / totalSpan).clamp(
      0.05,
      0.95,
    );

    final isOptimal = biomarker.clinicalStatus == 'OPTIMAL';
    final statusColor = isOptimal ? colorScheme.primary : colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  biomarker.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  biomarker.clinicalStatus,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${biomarker.value}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                biomarker.unit,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ref: ${biomarker.minRange} - ${biomarker.maxRange} ${biomarker.unit}',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Interactive Visual Range Bar with Indicator Pin
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final pinPosition = (barWidth * ratio).clamp(0.0, barWidth - 12);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background reference track
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondary.withAlpha(80),
                          colorScheme.primary.withAlpha(180),
                          colorScheme.secondary.withAlpha(80),
                        ],
                      ),
                    ),
                  ),
                  // Current value indicator pin
                  Positioned(
                    left: pinPosition,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 16,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withAlpha(80),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (biomarker.interpretation != null) ...[
            const SizedBox(height: 8),
            Text(
              biomarker.interpretation!,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
