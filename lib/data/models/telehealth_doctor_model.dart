class TelehealthDoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String? subspecialty;
  final String? hospital;
  final double rating;
  final int reviewCount;
  final double consultationFee;
  final bool availableToday;
  final String avatarPath;
  final String bio;
  final int experienceYears;

  const TelehealthDoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.subspecialty,
    this.hospital,
    required this.rating,
    required this.reviewCount,
    required this.consultationFee,
    required this.availableToday,
    required this.avatarPath,
    required this.bio,
    required this.experienceYears,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'subspecialty': subspecialty,
      'hospital': hospital,
      'rating': rating,
      'review_count': reviewCount,
      'consultation_fee': consultationFee,
      'available_today': availableToday ? 1 : 0,
      'avatar_path': avatarPath,
      'bio': bio,
      'experience_years': experienceYears,
    };
  }

  factory TelehealthDoctorModel.fromMap(Map<String, dynamic> map) {
    return TelehealthDoctorModel(
      id: map['id'] as String,
      name: map['name'] as String,
      specialty: map['specialty'] as String,
      subspecialty: map['subspecialty'] as String?,
      hospital: map['hospital'] as String?,
      rating: (map['rating'] as num).toDouble(),
      reviewCount: map['review_count'] as int,
      consultationFee: (map['consultation_fee'] as num).toDouble(),
      availableToday: (map['available_today'] as int? ?? 1) == 1,
      avatarPath:
          map['avatar_path'] as String? ??
          'assets/images/doctors/dr_sarah_chen.png',
      bio: map['bio'] as String? ?? '',
      experienceYears: map['experience_years'] as int? ?? 10,
    );
  }
}
