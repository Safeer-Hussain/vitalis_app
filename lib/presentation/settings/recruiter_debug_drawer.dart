import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/mock_clinical_interceptor.dart';
import '../../core/utils/app_feedback.dart';
import '../vitals/vitals_notifier.dart';

class RecruiterDebugDrawer extends ConsumerStatefulWidget {
  const RecruiterDebugDrawer({super.key});

  @override
  ConsumerState<RecruiterDebugDrawer> createState() =>
      _RecruiterDebugDrawerState();
}

class _RecruiterDebugDrawerState extends ConsumerState<RecruiterDebugDrawer> {
  bool _simulatedLatency = true;
  bool _forceHttp503 = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebugSettings();
  }

  Future<void> _loadDebugSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _simulatedLatency =
            prefs.getBool(MockClinicalInterceptor.keySimulatedLatency) ?? true;
        _forceHttp503 =
            prefs.getBool(MockClinicalInterceptor.keyForceHttp503) ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _setSimulatedLatency(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MockClinicalInterceptor.keySimulatedLatency, val);
    setState(() => _simulatedLatency = val);
    if (mounted) {
      AppFeedback.showInfo(
        context,
        val
            ? 'Simulated Network Latency (400-850ms) Enabled'
            : 'Simulated Network Latency Disabled',
      );
    }
  }

  Future<void> _setForceHttp503(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MockClinicalInterceptor.keyForceHttp503, val);
    setState(() => _forceHttp503 = val);
    if (mounted) {
      if (val) {
        AppFeedback.showWarning(
          context,
          'Simulated HTTP 503 Service Unavailable Active',
        );
      } else {
        AppFeedback.showSuccess(context, 'Simulated HTTP 503 Gateway Disabled');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bug_report_rounded,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Recruiter Debug Drawer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'NETWORK & TELEMETRY SIMULATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Simulated Network Latency'),
                    subtitle: const Text(
                      '400ms - 850ms clinical interceptor delay',
                    ),
                    value: _simulatedLatency,
                    onChanged: _setSimulatedLatency,
                    activeThumbColor: colorScheme.primary,
                  ),
                  SwitchListTile(
                    title: const Text('Force HTTP 503 Service Error'),
                    subtitle: const Text(
                      'Simulate clinical gateway failure and verify offline retry views',
                    ),
                    value: _forceHttp503,
                    onChanged: _setForceHttp503,
                    activeThumbColor: colorScheme.error,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'CLINICAL TELEMETRY INJECTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      ref
                          .read(vitalsNotifierProvider.notifier)
                          .injectSimulatedAbnormalAlert();
                      Navigator.of(context).pop();
                      AppFeedback.showWarning(
                        context,
                        'Injected Abnormal Alert: BP 158/102, Glucose 228 mg/dL',
                      );
                    },
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('Inject Abnormal Vitals Alert'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(vitalsNotifierProvider.notifier).refresh();
                      Navigator.of(context).pop();
                      AppFeedback.showSuccess(
                        context,
                        'Restored Normative Clinical Telemetry Stream',
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset Telemetry Baseline'),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vitalis Architecture Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SDK 36 Target | Riverpod State Engine | Native Android & iOS BLE Telemetry Bridge | Clean Architecture MVVM',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
