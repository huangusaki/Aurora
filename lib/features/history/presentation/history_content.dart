import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../chat/presentation/chat_provider.dart';
import '../../chat/presentation/topic_provider.dart';
import '../../chat/presentation/widgets/chat_view.dart';
import '../../chat/presentation/widgets/topic_dropdown.dart';
import '../../settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/number_format_utils.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

class HistoryContent extends ConsumerStatefulWidget {
  const HistoryContent({super.key});
  @override
  ConsumerState<HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends ConsumerState<HistoryContent> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(sessionsProvider.notifier).loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isDesktop) {
      return _buildDesktopLayout(context, ref);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return _buildMobileLayout(context, ref);
        }
        return _buildDesktopLayout(context, ref);
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    final sessionsState = ref.watch(sessionsProvider);
    if (selectedSessionId != null && selectedSessionId != '') {
      return GestureDetector(
        onHorizontalDragStart: (details) {},
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
            Scaffold.of(context).openDrawer();
          }
        },
        child: Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: fluent.FluentTheme.of(context)
                            .resources
                            .dividerStrokeColorDefault)),
                color: fluent.FluentTheme.of(context)
                    .navigationPaneTheme
                    .backgroundColor,
              ),
              child: Row(
                children: [
                  fluent.IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      final currentId =
                          ref.read(selectedHistorySessionIdProvider);
                      if (currentId != null) {
                        await ref
                            .read(sessionsProvider.notifier)
                            .cleanupSessionIfEmpty(currentId);
                      }
                      ref
                          .read(selectedHistorySessionIdProvider.notifier)
                          .state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.sessionDetails,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(child: ChatView(sessionId: selectedSessionId)),
          ],
        ),
      );
    } else {
      return _SessionList(
        sessionsState: sessionsState,
        selectedSessionId: selectedSessionId,
        isMobile: true,
      );
    }
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    final isSidebarVisible = ref.watch(isHistorySidebarVisibleProvider);
    final sessionsState = ref.watch(sessionsProvider);
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.transparent,
      child: Row(
        children: [
          RepaintBoundary(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: isSidebarVisible ? 250 : 0,
              child: ClipRect(
                child: OverflowBox(
                  minWidth: 250,
                  maxWidth: 250,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: _SessionList(
                      sessionsState: sessionsState,
                      selectedSessionId: selectedSessionId,
                      isMobile: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  child: selectedSessionId == null
                      ? Center(child: Text(l10n.selectOrNewTopic))
                      : ChatView(
                          key: ValueKey(selectedSessionId),
                          sessionId: selectedSessionId),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionList extends ConsumerWidget {
  final SessionsState sessionsState;
  final String? selectedSessionId;
  final bool isMobile;
  const _SessionList({
    required this.sessionsState,
    required this.selectedSessionId,
    required this.isMobile,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(chatSessionManagerProvider);
    ref.watch(chatStateUpdateTriggerProvider);
    ref.listen(selectedHistorySessionIdProvider, (_, next) {
      if (next != null) {
        final storage = ref.read(settingsStorageProvider);
        storage.saveLastSessionId(next);
      }
    });
    final selectedTopicId = ref.watch(selectedTopicIdProvider);
    final l10n = AppLocalizations.of(context)!;
    final filteredSessions = sessionsState.sessions.where((s) {
      if (selectedTopicId == null) return true;
      return s.topicId == selectedTopicId;
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TopicDropdown(isMobile: isMobile),
              const SizedBox(height: 4),
              fluent.HoverButton(
                onPressed: () {
                  ref.read(sessionsProvider.notifier).startNewSession();
                },
                builder: (context, states) {
                  final theme = fluent.FluentTheme.of(context);
                  final isHovering = states.isHovered;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isHovering
                          ? theme.resources.subtleFillColorSecondary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isHovering
                            ? theme.resources.surfaceStrokeColorDefault
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(fluent.FluentIcons.add,
                            size: 14, color: theme.accentColor),
                        const SizedBox(width: 12),
                        Text(l10n.startNewChat,
                            style: TextStyle(
                                fontSize: 14,
                                color: theme.typography.body?.color,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        if (isHovering)
                          Icon(fluent.FluentIcons.chevron_right,
                              size: 10,
                              color: theme.resources.textFillColorSecondary),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: sessionsState.isLoading && sessionsState.sessions.isEmpty
              ? const Center(child: fluent.ProgressRing())
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      type: MaterialType.transparency,
                      child: fluent.FluentTheme(
                        data: fluent.FluentTheme.of(context),
                        child: child,
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(sessionsProvider.notifier)
                        .reorderSession(oldIndex, newIndex);
                  },
                  itemCount: filteredSessions.length,
                  itemBuilder: (context, index) {
                    final session = filteredSessions[index];
                    final isSelected = session.sessionId == selectedSessionId;
                    final sessionState = manager.getState(session.sessionId);
                    final Color? statusColor;
                    if (sessionState == null) {
                      statusColor = null;
                    } else if (sessionState.error != null) {
                      statusColor = Colors.red;
                    } else if (sessionState.isLoading) {
                      statusColor = Colors.orange;
                    } else if (sessionState.hasUnreadResponse) {
                      statusColor = Colors.green;
                    } else {
                      statusColor = null;
                    }
                    return ReorderableDragStartListener(
                      key: Key(session.sessionId),
                      index: index,
                      child: _SessionItem(
                        session: session,
                        isSelected: isSelected,
                        statusColor: statusColor,
                        onTap: () async {
                          final currentId =
                              ref.read(selectedHistorySessionIdProvider);
                          if (currentId != null &&
                              currentId != session.sessionId) {
                            await ref
                                .read(sessionsProvider.notifier)
                                .cleanupSessionIfEmpty(currentId);
                          }
                          ref
                              .read(selectedHistorySessionIdProvider.notifier)
                              .state = session.sessionId;
                        },
                        onRename: (newTitle) {
                          ref
                              .read(sessionsProvider.notifier)
                              .renameSession(session.sessionId, newTitle);
                        },
                        onDelete: () {
                          ref
                              .read(sessionsProvider.notifier)
                              .deleteSession(session.sessionId);
                          if (isSelected) {
                            ref
                                .read(selectedHistorySessionIdProvider.notifier)
                                .state = null;
                          }
                        },
                        isMobile: isMobile,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SessionItem extends StatefulWidget {
  final dynamic session;
  final bool isSelected;
  final Color? statusColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(String newTitle) onRename;
  final bool isMobile;
  const _SessionItem({
    required this.session,
    required this.isSelected,
    required this.statusColor,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    this.isMobile = false,
  });
  @override
  State<_SessionItem> createState() => _SessionItemState();
}

class _SessionItemState extends State<_SessionItem> {
  bool _isHovering = false;
  bool _isRenaming = false;
  late TextEditingController _renameController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _renameController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isRenaming) {
      _confirmRename();
    }
  }

  void _startRenaming() {
    setState(() {
      _isRenaming = true;
      _renameController.text = widget.session.title;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _confirmRename() {
    if (!mounted) return;
    final newTitle = _renameController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.session.title) {
      widget.onRename(newTitle);
    }
    setState(() {
      _isRenaming = false;
    });
  }

  void _cancelRenaming() {
    if (!mounted) return;
    setState(() {
      _isRenaming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.accentColor.normal.withOpacity(0.15)
                : (_isHovering
                    ? theme.resources.subtleFillColorSecondary
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: fluent.Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (widget.statusColor != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isRenaming)
                        SizedBox(
                          height: 24,
                          child: fluent.TextBox(
                            controller: _renameController,
                            focusNode: _focusNode,
                            style: const TextStyle(fontSize: 13),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: WidgetStateProperty.all(BoxDecoration(
                              color: theme.resources.controlFillColorDefault,
                              border: Border.all(color: theme.accentColor),
                              borderRadius: BorderRadius.circular(4),
                            )),
                            onSubmitted: (_) => _confirmRename(),
                          ),
                        )
                      else
                        Text(widget.session.title,
                            style: TextStyle(
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      if (!_isRenaming)
                        Text(
                            DateFormat('MM/dd HH:mm')
                                    .format(widget.session.lastMessageTime) +
                                (widget.session.totalTokens > 0
                                    ? ' • ${formatTokenCount(widget.session.totalTokens)} tokens'
                                    : ''),
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.resources.textFillColorSecondary)),
                    ],
                  ),
                ),
                if ((widget.isSelected || _isHovering || widget.isMobile) &&
                    !_isRenaming) ...[
                  fluent.IconButton(
                    icon: const fluent.Icon(fluent.FluentIcons.edit, size: 14),
                    onPressed: _startRenaming,
                  ),
                  fluent.IconButton(
                    icon:
                        const fluent.Icon(fluent.FluentIcons.delete, size: 14),
                    onPressed: widget.onDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class SessionListWidget extends ConsumerWidget {
  final SessionsState sessionsState;
  final String? selectedSessionId;
  final ValueChanged<String> onSessionSelected;
  final ValueChanged<String> onSessionDeleted;
  const SessionListWidget({
    super.key,
    required this.sessionsState,
    required this.selectedSessionId,
    required this.onSessionSelected,
    required this.onSessionDeleted,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionsState.isLoading && sessionsState.sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final searchQuery = ref.watch(sessionSearchQueryProvider).toLowerCase();
    final selectedTopicId = ref.watch(selectedTopicIdProvider);
    final filteredSessions = sessionsState.sessions.where((s) {
      final matchesSearch = s.title.toLowerCase().contains(searchQuery);
      final matchesTopic =
          selectedTopicId == null || s.topicId == selectedTopicId;
      return matchesSearch && matchesTopic;
    }).toList();
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        ref.read(sessionsProvider.notifier).reorderSession(oldIndex, newIndex);
      },
      itemCount: filteredSessions.length,
      itemBuilder: (context, index) {
        final session = filteredSessions[index];
        final isSelected = session.sessionId == selectedSessionId;
        return ReorderableDelayedDragStartListener(
          key: Key(session.sessionId),
          index: index,
          child: RepaintBoundary(
            child: _TapDetector(
              onTap: () => onSessionSelected(session.sessionId),
              child: ListTile(
                selected: isSelected,
                selectedTileColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.5),
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 20),
                    Positioned(
                      top: -1,
                      right: -1,
                      child:
                          _SessionStatusIndicator(sessionId: session.sessionId),
                    ),
                  ],
                ),
                title: Text(session.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  DateFormat('MM/dd HH:mm').format(session.lastMessageTime) +
                      (session.totalTokens > 0
                          ? ' • ${formatTokenCount(session.totalTokens)} tokens'
                          : ''),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => onSessionDeleted(session.sessionId),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SessionStatusIndicator extends ConsumerWidget {
  final String sessionId;
  const _SessionStatusIndicator({required this.sessionId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.read(chatSessionManagerProvider);
    final sessionState = manager.getState(sessionId);
    final Color? statusColor;
    if (sessionState == null) {
      statusColor = null;
    } else if (sessionState.error != null) {
      statusColor = Colors.red;
    } else if (sessionState.isLoading) {
      statusColor = Colors.orange;
    } else if (sessionState.hasUnreadResponse) {
      statusColor = Colors.green;
    } else {
      statusColor = null;
    }
    if (statusColor == null) return const SizedBox.shrink();
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TapDetector extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _TapDetector({required this.onTap, required this.child});
  @override
  State<_TapDetector> createState() => _TapDetectorState();
}

class _TapDetectorState extends State<_TapDetector> {
  Offset? _downPosition;
  DateTime? _downTime;
  static const _tapTimeout = Duration(milliseconds: 300);
  static const _tapSlop = 18.0;
  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _downPosition = event.position;
        _downTime = DateTime.now();
      },
      onPointerUp: (event) {
        if (_downPosition != null && _downTime != null) {
          final elapsed = DateTime.now().difference(_downTime!);
          final distance = (event.position - _downPosition!).distance;
          if (elapsed < _tapTimeout && distance < _tapSlop) {
            widget.onTap();
          }
        }
        _downPosition = null;
        _downTime = null;
      },
      onPointerCancel: (_) {
        _downPosition = null;
        _downTime = null;
      },
      child: widget.child,
    );
  }
}
