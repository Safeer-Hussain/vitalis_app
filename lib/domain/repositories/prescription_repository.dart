import '../../data/models/prescription_model.dart';

abstract class PrescriptionRepository {
  Future<List<PrescriptionModel>> getPrescriptions();
  Future<void> savePrescription(PrescriptionModel prescription);
  Future<void> recordDoseTaken(String prescriptionId);
  Future<void> requestRefill(String prescriptionId);
}
