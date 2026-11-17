import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/mock_clinical_interceptor.dart';
import '../platform/native_sensor_bridge.dart';
import '../../data/repositories/ai_triage_repository_impl.dart';
import '../../data/repositories/fhir_repository_impl.dart';
import '../../data/repositories/lab_repository_impl.dart';
import '../../data/repositories/prescription_repository_impl.dart';
import '../../data/repositories/telehealth_repository_impl.dart';
import '../../data/repositories/vitals_repository_impl.dart';
import '../../domain/repositories/ai_triage_repository.dart';
import '../../domain/repositories/fhir_repository.dart';
import '../../domain/repositories/lab_repository.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../../domain/repositories/telehealth_repository.dart';
import '../../domain/repositories/vitals_repository.dart';
import '../fhir/fhir_r4_service.dart';

final sl = GetIt.instance;

Future<void> initDependencyInjection() async {
  // Network & Dio
  if (!sl.isRegistered<Dio>()) {
    final dio = Dio();
    dio.interceptors.add(MockClinicalInterceptor());
    sl.registerLazySingleton<Dio>(() => dio);
  }

  // Platform Sensor Bridge
  if (!sl.isRegistered<NativeSensorBridge>()) {
    sl.registerLazySingleton<NativeSensorBridge>(() => NativeSensorBridge());
  }

  // Repositories
  if (!sl.isRegistered<VitalsRepository>()) {
    sl.registerLazySingleton<VitalsRepository>(
      () => VitalsRepositoryImpl(sl<NativeSensorBridge>()),
    );
  }

  if (!sl.isRegistered<TelehealthRepository>()) {
    sl.registerLazySingleton<TelehealthRepository>(
      () => TelehealthRepositoryImpl(),
    );
  }

  if (!sl.isRegistered<LabRepository>()) {
    sl.registerLazySingleton<LabRepository>(() => LabRepositoryImpl());
  }

  if (!sl.isRegistered<PrescriptionRepository>()) {
    sl.registerLazySingleton<PrescriptionRepository>(
      () => PrescriptionRepositoryImpl(),
    );
  }

  if (!sl.isRegistered<AiTriageRepository>()) {
    sl.registerLazySingleton<AiTriageRepository>(
      () => AiTriageRepositoryImpl(),
    );
  }

  // FHIR R4 Interoperability Service & Repository
  if (!sl.isRegistered<FhirR4Service>()) {
    sl.registerLazySingleton<FhirR4Service>(() => FhirR4Service());
  }

  if (!sl.isRegistered<FhirRepository>()) {
    sl.registerLazySingleton<FhirRepository>(
      () => FhirRepositoryImpl(
        sl<VitalsRepository>(),
        sl<LabRepository>(),
        sl<PrescriptionRepository>(),
        sl<FhirR4Service>(),
      ),
    );
  }
}
