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
import 'components/chat_scroll_navigator.dart';

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
  final GlobalKey _messageViewportKey = GlobalKey();
  final Map<String, BuildContext> _builtItemContexts = {};
  List<String> _displayOrderIds = const [];
  Map<String, int> _displayIndexById = {};
  bool _isNavAnimating = false;
  String _lastSessionId = '';
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
    _lastSessionId = widget.sessionId;
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

      final target = (prevPixels + deltaMax)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
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

  void _registerBuiltItemContext(String itemId, BuildContext ctx) {
    _builtItemContexts[itemId] = ctx;
  }

  void _unregisterBuiltItemContext(String itemId) {
    _builtItemContexts.remove(itemId);
  }

  Rect? _rectForContext(BuildContext? ctx) {
    final renderObject = ctx?.findRenderObject();
    if (renderObject is! RenderBox) return null;
    if (!renderObject.hasSize) return null;
    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }

  Rect? _messageViewportRect() =>
      _rectForContext(_messageViewportKey.currentContext);

  int _computeAnchorIndex() {
    final count = _displayOrderIds.length;
    if (count == 0) return 0;

    final viewportRect = _messageViewportRect();
    if (viewportRect != null && viewportRect.height > 0) {
      final anchorY = viewportRect.top + viewportRect.height * 0.25;
      String? bestId;
      double bestDist = double.infinity;

      double distanceToRectY(Rect rect, double y) {
        if (y < rect.top) return rect.top - y;
        if (y > rect.bottom) return y - rect.bottom;
        return 0;
      }

      for (final entry in _builtItemContexts.entries) {
        if (!entry.value.mounted) continue;
        final rect = _rectForContext(entry.value);
        if (rect == null) continue;
        if (!rect.overlaps(viewportRect)) continue;
        final dist = distanceToRectY(rect, anchorY);
        if (dist < bestDist) {
          bestDist = dist;
          bestId = entry.key;
        }
      }
      if (bestId != null) {
        final idx = _displayIndexById[bestId];
        if (idx != null) {
          return idx.clamp(0, count - 1);
        }
      }
    }

    if (_scrollController.hasClients) {
      final pos = _scrollController.position;
      final maxScroll = pos.maxScrollExtent;
      if (maxScroll > 0) {
        final ratio = (pos.pixels / maxScroll).clamp(0.0, 1.0);
        final idx = (ratio * (count - 1)).round();
        return idx.clamp(0, count - 1);
      }
    }

    return 0;
  }

  Future<void> _runNavAction(Future<void> Function() action) async {
    if (_isNavAnimating) return;
    _isNavAnimating = true;
    try {
      await action();
    } finally {
      _isNavAnimating = false;
    }
  }

  Future<void> _jumpToBottom() async {
    await _runNavAction(() async {
      if (!_scrollController.hasClients) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _jumpToTop() async {
    await _runNavAction(() async {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      await _scrollController.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  (int?, int?) _findVisibleBoundaryIndices() {
    final viewportRect = _messageViewportRect();
    if (viewportRect == null) return (null, null);
    int? topmostIdx;
    int? bottommostIdx;
    for (final entry in _builtItemContexts.entries) {
      if (!entry.value.mounted) continue;
      final rect = _rectForContext(entry.value);
      if (rect == null) continue;
      if (!rect.overlaps(viewportRect)) continue;
      final idx = _displayIndexById[entry.key];
      if (idx == null) continue;
      if (topmostIdx == null || idx > topmostIdx) topmostIdx = idx;
      if (bottommostIdx == null || idx < bottommostIdx) bottommostIdx = idx;
    }
    return (topmostIdx, bottommostIdx);
  }

  Future<void> _jumpToPrevMessage() async {
    await _runNavAction(() async {
      final count = _displayOrderIds.length;
      if (count <= 1) return;
      final (topmostIdx, _) = _findVisibleBoundaryIndices();
      final anchorIndex = topmostIdx ?? _computeAnchorIndex();
      final targetIndex = (anchorIndex + 1).clamp(0, count - 1);
      if (targetIndex == anchorIndex) return;
      await _scrollToDisplayIndex(targetIndex, anchorIndex: anchorIndex);
    });
  }

  Future<void> _jumpToNextMessage() async {
    await _runNavAction(() async {
      final count = _displayOrderIds.length;
      if (count <= 1) return;
      final (_, bottommostIdx) = _findVisibleBoundaryIndices();
      final anchorIndex = bottommostIdx ?? _computeAnchorIndex();
      final targetIndex = (anchorIndex - 1).clamp(0, count - 1);
      if (targetIndex == anchorIndex) return;
      await _scrollToDisplayIndex(targetIndex, anchorIndex: anchorIndex);
    });
  }

  Future<void> _scrollToDisplayIndex(int targetIndex,
      {required int anchorIndex}) async {
    if (!_scrollController.hasClients) return;
    if (targetIndex < 0 || targetIndex >= _displayOrderIds.length) return;

    final pos = _scrollController.position;
    // NOTE: `alignment` is applied to the target's full paint bounds.
    // For very tall bubbles (e.g. long Markdown, agent output, reasoning blocks),
    // using a fractional alignment like 0.9 can still leave the bubble header
    // off-screen. Align to the physical top deterministically.
    final alignToTop = pos.axisDirection == AxisDirection.up ? 1.0 : 0.0;

    final targetId = _displayOrderIds[targetIndex];
    final targetCtx = _builtItemContexts[targetId];
    if (targetCtx != null) {
      try {
        await Scrollable.ensureVisible(
          targetCtx,
          alignment: alignToTop,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
      return;
    }

    final direction = targetIndex > anchorIndex ? 1.0 : -1.0;
    double delta = direction * pos.viewportDimension * 0.8;
    final viewportRect = _messageViewportRect();
    if (viewportRect != null &&
        anchorIndex >= 0 &&
        anchorIndex < _displayOrderIds.length) {
      final anchorId = _displayOrderIds[anchorIndex];
      final anchorCtx = _builtItemContexts[anchorId];
      final anchorRect = _rectForContext(anchorCtx);
      if (anchorRect != null) {
        const edgePaddingFactor = 0.15;
        if (direction > 0) {
          // Move current item down to create space above it for the previous (older) item.
          final desiredTop =
              viewportRect.top + viewportRect.height * edgePaddingFactor;
          final needed = desiredTop - anchorRect.top;
          if (needed > 0) {
            delta = needed;
          }
        } else {
          // Move current item up to create space below it for the next (newer) item.
          final desiredBottom =
              viewportRect.bottom - viewportRect.height * edgePaddingFactor;
          final needed = desiredBottom - anchorRect.bottom;
          if (needed < 0) {
            delta = needed;
          }
        }
      }
    }

    final roughOffset = (pos.pixels + delta)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent)
        .toDouble();

    try {
      final distance = (roughOffset - pos.pixels).abs();
      final normalized = pos.viewportDimension > 0
          ? (distance / pos.viewportDimension).clamp(0.0, 4.0)
          : 1.0;
      final durationMs = (180 + normalized * 90).round().clamp(180, 450);
      await _scrollController.animateTo(
        roughOffset,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final retryCtx = _builtItemContexts[targetId];
    if (retryCtx == null || !retryCtx.mounted) return;
    try {
      await Scrollable.ensureVisible(
        retryCtx,
        alignment: alignToTop,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
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

  Future<bool> _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return false;
    const maxAttempts = 10;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
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
    if (_lastSessionId != widget.sessionId) {
      _lastSessionId = widget.sessionId;
      _hasRestoredPosition = false;
      _wasLoading = false;
      _prevMaxScrollExtent = null;
      _prevScrollPixels = null;
      _builtItemContexts.clear();
      _displayOrderIds = const [];
      _displayIndexById = {};
    }
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

    _displayOrderIds =
        displayItems.reversed.map((e) => e.id).toList(growable: false);
    _displayIndexById = {
      for (int i = 0; i < _displayOrderIds.length; i++) _displayOrderIds[i]: i,
    };
    final showScrollNavigator =
        !chatState.isAutoScrollEnabled && displayItems.isNotEmpty;

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
                child: Stack(
                  key: _messageViewportKey,
                  children: [
                    Positioned.fill(
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
                                      key: ValueKey(ref.watch(
                                          selectedHistorySessionIdProvider)),
                                      controller: _scrollController,
                                      reverse: true,
                                      padding: const EdgeInsets.all(16),
                                      itemCount: displayItems.length,
                                      itemBuilder: (context, index) {
                                        final reversedIndex =
                                            displayItems.length - 1 - index;
                                        final item =
                                            displayItems[reversedIndex];
                                        final isLatest = index == 0;
                                        final isGenerating =
                                            isLatest && isLoading;

                                        Widget child;
                                        if (item is MergedGroupItem) {
                                          child = MergedMessageBubble(
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
                                            mergeBottom: mergeBottom,
                                          );
                                          if (isLatest) {
                                            child =
                                                TweenAnimationBuilder<double>(
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
                                          } else {
                                            child = bubble;
                                          }
                                        } else {
                                          return const SizedBox.shrink();
                                        }

                                        return _ChatItemAnchor(
                                          key: ValueKey(item.id),
                                          itemId: item.id,
                                          onMount: _registerBuiltItemContext,
                                          onUnmount:
                                              _unregisterBuiltItemContext,
                                          child: child,
                                        );
                                      },
                                      physics: const ClampingScrollPhysics(),
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                cacheExtent: 2000,
                                key: ValueKey(ref
                                    .watch(selectedHistorySessionIdProvider)),
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 12),
                                itemCount: displayItems.length,
                                itemBuilder: (context, index) {
                                  final reversedIndex =
                                      displayItems.length - 1 - index;
                                  final item = displayItems[reversedIndex];
                                  final isLatest = index == 0;
                                  final isGenerating = isLatest && isLoading;

                                  Widget child;
                                  if (item is MergedGroupItem) {
                                    final bubble = MergedMessageBubble(
                                      key: ValueKey(item.id),
                                      group: item,
                                      isLast: isLatest,
                                      isGenerating: isGenerating,
                                    );
                                    if (isLatest) {
                                      child = TweenAnimationBuilder<double>(
                                        key: ValueKey(item.id),
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
                                    } else {
                                      child = bubble;
                                    }
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
                                      mergeBottom: mergeBottom,
                                    );
                                    if (isLatest) {
                                      child = TweenAnimationBuilder<double>(
                                        key: ValueKey(msg.id),
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
                                    } else {
                                      child = bubble;
                                    }
                                  } else {
                                    return const SizedBox.shrink();
                                  }

                                  return _ChatItemAnchor(
                                    key: ValueKey(item.id),
                                    itemId: item.id,
                                    onMount: _registerBuiltItemContext,
                                    onUnmount: _unregisterBuiltItemContext,
                                    child: child,
                                  );
                                },
                                physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics()),
                              ),
                      ),
                    ),
                    Positioned(
                      right: PlatformUtils.isDesktop ? 20 : 12,
                      bottom: 12,
                      child: ChatScrollNavigator(
                        visible: showScrollNavigator,
                        onJumpToTop: _jumpToTop,
                        onJumpToPrev: _jumpToPrevMessage,
                        onJumpToNext: _jumpToNextMessage,
                        onJumpToBottom: _jumpToBottom,
                      ),
                    ),
                  ],
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

class _ChatItemAnchor extends StatefulWidget {
  final String itemId;
  final Widget child;
  final void Function(String itemId, BuildContext ctx) onMount;
  final void Function(String itemId) onUnmount;

  const _ChatItemAnchor({
    super.key,
    required this.itemId,
    required this.child,
    required this.onMount,
    required this.onUnmount,
  });

  @override
  State<_ChatItemAnchor> createState() => _ChatItemAnchorState();
}

class _ChatItemAnchorState extends State<_ChatItemAnchor> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onMount(widget.itemId, context);
  }

  @override
  void didUpdateWidget(covariant _ChatItemAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      widget.onUnmount(oldWidget.itemId);
    }
    widget.onMount(widget.itemId, context);
  }

  @override
  void dispose() {
    widget.onUnmount(widget.itemId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: widget.child);
  }
}
