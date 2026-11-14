import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/injection_container.dart';
import '../../data/models/prescription_model.dart';
import '../../domain/repositories/prescription_repository.dart';

class PrescriptionsState {
  final bool isLoading;
  final List<PrescriptionModel> prescriptions;
  final String? errorMessage;

  const PrescriptionsState({
    this.isLoading = false,
    this.prescriptions = const [],
    this.errorMessage,
  });

  double get overallAdherence {
    if (prescriptions.isEmpty) return 1.0;
    final totalTarget = prescriptions.fold<int>(
      0,
      (sum, p) => sum + p.dailyTargetDoses,
    );
    if (totalTarget == 0) return 1.0;
    final totalTaken = prescriptions.fold<int>(
      0,
      (sum, p) => sum + p.dosesTakenToday,
    );
    return (totalTaken / totalTarget).clamp(0.0, 1.0);
  }

  int get totalRemainingPills {
    return prescriptions.fold<int>(0, (sum, p) => sum + p.pillsRemaining);
  }

  PrescriptionsState copyWith({
    bool? isLoading,
    List<PrescriptionModel>? prescriptions,
    String? errorMessage,
  }) {
    return PrescriptionsState(
      isLoading: isLoading ?? this.isLoading,
      prescriptions: prescriptions ?? this.prescriptions,
      errorMessage: errorMessage,
    );
  }
}

class PrescriptionsNotifier extends Notifier<PrescriptionsState> {
  late final PrescriptionRepository _repository;

  @override
  PrescriptionsState build() {
    _repository = sl<PrescriptionRepository>();
    Future.microtask(_loadPrescriptions);
    return const PrescriptionsState(isLoading: true);
  }

  Future<void> _loadPrescriptions() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getPrescriptions();
      state = state.copyWith(isLoading: false, prescriptions: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await _loadPrescriptions();
  }

  Future<void> markDoseTaken(String prescriptionId) async {
    await _repository.recordDoseTaken(prescriptionId);
    final now = DateTime.now();

    final updated = state.prescriptions.map((p) {
      if (p.id == prescriptionId) {
        return p.copyWith(
          dosesTakenToday: p.dosesTakenToday + 1,
          pillsRemaining: (p.pillsRemaining - 1).clamp(0, 999),
          lastTakenTimestamp: now,
        );
      }
      return p;
    }).toList();

    state = state.copyWith(prescriptions: updated);
  }

  Future<void> requestRefill(String prescriptionId) async {
    await _repository.requestRefill(prescriptionId);
    final updated = state.prescriptions.map((p) {
      if (p.id == prescriptionId) {
        return p.copyWith(refillStatus: 'REFILL_REQUESTED');
      }
      return p;
    }).toList();
    state = state.copyWith(prescriptions: updated);
  }

  Future<void> addPrescription({
    required String medicationName,
    required String dosage,
    required String instructions,
    required String frequency,
    required int pillsCount,
    required int dailyTargetDoses,
    required String prescribingDoctor,
  }) async {
    const uuid = Uuid();
    final prescription = PrescriptionModel(
      id: 'rx_${uuid.v4().substring(0, 8)}',
      medicationName: medicationName,
      dosage: dosage,
      instructions: instructions,
      frequency: frequency,
      pillsRemaining: pillsCount,
      totalPills: pillsCount,
      dosesTakenToday: 0,
      dailyTargetDoses: dailyTargetDoses,
      prescribingDoctor: prescribingDoctor,
      refillStatus: 'NORMAL',
    );

    await _repository.savePrescription(prescription);
    state = state.copyWith(
      prescriptions: [...state.prescriptions, prescription],
    );
  }
}

final prescriptionsNotifierProvider =
    NotifierProvider<PrescriptionsNotifier, PrescriptionsState>(() {
      return PrescriptionsNotifier();
    });
