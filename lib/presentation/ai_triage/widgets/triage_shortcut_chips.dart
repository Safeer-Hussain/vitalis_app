import 'package:flutter/material.dart';

class TriageShortcutChips extends StatelessWidget {
  final ValueChanged<String> onShortcutTap;
  final bool isStreaming;

  const TriageShortcutChips({
    super.key,
    required this.onShortcutTap,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      {
        'label': 'Analyze My Latest Lab Biomarker Trends',
        'icon': Icons.biotech_outlined,
      },
      {
        'label': 'Check Active Prescriptions for Interactions',
        'icon': Icons.medication_outlined,
      },
      {
        'label': 'Prepare Pre-Consultation Summary for My Doctor',
        'icon': Icons.assignment_outlined,
      },
      {
        'label': "Evaluate Today's Blood Pressure & Glucose",
        'icon': Icons.monitor_heart_outlined,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: shortcuts.map((s) {
          final label = s['label'] as String;
          final icon = s['icon'] as IconData;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: Icon(icon, size: 14),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: isStreaming ? null : () => onShortcutTap(label),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}
