import 'dart:io';

import 'package:aurora/features/settings/presentation/app_log_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/utils/app_logger.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LogRecordsView extends ConsumerWidget {
  const LogRecordsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = fluent.FluentTheme.of(context);
    final hasEntries = ref.watch(
      appLogRepositoryProvider.select((state) => state.entries.isNotEmpty),
    );
    final visibleEntries = ref.watch(filteredAppLogEntriesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.logRecords,
                style: theme.typography.subtitle,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  fluent.Button(
                    onPressed: visibleEntries.isNotEmpty
                        ? () => _exportLogs(context, ref, visibleEntries)
                        : null,
                    child: Text(l10n.exportData),
                  ),
                  const SizedBox(width: 8),
                  fluent.Button(
                    onPressed: hasEntries ? () => _clearLogs(ref) : null,
                    child: Text(l10n.clear),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.logFilterHint,
            style: TextStyle(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const _LogLevelFilterBar(isMobile: false),
          const SizedBox(height: 16),
          const Expanded(
            child: _LogEntriesPanel(isMobile: false),
          ),
        ],
      ),
    );
  }
}

class MobileLogPage extends ConsumerWidget {
  final VoidCallback? onBack;

  const MobileLogPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasEntries = ref.watch(
      appLogRepositoryProvider.select((state) => state.entries.isNotEmpty),
    );
    final visibleEntries = ref.watch(filteredAppLogEntriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.logRecords),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: onBack,
              )
            : null,
        actions: [
          IconButton(
            onPressed: visibleEntries.isNotEmpty
                ? () => _exportLogs(context, ref, visibleEntries)
                : null,
            icon: const Icon(Icons.download_outlined),
            tooltip: l10n.exportData,
          ),
          IconButton(
            onPressed: hasEntries ? () => _clearLogs(ref) : null,
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.clear,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.logFilterHint,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 12),
            const _LogLevelFilterBar(isMobile: true),
            const SizedBox(height: 12),
            const Expanded(
              child: _LogEntriesPanel(isMobile: true),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _clearLogs(WidgetRef ref) async {
  await ref.read(appLogRepositoryProvider.notifier).clear();
}

Future<void> _exportLogs(
  BuildContext context,
  WidgetRef ref,
  List<AppLogEntry> entries,
) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final location = await getSaveLocation(
      suggestedName: 'aurora_logs_$timestamp.txt',
    );
    if (location == null) return;

    final content = entries.map((entry) => entry.toPlainText()).join('\n\n');
    final file = File(location.path);
    await file.writeAsString(content.isEmpty ? '' : '$content\n');

    if (context.mounted) {
      showAuroraNotice(
        context,
        l10n.exportSuccess,
        icon: AuroraIcons.success,
      );
    }
  } catch (e) {
    if (context.mounted) {
      showAuroraNotice(
        context,
        '${l10n.exportFailed}: $e',
        icon: AuroraIcons.error,
      );
    }
  }
}

class _LogLevelFilterBar extends ConsumerWidget {
  final bool isMobile;

  const _LogLevelFilterBar({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLevels = ref.watch(appLogFilterProvider);

    if (isMobile) {
      return Row(
        children: AppLogLevel.values.map((level) {
          final isSelected = selectedLevels.contains(level);
          final color = _levelColor(level);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: level != AppLogLevel.values.last ? 6 : 0,
              ),
              child: _MobileFilterChip(
                isSelected: isSelected,
                color: color,
                icon: _levelIcon(level),
                label: _levelLabel(AppLocalizations.of(context)!, level),
                onTap: () {
                  final next = Set<AppLogLevel>.from(selectedLevels);
                  if (isSelected) {
                    if (next.length > 1) next.remove(level);
                  } else {
                    next.add(level);
                  }
                  ref.read(appLogFilterProvider.notifier).state = next;
                },
              ),
            ),
          );
        }).toList(growable: false),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppLogLevel.values.map((level) {
        final isSelected = selectedLevels.contains(level);
        final color = _levelColor(level);

        // Desktop: 选中时加深颜色，不显示勾选图标
        return _DesktopFilterChip(
          isSelected: isSelected,
          color: color,
          icon: _levelIcon(level),
          label: _levelLabel(AppLocalizations.of(context)!, level),
          onTap: () {
            final next = Set<AppLogLevel>.from(selectedLevels);
            if (isSelected) {
              if (next.length > 1) next.remove(level);
            } else {
              next.add(level);
            }
            ref.read(appLogFilterProvider.notifier).state = next;
          },
        );
      }).toList(growable: false),
    );
  }
}

class _DesktopFilterChip extends StatelessWidget {
  final bool isSelected;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DesktopFilterChip({
    required this.isSelected,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final bgColor = isSelected
        ? color.withValues(alpha: 0.15)
        : theme.resources.cardBackgroundFillColorDefault;
    final fgColor = isSelected ? color : theme.resources.textFillColorSecondary;
    final borderColor = isSelected
        ? color.withValues(alpha: 0.4)
        : theme.resources.dividerStrokeColorDefault;

    return fluent.HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        final isHovered = states.isHovered;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHovered && !isSelected
                ? theme.resources.subtleFillColorSecondary
                : bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileFilterChip extends StatelessWidget {
  final bool isSelected;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MobileFilterChip({
    required this.isSelected,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isSelected
        ? color.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final fgColor = isSelected ? color : theme.textTheme.bodySmall?.color;
    final borderColor = isSelected
        ? color.withValues(alpha: 0.35)
        : theme.dividerColor.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEntriesPanel extends ConsumerStatefulWidget {
  final bool isMobile;

  const _LogEntriesPanel({required this.isMobile});

  @override
  ConsumerState<_LogEntriesPanel> createState() => _LogEntriesPanelState();
}

class _LogEntriesPanelState extends ConsumerState<_LogEntriesPanel> {
  static const double _topPinnedThreshold = 100;
  static const Duration _recentInteractionHold = Duration(milliseconds: 300);

  late final ScrollController _scrollController;
  double? _prevMaxScrollExtent;
  double? _prevScrollPixels;
  AppLogEntry? _lastVisibleHeadEntry;
  int _lastFilterSignature = 0;
  DateTime? _lastUserInteractionAt;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasPixels) return;
    _prevScrollPixels = position.pixels;
    if (position.hasContentDimensions) {
      _prevMaxScrollExtent = position.maxScrollExtent;
    }
  }

  void _scheduleScrollPositionCompensation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      final prevMax = _prevMaxScrollExtent;
      final prevPixels = _prevScrollPixels;
      if (prevMax == null || prevPixels == null) return;

      final position = _scrollController.position;
      if (!position.hasPixels || !position.hasContentDimensions) return;
      if (position.isScrollingNotifier.value) return;
      if (_hasRecentUserInteraction()) return;
      final deltaMax = position.maxScrollExtent - prevMax;
      if (deltaMax.abs() < 0.5) return;

      final target = (prevPixels + deltaMax)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((target - position.pixels).abs() < 0.5) return;
      _scrollController.jumpTo(target);
    });
  }

  void _scheduleScrollMetricsCapture() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (!position.hasPixels) return;
      _prevScrollPixels = position.pixels;
      if (!position.hasContentDimensions) return;
      _prevMaxScrollExtent = position.maxScrollExtent;
    });
  }

  bool _shouldPreserveViewport(
    List<AppLogEntry> entries,
    int filterSignature,
  ) {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    if (!position.hasPixels) return false;
    if (position.pixels <= _topPinnedThreshold) return false;
    final previousHead = _lastVisibleHeadEntry;
    if (previousHead == null) return false;
    if (_lastFilterSignature != filterSignature) return false;
    return _indexOfEntry(entries, previousHead) > 0;
  }

  bool _hasActiveScrollInteraction() {
    if (!_scrollController.hasClients) return false;
    return _scrollController.position.isScrollingNotifier.value;
  }

  bool _hasRecentUserInteraction() {
    final lastUserInteractionAt = _lastUserInteractionAt;
    if (lastUserInteractionAt == null) return false;
    return DateTime.now().difference(lastUserInteractionAt) <
        _recentInteractionHold;
  }

  void _recordUserInteraction(
    String source, {
    ScrollMetrics? metrics,
    bool? hasDragDetails,
  }) {
    _lastUserInteractionAt = DateTime.now();
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    int entryCount,
  ) {
    if (notification.depth != 0) return false;
    final dragDetails = switch (notification) {
      ScrollStartNotification() => notification.dragDetails,
      ScrollUpdateNotification() => notification.dragDetails,
      OverscrollNotification() => notification.dragDetails,
      ScrollEndNotification() => notification.dragDetails,
      _ => null,
    };

    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification ||
        notification is ScrollEndNotification ||
        notification is UserScrollNotification) {
      _recordUserInteraction(
        notification.runtimeType.toString(),
        metrics: notification.metrics,
        hasDragDetails: dragDetails != null,
      );
    }
    return false;
  }

  int _indexOfEntry(List<AppLogEntry> entries, AppLogEntry target) {
    for (var i = 0; i < entries.length; i++) {
      if (_sameEntry(entries[i], target)) {
        return i;
      }
    }
    return -1;
  }

  bool _sameEntry(AppLogEntry a, AppLogEntry b) {
    return a.timestamp == b.timestamp &&
        a.level == b.level &&
        a.channel == b.channel &&
        a.category == b.category &&
        a.message == b.message &&
        a.details == b.details;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appLogRepositoryProvider);
    final entries = ref.watch(filteredAppLogEntriesProvider);
    final selectedLevels = ref.watch(appLogFilterProvider);
    final l10n = AppLocalizations.of(context)!;
    final filterSignature = Object.hashAllUnordered(selectedLevels);

    if (!state.isLoading &&
        !_hasActiveScrollInteraction() &&
        !_hasRecentUserInteraction() &&
        _shouldPreserveViewport(entries, filterSignature)) {
      _scheduleScrollPositionCompensation();
    }
    _scheduleScrollMetricsCapture();

    _lastVisibleHeadEntry = entries.isEmpty ? null : entries.first;
    _lastFilterSignature = filterSignature;

    if (state.isLoading && entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (entries.isEmpty) {
      return _LogEmptyState(
        isMobile: widget.isMobile,
        title: l10n.noLogRecords,
      );
    }

    final scrollable = widget.isMobile
        ? ListView.separated(
            key: const PageStorageKey<String>('log-records-list'),
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _LogEntryTile(
                entry: entries[index],
                isMobile: widget.isMobile,
              );
            },
            physics: const ClampingScrollPhysics(),
          )
        : SingleChildScrollView(
            key: const PageStorageKey<String>('log-records-scroll-view'),
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    if (index > 0) const SizedBox(height: 10),
                    _LogEntryTile(
                      entry: entries[index],
                      isMobile: widget.isMobile,
                    ),
                  ],
                ],
              ),
            ),
          );

    Widget list = LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) =>
              _handleScrollNotification(notification, entries.length),
          child: scrollable,
        );
      },
    );

    if (!widget.isMobile) {
      final isDark =
          fluent.FluentTheme.of(context).brightness == Brightness.dark;
      list = Padding(
        padding: const EdgeInsets.only(right: 4),
        child: RawScrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          thickness: 6,
          radius: const Radius.circular(100),
          thumbColor:
              isDark ? const Color(0xFFa0a0a0) : const Color(0xFF898989),
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: list,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.isMobile
            ? Theme.of(context).cardColor
            : fluent.FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isMobile
              ? Theme.of(context).dividerColor.withValues(alpha: 0.3)
              : fluent.FluentTheme.of(context)
                  .resources
                  .dividerStrokeColorDefault,
        ),
      ),
      child: list,
    );
  }
}

class _LogEmptyState extends StatelessWidget {
  final bool isMobile;
  final String title;

  const _LogEmptyState({
    required this.isMobile,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor = isMobile
        ? Theme.of(context).textTheme.bodySmall?.color
        : fluent.FluentTheme.of(context).resources.textFillColorSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AuroraIcons.terminal,
            size: 48,
            color: secondaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: secondaryColor),
          ),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final AppLogEntry entry;
  final bool isMobile;

  const _LogEntryTile({
    required this.entry,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levelColor = _levelColor(entry.level);
    final secondaryColor = isMobile
        ? Theme.of(context).textTheme.bodySmall?.color
        : fluent.FluentTheme.of(context).resources.textFillColorSecondary;
    final primaryColor = isMobile
        ? Theme.of(context).textTheme.bodyLarge?.color
        : fluent.FluentTheme.of(context).resources.textFillColorPrimary;
    final surfaceColor = isMobile
        ? Theme.of(context).scaffoldBackgroundColor
        : fluent.FluentTheme.of(context).scaffoldBackgroundColor;

    final channelLabel = entry.category == null || entry.category!.isEmpty
        ? entry.channel
        : '${entry.channel} / ${entry.category}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: isMobile ? 0.7 : 1.0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _levelIcon(entry.level),
                      size: 14,
                      color: levelColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _levelLabel(l10n, entry.level),
                      style: TextStyle(
                        color: levelColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channelLabel,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(entry.timestamp),
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entry.message.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entry.message,
              style: TextStyle(
                color: primaryColor,
                height: 1.35,
              ),
            ),
          ],
          if (entry.details != null && entry.details!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                entry.details!,
                style: TextStyle(
                  color: primaryColor,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _levelLabel(AppLocalizations l10n, AppLogLevel level) {
  switch (level) {
    case AppLogLevel.debug:
      return l10n.logLevelDebug;
    case AppLogLevel.info:
      return l10n.logLevelInfo;
    case AppLogLevel.warn:
      return l10n.logLevelWarning;
    case AppLogLevel.error:
      return l10n.logLevelError;
  }
}

IconData _levelIcon(AppLogLevel level) {
  switch (level) {
    case AppLogLevel.debug:
      return AuroraIcons.terminal;
    case AppLogLevel.info:
      return AuroraIcons.info;
    case AppLogLevel.warn:
      return AuroraIcons.warning;
    case AppLogLevel.error:
      return AuroraIcons.error;
  }
}

Color _levelColor(AppLogLevel level) {
  switch (level) {
    case AppLogLevel.debug:
      return Colors.grey;
    case AppLogLevel.info:
      return Colors.blue;
    case AppLogLevel.warn:
      return Colors.orange;
    case AppLogLevel.error:
      return Colors.red;
  }
}

String _formatTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
}
