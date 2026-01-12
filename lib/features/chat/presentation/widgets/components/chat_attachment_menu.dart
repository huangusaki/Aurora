import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aurora/l10n/app_localizations.dart';

class ChatAttachmentMenu {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onPickCamera,
    required VoidCallback onPickGallery,
    required VoidCallback onPickFile,
  }) async {
    final theme = fluent.FluentTheme.of(context);
    final isDark = theme.brightness == fluent.Brightness.dark;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildAttachmentOption(
                context,
                icon: Icons.camera_alt_outlined,
                label: AppLocalizations.of(context)!.takePhoto,
                onTap: () {
                  Navigator.pop(ctx);
                  onPickCamera();
                },
              ),
              _buildAttachmentOption(
                context,
                icon: Icons.photo_library_outlined,
                label: AppLocalizations.of(context)!.selectFromGallery,
                onTap: () {
                  Navigator.pop(ctx);
                  onPickGallery();
                },
              ),
              _buildAttachmentOption(
                context,
                icon: Icons.folder_open_outlined,
                label: AppLocalizations.of(context)!.selectFile,
                onTap: () {
                  Navigator.pop(ctx);
                  onPickFile();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 17)),
          ],
        ),
      ),
    );
  }
}
