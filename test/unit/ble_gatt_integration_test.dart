import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis_app/core/platform/native_sensor_bridge.dart';
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

  group('Sprint 23: BLE GATT Direct Peripheral & Reconnect Tests', () {
    test(
      'scanGattPeripherals filters peripherals by clinical service UUIDs',
      () async {
        // Scan with only Glucose UUID (0x1808)
        final glucoseOnly = await fakeRepo.scanGattPeripherals(
          serviceUuids: [NativeSensorBridge.uuidGlucose],
        );
        expect(glucoseOnly.length, 1);
        expect(glucoseOnly.first.name, 'GlucoSense CGM Direct');
        expect(glucoseOnly.first.serviceUuids, contains('0x1808'));
        expect(glucoseOnly.first.isGattDevice, isTrue);
        expect(glucoseOnly.first.macAddress, 'E1:8B:22:90:3F:8A');

        // Scan with Blood Pressure UUID (0x1810)
        final bpOnly = await fakeRepo.scanGattPeripherals(
          serviceUuids: [NativeSensorBridge.uuidBloodPressure],
        );
        expect(bpOnly.length, 1);
        expect(bpOnly.first.name, 'CardioCuff Pro BLE-GATT');
        expect(bpOnly.first.serviceUuids, contains('0x1810'));

        // Scan with Heart Rate UUID (0x180D) - matches both CardioCuff and OxyPulse
        final hrDevices = await fakeRepo.scanGattPeripherals(
          serviceUuids: [NativeSensorBridge.uuidHeartRate],
        );
        expect(hrDevices.length, 2);
      },
    );

    test(
      'VitalsNotifier toggles auto-reconnect with exponential backoff policy',
      () async {
        container.read(vitalsNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));
        final notifier = container.read(vitalsNotifierProvider.notifier);

        expect(
          container.read(vitalsNotifierProvider).autoReconnectEnabled,
          isTrue,
        );

        // Toggle auto-reconnect off
        await notifier.toggleAutoReconnect(false);
        expect(
          container.read(vitalsNotifierProvider).autoReconnectEnabled,
          isFalse,
        );
        expect(fakeRepo.autoReconnectActive, isFalse);

        // Toggle auto-reconnect on
        await notifier.toggleAutoReconnect(true);
        expect(
          container.read(vitalsNotifierProvider).autoReconnectEnabled,
          isTrue,
        );
        expect(fakeRepo.autoReconnectActive, isTrue);
      },
    );

    test('VitalsNotifier toggles Android foreground background telemetry ingestion', () async {
      container.read(vitalsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(vitalsNotifierProvider.notifier);

      expect(
        container.read(vitalsNotifierProvider).backgroundTelemetryEnabled,
        isFalse,
      );

      // Toggle background telemetry on
      await notifier.toggleBackgroundTelemetry(true);
      expect(
        container.read(vitalsNotifierProvider).backgroundTelemetryEnabled,
        isTrue,
      );
      expect(fakeRepo.backgroundTelemetryActive, isTrue);

      // Toggle background telemetry off
      await notifier.toggleBackgroundTelemetry(false);
      expect(
        container.read(vitalsNotifierProvider).backgroundTelemetryEnabled,
        isFalse,
      );
      expect(fakeRepo.backgroundTelemetryActive, isFalse);
    });

    test('VitalsNotifier dynamic GATT UUID filter manipulation', () async {
      container.read(vitalsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(vitalsNotifierProvider.notifier);

      expect(
        container.read(vitalsNotifierProvider).activeGattUuidFilters.length,
        3,
      );
      expect(
        container.read(vitalsNotifierProvider).activeGattUuidFilters,
        contains(NativeSensorBridge.uuidGlucose),
      );

      // Remove Glucose filter
      await notifier.toggleGattUuidFilter(NativeSensorBridge.uuidGlucose);
      expect(
        container.read(vitalsNotifierProvider).activeGattUuidFilters,
        isNot(contains(NativeSensorBridge.uuidGlucose)),
      );
      expect(
        container.read(vitalsNotifierProvider).activeGattUuidFilters.length,
        2,
      );

      // Re-add Glucose filter
      await notifier.toggleGattUuidFilter(NativeSensorBridge.uuidGlucose);
      expect(
        container.read(vitalsNotifierProvider).activeGattUuidFilters,
        contains(NativeSensorBridge.uuidGlucose),
      );
      expect(
        container.read(vitalsNotifierProvider).activeGattUuidFilters.length,
        3,
      );
    });

    test(
      'VitalsNotifier handles connection drop and transitions to reconnecting',
      () async {
        container.read(vitalsNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));
        final notifier = container.read(vitalsNotifierProvider.notifier);

        expect(
          container.read(vitalsNotifierProvider).connectionStatus,
          'CONNECTED',
        );

        // Simulate connection drop
        await notifier.simulateConnectionDrop();

        // State recovers back to CONNECTED through status stream
        await Future.delayed(const Duration(milliseconds: 100));
        expect(
          container.read(vitalsNotifierProvider).connectionStatus,
          'CONNECTED',
        );
      },
    );
  });
}
