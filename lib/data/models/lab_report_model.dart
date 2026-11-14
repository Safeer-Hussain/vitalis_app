import 'biomarker_model.dart';

class LabReportModel {
  final String id;
  final String title;
  final String panelCode;
  final String category;
  final DateTime collectionDate;
  final String orderingPhysician;
  final String status;
  final bool isBookmarked;
  final String clinicalNotes;
  final List<BiomarkerModel> biomarkers;

  const LabReportModel({
    required this.id,
    required this.title,
    required this.panelCode,
    required this.category,
    required this.collectionDate,
    required this.orderingPhysician,
    required this.status,
    required this.isBookmarked,
    required this.clinicalNotes,
    this.biomarkers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'panel_code': panelCode,
      'category': category,
      'collection_date': collectionDate.millisecondsSinceEpoch,
      'ordering_physician': orderingPhysician,
      'status': status,
      'is_bookmarked': isBookmarked ? 1 : 0,
      'clinical_notes': clinicalNotes,
    };
  }

  factory LabReportModel.fromMap(
    Map<String, dynamic> map, {
    List<BiomarkerModel> biomarkers = const [],
  }) {
    return LabReportModel(
      id: map['id'] as String,
      title: map['title'] as String,
      panelCode: map['panel_code'] as String,
      category: map['category'] as String,
      collectionDate: DateTime.fromMillisecondsSinceEpoch(
        map['collection_date'] as int,
      ),
      orderingPhysician: map['ordering_physician'] as String? ?? 'Primary Care',
      status: map['status'] as String? ?? 'FINAL',
      isBookmarked: (map['is_bookmarked'] as int? ?? 0) == 1,
      clinicalNotes: map['clinical_notes'] as String? ?? '',
      biomarkers: biomarkers,
    );
  }

  LabReportModel copyWith({
    String? id,
    String? title,
    String? panelCode,
    String? category,
    DateTime? collectionDate,
    String? orderingPhysician,
    String? status,
    bool? isBookmarked,
    String? clinicalNotes,
    List<BiomarkerModel>? biomarkers,
  }) {
    return LabReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      panelCode: panelCode ?? this.panelCode,
      category: category ?? this.category,
      collectionDate: collectionDate ?? this.collectionDate,
      orderingPhysician: orderingPhysician ?? this.orderingPhysician,
      status: status ?? this.status,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      biomarkers: biomarkers ?? this.biomarkers,
    );
  }
}
