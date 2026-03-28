import 'dart:async';
import 'dart:io';

import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../chat_provider.dart';
import '../../../domain/chat_message_transformers.dart';
import '../../../domain/message.dart';
import '../../../domain/message_transformer.dart';
import '../../../domain/ui_message.dart';
import '../../../../settings/presentation/settings_provider.dart';
import 'attachment_aware_paste_action.dart';
import 'chat_attachment_pill.dart';
import 'chat_message_assembler.dart';
import 'chat_message_avatar.dart';
import 'chat_message_content_renderer.dart';
import 'chat_message_frame.dart';
import 'chat_utils.dart';

class MessageBubble extends ConsumerStatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isLast,
    this.isGenerating = false,
    this.animateStreamingContent = true,
    this.showAvatar = true,
    this.mergeTop = false,
    this.mergeBottom = false,
  });

  final Message message;
  final bool isLast;
  final bool isGenerating;
  final bool animateStreamingContent;
  final bool showAvatar;
  final bool mergeTop;
  final bool mergeBottom;

  @override
  ConsumerState<MessageBubble> createState() => MessageBubbleState();
}

class MessageBubbleState extends ConsumerState<MessageBubble>
    with AutomaticKeepAliveClientMixin {
  bool _isEditing = false;
  bool _isPasting = false;
  late TextEditingController _editController;
  late List<String> _newAttachments;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _editScrollController = ScrollController();

  @override
  bool get wantKeepAlive =>
      _isEditing ||
      widget.message.attachments.isNotEmpty ||
      widget.message.images.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
    _newAttachments = List<String>.from(widget.message.attachments);
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content) {
      _editController.text = widget.message.content;
    }
    if (oldWidget.message.attachments != widget.message.attachments &&
        !_isEditing) {
      _newAttachments = List<String>.from(widget.message.attachments);
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    _editScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final typeGroup = XTypeGroup(
      label: AppLocalizations.of(context)!.images,
      extensions: const ['jpg', 'png', 'jpeg', 'bmp', 'gif'],
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return;
    final newPaths = files
        .map((file) => file.path)
        .where((path) => !_newAttachments.contains(path))
        .toList();
    if (newPaths.isEmpty) return;
    setState(() => _newAttachments.addAll(newPaths));
  }

  Future<bool> _handlePaste() async {
    if (_isPasting) return false;
    _isPasting = true;
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return false;

      const maxAttempts = 10;
      for (int attempt = 0; attempt < maxAttempts; attempt += 1) {
        ClipboardReader reader;
        try {
          reader = await clipboard.read();
        } catch (e) {
          if (attempt == maxAttempts - 1) {
            debugPrint('Failed to read clipboard: $e');
            return false;
          }
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        bool handled = false;
        try {
          handled = await _processReader(reader);
        } catch (e) {
          debugPrint('Failed to process clipboard: $e');
        }
        if (handled) return true;
        if (attempt < maxAttempts - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      return false;
    } finally {
      _isPasting = false;
    }
  }

  Future<bool> _pastePlainTextFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return false;
    }

    final selection = _editController.selection;
    final currentText = _editController.text;
    late final String newText;
    late final int newSelectionIndex;

    if (selection.isValid && selection.start >= 0) {
      newText = currentText.replaceRange(selection.start, selection.end, text);
      newSelectionIndex = selection.start + text.length;
    } else {
      newText = currentText + text;
      newSelectionIndex = newText.length;
    }

    _editController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
    return true;
  }

  Future<String?> _saveClipboardFileAsAttachment(
    ClipboardReader reader,
    FileFormat format,
    String extension,
  ) async {
    final completer = Completer<String?>();
    reader.getFile(format, (file) async {
      try {
        final attachDir = await getAttachmentsDir();
        final path =
            '${attachDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final stream = file.getStream();
        final bytes = <int>[];
        await for (final chunk in stream) {
          bytes.addAll(chunk);
        }
        if (bytes.isEmpty) {
          completer.complete(null);
          return;
        }
        await File(path).writeAsBytes(bytes);
        completer.complete(path);
      } catch (_) {
        completer.complete(null);
      }
    });

    try {
      return await completer.future.timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  Future<bool> _processReader(ClipboardReader reader) async {
    if (reader.canProvide(Formats.png)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.png, 'png');
      if (imagePath != null && mounted) {
        if (!_newAttachments.contains(imagePath)) {
          setState(() => _newAttachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.jpeg)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.jpeg, 'jpg');
      if (imagePath != null && mounted) {
        if (!_newAttachments.contains(imagePath)) {
          setState(() => _newAttachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.gif)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.gif, 'gif');
      if (imagePath != null && mounted) {
        if (!_newAttachments.contains(imagePath)) {
          setState(() => _newAttachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.webp)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.webp, 'webp');
      if (imagePath != null && mounted) {
        if (!_newAttachments.contains(imagePath)) {
          setState(() => _newAttachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.bmp)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.bmp, 'bmp');
      if (imagePath != null && mounted) {
        if (!_newAttachments.contains(imagePath)) {
          setState(() => _newAttachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.tiff)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.tiff, 'tiff');
      if (imagePath != null && mounted) {
        if (!_newAttachments.contains(imagePath)) {
          setState(() => _newAttachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.fileUri)) {
      final uri = await reader.readValue(Formats.fileUri);
      if (uri != null) {
        final path = uri.toFilePath();
        final ext = path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tif', 'tiff']
            .contains(ext)) {
          if (!_newAttachments.contains(path) && mounted) {
            setState(() => _newAttachments.add(path));
          }
          return true;
        }
      }
    }
    if (reader.canProvide(Formats.htmlText)) {
      try {
        final html = await reader.readValue(Formats.htmlText);
        if (html != null) {
          final match = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false)
              .firstMatch(html);
          if (match != null) {
            final src = match.group(1) ?? '';
            if (src.startsWith('file:///')) {
              final filePath = Uri.parse(src).toFilePath();
              if (File(filePath).existsSync()) {
                if (!_newAttachments.contains(filePath) && mounted) {
                  setState(() => _newAttachments.add(filePath));
                }
                return true;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing HTML clipboard: $e');
      }
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
            selection:
                TextSelection.collapsed(offset: selection.start + text.length),
          );
        } else {
          _editController.text += text;
        }
        return true;
      }
    }
    return false;
  }

  void _handleAction(String action) async {
    final message = widget.message;
    final notifier = ref.read(historyChatProvider);
    switch (action) {
      case 'retry':
        notifier.regenerateResponse(message.id);
        break;
      case 'edit':
        setState(() => _isEditing = true);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _focusNode.requestFocus());
        break;
      case 'copy':
        final settingsState = ref.read(settingsProvider);
        final transformContext = MessageTransformContext(
          language: settingsState.language,
          model: message.model ?? settingsState.selectedModel,
          providerName: message.provider ?? settingsState.activeProvider.name,
        );
        final transformed = chatMessageTransformers.visualTransform(
          UiMessage.fromLegacy(message),
          transformContext,
        );
        await Clipboard.setData(ClipboardData(text: transformed.text));
        break;
      case 'delete':
        notifier.deleteMessage(message.id);
        break;
      case 'branch':
        final sessionId = ref.read(selectedHistorySessionIdProvider);
        if (sessionId == null) break;
        final sessions = ref.read(sessionsProvider).sessions;
        final session =
            sessions.where((item) => item.sessionId == sessionId).firstOrNull;
        if (session == null) break;
        final branchSuffix = AppLocalizations.of(context)!.branch;
        final newSessionId =
            await ref.read(sessionsProvider.notifier).createBranchSession(
                  originalSessionId: sessionId,
                  originalTitle: session.title,
                  upToMessageId: message.id,
                  branchSuffix: '-$branchSuffix',
                );
        if (newSessionId != null) {
          ref.read(selectedHistorySessionIdProvider.notifier).state =
              newSessionId;
        }
        break;
    }
  }

  Future<void> _saveEdit() async {
    if (_editController.text.trim().isNotEmpty) {
      await ref.read(historyChatProvider).editMessage(
            widget.message.id,
            _editController.text,
            newAttachments: _newAttachments,
          );
    }
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final message = widget.message;
    final isUser = message.isUser;
    final settingsState = ref.watch(settingsProvider);
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final transformContext = MessageTransformContext(
      language: settingsState.language,
      model: message.model ?? settingsState.selectedModel,
      providerName: message.provider ?? settingsState.activeProvider.name,
    );
    final renderData = ChatMessageAssembler.assembleSingle(
      message: message,
      transformContext: transformContext,
      isGenerating: widget.isGenerating,
      animateStreamingContent: widget.animateStreamingContent,
      loadingLabel: '${l10n.thinking}...',
    );
    final headerTextColor = (settingsState.useCustomTheme &&
            settingsState.backgroundImagePath != null &&
            settingsState.backgroundImagePath!.isNotEmpty)
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.grey[600];
    final mobileActionColor = (settingsState.useCustomTheme &&
            settingsState.backgroundImagePath != null &&
            settingsState.backgroundImagePath!.isNotEmpty)
        ? Colors.white.withValues(alpha: 0.7)
        : null;

    return ChatMessageFrame(
      isUser: isUser,
      settingsState: settingsState,
      theme: theme,
      isEditing: _isEditing,
      reserveLeadingAvatarSpace: !isUser && !widget.showAvatar,
      margin: EdgeInsets.only(
        top: widget.mergeTop ? 2 : 8,
        bottom: widget.mergeBottom ? 2 : 16,
        left: 10,
        right: 10,
      ),
      header: widget.showAvatar
          ? Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
              child: Text(
                isUser
                    ? (settingsState.userName.isNotEmpty
                        ? settingsState.userName
                        : l10n.user)
                    : '${message.model ?? settingsState.selectedModel} | ${message.provider ?? settingsState.activeProvider.name}',
                style: TextStyle(
                  color: headerTextColor,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      leadingAvatar: !isUser && widget.showAvatar
          ? ChatMessageAvatar(
              avatarPath: settingsState.llmAvatar,
              fallbackIcon: AuroraIcons.robot,
              backgroundColor: Colors.teal,
            )
          : null,
      trailingAvatar: isUser
          ? ChatMessageAvatar(
              avatarPath: settingsState.userAvatar,
              fallbackIcon: AuroraIcons.person,
              backgroundColor: Colors.blue,
            )
          : null,
      body: _isEditing
          ? _MessageEditPanel(
              message: message,
              editController: _editController,
              editScrollController: _editScrollController,
              focusNode: _focusNode,
              attachments: _newAttachments,
              onDeleteAttachment: (index) =>
                  setState(() => _newAttachments.removeAt(index)),
              onPickFiles: _pickFiles,
              onSave: _saveEdit,
              onCancel: () => setState(() => _isEditing = false),
              onSaveAndRegenerate: () async {
                await _saveEdit();
                ref.read(historyChatProvider).regenerateResponse(message.id);
              },
              onCustomPaste: _handlePaste,
              onFallbackPaste: _pastePlainTextFromClipboard,
            )
          : ChatMessageContentRenderer(
              blocks: renderData.blocks,
              theme: theme,
            ),
      desktopActionItems: [
        ActionButton(
          icon: AuroraIcons.retry,
          tooltip: l10n.retry,
          onPressed: () => _handleAction('retry'),
        ),
        ActionButton(
          icon: AuroraIcons.edit,
          tooltip: l10n.edit,
          onPressed: () => _handleAction('edit'),
        ),
        ActionButton(
          icon: AuroraIcons.copy,
          tooltip: l10n.copy,
          onPressed: () => _handleAction('copy'),
        ),
        if (!isUser)
          ActionButton(
            icon: AuroraIcons.branch,
            tooltip: l10n.branch,
            onPressed: () => _handleAction('branch'),
          ),
        ActionButton(
          icon: AuroraIcons.delete,
          tooltip: l10n.delete,
          onPressed: () => _handleAction('delete'),
        ),
      ],
      mobileActionItems: [
        MobileActionButton(
          icon: AuroraIcons.retry,
          color: mobileActionColor,
          onPressed: () => _handleAction('retry'),
        ),
        MobileActionButton(
          icon: AuroraIcons.edit,
          color: mobileActionColor,
          onPressed: () => _handleAction('edit'),
        ),
        MobileActionButton(
          icon: AuroraIcons.copy,
          color: mobileActionColor,
          onPressed: () => _handleAction('copy'),
        ),
        if (!isUser)
          MobileActionButton(
            icon: AuroraIcons.branch,
            color: mobileActionColor,
            onPressed: () => _handleAction('branch'),
          ),
        MobileActionButton(
          icon: AuroraIcons.delete,
          color: mobileActionColor,
          onPressed: () => _handleAction('delete'),
        ),
      ],
      showDesktopActions: !_isEditing,
      showMobileActions: !_isEditing,
      maintainDesktopActionSpace: true,
    );
  }
}

class _MessageEditPanel extends StatelessWidget {
  const _MessageEditPanel({
    required this.message,
    required this.editController,
    required this.editScrollController,
    required this.focusNode,
    required this.attachments,
    required this.onDeleteAttachment,
    required this.onPickFiles,
    required this.onSave,
    required this.onCancel,
    required this.onSaveAndRegenerate,
    required this.onCustomPaste,
    required this.onFallbackPaste,
  });

  final Message message;
  final TextEditingController editController;
  final ScrollController editScrollController;
  final FocusNode focusNode;
  final List<String> attachments;
  final ValueChanged<int> onDeleteAttachment;
  final VoidCallback onPickFiles;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;
  final Future<void> Function() onSaveAndRegenerate;
  final Future<bool> Function() onCustomPaste;
  final Future<bool> Function() onFallbackPaste;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          key: ValueKey('edit_container_${message.id}'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shortcuts(
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(LogicalKeyboardKey.keyV, control: true):
                      PasteTextIntent(SelectionChangedCause.keyboard),
                  SingleActivator(LogicalKeyboardKey.insert, shift: true):
                      PasteTextIntent(SelectionChangedCause.keyboard),
                  SingleActivator(LogicalKeyboardKey.paste):
                      PasteTextIntent(SelectionChangedCause.keyboard),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    PasteTextIntent: AttachmentAwarePasteAction(
                      onCustomPaste: onCustomPaste,
                      onFallbackPaste: onFallbackPaste,
                      onAfterPaste: focusNode.requestFocus,
                    ),
                  },
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) {
                        return KeyEventResult.ignored;
                      }
                      if (event.logicalKey != LogicalKeyboardKey.enter) {
                        return KeyEventResult.ignored;
                      }
                      if (HardwareKeyboard.instance.isShiftPressed) {
                        return KeyEventResult.ignored;
                      }
                      if (message.isUser) {
                        unawaited(onSaveAndRegenerate());
                      } else {
                        unawaited(onSave());
                      }
                      return KeyEventResult.handled;
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: fluent.TextBox(
                        key: ValueKey('edit_box_${message.id}'),
                        controller: editController,
                        scrollController: editScrollController,
                        focusNode: focusNode,
                        maxLines: 15,
                        minLines: 1,
                        placeholder: l10n.editMessagePlaceholder,
                        decoration: const fluent.WidgetStatePropertyAll(
                          fluent.BoxDecoration(
                            color: Colors.transparent,
                            border: Border.fromBorderSide(BorderSide.none),
                          ),
                        ),
                        highlightColor: fluent.Colors.transparent,
                        unfocusedColor: fluent.Colors.transparent,
                        foregroundDecoration:
                            const fluent.WidgetStatePropertyAll(
                          fluent.BoxDecoration(
                            border: Border.fromBorderSide(BorderSide.none),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: theme.typography.body?.color,
                        ),
                        cursorColor: theme.accentColor,
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                ),
              ),
              if (attachments.isNotEmpty)
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: attachments.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChatAttachmentPill(
                        path: attachments[index],
                        theme: theme,
                        onDelete: () => onDeleteAttachment(index),
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
              icon: const Icon(AuroraIcons.attach, size: 14),
              onPressed: onPickFiles,
              style: fluent.ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.isHovered
                      ? fluent.Colors.blue
                      : fluent.Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ActionButton(
              icon: AuroraIcons.cancel,
              tooltip: l10n.cancel,
              onPressed: onCancel,
            ),
            const SizedBox(width: 4),
            ActionButton(
              icon: AuroraIcons.save,
              tooltip: l10n.save,
              onPressed: () => unawaited(onSave()),
            ),
            if (message.isUser) ...[
              const SizedBox(width: 4),
              ActionButton(
                icon: AuroraIcons.send,
                tooltip: l10n.sendAndRegenerate,
                onPressed: () => unawaited(onSaveAndRegenerate()),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
