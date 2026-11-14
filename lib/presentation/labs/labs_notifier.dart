import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection_container.dart';
import '../../data/models/lab_report_model.dart';
import '../../domain/repositories/lab_repository.dart';

class LabsState {
  final bool isLoading;
  final List<LabReportModel> allReports;
  final String? selectedCategory;
  final bool onlyBookmarked;
  final LabReportModel? selectedReport;
  final String? errorMessage;

  const LabsState({
    this.isLoading = false,
    this.allReports = const [],
    this.selectedCategory,
    this.onlyBookmarked = false,
    this.selectedReport,
    this.errorMessage,
  });

  List<LabReportModel> get filteredReports {
    return allReports.where((report) {
      if (onlyBookmarked && !report.isBookmarked) {
        return false;
      }
      if (selectedCategory != null &&
          selectedCategory!.isNotEmpty &&
          selectedCategory != 'All') {
        if (report.category.toLowerCase() != selectedCategory!.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  LabsState copyWith({
    bool? isLoading,
    List<LabReportModel>? allReports,
    String? selectedCategory,
    bool? onlyBookmarked,
    LabReportModel? selectedReport,
    bool clearSelectedReport = false,
    String? errorMessage,
  }) {
    return LabsState(
      isLoading: isLoading ?? this.isLoading,
      allReports: allReports ?? this.allReports,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      onlyBookmarked: onlyBookmarked ?? this.onlyBookmarked,
      selectedReport: clearSelectedReport
          ? null
          : (selectedReport ?? this.selectedReport),
      errorMessage: errorMessage,
    );
  }
}

class LabsNotifier extends Notifier<LabsState> {
  late final LabRepository _repository;

  @override
  LabsState build() {
    _repository = sl<LabRepository>();
    Future.microtask(_loadReports);
    return const LabsState(isLoading: true);
  }

  Future<void> _loadReports() async {
    state = state.copyWith(isLoading: true);
    try {
      final reports = await _repository.getLabReports();
      state = state.copyWith(
        isLoading: false,
        allReports: reports,
        selectedReport: reports.isNotEmpty ? reports.first : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await _loadReports();
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void toggleBookmarkedOnly(bool val) {
    state = state.copyWith(onlyBookmarked: val);
  }

  void selectReport(LabReportModel report) {
    state = state.copyWith(selectedReport: report);
  }

  Future<void> toggleBookmark(String reportId) async {
    final report = state.allReports.firstWhere((r) => r.id == reportId);
    final newStatus = !report.isBookmarked;

    await _repository.toggleBookmark(reportId, newStatus);

    final updated = state.allReports.map((r) {
      if (r.id == reportId) {
        return r.copyWith(isBookmarked: newStatus);
      }
      return r;
    }).toList();

    state = state.copyWith(
      allReports: updated,
      selectedReport: state.selectedReport?.id == reportId
          ? state.selectedReport!.copyWith(isBookmarked: newStatus)
          : state.selectedReport,
    );
  }

  String generateFormattedSummary(LabReportModel report) {
    final buffer = StringBuffer();
    buffer.writeln('CLINICAL DIAGNOSTIC REPORT: ${report.title}');
    buffer.writeln('Panel Code: ${report.panelCode}');
    buffer.writeln('Ordering Physician: ${report.orderingPhysician}');
    buffer.writeln(
      'Collection Date: ${report.collectionDate.toIso8601String().split('T').first}',
    );
    buffer.writeln('Status: ${report.status}');
    buffer.writeln('\nBIOMARKERS:');
    for (final bm in report.biomarkers) {
      buffer.writeln(
        '- ${bm.name} (${bm.code}): ${bm.value} ${bm.unit} [Ref: ${bm.minRange} - ${bm.maxRange}] Status: ${bm.clinicalStatus}',
      );
      if (bm.interpretation != null) {
        buffer.writeln('  Note: ${bm.interpretation}');
      }
    }
    buffer.writeln('\nCLINICAL SUMMARY:');
    buffer.writeln(report.clinicalNotes);
    return buffer.toString();
  }

  String generateHl7JsonSnapshot(LabReportModel report) {
    final data = {
      'resourceType': 'DiagnosticReport',
      'id': report.id,
      'status': report.status.toLowerCase(),
      'code': {
        'coding': [
          {
            'system': 'http://loinc.org',
            'code': report.panelCode,
            'display': report.title,
          },
        ],
      },
      'subject': {'reference': 'Patient/SAFEER-HUSSAIN'},
      'effectiveDateTime': report.collectionDate.toIso8601String(),
      'performer': [
        {'display': report.orderingPhysician},
      ],
      'result': report.biomarkers.map((bm) {
        return {
          'resourceType': 'Observation',
          'id': bm.id,
          'code': {'text': bm.name, 'code': bm.code},
          'valueQuantity': {'value': bm.value, 'unit': bm.unit},
          'referenceRange': [
            {'low': bm.minRange, 'high': bm.maxRange},
          ],
          'interpretation': bm.clinicalStatus,
        };
      }).toList(),
      'conclusion': report.clinicalNotes,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

final labsNotifierProvider = NotifierProvider<LabsNotifier, LabsState>(() {
  return LabsNotifier();
});
