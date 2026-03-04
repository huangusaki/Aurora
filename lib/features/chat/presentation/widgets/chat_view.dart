import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:aurora/l10n/app_localizations.dart';

import 'package:super_clipboard/super_clipboard.dart';
import 'package:image_picker/image_picker.dart';
import '../chat_provider.dart';

import '../../../history/presentation/widgets/hover_image_preview.dart';

import 'components/chat_utils.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';

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
  final List<String> _attachments = [];
  String get _sessionId => widget.sessionId;

  void _showPillToast(String message, IconData icon) {
    showAuroraNotice(
      context,
      message,
      icon: icon,
      top: PlatformUtils.isDesktop
          ? 60
          : MediaQuery.of(context).padding.top + 64 + 60,
    );
  }

  Future<List<String>> _saveFilesToAppDir(List<XFile> files) async {
    final savedPaths = <String>[];
    try {
      final attachDir = await getAttachmentsDir();
      for (final file in files) {
        try {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '')}';
          final newPath = '${attachDir.path}${Platform.pathSeparator}$fileName';
          await file.saveTo(newPath);
          savedPaths.add(newPath);
        } catch (e) {
          debugPrint('Failed to save file ${file.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error accessing attachment directory: $e');
    }
    return savedPaths;
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        final saved = await _saveFilesToAppDir([image]);
        if (saved.isNotEmpty && !_attachments.contains(saved.first)) {
          setState(() {
            _attachments.add(saved.first);
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(source: source);
      if (video != null) {
        final saved = await _saveFilesToAppDir([video]);
        if (saved.isNotEmpty && !_attachments.contains(saved.first)) {
          setState(() {
            _attachments.add(saved.first);
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  bool _hasRestoredPosition = false;
  bool _wasLoading = false;

  // Used to keep the visible content stable while a response is streaming in a
  // reversed ListView (where new content grows from the bottom).
  double? _prevMaxScrollExtent;
  double? _prevScrollPixels;

  ChatNotifier? _notifier;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onNotifierStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _restoreScrollPosition() {
    final notifier = _notifier!;
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
    _notifier!.setAutoScrollEnabled(autoScroll);

    // Keep baselines fresh in case the user scrolls while generation is idle.
    _prevMaxScrollExtent = _scrollController.position.maxScrollExtent;
    _prevScrollPixels = currentScroll;
  }

  void _scheduleScrollPositionCompensation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      final prevMax = _prevMaxScrollExtent;
      final prevPixels = _prevScrollPixels;
      if (prevMax == null || prevPixels == null) return;

      final pos = _scrollController.position;
      final deltaMax = pos.maxScrollExtent - prevMax;
      if (deltaMax.abs() < 0.5) return;

      final target =
          (prevPixels + deltaMax).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if ((target - pos.pixels).abs() < 0.5) return;
      _scrollController.jumpTo(target);
    });
  }

  void _scheduleScrollMetricsCapture() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      _prevMaxScrollExtent = _scrollController.position.maxScrollExtent;
      _prevScrollPixels = _scrollController.position.pixels;
    });
  }

  @override
  void dispose() {
    _notifier?.removeLocalListener(_onNotifierStateChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final typeGroup = XTypeGroup(
      label: AppLocalizations.of(context)!.selectFile,
      extensions: <String>[
        // Images
        'jpg', 'png', 'jpeg', 'bmp', 'gif', 'webp',
        // Audio
        'mp3', 'wav', 'm4a', 'flac', 'ogg', 'opus',
        // Video
        'mp4', 'mov', 'avi', 'webm', 'mkv',
        // Documents
        'pdf', 'doc', 'docx', 'txt', 'md', 'csv', 'xlsx', 'pptx'
      ],
    );
    final List<XFile> files =
        await openFiles(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (files.isEmpty) return;

    final savedPaths = await _saveFilesToAppDir(files);
    final newPaths =
        savedPaths.where((path) => !_attachments.contains(path)).toList();

    if (newPaths.isNotEmpty) {
      setState(() {
        _attachments.addAll(newPaths);
      });
    }
  }

  Future<void> _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    const maxAttempts = 10;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      ClipboardReader reader;
      try {
        reader = await clipboard.read();
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          debugPrint('Failed to read clipboard: $e');
          return;
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

      if (handled) return;
      if (attempt < maxAttempts - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
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
        if (!_attachments.contains(imagePath)) {
          setState(() => _attachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.jpeg)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.jpeg, 'jpg');
      if (imagePath != null && mounted) {
        if (!_attachments.contains(imagePath)) {
          setState(() => _attachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.gif)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.gif, 'gif');
      if (imagePath != null && mounted) {
        if (!_attachments.contains(imagePath)) {
          setState(() => _attachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.webp)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.webp, 'webp');
      if (imagePath != null && mounted) {
        if (!_attachments.contains(imagePath)) {
          setState(() => _attachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.bmp)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.bmp, 'bmp');
      if (imagePath != null && mounted) {
        if (!_attachments.contains(imagePath)) {
          setState(() => _attachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.tiff)) {
      final imagePath =
          await _saveClipboardFileAsAttachment(reader, Formats.tiff, 'tiff');
      if (imagePath != null && mounted) {
        if (!_attachments.contains(imagePath)) {
          setState(() => _attachments.add(imagePath));
        }
        return true;
      }
    }
    if (reader.canProvide(Formats.fileUri)) {
      final uri = await reader.readValue(Formats.fileUri);
      if (uri != null) {
        final path = uri.toFilePath();
        final lower = path.toLowerCase();
        if (lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.gif') ||
            lower.endsWith('.bmp') ||
            lower.endsWith('.tif') ||
            lower.endsWith('.tiff')) {
          if (mounted) {
            if (!_attachments.contains(path)) {
              setState(() => _attachments.add(path));
            }
            return true;
          }
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
                if (mounted) {
                  if (!_attachments.contains(filePath)) {
                    setState(() => _attachments.add(filePath));
                  }
                  return true;
                }
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
        return true;
      }
    }
    return false;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.trim().isEmpty && _attachments.isEmpty) {
      return;
    }
    final attachmentsCopy = List<String>.from(_attachments);
    setState(() {
      _controller.clear();
      _attachments.clear();
    });
    ref
        .read(chatSessionManagerProvider)
        .getOrCreate(_sessionId)
        .setAutoScrollEnabled(true);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    final effectiveSessionId = widget.sessionId;

    // Always get the freshest notifier for sending to avoid using disposed instances
    final activeNotifier =
        ref.read(chatSessionNotifierProvider(effectiveSessionId));
    if (!activeNotifier.mounted) return;

    final finalSessionId =
        await activeNotifier.sendMessage(text, attachments: attachmentsCopy);

    if (!mounted) return;
    if (effectiveSessionId == 'new_chat' && finalSessionId != 'new_chat') {
      ref.read(selectedHistorySessionIdProvider.notifier).state =
          finalSessionId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(chatSessionNotifierProvider(widget.sessionId));
    if (_notifier != notifier) {
      _notifier?.removeLocalListener(_onNotifierStateChanged);
      _notifier = notifier;
      _notifier!.addLocalListener(_onNotifierStateChanged);
    }
    final keepChatScrollPositionOnResponse = ref.watch(
      settingsProvider
          .select((value) => value.keepChatScrollPositionOnResponse),
    );
    final chatState = notifier.currentState;
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;
    final hasUnreadResponse = chatState.hasUnreadResponse;
    final isLoadingHistory = chatState.isLoadingHistory;
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

    // When the list is reversed, new content grows from the bottom (offset=0).
    // If the user is reading older content (auto-scroll off), keep the viewport
    // stable while streaming/generating.
    if (keepChatScrollPositionOnResponse &&
        _hasRestoredPosition &&
        isLoading &&
        !chatState.isAutoScrollEnabled) {
      _scheduleScrollPositionCompensation();
    }
    _scheduleScrollMetricsCapture();

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
                            onPickVideo: () => _pickVideo(ImageSource.gallery),
                            onPickFile: _pickFiles,
                          ),
                          onShowToast: _showPillToast,
                        ),
                ),
              ],
            ),
          ),
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
        if (displayItems.isEmpty && !isLoadingHistory)
          Positioned.fill(
            child: Container(
              padding:
                  EdgeInsets.only(bottom: PlatformUtils.isDesktop ? 120 : 100),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.greetingMessage,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: fluent.FluentTheme.of(context)
                                .typography
                                .body
                                ?.color
                                ?.withValues(alpha: 0.5) ??
                            Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification) {
                      if (_scrollController.hasClients) {
                        ref
                            .read(chatSessionManagerProvider)
                            .getOrCreate(_sessionId)
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
                      : ListView.builder(
                          key: ValueKey(
                              ref.watch(selectedHistorySessionIdProvider)),
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
                              final bubble = MergedMessageBubble(
                                key: ValueKey(item.id),
                                group: item,
                                isLast: isLatest,
                                isGenerating: isGenerating,
                              );
                              if (isLatest) {
                                return TweenAnimationBuilder<double>(
                                  key: ValueKey(item.id),
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
                                    prevItem.message.isUser) {
                                  mergeTop = true;
                                }
                              }
                              bool mergeBottom = false;
                              if (reversedIndex < displayItems.length - 1) {
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
                                mergeBottom: mergeBottom,
                              );
                              if (isLatest) {
                                return TweenAnimationBuilder<double>(
                                  key: ValueKey(msg.id),
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
                                  child: bubble,
                                );
                              }
                              return bubble;
                            }
                            return const SizedBox.shrink();
                          },
                          physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics()),
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
                          primary:
                              false, // Prevent ListView from stealing focus
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachments.length,
                          itemBuilder: (context, index) {
                            final path = _attachments[index];
                            return HoverAttachmentPreview(
                              filePath: path,
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
                                    Text(
                                        path.split(Platform.pathSeparator).last,
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
                        key: const ValueKey(
                            'desktop_chat_input'), // Preserve State across rebuilds
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
                          onPickVideo: () => _pickVideo(ImageSource.gallery),
                          onPickFile: _pickFiles,
                        ),
                        onShowToast: _showPillToast,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
