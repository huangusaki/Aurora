import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material show CircularProgressIndicator, InteractiveViewer, Scaffold, AppBar, IconButton, Icons;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter/foundation.dart';
import 'windows_image_viewer.dart';

// Top-level function for compute
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
  String? _mimeType;
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
      if (mounted) {
        try {
          // Only use isolate for large images (>50KB) to avoid isolate startup overhead
          // for small icons/images which causes jank on mobile.
          if (widget.imageUrl.length > 50 * 1024) {
            final bytes = await compute(_decodeBase64Isolate, widget.imageUrl);
            if (mounted && bytes != null) {
              setState(() {
                _cachedBytes = bytes;
              });
            }
          } else {
             // Synchronous decode for small images (fast)
             final commaIndex = widget.imageUrl.indexOf(',');
             final bytes = (commaIndex != -1) 
                 ? base64Decode(widget.imageUrl.substring(commaIndex + 1))
                 : base64Decode(widget.imageUrl);
             if (mounted) {
               setState(() {
                 _cachedBytes = bytes;
               });
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

  Future<void> _handleCopy(BuildContext context) async {
    final bytes = _cachedBytes;
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
    final bytes = _cachedBytes;
    if (bytes == null) return;
    
    final FileSaveLocation? result = await getSaveLocation(
      suggestedName:
          'generated_image_${DateTime.now().millisecondsSinceEpoch}.png',
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

  void _showFullImage(BuildContext context) {
    final bytes = _cachedBytes;
    if (bytes == null) return;
    
    if (Platform.isWindows) {
      // Windows: Full-featured image viewer
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return WindowsImageViewer(
              imageBytes: bytes,
              onClose: () => Navigator.pop(context),
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      // Mobile: Simple zoomable viewer
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) {
            return material.Scaffold(
              backgroundColor: Colors.black,
              appBar: material.AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: material.IconButton(
                  icon: const Icon(material.Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              extendBodyBehindAppBar: true,
              body: Center(
                child: material.InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isBase64) {
      final bytes = _cachedBytes;
      if (bytes == null) return Icon(FluentIcons.error, color: Colors.red);
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
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
    return SizedBox(
      width: 60,
      height: 60,
      child: _isLocalFile
          ? Image.file(File(widget.imageUrl),
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const Icon(FluentIcons.error))
          : Image.network(widget.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const Icon(FluentIcons.error)),
    );
  }
}
