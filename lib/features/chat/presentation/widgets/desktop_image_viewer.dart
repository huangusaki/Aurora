import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:file_selector/file_selector.dart';
import 'package:super_clipboard/super_clipboard.dart';

class DesktopImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback? onClose;
  const DesktopImageViewer({
    super.key,
    required this.imageBytes,
    this.onClose,
  });
  @override
  State<DesktopImageViewer> createState() => _DesktopImageViewerState();
}

class _DesktopImageViewerState extends State<DesktopImageViewer> {
  double _scale = 1.0;
  double _rotation = 0.0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;
  Offset _offset = Offset.zero;
  void _zoomIn() {
    setState(() {
      _scale = (_scale * 1.25).clamp(0.1, 10.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale / 1.25).clamp(0.1, 10.0);
    });
  }

  void _rotateRight() {
    setState(() {
      _rotation += math.pi / 2;
    });
  }

  void _rotateLeft() {
    setState(() {
      _rotation -= math.pi / 2;
    });
  }

  void _flipH() {
    setState(() {
      _flipHorizontal = !_flipHorizontal;
    });
  }

  void _flipV() {
    setState(() {
      _flipVertical = !_flipVertical;
    });
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _rotation = 0.0;
      _flipHorizontal = false;
      _flipVertical = false;
      _offset = Offset.zero;
    });
  }

  Future<void> _handleCopy() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return;
      final item = DataWriterItem();
      item.add(Formats.png(widget.imageBytes));
      await clipboard.write([item]);
      if (mounted) {
        displayInfoBar(context, builder: (context, close) {
          final l10n = AppLocalizations.of(context)!;
          return InfoBar(
            title: Text(l10n.copied),
            content: Text(l10n.imageCopiedToClipboard),
            severity: InfoBarSeverity.success,
            action: IconButton(
                icon: const Icon(AuroraIcons.close), onPressed: close),
          );
        });
      }
    } catch (e) {
      debugPrint('Copy error: $e');
    }
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: 'image_${DateTime.now().millisecondsSinceEpoch}.png',
      acceptedTypeGroups: [
        XTypeGroup(label: l10n.images, extensions: const ['png']),
      ],
    );
    if (result != null) {
      final File file = File(result.path);
      await file.writeAsBytes(widget.imageBytes);
      if (mounted) {
        displayInfoBar(context, builder: (context, close) {
          final l10n = AppLocalizations.of(context)!;
          return InfoBar(
            title: Text(l10n.imageSaved),
            content: Text(l10n.imageSavedToPath(result.path)),
            severity: InfoBarSeverity.success,
            action: IconButton(
                icon: const Icon(AuroraIcons.close), onPressed: close),
          );
        });
      }
    }
  }

  void _handleScroll(PointerScrollEvent event) {
    setState(() {
      if (event.scrollDelta.dy < 0) {
        _scale = (_scale * 1.1).clamp(0.1, 10.0);
      } else {
        _scale = (_scale / 1.1).clamp(0.1, 10.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handleScroll(event);
        }
      },
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose ?? () => Navigator.pop(context),
            child: Container(color: Colors.black.withValues(alpha: 0.9)),
          ),
          GestureDetector(
            onScaleStart: (details) {},
            onScaleUpdate: (details) {
              setState(() {
                _scale = (_scale * details.scale).clamp(0.1, 10.0);
                _offset += details.focalPointDelta;
              });
            },
            onDoubleTap: _resetView,
            child: Center(
              child: Transform.translate(
                offset: _offset,
                child: Transform.scale(
                  scale: _scale,
                  child: Transform.rotate(
                    angle: _rotation,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(
                        _flipHorizontal ? -1.0 : 1.0,
                        _flipVertical ? -1.0 : 1.0,
                        1.0,
                      ),
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(AuroraIcons.close, size: 20, color: Colors.white),
              onPressed: widget.onClose ?? () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToolButton(
                      icon: AuroraIcons.refresh,
                      tooltip: l10n.reset,
                      onPressed: _resetView,
                    ),
                    const SizedBox(width: 8),
                    _ToolButton(
                      icon: AuroraIcons.retry,
                      tooltip: l10n.rotateLeft,
                      onPressed: _rotateLeft,
                    ),
                    _ToolButton(
                      icon: AuroraIcons.retry,
                      tooltip: l10n.rotateRight,
                      onPressed: _rotateRight,
                      flipIcon: true,
                    ),
                    const SizedBox(width: 8),
                    _ToolButton(
                      icon: AuroraIcons.sync,
                      tooltip: l10n.flipHorizontal,
                      onPressed: _flipH,
                    ),
                    _ToolButton(
                      icon: AuroraIcons.sync,
                      tooltip: l10n.flipVertical,
                      onPressed: _flipV,
                      rotateIcon: true,
                    ),
                    const SizedBox(width: 8),
                    _ToolButton(
                      icon: AuroraIcons.delete,
                      tooltip: l10n.zoomOut,
                      onPressed: _zoomOut,
                    ),
                    _ToolButton(
                      icon: FluentIcons.add,
                      tooltip: l10n.zoomIn,
                      onPressed: _zoomIn,
                    ),
                    const SizedBox(width: 16),
                    _ToolButton(
                      icon: FluentIcons.copy,
                      tooltip: l10n.copy,
                      onPressed: _handleCopy,
                    ),
                    _ToolButton(
                      icon: FluentIcons.download,
                      tooltip: l10n.save,
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool flipIcon;
  final bool rotateIcon;
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.flipIcon = false,
    this.rotateIcon = false,
  });
  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, size: 18, color: Colors.white);
    if (flipIcon) {
      iconWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: iconWidget,
      );
    }
    if (rotateIcon) {
      iconWidget = Transform.rotate(
        angle: math.pi / 2,
        child: iconWidget,
      );
    }
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: iconWidget,
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
        ),
      ),
    );
  }
}
