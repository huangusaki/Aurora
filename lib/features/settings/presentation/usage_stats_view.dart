import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'usage_stats_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';

/// PC View: Embedded in Settings Pane
class UsageStatsView extends ConsumerWidget {
  const UsageStatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(usageStatsProvider);
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
        title: fluent.Text(l10n.usageStats),
      ),
      content: statsState.isLoading
          ? const Center(child: fluent.ProgressRing())
          : statsState.stats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(fluent.FluentIcons.analytics_view, 
                           size: 64, 
                           color: theme.resources.textFillColorSecondary),
                      const SizedBox(height: 16),
                      Text(l10n.noUsageData, 
                           style: TextStyle(color: theme.resources.textFillColorSecondary)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(child: _buildSummaryCardPC(theme, l10n.totalCalls, statsState.totalCalls, Colors.blue)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSummaryCardPC(theme, l10n.success, statsState.totalSuccess, Colors.green)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSummaryCardPC(theme, l10n.failed, statsState.totalFailure, Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.modelCallDistribution, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          fluent.Button(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => fluent.ContentDialog(
                                  title: Text(l10n.clearStats),
                                  content: Text(l10n.clearStatsConfirm),
                                  actions: [
                                    fluent.Button(
                                      child: Text(l10n.cancel),
                                      onPressed: () => Navigator.pop(context, false),
                                    ),
                                    fluent.FilledButton(
                                      child: Text(l10n.clearData), // Button text "清除" -> assume clearData or create general "clear"? Arb has "clearData": "清除数据". I'll use clearData.
                                      onPressed: () => Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                ref.read(usageStatsProvider.notifier).clearStats();
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(fluent.FluentIcons.delete, size: 12),
                                const SizedBox(width: 8),
                                Text(l10n.clearData),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // List Visualization
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.resources.dividerStrokeColorDefault),
                          ),
                          child: _ModelStatsList(statsState: statsState, isMobile: false),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCardPC(fluent.FluentThemeData theme, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.resources.dividerStrokeColorDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: theme.resources.textFillColorSecondary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value.toString(), style: TextStyle(color: theme.resources.textFillColorPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Mobile View: Bottom Sheet
class UsageStatsMobileSheet extends ConsumerWidget {
  const UsageStatsMobileSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(usageStatsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.usageStats, style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.clearData),
                        content: Text(l10n.clearDataConfirm),
                        actions: [
                          TextButton(child: Text(l10n.cancel), onPressed: () => Navigator.pop(context, false)),
                          TextButton(child: Text(l10n.clearData), onPressed: () => Navigator.pop(context, true)),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      ref.read(usageStatsProvider.notifier).clearStats();
                    }
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
          
          if (statsState.isLoading)
             const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          else if (statsState.stats.isEmpty)
             SizedBox(height: 300, child: Center(child: Text(l10n.noUsageData)))
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     // Summary Cards Row
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCardMobile(theme, l10n.totalCalls, statsState.totalCalls, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryCardMobile(theme, l10n.success, statsState.totalSuccess, Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryCardMobile(theme, l10n.failed, statsState.totalFailure, Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // List
                    _ModelStatsList(statsState: statsState, isMobile: true),
                    const SizedBox(height: 32), 
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardMobile(ThemeData theme, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value.toString(), style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ModelStatsList extends StatelessWidget {
  final UsageStatsState statsState;
  final bool isMobile;

  const _ModelStatsList({required this.statsState, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final sortedEntries = statsState.stats.entries.toList()
      ..sort((a, b) => (b.value.success + b.value.failure).compareTo(a.value.success + a.value.failure));
    
    // Find the max total for relative bar sizing (normalization)
    final maxTotal = sortedEntries.isEmpty 
        ? 1 
        : sortedEntries.map((e) => e.value.success + e.value.failure).reduce((a, b) => a > b ? a : b);

    // If mobile, map to Column (since it's inside SingleChildScrollView)
    // If PC, use ListView.builder (since it's inside Expanded)
    if (isMobile) {
      return Column(
        children: sortedEntries.map((entry) => _buildItem(context, entry, maxTotal)).toList(),
      );
    } else {
      return ListView.separated(
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) => _buildItem(context, sortedEntries[index], maxTotal),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
      );
    }
  }

  Widget _buildItem(BuildContext context, MapEntry<String, ({int failure, int success, int totalDurationMs, int validDurationCount})> entry, int maxTotal) {
    final modelName = entry.key;
    final stats = entry.value;
    final total = stats.success + stats.failure;
    
    // Visualize relative to the busiest model (so the busiest model fills 100% width)
    final relativeFactor = maxTotal > 0 ? total / maxTotal : 0.0;

    final theme = isMobile ? Theme.of(context) : null;
    final textColor = isMobile ? theme!.textTheme.bodyMedium?.color : fluent.FluentTheme.of(context).resources.textFillColorPrimary;
    final subTextColor = isMobile ? theme!.textTheme.bodySmall?.color : fluent.FluentTheme.of(context).resources.textFillColorSecondary;
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  modelName, 
                  style: TextStyle(
                    fontWeight: FontWeight.w600, 
                    fontSize: isMobile ? 14 : 15,
                    color: textColor,
                    overflow: TextOverflow.visible, // Ensure text wraps
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.callsCount(total), 
                style: TextStyle(
                  fontSize: 12, 
                  color: subTextColor
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress Bar
          // We want the total bar length to be proportional to total usage relative to max
          LayoutBuilder(
            builder: (context, constraints) {
              final fullWidth = constraints.maxWidth;
              final barWidth = fullWidth * relativeFactor;
              // Ensure at least some visibility if count > 0
              final actualBarWidth = (barWidth < 4 && total > 0) ? 4.0 : barWidth;

              return Row(
                children: [
                  Container(
                    width: actualBarWidth,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                     // If mixed, we might need a Row or Gradient inside. 
                     // Simplest is a Row of two Flexibles inside a clipped container
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          if (stats.success > 0)
                            Expanded(
                              flex: stats.success,
                              child: Container(color: Colors.green),
                            ),
                          if (stats.failure > 0)
                            Expanded(
                              flex: stats.failure,
                              child: Container(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (total < maxTotal)
                    // Visual spacer or ghost bar? 
                    // Usually ghost bar looks better for context 
                    Expanded(
                      child: Container(
                        height: 12,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              );
            }
          ),
          // Stats Detail Text
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (stats.success > 0)
                  Text(l10n.successCount(stats.success), style: const TextStyle(fontSize: 10, color: Colors.green)),
                if (stats.success > 0 && stats.failure > 0)
                  Text(' · ', style: TextStyle(fontSize: 10, color: subTextColor)),
                if (stats.failure > 0)
                  Text(l10n.failureCount(stats.failure), style: const TextStyle(fontSize: 10, color: Colors.red)),
                if (stats.validDurationCount > 0) ...[
                  Text(' · ', style: TextStyle(fontSize: 10, color: subTextColor)),
                  Text(
                    l10n.averageDuration((stats.totalDurationMs / stats.validDurationCount / 1000).toStringAsFixed(2)),
                    style: TextStyle(fontSize: 10, color: subTextColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
