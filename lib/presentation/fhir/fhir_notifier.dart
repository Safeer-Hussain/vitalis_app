import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection_container.dart';
import '../../core/fhir/fhir_r4_service.dart';
import '../../data/models/fhir_bundle_model.dart';
import '../../domain/repositories/fhir_repository.dart';

class FhirState {
  final bool isLoading;
  final FhirBundleModel? bundle;
  final String selectedResourceType; // 'ALL', 'Observation', 'DiagnosticReport', 'MedicationStatement'
  final FhirValidationReport? validationReport;
  final bool isSignatureVerified;
  final String? simulatedEhrDestination;
  final String? errorMessage;

  const FhirState({
    this.isLoading = false,
    this.bundle,
    this.selectedResourceType = 'ALL',
    this.validationReport,
    this.isSignatureVerified = true,
    this.simulatedEhrDestination,
    this.errorMessage,
  });

  List<FhirResourceModel> get filteredEntries {
    if (bundle == null) return [];
    if (selectedResourceType == 'ALL') return bundle!.entries;
    return bundle!.entries
        .where((e) => e.resourceType == selectedResourceType)
        .toList();
  }

  FhirState copyWith({
    bool? isLoading,
    FhirBundleModel? bundle,
    String? selectedResourceType,
    FhirValidationReport? validationReport,
    bool? isSignatureVerified,
    String? simulatedEhrDestination,
    String? errorMessage,
  }) {
    return FhirState(
      isLoading: isLoading ?? this.isLoading,
      bundle: bundle ?? this.bundle,
      selectedResourceType: selectedResourceType ?? this.selectedResourceType,
      validationReport: validationReport ?? this.validationReport,
      isSignatureVerified: isSignatureVerified ?? this.isSignatureVerified,
      simulatedEhrDestination:
          simulatedEhrDestination ?? this.simulatedEhrDestination,
      errorMessage: errorMessage,
    );
  }
}

class FhirNotifier extends Notifier<FhirState> {
  late final FhirRepository _repository;

  @override
  FhirState build() {
    _repository = sl<FhirRepository>();
    Future.microtask(_loadFhirBundle);
    return const FhirState(isLoading: true);
  }

  Future<void> _loadFhirBundle() async {
    state = state.copyWith(isLoading: true);
    try {
      final bundle = await _repository.exportPatientFhirBundle();
      final report = _repository.validateBundle(bundle);
      final isVerified = _repository.verifyCryptographicSignature(bundle);

      state = state.copyWith(
        isLoading: false,
        bundle: bundle,
        validationReport: report,
        isSignatureVerified: isVerified,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await _loadFhirBundle();
  }

  void filterByType(String type) {
    state = state.copyWith(selectedResourceType: type);
  }

  bool verifySignature() {
    if (state.bundle == null) return false;
    final verified = _repository.verifyCryptographicSignature(state.bundle!);
    state = state.copyWith(isSignatureVerified: verified);
    return verified;
  }

  Future<void> simulateEhrExport(String ehrSystem) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      isLoading: false,
      simulatedEhrDestination: ehrSystem,
    );
  }
}

final fhirNotifierProvider = NotifierProvider<FhirNotifier, FhirState>(
  () => FhirNotifier(),
);
