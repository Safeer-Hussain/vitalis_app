import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/injection_container.dart';
import '../../data/models/telehealth_appointment_model.dart';
import '../../data/models/telehealth_doctor_model.dart';
import '../../domain/repositories/telehealth_repository.dart';

class TelehealthState {
  final bool isLoading;
  final List<TelehealthDoctorModel> allDoctors;
  final List<TelehealthAppointmentModel> appointments;
  final String searchQuery;
  final String? selectedSpecialty;
  final bool onlyAvailableToday;
  final double? maxFee;
  final TelehealthAppointmentModel? activeCallAppointment;
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isSharingVitals;
  final String? errorMessage;

  const TelehealthState({
    this.isLoading = false,
    this.allDoctors = const [],
    this.appointments = const [],
    this.searchQuery = '',
    this.selectedSpecialty,
    this.onlyAvailableToday = false,
    this.maxFee,
    this.activeCallAppointment,
    this.isMicMuted = false,
    this.isCameraOff = false,
    this.isSharingVitals = true,
    this.errorMessage,
  });

  List<TelehealthDoctorModel> get filteredDoctors {
    return allDoctors.where((doc) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final match =
            doc.name.toLowerCase().contains(q) ||
            doc.specialty.toLowerCase().contains(q) ||
            (doc.subspecialty?.toLowerCase().contains(q) ?? false) ||
            (doc.hospital?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      if (selectedSpecialty != null &&
          selectedSpecialty!.isNotEmpty &&
          selectedSpecialty != 'All') {
        if (doc.specialty.toLowerCase() != selectedSpecialty!.toLowerCase()) {
          return false;
        }
      }
      if (onlyAvailableToday && !doc.availableToday) {
        return false;
      }
      if (maxFee != null && doc.consultationFee > maxFee!) {
        return false;
      }
      return true;
    }).toList();
  }

  TelehealthState copyWith({
    bool? isLoading,
    List<TelehealthDoctorModel>? allDoctors,
    List<TelehealthAppointmentModel>? appointments,
    String? searchQuery,
    String? selectedSpecialty,
    bool? onlyAvailableToday,
    double? maxFee,
    TelehealthAppointmentModel? activeCallAppointment,
    bool clearActiveCall = false,
    bool? isMicMuted,
    bool? isCameraOff,
    bool? isSharingVitals,
    String? errorMessage,
  }) {
    return TelehealthState(
      isLoading: isLoading ?? this.isLoading,
      allDoctors: allDoctors ?? this.allDoctors,
      appointments: appointments ?? this.appointments,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSpecialty: selectedSpecialty ?? this.selectedSpecialty,
      onlyAvailableToday: onlyAvailableToday ?? this.onlyAvailableToday,
      maxFee: maxFee ?? this.maxFee,
      activeCallAppointment: clearActiveCall
          ? null
          : (activeCallAppointment ?? this.activeCallAppointment),
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isSharingVitals: isSharingVitals ?? this.isSharingVitals,
      errorMessage: errorMessage,
    );
  }
}

class TelehealthNotifier extends Notifier<TelehealthState> {
  late final TelehealthRepository _repository;

  @override
  TelehealthState build() {
    _repository = sl<TelehealthRepository>();
    Future.microtask(_loadData);
    return const TelehealthState(isLoading: true);
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final doctors = await _repository.getDoctors();
      final appointments = await _repository.getAppointments();
      state = state.copyWith(
        isLoading: false,
        allDoctors: doctors,
        appointments: appointments,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSpecialtyFilter(String? specialty) {
    state = state.copyWith(selectedSpecialty: specialty);
  }

  void toggleAvailableToday(bool onlyAvailable) {
    state = state.copyWith(onlyAvailableToday: onlyAvailable);
  }

  void setMaxFee(double? maxFee) {
    state = state.copyWith(maxFee: maxFee);
  }

  Future<void> bookAppointment({
    required TelehealthDoctorModel doctor,
    required DateTime scheduledTime,
    required String consultationMode,
    required String symptomNotes,
    bool liveVitalSharing = true,
  }) async {
    const uuid = Uuid();
    final appointment = TelehealthAppointmentModel(
      id: 'apt_${uuid.v4().substring(0, 8)}',
      doctorId: doctor.id,
      doctorName: doctor.name,
      specialty: doctor.specialty,
      scheduledTime: scheduledTime,
      consultationMode: consultationMode,
      symptomNotes: symptomNotes,
      status: 'SCHEDULED',
      liveVitalSharing: liveVitalSharing,
    );

    await _repository.bookAppointment(appointment);
    final updatedList = [...state.appointments, appointment];
    updatedList.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    state = state.copyWith(appointments: updatedList);
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _repository.cancelAppointment(appointmentId);
    final updatedList = state.appointments.map((a) {
      if (a.id == appointmentId) {
        return a.copyWith(status: 'CANCELLED');
      }
      return a;
    }).toList();
    state = state.copyWith(appointments: updatedList);
  }

  void startConsultationCall(TelehealthAppointmentModel appointment) {
    state = state.copyWith(
      activeCallAppointment: appointment,
      isMicMuted: false,
      isCameraOff: false,
      isSharingVitals: appointment.liveVitalSharing,
    );
  }

  void toggleMic() {
    state = state.copyWith(isMicMuted: !state.isMicMuted);
  }

  void toggleCamera() {
    state = state.copyWith(isCameraOff: !state.isCameraOff);
  }

  void toggleVitalSharing() {
    state = state.copyWith(isSharingVitals: !state.isSharingVitals);
  }

  void endConsultationCall() {
    state = state.copyWith(clearActiveCall: true);
  }
}

final telehealthNotifierProvider =
    NotifierProvider<TelehealthNotifier, TelehealthState>(() {
      return TelehealthNotifier();
    });
