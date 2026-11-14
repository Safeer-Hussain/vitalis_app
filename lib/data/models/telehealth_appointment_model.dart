class TelehealthAppointmentModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final DateTime scheduledTime;
  final String consultationMode; // 'VIDEO_CALL', 'CLINIC_VISIT'
  final String symptomNotes;
  final String status; // 'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
  final bool liveVitalSharing;

  const TelehealthAppointmentModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.scheduledTime,
    required this.consultationMode,
    required this.symptomNotes,
    required this.status,
    required this.liveVitalSharing,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'specialty': specialty,
      'scheduled_time': scheduledTime.millisecondsSinceEpoch,
      'consultation_mode': consultationMode,
      'symptom_notes': symptomNotes,
      'status': status,
      'live_vital_sharing': liveVitalSharing ? 1 : 0,
    };
  }

  factory TelehealthAppointmentModel.fromMap(Map<String, dynamic> map) {
    return TelehealthAppointmentModel(
      id: map['id'] as String,
      doctorId: map['doctor_id'] as String,
      doctorName: map['doctor_name'] as String,
      specialty: map['specialty'] as String,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(
        map['scheduled_time'] as int,
      ),
      consultationMode: map['consultation_mode'] as String,
      symptomNotes: map['symptom_notes'] as String? ?? '',
      status: map['status'] as String,
      liveVitalSharing: (map['live_vital_sharing'] as int? ?? 1) == 1,
    );
  }

  TelehealthAppointmentModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? specialty,
    DateTime? scheduledTime,
    String? consultationMode,
    String? symptomNotes,
    String? status,
    bool? liveVitalSharing,
  }) {
    return TelehealthAppointmentModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      consultationMode: consultationMode ?? this.consultationMode,
      symptomNotes: symptomNotes ?? this.symptomNotes,
      status: status ?? this.status,
      liveVitalSharing: liveVitalSharing ?? this.liveVitalSharing,
    );
  }
}
