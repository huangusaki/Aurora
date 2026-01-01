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
      await ref.read(sessionsProvider.notifier).loadSessions();
      if (ref.read(selectedHistorySessionIdProvider) == null) {
        final sessions = ref.read(sessionsProvider).sessions;
        if (sessions.isNotEmpty) {
          ref.read(selectedHistorySessionIdProvider.notifier).state =
              sessions.first.sessionId;
        } else {
          ref.read(selectedHistorySessionIdProvider.notifier).state =
              'new_chat';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsState = ref.watch(sessionsProvider);
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Enforce desktop layout on Windows, regardless of width
        final isMobile = !Platform.isWindows && constraints.maxWidth < 600;
        if (isMobile) {
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
                const Expanded(child: ChatView()),
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
        final isSidebarVisible = ref.watch(isHistorySidebarVisibleProvider);
        return Row(
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
                        border: Border(
                            right: BorderSide(
                                color: fluent.FluentTheme.of(context)
                                    .resources
                                    .dividerStrokeColorDefault)),
                        color: fluent.FluentTheme.of(context).cardColor,
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
              child: RepaintBoundary(
                child: selectedSessionId == null
                    ? const Center(child: Text('请选择或新建一个话题'))
                    : const ChatView(),
              ),
            ),
          ],
        );
      },
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: fluent.Button(
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    fluent.Icon(fluent.FluentIcons.add),
                    SizedBox(width: 8),
                    Text('新建话题')
                  ]),
              onPressed: () {
                ref.read(selectedHistorySessionIdProvider.notifier).state =
                    'new_chat';
              },
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: sessionsState.isLoading && sessionsState.sessions.isEmpty
              ? const Center(child: fluent.ProgressRing())
              : ListView.builder(
                  itemCount: sessionsState.sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessionsState.sessions[index];
                    final isSelected = session.sessionId == selectedSessionId;
                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(selectedHistorySessionIdProvider.notifier)
                            .state = session.sessionId;
                      },
                      child: Container(
                        color: isSelected
                            ? fluent.FluentTheme.of(context)
                                .accentColor
                                .withOpacity(0.1)
                            : Colors.transparent,
                        child: fluent.ListTile(
                          title: Text(session.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(DateFormat('MM/dd HH:mm')
                              .format(session.lastMessageTime)),
                          onPressed: () {
                            ref
                                .read(selectedHistorySessionIdProvider.notifier)
                                .state = session.sessionId;
                          },
                          trailing: fluent.IconButton(
                            icon: const fluent.Icon(fluent.FluentIcons.delete,
                                size: 12),
                            onPressed: () {
                              ref
                                  .read(sessionsProvider.notifier)
                                  .deleteSession(session.sessionId);
                              if (isSelected) {
                                ref
                                    .read(selectedHistorySessionIdProvider
                                        .notifier)
                                    .state = null;
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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
    return ListView.builder(
      itemCount: sessionsState.sessions.length,
      itemBuilder: (context, index) {
        final session = sessionsState.sessions[index];
        final isSelected = session.sessionId == selectedSessionId;
        return ListTile(
          selected: isSelected,
          selectedTileColor:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          leading: const Icon(Icons.chat_bubble_outline, size: 20),
          title: Text(session.title,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            DateFormat('MM/dd HH:mm').format(session.lastMessageTime),
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () => onSessionSelected(session.sessionId),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => onSessionDeleted(session.sessionId),
          ),
        );
      },
    );
  }
}
