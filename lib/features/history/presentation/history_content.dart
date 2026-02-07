import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aurora/features/chat/presentation/chat_provider.dart';
import 'package:aurora/features/chat/presentation/topic_provider.dart';
import 'package:aurora/features/chat/presentation/widgets/chat_view.dart';
import 'package:aurora/features/chat/presentation/widgets/topic_dropdown.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/number_format_utils.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:aurora/features/chat/data/session_entity.dart';

class _SessionTreeItem {
  final SessionEntity session;
  final int depth;
  final bool hasChildren;
  final bool isCollapsed;
  const _SessionTreeItem({
    required this.session,
    required this.depth,
    required this.hasChildren,
    required this.isCollapsed,
  });
}

List<_SessionTreeItem> _buildSessionTreeItems(
  List<SessionEntity> sessions, {
  required int? selectedTopicId,
  required String searchQuery,
  required Set<String> collapsedSessionIds,
}) {
  final normalizedQuery = searchQuery.trim().toLowerCase();
  final idMap = {for (final session in sessions) session.sessionId: session};
  final childrenMap = <String, List<SessionEntity>>{};
  final roots = <SessionEntity>[];

  for (final session in sessions) {
    final parentId = session.parentSessionId;
    if (parentId == null || parentId.isEmpty || !idMap.containsKey(parentId)) {
      roots.add(session);
      continue;
    }
    childrenMap.putIfAbsent(parentId, () => <SessionEntity>[]).add(session);
  }

  bool matchesTopic(SessionEntity session) {
    return selectedTopicId == null || session.topicId == selectedTopicId;
  }

  bool matchesQuery(SessionEntity session) {
    if (normalizedQuery.isEmpty) return true;
    return session.title.toLowerCase().contains(normalizedQuery);
  }

  final includedIds = <String>{};
  if (normalizedQuery.isEmpty) {
    for (final session in sessions) {
      if (matchesTopic(session)) {
        includedIds.add(session.sessionId);
      }
    }
  } else {
    for (final session in sessions) {
      if (!matchesTopic(session) || !matchesQuery(session)) continue;
      SessionEntity? current = session;
      while (current != null && matchesTopic(current)) {
        includedIds.add(current.sessionId);
        final parentId = current.parentSessionId;
        if (parentId == null || parentId.isEmpty) break;
        current = idMap[parentId];
      }
    }
  }

  final forceExpand = normalizedQuery.isNotEmpty;
  final visibleItems = <_SessionTreeItem>[];

  void appendNode(SessionEntity session, int depth) {
    if (!includedIds.contains(session.sessionId)) return;
    final childSessions =
        (childrenMap[session.sessionId] ?? const <SessionEntity>[])
            .where((child) => includedIds.contains(child.sessionId))
            .toList();
    final hasChildren = childSessions.isNotEmpty;
    final isCollapsed = hasChildren &&
        !forceExpand &&
        collapsedSessionIds.contains(session.sessionId);
    visibleItems.add(_SessionTreeItem(
      session: session,
      depth: depth,
      hasChildren: hasChildren,
      isCollapsed: isCollapsed,
    ));
    if (isCollapsed) return;
    for (final child in childSessions) {
      appendNode(child, depth + 1);
    }
  }

  for (final root in roots) {
    appendNode(root, 0);
  }
  return visibleItems;
}

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

class _SessionList extends ConsumerStatefulWidget {
  final SessionsState sessionsState;
  final String? selectedSessionId;
  final bool isMobile;
  const _SessionList({
    required this.sessionsState,
    required this.selectedSessionId,
    required this.isMobile,
  });

  @override
  ConsumerState<_SessionList> createState() => _SessionListState();
}

class _SessionListState extends ConsumerState<_SessionList> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(sessionSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(chatSessionManagerProvider);
    ref.watch(chatStateUpdateTriggerProvider);
    ref.listen(selectedHistorySessionIdProvider, (_, next) {
      if (next != null) {
        final storage = ref.read(settingsStorageProvider);
        storage.saveLastSessionId(next);
      }
    });

    final searchQuery = ref.watch(sessionSearchQueryProvider);
    if (_searchController.text != searchQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: searchQuery,
        selection: TextSelection.collapsed(offset: searchQuery.length),
        composing: TextRange.empty,
      );
    }

    final selectedTopicId = ref.watch(selectedTopicIdProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = fluent.FluentTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collapsedSessionIds = ref.watch(collapsedHistorySessionIdsProvider);
    final visibleSessionItems = _buildSessionTreeItems(
      widget.sessionsState.sessions,
      selectedTopicId: selectedTopicId,
      searchQuery: searchQuery,
      collapsedSessionIds: collapsedSessionIds,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isMobile) ...[
                Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        ref.read(sessionSearchQueryProvider.notifier).state =
                            value;
                      },
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: l10n.searchChatHistory,
                        hintStyle:
                            TextStyle(color: Colors.grey[600], fontSize: 12),
                        prefixIcon: Icon(AuroraIcons.search,
                            size: 16, color: theme.accentColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(AuroraIcons.close,
                                    size: 14, color: Colors.grey[600]),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(sessionSearchQueryProvider.notifier)
                                      .state = '';
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            : null,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TopicDropdown(isMobile: widget.isMobile),
              const SizedBox(height: 4),
              fluent.HoverButton(
                onPressed: () {
                  ref.read(sessionsProvider.notifier).startNewSession();
                },
                builder: (context, states) {
                  final isHovered = states.isHovered;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? theme.resources.subtleFillColorSecondary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isHovered
                            ? theme.resources.surfaceStrokeColorDefault
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(AuroraIcons.add,
                            size: 14, color: theme.accentColor),
                        const SizedBox(width: 12),
                        Text(l10n.startNewChat,
                            style: TextStyle(
                                fontSize: 14,
                                color: theme.typography.body?.color,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        if (isHovered)
                          Icon(AuroraIcons.chevronRight,
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
          child: widget.sessionsState.isLoading &&
                  widget.sessionsState.sessions.isEmpty
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
                    final visibleIds = visibleSessionItems
                        .map((item) => item.session.sessionId)
                        .toList();
                    if (oldIndex < 0 || oldIndex >= visibleIds.length) return;
                    final draggedId = visibleIds.removeAt(oldIndex);
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    if (newIndex < 0) newIndex = 0;
                    if (newIndex > visibleIds.length) {
                      newIndex = visibleIds.length;
                    }
                    final beforeSessionId = newIndex >= visibleIds.length
                        ? null
                        : visibleIds[newIndex];
                    ref.read(sessionsProvider.notifier).reorderSessionById(
                          draggedSessionId: draggedId,
                          beforeSessionId: beforeSessionId,
                        );
                  },
                  itemCount: visibleSessionItems.length,
                  itemBuilder: (context, index) {
                    final treeItem = visibleSessionItems[index];
                    final session = treeItem.session;
                    final isSelected =
                        session.sessionId == widget.selectedSessionId;
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
                              .read(sessionsProvider.notifier)
                              .ensureSessionVisible(session.sessionId);
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
                        depth: treeItem.depth,
                        hasChildren: treeItem.hasChildren,
                        isCollapsed: treeItem.isCollapsed,
                        onToggleCollapse: treeItem.hasChildren
                            ? () {
                                final nextCollapsed = Set<String>.from(ref
                                    .read(collapsedHistorySessionIdsProvider));
                                if (treeItem.isCollapsed) {
                                  nextCollapsed.remove(session.sessionId);
                                } else {
                                  nextCollapsed.add(session.sessionId);
                                }
                                ref
                                    .read(collapsedHistorySessionIdsProvider
                                        .notifier)
                                    .state = nextCollapsed;
                              }
                            : null,
                        isMobile: widget.isMobile,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SessionItem extends ConsumerStatefulWidget {
  final SessionEntity session;
  final bool isSelected;
  final Color? statusColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(String newTitle) onRename;
  final int depth;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final bool isMobile;
  const _SessionItem({
    required this.session,
    required this.isSelected,
    required this.statusColor,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    this.depth = 0,
    this.hasChildren = false,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.isMobile = false,
  });
  @override
  ConsumerState<_SessionItem> createState() => _SessionItemState();
}

class _SessionItemState extends ConsumerState<_SessionItem> {
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
                ? theme.accentColor.normal.withValues(alpha: 0.15)
                : (_isHovering
                    ? theme.resources.subtleFillColorSecondary
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: fluent.Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (widget.depth > 0)
                  SizedBox(width: (widget.depth * 12).toDouble()),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: widget.hasChildren
                      ? fluent.IconButton(
                          icon: Icon(
                            widget.isCollapsed
                                ? AuroraIcons.chevronRight
                                : AuroraIcons.chevronDown,
                            size: 14,
                          ),
                          onPressed: widget.onToggleCollapse,
                        )
                      : widget.depth > 0
                          ? Icon(
                              AuroraIcons.branch,
                              size: 12,
                              color: theme.resources.textFillColorSecondary,
                            )
                          : const SizedBox.shrink(),
                ),
                const SizedBox(width: 4),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.resources.textFillColorSecondary)),
                    ],
                  ),
                ),
                if ((widget.isSelected || _isHovering || widget.isMobile) &&
                    !_isRenaming) ...[
                  fluent.IconButton(
                    icon: const fluent.Icon(AuroraIcons.edit, size: 14),
                    onPressed: _startRenaming,
                  ),
                  fluent.IconButton(
                    icon: const fluent.Icon(AuroraIcons.delete, size: 14),
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
    final searchQuery = ref.watch(sessionSearchQueryProvider);
    final selectedTopicId = ref.watch(selectedTopicIdProvider);
    final collapsedSessionIds = ref.watch(collapsedHistorySessionIdsProvider);
    final visibleSessionItems = _buildSessionTreeItems(
      sessionsState.sessions,
      selectedTopicId: selectedTopicId,
      searchQuery: searchQuery,
      collapsedSessionIds: collapsedSessionIds,
    );
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        final visibleIds =
            visibleSessionItems.map((item) => item.session.sessionId).toList();
        if (oldIndex < 0 || oldIndex >= visibleIds.length) return;
        final draggedId = visibleIds.removeAt(oldIndex);
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        if (newIndex < 0) newIndex = 0;
        if (newIndex > visibleIds.length) {
          newIndex = visibleIds.length;
        }
        final beforeSessionId =
            newIndex >= visibleIds.length ? null : visibleIds[newIndex];
        ref.read(sessionsProvider.notifier).reorderSessionById(
              draggedSessionId: draggedId,
              beforeSessionId: beforeSessionId,
            );
      },
      itemCount: visibleSessionItems.length,
      itemBuilder: (context, index) {
        final treeItem = visibleSessionItems[index];
        final session = treeItem.session;
        final isSelected = session.sessionId == selectedSessionId;
        return ReorderableDelayedDragStartListener(
          key: Key(session.sessionId),
          index: index,
          child: RepaintBoundary(
            child: ListTile(
              onTap: () {
                ref
                    .read(sessionsProvider.notifier)
                    .ensureSessionVisible(session.sessionId);
                onSessionSelected(session.sessionId);
              },
              selected: isSelected,
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.5),
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  const SizedBox(width: 28, height: 28),
                  Positioned(
                    top: -1,
                    right: -1,
                    child:
                        _SessionStatusIndicator(sessionId: session.sessionId),
                  ),
                ],
              ),
              title: Row(
                children: [
                  if (treeItem.depth > 0)
                    SizedBox(width: (treeItem.depth * 12).toDouble()),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: treeItem.hasChildren
                        ? IconButton(
                            visualDensity: VisualDensity.compact,
                            splashRadius: 14,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              treeItem.isCollapsed
                                  ? AuroraIcons.chevronRight
                                  : AuroraIcons.chevronDown,
                              size: 14,
                            ),
                            onPressed: () {
                              final nextCollapsed = Set<String>.from(
                                  ref.read(collapsedHistorySessionIdsProvider));
                              if (treeItem.isCollapsed) {
                                nextCollapsed.remove(session.sessionId);
                              } else {
                                nextCollapsed.add(session.sessionId);
                              }
                              ref
                                  .read(collapsedHistorySessionIdsProvider
                                      .notifier)
                                  .state = nextCollapsed;
                            },
                          )
                        : treeItem.depth > 0
                            ? Icon(
                                AuroraIcons.branch,
                                size: 12,
                                color: Theme.of(context).hintColor,
                              )
                            : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
