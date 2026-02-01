import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/utils/avatar_cropper.dart';
import 'settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import '../../sync/presentation/mobile_sync_settings_page.dart';
import 'widgets/mobile_settings_widgets.dart';

class MobileUserPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const MobileUserPage({super.key, this.onBack});
  @override
  ConsumerState<MobileUserPage> createState() => _MobileUserPageState();
}

class _MobileUserPageState extends ConsumerState<MobileUserPage> {
  final ImagePicker _picker = ImagePicker();
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final fluentTheme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = fluentTheme.brightness == fluent.Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.userSettings),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          MobileSettingsSection(
            title: l10n.userInfo,
            children: [
              MobileSettingsTile(
                leading: const Icon(Icons.badge_outlined),
                title: l10n.userName,
                subtitle: settingsState.userName.isNotEmpty
                    ? settingsState.userName
                    : l10n.user,
                trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onTap: () => _showTextEditor(
                  context,
                  l10n.userName,
                  settingsState.userName,
                  (value) => ref
                      .read(settingsProvider.notifier)
                      .setChatDisplaySettings(userName: value),
                ),
              ),
              MobileSettingsTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundImage: settingsState.userAvatar?.isNotEmpty == true
                      ? FileImage(File(settingsState.userAvatar!))
                      : null,
                  child: settingsState.userAvatar?.isNotEmpty != true
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                title: l10n.userAvatar,
                subtitle: l10n.clickToChangeAvatar,
                trailing: const Icon(Icons.image, size: 20, color: Colors.grey),
                onTap: () => _showAvatarPicker(isUser: true),
              ),
            ],
          ),
          
          MobileSettingsSection(
            title: l10n.aiInfo,
            children: [
              MobileSettingsTile(
                leading: const Icon(Icons.badge_outlined),
                title: l10n.aiName,
                subtitle: settingsState.llmName.isNotEmpty
                    ? settingsState.llmName
                    : 'Assistant',
                trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onTap: () => _showTextEditor(
                  context,
                  l10n.aiName,
                  settingsState.llmName,
                  (value) => ref
                      .read(settingsProvider.notifier)
                      .setChatDisplaySettings(llmName: value),
                ),
              ),
              MobileSettingsTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundImage: settingsState.llmAvatar?.isNotEmpty == true
                      ? FileImage(File(settingsState.llmAvatar!))
                      : null,
                  child: settingsState.llmAvatar?.isNotEmpty != true
                      ? const Icon(Icons.smart_toy, size: 20)
                      : null,
                ),
                title: l10n.aiAvatar,
                subtitle: l10n.clickToChangeAvatar,
                trailing: const Icon(Icons.image, size: 20, color: Colors.grey),
                onTap: () => _showAvatarPicker(isUser: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTextEditor(BuildContext context, String title, String currentValue,
      Function(String) onSave) async {
    final l10n = AppLocalizations.of(context)!;
    final newValue = await AuroraBottomSheet.showInput(
      context: context,
      title: '${l10n.edit}$title',
      initialValue: currentValue,
      hintText: '${l10n.pleaseEnter}$title',
    );
    if (newValue != null) {
      onSave(newValue);
    }
  }

  void _showAvatarPicker({required bool isUser}) {
    final l10n = AppLocalizations.of(context)!;
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(context, l10n.changeAvatarTitle(isUser ? l10n.user : 'AI')),
            const Divider(height: 1),
            AuroraBottomSheet.buildListItem(
              context: context,
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.camera),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, isUser);
              },
            ),
            AuroraBottomSheet.buildListItem(
              context: context,
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.photos),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, isUser);
              },
            ),
            if ((isUser
                    ? ref.read(settingsProvider).userAvatar
                    : ref.read(settingsProvider).llmAvatar) !=
                null)
              AuroraBottomSheet.buildListItem(
                context: context,
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(l10n.removeAvatar, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (isUser) {
                    ref.read(settingsProvider.notifier).setChatDisplaySettings(userAvatar: '');
                  } else {
                    ref.read(settingsProvider.notifier).setChatDisplaySettings(llmAvatar: '');
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, bool isUser) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        if (mounted) _showPermissionDialog('相机');
        return;
      }
      if (!status.isGranted) return;
    } else {
      if (PlatformUtils.isAndroid) {}
    }
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final croppedPath = await AvatarCropper.cropImage(context, image.path);
        if (croppedPath != null) {
          final appDir = await getApplicationDocumentsDirectory();
          final avatarDir = Directory('${appDir.path}${Platform.pathSeparator}avatars');
          if (!await avatarDir.exists()) {
            await avatarDir.create(recursive: true);
          }
          final fileName = 'avatar_${isUser ? "user" : "llm"}_${DateTime.now().millisecondsSinceEpoch}.png';
          final persistentPath = '${avatarDir.path}${Platform.pathSeparator}$fileName';
          await File(croppedPath).copy(persistentPath);

          if (isUser) {
            ref
                .read(settingsProvider.notifier)
                .setChatDisplaySettings(userAvatar: persistentPath);
          } else {
            ref
                .read(settingsProvider.notifier)
                .setChatDisplaySettings(llmAvatar: persistentPath);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.pickImageFailed}: $e')),
        );
      }
    }
  }

  void _showPermissionDialog(String name) async {
    final l10n = AppLocalizations.of(context)!;
    final localizedName = name == '相机' ? l10n.camera : name;
    final confirmed = await AuroraBottomSheet.showConfirm(
      context: context,
      title: l10n.permissionRequired(localizedName),
      content: l10n.permissionContent(localizedName),
      confirmText: l10n.goToSettings,
    );
    if (confirmed == true) {
      openAppSettings();
    }
  }


}


