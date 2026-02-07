import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material
    show CircularProgressIndicator;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:aurora/shared/widgets/aurora_page_route.dart';
import 'windows_image_viewer.dart';
import 'mobile_image_viewer.dart';

final Map<int, Uint8List> _imageCache = {};
void clearImageCache() {
  _imageCache.clear();
}

Uint8List? _decodeBase64Isolate(String imageUrl) {
  final commaIndex = imageUrl.indexOf(',');
  if (commaIndex != -1) {
    return base64Decode(imageUrl.substring(commaIndex + 1));
  }
  return null;
}

class ChatImageBubble extends StatefulWidget {
  final String imageUrl;
  final String? altText;
  const ChatImageBubble({
    super.key,
    required this.imageUrl,
    this.altText,
  });
  @override
  State<ChatImageBubble> createState() => _ChatImageBubbleState();
}

class _ChatImageBubbleState extends State<ChatImageBubble> {
  Uint8List? _cachedBytes;
  bool get _isBase64 => widget.imageUrl.startsWith('data:');
  bool get _isLocalFile => !widget.imageUrl.startsWith('http') && !_isBase64;
  final FlyoutController _flyoutController = FlyoutController();
  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatImageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _decodeImage();
    }
  }

  Future<void> _decodeImage() async {
    if (_isBase64) {
      final cacheKey = widget.imageUrl.hashCode;
      if (_imageCache.containsKey(cacheKey)) {
        if (mounted) {
          setState(() => _cachedBytes = _imageCache[cacheKey]);
        }
        return;
      }
      if (mounted) {
        try {
          Uint8List? bytes;
          if (widget.imageUrl.length > 50 * 1024) {
            bytes = await compute(_decodeBase64Isolate, widget.imageUrl);
          } else {
            final commaIndex = widget.imageUrl.indexOf(',');
            bytes = (commaIndex != -1)
                ? base64Decode(widget.imageUrl.substring(commaIndex + 1))
                : base64Decode(widget.imageUrl);
          }
          if (bytes != null) {
            _imageCache[cacheKey] = bytes;
            if (mounted) {
              setState(() => _cachedBytes = bytes);
            }
          }
        } catch (e) {
          debugPrint('Failed to decode base64 image: $e');
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _cachedBytes = null;
        });
      }
    }
  }

  Future<Uint8List?> _getImageBytes() async {
    if (_cachedBytes != null) return _cachedBytes;
    if (_isLocalFile) {
      try {
        final file = File(widget.imageUrl);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _imageCache[widget.imageUrl.hashCode] = bytes;
          if (mounted) {
            setState(() => _cachedBytes = bytes);
          }
          return bytes;
        }
      } catch (e) {
        debugPrint('Failed to read local file: $e');
      }
    }
    return null;
  }

  Future<void> _handleCopy(BuildContext context) async {
    final bytes = await _getImageBytes();
    if (bytes == null) {
      return;
    }
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return;
      final item = DataWriterItem();
      item.add(Formats.png(bytes));
      await clipboard.write([item]);
      if (context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Image Copied'),
            content: const Text('Image has been copied to clipboard'),
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
            severity: InfoBarSeverity.success,
          );
        });
      }
    } catch (e) {
      debugPrint('Clipboard error: $e');
      if (context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Clipboard Error'),
            content: const Text(
                'Failed to access clipboard. Please restart the app completely.'),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          );
        });
      }
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    final bytes = await _getImageBytes();
    if (bytes == null) return;
    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: 'image_${DateTime.now().millisecondsSinceEpoch}.png',
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Images',
          extensions: ['png'],
        ),
      ],
    );
    if (result != null) {
      final File file = File(result.path);
      await file.writeAsBytes(bytes);
    }
  }

  void _showFullImage(BuildContext context) async {
    Uint8List? bytes = _cachedBytes;
    if (bytes == null && _isLocalFile) {
      try {
        final file = File(widget.imageUrl);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
          _imageCache[widget.imageUrl.hashCode] = bytes;
          if (mounted) {
            setState(() => _cachedBytes = bytes);
          }
        }
      } catch (e) {
        debugPrint('Failed to read local file: $e');
        return;
      }
    }
    if (bytes == null) return;
    if (!context.mounted) return;
    if (Platform.isWindows) {
      Navigator.of(context).push(
        AuroraFadePageRoute(
          opaque: false,
          builder: (context) => WindowsImageViewer(
            imageBytes: bytes!,
            onClose: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        AuroraFadePageRoute(
          builder: (context) => MobileImageViewer(
            imageBytes: bytes!,
            onClose: () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isBase64) {
      final bytes = _cachedBytes;
      if (bytes == null) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: Platform.isWindows
                  ? const ProgressRing(strokeWidth: 2)
                  : const material.CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      return FlyoutTarget(
        controller: _flyoutController,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showFullImage(context),
            onSecondaryTapUp: (details) {
              _flyoutController.showFlyout(
                position: details.globalPosition,
                builder: (context) {
                  return MenuFlyout(
                    items: [
                      MenuFlyoutItem(
                        leading: const Icon(FluentIcons.copy),
                        text: const Text('Copy Image'),
                        onPressed: () {
                          Flyout.of(context).close();
                          _handleCopy(context);
                        },
                      ),
                      MenuFlyoutItem(
                        leading: const Icon(FluentIcons.save),
                        text: const Text('Save Image As...'),
                        onPressed: () {
                          Flyout.of(context).close();
                          _handleSave(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) =>
                      const Icon(FluentIcons.error),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return FlyoutTarget(
      controller: _flyoutController,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showFullImage(context),
          onSecondaryTapUp: (details) {
            _flyoutController.showFlyout(
              position: details.globalPosition,
              builder: (context) {
                return MenuFlyout(
                  items: [
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.copy),
                      text: const Text('Copy Image'),
                      onPressed: () {
                        Flyout.of(context).close();
                        _handleCopy(context);
                      },
                    ),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.save),
                      text: const Text('Save Image As...'),
                      onPressed: () {
                        Flyout.of(context).close();
                        _handleSave(context);
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _isLocalFile
                  ? Image.file(
                      File(widget.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) =>
                          const Icon(FluentIcons.error),
                    )
                  : Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) =>
                          const Icon(FluentIcons.error),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
