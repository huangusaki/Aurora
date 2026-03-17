import 'dart:io';
import 'package:flutter/material.dart';

const int _hoverPreviewCacheWidth = 468;
const int _hoverPreviewCacheHeight = 400;

class HoverAttachmentPreview extends StatefulWidget {
  final String filePath;
  final Widget child;
  const HoverAttachmentPreview({
    super.key,
    required this.filePath,
    required this.child,
  });
  @override
  State<HoverAttachmentPreview> createState() => _HoverAttachmentPreviewState();
}

class _HoverAttachmentPreviewState extends State<HoverAttachmentPreview> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late Future<String> _fileSizeFuture;

  @override
  void initState() {
    super.initState();
    _fileSizeFuture = _loadFileSize(widget.filePath);
  }

  @override
  void didUpdateWidget(covariant HoverAttachmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _fileSizeFuture = _loadFileSize(widget.filePath);
    }
  }

  void _showPreview() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hidePreview() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final path = widget.filePath.toLowerCase();
    final isImage = path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif') ||
        path.endsWith('.bmp');
    final isAudio = path.endsWith('.mp3') ||
        path.endsWith('.wav') ||
        path.endsWith('.m4a') ||
        path.endsWith('.flac') ||
        path.endsWith('.ogg') ||
        path.endsWith('.opus');
    final isVideo = path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.webm') ||
        path.endsWith('.mkv');
    final isPdf = path.endsWith('.pdf');

    IconData iconData = Icons.insert_drive_file;
    if (isAudio) iconData = Icons.audiotrack;
    if (isVideo) iconData = Icons.videocam;
    if (isPdf) iconData = Icons.picture_as_pdf;

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
                    child: isImage
                        ? ColoredBox(
                            color: Colors.white.withValues(alpha: 0.06),
                            child: Image.file(
                              File(widget.filePath),
                              height: 200,
                              width: 234,
                              fit: BoxFit.contain,
                              cacheWidth: _hoverPreviewCacheWidth,
                              cacheHeight: _hoverPreviewCacheHeight,
                              filterQuality: FilterQuality.low,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildIconPreview(Icons.broken_image),
                            ),
                          )
                        : _buildIconPreview(iconData),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.filePath.split(Platform.pathSeparator).last,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  FutureBuilder<String>(
                    future: _fileSizeFuture,
                    builder: (context, snapshot) {
                      final text = snapshot.data ?? '';
                      if (text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPreview(IconData icon) {
    return Container(
      height: 200,
      width: 234,
      color: Colors.grey.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 64),
    );
  }

  Future<String> _loadFileSize(String path) async {
    try {
      final file = File(path);
      final stat = await file.stat();
      if (stat.type == FileSystemEntityType.file) {
        final bytes = stat.size;
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) {
          return '${(bytes / 1024).toStringAsFixed(1)} KB';
        }
        if (bytes < 1024 * 1024 * 1024) {
          return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
        return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
