import 'dart:convert';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../selectable_markdown/animated_streaming_markdown.dart';
import 'package:super_clipboard/super_clipboard.dart';
import '../../chat_provider.dart';
import '../../../domain/message.dart';
import '../chat_image_bubble.dart';
import '../reasoning_display.dart';
import 'chat_utils.dart';
import 'tool_output.dart';
import '../../../../settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/number_format_utils.dart';
import 'package:aurora/shared/utils/stats_calculator.dart';


class MergedMessageBubble extends ConsumerStatefulWidget {
  final MergedGroupItem group;
  final bool isLast;
  final bool isGenerating;
  const MergedMessageBubble({
    super.key,
    required this.group,
    this.isLast = false,
    this.isGenerating = false,
  });
  @override
  ConsumerState<MergedMessageBubble> createState() =>
      _MergedMessageBubbleState();
}

class _MergedMessageBubbleState extends ConsumerState<MergedMessageBubble>
    with AutomaticKeepAliveClientMixin {
  bool _isHovering = false;
  bool _isEditing = false;
  late TextEditingController _editController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _editScrollController = ScrollController();
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    final lastMsg = widget.group.messages.last;
    _editController = TextEditingController(text: lastMsg.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    _editScrollController.dispose();
    super.dispose();
  }

  void _handleAction(String action) async {
    final group = widget.group;
    final notifier = ref.read(historyChatProvider);
    switch (action) {
      case 'retry':
        notifier.regenerateResponse(group.messages.first.id);
        break;
      case 'edit':
        setState(() {
          _isEditing = true;
        });
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _focusNode.requestFocus());
        break;
      case 'copy':
        final item = DataWriterItem();
        item.add(Formats.plainText(widget.group.messages.last.content));
        SystemClipboard.instance?.write([item]);
        break;
      case 'delete':
        for (final msg in widget.group.messages) {
          notifier.deleteMessage(msg.id);
        }
        break;
      case 'branch':
        final sessionId = ref.read(selectedHistorySessionIdProvider);
        if (sessionId == null) break;
        final sessions = ref.read(sessionsProvider).sessions;
        final session = sessions.where((s) => s.sessionId == sessionId).firstOrNull;
        if (session == null) break;
        final l10n = AppLocalizations.of(context);
        final branchSuffix = l10n?.branch ?? 'Branch';
        final lastMsg = widget.group.messages.last;
        final newSessionId = await ref.read(sessionsProvider.notifier).createBranchSession(
          originalSessionId: sessionId,
          originalTitle: session.title,
          upToMessageId: lastMsg.id,
          branchSuffix: '-$branchSuffix',
        );
        if (newSessionId != null) {
          ref.read(selectedHistorySessionIdProvider.notifier).state = newSessionId;
        }
        break;
    }
  }

  void _saveEdit() {
    final lastMsg = widget.group.messages.last;
    if (_editController.text.trim().isNotEmpty) {
      ref
          .read(historyChatProvider)
          .editMessage(lastMsg.id, _editController.text);
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = fluent.FluentTheme.of(context);
    final messages = widget.group.messages;
    final lastMsg = messages.last;
    final l10n = AppLocalizations.of(context);
    final headerMsg = messages.firstWhere((m) => m.role != 'tool',
        orElse: () => messages.last);
    return MouseRegion(
      onEnter: (_) =>
          Platform.isWindows ? setState(() => _isHovering = true) : null,
      onExit: (_) =>
          Platform.isWindows ? setState(() => _isHovering = false) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Builder(builder: (context) {
              final settingsState = ref.watch(settingsProvider);
              final avatarPath = settingsState.llmAvatar;
              if (avatarPath != null && avatarPath.isNotEmpty) {
                return ClipOval(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Image.file(
                      File(avatarPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(AuroraIcons.robot,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.only(top: 2),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AuroraIcons.robot,
                    color: Colors.white, size: 16),
              );
            }),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${headerMsg.model ?? 'AI'} | ${headerMsg.provider ?? 'Assistant'}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),

                      ],
                    ),
                  ),
                  Container(
                    padding:
                        _isEditing ? EdgeInsets.zero : const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isEditing ? Colors.transparent : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: _isEditing
                          ? null
                          : Border.all(
                              color: theme.resources.dividerStrokeColorDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isEditing) ...[
                          ..._buildMergedContent(messages, theme, lastMsg),
                          if (widget.isGenerating &&
                              lastMsg.role != 'tool' &&
                              lastMsg.content.isEmpty &&
                              (lastMsg.reasoningContent?.isEmpty ?? true) &&
                              (lastMsg.toolCalls == null ||
                                  lastMsg.toolCalls!.isEmpty))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: Platform.isWindows
                                        ? const fluent.ProgressRing(
                                            strokeWidth: 2)
                                        : const CircularProgressIndicator(
                                            strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${l10n?.deepThinking ?? '思考中...'}',
                                    style: TextStyle(
                                      color: theme.typography.body?.color
                                          ?.withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (_isEditing)
                          Container(
                            key: ValueKey(
                                'merged_edit_container_${widget.group.messages.last.id}'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: fluent.TextBox(
                                      key: ValueKey(
                                          'merged_edit_box_${widget.group.messages.last.id}'),
                                      controller: _editController,
                                      scrollController: _editScrollController,
                                      focusNode: _focusNode,
                                      maxLines: 15,
                                      minLines: 1,
                                      decoration:
                                          const fluent.WidgetStatePropertyAll(
                                              fluent.BoxDecoration(
                                        color: Colors.transparent,
                                        border: Border.fromBorderSide(
                                            BorderSide.none),
                                      )),
                                      highlightColor: Colors.transparent,
                                      unfocusedColor: Colors.transparent,
                                      style: TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: theme.typography.body?.color),
                                      onSubmitted: (_) => _saveEdit(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ActionButton(
                                        icon: AuroraIcons.cancel,
                                        tooltip: l10n?.cancel ?? 'Cancel',
                                        onPressed: () =>
                                            setState(() => _isEditing = false)),
                                    const SizedBox(width: 4),
                                    ActionButton(
                                        icon: AuroraIcons.save,
                                        tooltip: l10n?.save ?? 'Save',
                                        onPressed: _saveEdit),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Platform.isWindows
                      ? Visibility(
                          visible: !_isEditing && !widget.isGenerating,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Row(
                              children: [
                                ActionButton(
                                    icon: AuroraIcons.refresh,
                                    tooltip: l10n?.retry ?? 'Retry',
                                    onPressed: () => _handleAction('retry')),
                                const SizedBox(width: 4),
                                ActionButton(
                                    icon: AuroraIcons.edit,
                                    tooltip: l10n?.edit ?? 'Edit',
                                    onPressed: () => _handleAction('edit')),
                                const SizedBox(width: 4),
                                ActionButton(
                                    icon: AuroraIcons.copy,
                                    tooltip: l10n?.copy ?? 'Copy',
                                    onPressed: () => _handleAction('copy')),
                                const SizedBox(width: 4),
                                ActionButton(
                                    icon: AuroraIcons.branch,
                                    tooltip: l10n?.branch ?? 'Branch',
                                    onPressed: () => _handleAction('branch')),
                                const SizedBox(width: 4),
                                ActionButton(
                                    icon: AuroraIcons.delete,
                                    tooltip: l10n?.delete ?? 'Delete',
                                    onPressed: () => _handleAction('delete')),
                              ],
                            ),
                          ),
                        )
                      : (!_isEditing && !widget.isGenerating)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MobileActionButton(
                                    icon: AuroraIcons.refresh,
                                    onPressed: () => _handleAction('retry'),
                                  ),
                                  MobileActionButton(
                                    icon: AuroraIcons.edit,
                                    onPressed: () => _handleAction('edit'),
                                  ),
                                  MobileActionButton(
                                    icon: AuroraIcons.copy,
                                    onPressed: () => _handleAction('copy'),
                                  ),
                                  MobileActionButton(
                                    icon: AuroraIcons.branch,
                                    onPressed: () => _handleAction('branch'),
                                  ),
                                  MobileActionButton(
                                    icon: AuroraIcons.delete,
                                    onPressed: () => _handleAction('delete'),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build merged content: aggregate all reasoning, all tool outputs, then all text content
  List<Widget> _buildMergedContent(
      List<Message> messages, fluent.FluentThemeData theme, Message lastMsg) {
    final parts = <Widget>[];

    // 1. Aggregate all reasoning content
    final allReasoning = StringBuffer();
    double totalReasoningDuration = 0;
    DateTime? firstReasoningTimestamp;
    bool hasActiveReasoning = false;

    for (final msg in messages) {
      if (msg.reasoningContent != null && msg.reasoningContent!.isNotEmpty) {
        if (allReasoning.isNotEmpty) {
          allReasoning.write('\n\n');
        }
        allReasoning.write(msg.reasoningContent!);
        totalReasoningDuration += msg.reasoningDurationSeconds ?? 0;
        firstReasoningTimestamp ??= msg.timestamp;
        if (widget.isGenerating && msg == lastMsg) {
          hasActiveReasoning = true;
        }
      }
    }

    if (allReasoning.isNotEmpty) {
      parts.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ReasoningDisplay(
          content: allReasoning.toString(),
          isWindows: Platform.isWindows,
          isRunning: hasActiveReasoning,
          duration: totalReasoningDuration > 0 ? totalReasoningDuration : null,
          startTime: firstReasoningTimestamp,
        ),
      ));
    }

    // 2. Aggregate all tool outputs
    final List<Map<String, dynamic>> allSearchResults = [];
    final List<String> otherToolOutputs = [];
    
    for (final msg in messages) {
      if (msg.role == 'tool') {
        try {
          final data = jsonDecode(msg.content) as Map<String, dynamic>?;
          if (data != null) {
            // Check if it's a Search result
            if (data['results'] is List) {
              final results = data['results'] as List;
              for (final r in results) {
                if (r is Map<String, dynamic>) {
                  allSearchResults.add(r);
                }
              }
            } else {
              // It's a general tool output or error
              otherToolOutputs.add(msg.content);
            }
          } else {
            // Raw string output
            otherToolOutputs.add(jsonEncode({'message': msg.content}));
          }
        } catch (_) {
          // If parsing fails, show raw content as message
          otherToolOutputs.add(jsonEncode({'message': msg.content}));
        }
      }
    }

    // Render Search Results if any
    if (allSearchResults.isNotEmpty) {
      final mergedJson = jsonEncode({'results': allSearchResults});
      parts.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: BuildToolOutput(content: mergedJson),
      ));
    }

    // Render Other Tool Outputs (Shell, Errors, etc.)
    for (final output in otherToolOutputs) {
      parts.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: BuildToolOutput(content: output),
      ));
    }

    // 3. Render text content and images for non-tool messages
    for (final message in messages) {
      if (message.role == 'tool') continue;

      if (message.content.isNotEmpty) {
        parts.add(fluent.FluentTheme(
          data: theme,
          child: AnimatedStreamingMarkdown(
            data: message.content,
            isDark: theme.brightness == Brightness.dark,
            textColor: theme.typography.body!.color!,
          ),
        ));
      }

      if (message.images.isNotEmpty) {
        parts.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.images
                  .map((img) => ChatImageBubble(
                        key: ValueKey(img.hashCode),
                        imageUrl: img,
                      ))
                  .toList(),
            ),
          ),
        );
      }

      // Timestamp footer (only for the last non-tool message, and not while generating)
      final isCurrentlyGenerating = widget.isGenerating && message == lastMsg;
      if (!isCurrentlyGenerating && message == messages.where((m) => m.role != 'tool').lastOrNull) {
        parts.add(
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.tokenCount != null && message.tokenCount! > 0) ...[
                  Builder(builder: (context) {
                    final p = message.promptTokens ?? 0;
                    final c = message.completionTokens ?? 0;
                    final r = message.reasoningTokens ?? 0;
                    final total = message.tokenCount!;
                    
                    String tokenText = formatFullTokenCount(total);

                    
                    return Text(
                      '$tokenText Tokens',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.typography.body!.color!.withOpacity(0.5),
                      ),
                    );
                  }),
                  if (message.firstTokenMs != null && message.firstTokenMs! > 0) ...[
                    Text(
                      ' | ',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.typography.body!.color!.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context)?.averageFirstToken((message.firstTokenMs! / 1000).toStringAsFixed(2)) ?? 'TTFT: ${(message.firstTokenMs! / 1000).toStringAsFixed(2)}s'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.typography.body!.color!.withOpacity(0.5),
                      ),
                    ),
                  ],
                  if (message.durationMs != null &&
                      message.durationMs! > 0 &&
                      message.tokenCount != null &&
                      message.tokenCount! > 0) ...[
                    Text(
                      ' | ',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.typography.body!.color!.withOpacity(0.5),
                      ),
                    ),
                    Builder(builder: (context) {
                      final c = message.completionTokens ?? 0;
                      final r = message.reasoningTokens ?? 0;
                      final p = message.promptTokens ?? 0;
                      
                      int effectiveGenerated = c + r;
                      if (effectiveGenerated == 0 && (message.tokenCount ?? 0) > 0) {
                        effectiveGenerated = (message.tokenCount! - p);
                      }

                      final tps = StatsCalculator.calculateTPS(
                        completionTokens: effectiveGenerated,
                        reasoningTokens: 0,
                        durationMs: message.durationMs ?? 0,
                        firstTokenMs: message.firstTokenMs ?? 0,
                      );

                      if (tps <= 0) return const SizedBox.shrink();
                      
                      return Text(
                        'Token/s: ${tps.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.typography.body!.color!.withOpacity(0.5),
                        ),
                      );
                    }),
                  ],
                  Text(
                    ' | ',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.typography.body!.color!.withOpacity(0.5),
                    ),
                  ),
                ],
                Text(
                  '${message.timestamp.month}/${message.timestamp.day} ${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.typography.body!.color!.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return parts;
  }
}
