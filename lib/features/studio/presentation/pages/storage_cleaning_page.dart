import 'package:aurora/features/cleaner/domain/cleaner_models.dart';
import 'package:aurora/features/cleaner/presentation/cleaner_provider.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/features/studio/presentation/widgets/studio_cleanup_components.dart';
import 'package:aurora/features/studio/presentation/widgets/studio_surface_components.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _DesktopSizeFilter {
  all,
  oneToTenMb,
  tenToHundredMb,
  overHundredMb,
}

class StudioStorageCleaningPage extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const StudioStorageCleaningPage({
    super.key,
    required this.onBack,
  });

  @override
  ConsumerState<StudioStorageCleaningPage> createState() =>
      _StudioStorageCleaningPageState();
}

class _StudioStorageCleaningPageState
    extends ConsumerState<StudioStorageCleaningPage> {
  final List<String> _selectedRoots = <String>[];
  bool _detectDuplicates = true;
  bool _deleteReviewRequired = false;
  _DesktopSizeFilter _sizeFilter = _DesktopSizeFilter.all;
  CleanerRiskLevel? _riskFilter;
  Set<String> _selectedCandidateIds = <String>{};

  bool get _isZh {
    return Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
  }

  String _t(String zh, String en) => _isZh ? zh : en;

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

  Future<void> _runAnalyze() async {
    final notifier = ref.read(cleanerProvider.notifier);
    final roots = List<String>.from(_selectedRoots);
    final hasUserRoots = roots.isNotEmpty;
    await notifier.analyze(
      options: CleanerScanOptions(
        includeAppCache: !hasUserRoots,
        includeTemporary: !hasUserRoots,
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
            (item) => item.finalDecision == CleanerDecision.deleteRecommend,
          )
          .map((item) => item.candidate.id)
          .toSet();
    });
  }

  Future<void> _continueAnalyze() async {
    final notifier = ref.read(cleanerProvider.notifier);
    await notifier.continueAnalyze();

    if (!mounted) return;
    final result = ref.read(cleanerProvider).runResult;
    if (result == null) return;
    setState(() {
      _selectedCandidateIds = result.items
          .where(
            (item) => item.finalDecision == CleanerDecision.deleteRecommend,
          )
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

  void _selectVisibleRecommendations(List<CleanerReviewItem> visibleItems) {
    final ids = visibleItems
        .where((item) => item.finalDecision == CleanerDecision.deleteRecommend)
        .map((item) => item.candidate.id)
        .toSet();
    setState(() {
      _selectedCandidateIds = ids;
    });
  }

  void _clearSelections() {
    setState(() {
      _selectedCandidateIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cleanerProvider);
    final hasBackground = ref.watch(
      settingsProvider.select(
        (s) =>
            s.useCustomTheme &&
            s.backgroundImagePath != null &&
            s.backgroundImagePath!.isNotEmpty,
      ),
    );
    final result = state.runResult;
    final summary = result?.summary;
    final allItems = result?.items ?? const <CleanerReviewItem>[];
    final filteredItems = _applyFilters(allItems);
    final sizeCounts = _buildSizeCounts(allItems);
    final riskCounts = _buildRiskCounts(allItems);
    final theme = FluentTheme.of(context);

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildHeader(
            theme: theme,
            state: state,
            summary: summary,
            hasBackground: hasBackground,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1180;
                if (compact) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildControlPanel(
                          theme: theme,
                          state: state,
                          hasBackground: hasBackground,
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryPanel(
                          theme: theme,
                          summary: summary,
                          sizeCounts: sizeCounts,
                          riskCounts: riskCounts,
                          hasBackground: hasBackground,
                        ),
                        const SizedBox(height: 12),
                        _buildFilterPanel(
                          theme: theme,
                          allItems: allItems,
                          filteredItems: filteredItems,
                          onSelectVisible: () =>
                              _selectVisibleRecommendations(filteredItems),
                          onClearSelection: _clearSelections,
                          hasBackground: hasBackground,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 560,
                          child: _buildResultsPanel(
                            theme: theme,
                            state: state,
                            visibleItems: filteredItems,
                            hasBackground: hasBackground,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 390,
                        child: SingleChildScrollView(
                          child: _buildControlPanel(
                            theme: theme,
                            state: state,
                            hasBackground: hasBackground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryPanel(
                              theme: theme,
                              summary: summary,
                              sizeCounts: sizeCounts,
                              riskCounts: riskCounts,
                              hasBackground: hasBackground,
                            ),
                            const SizedBox(height: 12),
                            _buildFilterPanel(
                              theme: theme,
                              allItems: allItems,
                              filteredItems: filteredItems,
                              onSelectVisible: () =>
                                  _selectVisibleRecommendations(filteredItems),
                              onClearSelection: _clearSelections,
                              hasBackground: hasBackground,
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _buildResultsPanel(
                                theme: theme,
                                state: state,
                                visibleItems: filteredItems,
                                hasBackground: hasBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required FluentThemeData theme,
    required CleanerState state,
    required CleanerRunSummary? summary,
    required bool hasBackground,
  }) {
    final statusText = state.isAnalyzing
        ? _t('分析中', 'Analyzing')
        : state.canContinueAnalyze
            ? _t('已暂停', 'Paused')
            : _t('待命', 'Ready');
    final statusColor = state.isAnalyzing
        ? Colors.orange
        : state.canContinueAnalyze
            ? Colors.yellow
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: StudioPanel(
        hasBackground: hasBackground,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(AuroraIcons.back, size: 18),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('智能清理', 'AI Cleanup'),
                        style: theme.typography.title?.copyWith(fontSize: 30),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _t(
                          '规则扫描 + AI 建议 + 策略护栏（全程可中止与继续）',
                          'Rule scan + AI advice + policy guardrails (stop/continue supported)',
                        ),
                        style: theme.typography.caption,
                      ),
                    ],
                  ),
                ),
                StudioStatusChip(
                  label: statusText,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StudioKpiChip(
                  icon: AuroraIcons.database,
                  label: _t('候选', 'Candidates'),
                  value: summary?.totalCandidates.toString() ?? '-',
                  hasBackground: hasBackground,
                ),
                StudioKpiChip(
                  icon: AuroraIcons.broom,
                  label: _t('建议删除', 'Delete'),
                  value: summary?.deleteRecommendedCount.toString() ?? '-',
                  hasBackground: hasBackground,
                ),
                StudioKpiChip(
                  icon: AuroraIcons.warning,
                  label: _t('需复核', 'Review'),
                  value: summary?.reviewRequiredCount.toString() ?? '-',
                  hasBackground: hasBackground,
                ),
                StudioKpiChip(
                  icon: AuroraIcons.download,
                  label: _t('预计释放', 'Est. Reclaim'),
                  value: summary == null
                      ? '-'
                      : _formatBytes(summary.estimatedReclaimBytes),
                  hasBackground: hasBackground,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel({
    required FluentThemeData theme,
    required CleanerState state,
    required bool hasBackground,
  }) {
    final selectedCount = _selectedCandidateIds.length;
    final progressValue = state.totalCandidates <= 0
        ? 0.0
        : state.processedCandidates / state.totalCandidates;

    return StudioPanel(
      hasBackground: hasBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudioSectionHeader(
            icon: AuroraIcons.folderOpen,
            title: _t('扫描配置', 'Scan Setup'),
            subtitle: _t(
              '可选目录优先；不选目录时走默认缓存/临时目录策略。',
              'Selected folders first; defaults to cache/temp roots otherwise.',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed:
                    state.isAnalyzing || state.isDeleting ? null : _pickFolder,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AuroraIcons.add, size: 12),
                    const SizedBox(width: 6),
                    Text(_t('添加文件夹', 'Add Folder')),
                  ],
                ),
              ),
              Button(
                onPressed: _selectedRoots.isEmpty ? null : _clearFolders,
                child: Text(_t('清空目录', 'Clear Folders')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _rootList(theme, hasBackground),
          const SizedBox(height: 12),
          Checkbox(
            checked: _detectDuplicates,
            content: Text(_t('启用重复文件检测', 'Detect Duplicates')),
            onChanged: (value) {
              setState(() {
                _detectDuplicates = value ?? true;
              });
            },
          ),
          Checkbox(
            checked: _deleteReviewRequired,
            content: Text(_t('按建议删除时包含“需复核”', 'Include Review On Delete')),
            onChanged: (value) {
              setState(() {
                _deleteReviewRequired = value ?? false;
              });
            },
          ),
          const SizedBox(height: 10),
          StudioSectionHeader(
            icon: AuroraIcons.zap,
            title: _t('执行操作', 'Actions'),
            subtitle: _t(
              '分析支持中止与继续；删除需手动触发。',
              'Analysis supports stop/continue; deletion is always manual.',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed:
                    state.isAnalyzing || state.isDeleting ? null : _runAnalyze,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.isAnalyzing)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: ProgressRing(strokeWidth: 2),
                        ),
                      )
                    else
                      const Icon(AuroraIcons.search, size: 12),
                    const SizedBox(width: 6),
                    Text(_t('开始分析', 'Start Analyze')),
                  ],
                ),
              ),
              Button(
                onPressed: state.isAnalyzing
                    ? (state.stopRequested
                        ? null
                        : () => ref
                            .read(cleanerProvider.notifier)
                            .requestStopAnalyze())
                    : (state.canContinueAnalyze && !state.isDeleting
                        ? _continueAnalyze
                        : null),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isAnalyzing ? AuroraIcons.stop : AuroraIcons.play,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isAnalyzing
                          ? (state.stopRequested
                              ? _t('中止中…', 'Stopping...')
                              : _t('中止', 'Stop'))
                          : _t('继续', 'Continue'),
                    ),
                  ],
                ),
              ),
              Button(
                onPressed: state.isDeleting || _selectedCandidateIds.isEmpty
                    ? null
                    : _deleteSelected,
                child: Text(
                  _t('删除已选($selectedCount)', 'Delete Selected($selectedCount)'),
                ),
              ),
              Button(
                onPressed: state.isDeleting || state.runResult == null
                    ? null
                    : _deleteByRecommendation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.isDeleting)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: ProgressRing(strokeWidth: 2),
                        ),
                      )
                    else
                      const Icon(AuroraIcons.broom, size: 12),
                    const SizedBox(width: 6),
                    Text(_t('按建议删除', 'Delete Recommended')),
                  ],
                ),
              ),
            ],
          ),
          if (state.totalCandidates > 0) ...[
            const SizedBox(height: 12),
            Text(
              _t(
                '进度 ${state.processedCandidates}/${state.totalCandidates} · 批次 ${state.processedBatches}/${state.totalBatches > 0 ? state.totalBatches : '?'}',
                'Progress ${state.processedCandidates}/${state.totalCandidates} · Batches ${state.processedBatches}/${state.totalBatches > 0 ? state.totalBatches : '?'}',
              ),
              style: theme.typography.caption,
            ),
            const SizedBox(height: 6),
            ProgressBar(value: progressValue.clamp(0.0, 1.0)),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 12),
            InfoBar(
              title: Text(_t('错误', 'Error')),
              severity: InfoBarSeverity.error,
              content: Text(state.error!),
            ),
          ],
          if (state.lastDeleteResult != null) ...[
            const SizedBox(height: 12),
            InfoBar(
              title: Text(_t('删除结果', 'Delete Result')),
              severity: InfoBarSeverity.success,
              content: Text(
                _t(
                  '释放 ${_formatBytes(state.lastDeleteResult!.totalFreedBytes)} · 成功 ${state.lastDeleteResult!.results.where((e) => e.success).length}/${state.lastDeleteResult!.results.length}',
                  'Freed ${_formatBytes(state.lastDeleteResult!.totalFreedBytes)} · Success ${state.lastDeleteResult!.results.where((e) => e.success).length}/${state.lastDeleteResult!.results.length}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryPanel({
    required FluentThemeData theme,
    required CleanerRunSummary? summary,
    required Map<_DesktopSizeFilter, int> sizeCounts,
    required Map<CleanerRiskLevel, int> riskCounts,
    required bool hasBackground,
  }) {
    if (summary == null) {
      return StudioPanel(
        hasBackground: hasBackground,
        child: SizedBox(
          height: 116,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AuroraIcons.database,
                  size: 24,
                  color: theme.inactiveColor,
                ),
                const SizedBox(width: 10),
                Text(
                  _t('尚未分析，先开始扫描。', 'No results yet. Start analysis first.'),
                  style: theme.typography.caption,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StudioPanel(
      hasBackground: hasBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudioSectionHeader(
            icon: AuroraIcons.stats,
            title: _t('分析总览', 'Analysis Overview'),
            subtitle:
                _t('按结果、体积、风险三组汇总。', 'Summarized by decision, size, and risk.'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StudioStatTile(
                label: _t('候选', 'Candidates'),
                value: summary.totalCandidates.toString(),
                color: Colors.blue,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: _t('建议删除', 'Delete'),
                value: summary.deleteRecommendedCount.toString(),
                color: Colors.green,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: _t('需复核', 'Review'),
                value: summary.reviewRequiredCount.toString(),
                color: Colors.orange,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: _t('保留', 'Keep'),
                value: summary.keepCount.toString(),
                color: Colors.grey,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: _t('预计释放', 'Est. Reclaim'),
                value: _formatBytes(summary.estimatedReclaimBytes),
                color: Colors.teal,
                wide: true,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: '1-10MB',
                value:
                    (sizeCounts[_DesktopSizeFilter.oneToTenMb] ?? 0).toString(),
                color: Colors.purple,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: '10-100MB',
                value: (sizeCounts[_DesktopSizeFilter.tenToHundredMb] ?? 0)
                    .toString(),
                color: Colors.blue,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: '>=100MB',
                value: (sizeCounts[_DesktopSizeFilter.overHundredMb] ?? 0)
                    .toString(),
                color: Colors.magenta,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: _t('低风险', 'Low Risk'),
                value: (riskCounts[CleanerRiskLevel.low] ?? 0).toString(),
                color: Colors.green,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: _t('中风险', 'Medium Risk'),
                value: (riskCounts[CleanerRiskLevel.medium] ?? 0).toString(),
                color: Colors.orange,
                hasBackground: hasBackground,
              ),
              StudioStatTile(
                label: _t('高风险', 'High Risk'),
                value: (riskCounts[CleanerRiskLevel.high] ?? 0).toString(),
                color: Colors.red,
                hasBackground: hasBackground,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel({
    required FluentThemeData theme,
    required List<CleanerReviewItem> allItems,
    required List<CleanerReviewItem> filteredItems,
    required VoidCallback onSelectVisible,
    required VoidCallback onClearSelection,
    required bool hasBackground,
  }) {
    return StudioPanel(
      hasBackground: hasBackground,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: InfoLabel(
                    label: _t('大小筛选', 'Size Filter'),
                    child: ComboBox<_DesktopSizeFilter>(
                      value: _sizeFilter,
                      isExpanded: true,
                      items: _DesktopSizeFilter.values
                          .map(
                            (filter) => ComboBoxItem<_DesktopSizeFilter>(
                              value: filter,
                              child: Text(_sizeFilterText(filter)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _sizeFilter = value;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: InfoLabel(
                    label: _t('风险筛选', 'Risk Filter'),
                    child: ComboBox<String>(
                      value: _riskFilterWireValue,
                      isExpanded: true,
                      items: [
                        ComboBoxItem(
                          value: 'all',
                          child: Text(_t('全部风险', 'All Risk')),
                        ),
                        ComboBoxItem(
                          value: CleanerRiskLevel.low.name,
                          child: Text(_t('低风险', 'Low Risk')),
                        ),
                        ComboBoxItem(
                          value: CleanerRiskLevel.medium.name,
                          child: Text(_t('中风险', 'Medium Risk')),
                        ),
                        ComboBoxItem(
                          value: CleanerRiskLevel.high.name,
                          child: Text(_t('高风险', 'High Risk')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _riskFilter = switch (value) {
                            'all' => null,
                            'low' => CleanerRiskLevel.low,
                            'medium' => CleanerRiskLevel.medium,
                            'high' => CleanerRiskLevel.high,
                            _ => null,
                          };
                        });
                      },
                    ),
                  ),
                ),
                Text(
                  _t(
                    '当前显示 ${filteredItems.length}/${allItems.length}',
                    'Showing ${filteredItems.length}/${allItems.length}',
                  ),
                  style: theme.typography.caption,
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Button(
                onPressed: filteredItems.isEmpty ? null : onSelectVisible,
                child: Text(_t('选中可删项', 'Select Deletable')),
              ),
              Button(
                onPressed:
                    _selectedCandidateIds.isEmpty ? null : onClearSelection,
                child: Text(_t('清空选择', 'Clear Selection')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel({
    required FluentThemeData theme,
    required CleanerState state,
    required List<CleanerReviewItem> visibleItems,
    required bool hasBackground,
  }) {
    return StudioPanel(
      hasBackground: hasBackground,
      child: _buildResultList(
        theme: theme,
        state: state,
        visibleItems: visibleItems,
        hasBackground: hasBackground,
      ),
    );
  }

  Widget _buildResultList({
    required FluentThemeData theme,
    required CleanerState state,
    required List<CleanerReviewItem> visibleItems,
    required bool hasBackground,
  }) {
    final result = state.runResult;
    final isDark = theme.brightness == Brightness.dark;
    final itemFill = hasBackground
        ? (isDark
            ? theme.cardColor.withValues(alpha: 0.54)
            : Colors.white.withValues(alpha: 0.72))
        : (isDark
            ? Color.lerp(theme.cardColor, Colors.black, 0.06)!
            : Color.lerp(theme.cardColor, Colors.white, 0.30)!);

    if (state.isAnalyzing && result == null) {
      return StudioEmptyState(
        icon: AuroraIcons.search,
        title: _t('正在扫描与分析', 'Scanning and Analyzing'),
        subtitle:
            _t('稍候，候选项会实时出现。', 'Please wait; candidates appear in real time.'),
        loading: true,
      );
    }

    if (result == null || result.items.isEmpty) {
      return StudioEmptyState(
        icon: AuroraIcons.database,
        title: _t('准备就绪', 'Ready'),
        subtitle: _t('点击“开始分析”启动扫描', 'Click "Start Analyze" to begin'),
      );
    }

    if (visibleItems.isEmpty) {
      return StudioEmptyState(
        icon: AuroraIcons.parameter,
        title: _t('筛选后无结果', 'No Results'),
        subtitle: _t('调整大小或风险筛选条件。', 'Adjust size/risk filters.'),
      );
    }

    return ListView.separated(
      itemCount: visibleItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = visibleItems[index];
        final selectable = item.finalDecision != CleanerDecision.keep;
        final checked = _selectedCandidateIds.contains(item.candidate.id);
        final sourceTag = item.candidate.tags
            .where((tag) => tag.startsWith('windows_group:'));
        final windowsGroup = sourceTag.isEmpty
            ? null
            : sourceTag.first.replaceFirst('windows_group:', '');

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.resources.surfaceStrokeColorDefault,
            ),
            color: itemFill,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    checked: checked,
                    onChanged: selectable
                        ? (value) {
                            setState(() {
                              if (value ?? false) {
                                _selectedCandidateIds.add(item.candidate.id);
                              } else {
                                _selectedCandidateIds.remove(item.candidate.id);
                              }
                            });
                          }
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.candidate.path,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.bodyStrong,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            StudioTag(
                              text: _decisionText(item.finalDecision),
                              color: _decisionColor(item.finalDecision),
                              hasBackground: hasBackground,
                            ),
                            StudioTag(
                              text: _riskText(item.finalRiskLevel),
                              color: _riskColor(item.finalRiskLevel),
                              hasBackground: hasBackground,
                            ),
                            StudioTag(
                              text:
                                  '${_formatBytes(item.candidate.sizeBytes)} · ${_sizeBucketLabel(item.candidate.sizeBytes)}',
                              color: Colors.grey,
                              hasBackground: hasBackground,
                            ),
                            StudioTag(
                              text:
                                  '${_t('置信度', 'Confidence')} ${(item.aiSuggestion.confidence * 100).toStringAsFixed(0)}%',
                              color: Colors.blue,
                              hasBackground: hasBackground,
                            ),
                            if (windowsGroup != null)
                              StudioTag(
                                text: _t(
                                    '规则:$windowsGroup', 'Rule:$windowsGroup'),
                                color: Colors.teal,
                                hasBackground: hasBackground,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.aiSuggestion.humanReason,
                style: theme.typography.caption,
              ),
              if (item.policyReasons.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${_t('策略护栏', 'Policy Guard')}: ${item.policyReasons.join(', ')}',
                  style: theme.typography.caption?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _rootList(FluentThemeData theme, bool hasBackground) {
    final isDark = theme.brightness == Brightness.dark;
    final listFill = hasBackground
        ? (isDark
            ? theme.cardColor.withValues(alpha: 0.52)
            : Colors.white.withValues(alpha: 0.70))
        : (isDark
            ? Color.lerp(theme.cardColor, Colors.black, 0.08)!
            : Color.lerp(theme.cardColor, Colors.white, 0.22)!);
    final chipFill = hasBackground
        ? (isDark
            ? theme.cardColor.withValues(alpha: 0.60)
            : Colors.white.withValues(alpha: 0.76))
        : (isDark
            ? Color.lerp(theme.cardColor, Colors.black, 0.12)!
            : Color.lerp(theme.cardColor, Colors.black, 0.03)!);

    if (_selectedRoots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.resources.surfaceStrokeColorDefault),
          color: listFill,
        ),
        child: Text(
          _t(
            '当前使用默认模式：扫描应用缓存与临时目录。',
            'Using default mode: app cache and temp roots.',
          ),
          style: theme.typography.caption,
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 170),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.resources.surfaceStrokeColorDefault),
        color: listFill,
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedRoots.map((path) {
            return Container(
              constraints: const BoxConstraints(maxWidth: 338),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: chipFill,
                border: Border.all(
                    color: theme.resources.surfaceStrokeColorDefault),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AuroraIcons.folder, size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeFolder(path),
                    child: const Icon(AuroraIcons.close, size: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _decisionText(CleanerDecision decision) {
    switch (decision) {
      case CleanerDecision.deleteRecommend:
        return _t('建议删除', 'Delete');
      case CleanerDecision.reviewRequired:
        return _t('需复核', 'Review');
      case CleanerDecision.keep:
        return _t('保留', 'Keep');
    }
  }

  String _riskText(CleanerRiskLevel riskLevel) {
    switch (riskLevel) {
      case CleanerRiskLevel.low:
        return _t('低风险', 'Low Risk');
      case CleanerRiskLevel.medium:
        return _t('中风险', 'Medium Risk');
      case CleanerRiskLevel.high:
        return _t('高风险', 'High Risk');
    }
  }

  Color _decisionColor(CleanerDecision decision) {
    switch (decision) {
      case CleanerDecision.deleteRecommend:
        return Colors.green;
      case CleanerDecision.reviewRequired:
        return Colors.orange;
      case CleanerDecision.keep:
        return Colors.grey;
    }
  }

  Color _riskColor(CleanerRiskLevel riskLevel) {
    switch (riskLevel) {
      case CleanerRiskLevel.low:
        return Colors.green;
      case CleanerRiskLevel.medium:
        return Colors.orange;
      case CleanerRiskLevel.high:
        return Colors.red;
    }
  }

  String get _riskFilterWireValue => _riskFilter?.name ?? 'all';

  String _sizeFilterText(_DesktopSizeFilter filter) {
    switch (filter) {
      case _DesktopSizeFilter.all:
        return _t('全部大小', 'All Size');
      case _DesktopSizeFilter.oneToTenMb:
        return '1-10MB';
      case _DesktopSizeFilter.tenToHundredMb:
        return '10-100MB';
      case _DesktopSizeFilter.overHundredMb:
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

  Map<_DesktopSizeFilter, int> _buildSizeCounts(List<CleanerReviewItem> items) {
    final counts = <_DesktopSizeFilter, int>{
      _DesktopSizeFilter.oneToTenMb: 0,
      _DesktopSizeFilter.tenToHundredMb: 0,
      _DesktopSizeFilter.overHundredMb: 0,
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

  bool _matchesSizeFilter(int bytes, _DesktopSizeFilter filter) {
    switch (filter) {
      case _DesktopSizeFilter.all:
        return true;
      case _DesktopSizeFilter.oneToTenMb:
        return bytes >= 1024 * 1024 && bytes < 10 * 1024 * 1024;
      case _DesktopSizeFilter.tenToHundredMb:
        return bytes >= 10 * 1024 * 1024 && bytes < 100 * 1024 * 1024;
      case _DesktopSizeFilter.overHundredMb:
        return bytes >= 100 * 1024 * 1024;
    }
  }

  _DesktopSizeFilter? _sizeBucketForBytes(int bytes) {
    if (bytes >= 100 * 1024 * 1024) {
      return _DesktopSizeFilter.overHundredMb;
    }
    if (bytes >= 10 * 1024 * 1024) {
      return _DesktopSizeFilter.tenToHundredMb;
    }
    if (bytes >= 1024 * 1024) {
      return _DesktopSizeFilter.oneToTenMb;
    }
    return null;
  }

  String _sizeBucketLabel(int bytes) {
    final bucket = _sizeBucketForBytes(bytes);
    if (bucket == null) {
      return '<1MB';
    }
    return switch (bucket) {
      _DesktopSizeFilter.oneToTenMb => '1-10MB',
      _DesktopSizeFilter.tenToHundredMb => '10-100MB',
      _DesktopSizeFilter.overHundredMb => '>=100MB',
      _DesktopSizeFilter.all => '<1MB',
    };
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
