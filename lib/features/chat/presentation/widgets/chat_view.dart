import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:image_picker/image_picker.dart';
import '../chat_provider.dart';
import '../../domain/message.dart';
import 'reasoning_display.dart';
import 'chat_image_bubble.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../history/presentation/widgets/hover_image_preview.dart';
import 'package:aurora/l10n/app_localizations.dart';

/// Returns a persistent directory for storing user-uploaded attachments.
/// Creates the directory if it doesn't exist.
Future<Directory> getAttachmentsDir() async {
  final appDir = await getApplicationDocumentsDirectory();
  final attachmentsDir = Directory('${appDir.path}${Platform.pathSeparator}Aurora${Platform.pathSeparator}attachments');
  if (!await attachmentsDir.exists()) {
    await attachmentsDir.create(recursive: true);
  }
  return attachmentsDir;
}

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
  
  // Use the widget's sessionId
  String get _sessionId => widget.sessionId;
  
  // Toast State
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
      top: 60, // Top margin
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
                    Icon(_toastIcon, size: 18, color: Theme.of(context).colorScheme.primary),
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


  Future<void> _showMobileAttachmentOptions() async {
    final theme = fluent.FluentTheme.of(context);
    final isDark = theme.brightness == fluent.Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildAttachmentOption(
                icon: Icons.camera_alt_outlined,
                label: AppLocalizations.of(context)!.takePhoto,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImage(ImageSource.camera);
                },
              ),
              _buildAttachmentOption(
                icon: Icons.photo_library_outlined,
                label: AppLocalizations.of(context)!.selectFromGallery,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              _buildAttachmentOption(
                icon: Icons.folder_open_outlined,
                label: AppLocalizations.of(context)!.selectFile,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFiles();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 17)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        // We'll use the path for now, consistent with how desktop file selection works
        // If image.path is empty (web), we'd need readAsBytes. But this is mobile logic.
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
  ChatNotifier? _notifier;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Subscribe to session-specific state changes
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
    final notifier = ref.read(chatSessionManagerProvider).getOrCreate(_sessionId);
    final state = notifier.currentState;
    if (_hasRestoredPosition || state.messages.isEmpty) return;
    
    // If we have messages and haven't restored yet
    _hasRestoredPosition = true;
    
    final savedOffset = notifier.savedScrollOffset;
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
      
    // Update state via notifier (session-specific)
    ref.read(chatSessionManagerProvider).getOrCreate(_sessionId).setAutoScrollEnabled(autoScroll);
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
    
    // JPEG handling
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
    // Get session-specific notifier
    final notifier = ref.read(chatSessionManagerProvider).getOrCreate(_sessionId);
    final chatState = notifier.currentState;
    
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;
    final hasUnreadResponse = chatState.hasUnreadResponse;
    final isLoadingHistory = chatState.isLoadingHistory;
    
    final settings = ref.watch(settingsProvider);
    
    // Attempt to restore scroll position if needed
    _restoreScrollPosition();
    
    // Mark as read if displaying unread content
    if (hasUnreadResponse) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.markAsRead();
      });
    }
    
    // Show loading indicator while history is loading
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
                    Platform.isWindows ? 12 : 0, 
                    Platform.isWindows ? 0 : 0,
                    Platform.isWindows ? 12 : 0, 
                    Platform.isWindows ? 12 : 0
                  ),
                  child: Platform.isWindows
                      ? _buildDesktopInputArea(isLoading, settings)
                      : _buildMobileInputArea(isLoading, settings),
                ),
              ],
            ),
          ),
          _buildPillToastWidget(),
        ],
      );
    }
    
    // --- Grouping Logic Start ---
    List<DisplayItem> displayItems = [];
    MergedGroupItem? currentGroup;

    // messages is [Oldest -> Newest]. Iterate from Oldest to Newest to build groups.
    for (int i = 0; i < messages.length; i++) {
       final msg = messages[i];
       
       if (msg.isUser) {
          // Close valid group if any
          if (currentGroup != null) {
             displayItems.add(currentGroup);
             currentGroup = null;
          }
          displayItems.add(SingleMessageItem(msg));
       } else {
          // Assistant or Tool
          if (currentGroup == null) {
             currentGroup = MergedGroupItem([msg]);
          } else {
             currentGroup.messages.add(msg);
          }
       }
    }
    // Add final group
    if (currentGroup != null) {
       displayItems.add(currentGroup);
    }
    // --- Grouping Logic End ---

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
            child: Platform.isWindows
                ? SelectionArea(
                    child: Padding(
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
                          itemCount: displayItems.length,
                          itemBuilder: (context, index) {
                             // index 0 is BOTTOM (Latest Item)
                             // displayItems is [Oldest, ..., Newest]
                             // So reversedIndex = displayItems.length - 1 - index
                             final reversedIndex = displayItems.length - 1 - index;
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
                                
                                // Merge Logic for Users (User vs User)
                                bool mergeTop = false;
                                if (reversedIndex > 0) {
                                  final prevItem = displayItems[reversedIndex - 1];
                                  if (prevItem is SingleMessageItem && prevItem.message.isUser) {
                                     mergeTop = true;
                                  }
                                }
                                bool mergeBottom = false;
                                if (reversedIndex < displayItems.length - 1) {
                                   final nextItem = displayItems[reversedIndex + 1];
                                   if (nextItem is SingleMessageItem && nextItem.message.isUser) {
                                      mergeBottom = true;
                                   }
                                }
                                
                                bool showAvatar = !mergeTop;

                                final bubble = MessageBubble(
                                    key: ValueKey(msg.id),
                                    message: msg,
                                    isLast: isLatest,
                                    isGenerating: false, // User messages don't generate
                                    showAvatar: showAvatar,
                                    mergeTop: mergeTop,
                                    mergeBottom: mergeBottom
                                );
                                
                                // Animation only for latest?
                                if (isLatest) {
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
                  ),
                )
                : CustomScrollView(
                    controller: _scrollController,
                    reverse: true,
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          verticalDirection: VerticalDirection.up,
                          children: [
                            for (int index = 0; index < displayItems.length; index++)
                              Builder(builder: (context) {
                                final reversedIndex = displayItems.length - 1 - index;
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
                                    final prevItem = displayItems[reversedIndex - 1];
                                    if (prevItem is SingleMessageItem && prevItem.message.isUser) mergeTop = true;
                                  }
                                  bool mergeBottom = false;
                                  if (reversedIndex < displayItems.length - 1) {
                                    final nextItem = displayItems[reversedIndex + 1];
                                    if (nextItem is SingleMessageItem && nextItem.message.isUser) mergeBottom = true;
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
                              }),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
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
              ? _buildDesktopInputArea(isLoading, settings)
              : _buildMobileInputArea(isLoading, settings),
        ),
      ],
            ),
          ),
          _buildPillToastWidget(),
        ],
      );
  }



  Widget _buildDesktopInputArea(bool isLoading, SettingsState settings) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
              placeholder: l10n.desktopInputHint,
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
              const SizedBox(width: 4),

              // Clear Context
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.broom, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(theme.resources.textFillColorSecondary),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => fluent.ContentDialog(
                      title: Text(l10n.clearContext),
                      content: Text(l10n.clearContextConfirm),
                      actions: [
                        fluent.Button(
                          child: Text(l10n.cancel),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        fluent.FilledButton(
                          child: Text(l10n.confirm),
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

              const SizedBox(width: 4),

              // Stream Toggle
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
                  _showPillToast(newState ? l10n.streamEnabled : l10n.streamDisabled, fluent.FluentIcons.lightning_bolt);
                },
                style: fluent.ButtonStyle(
                  backgroundColor: fluent.WidgetStateProperty.resolveWith((states) {
                     if (settings.isStreamEnabled) return theme.accentColor.withOpacity(0.1);
                     return Colors.transparent;
                  }),
                ),
              ),

              const SizedBox(width: 4),

              // Search Toggle (Simplified)
              fluent.IconButton(
                icon: Icon(
                  fluent.FluentIcons.globe,
                  size: 16,
                  color: settings.isSearchEnabled 
                      ? theme.accentColor 
                      : theme.resources.textFillColorSecondary,
                ),
                onPressed: () {
                   final newState = !settings.isSearchEnabled;
                   ref.read(historyChatProvider).toggleSearch();
                   _showPillToast(newState ? l10n.searchEnabled : l10n.searchDisabled, fluent.FluentIcons.globe);
                },
                style: fluent.ButtonStyle(
                  backgroundColor: fluent.WidgetStateProperty.resolveWith((states) {
                     if (settings.isSearchEnabled) return theme.accentColor.withOpacity(0.1);
                     return Colors.transparent;
                  }),
                ),
              ),
              
              const Spacer(),
              
              if (isLoading)
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

  Widget _buildMobileInputArea(bool isLoading, SettingsState settings) {
    final l10n = AppLocalizations.of(context)!;
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
              decoration: InputDecoration(
                hintText: l10n.mobileInputHint,
                hintStyle: const TextStyle(fontSize: 15, color: Colors.grey),
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
              
              // Attachment Button
              InkWell(
                onTap: _showMobileAttachmentOptions,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    fluent.FluentIcons.attach,
                    color: Theme.of(context).colorScheme.outline,
                    size: 26,
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
                      title: Text(l10n.clearContext),
                      content: Text(l10n.clearContextConfirm),
                      actions: [
                        TextButton(
                          child: Text(l10n.cancel),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        FilledButton(
                          child: Text(l10n.confirm),
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(historyChatProvider).clearContext();
                          },
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    fluent.FluentIcons.broom,
                    color: Theme.of(context).colorScheme.outline,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Stream Toggle
              InkWell(
                onTap: () {
                  final newState = !settings.isStreamEnabled;
                  ref.read(settingsProvider.notifier).toggleStreamEnabled();
                  _showPillToast(newState ? l10n.streamEnabled : l10n.streamDisabled, fluent.FluentIcons.lightning_bolt);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    fluent.FluentIcons.lightning_bolt,
                    color: settings.isStreamEnabled 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Search Toggle
               InkWell(
                onTap: () {
                   final newState = !settings.isSearchEnabled;
                   ref.read(historyChatProvider).toggleSearch();
                   _showPillToast(newState ? l10n.searchEnabled : l10n.searchDisabled, fluent.FluentIcons.globe);
                },
                onLongPress: () {
                   // Todo: Show bottom sheet for engine selection
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    fluent.FluentIcons.globe,
                    color: settings.isSearchEnabled 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Send Button (Action depends on loading state)
              if (isLoading)
                IconButton(
                  icon: const Icon(fluent.FluentIcons.stop, color: Colors.red),
                  onPressed: () => ref.read(historyChatProvider).abortGeneration(),
                )
              else
                IconButton(
                  icon: Icon(fluent.FluentIcons.send, color: Theme.of(context).colorScheme.primary),
                  onPressed: _sendMessage,
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
          final attachDir = await getAttachmentsDir();
          final path =
              '${attachDir.path}${Platform.pathSeparator}paste_fb_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(path).writeAsBytes(imageBytes);
          if (mounted) {
            if (!_newAttachments.contains(path)) {
              setState(() {
                _newAttachments.add(path);
              });
            } else {
            }
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
        // Check extensions
        final ext = path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
             if (mounted && !_newAttachments.contains(path)) {
                setState(() {
                  _newAttachments.add(path);
                });
             } else {
             }
        }
      }
      if (!completer.isCompleted) completer.complete();
    } else {
      if (!completer.isCompleted) completer.complete();
    }
    
    // Wait for the file operation to complete, with a timeout to prevent hanging
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
          } else {
          }
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
      onEnter: (_) => Platform.isWindows ? setState(() => _isHovering = true) : null,
      onExit: (_) => Platform.isWindows ? setState(() => _isHovering = false) : null,
      child: Container(
        margin: EdgeInsets.only(
          top: widget.mergeTop ? 2 : 8,
          bottom: widget.mergeBottom ? 2 : 16, // Default was implicit separation
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
                      fallbackIcon: Icons.smart_toy,
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
                          padding:
                              const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                          child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${message.timestamp.month}/${message.timestamp.day} ${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUser
                                  ? (settingsState.userName.isNotEmpty
                                      ? settingsState.userName
                                      : AppLocalizations.of(context)!.user)
                                  : '${message.model ?? settingsState.selectedModel} | ${message.provider ?? settingsState.activeProvider?.name ?? 'AI'}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
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
                                      '${AppLocalizations.of(context)!.thinking}...',
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
                                                child: HoverImagePreview(
                                                  imagePath: _newAttachments[index],
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
                              Text(
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
                                    .map((path) => ChatImageBubble(
                                          key: ValueKey(path.hashCode),
                                          imageUrl: path,
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
                                          key: ValueKey(img.hashCode),
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
                    visible: !_isEditing, // Always visible on desktop, hidden when editing
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




class BuildToolOutput extends StatefulWidget {
  final String content;
  const BuildToolOutput({super.key, required this.content});

  @override
  State<BuildToolOutput> createState() => _BuildToolOutputState();
}

class _BuildToolOutputState extends State<BuildToolOutput> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Try parse JSON
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(widget.content);
    } catch (_) {}

    final theme = fluent.FluentTheme.of(context);
    final results = data != null ? data['results'] as List? : null;
    final count = results?.length ?? 0;
    final engine = data?['engine'] ?? 'Search';

    if (count == 0) {
      if (data?.containsKey('message') == true) {
         return Text(
           'Search Error: ${data!['message']}', 
           style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 13)
         );
      }
      return const SizedBox.shrink(); // Hide empty
    }

    // Check for search results structure
    if (results != null && results.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.resources.controlStrokeColorDefault),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Favicon Pile
                      SizedBox(
                        height: 20,
                        width: 20.0 + (math.min(results.length, 3) - 1) * 12.0,
                        child: Stack(
                          children: List.generate(math.min(results.length, 3), (index) {
                            final url = results[index]['link'] as String? ?? '';
                            Uri? uri;
                            try { uri = Uri.parse(url); } catch (_) {}
                            final domain = uri?.host ?? '';
                            final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
                            
                            return Positioned(
                              left: index * 12.0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor, 
                                    width: 2
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: domain.isNotEmpty 
                                    ? Image.network(
                                        faviconUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(fluent.FluentIcons.globe, size: 12, color: Colors.grey),
                                      )
                                    : const Icon(fluent.FluentIcons.globe, size: 12, color: Colors.grey),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$count 个引用内容', 
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.typography.body?.color?.withOpacity(0.9),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded ? fluent.FluentIcons.chevron_up : fluent.FluentIcons.chevron_down,
                        size: 10,
                        color: theme.typography.caption?.color,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded)
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.resources.controlStrokeColorDefault)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: List.generate(results.length, (index) {
                      final item = results[index];
                      final idx = item['index'] ?? (index + 1);
                      return InkWell(
                        onTap: () async {
                           final link = item['link'] as String?;
                           if (link != null) {
                             // Try open link
                              // Since we don't have launchUrl readily available in this context without imports checking, 
                              // we assume specific implementation or just ignore for now as this is UI focused.
                              // Actually, let's try to find if url_launcher is used elsewhere.
                              // For now, simple print or ignore. The user asked for UI.
                           }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 18, 
                                height: 18,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.accentColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$idx', 
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                    color: theme.accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 12, 
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item['link'] != null)
                                      Text(
                                        item['link'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.typography.caption?.color,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    }
            
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded ? fluent.FluentIcons.chevron_down : fluent.FluentIcons.chevron_right,
                  size: 10,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 8),
                Icon(fluent.FluentIcons.search, size: 14, color: theme.accentColor),
                const SizedBox(width: 8),
                Text(
                  '$count Search Results ($engine)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          ...results!.map((r) {
            final title = r['title'] ?? 'No Title';
            final link = r['link'] ?? '';
            final snippet = r['snippet'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.resources.dividerStrokeColorDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (link.isNotEmpty)
                    Text(link, style: TextStyle(color: Colors.blue, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(snippet, style: TextStyle(fontSize: 12, color: theme.typography.body!.color!.withOpacity(0.8)), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}

// --- Merged Message Support ---

abstract class DisplayItem {
  String get id;
}

class SingleMessageItem extends DisplayItem {
  final Message message;
  SingleMessageItem(this.message);
  @override
  String get id => message.id;
}

class MergedGroupItem extends DisplayItem {
  final List<Message> messages;
  MergedGroupItem(this.messages);
  @override
  String get id => messages.first.id;
  
  Message get latestMessage => messages.last;
}

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
  ConsumerState<MergedMessageBubble> createState() => _MergedMessageBubbleState();
}

class _MergedMessageBubbleState extends ConsumerState<MergedMessageBubble> with AutomaticKeepAliveClientMixin {
  bool _isHovering = false;
  bool _isEditing = false;
  late TextEditingController _editController;
  final FocusNode _focusNode = FocusNode();

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
    super.dispose();
  }

  void _handleAction(String action) {
    final group = widget.group;
    final notifier = ref.read(historyChatProvider);
    // For regeneration, we start from the FIRST message in the group (the trigger)
    // For delete, we delete ALL messages in the group
    // For copy/edit, we target the LAST message (usually the visible text)
    
    switch (action) {
      case 'retry':
        notifier.regenerateResponse(group.messages.first.id);
        break;
      case 'edit':
        setState(() {
          _isEditing = true;
          // Update controller with latest content just in case
          _editController.text = group.messages.last.content;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
        break;
      case 'copy':
        final text = group.messages.map((m) => m.content).join('\n').trim();
        final item = DataWriterItem();
        item.add(Formats.plainText(text.isNotEmpty ? text : group.messages.last.content));
        SystemClipboard.instance?.write([item]);
        break;
      case 'delete':
        for (final msg in group.messages) {
           notifier.deleteMessage(msg.id);
        }
        break;
    }
  }

  void _saveEdit() {
     final lastMsg = widget.group.messages.last;
     if (_editController.text.trim().isNotEmpty) {
       ref.read(historyChatProvider).editMessage(lastMsg.id, _editController.text);
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

    final headerMsg = messages.firstWhere((m) => m.role != 'tool', orElse: () => messages.last);

    return MouseRegion(
      onEnter: (_) => Platform.isWindows ? setState(() => _isHovering = true) : null,
      onExit: (_) => Platform.isWindows ? setState(() => _isHovering = false) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
               margin: const EdgeInsets.only(top: 2),
               width: 32,
               height: 32,
               decoration: BoxDecoration(
                 color: theme.accentColor,
                 shape: BoxShape.circle,
               ),
               child: const Icon(fluent.FluentIcons.robot,
                   color: Colors.white, size: 16),
             ),
            const SizedBox(width: 8),
            
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      children: [
                         Text(
                          '${headerMsg.timestamp.month}/${headerMsg.timestamp.day} ${headerMsg.timestamp.hour.toString().padLeft(2, '0')}:${headerMsg.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${headerMsg.model ?? 'AI'} | ${headerMsg.provider ?? 'Assistant'}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content Box
                  Container(
                    padding: _isEditing ? EdgeInsets.zero : const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isEditing ? Colors.transparent : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: _isEditing ? null : Border.all(
                         color: theme.resources.dividerStrokeColorDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isEditing) ...[
                          ...messages.expand((msg) {
                            return _buildMessageParts(msg, theme);
                          }),
                          if (widget.isGenerating && lastMsg.role != 'tool' && lastMsg.content.isEmpty && (lastMsg.reasoningContent?.isEmpty ?? true) && (lastMsg.toolCalls == null || lastMsg.toolCalls!.isEmpty))
                             Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
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
                        ],
                        
                        if (_isEditing)
                           Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                   fluent.TextBox(
                                      controller: _editController,
                                      focusNode: _focusNode,
                                      maxLines: null,
                                      minLines: 1,
                                      decoration: const fluent.WidgetStatePropertyAll(fluent.BoxDecoration(
                                         color: Colors.transparent,
                                         border: Border.fromBorderSide(BorderSide.none),
                                      )),
                                      highlightColor: Colors.transparent,
                                      unfocusedColor: Colors.transparent,
                                      style: TextStyle(fontSize: 14, height: 1.5, color: theme.typography.body?.color),
                                      onSubmitted: (_) => _saveEdit(),
                                   ),
                                   const SizedBox(height: 8),
                                   Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                         ActionButton(
                                            icon: fluent.FluentIcons.cancel,
                                            tooltip: 'Cancel',
                                            onPressed: () => setState(() => _isEditing = false)),
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
                  
                  // Action Buttons logic (Similar to MessageBubble)
                  Platform.isWindows
                  ? Visibility(
                      visible: !_isEditing && !widget.isGenerating, // Always visible on desktop, hidden when editing or generating
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

  List<Widget> _buildMessageParts(Message message, fluent.FluentThemeData theme) {
     if (message.role == 'tool') {
       return [
         Padding(
           padding: const EdgeInsets.symmetric(vertical: 8.0),
           child: BuildToolOutput(content: message.content),
         )
       ];
     }
     
     // Assistant
     final parts = <Widget>[];
     
     // Reasoning
     if (message.reasoningContent != null && message.reasoningContent!.isNotEmpty) {
        parts.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ReasoningDisplay(
               content: message.reasoningContent!,
               isWindows: Platform.isWindows,
               isRunning: widget.isGenerating && message == widget.group.messages.last,
               duration: message.reasoningDurationSeconds,
               startTime: message.timestamp,
            ),
          )
        );
     }
     
     // Content
     if (message.content.isNotEmpty) {
       parts.add(
          fluent.FluentTheme(
            data: theme,
            child: MarkdownBody(
              data: message.content,
              selectable: false,
              softLineBreak: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.typography.body!.color,
                    fontFamily: Platform.isWindows ? 'Microsoft YaHei' : null,
                  ),
                  code: TextStyle(
                    backgroundColor: theme.micaBackgroundColor,
                    color: theme.typography.body!.color,
                    fontFamily: Platform.isWindows ? 'Consolas' : null, 
                  ),
                ),
            ),
          )
       );
     }
     
     // Images (AI-generated)
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
     
     return parts;
  }
}
