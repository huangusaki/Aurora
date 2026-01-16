import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'usage_stats_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';

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
          : statsState.stats.isEmpty && statsState.dailyStats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(fluent.FluentIcons.analytics_view,
                          size: 64,
                          color: theme.resources.textFillColorSecondary),
                      const SizedBox(height: 16),
                      Text(l10n.noUsageData,
                          style: TextStyle(
                              color: theme.resources.textFillColorSecondary)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _buildSummaryCardPC(
                                    theme,
                                    l10n.totalCalls,
                                    statsState.totalCalls,
                                    Colors.blue)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildSummaryCardPC(theme, l10n.success,
                                    statsState.totalSuccess, Colors.green)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildSummaryCardPC(theme, l10n.failed,
                                    statsState.totalFailure, Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                      context, l10n.modelCallDistribution, ref),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.only(
                                        left: 16,
                                        top: 16,
                                        bottom: 16,
                                        right: 24),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: theme.resources
                                              .dividerStrokeColorDefault),
                                    ),
                                    child: _ModelStatsList(
                                        statsState: statsState,
                                        isMobile: false),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.errorDistribution, 
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: theme.resources
                                              .dividerStrokeColorDefault),
                                    ),
                                    child: _ErrorDistributionList(
                                        statsState: statsState),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildChartSection(context, statsState, theme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    child: Text(l10n.clearData),
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
    );
  }

  Widget _buildChartSection(BuildContext context, UsageStatsState state,
      fluent.FluentThemeData theme) {
    if (state.dailyStats.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    // Sort by date just in case
    final sortedDaily = List.of(state.dailyStats)
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = sortedDaily.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.totalCalls.toDouble());
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.resources.dividerStrokeColorDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.callTrend, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.resources.dividerStrokeColorDefault
                        .withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: theme.resources.dividerStrokeColorDefault
                        .withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5, // Show date every 5 points roughly
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedDaily.length) {
                          final date = sortedDaily[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child:
                                Text(DateFormat('MM/dd').format(date),
                                    style: TextStyle(
                                      color: theme
                                          .resources.textFillColorSecondary,
                                      fontSize: 12,
                                    )),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                         // Only show integer values
                         if (value % 1 == 0) {
                             return Text(value.toInt().toString(),
                              style: TextStyle(
                                color: theme.resources.textFillColorSecondary,
                                fontSize: 12,
                              ));
                         }
                         return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                         final index = touchedSpot.x.toInt();
                         if (index >= 0 && index < sortedDaily.length) {
                             final stat = sortedDaily[index];
                             final date = DateFormat('yyyy-MM-dd').format(stat.date);
                             return LineTooltipItem(
                               '$date\nCalls: ${stat.totalCalls}',
                               const TextStyle(color: Colors.white),
                             );
                         }
                         return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardPC(
      fluent.FluentThemeData theme, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.resources.dividerStrokeColorDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Text(label,
                  style: TextStyle(
                      color: theme.resources.textFillColorSecondary,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value.toString(),
              style: TextStyle(
                  color: theme.resources.textFillColorPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class UsageStatsMobileSheet extends ConsumerWidget {
  const UsageStatsMobileSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep mobile concise, maybe just summary cards and model list for now
    // Or if needed, add chart later. Currently matching previous implementation + new data.
    // User asked for "UI concept" which was PC focused mainly.
    // Let's keep existing mobile structure but updated.
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
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.usageStats, style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    // Copied delete logic...
                    ref.read(usageStatsProvider.notifier).clearStats();
                  },
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
          if (statsState.isLoading)
            const SizedBox(
                height: 200, child: Center(child: CircularProgressIndicator()))
          else if (statsState.stats.isEmpty)
            SizedBox(height: 300, child: Center(child: Text(l10n.noUsageData)))
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildSummaryCardMobile(
                                theme,
                                l10n.totalCalls,
                                statsState.totalCalls,
                                Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildSummaryCardMobile(theme, l10n.success,
                                statsState.totalSuccess, Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildSummaryCardMobile(theme, l10n.failed,
                                statsState.totalFailure, Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 24),
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

  Widget _buildSummaryCardMobile(
      ThemeData theme, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value.toString(),
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
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
      ..sort((a, b) => (b.value.success + b.value.failure)
          .compareTo(a.value.success + a.value.failure));
    final maxTotal = sortedEntries.isEmpty
        ? 1
        : sortedEntries
            .map((e) => e.value.success + e.value.failure)
            .reduce((a, b) => a > b ? a : b);
    if (isMobile) {
      return Column(
        children: sortedEntries
            .map((entry) => _buildItem(context, entry, maxTotal))
            .toList(),
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) =>
            _buildItem(context, sortedEntries[index], maxTotal),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
      );
    }
  }

  Widget _buildItem(
      BuildContext context,
      MapEntry<
              String,
              ({
                int failure,
                int success,
                int totalDurationMs,
                int validDurationCount,
                int totalFirstTokenMs,
                int validFirstTokenCount,
                int totalTokenCount,
                int errorTimeoutCount,
                int errorNetworkCount,
                int errorBadRequestCount,
                int errorUnauthorizedCount,
                int errorServerCount,
                int errorRateLimitCount,
                int errorUnknownCount,
              })>
          entry,
      int maxTotal) {
    final modelName = entry.key;
    final stats = entry.value;
    final total = stats.success + stats.failure;
    final relativeFactor = maxTotal > 0 ? total / maxTotal : 0.0;
    
    // Theme helpers
    final themeData = isMobile ? null : fluent.FluentTheme.of(context);
    final mobileTheme = isMobile ? Theme.of(context) : null;
    
    final textColor = isMobile
        ? mobileTheme!.textTheme.bodyMedium?.color
        : themeData!.resources.textFillColorPrimary;
    final subTextColor = isMobile
        ? mobileTheme!.textTheme.bodySmall?.color
        : themeData!.resources.textFillColorSecondary;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(top: 8, bottom: 8, right: isMobile ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.callsCount(total),
                style: TextStyle(fontSize: 12, color: subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, constraints) {
            final fullWidth = constraints.maxWidth;
            final barWidth = fullWidth * relativeFactor;
            final actualBarWidth = (barWidth < 4 && total > 0) ? 4.0 : barWidth;
            return Row(
              children: [
                Container(
                  width: actualBarWidth,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
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
                  Expanded(
                    child: Container(
                      height: 12,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            );
          }),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (stats.success > 0)
                  Text(l10n.successCount(stats.success),
                      style:
                          const TextStyle(fontSize: 10, color: Colors.green)),
                if (stats.success > 0 && stats.failure > 0)
                  Text(' | ',
                      style: TextStyle(fontSize: 10, color: subTextColor)),
                if (stats.failure > 0)
                  Text(l10n.failureCount(stats.failure),
                      style: const TextStyle(fontSize: 10, color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
             final avgDuration = stats.validDurationCount > 0 
                ? (stats.totalDurationMs / stats.validDurationCount / 1000).toStringAsFixed(2) 
                : '0.00';
             final avgFirstToken = stats.validFirstTokenCount > 0 
                ? (stats.totalFirstTokenMs / stats.validFirstTokenCount / 1000).toStringAsFixed(2) 
                : '0.00';
             final tps = stats.totalDurationMs > 0 
                ? (stats.totalTokenCount / (stats.totalDurationMs / 1000)).toStringAsFixed(1) 
                : '0.0';
             return Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _buildMetricItem(isMobile, '累计Token', '${stats.totalTokenCount}', Colors.teal),
                 _buildMetricItem(isMobile, 'Token/s', tps, Colors.blue),
                 _buildMetricItem(isMobile, 'FirstToken', '${avgFirstToken}s', Colors.orange),
                 _buildMetricItem(isMobile, '平均', '${avgDuration}s', Colors.purple),
               ],
             );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricItem(bool isMobile, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: isMobile ? 10 : 11,
          color: Colors.grey
        )),
        Text(value, style: TextStyle(
          fontSize: isMobile ? 12 : 13,
          fontWeight: FontWeight.w600,
          color: color
        )),
      ],
    );
  }
}

class _ErrorDistributionList extends StatelessWidget {
  final UsageStatsState statsState;
  const _ErrorDistributionList({required this.statsState});

  @override
  Widget build(BuildContext context) {
    // Aggregate errors
    int timeout = 0;
    int network = 0;
    int badRequest = 0;
    int unauthorized = 0;
    int server = 0;
    int rateLimit = 0;
    int unknown = 0;

    for (var s in statsState.stats.values) {
      timeout += s.errorTimeoutCount;
      network += s.errorNetworkCount;
      badRequest += s.errorBadRequestCount;
      unauthorized += s.errorUnauthorizedCount;
      server += s.errorServerCount;
      rateLimit += s.errorRateLimitCount;
      unknown += s.errorUnknownCount;
    }

    // Account for legacy failures (before error tracking was added)
    final categorizedErrors = timeout + network + badRequest + unauthorized + server + rateLimit + unknown;
    final totalFailures = statsState.stats.values.fold(0, (sum, s) => sum + s.failure);
    final legacyUnknown = totalFailures - categorizedErrors;
    if (legacyUnknown > 0) {
      unknown += legacyUnknown;
    }

    final totalErrors = timeout + network + badRequest + unauthorized + server + rateLimit + unknown;
    final l10n = AppLocalizations.of(context)!;
    
    if (totalErrors == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(l10n.noUsageData, 
            style: TextStyle(color: Colors.grey[400])
          ),
        ),
      );
    }

    final list = [
      ('Timeout', timeout, Colors.orange), 
      ('Network Error', network, Colors.red),
      ('Rate Limit (429)', rateLimit, Colors.amber),
      ('Unauthorized (401)', unauthorized, Colors.grey),
      ('Server Error (5XX)', server, Colors.red[900]!),
      ('Bad Request (400)', badRequest, Colors.purple),
      ('Other Error', unknown, Colors.blueGrey),
    ];
    
    // Sort by count desc
    list.sort((a, b) => b.$2.compareTo(a.$2));

    return Column(
      children: list.where((e) => e.$2 > 0).map((e) {
        return _buildErrorItem(context, e.$1, e.$2, e.$3, totalErrors);
      }).toList(),
    );
  }

  Widget _buildErrorItem(BuildContext context, String label, int count, Color color, int total) {
    final theme = fluent.FluentTheme.of(context);
    final percentage = (count / total);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(
                color: theme.resources.textFillColorPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500
              )),
              Text('($count)', style: TextStyle(
                 color: theme.resources.textFillColorSecondary,
                 fontSize: 12
              )),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: (percentage * 100).toInt(),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4)
                  ),
                ),
              ),
              if (percentage < 1.0)
                Expanded(
                  flex: ((1 - percentage) * 100).toInt(),
                  child: Container(
                    height: 8,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                )
            ],
          ),
          Text('${(percentage * 100).toStringAsFixed(1)}%', 
             style: TextStyle(
               color: theme.resources.textFillColorSecondary,
               fontSize: 10
             )),
        ],
      ),
    );
  }
}
