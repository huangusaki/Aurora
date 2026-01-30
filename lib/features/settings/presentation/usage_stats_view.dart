import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'usage_stats_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/number_format_utils.dart';

class UsageStatsView extends ConsumerWidget {
  const UsageStatsView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(usageStatsProvider);
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (statsState.isLoading) {
      return const Center(child: fluent.ProgressRing());
    }

    if (statsState.stats.isEmpty && statsState.dailyStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AuroraIcons.stats,
                size: 64,
                color: theme.resources.textFillColorSecondary),
            const SizedBox(height: 16),
            Text(l10n.noUsageData,
                style: TextStyle(
                    color: theme.resources.textFillColorSecondary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fluent.Text(l10n.usageStats,
              style: theme.typography.subtitle),
          const SizedBox(height: 24),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildSummaryCardPC(
                                        theme,
                                        l10n.totalCalls,
                                        statsState.totalCalls,
                                        Colors.blue),
                                    const SizedBox(height: 12),
                                    Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: theme.resources.dividerStrokeColorDefault),
                                        borderRadius: BorderRadius.circular(4),
                                        color: theme.cardColor,
                                      ),
                                      child: fluent.Button(
                                        style: fluent.ButtonStyle(
                                          // border: fluent.ButtonState.all(BorderSide.none), // Removed as invalid
                                          padding: fluent.ButtonState.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                          backgroundColor: fluent.ButtonState.resolveWith((states) {
                                             if (states.isHovering) return theme.resources.subtleFillColorSecondary;
                                             return Colors.transparent;
                                          }),
                                        ),
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => fluent.ContentDialog(
                                              title: Text(_getLoc(context, 'clearStats')),
                                              content: Text(_getLoc(context, 'clearStatsConfirm')),
                                              actions: [
                                                fluent.Button(
                                                  child: Text(l10n.cancel),
                                                  onPressed: () =>
                                                      Navigator.pop(context, false),
                                                ),
                                                fluent.FilledButton(
                                                  child: Text(_getLoc(context, 'clearData')),
                                                  onPressed: () =>
                                                      Navigator.pop(context, true),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            ref.read(usageStatsProvider.notifier)
                                                .clearStats();
                                          }
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Icon(AuroraIcons.delete, size: 14, color: theme.resources.textFillColorSecondary),
                                            const SizedBox(width: 6),
                                            Text(_getLoc(context, 'clearData'), style: TextStyle(
                                              fontSize: 12,
                                              color: theme.resources.textFillColorSecondary
                                            )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
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
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w600,
                color: fluent.FluentTheme.of(context).resources.textFillColorPrimary
            )),
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

  String _getLoc(BuildContext context, String key) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    switch (key) {
      case 'cumulativeToken':
        return isZh ? '累计Token' : 'Total Tokens';
      case 'tokensPerSecond':
        return isZh ? 'Token/s' : 'Tokens/s';
      case 'averageFirstToken':
        return isZh ? 'TTFT' : 'TTFT';
      case 'averageDuration':
        return isZh ? '平均' : 'Average';
      case 'clearStats':
        return isZh ? '清除数据' : 'Clear Stats';
      case 'clearStatsConfirm':
        return isZh ? '确定要清除所有统计数据吗？此操作无法撤销。' : 'Are you sure you want to clear all statistics? This cannot be undone.';
      case 'clearData':
        return isZh ? '清除数据' : 'Clear Data';
      default:
        return key;
    }
  }
}

class UsageStatsMobileSheet extends ConsumerWidget {
  const UsageStatsMobileSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(usageStatsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraBottomSheet.buildTitle(
          context,
          l10n.usageStats,
          trailing: IconButton(
            icon: const Icon(AuroraIcons.delete),
            onPressed: () async {
              ref.read(usageStatsProvider.notifier).clearStats();
            },
          ),
        ),
        const Divider(height: 1),
        if (statsState.isLoading)
          const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()))
        else if (statsState.stats.isEmpty)
          const SizedBox(height: 300, child: Center(child: Text('No data')))
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
    
    // Calculate grand total for percentage
    final grandTotal = sortedEntries.fold<int>(0, (sum, e) => sum + e.value.success + e.value.failure);

    if (isMobile) {
      return Column(
        children: sortedEntries
            .map((entry) => _buildItem(context, entry, maxTotal, grandTotal))
            .toList(),
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) =>
            _buildItem(context, sortedEntries[index], maxTotal, grandTotal),
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
                int promptTokenCount,
                int completionTokenCount,
                int errorTimeoutCount,
                int errorNetworkCount,
                int errorBadRequestCount,
                int errorUnauthorizedCount,
                int errorServerCount,
                int errorRateLimitCount,
                int errorUnknownCount,
              })>
          entry,
      int maxTotal,
      int grandTotal) {
    final modelName = entry.key;
    final stats = entry.value;
    final total = stats.success + stats.failure;
    final relativeFactor = grandTotal > 0 ? total / grandTotal : 0.0;
    final percentage = grandTotal > 0 ? (total / grandTotal * 100).toStringAsFixed(1) : '0.0';
    
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stats.success > 0)
                    Text(l10n.successCount(stats.success),
                        style: const TextStyle(fontSize: 10, color: Colors.green)),
                  if (stats.success > 0 && stats.failure > 0)
                    Text(' | ', style: TextStyle(fontSize: 10, color: subTextColor)),
                  if (stats.failure > 0)
                    Text(l10n.failureCount(stats.failure),
                        style: const TextStyle(fontSize: 10, color: Colors.red)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, constraints) {
            final fullWidth = constraints.maxWidth;
            final barWidth = fullWidth * relativeFactor;
            final actualBarWidth = (barWidth < 4 && total > 0) ? 4.0 : barWidth;
            final displayedPercentageText = total / grandTotal * 100;
            return Stack(
              children: [
                Row(
                  children: [
                    Container(
                      width: actualBarWidth,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                    if (total < grandTotal)
                      Expanded(
                        child: Container(
                          height: 16,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      '${displayedPercentageText.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10, 
                        color: subTextColor, 
                        height: 1.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
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

             // Thresholds for coloring (Green/Yellow/Red)
             // TPS: 30/60/90. Large->Small: Green/Yellow/Red.
             // Implies: >= 60 Green, >= 30 Orange, < 30 Red.
             final tpsVal = double.tryParse(tps) ?? 0.0;
             final tpsColor = tpsVal >= 60.0 ? Colors.green 
                            : (tpsVal >= 30.0 ? Colors.orange : Colors.red);

             // First Token: 5/10/15. Small->Large: Green/Yellow/Red.
             // Implies: <= 5 Green, <= 10 Orange, > 10 Red.
             final ftVal = double.tryParse(avgFirstToken) ?? 0.0;
             final ftColor = ftVal <= 5.0 ? Colors.green 
                           : (ftVal <= 10.0 ? Colors.orange : Colors.red);

             // Duration: 30/60/90. Small->Large: Green/Yellow/Red.
             // Implies: <= 30 Green, <= 60 Orange, > 60 Red.
             final durationVal = double.tryParse(avgDuration) ?? 0.0;
             final durationColor = durationVal <= 30.0 ? Colors.green 
                                 : (durationVal <= 60.0 ? Colors.orange : Colors.red);


             return Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  _buildMetricItem(isMobile, themeData, mobileTheme, 
                      _getLoc(context, 'cumulativeToken'), 
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Segoe UI Variable',
                            color: isMobile 
                                ? mobileTheme!.textTheme.bodyMedium?.color 
                                : themeData!.resources.textFillColorPrimary,
                          ),
                          children: [
                            TextSpan(text: '${formatTokenCount(stats.totalTokenCount)} '),
                            TextSpan(
                              text: '(↑ ${formatTokenCount(stats.promptTokenCount)} / ↓ ${formatTokenCount(stats.completionTokenCount)})',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                                color: isMobile 
                                    ? mobileTheme!.textTheme.bodySmall?.color 
                                    : themeData!.resources.textFillColorSecondary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      )),
                  _buildMetricItem(isMobile, themeData, mobileTheme, _getLoc(context, 'tokensPerSecond'), 
                      Text(tps, style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: tpsColor,
                          fontFamily: 'Segoe UI Variable'))),
                  _buildMetricItem(isMobile, themeData, mobileTheme, _getLoc(context, 'averageFirstToken'), 
                      Text('${avgFirstToken}s', style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: ftColor,
                          fontFamily: 'Segoe UI Variable'))),
                  _buildMetricItem(isMobile, themeData, mobileTheme, _getLoc(context, 'averageDuration'), 
                      Text('${avgDuration}s', style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: durationColor,
                          fontFamily: 'Segoe UI Variable'))),
                ],
              );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricItem(bool isMobile, fluent.FluentThemeData? themeData, ThemeData? mobileTheme, String label, Widget valueWidget) {
    final labelColor = isMobile 
        ? mobileTheme!.textTheme.bodySmall?.color 
        : themeData!.resources.textFillColorSecondary;
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: isMobile ? 10 : 12,
          color: labelColor
        )),
        const SizedBox(height: 2),
        valueWidget,
      ],
    );
  }

  String _getLoc(BuildContext context, String key) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    switch (key) {
      case 'cumulativeToken':
        return isZh ? '累计Token' : 'Total Tokens';
      case 'tokensPerSecond':
        return isZh ? 'Token/s' : 'Tokens/s';
      case 'averageFirstToken':
        return isZh ? 'TTFT' : 'TTFT';
      case 'averageDuration':
        return isZh ? '平均' : 'Average';
      case 'prompt':
        return isZh ? '提问' : 'Prompt';
      case 'completion':
        return isZh ? '回答' : 'Completion';
      default:
        return key;
    }
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
      ('Rate Limit (429)', rateLimit, Colors.orange.withOpacity(0.8)),
      ('Unauthorized (401)', unauthorized, Colors.red.withOpacity(0.7)),
      ('Server Error (5XX)', server, Colors.red),
      ('Bad Request (400)', badRequest, Colors.orange),
      ('Other Error', unknown, Colors.grey),
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
              Expanded(
                child: Text(label, style: TextStyle(
                  color: theme.resources.textFillColorPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600
                )),
              ),
              Text('$count', style: TextStyle(
                 color: theme.resources.textFillColorSecondary,
                 fontSize: 12
              )),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, constraints) {
             final fullWidth = constraints.maxWidth;
             // Ensure at least 4px width if there are calls
             final barWidth = percentage * fullWidth;
             final actualBarWidth = (barWidth < 4 && count > 0) ? 4.0 : barWidth;
             
             return Stack(
               children: [
                 Row(
                   children: [
                     Container(
                       width: actualBarWidth,
                       height: 16, // Match Usage Stats height
                       decoration: BoxDecoration(
                         color: color,
                         borderRadius: BorderRadius.circular(8)
                       ),
                     ),
                     if (percentage < 1.0)
                       Expanded(
                         child: Container(
                           height: 16,
                           margin: const EdgeInsets.only(left: 4),
                           decoration: BoxDecoration(
                             color: Colors.grey.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(8)
                           ),
                         ),
                       )
                   ],
                 ),
                 Positioned(
                   right: 4,
                   top: 0,
                   bottom: 0,
                   child: Center(
                     child: Text('${(percentage * 100).toStringAsFixed(1)}%', 
                       style: TextStyle(
                         color: theme.resources.textFillColorSecondary,
                         fontSize: 10,
                         height: 1.0,
                         fontWeight: FontWeight.bold
                       )),
                   ),
                 ),
               ],
             );
          }),
        ],
      ),
    );
  }
}
