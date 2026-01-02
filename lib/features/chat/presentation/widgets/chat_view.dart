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
  late final ScrollController _scrollController;
  List<String> _attachments = [];
  String? _sessionId;
  bool _hasRestoredPosition = false;
  
  @override
  void initState() {
    super.initState();
    _sessionId = ref.read(selectedHistorySessionIdProvider);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _restoreScrollPosition() {
    final state = ref.read(historyChatProvider).currentState;
    if (_hasRestoredPosition || state.messages.isEmpty) return;
    
    // If we have messages and haven't restored yet
    _hasRestoredPosition = true;
    
    final savedOffset = ref.read(historyChatProvider).savedScrollOffset;
    final isAutoScroll = state.isAutoScrollEnabled;
    
    if (savedOffset != null || isAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // Prioritize saved offset if user was significantly scrolled up (> 100px),
          // ignoring stale auto-scroll flag to prevent unwanted jumps.
          if (savedOffset != null && savedOffset > 100) {
            _scrollController.jumpTo(savedOffset);
          } else if (isAutoScroll) {
            _scrollController.jumpTo(0); // 0 is bottom
          } else if (savedOffset != null) {
            _scrollController.jumpTo(savedOffset);
          }
        }
      });
    }
  }
  
  void _onScroll() {
    // Do not update state if we haven't restored position (or initial load)
    // or if the list is effectively empty
    if (!_hasRestoredPosition) return;
    if (!_scrollController.hasClients) return;
    
    // In reverse mode, offset 0 is bottom
    final currentScroll = _scrollController.position.pixels;
    
    // Re-enable auto-scroll if close to bottom (0)
    final autoScroll = currentScroll < 100;
      
    // Update state via notifier
    if (_sessionId != null) {
      ref.read(historyChatProvider).setAutoScrollEnabled(autoScroll);
    }
  }
  

  
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
      // Retry logic for images
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
      // Pasteboard fallback for images
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
      // No image found, try to handle as text
      await _processReader(reader);
    } else {
      await _processReader(reader);
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
    
    // Capture attachments before clearing
    final attachmentsCopy = List<String>.from(_attachments);
    
    // Clear input immediately before async operation
    setState(() {
      _controller.clear();
      _attachments.clear();
    });
    
    // Enable auto-scroll when sending message
    ref.read(historyChatProvider).setAutoScrollEnabled(true);
    
    // Explicitly scroll to bottom (0)
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    
    final finalSessionId = await ref
        .read(historyChatProvider)
        .sendMessage(text, attachments: attachmentsCopy);
    if (!mounted) return; // Widget disposed during async operation
    if (currentSessionId == 'new_chat' && finalSessionId != 'new_chat') {
      ref.read(selectedHistorySessionIdProvider.notifier).state =
          finalSessionId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(historyChatStateProvider);
    final settings = ref.watch(settingsProvider);
    
    // Attempt to restore scroll position if needed
    _restoreScrollPosition();
    

    
    // Mark as read if displaying unread content
    if (chatState.hasUnreadResponse) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(historyChatProvider).markAsRead();
      });
    }
    
    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                if (_sessionId != null && _scrollController.hasClients) {
                  ref
                      .read(chatSessionManagerProvider)
                      .getOrCreate(_sessionId!)
                      .saveScrollOffset(_scrollController.offset);
                }
              }
              return false;
            },
            child: Platform.isWindows
                ? Padding(
                    padding: const EdgeInsets.only(right: 4.0, top: 2.0, bottom: 2.0),
                    child: fluent.Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      style: const fluent.ScrollbarThemeData(
                        thickness: 6,
                        hoveringThickness: 10,
                      ),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                        child: ListView.builder(
                          cacheExtent: 2000,
                          key: ValueKey(ref.watch(selectedHistorySessionIdProvider)),
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: chatState.messages.length,
                          itemBuilder: (context, index) {
                            final reversedIndex = chatState.messages.length - 1 - index;
                            final msg = chatState.messages[reversedIndex];
                            final isLatest = index == 0;
                            final isGenerating = isLatest && !msg.isUser && chatState.isLoading;

                            if (index == 0) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: RepaintBoundary(
                                  child: MessageBubble(
                                      key: ValueKey(msg.id),
                                      message: msg,
                                      isLast: isLatest,
                                      isGenerating: isGenerating),
                                ),
                              );
                            } else {
                              return RepaintBoundary(
                                child: MessageBubble(
                                    key: ValueKey(msg.id),
                                    message: msg,
                                    isLast: isLatest,
                                    isGenerating: isGenerating),
                              );
                            }
                          },
                          physics: const ClampingScrollPhysics(),
                        ),
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    child: ListView.builder(
                      cacheExtent: 2000,
                      key: ValueKey(ref.watch(selectedHistorySessionIdProvider)),
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final reversedIndex = chatState.messages.length - 1 - index;
                        final msg = chatState.messages[reversedIndex];
                        final isLatest = index == 0;
                        final isGenerating = isLatest && !msg.isUser && chatState.isLoading;

                        if (index == 0) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: RepaintBoundary(
                              child: MessageBubble(
                                  key: ValueKey(msg.id),
                                  message: msg,
                                  isLast: isLatest,
                                  isGenerating: isGenerating),
                            ),
                          );
                        } else {
                          return RepaintBoundary(
                            child: MessageBubble(
                                key: ValueKey(msg.id),
                                message: msg,
                                isLast: isLatest,
                                isGenerating: isGenerating),
                          );
                        }
                      },
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                    ),
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
          padding: EdgeInsets.fromLTRB(
            Platform.isWindows ? 12 : 0, 
            Platform.isWindows ? 0 : 0,  // Top: 0 on Windows (gap reduction)
            Platform.isWindows ? 12 : 0, 
            Platform.isWindows ? 12 : 0// Mobile padding handled by margin
          ),

          child: Platform.isWindows
              ? _buildDesktopInputArea(chatState, settings)
              : _buildMobileInputArea(chatState, settings),
        ),
      ],
    );
  }

  OverlayEntry? _streamToastEntry;

  void _showStreamToast(bool isEnabled) {
    if (Platform.isWindows) {
      // Remove existing toast immediately to prevent stacking/overlap
      _streamToastEntry?.remove();
      _streamToastEntry = null;

      final entry = OverlayEntry(
        builder: (context) {
          return Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _StreamToastWidget(
              isEnabled: isEnabled,
              onClose: () {
                _streamToastEntry?.remove();
                _streamToastEntry = null;
              },
            ),
          );
        },
      );

      Overlay.of(context).insert(entry);
      _streamToastEntry = entry;
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEnabled ? '已开启流式输出' : '已关闭流式输出'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          width: 200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }
  }

  Widget _buildDesktopInputArea(ChatState chatState, SettingsState settings) {
    final theme = fluent.FluentTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20), // Matches capsule look
        border: Border.all(
          color: theme.resources.dividerStrokeColorDefault,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // Tighter vertical padding
      child: Column(
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
              placeholder: '随便输入点什么吧 (Enter 换行，Ctrl + Enter 发送)',
              maxLines: 5,
              minLines: 1,
              // Completely transparent decoration to avoid "nested box" look
              decoration: const fluent.WidgetStatePropertyAll(fluent.BoxDecoration(
                color: Colors.transparent,
                border: Border.fromBorderSide(BorderSide.none),
              )),
              highlightColor: Colors.transparent,
              unfocusedColor: Colors.transparent,
              cursorColor: theme.accentColor,
              style: const TextStyle(fontSize: 14),
              foregroundDecoration: const fluent.WidgetStatePropertyAll(fluent.BoxDecoration(
                border: Border.fromBorderSide(BorderSide.none),
              )),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.attach, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(theme.resources.textFillColorSecondary),
                ),
                onPressed: _pickFiles,
              ),
              const SizedBox(width: 4),
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.add, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(theme.resources.textFillColorSecondary),
                ),
                onPressed: () {
                  ref.read(selectedHistorySessionIdProvider.notifier).state =
                      'new_chat';
                },
              ),
              const SizedBox(width: 4),
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.paste, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(theme.resources.textFillColorSecondary),
                ),
                onPressed: _handlePaste,
              ),
              
              const Spacer(),
              
              // Feature Toggles (Stream / Clear) - Monochrome, reduced visual noise
              // Feature Toggles (Stream / Clear) - Monochrome, reduced visual noise
              fluent.IconButton(
                icon: Icon(
                  fluent.FluentIcons.lightning_bolt, 
                  size: 16,
                  color: settings.isStreamEnabled 
                      ? theme.accentColor 
                      : theme.resources.textFillColorSecondary,
                ),
                onPressed: () {
                  final newState = !settings.isStreamEnabled;
                  ref.read(settingsProvider.notifier).toggleStreamEnabled();
                  _showStreamToast(newState);
                },
                style: fluent.ButtonStyle(
                  backgroundColor: fluent.WidgetStateProperty.resolveWith((states) {
                     if (settings.isStreamEnabled) return theme.accentColor.withOpacity(0.1);
                     return Colors.transparent;
                  }),
                ),
              ),
              const SizedBox(width: 4),
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.broom, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(theme.resources.textFillColorSecondary),
                ),
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
                            ref.read(historyChatProvider).clearContext();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 8),
              
              if (chatState.isLoading)
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.stop_solid, size: 16, color: Colors.red),
                  onPressed: () => ref.read(historyChatProvider).abortGeneration(),
                )
              else
                fluent.IconButton(
                  icon: Icon(fluent.FluentIcons.send, size: 16, color: theme.accentColor),
                  onPressed: _sendMessage,
                  style: fluent.ButtonStyle(
                    backgroundColor: fluent.WidgetStateProperty.resolveWith((states) {
                       if (states.isHovered || states.isPressed) return theme.accentColor.withOpacity(0.1);
                       return Colors.transparent;
                    }),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInputArea(ChatState chatState, SettingsState settings) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Text Field
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: '随便输入点什么吧',
                hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 16),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(height: 12),
          
          // 2. Action Icons Row
          Row(
            children: [
              // Left Side: Feature Toggles
              
              // Stream Toggle
              InkWell(
                onTap: () {
                  final newState = !settings.isStreamEnabled;
                  ref.read(settingsProvider.notifier).toggleStreamEnabled();
                  _showStreamToast(newState);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    settings.isStreamEnabled ? Icons.bolt : Icons.article_outlined,
                    color: settings.isStreamEnabled 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ),
              
              const SizedBox(width: 4),
              
              // Clear Context
              InkWell(
                onTap: () {
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
                            ref.read(historyChatProvider).clearContext();
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.cleaning_services_outlined,
                    color: Colors.grey,
                    size: 22,
                  ),
                ),
              ),

              const Spacer(),

              // Right Side: Actions
              
              // New Chat (+)
              IconButton(
                icon: const Icon(Icons.add, size: 24, color: Colors.grey),
                onPressed: () {
                  ref.read(selectedHistorySessionIdProvider.notifier).state =
                      'new_chat';
                },
                tooltip: '新对话',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: IconButton(
                    icon: const Icon(Icons.attach_file, size: 22, color: Colors.grey),
                    onPressed: _pickFiles,
                    tooltip: '添加附件',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ),
              
              // Send/Stop Button (Circular)
              Material(
                color: chatState.isLoading 
                    ? Colors.red.withOpacity(0.1) 
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: chatState.isLoading
                      ? () => ref.read(historyChatProvider).abortGeneration()
                      : _sendMessage,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: chatState.isLoading
                        ? const Icon(Icons.stop_rounded, color: Colors.red, size: 24)
                        : const Icon(Icons.arrow_upward, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isLast;
  final bool isGenerating;
  const MessageBubble(
      {super.key, required this.message, required this.isLast, this.isGenerating = false});
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
    }
  }

  void _saveEdit() {
    if (_editController.text.trim().isNotEmpty) {
      ref.read(historyChatProvider).editMessage(
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
      onEnter: (_) => Platform.isWindows ? setState(() => _isHovering = true) : null,
      onExit: (_) => Platform.isWindows ? setState(() => _isHovering = false) : null,
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
                                    color: theme.resources.dividerStrokeColorDefault),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            // Show loading indicator or reasoning content when generating
                            if (!message.isUser && widget.isGenerating && 
                                message.content.isEmpty && 
                                (message.reasoningContent == null || message.reasoningContent!.isEmpty))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Platform.isWindows
                                          ? const fluent.ProgressRing(strokeWidth: 2)
                                          : const CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '思考中...',
                                      style: TextStyle(
                                        color: theme.typography.body?.color?.withOpacity(0.6),
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
                                  isWindows: Platform.isWindows,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      // Removed border to avoid "grey rectangle" look
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
                                          child: fluent.TextBox(
                                            controller: _editController,
                                            focusNode: _focusNode,
                                            maxLines: null,
                                            minLines: 1,
                                            placeholder: '编辑消息...',
                                            decoration: const fluent.WidgetStatePropertyAll(fluent.BoxDecoration(
                                              color: Colors.transparent,
                                              border: Border.fromBorderSide(BorderSide.none),
                                            )),
                                            highlightColor:
                                                fluent.Colors.transparent,
                                            unfocusedColor:
                                                fluent.Colors.transparent,
                                            foregroundDecoration: const fluent.WidgetStatePropertyAll(fluent.BoxDecoration(
                                              border: Border.fromBorderSide(BorderSide.none),
                                            )),
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
                                        if (_newAttachments.isNotEmpty)
                                          Container(
                                            height: 40,
                                            margin: const EdgeInsets.only(
                                                top: 8),
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
                                                  .read(historyChatProvider)
                                                  .regenerateResponse(
                                                      message.id);
                                            }),
                                      ],
                                    ],
                                  ),
                                ],
                              )
                            else if (isUser)
                              SelectableText(
                                message.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: theme.typography.body!.color,
                                ),
                              )
                            else
                              fluent.FluentTheme(
                                data: theme,
                                child: SelectionArea(
                                  child: MarkdownBody(
                                    data: message.content,
                                    selectable: false,
                                    softLineBreak: true,
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
                            // Display attachments for user messages (image files)
                            if (isUser && message.attachments.isNotEmpty && !_isEditing) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: message.attachments
                                    .where((path) {
                                      final ext = path.toLowerCase();
                                      return ext.endsWith('.png') || 
                                             ext.endsWith('.jpg') || 
                                             ext.endsWith('.jpeg') ||
                                             ext.endsWith('.webp') ||
                                             ext.endsWith('.gif');
                                    })
                                    .map((path) => Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(path),
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              const Icon(fluent.FluentIcons.error),
                                        ),
                                      ),
                                    ))
                                    .toList(),
                              ),
                            ],
                            // Display AI-generated images
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


class _StreamToastWidget extends StatefulWidget {
  final bool isEnabled;
  final VoidCallback onClose;

  const _StreamToastWidget({
    required this.isEnabled,
    required this.onClose,
  });

  @override
  State<_StreamToastWidget> createState() => _StreamToastWidgetState();
}

class _StreamToastWidgetState extends State<_StreamToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
        
    _controller.forward();

    // Auto-close countdown (shorter for minimalist feel)
    _closeTimer = Timer(const Duration(milliseconds: 1500), _startClosing);
  }

  void _startClosing() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    // Minimalist Apple-style toast
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.9) 
                  : Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isEnabled ? fluent.FluentIcons.lightning_bolt : fluent.FluentIcons.clear, 
                  size: 14, 
                  color: theme.brightness == Brightness.dark ? Colors.black : Colors.white
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isEnabled ? '流式输出 On' : '流式输出 Off',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
