import '../../data/models/telehealth_appointment_model.dart';
import '../../data/models/telehealth_doctor_model.dart';

abstract class TelehealthRepository {
  Future<List<TelehealthDoctorModel>> getDoctors();
  Future<List<TelehealthAppointmentModel>> getAppointments();
  Future<void> bookAppointment(TelehealthAppointmentModel appointment);
  Future<void> cancelAppointment(String appointmentId);
  Future<void> updateAppointment(TelehealthAppointmentModel appointment);
}
