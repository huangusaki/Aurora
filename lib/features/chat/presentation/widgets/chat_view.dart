import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';
import '../chat_provider.dart';
import '../../domain/message.dart';
import 'reasoning_display.dart';
import 'chat_image_bubble.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../history/presentation/widgets/hover_image_preview.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});
  @override
  ConsumerState<ChatView> createState() => ChatViewState();
}

class ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _controller = TextEditingController();
  List<String> _attachments = [];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: <String>['jpg', 'png', 'jpeg', 'bmp', 'gif'],
    );
    final List<XFile> files =
        await openFiles(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (files.isEmpty) return;
    setState(() {
      _attachments.addAll(files.map((e) => e.path));
    });
  }

  Future<void> _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    final reader = await clipboard.read();
    
    if (!reader.canProvide(Formats.png) &&
        !reader.canProvide(Formats.jpeg) &&
        !reader.canProvide(Formats.fileUri)) {
      // Retry logic
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        final newReader = await clipboard.read();
        if (newReader.canProvide(Formats.png) ||
            newReader.canProvide(Formats.jpeg) ||
            newReader.canProvide(Formats.fileUri)) {
          await _processReader(newReader);
          return;
        }
      }
      // Pasteboard fallback
      try {
        final imageBytes = await Pasteboard.image;
        if (imageBytes != null && imageBytes.isNotEmpty) {
          final tempDir = await getTemporaryDirectory();
          final path =
              '${tempDir.path}${Platform.pathSeparator}paste_fb_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(path).writeAsBytes(imageBytes);
          if (mounted) {
            setState(() {
              _attachments.add(path);
            });
          }
          return;
        }
      } catch (e) {
        debugPrint('Pasteboard fallback failed: $e');
      }
    } else {
      await _processReader(reader);
      return;
    }
  }

  Future<void> _processReader(ClipboardReader reader) async {
    if (reader.canProvide(Formats.png)) {
      final completer = Completer<String?>();
      reader.getFile(Formats.png, (file) async {
        try {
          final tempDir = await getTemporaryDirectory();
          final path =
              '${tempDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.png';
          final stream = file.getStream();
          final bytes = await stream.toList();
          final allBytes = bytes.expand((x) => x).toList();
          if (allBytes.isNotEmpty) {
            await File(path).writeAsBytes(allBytes);
            completer.complete(path);
          } else {
            completer.complete(null);
          }
        } catch (e) {
          completer.complete(null);
        }
      });
      final imagePath = await completer.future;
      if (imagePath != null && mounted) {
        setState(() {
          _attachments.add(imagePath);
        });
        return;
      }
    } 
    
    // JPEG handling
    if (reader.canProvide(Formats.jpeg)) {
      final completer = Completer<String?>();
      reader.getFile(Formats.jpeg, (file) async {
        try {
          final tempDir = await getTemporaryDirectory();
          final path =
              '${tempDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final stream = file.getStream();
          final bytes = await stream.toList();
          final allBytes = bytes.expand((x) => x).toList();
          if (allBytes.isNotEmpty) {
            await File(path).writeAsBytes(allBytes);
            completer.complete(path);
          } else {
            completer.complete(null);
          }
        } catch (e) {
          completer.complete(null);
        }
      });
      final imagePath = await completer.future;
      if (imagePath != null && mounted) {
        setState(() {
          _attachments.add(imagePath);
        });
        return;
      }
    }

    if (reader.canProvide(Formats.fileUri)) {
      final uri = await reader.readValue(Formats.fileUri);
      if (uri != null) {
        final path = uri.toFilePath();
        if (path.toLowerCase().endsWith('.png') ||
            path.toLowerCase().endsWith('.jpg') ||
            path.toLowerCase().endsWith('.jpeg') ||
            path.toLowerCase().endsWith('.webp')) {
          setState(() {
            _attachments.add(path);
          });
          return;
        }
      }
    }
    if (reader.canProvide(Formats.htmlText)) {
      try {
        final html = await reader.readValue(Formats.htmlText);
        if (html != null) {
          final RegExp imgRegex =
              RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false);
          final match = imgRegex.firstMatch(html);
          if (match != null) {
            String src = match.group(1) ?? '';
            if (src.startsWith('file:///')) {
              Uri fileUri = Uri.parse(src);
              String filePath = fileUri.toFilePath();
              if (File(filePath).existsSync()) {
                setState(() {
                  _attachments.add(filePath);
                });
                return;
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
        final selection = _controller.selection;
        final currentText = _controller.text;
        String newText;
        int newSelectionIndex;
        if (selection.isValid && selection.start >= 0) {
          newText =
              currentText.replaceRange(selection.start, selection.end, text);
          newSelectionIndex = selection.start + text.length;
        } else {
          newText = currentText + text;
          newSelectionIndex = newText.length;
        }
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newSelectionIndex),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.trim().isEmpty && _attachments.isEmpty) return;
    final currentSessionId = ref.read(selectedHistorySessionIdProvider);
    final finalSessionId = await ref
        .read(historyChatProvider.notifier)
        .sendMessage(text, attachments: List.from(_attachments));
    _controller.clear();
    setState(() {
      _attachments.clear();
    });
    if (currentSessionId == 'new_chat' && finalSessionId != 'new_chat') {
      ref.read(selectedHistorySessionIdProvider.notifier).state =
          finalSessionId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(historyChatProvider);
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: ListView.builder(
              key: ValueKey(ref.watch(selectedHistorySessionIdProvider)),
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                final isLast = index == chatState.messages.length - 1;
                return MessageBubble(
                    key: ValueKey(msg.id), message: msg, isLast: isLast);
              },
            ),
          ),
        ),
        if (_attachments.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final path = _attachments[index];
                return HoverImagePreview(
                  imagePath: path,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: fluent.FluentTheme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: fluent.FluentTheme.of(context)
                              .resources
                              .dividerStrokeColorDefault),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 14),
                        const SizedBox(width: 4),
                        Text(path.split(Platform.pathSeparator).last,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _attachments.removeAt(index)),
                          child: const Icon(Icons.close, size: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        Container(
          padding: EdgeInsets.all(Platform.isWindows ? 12 : 8),
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: fluent.FluentTheme.of(context)
                        .resources
                        .dividerStrokeColorDefault)),
            color: Platform.isWindows
                ? fluent.FluentTheme.of(context).cardColor
                : Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Platform.isWindows
              ? _buildDesktopInputArea(chatState)
              : _buildMobileInputArea(chatState),
        ),
      ],
    );
  }

  Widget _buildDesktopInputArea(ChatState chatState) {
    return Column(
      children: [
        Focus(
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final isControl = HardwareKeyboard.instance.isControlPressed;
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            if ((isControl && event.logicalKey == LogicalKeyboardKey.keyV) ||
                (isShift && event.logicalKey == LogicalKeyboardKey.insert)) {
              _handlePaste();
              return KeyEventResult.handled;
            }
            if (isControl && event.logicalKey == LogicalKeyboardKey.enter) {
              _sendMessage();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: fluent.TextBox(
            controller: _controller,
            placeholder: '输入消息 (Enter 换行，Ctrl + Enter 发送)',
            maxLines: 3,
            minLines: 1,
            decoration:
                const fluent.WidgetStatePropertyAll(fluent.BoxDecoration()),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            fluent.IconButton(
              icon: const fluent.Icon(fluent.FluentIcons.attach),
              onPressed: _pickFiles,
            ),
            const SizedBox(width: 8),
            fluent.IconButton(
              icon: const fluent.Icon(fluent.FluentIcons.add),
              onPressed: () {
                ref.read(selectedHistorySessionIdProvider.notifier).state =
                    'new_chat';
              },
            ),
            const SizedBox(width: 8),
            fluent.IconButton(
              icon: const fluent.Icon(fluent.FluentIcons.paste),
              onPressed: _handlePaste,
            ),
            const SizedBox(width: 8),
            fluent.IconButton(
              icon: const fluent.Icon(fluent.FluentIcons.broom),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => fluent.ContentDialog(
                    title: const Text('清空上下文'),
                    content: const Text('确定要清空当前对话的历史记录吗？此操作不可撤销。'),
                    actions: [
                      fluent.Button(
                        child: const Text('取消'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      fluent.FilledButton(
                        child: const Text('确定'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(historyChatProvider.notifier).clearContext();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            if (chatState.isLoading)
              const fluent.ProgressRing(
                  strokeWidth: 2, activeColor: Colors.blue)
            else
              fluent.IconButton(
                icon: const fluent.Icon(fluent.FluentIcons.send),
                onPressed: _sendMessage,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileInputArea(ChatState chatState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, size: 22),
              onPressed: _pickFiles,
              tooltip: '添加附件',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 22),
              onPressed: () {
                ref.read(selectedHistorySessionIdProvider.notifier).state =
                    'new_chat';
              },
              tooltip: '新对话',
            ),
            IconButton(
              icon: const Icon(Icons.cleaning_services_outlined, size: 22),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('清空上下文'),
                    content: const Text('确定要清空当前对话的历史记录吗？此操作不可撤销。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(historyChatProvider.notifier).clearContext();
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: '清空上下文',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 16),
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            const SizedBox(width: 8),
            chatState.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: Icon(Icons.send,
                        color: Theme.of(context).colorScheme.primary),
                    iconSize: 26,
                    onPressed: _sendMessage,
                    padding: const EdgeInsets.all(8),
                  ),
          ],
        ),
      ],
    );
  }
}

class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isLast;
  const MessageBubble(
      {super.key, required this.message, required this.isLast});
  @override
  ConsumerState<MessageBubble> createState() =>
      MessageBubbleState();
}

class MessageBubbleState extends ConsumerState<MessageBubble> {
  bool _isHovering = false;
  bool _isEditing = false;
  late TextEditingController _editController;
  final FocusNode _focusNode = FocusNode();
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

  Future<void> _pickFiles() async {
    const typeGroup = XTypeGroup(
        label: 'images', extensions: ['jpg', 'png', 'jpeg', 'bmp', 'gif']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return;
    setState(() {
      _newAttachments.addAll(files.map((file) => file.path));
    });
  }

  Future<void> _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    final reader = await clipboard.read();
    if (reader.canProvide(Formats.png) ||
        reader.canProvide(Formats.jpeg) ||
        reader.canProvide(Formats.fileUri)) {
      _processReader(reader);
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
            selection:
                TextSelection.collapsed(offset: selection.start + text.length),
          );
        } else {
          _editController.text += text;
        }
      }
      return;
    }
    // Pasteboard fallback
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}${Platform.pathSeparator}paste_fb_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(path).writeAsBytes(imageBytes);
        if (mounted) {
          setState(() {
            _newAttachments.add(path);
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Pasteboard Fallback Error: $e');
    }
  }

  Future<void> _processReader(ClipboardReader reader) async {
    if (reader.canProvide(Formats.png)) {
      reader.getFile(Formats.png, (file) => _saveClipImage(file));
    } else if (reader.canProvide(Formats.jpeg)) {
      reader.getFile(Formats.jpeg, (file) => _saveClipImage(file));
    }
  }

  Future<void> _saveClipImage(file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.png';
      final stream = file.getStream();
      final List<int> bytes = [];
      await for (final chunk in stream) {
        bytes.addAll(chunk as List<int>);
      }
      if (bytes.isNotEmpty) {
        await File(path).writeAsBytes(bytes);
        if (mounted) {
          setState(() {
            _newAttachments.add(path);
          });
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
    super.dispose();
  }

  void _handleAction(String action) {
    final msg = widget.message;
    final notifier = ref.read(historyChatProvider.notifier);
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
    }
  }

  void _saveEdit() {
    if (_editController.text.trim().isNotEmpty) {
      ref.read(historyChatProvider.notifier).editMessage(
          widget.message.id, _editController.text,
          newAttachments: _newAttachments);
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isUser = message.isUser;
    final settingsState = ref.watch(settingsProvider);
    final theme = fluent.FluentTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
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
                  _buildAvatar(
                    avatarPath: settingsState.llmAvatar,
                    fallbackIcon: Icons.smart_toy,
                    backgroundColor: Colors.teal,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isUser
                                  ? (settingsState.userName.isNotEmpty
                                      ? settingsState.userName
                                      : '用户')
                                  : '${message.model ?? settingsState.selectedModel} | ${message.provider ?? settingsState.activeProvider?.name ?? 'AI'}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              '${message.timestamp.month}/${message.timestamp.day} ${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
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
                                  color: theme.resources.dividerStrokeColorDefault),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!message.isUser &&
                                message.reasoningContent != null &&
                                message.reasoningContent!.isNotEmpty)
                              Padding(
                                padding: _isEditing
                                    ? const EdgeInsets.fromLTRB(12, 0, 12, 8)
                                    : const EdgeInsets.only(bottom: 8.0),
                                child: ReasoningDisplay(
                                  content: message.reasoningContent!,
                                  isWindows: true,
                                  isRunning: false,
                                ),
                              ),
                            if (_isEditing)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                          color: theme.resources
                                              .dividerStrokeColorDefault),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_newAttachments.isNotEmpty)
                                          Container(
                                            height: 40,
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: _newAttachments.length,
                                              itemBuilder: (context, index) =>
                                                  Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8),
                                                child: MouseRegion(
                                                  cursor:
                                                      SystemMouseCursors.click,
                                                  child: GestureDetector(
                                                    onTap: () => setState(() =>
                                                        _newAttachments
                                                            .removeAt(index)),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: theme.accentColor
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                            color: theme
                                                                .accentColor
                                                                .withOpacity(
                                                                    0.3)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          ConstrainedBox(
                                                            constraints:
                                                                const BoxConstraints(
                                                                    maxWidth:
                                                                        100),
                                                            child: Text(
                                                              _newAttachments[
                                                                      index]
                                                                  .split(Platform
                                                                      .pathSeparator)
                                                                  .last,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          12),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Icon(
                                                              fluent.FluentIcons
                                                                  .chrome_close,
                                                              size: 8,
                                                              color: theme
                                                                  .accentColor),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        CallbackShortcuts(
                                          bindings: {
                                            const SingleActivator(
                                                LogicalKeyboardKey.keyV,
                                                control: true): _handlePaste,
                                          },
                                          child: fluent.TextBox(
                                            controller: _editController,
                                            focusNode: _focusNode,
                                            maxLines: null,
                                            minLines: 1,
                                            placeholder: '编辑消息...',
                                            decoration: null,
                                            highlightColor:
                                                fluent.Colors.transparent,
                                            unfocusedColor:
                                                fluent.Colors.transparent,
                                            style: TextStyle(
                                                fontSize: 14,
                                                height: 1.5,
                                                color: theme
                                                    .typography.body?.color),
                                            cursorColor: theme.accentColor,
                                            textInputAction:
                                                TextInputAction.send,
                                            onSubmitted: (_) => _saveEdit(),
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
                                            fluent.FluentIcons.attach,
                                            size: 14),
                                        onPressed: _pickFiles,
                                        style: fluent.ButtonStyle(
                                          foregroundColor:
                                              fluent.ButtonState.resolveWith(
                                                  (states) {
                                            if (states.isHovering)
                                              return fluent.Colors.blue;
                                            return fluent.Colors.grey;
                                          }),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ActionButton(
                                          icon: fluent.FluentIcons.cancel,
                                          tooltip: 'Cancel',
                                          onPressed: () => setState(
                                              () => _isEditing = false)),
                                      const SizedBox(width: 4),
                                      ActionButton(
                                          icon: fluent.FluentIcons.save,
                                          tooltip: 'Save',
                                          onPressed: _saveEdit),
                                      if (message.isUser) ...[
                                        const SizedBox(width: 4),
                                        ActionButton(
                                            icon: fluent.FluentIcons.send,
                                            tooltip: 'Send & Regenerate',
                                            onPressed: () {
                                              _saveEdit();
                                              ref
                                                  .read(historyChatProvider
                                                      .notifier)
                                                  .regenerateResponse(
                                                      message.id);
                                            }),
                                      ],
                                    ],
                                  ),
                                ],
                              )
                            else
                              fluent.FluentTheme(
                                data: theme,
                                child: SelectionArea(
                                  child: MarkdownBody(
                                    data: message.content,
                                    selectable: false,
                                    styleSheet: MarkdownStyleSheet(
                                      p: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: theme.typography.body!.color,
                                      ),
                                      code: TextStyle(
                                        backgroundColor: theme.micaBackgroundColor,
                                        color: theme.typography.body!.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (message.images.isNotEmpty &&
                                !(isUser && _isEditing)) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: message.images
                                    .map((img) => ChatImageBubble(
                                          imageUrl: img,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 8),
                  _buildAvatar(
                    avatarPath: settingsState.userAvatar,
                    fallbackIcon: Icons.person,
                    backgroundColor: Colors.blue,
                  ),
                ],
              ],
            ),
            Platform.isWindows
                ? Visibility(
                    visible: _isHovering && !_isEditing,
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
                      ),
          ],
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

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const ActionButton(
      {super.key, required this.icon, required this.tooltip, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return fluent.Tooltip(
      message: tooltip,
      child: fluent.IconButton(
        icon: fluent.Icon(icon, size: 14),
        onPressed: onPressed,
      ),
    );
  }
}

class MobileActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const MobileActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: Colors.grey[600]),
        onPressed: onPressed,
      ),
    );
  }
}
