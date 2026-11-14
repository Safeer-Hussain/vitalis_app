import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis_app/data/models/vital_reading_model.dart';
import 'package:vitalis_app/presentation/vitals/vitals_notifier.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeVitalsRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeVitalsRepository();
    registerTestDependencies(vitals: fakeRepo);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('VitalsNotifier Unit Tests', () {
    test(
      'Initial build loads historical vitals and available devices',
      () async {
        container.read(vitalsNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));
        final state = container.read(vitalsNotifierProvider);

        expect(state.isLoading, isFalse);
        expect(state.devices.length, 2);
        expect(state.selectedSensorType, 'CARDIO_CUFF');
      },
    );

    test(
      'Log manual vital inserts reading immutably into state and repository',
      () async {
        container.read(vitalsNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));
        final notifier = container.read(vitalsNotifierProvider.notifier);

        await notifier.logManualVital(
          systolic: 124,
          diastolic: 82,
          pulseRate: 74,
          glucoseMgDl: 104,
          oxygenSaturation: 99,
          temperatureCelsius: 36.9,
          notes: 'Clinical Test Reading',
        );

        final state = container.read(vitalsNotifierProvider);
        expect(state.historicalVitals.isNotEmpty, isTrue);
        expect(state.historicalVitals.first.systolic, 124);
        expect(state.historicalVitals.first.diastolic, 82);
        expect(state.historicalVitals.first.meanArterialPressure, 96.0);
        expect(state.currentTelemetry?.systolic, 124);
        expect(fakeRepo.vitals.first.systolic, 124);
      },
    );

    test(
      'Live telemetry packet updates currentTelemetry in real-time',
      () async {
        container.read(vitalsNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        final testPacket = VitalReadingModel(
          id: 'tel_999',
          timestamp: DateTime.now(),
          sensorType: 'CARDIO_CUFF',
          systolic: 128,
          diastolic: 84,
          meanArterialPressure: 98.7,
          pulseRate: 76,
        );

        fakeRepo.emitTelemetry(testPacket);
        await Future.delayed(const Duration(milliseconds: 50));

        final state = container.read(vitalsNotifierProvider);
        expect(state.currentTelemetry?.systolic, 128);
        expect(state.currentTelemetry?.pulseRate, 76);
      },
    );

    test('Inject abnormal alert flags simulated spike in state', () async {
      container.read(vitalsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(vitalsNotifierProvider.notifier);

      notifier.injectSimulatedAbnormalAlert();

      final state = container.read(vitalsNotifierProvider);
      expect(state.simulatedAbnormalInjected, isTrue);
      expect(state.currentTelemetry?.systolic, 158);
      expect(state.currentTelemetry?.diastolic, 102);
      expect(state.currentTelemetry?.irregularHeartbeat, isTrue);
    });
  });
}
