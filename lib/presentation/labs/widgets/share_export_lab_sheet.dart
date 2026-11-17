import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/lab_report_model.dart';
import '../../fhir/widgets/fhir_export_modal.dart';
import '../labs_notifier.dart';

class ShareExportLabSheet extends ConsumerWidget {
  final LabReportModel report;

  const ShareExportLabSheet({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final labsNotifier = ref.read(labsNotifierProvider.notifier);

    final summary = labsNotifier.generateFormattedSummary(report);
    final hl7Json = labsNotifier.generateHl7JsonSnapshot(report);

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
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.share_rounded,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share / Export Diagnostic Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        report.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
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
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: summary));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  AppFeedback.showSuccess(
                    context,
                    'Formatted clinical diagnostic summary copied to clipboard.',
                  );
                }
              },
              icon: const Icon(Icons.copy_all_rounded),
              label: const Text('Copy Formatted Clinical Summary'),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).pop();
                AppFeedback.showSuccess(
                  context,
                  'Encrypted lab report transmitted to ${report.orderingPhysician}.',
                );
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Share Directly with Specialist'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const FhirExportModal(),
                );
              },
              icon: const Icon(Icons.sync_alt_rounded),
              label: const Text('Open Full FHIR R4 Bundle Gateway'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: hl7Json));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  AppFeedback.showSuccess(
                    context,
                    'HL7/FHIR DiagnosticReport JSON snapshot exported & copied.',
                  );
                }
              },
              icon: const Icon(Icons.code_rounded),
              label: const Text('Export HL7/FHIR JSON Snapshot'),
            ),
            const SizedBox(height: 16),
            Text(
              'HL7/FHIR JSON PREVIEW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  hl7Json,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
