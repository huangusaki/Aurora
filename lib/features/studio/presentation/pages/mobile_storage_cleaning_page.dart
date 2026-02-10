import 'package:aurora/features/cleaner/domain/cleaner_models.dart';
import 'package:aurora/features/cleaner/presentation/cleaner_provider.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/settings/presentation/widgets/mobile_settings_widgets.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _MobileSizeFilter {
  all,
  oneToTenMb,
  tenToHundredMb,
  overHundredMb,
}

const String _mobileDefaultExecutionModelKey = '__default_execution_model__';

class _MobileExecutionModelChoice {
  final String key;
  final String label;
  final String? model;
  final String? providerId;

  const _MobileExecutionModelChoice({
    required this.key,
    required this.label,
    required this.model,
    required this.providerId,
  });
}

class MobileStorageCleaningPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const MobileStorageCleaningPage({super.key, this.onBack});

  @override
  ConsumerState<MobileStorageCleaningPage> createState() =>
      _MobileStorageCleaningPageState();
}

class _MobileStorageCleaningPageState
    extends ConsumerState<MobileStorageCleaningPage> {
  final List<String> _selectedRoots = <String>[];
  bool _detectDuplicates = true;
  bool _deleteReviewRequired = false;
  _MobileSizeFilter _sizeFilter = _MobileSizeFilter.all;
  CleanerRiskLevel? _riskFilter;
  Set<String> _selectedCandidateIds = <String>{};

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  // ─── Business logic (unchanged) ────────────────────────────────

  Future<void> _pickFolder() async {
    final path = await getDirectoryPath();
    if (path == null || path.trim().isEmpty) return;

    setState(() {
      if (!_selectedRoots.contains(path)) {
        _selectedRoots.add(path);
      }
    });
  }

  void _removeFolder(String path) {
    setState(() {
      _selectedRoots.remove(path);
    });
  }

  void _clearFolders() {
    setState(() {
      _selectedRoots.clear();
    });
  }

  List<_MobileExecutionModelChoice> _buildExecutionModelChoices(
      SettingsState settings) {
    final choices = <_MobileExecutionModelChoice>[
      _MobileExecutionModelChoice(
        key: _mobileDefaultExecutionModelKey,
        label: _l10n.cleanerExecutionModelDefaultChat,
        model: null,
        providerId: null,
      ),
    ];

    for (final provider in settings.providers) {
      if (!provider.isEnabled || provider.models.isEmpty) {
        continue;
      }
      for (final model in provider.models) {
        if (!provider.isModelEnabled(model)) {
          continue;
        }
        choices.add(
          _MobileExecutionModelChoice(
            key: '${provider.id}::$model',
            label: '${provider.name} - $model',
            model: model,
            providerId: provider.id,
          ),
        );
      }
    }
    return choices;
  }

  String _currentExecutionModelChoiceKey(
    SettingsState settings,
    List<_MobileExecutionModelChoice> choices,
  ) {
    final model = settings.executionModel;
    if (model == null || model.trim().isEmpty) {
      return _mobileDefaultExecutionModelKey;
    }
    final providerId =
        (settings.executionProviderId ?? settings.activeProviderId).trim();
    final key = '$providerId::$model';
    final exists = choices.any((choice) => choice.key == key);
    return exists ? key : _mobileDefaultExecutionModelKey;
  }

  void _setExecutionModelByKey(
    String key,
    List<_MobileExecutionModelChoice> choices,
  ) {
    if (key == _mobileDefaultExecutionModelKey) {
      ref
          .read(settingsProvider.notifier)
          .setExecutionSettings(model: null, providerId: null);
      return;
    }

    for (final choice in choices) {
      if (choice.key != key) continue;
      ref.read(settingsProvider.notifier).setExecutionSettings(
            model: choice.model,
            providerId: choice.providerId,
          );
      return;
    }
  }

  Future<void> _runAnalyze() async {
    final notifier = ref.read(cleanerProvider.notifier);
    final roots = List<String>.from(_selectedRoots);
    final hasUserRoots = roots.isNotEmpty;

    await notifier.analyze(
      options: CleanerScanOptions(
        includeAppCache: true,
        includeTemporary: true,
        includeCommonUserRoots: true,
        additionalRootPaths: roots,
        includeUserSelectedRoots: hasUserRoots,
        includeUnknownInUserSelectedRoots: hasUserRoots,
        detectDuplicates: _detectDuplicates,
      ),
    );

    if (!mounted) return;
    final result = ref.read(cleanerProvider).runResult;
    if (result == null) return;
    setState(() {
      _selectedCandidateIds = result.items
          .where(
              (item) => item.finalDecision == CleanerDecision.deleteRecommend)
          .map((item) => item.candidate.id)
          .toSet();
    });
  }

  Future<void> _continueAnalyze() async {
    await ref.read(cleanerProvider.notifier).continueAnalyze();
    if (!mounted) return;
    final result = ref.read(cleanerProvider).runResult;
    if (result == null) return;
    setState(() {
      _selectedCandidateIds = result.items
          .where(
              (item) => item.finalDecision == CleanerDecision.deleteRecommend)
          .map((item) => item.candidate.id)
          .toSet();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedCandidateIds.isEmpty) return;
    await ref
        .read(cleanerProvider.notifier)
        .deleteByIds(_selectedCandidateIds.toList());
  }

  Future<void> _deleteByRecommendation() async {
    await ref.read(cleanerProvider.notifier).deleteRecommended(
          includeReviewRequired: _deleteReviewRequired,
        );
  }

  // ─── UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cleanerProvider);
    final settings = ref.watch(settingsProvider);
    final result = state.runResult;
    final summary = result?.summary;
    final allItems = result?.items ?? const <CleanerReviewItem>[];
    final filteredItems = _applyFilters(allItems);
    final theme = Theme.of(context);
    final l10n = _l10n;

    final executionModelChoices = _buildExecutionModelChoices(settings);
    final executionModelChoiceKey =
        _currentExecutionModelChoiceKey(settings, executionModelChoices);
    final currentModelLabel = executionModelChoices
        .firstWhere((c) => c.key == executionModelChoiceKey,
            orElse: () => executionModelChoices.first)
        .label;

    final busy = state.isAnalyzing || state.isDeleting;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.cleanerTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(AuroraIcons.back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── 1. Config Section ──
          MobileSettingsSection(
            title: l10n.cleanerRuleAiPolicyTitle,
            children: [
              MobileSettingsTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: l10n.executionModel,
                subtitle: currentModelLabel,
                onTap: busy
                    ? null
                    : () => _showExecutionModelPicker(
                          executionModelChoices,
                          executionModelChoiceKey,
                        ),
              ),
              MobileSettingsTile(
                leading: const Icon(AuroraIcons.folderOpen),
                title: l10n.cleanerAddExtraFolder,
                subtitle: _selectedRoots.isEmpty
                    ? l10n.cleanerAutoModeHint
                    : l10n.cleanerShowingCount(
                        _selectedRoots.length, _selectedRoots.length),
                onTap: busy ? null : _pickFolder,
                trailing: _selectedRoots.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            size: 18, color: theme.hintColor),
                        onPressed: busy ? null : _clearFolders,
                        tooltip: l10n.cleanerClearFolders,
                      )
                    : null,
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.file_copy_outlined),
                title: l10n.cleanerDetectDuplicates,
                showChevron: false,
                trailing: Switch.adaptive(
                  value: _detectDuplicates,
                  onChanged: (v) => setState(() => _detectDuplicates = v),
                ),
                onTap: () =>
                    setState(() => _detectDuplicates = !_detectDuplicates),
              ),
            ],
          ),

          // ── Selected folders chips ──
          if (_selectedRoots.isNotEmpty) _buildFolderChips(theme),

          // ── Android storage note ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            child: Text(
              l10n.cleanerAndroidStorageRestriction,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontSize: 11,
              ),
            ),
          ),

          // ── 2. Actions Section ──
          const SizedBox(height: 4),
          _buildActionSection(state, l10n, theme),

          // ── Error ──
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Freed notification ──
          if (state.lastDeleteResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.cleanerFreedBytesOnly(
                        _formatBytes(state.lastDeleteResult!.totalFreedBytes),
                      ),
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

          // ── 3. Summary Section ──
          if (summary != null) _buildSummarySection(summary, allItems, theme, l10n),

          // ── 4. Filter & Delete Section ──
          if (allItems.isNotEmpty)
            _buildFilterSection(state, allItems, filteredItems, theme, l10n),

          // ── 5. Results List ──
          if (allItems.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildCandidateList(state, filteredItems, theme, l10n),
          ] else if (!state.isAnalyzing) ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(AuroraIcons.broom,
                      size: 48, color: theme.hintColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.cleanerNoCandidatesYet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Action Section ────────────────────────────────────────────

  Widget _buildActionSection(
      CleanerState state, AppLocalizations l10n, ThemeData theme) {
    final busy = state.isAnalyzing || state.isDeleting;
    final progress = state.totalCandidates > 0
        ? state.processedCandidates / state.totalCandidates
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main action button
          FilledButton.icon(
            onPressed: busy ? null : _runAnalyze,
            icon: state.isAnalyzing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(AuroraIcons.search),
            label: Text(l10n.cleanerStartAnalyze),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          // Progress indicator during analysis
          if (state.isAnalyzing && state.totalCandidates > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor:
                    theme.primaryColor.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.cleanerProgressLine(
                state.processedCandidates,
                state.totalCandidates,
                state.processedBatches,
                state.totalBatches > 0 ? '${state.totalBatches}' : '?',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Continue / Stop
          if (state.isAnalyzing || state.canContinueAnalyze) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: state.isAnalyzing
                  ? (state.stopRequested
                      ? null
                      : () =>
                          ref.read(cleanerProvider.notifier).requestStopAnalyze())
                  : (state.canContinueAnalyze && !state.isDeleting
                      ? _continueAnalyze
                      : null),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                state.isAnalyzing
                    ? (state.stopRequested
                        ? l10n.cleanerStopping
                        : l10n.cleanerStop)
                    : l10n.cleanerContinue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Summary Section ───────────────────────────────────────────

  Widget _buildSummarySection(CleanerRunSummary summary,
      List<CleanerReviewItem> allItems, ThemeData theme, AppLocalizations l10n) {
    final sizeCounts = _buildSizeCounts(allItems);
    final riskCounts = _buildRiskCounts(allItems);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              l10n.cleanerRuleAiPolicyTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip(
                icon: Icons.analytics_outlined,
                label: l10n.cleanerCandidates,
                value: '${summary.totalCandidates}',
                color: theme.primaryColor,
                theme: theme,
              ),
              _buildStatChip(
                icon: Icons.delete_outline,
                label: l10n.cleanerDelete,
                value: '${summary.deleteRecommendedCount}',
                color: Colors.red,
                theme: theme,
              ),
              _buildStatChip(
                icon: Icons.rate_review_outlined,
                label: l10n.cleanerReview,
                value: '${summary.reviewRequiredCount}',
                color: Colors.orange,
                theme: theme,
              ),
              _buildStatChip(
                icon: Icons.storage_outlined,
                label: l10n.cleanerEstimatedReclaim,
                value: _formatBytes(summary.estimatedReclaimBytes),
                color: Colors.green,
                theme: theme,
              ),
              _buildStatChip(
                icon: Icons.shield_outlined,
                label: l10n.cleanerRiskLow,
                value: '${riskCounts[CleanerRiskLevel.low] ?? 0}',
                color: Colors.green,
                theme: theme,
              ),
              _buildStatChip(
                icon: Icons.warning_amber,
                label: l10n.cleanerRiskMedium,
                value: '${riskCounts[CleanerRiskLevel.medium] ?? 0}',
                color: Colors.orange,
                theme: theme,
              ),
              _buildStatChip(
                icon: Icons.error_outline,
                label: l10n.cleanerRiskHigh,
                value: '${riskCounts[CleanerRiskLevel.high] ?? 0}',
                color: Colors.red,
                theme: theme,
              ),
              _buildStatChip(
                icon: Icons.folder_outlined,
                label: '1-10MB',
                value: '${sizeCounts[_MobileSizeFilter.oneToTenMb] ?? 0}',
                color: theme.hintColor,
                theme: theme,
              ),
              _buildStatChip(
                icon: Icons.folder,
                label: '10-100MB',
                value: '${sizeCounts[_MobileSizeFilter.tenToHundredMb] ?? 0}',
                color: theme.hintColor,
                theme: theme,
              ),
              _buildStatChip(
                icon: Icons.folder_special,
                label: '≥100MB',
                value: '${sizeCounts[_MobileSizeFilter.overHundredMb] ?? 0}',
                color: theme.hintColor,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter & Delete Section ───────────────────────────────────

  Widget _buildFilterSection(
    CleanerState state,
    List<CleanerReviewItem> allItems,
    List<CleanerReviewItem> filteredItems,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return MobileSettingsSection(
      title: l10n.cleanerClassificationFilter,
      children: [
        MobileSettingsTile(
          leading: const Icon(Icons.straighten),
          title: l10n.cleanerAllSize,
          subtitle: _sizeFilterText(_sizeFilter),
          onTap: () => _showSizeFilterPicker(l10n),
        ),
        MobileSettingsTile(
          leading: const Icon(Icons.security),
          title: l10n.cleanerAllRisk,
          subtitle: _riskFilter == null
              ? l10n.cleanerAllRisk
              : _riskText(_riskFilter!),
          onTap: () => _showRiskFilterPicker(l10n),
        ),
        MobileSettingsTile(
          leading: const Icon(Icons.checklist),
          title: l10n.cleanerIncludeReviewRequiredItems,
          showChevron: false,
          trailing: Switch.adaptive(
            value: _deleteReviewRequired,
            onChanged: (v) => setState(() => _deleteReviewRequired = v),
          ),
          onTap: () =>
              setState(() => _deleteReviewRequired = !_deleteReviewRequired),
        ),
      ],
    );
  }

  // ─── Folder Chips ──────────────────────────────────────────────

  Widget _buildFolderChips(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _selectedRoots.map((path) {
          final shortName =
              path.length > 30 ? '...${path.substring(path.length - 27)}' : path;
          return Chip(
            avatar: Icon(AuroraIcons.folder,
                size: 14, color: theme.primaryColor),
            label: Text(shortName, style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () => _removeFolder(path),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Candidate List ────────────────────────────────────────────

  Widget _buildCandidateList(
    CleanerState state,
    List<CleanerReviewItem> visibleItems,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (state.isAnalyzing && state.runResult == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (visibleItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.cleanerNoItemsUnderFilters,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
      );
    }

    // Delete action buttons + count header + list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delete buttons row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.isDeleting || _selectedCandidateIds.isEmpty
                      ? null
                      : _deleteSelected,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(
                    l10n.cleanerDeleteSelectedCount(
                        _selectedCandidateIds.length),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isDeleting || state.runResult == null
                      ? null
                      : _deleteByRecommendation,
                  icon: const Icon(Icons.auto_delete_outlined, size: 16),
                  label: Text(
                    l10n.cleanerDeleteRecommended,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            l10n.cleanerShowingCount(
                visibleItems.length, state.runResult?.items.length ?? 0),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ),

        // List
        ...visibleItems.map((item) {
          final selectable = item.finalDecision != CleanerDecision.keep;
          final checked = _selectedCandidateIds.contains(item.candidate.id);
          final riskColor = _riskColor(item.finalRiskLevel);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: checked,
                onChanged: selectable
                    ? (v) {
                        setState(() {
                          if (v ?? false) {
                            _selectedCandidateIds.add(item.candidate.id);
                          } else {
                            _selectedCandidateIds.remove(item.candidate.id);
                          }
                        });
                      }
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                title: Text(
                  item.candidate.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildTag(
                        _decisionText(item.finalDecision),
                        item.finalDecision == CleanerDecision.deleteRecommend
                            ? Colors.red
                            : (item.finalDecision ==
                                    CleanerDecision.reviewRequired
                                ? Colors.orange
                                : Colors.green),
                      ),
                      _buildTag(_riskText(item.finalRiskLevel), riskColor),
                      _buildTag(
                        _formatBytes(item.candidate.sizeBytes),
                        Theme.of(context).hintColor,
                      ),
                      if (item.aiSuggestion.humanReason.isNotEmpty)
                        Text(
                          item.aiSuggestion.humanReason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: Theme.of(context).hintColor),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // ─── Bottom‐Sheet Pickers ──────────────────────────────────────

  void _showExecutionModelPicker(
    List<_MobileExecutionModelChoice> choices,
    String currentKey,
  ) {
    final l10n = _l10n;
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(ctx, l10n.executionModel),
            const Divider(height: 1),
            ...choices.map((choice) {
              final selected = choice.key == currentKey;
              return AuroraBottomSheet.buildListItem(
                context: ctx,
                title: Text(choice.label),
                selected: selected,
                trailing: selected
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).primaryColor, size: 18)
                    : null,
                onTap: () {
                  _setExecutionModelByKey(choice.key, choices);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSizeFilterPicker(AppLocalizations l10n) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(ctx, l10n.cleanerAllSize),
          const Divider(height: 1),
          ..._MobileSizeFilter.values.map((filter) {
            final selected = filter == _sizeFilter;
            return AuroraBottomSheet.buildListItem(
              context: ctx,
              title: Text(_sizeFilterText(filter)),
              selected: selected,
              trailing: selected
                  ? Icon(Icons.check,
                      color: Theme.of(ctx).primaryColor, size: 18)
                  : null,
              onTap: () {
                setState(() => _sizeFilter = filter);
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showRiskFilterPicker(AppLocalizations l10n) {
    final options = <(String, CleanerRiskLevel?)>[
      (l10n.cleanerAllRisk, null),
      (l10n.cleanerRiskLow, CleanerRiskLevel.low),
      (l10n.cleanerRiskMedium, CleanerRiskLevel.medium),
      (l10n.cleanerRiskHigh, CleanerRiskLevel.high),
    ];

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(ctx, l10n.cleanerAllRisk),
          const Divider(height: 1),
          ...options.map((opt) {
            final selected = opt.$2 == _riskFilter;
            return AuroraBottomSheet.buildListItem(
              context: ctx,
              title: Text(opt.$1),
              selected: selected,
              trailing: selected
                  ? Icon(Icons.check,
                      color: Theme.of(ctx).primaryColor, size: 18)
                  : null,
              onTap: () {
                setState(() => _riskFilter = opt.$2);
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  Color _riskColor(CleanerRiskLevel level) {
    switch (level) {
      case CleanerRiskLevel.low:
        return Colors.green;
      case CleanerRiskLevel.medium:
        return Colors.orange;
      case CleanerRiskLevel.high:
        return Colors.red;
    }
  }

  String _decisionText(CleanerDecision decision) {
    switch (decision) {
      case CleanerDecision.deleteRecommend:
        return _l10n.cleanerDelete;
      case CleanerDecision.reviewRequired:
        return _l10n.cleanerReview;
      case CleanerDecision.keep:
        return _l10n.cleanerKeep;
    }
  }

  String _riskText(CleanerRiskLevel riskLevel) {
    switch (riskLevel) {
      case CleanerRiskLevel.low:
        return _l10n.cleanerRiskLow;
      case CleanerRiskLevel.medium:
        return _l10n.cleanerRiskMedium;
      case CleanerRiskLevel.high:
        return _l10n.cleanerRiskHigh;
    }
  }

  String _sizeFilterText(_MobileSizeFilter filter) {
    switch (filter) {
      case _MobileSizeFilter.all:
        return _l10n.cleanerAllSize;
      case _MobileSizeFilter.oneToTenMb:
        return '1-10MB';
      case _MobileSizeFilter.tenToHundredMb:
        return '10-100MB';
      case _MobileSizeFilter.overHundredMb:
        return '>=100MB';
    }
  }

  List<CleanerReviewItem> _applyFilters(List<CleanerReviewItem> items) {
    return items.where((item) {
      if (!_matchesSizeFilter(item.candidate.sizeBytes, _sizeFilter)) {
        return false;
      }
      if (_riskFilter != null && item.finalRiskLevel != _riskFilter) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  Map<_MobileSizeFilter, int> _buildSizeCounts(List<CleanerReviewItem> items) {
    final counts = <_MobileSizeFilter, int>{
      _MobileSizeFilter.oneToTenMb: 0,
      _MobileSizeFilter.tenToHundredMb: 0,
      _MobileSizeFilter.overHundredMb: 0,
    };
    for (final item in items) {
      final bucket = _sizeBucketForBytes(item.candidate.sizeBytes);
      if (bucket == null) continue;
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  Map<CleanerRiskLevel, int> _buildRiskCounts(List<CleanerReviewItem> items) {
    final counts = <CleanerRiskLevel, int>{
      CleanerRiskLevel.low: 0,
      CleanerRiskLevel.medium: 0,
      CleanerRiskLevel.high: 0,
    };
    for (final item in items) {
      counts[item.finalRiskLevel] = (counts[item.finalRiskLevel] ?? 0) + 1;
    }
    return counts;
  }

  bool _matchesSizeFilter(int bytes, _MobileSizeFilter filter) {
    switch (filter) {
      case _MobileSizeFilter.all:
        return true;
      case _MobileSizeFilter.oneToTenMb:
        return bytes >= 1024 * 1024 && bytes < 10 * 1024 * 1024;
      case _MobileSizeFilter.tenToHundredMb:
        return bytes >= 10 * 1024 * 1024 && bytes < 100 * 1024 * 1024;
      case _MobileSizeFilter.overHundredMb:
        return bytes >= 100 * 1024 * 1024;
    }
  }

  _MobileSizeFilter? _sizeBucketForBytes(int bytes) {
    if (bytes >= 100 * 1024 * 1024) {
      return _MobileSizeFilter.overHundredMb;
    }
    if (bytes >= 10 * 1024 * 1024) {
      return _MobileSizeFilter.tenToHundredMb;
    }
    if (bytes >= 1024 * 1024) {
      return _MobileSizeFilter.oneToTenMb;
    }
    return null;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    final fractionDigits = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
    return '${value.toStringAsFixed(fractionDigits)} ${units[index]}';
  }
}
