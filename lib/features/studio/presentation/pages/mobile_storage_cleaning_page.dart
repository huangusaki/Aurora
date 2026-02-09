import 'package:aurora/features/cleaner/domain/cleaner_models.dart';
import 'package:aurora/features/cleaner/presentation/cleaner_provider.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _MobileSizeFilter {
  all,
  oneToTenMb,
  tenToHundredMb,
  overHundredMb,
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
  bool _deleteReviewRequired = false;
  _MobileSizeFilter _sizeFilter = _MobileSizeFilter.all;
  CleanerRiskLevel? _riskFilter;
  Set<String> _selectedCandidateIds = <String>{};

  bool get _isZh {
    return Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
  }

  String _t(String zh, String en) => _isZh ? zh : en;

  Future<void> _runAnalyze() async {
    await ref.read(cleanerProvider.notifier).analyze();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cleanerProvider);
    final result = state.runResult;
    final summary = result?.summary;
    final allItems = result?.items ?? const <CleanerReviewItem>[];
    final filteredItems = _applyFilters(allItems);
    final sizeCounts = _buildSizeCounts(allItems);
    final riskCounts = _buildRiskCounts(allItems);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_t('智能清理', 'AI Cleanup')),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(AuroraIcons.back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        '规则扫描 + AI 建议 + 策略护栏',
                        'Rule scan + AI advice + policy guardrails',
                      ),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t(
                        '移动端默认只扫描可访问目录，删除需要你确认。',
                        'Mobile scans only accessible folders and requires confirmation.',
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: state.isAnalyzing || state.isDeleting
                              ? null
                              : _runAnalyze,
                          icon: state.isAnalyzing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(AuroraIcons.search),
                          label: Text(_t('开始分析', 'Analyze')),
                        ),
                        OutlinedButton(
                          onPressed: state.isAnalyzing
                              ? (state.stopRequested
                                  ? null
                                  : () => ref
                                      .read(cleanerProvider.notifier)
                                      .requestStopAnalyze())
                              : (state.canContinueAnalyze && !state.isDeleting
                                  ? _continueAnalyze
                                  : null),
                          child: Text(
                            state.isAnalyzing
                                ? (state.stopRequested
                                    ? _t('中止中…', 'Stopping...')
                                    : _t('中止', 'Stop'))
                                : _t('继续', 'Continue'),
                          ),
                        ),
                        OutlinedButton(
                          onPressed:
                              state.isDeleting || _selectedCandidateIds.isEmpty
                                  ? null
                                  : _deleteSelected,
                          child: Text(_t('删除已选', 'Delete Selected')),
                        ),
                        OutlinedButton(
                          onPressed: state.isDeleting || state.runResult == null
                              ? null
                              : _deleteByRecommendation,
                          child: Text(_t('按建议删除', 'Delete Recommended')),
                        ),
                      ],
                    ),
                    if (state.totalCandidates > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        _t(
                          '进度: ${state.processedCandidates}/${state.totalCandidates} · 批次 ${state.processedBatches}/${state.totalBatches > 0 ? state.totalBatches : '?'}',
                          'Progress: ${state.processedCandidates}/${state.totalCandidates} · Batches ${state.processedBatches}/${state.totalBatches > 0 ? state.totalBatches : '?'}',
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _deleteReviewRequired,
                      onChanged: (v) {
                        setState(() {
                          _deleteReviewRequired = v;
                        });
                      },
                      title: Text(_t('包含“需复核”项', 'Include review-required')),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (summary != null) ...[
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _metric(_t('候选', 'Candidates'),
                          summary.totalCandidates.toString()),
                      _metric(_t('建议删', 'Delete'),
                          summary.deleteRecommendedCount.toString()),
                      _metric(_t('需复核', 'Review'),
                          summary.reviewRequiredCount.toString()),
                      _metric(
                        _t('预计释放', 'Est. Reclaim'),
                        _formatBytes(summary.estimatedReclaimBytes),
                      ),
                      _metric(
                        '1-10MB',
                        (sizeCounts[_MobileSizeFilter.oneToTenMb] ?? 0)
                            .toString(),
                      ),
                      _metric(
                        '10-100MB',
                        (sizeCounts[_MobileSizeFilter.tenToHundredMb] ?? 0)
                            .toString(),
                      ),
                      _metric(
                        '>=100MB',
                        (sizeCounts[_MobileSizeFilter.overHundredMb] ?? 0)
                            .toString(),
                      ),
                      _metric(
                        _t('低风险', 'Low Risk'),
                        (riskCounts[CleanerRiskLevel.low] ?? 0).toString(),
                      ),
                      _metric(
                        _t('中风险', 'Medium Risk'),
                        (riskCounts[CleanerRiskLevel.medium] ?? 0).toString(),
                      ),
                      _metric(
                        _t('高风险', 'High Risk'),
                        (riskCounts[CleanerRiskLevel.high] ?? 0).toString(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('分类筛选', 'Classification Filter'),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown<_MobileSizeFilter>(
                            value: _sizeFilter,
                            options: _MobileSizeFilter.values,
                            labelBuilder: _sizeFilterText,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _sizeFilter = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDropdown<String>(
                            value: _riskFilter?.name ?? 'all',
                            options: const ['all', 'low', 'medium', 'high'],
                            labelBuilder: (value) {
                              return switch (value) {
                                'all' => _t('全部风险', 'All Risk'),
                                'low' => _t('低风险', 'Low Risk'),
                                'medium' => _t('中风险', 'Medium Risk'),
                                'high' => _t('高风险', 'High Risk'),
                                _ => value,
                              };
                            },
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _riskFilter = switch (value) {
                                  'low' => CleanerRiskLevel.low,
                                  'medium' => CleanerRiskLevel.medium,
                                  'high' => CleanerRiskLevel.high,
                                  _ => null,
                                };
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        '当前显示: ${filteredItems.length}/${allItems.length}',
                        'Showing: ${filteredItems.length}/${allItems.length}',
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (state.lastDeleteResult != null) ...[
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _t(
                      '已释放 ${_formatBytes(state.lastDeleteResult!.totalFreedBytes)}',
                      'Freed ${_formatBytes(state.lastDeleteResult!.totalFreedBytes)}',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildCandidateList(state, filteredItems),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateList(
    CleanerState state,
    List<CleanerReviewItem> visibleItems,
  ) {
    final result = state.runResult;
    if (state.isAnalyzing && result == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (result == null || result.items.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(_t('暂无候选项', 'No candidates yet')),
          ),
        ),
      );
    }

    if (visibleItems.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(_t('当前筛选下无结果', 'No items under current filters.')),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visibleItems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = visibleItems[index];
          final selectable = item.finalDecision != CleanerDecision.keep;
          final checked = _selectedCandidateIds.contains(item.candidate.id);

          return CheckboxListTile(
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
            title: Text(
              item.candidate.path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  '${_decisionText(item.finalDecision)} · ${_riskText(item.finalRiskLevel)} · ${_formatBytes(item.candidate.sizeBytes)} · ${_sizeBucketLabel(item.candidate.sizeBytes)}',
                ),
                const SizedBox(height: 2),
                Text(
                  item.aiSuggestion.humanReason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: '),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> options,
    required String Function(T value) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: options
            .map(
              (entry) => DropdownMenuItem<T>(
                value: entry,
                child: Text(
                  labelBuilder(entry),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
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

  String _sizeFilterText(_MobileSizeFilter filter) {
    switch (filter) {
      case _MobileSizeFilter.all:
        return _t('全部大小', 'All Size');
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

  String _sizeBucketLabel(int bytes) {
    final bucket = _sizeBucketForBytes(bytes);
    if (bucket == null) return '<1MB';
    return switch (bucket) {
      _MobileSizeFilter.oneToTenMb => '1-10MB',
      _MobileSizeFilter.tenToHundredMb => '10-100MB',
      _MobileSizeFilter.overHundredMb => '>=100MB',
      _MobileSizeFilter.all => '<1MB',
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
