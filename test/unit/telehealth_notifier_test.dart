import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis_app/data/models/telehealth_doctor_model.dart';
import 'package:vitalis_app/presentation/telehealth/telehealth_notifier.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeTelehealthRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeTelehealthRepository();
    registerTestDependencies(telehealth: fakeRepo);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('TelehealthNotifier Unit Tests', () {
    test('Loads doctors and handles search filtering', () async {
      container.read(telehealthNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final state = container.read(telehealthNotifierProvider);
      final notifier = container.read(telehealthNotifierProvider.notifier);

      expect(state.allDoctors.length, 1);
      expect(state.filteredDoctors.length, 1);

      notifier.setSearchQuery('NonExistentDoctor');
      final filteredState = container.read(telehealthNotifierProvider);
      expect(filteredState.filteredDoctors.isEmpty, isTrue);

      notifier.setSearchQuery('Chen');
      final matchedState = container.read(telehealthNotifierProvider);
      expect(matchedState.filteredDoctors.length, 1);
    });

    test(
      'Book appointment creates and persists appointment into state',
      () async {
        container.read(telehealthNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));
        final notifier = container.read(telehealthNotifierProvider.notifier);

        const doctor = TelehealthDoctorModel(
          id: 'doc_01',
          name: 'Dr. Sarah Chen, MD, FACC',
          specialty: 'Cardiology',
          rating: 4.96,
          reviewCount: 342,
          consultationFee: 180.0,
          availableToday: true,
          avatarPath: 'assets/images/doctors/dr_sarah_chen.png',
          bio: 'Cardiology specialist',
          experienceYears: 14,
        );

        final scheduledDate = DateTime.now().add(const Duration(days: 1));

        await notifier.bookAppointment(
          doctor: doctor,
          scheduledTime: scheduledDate,
          consultationMode: 'VIDEO_CALL',
          symptomNotes: 'Heart palpitations telemetry check',
          liveVitalSharing: true,
        );

        final state = container.read(telehealthNotifierProvider);
        expect(state.appointments.length, 1);
        expect(state.appointments.first.doctorName, 'Dr. Sarah Chen, MD, FACC');
        expect(state.appointments.first.consultationMode, 'VIDEO_CALL');
        expect(fakeRepo.appointments.length, 1);
      },
    );

    test(
      'Cancel appointment updates status to CANCELLED in state & repo',
      () async {
        container.read(telehealthNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 50));
        final notifier = container.read(telehealthNotifierProvider.notifier);

        const doctor = TelehealthDoctorModel(
          id: 'doc_01',
          name: 'Dr. Sarah Chen, MD, FACC',
          specialty: 'Cardiology',
          rating: 4.96,
          reviewCount: 342,
          consultationFee: 180.0,
          availableToday: true,
          avatarPath: 'assets/images/doctors/dr_sarah_chen.png',
          bio: 'Cardiology specialist',
          experienceYears: 14,
        );

        await notifier.bookAppointment(
          doctor: doctor,
          scheduledTime: DateTime.now().add(const Duration(days: 2)),
          consultationMode: 'VIDEO_CALL',
          symptomNotes: 'Routine follow up',
        );

        final bookedState = container.read(telehealthNotifierProvider);
        final aptId = bookedState.appointments.first.id;

        await notifier.cancelAppointment(aptId);

        final updatedState = container.read(telehealthNotifierProvider);
        expect(updatedState.appointments.first.status, 'CANCELLED');
        expect(fakeRepo.appointments.first.status, 'CANCELLED');
      },
    );

    test('Consultation call HUD controls toggle correctly', () async {
      container.read(telehealthNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final notifier = container.read(telehealthNotifierProvider.notifier);

      expect(container.read(telehealthNotifierProvider).isMicMuted, isFalse);
      notifier.toggleMic();
      expect(container.read(telehealthNotifierProvider).isMicMuted, isTrue);

      expect(container.read(telehealthNotifierProvider).isCameraOff, isFalse);
      notifier.toggleCamera();
      expect(container.read(telehealthNotifierProvider).isCameraOff, isTrue);

      expect(
        container.read(telehealthNotifierProvider).isSharingVitals,
        isTrue,
      );
      notifier.toggleVitalSharing();
      expect(
        container.read(telehealthNotifierProvider).isSharingVitals,
        isFalse,
      );
    });
  });
}
