import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../chat/presentation/chat_provider.dart';
import '../../chat/presentation/widgets/chat_view.dart';

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
      // SessionsNotifier handles restoration or default selection
      await ref.read(sessionsProvider.notifier).loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
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
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    final sessionsState = ref.watch(sessionsProvider);

    if (selectedSessionId != null && selectedSessionId != '') {
      return Column(
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
                  onPressed: () {
                    ref
                        .read(selectedHistorySessionIdProvider.notifier)
                        .state = null;
                  },
                ),
                const SizedBox(width: 8),
                const Text('会话详情',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(child: ChatView(sessionId: selectedSessionId)),
        ],
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

    return Container(
      color: fluent.FluentTheme.of(context).navigationPaneTheme.backgroundColor,
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
                      color: fluent.FluentTheme.of(context).navigationPaneTheme.backgroundColor,
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
                color: fluent.FluentTheme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04), // Subtle shadow for depth
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  child: selectedSessionId == null
                      ? const Center(child: Text('请选择或新建一个话题'))
                      : ChatView(key: ValueKey(selectedSessionId), sessionId: selectedSessionId),
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
    // Watch trigger to rebuild when any session state changes
    ref.watch(chatStateUpdateTriggerProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: fluent.HoverButton(
            onPressed: () {
              ref.read(sessionsProvider.notifier).startNewSession();
            },
            builder: (context, states) {
              final theme = fluent.FluentTheme.of(context);
              final isHovering = states.isHovered;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isHovering 
                      ? theme.resources.subtleFillColorSecondary 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isHovering 
                        ? theme.resources.surfaceStrokeColorDefault
                        : Colors.transparent, // Only show border on hover
                  ),
                ),
                child: Row(
                  children: [
                    Icon(fluent.FluentIcons.add, 
                        size: 14, 
                        color: theme.accentColor),
                    const SizedBox(width: 12),
                    Text('开启新对话', 
                        style: TextStyle(
                            fontSize: 14,
                            color: theme.typography.body?.color,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    if (isHovering)
                       Icon(fluent.FluentIcons.chevron_right, size: 10, color: theme.resources.textFillColorSecondary),
                  ],
                ),
              );
            },
          ),
        ),
        // Removed Divider
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
                    ref.read(sessionsProvider.notifier).reorderSession(oldIndex, newIndex);
                  },
                  itemCount: sessionsState.sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessionsState.sessions[index];
                    final isSelected = session.sessionId == selectedSessionId;
                    
                    // Get session state for status indicator
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
                          // Cleanup current session if empty before switching
                          final currentId = ref.read(selectedHistorySessionIdProvider);
                          if (currentId != null && currentId != session.sessionId) {
                            await ref.read(sessionsProvider.notifier).cleanupSessionIfEmpty(currentId);
                          }
                          ref
                              .read(selectedHistorySessionIdProvider.notifier)
                              .state = session.sessionId;
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
  final dynamic session; // Using dynamic to avoid import issues if Session model isn't exported here, but ideally should be typed
  final bool isSelected;
  final Color? statusColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionItem({
    required this.session,
    required this.isSelected,
    required this.statusColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SessionItem> createState() => _SessionItemState();
}

class _SessionItemState extends State<_SessionItem> {
  bool _isHovering = false;

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
                ? theme.accentColor.withOpacity(0.1)
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
                      Text(widget.session.title,
                          style: TextStyle(
                            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(DateFormat('MM/dd HH:mm')
                          .format(widget.session.lastMessageTime),
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.resources.textFillColorSecondary
                          )),
                    ],
                  ),
                ),
                if (widget.isSelected || _isHovering)
                  fluent.IconButton(
                    icon: const fluent.Icon(fluent.FluentIcons.delete,
                        size: 14),
                    onPressed: widget.onDelete,
                  ),
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
    final filteredSessions = sessionsState.sessions.where((s) {
      return s.title.toLowerCase().contains(searchQuery);
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
          child: RepaintBoundary( // Isolate item painting
            child: _TapDetector(
              onTap: () => onSessionSelected(session.sessionId),
              child: ListTile(
                selected: isSelected,
                selectedTileColor:
                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 20),
                    Positioned(
                      top: -1,
                      right: -1,
                      child: _SessionStatusIndicator(sessionId: session.sessionId),
                    ),
                  ],
                ),
                title: Text(session.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  DateFormat('MM/dd HH:mm').format(session.lastMessageTime),
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
    // Read (not watch) the manager to avoid cascading rebuilds of ALL items
    // when any session state changes. Each indicator only needs to show
    // the current state at render time - it will re-render when the list itself rebuilds.
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
      statusColor = Colors.green; // Unread check complete
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

/// A tap detector that uses raw pointer events instead of GestureDetector.
/// This avoids participating in the gesture arena, allowing ReorderableDelayedDragStartListener
/// to properly recognize long press for dragging.
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
  static const _tapSlop = 18.0; // movement threshold

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
          
          // Only trigger tap if quick press and minimal movement
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
