import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../selectable_markdown/animated_streaming_markdown.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:file_selector/file_selector.dart';
import '../../chat_provider.dart';
import '../../../domain/message.dart';
import '../chat_image_bubble.dart';
import '../reasoning_display.dart';
import '../../../../settings/presentation/settings_provider.dart';
import '../../../../history/presentation/widgets/hover_image_preview.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'chat_utils.dart';
import 'tool_output.dart';
import '../../../../../shared/utils/stats_calculator.dart';
import 'package:aurora/shared/utils/number_format_utils.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';


class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isLast;
  final bool isGenerating;
  final bool showAvatar;
  final bool mergeTop;
  final bool mergeBottom;
  const MessageBubble({
    super.key,
    required this.message,
    required this.isLast,
    this.isGenerating = false,
    this.showAvatar = true,
    this.mergeTop = false,
    this.mergeBottom = false,
  });
  @override
  ConsumerState<MessageBubble> createState() => MessageBubbleState();
}

class MessageBubbleState extends ConsumerState<MessageBubble> {
  bool _isHovering = false;
  bool _isEditing = false;
  late TextEditingController _editController;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _editScrollController = ScrollController();
  late List<String> _newAttachments;
  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
    _newAttachments = List.from(widget.message.attachments);
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content) {
      _editController.text = widget.message.content;
    }
    if (oldWidget.message.attachments != widget.message.attachments) {
      if (!_isEditing) {
        _newAttachments = List.from(widget.message.attachments);
      }
    }
  }

  bool _isPasting = false;
  Future<void> _pickFiles() async {
    const typeGroup = XTypeGroup(
        label: 'images', extensions: ['jpg', 'png', 'jpeg', 'bmp', 'gif']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return;
    final newPaths = files
        .map((file) => file.path)
        .where((path) => !_newAttachments.contains(path))
        .toList();
    if (newPaths.isNotEmpty) {
      setState(() {
        _newAttachments.addAll(newPaths);
      });
    }
  }

  Future<void> _handlePaste() async {
    if (_isPasting) {
      return;
    }
    _isPasting = true;
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        return;
      }
      final reader = await clipboard.read();
      if (reader.canProvide(Formats.png) ||
          reader.canProvide(Formats.jpeg) ||
          reader.canProvide(Formats.fileUri)) {
        await _processReader(reader);
        return;
      }
      if (reader.canProvide(Formats.plainText)) {
        final text = await reader.readValue(Formats.plainText);
        if (text != null && text.isNotEmpty) {
          final selection = _editController.selection;
          final currentText = _editController.text;
          if (selection.isValid) {
            final newText =
                currentText.replaceRange(selection.start, selection.end, text);
            _editController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                  offset: selection.start + text.length),
            );
          } else {
            _editController.text += text;
          }
        }
        return;
      }
      try {
        final imageBytes = await Pasteboard.image;
        if (imageBytes != null && imageBytes.isNotEmpty) {
          final attachDir = await getAttachmentsDir();
          final path =
              '${attachDir.path}${Platform.pathSeparator}paste_fb_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(path).writeAsBytes(imageBytes);
          if (mounted) {
            if (!_newAttachments.contains(path)) {
              setState(() {
                _newAttachments.add(path);
              });
            } else {}
          }
          return;
        }
      } catch (e) {
        debugPrint('Pasteboard Fallback Error: $e');
      }
    } finally {
      _isPasting = false;
    }
  }

  Future<void> _processReader(ClipboardReader reader) async {
    final completer = Completer<void>();
    if (reader.canProvide(Formats.png)) {
      reader.getFile(Formats.png, (file) async {
        await _saveClipImage(file);
        if (!completer.isCompleted) completer.complete();
      });
    } else if (reader.canProvide(Formats.jpeg)) {
      reader.getFile(Formats.jpeg, (file) async {
        await _saveClipImage(file);
        if (!completer.isCompleted) completer.complete();
      });
    } else if (reader.canProvide(Formats.fileUri)) {
      final uri = await reader.readValue(Formats.fileUri);
      if (uri != null) {
        final path = uri.toFilePath();
        final ext = path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
          if (mounted && !_newAttachments.contains(path)) {
            setState(() {
              _newAttachments.add(path);
            });
          } else {}
        }
      }
      if (!completer.isCompleted) completer.complete();
    } else {
      if (!completer.isCompleted) completer.complete();
    }
    try {
      await completer.future.timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Paste completion timeout: $e');
    }
  }

  Future<void> _saveClipImage(file) async {
    try {
      final attachDir = await getAttachmentsDir();
      final path =
          '${attachDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.png';
      final stream = file.getStream();
      final List<int> bytes = [];
      await for (final chunk in stream) {
        bytes.addAll(chunk as List<int>);
      }
      if (bytes.isNotEmpty) {
        await File(path).writeAsBytes(bytes);
        if (mounted) {
          if (!_newAttachments.contains(path)) {
            setState(() {
              _newAttachments.add(path);
            });
          } else {}
        }
      }
    } catch (e) {
      debugPrint('Paste Error: $e');
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    _editScrollController.dispose();
    super.dispose();
  }

  void _handleAction(String action) async {
    final msg = widget.message;
    final notifier = ref.read(historyChatProvider);
    switch (action) {
      case 'retry':
        notifier.regenerateResponse(msg.id);
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
        item.add(Formats.plainText(msg.content));
        SystemClipboard.instance?.write([item]);
        break;
      case 'delete':
        notifier.deleteMessage(msg.id);
        break;
      case 'branch':
        final sessionId = ref.read(selectedHistorySessionIdProvider);
        if (sessionId == null) break;
        final sessions = ref.read(sessionsProvider).sessions;
        final session = sessions.where((s) => s.sessionId == sessionId).firstOrNull;
        if (session == null) break;
        final l10n = AppLocalizations.of(context);
        final branchSuffix = l10n?.branch ?? 'Branch';
        final newSessionId = await ref.read(sessionsProvider.notifier).createBranchSession(
          originalSessionId: sessionId,
          originalTitle: session.title,
          upToMessageId: msg.id,
          branchSuffix: '-$branchSuffix',
        );
        if (newSessionId != null) {
          ref.read(selectedHistorySessionIdProvider.notifier).state = newSessionId;
        }
        break;
    }
  }

  Future<void> _saveEdit() async {
    if (_editController.text.trim().isNotEmpty) {
      await ref.read(historyChatProvider).editMessage(
          widget.message.id, _editController.text,
          newAttachments: _newAttachments);
    }
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isUser = message.isUser;
    final settingsState = ref.watch(settingsProvider);
    final theme = fluent.FluentTheme.of(context);
    return MouseRegion(
      onEnter: (_) =>
          PlatformUtils.isDesktop ? setState(() => _isHovering = true) : null,
      onExit: (_) =>
          PlatformUtils.isDesktop ? setState(() => _isHovering = false) : null,
      child: Container(
        margin: EdgeInsets.only(
          top: widget.mergeTop ? 2 : 8,
          bottom: widget.mergeBottom ? 2 : 16,
          left: 10,
          right: 10,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  if (widget.showAvatar) ...[
                    _buildAvatar(
                      avatarPath: settingsState.llmAvatar,
                      fallbackIcon: AuroraIcons.robot,
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                  ] else
                    const SizedBox(width: 40),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (widget.showAvatar)
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 4, left: 4, right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              if (isUser) ...[

                                Text(
                                  settingsState.userName.isNotEmpty
                                      ? settingsState.userName
                                      : AppLocalizations.of(context)!.user,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                ),
                              ] else ...[
                                Text(
                                  '${message.model ?? settingsState.selectedModel} | ${message.provider ?? settingsState.activeProvider?.name ?? 'AI'}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                ),

                              ],
                            ],
                          ),
                        ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 0),
                        child: Container(
                          padding: _isEditing
                              ? EdgeInsets.zero
                              : const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isEditing
                                ? fluent.Colors.transparent
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: _isEditing
                                ? null
                                : Border.all(
                                    color: theme
                                        .resources.dividerStrokeColorDefault),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!message.isUser &&
                                  widget.isGenerating &&
                                  message.content.isEmpty &&
                                  (message.reasoningContent == null ||
                                      message.reasoningContent!.isEmpty))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: PlatformUtils.isDesktop
                                            ? const fluent.ProgressRing(
                                                strokeWidth: 2)
                                            : const CircularProgressIndicator(
                                                strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${AppLocalizations.of(context)!.thinking}...',
                                        style: TextStyle(
                                          color: theme.typography.body?.color
                                              ?.withOpacity(0.6),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (!message.isUser &&
                                  message.reasoningContent != null &&
                                  message.reasoningContent!.isNotEmpty)
                                Padding(
                                  padding: _isEditing
                                      ? const EdgeInsets.fromLTRB(12, 0, 12, 8)
                                      : const EdgeInsets.only(bottom: 8.0),
                                  child: ReasoningDisplay(
                                    content: message.reasoningContent!,
                                    isWindows: PlatformUtils.isDesktop,
                                    isRunning: widget.isGenerating,
                                    duration: message.reasoningDurationSeconds,
                                    startTime: message.timestamp,
                                  ),
                                ),
                              if (_isEditing)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      key: ValueKey(
                                          'edit_container_${widget.message.id}'),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CallbackShortcuts(
                                            bindings: {
                                              const SingleActivator(
                                                  LogicalKeyboardKey.keyV,
                                                  control: true): _handlePaste,
                                            },
                                            child: Focus(
                                              onKeyEvent: (node, event) {
                                                if (event is! KeyDownEvent) {
                                                  return KeyEventResult.ignored;
                                                }
                                                if (event.logicalKey ==
                                                    LogicalKeyboardKey.enter) {
                                                  if (HardwareKeyboard
                                                      .instance.isShiftPressed) {
                                                    // Shift+Enter: Insert newline
                                                    return KeyEventResult
                                                        .ignored;
                                                  } else {
                                                    // Enter: Save edit (and regenerate if user)
                                                    _saveEdit();
                                                    if (widget.message.isUser) {
                                                        ref.read(historyChatProvider).regenerateResponse(widget.message.id);
                                                    }
                                                    return KeyEventResult
                                                        .handled;
                                                  }
                                                }
                                                return KeyEventResult.ignored;
                                              },
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: fluent.TextBox(
                                                    key: ValueKey(
                                                        'edit_box_${widget.message.id}'),
                                                    controller: _editController,
                                                    scrollController:
                                                        _editScrollController,
                                                    focusNode: _focusNode,
                                                    maxLines: 15,
                                                    minLines: 1,
                                                    placeholder: '编辑消息...',
                                                    decoration: const fluent
                                                        .WidgetStatePropertyAll(
                                                        fluent.BoxDecoration(
                                                      color: Colors.transparent,
                                                      border: Border.fromBorderSide(
                                                          BorderSide.none),
                                                    )),
                                                    highlightColor:
                                                        fluent.Colors.transparent,
                                                    unfocusedColor:
                                                        fluent.Colors.transparent,
                                                    foregroundDecoration: const fluent
                                                        .WidgetStatePropertyAll(
                                                        fluent.BoxDecoration(
                                                      border: Border.fromBorderSide(
                                                          BorderSide.none),
                                                    )),
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        height: 1.5,
                                                        color: theme
                                                            .typography.body?.color),
                                                    cursorColor: theme.accentColor,
                                                    textInputAction:
                                                        TextInputAction.send,
                                                    // onSubmitted removed as we handle it in Focus manually now for finer control
                                                  // onSubmitted: (_) => _saveEdit(), 
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_newAttachments.isNotEmpty)
                                            Container(
                                              height: 40,
                                              margin:
                                                  const EdgeInsets.only(top: 8),
                                              child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount:
                                                    _newAttachments.length,
                                                itemBuilder: (context, index) =>
                                                    Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8),
                                                  child: _buildFileAttachmentPill(
                                                    _newAttachments[index],
                                                    theme,
                                                    onDelete: () => setState(
                                                        () => _newAttachments
                                                            .removeAt(index)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        fluent.IconButton(
                                          icon: const Icon(
                                              AuroraIcons.attach,
                                              size: 14),
                                          onPressed: _pickFiles,
                                          style: fluent.ButtonStyle(
                                            foregroundColor:
                                                fluent.ButtonState.resolveWith(
                                                    (states) {
                                              if (states.isHovered)
                                                return fluent.Colors.blue;
                                              return fluent.Colors.grey;
                                            }),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ActionButton(
                                            icon: AuroraIcons.cancel,
                                            tooltip: AppLocalizations.of(context)?.cancel ?? 'Cancel',
                                            onPressed: () => setState(
                                                () => _isEditing = false)),
                                        const SizedBox(width: 4),
                                        ActionButton(
                                            icon: AuroraIcons.save,
                                            tooltip: AppLocalizations.of(context)?.save ?? 'Save',
                                            onPressed: _saveEdit),
                                        if (message.isUser) ...[
                                          const SizedBox(width: 4),
                                          ActionButton(
                                              icon: AuroraIcons.send,
                                              tooltip: 'Send & Regenerate',
                                              onPressed: () async {
                                                await _saveEdit();
                                                ref
                                                    .read(historyChatProvider)
                                                    .regenerateResponse(
                                                        message.id);
                                              }),
                                        ],
                                      ],
                                    ),
                                  ],
                                )
                              else if (message.role == 'tool')
                                BuildToolOutput(content: message.content)
                              else if (isUser)
                                SelectableText(
                                  message.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: theme.typography.body!.color,
                                  ),
                                  selectionControls: fluent.fluentTextSelectionControls,
                                )
                              else
                                fluent.FluentTheme(
                                  data: theme,
                                  child: AnimatedStreamingMarkdown(
                                    data: message.content,
                                    isDark: theme.brightness == Brightness.dark,
                                    textColor: theme.typography.body!.color!,
                                  ),
                                ),
                               if (message.attachments.isNotEmpty &&
                                   !_isEditing) ...[
                                 const SizedBox(height: 8),
                                 Wrap(
                                   spacing: 8,
                                   runSpacing: 8,
                                   children: message.attachments.map((path) {
                                     final ext = path.toLowerCase();
                                     final isImage = ext.endsWith('.png') ||
                                         ext.endsWith('.jpg') ||
                                         ext.endsWith('.jpeg') ||
                                         ext.endsWith('.webp') ||
                                         ext.endsWith('.gif');
                                     if (isImage) {
                                       return ChatImageBubble(
                                         key: ValueKey(path.hashCode),
                                         imageUrl: path,
                                       );
                                     }
                                     return _buildFileAttachmentPill(path, theme);
                                   }).toList(),
                                 ),
                               ],
                               if (message.images.isNotEmpty &&
                                   !(isUser && _isEditing)) ...[
                                 const SizedBox(height: 8),
                                 Wrap(
                                   spacing: 8,
                                   runSpacing: 8,
                                   children: message.images
                                       .map((img) => ChatImageBubble(
                                             key: ValueKey(img.hashCode),
                                             imageUrl: img,
                                           ))
                                       .toList(),
                                 ),
                             ],
                             if (message.tokenCount != null && message.tokenCount! > 0 || message.durationMs != null)
                                 Padding(
                                   padding: const EdgeInsets.only(top: 4.0),
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     mainAxisAlignment: MainAxisAlignment.end,
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
                                               color: theme.typography.body?.color?.withOpacity(0.5),
                                             ),
                                           );
                                         }),
                                       ],
                                       if (message.firstTokenMs != null && message.firstTokenMs! > 0) ...[
                                         Text(
                                           ' | ',
                                           style: TextStyle(
                                             fontSize: 10,
                                             color: theme.typography.body?.color?.withOpacity(0.5),
                                           ),
                                         ),
                                         Text(
                                           '${AppLocalizations.of(context)?.averageFirstToken((message.firstTokenMs! / 1000).toStringAsFixed(2)) ?? 'TTFT: ${(message.firstTokenMs! / 1000).toStringAsFixed(2)}s'}',
                                           style: TextStyle(
                                             fontSize: 10,
                                             color: theme.typography.body?.color?.withOpacity(0.5),
                                           ),
                                         ),
                                       ],
                                       if (message.durationMs != null && message.durationMs! > 0) ...[
                                         Text(
                                           ' | ',
                                           style: TextStyle(
                                             fontSize: 10,
                                             color: theme.typography.body?.color?.withOpacity(0.5),
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
                                             '${tps.toStringAsFixed(2)} T/s',
                                             style: TextStyle(
                                               fontSize: 10,
                                               color: theme.typography.body?.color?.withOpacity(0.5),
                                             ),
                                           );
                                         }),
                                       ],
                                       Text(
                                         ' | ',
                                         style: TextStyle(
                                           fontSize: 10,
                                           color: theme.typography.body?.color?.withOpacity(0.5),
                                         ),
                                       ),
                                       Text(
                                         '${message.timestamp.month}/${message.timestamp.day} ${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                         style: TextStyle(
                                           fontSize: 10,
                                           color: theme.typography.body?.color?.withOpacity(0.5),
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                             ],
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 if (isUser) ...[
                   const SizedBox(width: 8),
                   _buildAvatar(
                     avatarPath: settingsState.userAvatar,
                     fallbackIcon: AuroraIcons.person,
                     backgroundColor: Colors.blue,
                   ),
                 ],
               ],
             ),
            PlatformUtils.isDesktop
                ? Visibility(
                    visible: !_isEditing,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 4,
                          left: isUser ? 0 : 40,
                          right: isUser ? 40 : 0),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          ActionButton(
                              icon: AuroraIcons.retry,
                              tooltip: 'Retry',
                              onPressed: () => _handleAction('retry')),
                          const SizedBox(width: 4),
                          ActionButton(
                              icon: AuroraIcons.edit,
                              tooltip: 'Edit',
                              onPressed: () => _handleAction('edit')),
                          const SizedBox(width: 4),
                          ActionButton(
                              icon: AuroraIcons.copy,
                              tooltip: 'Copy',
                              onPressed: () => _handleAction('copy')),
                          if (!isUser) ...[
                            const SizedBox(width: 4),
                            ActionButton(
                                icon: AuroraIcons.branch,
                                tooltip: AppLocalizations.of(context)?.branch ?? 'Branch',
                                onPressed: () => _handleAction('branch')),
                          ],
                          const SizedBox(width: 4),
                          ActionButton(
                              icon: AuroraIcons.delete,
                              tooltip: 'Delete',
                              onPressed: () => _handleAction('delete')),
                        ],
                      ),
                    ),
                  )
                : _isEditing
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsets.only(
                            top: 4,
                            left: isUser ? 0 : 40,
                            right: isUser ? 40 : 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            MobileActionButton(
                              icon: AuroraIcons.retry,
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
                            if (!isUser)
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
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileAttachmentPill(String path, fluent.FluentThemeData theme,
      {VoidCallback? onDelete}) {
    final pathLower = path.toLowerCase();
    IconData iconData = AuroraIcons.file;
    if (pathLower.endsWith('.mp3') ||
        pathLower.endsWith('.wav') ||
        pathLower.endsWith('.m4a') ||
        pathLower.endsWith('.flac') ||
        pathLower.endsWith('.ogg') ||
        pathLower.endsWith('.opus')) {
      iconData = AuroraIcons.audio;
    } else if (pathLower.endsWith('.mp4') ||
        pathLower.endsWith('.mov') ||
        pathLower.endsWith('.avi') ||
        pathLower.endsWith('.webm') ||
        pathLower.endsWith('.mkv')) {
      iconData = AuroraIcons.video;
    } else if (pathLower.endsWith('.pdf')) {
      iconData = AuroraIcons.pdf;
    }

    return HoverAttachmentPreview(
      filePath: path,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.accentColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 14, color: theme.accentColor),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    path.split(Platform.pathSeparator).last,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  Icon(AuroraIcons.close,
                      size: 8, color: theme.accentColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String? avatarPath,
    required IconData fallbackIcon,
    required Color backgroundColor,
  }) {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 32,
          height: 32,
          child: Image.file(
            File(avatarPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CircleAvatar(
              radius: 16,
              backgroundColor: backgroundColor,
              child: Icon(fallbackIcon, size: 16, color: Colors.white),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: backgroundColor,
      child: Icon(fallbackIcon, size: 16, color: Colors.white),
    );
  }
}
