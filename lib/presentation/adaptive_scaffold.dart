import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/network_info.dart';
import '../core/theme/theme_mode_provider.dart';
import '../core/utils/app_feedback.dart';
import 'ai_triage/ai_triage_view.dart';
import 'labs/labs_view.dart';
import 'prescriptions/prescriptions_view.dart';
import 'settings/recruiter_debug_drawer.dart';
import 'settings/settings_view.dart';
import 'telehealth/telehealth_view.dart';
import 'vitals/vitals_view.dart';

class AdaptiveScaffold extends ConsumerStatefulWidget {
  const AdaptiveScaffold({super.key});

  @override
  ConsumerState<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends ConsumerState<AdaptiveScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _destinations = const [
    VitalsView(),
    TelehealthView(),
    LabsView(),
    PrescriptionsView(),
    AiClinicalTriageView(),
  ];

  final List<String> _titles = const [
    'Clinical Vitals Cockpit',
    'Telemedicine Specialist Hub',
    'Lab Diagnostics & Biomarkers',
    'Prescriptions & Adherence',
    'AI Clinical Triage Companion',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isOnlineAsync = ref.watch(isOnlineStreamProvider);
    final isOnline = isOnlineAsync.value ?? true;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: const RecruiterDebugDrawer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isLandscape ? 36.0 : 56.0),
          child: AppBar(
            toolbarHeight: isLandscape ? 36.0 : 56.0,
            title: Row(
              children: [
                GestureDetector(
                  onLongPress: () {
                    AppFeedback.showInfo(
                      context,
                      'Opening Recruiter Debug Console...',
                    );
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                  child: Row(
                    children: [
                      Container(
                        width: isLandscape ? 20 : 28,
                        height: isLandscape ? 20 : 28,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.local_hospital_rounded,
                          size: isLandscape ? 14 : 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'VITALIS',
                        style: TextStyle(
                          fontSize: isLandscape ? 12 : 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: isLandscape ? 16 : 22,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _titles[_currentIndex],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isLandscape ? 11 : 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: isLandscape ? 18 : 22,
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                tooltip: 'Toggle Obsidian Dark / Sterile Light Theme',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: isLandscape ? 18 : 22,
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings & Recruiter Debug',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsView()),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Animated Offline Banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isOnline ? 0 : 32,
              color: colorScheme.errorContainer,
              child: isOnline
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 14,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Offline Clinical Vault - Syncing Vitals & Prescriptions to Local SQLite',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
            ),
            // Body with Landscape Rail or Portrait Full View
            Expanded(
              child: isLandscape
                  ? Row(
                      children: [
                        // Compact Landscape Navigation Rail (Safe on 360dp height)
                        SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              minWidth: 56,
                              selectedIndex: _currentIndex,
                              labelType: NavigationRailLabelType.none,
                              backgroundColor: colorScheme.surfaceContainer,
                              destinations: const [
                                NavigationRailDestination(
                                  icon: Icon(Icons.monitor_heart_outlined),
                                  selectedIcon: Icon(
                                    Icons.monitor_heart_rounded,
                                  ),
                                  label: Text('Vitals'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.video_call_outlined),
                                  selectedIcon: Icon(Icons.video_call_rounded),
                                  label: Text('Telehealth'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.biotech_outlined),
                                  selectedIcon: Icon(Icons.biotech_rounded),
                                  label: Text('Labs'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.medication_outlined),
                                  selectedIcon: Icon(Icons.medication_rounded),
                                  label: Text('Rx'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.auto_awesome_outlined),
                                  selectedIcon: Icon(
                                    Icons.auto_awesome_rounded,
                                  ),
                                  label: Text('AI Triage'),
                                ),
                              ],
                              onDestinationSelected: (index) {
                                setState(() => _currentIndex = index);
                              },
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        // Main content
                        Expanded(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: _destinations,
                          ),
                        ),
                      ],
                    )
                  : IndexedStack(index: _currentIndex, children: _destinations),
            ),
          ],
        ),
        bottomNavigationBar: isLandscape
            ? null
            : NavigationBar(
                selectedIndex: _currentIndex,
                backgroundColor: colorScheme.surfaceContainer,
                elevation: 3,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.monitor_heart_outlined),
                    selectedIcon: Icon(Icons.monitor_heart_rounded),
                    label: 'Vitals',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.video_call_outlined),
                    selectedIcon: Icon(Icons.video_call_rounded),
                    label: 'Telehealth',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.biotech_outlined),
                    selectedIcon: Icon(Icons.biotech_rounded),
                    label: 'Labs',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.medication_outlined),
                    selectedIcon: Icon(Icons.medication_rounded),
                    label: 'Rx',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome_rounded),
                    label: 'AI Triage',
                  ),
                ],
                onDestinationSelected: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
      ),
    );
  }
}
