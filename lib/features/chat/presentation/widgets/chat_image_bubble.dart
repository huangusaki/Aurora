import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'dart:collection';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material
    show CircularProgressIndicator;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:aurora/shared/utils/image_format_utils.dart';
import 'package:aurora/shared/utils/base64_utils.dart';
import 'package:aurora/shared/widgets/aurora_page_route.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'desktop_image_viewer.dart';
import 'mobile_image_viewer.dart';

const double _thumbnailMaxEdge = 72;
const double _thumbnailMinEdge = 44;
final LinkedHashMap<String, Uint8List> _imageCache =
    LinkedHashMap<String, Uint8List>();

void _rememberImageCache(String key, Uint8List bytes) {
  _imageCache.remove(key);
  _imageCache[key] = bytes;
  while (_imageCache.length > 96) {
    _imageCache.remove(_imageCache.keys.first);
  }
}

void clearImageCache() {
  _imageCache.clear();
}

TransferableTypedData _decodeBase64Isolate(String imageUrl) {
  final bytes = decodeDataUrlBytesLenient(imageUrl);
  return TransferableTypedData.fromList([bytes]);
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
  double? _imageAspectRatio;
  ImageStream? _imageInfoStream;
  ImageStreamListener? _imageInfoListener;
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
    _clearImageInfoListener();
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatImageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _clearImageInfoListener();
      _cachedBytes = null;
      _imageAspectRatio = null;
      _decodeImage();
    }
  }

  void _clearImageInfoListener() {
    final stream = _imageInfoStream;
    final listener = _imageInfoListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageInfoStream = null;
    _imageInfoListener = null;
  }

  void _resolveImageAspectRatio({Uint8List? bytes}) {
    _clearImageInfoListener();

    final ImageProvider provider;
    if (bytes != null) {
      provider = MemoryImage(bytes);
    } else if (_isLocalFile) {
      provider = FileImage(File(widget.imageUrl));
    } else {
      provider = NetworkImage(widget.imageUrl);
    }

    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        final ui.Image image = info.image;
        if (image.width <= 0 || image.height <= 0 || !mounted) {
          _clearImageInfoListener();
          return;
        }
        final ratio = image.width / image.height;
        if (_imageAspectRatio != ratio) {
          setState(() {
            _imageAspectRatio = ratio;
          });
        }
        _clearImageInfoListener();
      },
      onError: (Object error, StackTrace? stackTrace) {
        _clearImageInfoListener();
      },
    );

    _imageInfoStream = stream;
    _imageInfoListener = listener;
    stream.addListener(listener);
  }

  void _setAspectRatioFromBytes(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
        _resolveImageAspectRatio(bytes: bytes);
        return;
      }
      final ratio = decoded.width / decoded.height;
      if (!mounted) return;
      if (_imageAspectRatio != ratio) {
        setState(() {
          _imageAspectRatio = ratio;
        });
      }
    } catch (_) {
      _resolveImageAspectRatio(bytes: bytes);
    }
  }

  Size _thumbnailSize() {
    final ratio = (_imageAspectRatio ?? 1.0).clamp(0.4, 2.5);
    if (ratio >= 1) {
      return Size(
        _thumbnailMaxEdge,
        (_thumbnailMaxEdge / ratio).clamp(_thumbnailMinEdge, _thumbnailMaxEdge),
      );
    }
    return Size(
      (_thumbnailMaxEdge * ratio).clamp(_thumbnailMinEdge, _thumbnailMaxEdge),
      _thumbnailMaxEdge,
    );
  }

  Future<void> _decodeImage() async {
    if (_isBase64) {
      final cacheKey = widget.imageUrl;
      if (_imageCache.containsKey(cacheKey)) {
        if (mounted) {
          final cachedBytes = _imageCache[cacheKey];
          setState(() => _cachedBytes = cachedBytes);
          if (cachedBytes != null) {
            _setAspectRatioFromBytes(cachedBytes);
          }
        }
        return;
      }
      if (mounted) {
        try {
          final Uint8List bytes;
          final useIsolate = widget.imageUrl.length > 50 * 1024;
          if (useIsolate) {
            final transferable =
                await compute(_decodeBase64Isolate, widget.imageUrl);
            bytes = transferable.materialize().asUint8List();
          } else {
            bytes = decodeDataUrlBytesLenient(widget.imageUrl);
          }
          _rememberImageCache(cacheKey, bytes);
          if (mounted) {
            setState(() => _cachedBytes = bytes);
          }
          _setAspectRatioFromBytes(bytes);
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
      _resolveImageAspectRatio();
    }
  }

  Future<Uint8List?> _getImageBytes() async {
    if (_cachedBytes != null) {
      return _cachedBytes;
    }
    if (_isLocalFile) {
      try {
        final file = File(widget.imageUrl);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _rememberImageCache(widget.imageUrl, bytes);
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

  Widget _buildThumbnailImage() {
    if (_isBase64 && _cachedBytes != null) {
      return Image.memory(
        _cachedBytes!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) {
          debugPrint('Image.memory render error: $err');
          return const Icon(FluentIcons.error);
        },
      );
    }
    if (_isLocalFile) {
      return Image.file(
        File(widget.imageUrl),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) {
          return const Icon(FluentIcons.error);
        },
      );
    }
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      errorBuilder: (ctx, err, stack) {
        return const Icon(FluentIcons.error);
      },
    );
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
      final ext = detectImageExtension(bytes);
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          item.add(Formats.jpeg(bytes));
          break;
        case 'gif':
          item.add(Formats.gif(bytes));
          break;
        case 'webp':
          item.add(Formats.webp(bytes));
          break;
        case 'bmp':
          item.add(Formats.bmp(bytes));
          break;
        case 'tif':
        case 'tiff':
          item.add(Formats.tiff(bytes));
          break;
        case 'png':
        default:
          item.add(Formats.png(bytes));
          break;
      }
      await clipboard.write([item]);
      if (context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          final l10n = AppLocalizations.of(context)!;
          return InfoBar(
            title: Text(l10n.imageCopied),
            content: Text(l10n.imageCopiedToClipboard),
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
          final l10n = AppLocalizations.of(context)!;
          return InfoBar(
            title: Text(l10n.clipboardError),
            content: Text(l10n.clipboardAccessFailed),
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

  Future<void> _handleSave({required String imagesLabel}) async {
    final bytes = await _getImageBytes();
    if (bytes == null) return;
    final ext = detectImageExtension(bytes);
    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: 'image_${DateTime.now().millisecondsSinceEpoch}.$ext',
      acceptedTypeGroups: [
        XTypeGroup(label: imagesLabel, extensions: [ext]),
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
          _rememberImageCache(widget.imageUrl, bytes);
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
    if (PlatformUtils.isDesktop) {
      Navigator.of(context).push(
        AuroraFadePageRoute(
          opaque: false,
          builder: (context) => DesktopImageViewer(
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
    final thumbnailSize = _thumbnailSize();
    if (_isBase64 && _cachedBytes == null) {
      return Container(
        width: thumbnailSize.width,
        height: thumbnailSize.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: PlatformUtils.isDesktop
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
                final l10n = AppLocalizations.of(context)!;
                return MenuFlyout(
                  items: [
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.copy),
                      text: Text(l10n.copyImage),
                      onPressed: () {
                        Flyout.of(context).close();
                        _handleCopy(context);
                      },
                    ),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.save),
                      text: Text(l10n.saveImageAs),
                      onPressed: () {
                        Flyout.of(context).close();
                        _handleSave(imagesLabel: l10n.images);
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: Container(
            width: thumbnailSize.width,
            height: thumbnailSize.height,
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
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.04),
                child: _buildThumbnailImage(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
