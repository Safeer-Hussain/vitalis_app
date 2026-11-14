import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis_app/core/theme/app_theme.dart';
import 'package:vitalis_app/presentation/adaptive_scaffold.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    registerTestDependencies();
  });

  testWidgets(
    'Zero duplicate Hero tag exceptions across multi-tab shell navigation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AdaptiveScaffold(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tab 0: Vitals
      expect(find.byType(AdaptiveScaffold), findsOneWidget);
      final fabVitals = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'fab_vitals_sync',
      );
      expect(fabVitals, findsOneWidget);

      // Navigate to Tab 1: Telehealth
      await tester.tap(find.text('Telehealth'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final fabTelehealth = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'fab_telehealth_book',
      );
      expect(fabTelehealth, findsOneWidget);

      // Navigate to Tab 2: Labs
      await tester.tap(find.text('Labs'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final fabLabs = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'fab_lab_upload',
      );
      expect(fabLabs, findsOneWidget);

      // Navigate to Tab 3: Prescriptions
      await tester.tap(find.text('Rx'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final fabRx = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'fab_rx_add_med',
      );
      expect(fabRx, findsOneWidget);

      // Navigate to Tab 4: AI Triage
      await tester.tap(find.text('AI Triage'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final fabAiTriage = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'fab_ai_triage_clear',
      );
      expect(fabAiTriage, findsOneWidget);

      // Verify tester recorded zero uncaught exceptions
      expect(tester.takeException(), isNull);
    },
  );
}
