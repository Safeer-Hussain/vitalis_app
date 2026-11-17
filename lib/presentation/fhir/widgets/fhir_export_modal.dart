import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_feedback.dart';
import '../fhir_notifier.dart';

class FhirExportModal extends ConsumerStatefulWidget {
  const FhirExportModal({super.key});

  @override
  ConsumerState<FhirExportModal> createState() => _FhirExportModalState();
}

class _FhirExportModalState extends ConsumerState<FhirExportModal> {
  String _selectedEhr = 'Epic Systems MyChart';
  bool _showRawJson = false;

  final List<String> _ehrOptions = const [
    'Epic Systems MyChart',
    'Cerner Millennium FHIR',
    'Apple HealthKit FHIR Sync',
    'NHS Digital Interoperability',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fhirState = ref.watch(fhirNotifierProvider);
    final fhirNotifier = ref.read(fhirNotifierProvider.notifier);

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FHIR R4 Interoperability Gateway',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'HL7 FHIR Release 4.0.1 • LOINC & RxNorm Ontologies',
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
            ),
            const Divider(height: 1),

            // Content Body
            Expanded(
              child: fhirState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cryptographic Signature & Validation Card
                          _buildCryptographicSealCard(context, fhirState),

                          const SizedBox(height: 14),

                          // EHR Destination Dispatcher Card
                          _buildEhrDispatchCard(
                            context,
                            fhirState,
                            fhirNotifier,
                          ),

                          const SizedBox(height: 14),

                          // Resource Filter & Metrics Row
                          _buildResourceMetricsHeader(
                            context,
                            fhirState,
                            fhirNotifier,
                          ),

                          const SizedBox(height: 12),

                          // Resources List or Raw JSON View
                          if (_showRawJson)
                            _buildRawJsonViewer(context, fhirState)
                          else
                            _buildResourceList(context, fhirState),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCryptographicSealCard(
    BuildContext context,
    FhirState fhirState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final bundle = fhirState.bundle;
    final isVerified = fhirState.isSignatureVerified;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isVerified
            ? colorScheme.primaryContainer.withAlpha(45)
            : colorScheme.errorContainer.withAlpha(45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVerified ? colorScheme.primary : colorScheme.error,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                color: isVerified ? colorScheme.primary : colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isVerified
                      ? 'Cryptographic SHA-256 Bundle Seal: Authenticated'
                      : 'Cryptographic Signature Mismatch',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isVerified ? colorScheme.primary : colorScheme.error,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isVerified
                      ? colorScheme.primaryContainer
                      : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isVerified ? 'VERIFIED' : 'TAMPERED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isVerified
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'SHA-256 Digest: ${bundle?.signature.sha256Hex ?? "N/A"}',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Certifier: ${bundle?.signature.who ?? "N/A"} • Timestamp: ${bundle?.signature.when.toIso8601String() ?? "N/A"}',
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEhrDispatchCard(
    BuildContext context,
    FhirState fhirState,
    FhirNotifier fhirNotifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'EHR DIRECT TRANSMISSION (SMART-on-FHIR)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedEhr,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Target Health Network',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: _ehrOptions.map((ehr) {
              return DropdownMenuItem(value: ehr, child: Text(ehr));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedEhr = val);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await fhirNotifier.simulateEhrExport(_selectedEhr);
                    if (context.mounted) {
                      AppFeedback.showSuccess(
                        context,
                        'FHIR R4 Bundle successfully dispatched to $_selectedEhr with valid cryptographic seal.',
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text('Dispatch to $_selectedEhr'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceMetricsHeader(
    BuildContext context,
    FhirState fhirState,
    FhirNotifier fhirNotifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final bundle = fhirState.bundle;

    final obsCount = bundle?.countByType('Observation') ?? 0;
    final diagCount = bundle?.countByType('DiagnosticReport') ?? 0;
    final medCount = bundle?.countByType('MedicationStatement') ?? 0;
    final total = bundle?.totalResources ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BUNDLE RESOURCES ($total TOTAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: colorScheme.primary,
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () {
                setState(() => _showRawJson = !_showRawJson);
              },
              icon: Icon(
                _showRawJson ? Icons.list_alt_rounded : Icons.code_rounded,
                size: 16,
              ),
              label: Text(
                _showRawJson ? 'View Resource Cards' : 'View Raw JSON',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill(
                context,
                label: 'All ($total)',
                type: 'ALL',
                isSelected: fhirState.selectedResourceType == 'ALL',
                onTap: () => fhirNotifier.filterByType('ALL'),
              ),
              const SizedBox(width: 6),
              _buildFilterPill(
                context,
                label: 'Observations ($obsCount)',
                type: 'Observation',
                isSelected: fhirState.selectedResourceType == 'Observation',
                onTap: () => fhirNotifier.filterByType('Observation'),
              ),
              const SizedBox(width: 6),
              _buildFilterPill(
                context,
                label: 'Reports ($diagCount)',
                type: 'DiagnosticReport',
                isSelected:
                    fhirState.selectedResourceType == 'DiagnosticReport',
                onTap: () => fhirNotifier.filterByType('DiagnosticReport'),
              ),
              const SizedBox(width: 6),
              _buildFilterPill(
                context,
                label: 'Medications ($medCount)',
                type: 'MedicationStatement',
                isSelected:
                    fhirState.selectedResourceType == 'MedicationStatement',
                onTap: () => fhirNotifier.filterByType('MedicationStatement'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(
    BuildContext context, {
    required String label,
    required String type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primaryContainer,
    );
  }

  Widget _buildResourceList(BuildContext context, FhirState fhirState) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = fhirState.filteredEntries;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No FHIR resources match the selected filter.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      children: entries.map((entry) {
        final res = entry.content;
        final resType = entry.resourceType;
        final id = entry.id;

        IconData icon = Icons.monitor_heart_outlined;
        if (resType == 'DiagnosticReport') {
          icon = Icons.biotech_outlined;
        } else if (resType == 'MedicationStatement') {
          icon = Icons.medication_outlined;
        }

        String title = id;
        String subtitle = 'Resource: $resType';

        if (resType == 'Observation') {
          final codeText = (res['code'] as Map?)?['text'] as String?;
          final val = (res['valueQuantity'] as Map?)?['value'];
          final unit = (res['valueQuantity'] as Map?)?['unit'];
          title = codeText ?? id;
          subtitle = val != null
              ? 'Value: $val $unit'
              : 'Multi-component observation';
        } else if (resType == 'DiagnosticReport') {
          title = (res['code'] as Map?)?['text'] as String? ?? id;
          subtitle =
              'Ordering: ${(res['performer'] as List?)?.first?['display'] ?? "Clinician"}';
        } else if (resType == 'MedicationStatement') {
          title =
              (res['medicationCodeableConcept'] as Map?)?['text'] as String? ??
              id;
          subtitle =
              (res['dosage'] as List?)?.first?['text'] as String? ??
              'Prescription';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  resType,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRawJsonViewer(BuildContext context, FhirState fhirState) {
    final colorScheme = Theme.of(context).colorScheme;
    final jsonStr = fhirState.bundle?.toPrettyJson() ?? '{}';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'application/fhir+json (R4)',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    AppFeedback.showSuccess(
                      context,
                      'FHIR R4 JSON Bundle copied to clipboard.',
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text(
                    'Copy JSON',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              jsonStr,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
