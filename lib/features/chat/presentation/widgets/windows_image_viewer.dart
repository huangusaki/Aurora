import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:file_selector/file_selector.dart';
import 'package:super_clipboard/super_clipboard.dart';

class WindowsImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback? onClose;
  const WindowsImageViewer({
    super.key,
    required this.imageBytes,
    this.onClose,
  });
  @override
  State<WindowsImageViewer> createState() => _WindowsImageViewerState();
}

class _WindowsImageViewerState extends State<WindowsImageViewer> {
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
          return InfoBar(
            title: const Text('已复制'),
            content: const Text('图片已复制到剪贴板'),
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
    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: 'image_${DateTime.now().millisecondsSinceEpoch}.png',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Images', extensions: ['png']),
      ],
    );
    if (result != null) {
      final File file = File(result.path);
      await file.writeAsBytes(widget.imageBytes);
      if (mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('已保存'),
            content: Text('图片已保存到 ${result.path}'),
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
            child: Container(color: Colors.black.withOpacity(0.9)),
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
                      transform: Matrix4.identity()
                        ..scale(_flipHorizontal ? -1.0 : 1.0,
                            _flipVertical ? -1.0 : 1.0),
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
              icon:
                  Icon(AuroraIcons.close, size: 20, color: Colors.white),
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
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToolButton(
                      icon: AuroraIcons.refresh,
                      tooltip: '重置',
                      onPressed: _resetView,
                    ),
                    const SizedBox(width: 8),
                    _ToolButton(
                      icon: AuroraIcons.retry,
                      tooltip: '向左旋转',
                      onPressed: _rotateLeft,
                    ),
                    _ToolButton(
                      icon: AuroraIcons.retry,
                      tooltip: '向右旋转',
                      onPressed: _rotateRight,
                      flipIcon: true,
                    ),
                    const SizedBox(width: 8),
                    _ToolButton(
                      icon: AuroraIcons.sync,
                      tooltip: '水平翻转',
                      onPressed: _flipH,
                    ),
                    _ToolButton(
                      icon: AuroraIcons.sync,
                      tooltip: '垂直翻转',
                      onPressed: _flipV,
                      rotateIcon: true,
                    ),
                    const SizedBox(width: 8),
                    _ToolButton(
                      icon: AuroraIcons.delete,
                      tooltip: '缩小',
                      onPressed: _zoomOut,
                    ),
                    _ToolButton(
                      icon: FluentIcons.add,
                      tooltip: '放大',
                      onPressed: _zoomIn,
                    ),
                    const SizedBox(width: 16),
                    _ToolButton(
                      icon: FluentIcons.copy,
                      tooltip: '复制',
                      onPressed: _handleCopy,
                    ),
                    _ToolButton(
                      icon: FluentIcons.download,
                      tooltip: '保存',
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
        transform: Matrix4.identity()..scale(-1.0, 1.0),
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
