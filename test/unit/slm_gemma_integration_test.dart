import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis_app/core/slm/clinical_safety_classifier.dart';
import 'package:vitalis_app/core/slm/gemma_clinical_slm_engine.dart';
import 'package:vitalis_app/presentation/ai_triage/ai_triage_notifier.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Sprint 25: Clinical Safety Classifier Tests', () {
    late ClinicalSafetyClassifier classifier;

    setUp(() {
      classifier = ClinicalSafetyClassifier();
    });

    test('Tier 1: Flags acute emergency and requires 911/112 intervention', () {
      final result = classifier.evaluateInput(
        'I have severe crushing chest pain radiating to my left arm',
      );

      expect(result.tier, equals(ClinicalSafetyTier.acuteEmergency));
      expect(result.isGated, isTrue);
      expect(result.isSafe, isFalse);
      expect(
        result.escalationProtocol,
        contains('EMERGENCY_SERVICES_DISPATCH_911'),
      );
      expect(result.gatingMessage, contains('911'));
    });

    test('Tier 2: Flags suicide and self-harm crisis with 988 lifeline', () {
      final result = classifier.evaluateInput(
        'I feel hopeless and want to end my life right now',
      );

      expect(result.tier, equals(ClinicalSafetyTier.selfHarmCrisis));
      expect(result.isGated, isTrue);
      expect(result.isSafe, isFalse);
      expect(result.escalationProtocol, contains('CRISIS_LIFELINE_988'));
      expect(result.gatingMessage, contains('988'));
    });

    test('Tier 3: Flags unauthorized medication dosage alteration', () {
      final result = classifier.evaluateInput(
        'Can I double my dose without doctor recommendation?',
      );

      expect(
        result.tier,
        equals(ClinicalSafetyTier.unauthorizedDosageAlteration),
      );
      expect(result.isGated, isTrue);
      expect(
        result.escalationProtocol,
        contains('PREVENT_UNSUPERVISED_DOSAGE_TITRATION'),
      );
    });

    test('Tier 4: Permits benign informational query through gate', () {
      final result = classifier.evaluateInput(
        'What is the normal clinical reference range for resting heart rate?',
      );

      expect(result.tier, equals(ClinicalSafetyTier.benign));
      expect(result.isGated, isFalse);
      expect(result.isSafe, isTrue);
    });
  });

  group('Sprint 25: Gemma Clinical SLM Engine Tests', () {
    late GemmaClinicalSlmEngine engine;

    setUp(() {
      engine = GemmaClinicalSlmEngine();
    });

    test('Initializes with Q4_K_M 4-bit quant, NPU delegate, and zero network guarantee', () {
      final metrics = engine.metrics;

      expect(metrics.modelName, contains('Gemma 2B-IT Clinical'));
      expect(metrics.quantizationTier, contains('Q4_K_M'));
      expect(metrics.activeDelegate, equals('NPU'));
      expect(metrics.isZeroNetworkVerified, isTrue);
      expect(metrics.timeToFirstTokenMs, lessThanOrEqualTo(50));
      expect(metrics.contextLength, equals(2048));
    });

    test(
      'Switches execution delegates dynamically across NPU, GPU, and CPU',
      () async {
        await engine.setExecutionDelegate('GPU');
        expect(engine.metrics.activeDelegate, equals('GPU'));

        await engine.setExecutionDelegate('CPU');
        expect(engine.metrics.activeDelegate, equals('CPU'));

        await engine.setExecutionDelegate('NPU');
        expect(engine.metrics.activeDelegate, equals('NPU'));
      },
    );

    test(
      'Streams clinical tokens locally with sub-50ms TTFT without network',
      () async {
        final tokens = <String>[];

        await for (final token in engine.generateClinicalInference(
          userPrompt: 'Gemma runtime architecture diagnostic',
          recentVitals: const [],
          labReports: const [],
          prescriptions: const [],
        )) {
          tokens.add(token);
        }

        expect(tokens, isNotEmpty);
        final completeText = tokens.join('');
        expect(completeText, contains('Gemma 2B-IT Clinical'));
        expect(engine.metrics.isZeroNetworkVerified, isTrue);
        expect(engine.metrics.timeToFirstTokenMs, lessThanOrEqualTo(50));
      },
    );
  });

  group('Sprint 25: AiTriageNotifier SLM Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      registerTestDependencies();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'Loads initial SLM metrics and allows switching execution delegates',
      () async {
        final notifier = container.read(aiTriageNotifierProvider.notifier);

        // Allow microtask _loadHistory to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(aiTriageNotifierProvider);
        expect(state.slmMetrics.modelName, contains('Gemma 2B-IT Clinical'));
        expect(state.slmMetrics.activeDelegate, equals('NPU'));

        await notifier.setSlmDelegate('GPU');
        final updatedState = container.read(aiTriageNotifierProvider);
        expect(updatedState.slmMetrics.activeDelegate, equals('GPU'));
      },
    );

    test(
      'Safety classifier pre-screens prompts and gates clinical emergencies',
      () async {
        final notifier = container.read(aiTriageNotifierProvider.notifier);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await notifier.sendPrompt('crushing chest pain');

        final state = container.read(aiTriageNotifierProvider);
        expect(state.lastSafetyResult, isNotNull);
        expect(
          state.lastSafetyResult!.tier,
          equals(ClinicalSafetyTier.acuteEmergency),
        );
        expect(state.lastSafetyResult!.isGated, isTrue);
        expect(state.isStreaming, isFalse);
      },
    );
  });
}
