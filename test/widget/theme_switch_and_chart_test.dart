import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis_app/core/theme/app_theme.dart';
import 'package:vitalis_app/core/theme/theme_mode_provider.dart';
import 'package:vitalis_app/data/models/vital_reading_model.dart';
import 'package:vitalis_app/presentation/vitals/widgets/vitals_trend_chart.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    registerTestDependencies();
  });

  group('Theme Switching and Chart Widget Tests', () {
    testWidgets('Full-width chart rendering and metric switching', (
      WidgetTester tester,
    ) async {
      final sampleVitals = [
        VitalReadingModel(
          id: 'v1',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          sensorType: 'CARDIO_CUFF',
          systolic: 120,
          diastolic: 80,
          glucoseMgDl: 105,
        ),
        VitalReadingModel(
          id: 'v2',
          timestamp: DateTime.now(),
          sensorType: 'CARDIO_CUFF',
          systolic: 122,
          diastolic: 82,
          glucoseMgDl: 110,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(body: VitalsTrendChart(vitals: sampleVitals)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('14-Day Hemodynamic BP Profile'), findsOneWidget);

      // Switch to CGM metric
      await tester.tap(find.text('CGM'));
      await tester.pumpAndSettle();

      expect(find.text('14-Day CGM Glycemic Trajectory'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Instant Dark and Light theme reactive switching', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                home: const Scaffold(body: Center(child: Text('ThemeTest'))),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Starts in dark mode
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Toggle to light mode
      await container.read(themeModeProvider.notifier).toggleTheme();
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.light);

      // Toggle back to dark mode
      await container.read(themeModeProvider.notifier).toggleTheme();
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
