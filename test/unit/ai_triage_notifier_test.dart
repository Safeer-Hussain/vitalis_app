import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis_app/presentation/ai_triage/ai_triage_notifier.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeAiTriageRepository fakeTriageRepo;
  late ProviderContainer container;

  setUp(() {
    fakeTriageRepo = FakeAiTriageRepository();
    registerTestDependencies(triage: fakeTriageRepo);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AiTriageNotifier Unit Tests', () {
    test('Initial history load', () async {
      final initial = container.read(aiTriageNotifierProvider);
      expect(initial.isLoading, isTrue);

      await Future.delayed(const Duration(milliseconds: 50));
      final loaded = container.read(aiTriageNotifierProvider);
      expect(loaded.isLoading, isFalse);
      expect(loaded.isStreaming, isFalse);
      expect(loaded.isCorrelating, isFalse);
    });

    test('sendPrompt streams tokens and guarantees isStreaming resets to false in finally', () async {
      container.read(aiTriageNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(aiTriageNotifierProvider.notifier);

      final future = notifier.sendPrompt('Analyze my latest lab trends');

      final immediateState = container.read(aiTriageNotifierProvider);
      expect(immediateState.isStreaming, isTrue);
      expect(immediateState.messages.isNotEmpty, isTrue);
      expect(
        immediateState.messages.first.content,
        'Analyze my latest lab trends',
      );

      await future;

      final finishedState = container.read(aiTriageNotifierProvider);
      expect(finishedState.isStreaming, isFalse);
      expect(finishedState.isCorrelating, isFalse);
      expect(finishedState.messages.length, 2);
      expect(
        finishedState.messages.last.content,
        'Clinical triage assessment.',
      );
    });

    test('clearHistory clears message list', () async {
      container.read(aiTriageNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(aiTriageNotifierProvider.notifier);

      await notifier.sendPrompt('Test message');
      expect(
        container.read(aiTriageNotifierProvider).messages.isNotEmpty,
        isTrue,
      );

      await notifier.clearHistory();
      expect(container.read(aiTriageNotifierProvider).messages.isEmpty, isTrue);
    });
  });
}
