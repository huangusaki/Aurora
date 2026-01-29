import 'dart:async';
import 'dart:io';


import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';

import 'package:super_clipboard/super_clipboard.dart';

import 'package:pasteboard/pasteboard.dart';
import 'package:image_picker/image_picker.dart';
import '../chat_provider.dart';



import '../../../settings/presentation/settings_provider.dart';
import '../../../history/presentation/widgets/hover_image_preview.dart';

import 'components/chat_utils.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

import 'components/message_bubble.dart';
import 'components/merged_message_bubble.dart';
import 'components/chat_input_area.dart';
import 'components/chat_attachment_menu.dart';

class ChatView extends ConsumerStatefulWidget {
  final String sessionId;
  const ChatView({super.key, required this.sessionId});
  @override
  ConsumerState<ChatView> createState() => ChatViewState();
}

class ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _controller = TextEditingController();
  late final ScrollController _scrollController;
  List<String> _attachments = [];
  String get _sessionId => widget.sessionId;
  bool _toastVisible = false;
  String _toastMessage = '';
  IconData? _toastIcon;
  Timer? _toastTimer;
  void _showPillToast(String message, IconData icon) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIcon = icon;
      _toastVisible = true;
    });
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  Widget _buildPillToastWidget() {
    final theme = fluent.FluentTheme.of(context);
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_toastVisible,
        child: Center(
          child: AnimatedOpacity(
            opacity: _toastVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.resources.dividerStrokeColorDefault,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_toastIcon != null) ...[
                    Icon(_toastIcon,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    _toastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.typography.body?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        if (!_attachments.contains(image.path)) {
          setState(() {
            _attachments.add(image.path);
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  bool _hasRestoredPosition = false;
  bool _wasLoading = false;
  ChatNotifier? _notifier;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier = ref.read(chatSessionManagerProvider).getOrCreate(_sessionId);
      _notifier!.addLocalListener(_onNotifierStateChanged);
    });
  }

  void _onNotifierStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _restoreScrollPosition() {
    final notifier =
        ref.read(chatSessionManagerProvider).getOrCreate(_sessionId);
    final state = notifier.currentState;
    if (_hasRestoredPosition || state.messages.isEmpty) return;
    _hasRestoredPosition = true;
    final savedOffset = notifier.savedScrollOffset;
    final isAutoScroll = state.isAutoScrollEnabled;
    if (savedOffset != null || isAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          if (savedOffset != null && savedOffset > 100) {
            _scrollController.jumpTo(savedOffset);
          } else if (isAutoScroll) {
            _scrollController.jumpTo(0);
          } else if (savedOffset != null) {
            _scrollController.jumpTo(savedOffset);
          }
        }
      });
    }
  }

  void _onScroll() {
    if (!_hasRestoredPosition) return;
    if (!_scrollController.hasClients) return;
    final currentScroll = _scrollController.position.pixels;
    final autoScroll = currentScroll < 100;
    ref
        .read(chatSessionManagerProvider)
        .getOrCreate(_sessionId)
        .setAutoScrollEnabled(autoScroll);
  }

  @override
  void dispose() {
    _notifier?.removeLocalListener(_onNotifierStateChanged);
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
    final newPaths = files
        .map((e) => e.path)
        .where((path) => !_attachments.contains(path))
        .toList();
    if (newPaths.isNotEmpty) {
      setState(() {
        _attachments.addAll(newPaths);
      });
    }
  }

  Future<void> _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    final reader = await clipboard.read();
    if (!reader.canProvide(Formats.png) &&
        !reader.canProvide(Formats.jpeg) &&
        !reader.canProvide(Formats.fileUri) &&
        !reader.canProvide(Formats.plainText)) {
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
      try {
        final imageBytes = await Pasteboard.image;
        if (imageBytes != null && imageBytes.isNotEmpty) {
          final attachDir = await getAttachmentsDir();
          final path =
              '${attachDir.path}${Platform.pathSeparator}paste_fb_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(path).writeAsBytes(imageBytes);
          if (mounted) {
            if (!_attachments.contains(path)) {
              setState(() {
                _attachments.add(path);
              });
            }
          }
          return;
        }
      } catch (e) {
        debugPrint('Pasteboard fallback failed: $e');
      }
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
          final attachDir = await getAttachmentsDir();
          final path =
              '${attachDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.png';
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
        if (!_attachments.contains(imagePath)) {
          setState(() {
            _attachments.add(imagePath);
          });
        }
        return;
      }
    }
    if (reader.canProvide(Formats.jpeg)) {
      final completer = Completer<String?>();
      reader.getFile(Formats.jpeg, (file) async {
        try {
          final attachDir = await getAttachmentsDir();
          final path =
              '${attachDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
        if (!_attachments.contains(imagePath)) {
          setState(() {
            _attachments.add(imagePath);
          });
        }
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
          if (!_attachments.contains(path)) {
            setState(() {
              _attachments.add(path);
            });
          }
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
                if (!_attachments.contains(filePath)) {
                  setState(() {
                    _attachments.add(filePath);
                  });
                }
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
    if (text.trim().isEmpty && _attachments.isEmpty) {
      return;
    }
    final currentSessionId = ref.read(selectedHistorySessionIdProvider);
    final attachmentsCopy = List<String>.from(_attachments);
    setState(() {
      _controller.clear();
      _attachments.clear();
    });
    ref.read(historyChatProvider).setAutoScrollEnabled(true);
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
    if (!mounted) return;
    if (currentSessionId == 'new_chat' && finalSessionId != 'new_chat') {
      ref.read(selectedHistorySessionIdProvider.notifier).state =
          finalSessionId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier =
        ref.read(chatSessionManagerProvider).getOrCreate(_sessionId);
    final chatState = notifier.currentState;
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;
    final hasUnreadResponse = chatState.hasUnreadResponse;
    final isLoadingHistory = chatState.isLoadingHistory;
    final settings = ref.watch(settingsProvider);
    _restoreScrollPosition();
    if (isLoading && !_wasLoading && chatState.isAutoScrollEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _wasLoading = isLoading;
    if (hasUnreadResponse) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.markAsRead();
      });
    }
    if (isLoadingHistory && messages.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                      PlatformUtils.isDesktop ? 12 : 0,
                      PlatformUtils.isDesktop ? 0 : 0,
                      PlatformUtils.isDesktop ? 12 : 0,
                      PlatformUtils.isDesktop ? 12 : 0),
                  child: PlatformUtils.isDesktop
                      ? DesktopChatInputArea(
                          controller: _controller,
                          isLoading: isLoading,
                          onSend: _sendMessage,
                          onPickFiles: _pickFiles,
                          onPaste: _handlePaste,
                          onShowToast: _showPillToast,
                        )
                      : MobileChatInputArea(
                          controller: _controller,
                          isLoading: isLoading,
                          onSend: _sendMessage,
                          onAttachmentTap: () => ChatAttachmentMenu.show(
                            context,
                            onPickCamera: () => _pickImage(ImageSource.camera),
                            onPickGallery: () =>
                                _pickImage(ImageSource.gallery),
                            onPickFile: _pickFiles,
                          ),
                          onShowToast: _showPillToast,
                        ),
                ),
              ],
            ),
          ),
          _buildPillToastWidget(),
        ],
      );
    }
    List<DisplayItem> displayItems = [];
    MergedGroupItem? currentGroup;
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (msg.role == 'system') continue;
      if (msg.isUser) {
        if (currentGroup != null) {
          displayItems.add(currentGroup);
          currentGroup = null;
        }
        displayItems.add(SingleMessageItem(msg));
      } else {
        if (currentGroup == null) {
          currentGroup = MergedGroupItem([msg]);
        } else {
          currentGroup.messages.add(msg);
        }
      }
    }
    if (currentGroup != null) {
      displayItems.add(currentGroup);
    }
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
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
                  child: PlatformUtils.isDesktop
                      ? Padding(
                          padding: const EdgeInsets.only(
                              right: 4.0, top: 2.0, bottom: 2.0),
                          child: fluent.Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            style: const fluent.ScrollbarThemeData(
                              thickness: 6,
                              hoveringThickness: 10,
                            ),
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(scrollbars: false),
                              child: ListView.builder(
                                cacheExtent: 20000,
                                key: ValueKey(ref
                                    .watch(selectedHistorySessionIdProvider)),
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.all(16),
                                itemCount: displayItems.length,
                                itemBuilder: (context, index) {
                                  final reversedIndex =
                                      displayItems.length - 1 - index;
                                  final item = displayItems[reversedIndex];
                                  final isLatest = index == 0;
                                  final isGenerating = isLatest && isLoading;
                                  if (item is MergedGroupItem) {
                                    return MergedMessageBubble(
                                      key: ValueKey(item.id),
                                      group: item,
                                      isLast: isLatest,
                                      isGenerating: isGenerating,
                                    );
                                  } else if (item is SingleMessageItem) {
                                    final msg = item.message;
                                    bool mergeTop = false;
                                    if (reversedIndex > 0) {
                                      final prevItem =
                                          displayItems[reversedIndex - 1];
                                      if (prevItem is SingleMessageItem &&
                                          prevItem.message.isUser) {
                                        mergeTop = true;
                                      }
                                    }
                                    bool mergeBottom = false;
                                    if (reversedIndex <
                                        displayItems.length - 1) {
                                      final nextItem =
                                          displayItems[reversedIndex + 1];
                                      if (nextItem is SingleMessageItem &&
                                          nextItem.message.isUser) {
                                        mergeBottom = true;
                                      }
                                    }
                                    bool showAvatar = !mergeTop;
                                    final bubble = MessageBubble(
                                        key: ValueKey(msg.id),
                                        message: msg,
                                        isLast: isLatest,
                                        isGenerating: false,
                                        showAvatar: showAvatar,
                                        mergeTop: mergeTop,
                                        mergeBottom: mergeBottom);
                                    if (isLatest) {
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset:
                                                  Offset(0, 20 * (1 - value)),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: bubble,
                                      );
                                    }
                                    return bubble;
                                  }
                                  return const SizedBox.shrink();
                                },
                                physics: const ClampingScrollPhysics(),
                              ),
                            ),
                          ),
                        )
                      : CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics()),
                          reverse: true,
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                verticalDirection: VerticalDirection.up,
                                children: [
                                  for (int index = 0;
                                      index < displayItems.length;
                                      index++)
                                    Builder(builder: (context) {
                                      final reversedIndex =
                                          displayItems.length - 1 - index;
                                      final item =
                                          displayItems[reversedIndex];
                                      final isLatest = index == 0;
                                      final isGenerating =
                                          isLatest && isLoading;
                                      if (item is MergedGroupItem) {
                                        final bubble = MergedMessageBubble(
                                          key: ValueKey(item.id),
                                          group: item,
                                          isLast: isLatest,
                                          isGenerating: isGenerating,
                                        );
                                        if (isLatest) {
                                          return TweenAnimationBuilder<
                                              double>(
                                            key: ValueKey(item.id),
                                            tween:
                                                Tween(begin: 0.0, end: 1.0),
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, value, child) {
                                              return Opacity(
                                                opacity: value,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                      0, 20 * (1 - value)),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: bubble,
                                          );
                                        }
                                        return bubble;
                                      } else if (item is SingleMessageItem) {
                                        final msg = item.message;
                                        bool mergeTop = false;
                                        if (reversedIndex > 0) {
                                          final prevItem =
                                              displayItems[reversedIndex - 1];
                                          if (prevItem is SingleMessageItem &&
                                              prevItem.message.isUser)
                                            mergeTop = true;
                                        }
                                        bool mergeBottom = false;
                                        if (reversedIndex <
                                            displayItems.length - 1) {
                                          final nextItem =
                                              displayItems[reversedIndex + 1];
                                          if (nextItem is SingleMessageItem &&
                                              nextItem.message.isUser)
                                            mergeBottom = true;
                                        }
                                        bool showAvatar = !mergeTop;
                                        final bubble = MessageBubble(
                                          key: ValueKey(msg.id),
                                          message: msg,
                                          isLast: isLatest,
                                          isGenerating: false,
                                          showAvatar: showAvatar,
                                          mergeTop: mergeTop,
                                          mergeBottom: mergeBottom,
                                        );
                                        if (isLatest) {
                                          return TweenAnimationBuilder<
                                              double>(
                                            key: ValueKey(msg.id),
                                            tween:
                                                Tween(begin: 0.0, end: 1.0),
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, value, child) {
                                              return Opacity(
                                                opacity: value,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                      0, 20 * (1 - value)),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: bubble,
                                          );
                                        }
                                        return bubble;
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              // Always render attachments container to prevent widget tree structure change
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: _attachments.isNotEmpty ? 60 : 0,
                child: _attachments.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListView.builder(
                          primary: false, // Prevent ListView from stealing focus
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachments.length,
                          itemBuilder: (context, index) {
                            final path = _attachments[index];
                            return HoverImagePreview(
                              imagePath: path,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      fluent.FluentTheme.of(context).cardColor,
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
                                      onTap: () => setState(
                                          () => _attachments.removeAt(index)),
                                      child: const Icon(Icons.close, size: 14),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : null,
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                    PlatformUtils.isDesktop ? 12 : 0,
                    PlatformUtils.isDesktop ? 0 : 0,
                    PlatformUtils.isDesktop ? 12 : 0,
                    PlatformUtils.isDesktop ? 12 : 0),
                child: PlatformUtils.isDesktop
                    ? DesktopChatInputArea(
                        key: const ValueKey('desktop_chat_input'), // Preserve State across rebuilds
                        controller: _controller,
                        isLoading: isLoading,
                        onSend: _sendMessage,
                        onPickFiles: _pickFiles,
                        onPaste: _handlePaste,
                        onShowToast: _showPillToast,
                      )
                    : MobileChatInputArea(
                        controller: _controller,
                        isLoading: isLoading,
                        onSend: _sendMessage,
                        onAttachmentTap: () => ChatAttachmentMenu.show(
                          context,
                          onPickCamera: () => _pickImage(ImageSource.camera),
                          onPickGallery: () => _pickImage(ImageSource.gallery),
                          onPickFile: _pickFiles,
                        ),
                        onShowToast: _showPillToast,
                      ),
              ),
            ],
          ),
        ),
        _buildPillToastWidget(),
      ],
    );
  }
}
