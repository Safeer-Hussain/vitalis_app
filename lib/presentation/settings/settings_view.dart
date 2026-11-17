import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/app_feedback.dart';
import '../fhir/widgets/fhir_export_modal.dart';
import 'emergency_ice_modal.dart';
import 'recruiter_debug_drawer.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Settings & System')),
      endDrawer: const RecruiterDebugDrawer(),
      body: Builder(
        builder: (innerContext) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Appearance & Visual Theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Obsidian Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Sterile Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setTheme(newSelection.first);
                          AppFeedback.showSuccess(
                            context,
                            newSelection.first == ThemeMode.dark
                                ? 'Switched to Obsidian Clinical Dark Mode'
                                : 'Switched to Crisp Sterile Light Mode',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.emergency_rounded,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  title: const Text(
                    'Emergency ICE Medical ID',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Blood group, chronic conditions, allergy notes & contact',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => const EmergencyIceModal(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: const Text(
                    'FHIR R4 Clinical Interoperability Hub',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Export cryptographically sealed HL7 FHIR bundles (LOINC & RxNorm)',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const FhirExportModal(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.security_rounded,
                        color: colorScheme.secondary,
                      ),
                      title: const Text(
                        'Encrypted Local SQLite Vault',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Zero external cloud dependency. All clinical records stay on device.',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'OFFLINE ENCRYPTED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.bug_report_outlined,
                        color: colorScheme.tertiary,
                      ),
                      title: const Text(
                        'Recruiter Debug Drawer',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Toggle simulated latency, force 503 errors & abnormal vital spikes',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Scaffold.of(innerContext).openEndDrawer();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onLongPress: () {
                    AppFeedback.showInfo(
                      context,
                      'Opening Recruiter Debug Console...',
                    );
                    Scaffold.of(innerContext).openEndDrawer();
                  },
                  child: Column(
                    children: [
                      Text(
                        'Vitalis Mobile Health Platform',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0+1 (Android SDK 36 Compliant)',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tip: Long-press version to open Recruiter Debug Drawer',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.primary.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
