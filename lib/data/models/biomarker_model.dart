class BiomarkerModel {
  final String id;
  final String reportId;
  final String name;
  final String code;
  final double value;
  final String unit;
  final double minRange;
  final double maxRange;
  final String clinicalStatus; // 'OPTIMAL', 'LOW', 'ELEVATED', 'CRITICAL'
  final double? historicalValue;
  final String? interpretation;

  const BiomarkerModel({
    required this.id,
    required this.reportId,
    required this.name,
    required this.code,
    required this.value,
    required this.unit,
    required this.minRange,
    required this.maxRange,
    required this.clinicalStatus,
    this.historicalValue,
    this.interpretation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_id': reportId,
      'name': name,
      'code': code,
      'value': value,
      'unit': unit,
      'min_range': minRange,
      'max_range': maxRange,
      'clinical_status': clinicalStatus,
      'historical_value': historicalValue,
      'interpretation': interpretation,
    };
  }

  factory BiomarkerModel.fromMap(Map<String, dynamic> map) {
    return BiomarkerModel(
      id: map['id'] as String,
      reportId: map['report_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      minRange: (map['min_range'] as num).toDouble(),
      maxRange: (map['max_range'] as num).toDouble(),
      clinicalStatus: map['clinical_status'] as String,
      historicalValue: (map['historical_value'] as num?)?.toDouble(),
      interpretation: map['interpretation'] as String?,
    );
  }
}
