import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis_app/presentation/prescriptions/prescriptions_notifier.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakePrescriptionRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakePrescriptionRepository();
    registerTestDependencies(prescriptions: fakeRepo);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('PrescriptionsNotifier Unit Tests', () {
    test(
      'Initial build calculates total pills and zero baseline adherence',
      () async {
        container.read(prescriptionsNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));
        final state = container.read(prescriptionsNotifierProvider);

        expect(state.isLoading, isFalse);
        expect(state.prescriptions.length, 1);
        expect(state.totalRemainingPills, 24);
        expect(state.overallAdherence, 0.0);
      },
    );

    test(
      'Mark dose taken increments doses taken and decrements pill count',
      () async {
        container.read(prescriptionsNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));
        final notifier = container.read(prescriptionsNotifierProvider.notifier);

        await notifier.markDoseTaken('rx_01');

        final state = container.read(prescriptionsNotifierProvider);
        final rx = state.prescriptions.firstWhere((p) => p.id == 'rx_01');

        expect(rx.dosesTakenToday, 1);
        expect(rx.pillsRemaining, 23);
        expect(state.overallAdherence, 1.0);
        expect(rx.isCompletedToday, isTrue);

        final repoRx = fakeRepo.prescriptions.first;
        expect(repoRx.pillsRemaining, 23);
        expect(repoRx.dosesTakenToday, 1);
      },
    );

    test('Request refill flags prescription as REFILL_REQUESTED', () async {
      container.read(prescriptionsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(prescriptionsNotifierProvider.notifier);

      await notifier.requestRefill('rx_01');

      final state = container.read(prescriptionsNotifierProvider);
      final rx = state.prescriptions.firstWhere((p) => p.id == 'rx_01');

      expect(rx.refillStatus, 'REFILL_REQUESTED');
      expect(fakeRepo.prescriptions.first.refillStatus, 'REFILL_REQUESTED');
    });

    test('Add prescription inserts new record into state', () async {
      container.read(prescriptionsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(prescriptionsNotifierProvider.notifier);

      await notifier.addPrescription(
        medicationName: 'Metformin ER',
        dosage: '500 mg Tablet',
        instructions: 'Take twice daily with meals',
        frequency: 'Morning & Evening',
        pillsCount: 60,
        dailyTargetDoses: 2,
        prescribingDoctor: 'Dr. Marcus Vance, MD',
      );

      final state = container.read(prescriptionsNotifierProvider);
      expect(state.prescriptions.length, 2);
      expect(state.prescriptions.last.medicationName, 'Metformin ER');
      expect(state.totalRemainingPills, 84);
    });
  });
}
