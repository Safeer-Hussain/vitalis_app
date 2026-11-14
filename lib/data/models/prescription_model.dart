class PrescriptionModel {
  final String id;
  final String medicationName;
  final String dosage;
  final String instructions;
  final String frequency;
  final int pillsRemaining;
  final int totalPills;
  final int dosesTakenToday;
  final int dailyTargetDoses;
  final String prescribingDoctor;
  final String refillStatus;
  final DateTime? lastTakenTimestamp;

  const PrescriptionModel({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.instructions,
    required this.frequency,
    required this.pillsRemaining,
    required this.totalPills,
    required this.dosesTakenToday,
    required this.dailyTargetDoses,
    required this.prescribingDoctor,
    required this.refillStatus,
    this.lastTakenTimestamp,
  });

  double get adherencePercentage {
    if (dailyTargetDoses <= 0) return 1.0;
    return (dosesTakenToday / dailyTargetDoses).clamp(0.0, 1.0);
  }

  bool get isCompletedToday => dosesTakenToday >= dailyTargetDoses;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_name': medicationName,
      'dosage': dosage,
      'instructions': instructions,
      'frequency': frequency,
      'pills_remaining': pillsRemaining,
      'total_pills': totalPills,
      'doses_taken_today': dosesTakenToday,
      'daily_target_doses': dailyTargetDoses,
      'prescribing_doctor': prescribingDoctor,
      'refill_status': refillStatus,
      'last_taken_timestamp': lastTakenTimestamp?.millisecondsSinceEpoch,
    };
  }

  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionModel(
      id: map['id'] as String,
      medicationName: map['medication_name'] as String,
      dosage: map['dosage'] as String,
      instructions: map['instructions'] as String? ?? '',
      frequency: map['frequency'] as String,
      pillsRemaining: map['pills_remaining'] as int? ?? 0,
      totalPills: map['total_pills'] as int? ?? 30,
      dosesTakenToday: map['doses_taken_today'] as int? ?? 0,
      dailyTargetDoses: map['daily_target_doses'] as int? ?? 1,
      prescribingDoctor:
          map['prescribing_doctor'] as String? ?? 'General Practice',
      refillStatus: map['refill_status'] as String? ?? 'NORMAL',
      lastTakenTimestamp: map['last_taken_timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['last_taken_timestamp'] as int,
            )
          : null,
    );
  }

  PrescriptionModel copyWith({
    String? id,
    String? medicationName,
    String? dosage,
    String? instructions,
    String? frequency,
    int? pillsRemaining,
    int? totalPills,
    int? dosesTakenToday,
    int? dailyTargetDoses,
    String? prescribingDoctor,
    String? refillStatus,
    DateTime? lastTakenTimestamp,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      frequency: frequency ?? this.frequency,
      pillsRemaining: pillsRemaining ?? this.pillsRemaining,
      totalPills: totalPills ?? this.totalPills,
      dosesTakenToday: dosesTakenToday ?? this.dosesTakenToday,
      dailyTargetDoses: dailyTargetDoses ?? this.dailyTargetDoses,
      prescribingDoctor: prescribingDoctor ?? this.prescribingDoctor,
      refillStatus: refillStatus ?? this.refillStatus,
      lastTakenTimestamp: lastTakenTimestamp ?? this.lastTakenTimestamp,
    );
  }
}
