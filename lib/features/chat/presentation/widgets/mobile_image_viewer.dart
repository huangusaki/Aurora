import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';

class MobileImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback? onClose;
  const MobileImageViewer({
    super.key,
    required this.imageBytes,
    this.onClose,
  });
  @override
  State<MobileImageViewer> createState() => _MobileImageViewerState();
}

class _MobileImageViewerState extends State<MobileImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _showToolbar = true;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleToolbar() {
    setState(() {
      _showToolbar = !_showToolbar;
    });
  }

  void _onDoubleTap() {
    Matrix4 currentMatrix = _transformationController.value;
    double currentScale = currentMatrix.getMaxScaleOnAxis();
    Matrix4 endMatrix;
    if (currentScale > 1.2) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix = Matrix4.identity()..scaleByDouble(2.0, 2.0, 2.0, 1.0);
    }
    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeOut).animate(_animationController));
    _animationController.forward(from: 0);
  }

  Future<void> _handleCopy(BuildContext context) async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return;
      final item = DataWriterItem();
      item.add(Formats.png(widget.imageBytes));
      await clipboard.write([item]);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        showAuroraNotice(
          context,
          l10n.copied,
          icon: Icons.copy_rounded,
        );
      }
    } catch (e) {
      debugPrint('Copy error: $e');
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(widget.imageBytes);
      await Gal.putImage(tempPath);
      await tempFile.delete();
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        showAuroraNotice(
          context,
          l10n.imageSaved,
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        showAuroraNotice(
          context,
          '${l10n.imageSaveFailed}: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _rotateClockwise() {
    setState(() {
      _rotation += math.pi / 2;
    });
  }

  double _rotation = 0.0;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showToolbar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onClose ?? () => Navigator.pop(context),
                tooltip: l10n.back,
              ),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _toggleToolbar,
            onDoubleTap: _onDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: Transform.rotate(
                  angle: _rotation,
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          if (_showToolbar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.rotate_right, color: Colors.white),
                        onPressed: _rotateClockwise,
                        tooltip: l10n.rotate,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () => _handleCopy(context),
                        tooltip: l10n.copy,
                      ),
                      IconButton(
                        icon: const Icon(Icons.save_alt, color: Colors.white),
                        onPressed: () => _handleSave(context),
                        tooltip: l10n.save,
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
