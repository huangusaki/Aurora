import 'dart:io';

import 'package:aurora/features/history/presentation/widgets/hover_image_preview.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

class ChatAttachmentPill extends StatelessWidget {
  const ChatAttachmentPill({
    super.key,
    required this.path,
    required this.theme,
    this.onDelete,
  });

  final String path;
  final fluent.FluentThemeData theme;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final pathLower = path.toLowerCase();
    IconData iconData = AuroraIcons.file;
    if (pathLower.endsWith('.mp3') ||
        pathLower.endsWith('.wav') ||
        pathLower.endsWith('.m4a') ||
        pathLower.endsWith('.flac') ||
        pathLower.endsWith('.ogg') ||
        pathLower.endsWith('.opus')) {
      iconData = AuroraIcons.audio;
    } else if (pathLower.endsWith('.mp4') ||
        pathLower.endsWith('.mov') ||
        pathLower.endsWith('.avi') ||
        pathLower.endsWith('.webm') ||
        pathLower.endsWith('.mkv')) {
      iconData = AuroraIcons.video;
    } else if (pathLower.endsWith('.pdf')) {
      iconData = AuroraIcons.pdf;
    }

    return HoverAttachmentPreview(
      filePath: path,
      child: MouseRegion(
        cursor: onDelete == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 14, color: theme.accentColor),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    path.split(Platform.pathSeparator).last,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  Icon(AuroraIcons.close, size: 8, color: theme.accentColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
