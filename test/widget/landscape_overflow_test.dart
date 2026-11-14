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

  testWidgets('Zero RenderFlex overflow errors on 800x360 landscape viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
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

    // Verify compact NavigationRail is active in landscape
    expect(find.byType(NavigationRail), findsOneWidget);

    // Verify no RenderFlex overflow exception
    expect(tester.takeException(), isNull);

    // Switch to Telehealth
    await tester.tap(find.byIcon(Icons.video_call_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    // Switch to Labs
    await tester.tap(find.byIcon(Icons.biotech_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final excLabs = tester.takeException();
    if (excLabs is FlutterError) {
      for (final detail in excLabs.diagnostics) {
        debugPrint('DIAG: ${detail.toStringDeep()}');
      }
    }
    expect(excLabs, isNull);

    // Switch to Rx
    await tester.tap(find.byIcon(Icons.medication_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final exc = tester.takeException();
    if (exc != null) {
      debugPrint('LANDSCAPE OVERFLOW IN RX: $exc');
    }
    expect(exc, isNull);

    // Switch to AI Triage
    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
