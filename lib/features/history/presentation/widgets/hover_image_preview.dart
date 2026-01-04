import 'dart:io';
import 'package:flutter/material.dart';

class HoverImagePreview extends StatefulWidget {
  final String imagePath;
  final Widget child;
  const HoverImagePreview({
    Key? key,
    required this.imagePath,
    required this.child,
  }) : super(key: key);
  @override
  State<HoverImagePreview> createState() => _HoverImagePreviewState();
}

class _HoverImagePreviewState extends State<HoverImagePreview> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  void _showPreview() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hidePreview() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 250,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, -260),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(widget.imagePath),
                      height: 200,
                      width: 234,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey,
                        alignment: Alignment.center,
                        child:
                            const Icon(Icons.broken_image, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.imagePath.split(Platform.pathSeparator).last,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getFileSize(widget.imagePath),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFileSize(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024)
          return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {}
    return '';
  }

  @override
  void dispose() {
    _hidePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showPreview(),
        onExit: (_) => _hidePreview(),
        child: widget.child,
      ),
    );
  }
}
