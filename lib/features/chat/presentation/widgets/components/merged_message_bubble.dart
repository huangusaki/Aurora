import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../selectable_markdown/selectable_markdown.dart';
import 'package:super_clipboard/super_clipboard.dart';
import '../../chat_provider.dart';
import '../../../domain/message.dart';
import '../chat_image_bubble.dart';
import '../reasoning_display.dart';
import 'chat_utils.dart';
import 'tool_output.dart';
import '../../../../settings/presentation/settings_provider.dart';


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

  void _handleAction(String action) {
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
    final headerMsg = messages.firstWhere((m) => m.role != 'tool',
        orElse: () => messages.last);
    return MouseRegion(
      onEnter: (_) =>
          Platform.isWindows ? setState(() => _isHovering = true) : null,
      onExit: (_) =>
          Platform.isWindows ? setState(() => _isHovering = false) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                        child: const Icon(fluent.FluentIcons.robot,
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
                child: const Icon(fluent.FluentIcons.robot,
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
                          ...messages.expand((msg) {
                            return _buildMessageParts(msg, theme);
                          }),
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
                                    '思考中...',
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
                                        icon: fluent.FluentIcons.cancel,
                                        tooltip: 'Cancel',
                                        onPressed: () =>
                                            setState(() => _isEditing = false)),
                                    const SizedBox(width: 4),
                                    ActionButton(
                                        icon: fluent.FluentIcons.save,
                                        tooltip: 'Save',
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
                                    icon: fluent.FluentIcons.refresh,
                                    tooltip: 'Retry',
                                    onPressed: () => _handleAction('retry')),
                                const SizedBox(width: 4),
                                ActionButton(
                                    icon: fluent.FluentIcons.edit,
                                    tooltip: 'Edit',
                                    onPressed: () => _handleAction('edit')),
                                const SizedBox(width: 4),
                                ActionButton(
                                    icon: fluent.FluentIcons.copy,
                                    tooltip: 'Copy',
                                    onPressed: () => _handleAction('copy')),
                                const SizedBox(width: 4),
                                ActionButton(
                                    icon: fluent.FluentIcons.delete,
                                    tooltip: 'Delete',
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
                                    icon: Icons.refresh,
                                    onPressed: () => _handleAction('retry'),
                                  ),
                                  MobileActionButton(
                                    icon: Icons.edit_outlined,
                                    onPressed: () => _handleAction('edit'),
                                  ),
                                  MobileActionButton(
                                    icon: Icons.copy_outlined,
                                    onPressed: () => _handleAction('copy'),
                                  ),
                                  MobileActionButton(
                                    icon: Icons.delete_outline,
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

  List<Widget> _buildMessageParts(
      Message message, fluent.FluentThemeData theme) {
    if (message.role == 'tool') {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: BuildToolOutput(content: message.content),
        )
      ];
    }
    final parts = <Widget>[];
    if (message.reasoningContent != null &&
        message.reasoningContent!.isNotEmpty) {
      parts.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ReasoningDisplay(
          content: message.reasoningContent!,
          isWindows: Platform.isWindows,
          isRunning:
              widget.isGenerating && message == widget.group.messages.last,
          duration: message.reasoningDurationSeconds,
          startTime: message.timestamp,
        ),
      ));
    }
    if (message.content.isNotEmpty) {
      parts.add(fluent.FluentTheme(
        data: theme,
        child: SelectableMarkdown(
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
    parts.add(
      Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.tokenCount != null && message.tokenCount! > 0) ...[
              Text(
                '${message.tokenCount} Tokens',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.typography.body!.color!.withOpacity(0.5),
                ),
              ),
              if (message.firstTokenMs != null && message.firstTokenMs! > 0) ...[
                Text(
                  ' | ',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.typography.body!.color!.withOpacity(0.5),
                  ),
                ),
                Text(
                  'FirstToken: ${(message.firstTokenMs! / 1000).toStringAsFixed(2)}s',
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
                Text(
                  'Token/s: ${(message.tokenCount! / (message.durationMs! / 1000)).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.typography.body!.color!.withOpacity(0.5),
                  ),
                ),
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
    return parts;
  }
}
