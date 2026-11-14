import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_feedback.dart';
import '../../data/models/lab_report_model.dart';
import 'labs_notifier.dart';
import 'widgets/biomarker_breakdown_sheet.dart';
import 'widgets/biomarker_range_bar.dart';
import 'widgets/lab_panel_card.dart';
import 'widgets/share_export_lab_sheet.dart';

class LabsView extends ConsumerWidget {
  const LabsView({super.key});

  void _openBreakdownSheet(BuildContext context, LabReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BiomarkerBreakdownSheet(report: report),
    );
  }

  void _openUploadLabModal(BuildContext context) {
    AppFeedback.showInfo(
      context,
      'Connecting to Local Secure Health Records scanner for automated OCR extraction...',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(labsNotifierProvider);
    final notifier = ref.read(labsNotifierProvider.notifier);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_lab_upload',
        onPressed: () => _openUploadLabModal(context),
        icon: const Icon(Icons.file_upload_outlined),
        label: const Text('Import Lab'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: isLandscape
                  ? _buildLandscapeLayout(context, state, notifier)
                  : _buildPortraitLayout(context, state, notifier),
            ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    LabsState state,
    LabsNotifier notifier,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildCategoryFilters(context, state, notifier),
        const SizedBox(height: 12),
        _buildVaultHeader(context, state.filteredReports.length),
        const SizedBox(height: 8),
        ...state.filteredReports.map(
          (report) => LabPanelCard(
            report: report,
            onTap: () => _openBreakdownSheet(context, report),
            onToggleBookmark: () => notifier.toggleBookmark(report.id),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    LabsState state,
    LabsNotifier notifier,
  ) {
    final selectedReport =
        state.selectedReport ??
        (state.filteredReports.isNotEmpty ? state.filteredReports.first : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Pane: Lab Panels List
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCategoryFilters(context, state, notifier),
                const SizedBox(height: 12),
                _buildVaultHeader(context, state.filteredReports.length),
                const SizedBox(height: 8),
                ...state.filteredReports.map(
                  (report) => LabPanelCard(
                    report: report,
                    onTap: () => notifier.selectReport(report),
                    onToggleBookmark: () => notifier.toggleBookmark(report.id),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        // Right Pane: Selected Panel Details & Biomarker Bars
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: selectedReport == null
                ? const Center(
                    child: Text('Select a panel to inspect biomarkers'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedReport.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_rounded),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    ShareExportLabSheet(report: selectedReport),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...selectedReport.biomarkers.map(
                        (bm) => BiomarkerRangeBar(biomarker: bm),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(
    BuildContext context,
    LabsState state,
    LabsNotifier notifier,
  ) {
    final categories = [
      'All',
      'Hematology',
      'Cardiovascular',
      'Endocrine',
      'Nutritional',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...categories.map((cat) {
            final isSelected =
                (state.selectedCategory == null && cat == 'All') ||
                state.selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(cat, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (_) {
                  notifier.setCategory(cat == 'All' ? null : cat);
                },
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          FilterChip(
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_rounded, size: 14),
                SizedBox(width: 4),
                Text('Bookmarked', style: TextStyle(fontSize: 11)),
              ],
            ),
            selected: state.onlyBookmarked,
            onSelected: (val) => notifier.toggleBookmarkedOnly(val),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildVaultHeader(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.folder_shared_outlined,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Diagnostic Panels Vault ($count)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
