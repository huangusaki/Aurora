
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:super_clipboard/super_clipboard.dart';

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

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(ChatImageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _decodeImage();
    }
  }

  void _decodeImage() {
    if (_isBase64) {
      try {
        final commaIndex = widget.imageUrl.indexOf(',');
        if (commaIndex != -1) {
          setState(() {
            _cachedBytes = base64Decode(widget.imageUrl.substring(commaIndex + 1));
          });
          return;
        }
      } catch (e) {
        debugPrint('Failed to decode base64 image: $e');
      }
    }
    setState(() {
      _cachedBytes = null;
    });
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
            content: const Text('Failed to access clipboard. Please restart the app completely.'),
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
      suggestedName: 'generated_image_${DateTime.now().millisecondsSinceEpoch}.png',
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg'],
        ),
      ],
    );

    if (result != null) {
      final File file = File(result.path);
      await file.writeAsBytes(bytes);
    }
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          content: _isBase64 
              ? (_cachedBytes != null 
                  ? Image.memory(_cachedBytes!, fit: BoxFit.contain)
                  : const Icon(FluentIcons.error))
              : (_isLocalFile 
                  ? Image.file(File(widget.imageUrl), fit: BoxFit.contain)
                  : Image.network(widget.imageUrl, fit: BoxFit.contain)),
          actions: [
            Button(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
            Button(
              child: const Text('Save'),
              onPressed: () {
                _handleSave(context);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isBase64) {
      final bytes = _cachedBytes;
      if (bytes == null) return Icon(FluentIcons.error, color: Colors.red);

      // Controller for the context menu
      final flyoutController = FlyoutController();

      return FlyoutTarget(
        controller: flyoutController,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showFullImage(context),
            onSecondaryTapUp: (details) {
              flyoutController.showFlyout(
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
                ]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(FluentIcons.error),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Fallback for URLs or Local Files
    return SizedBox(
      width: 60,
      height: 60, 
      child: _isLocalFile 
        ? Image.file(File(widget.imageUrl), fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(FluentIcons.error))
        : Image.network(widget.imageUrl, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(FluentIcons.error)),
    );
  }
}
