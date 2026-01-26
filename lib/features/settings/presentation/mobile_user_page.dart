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
import '../../sync/presentation/mobile_sync_settings_page.dart';

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
    return Scaffold(
      backgroundColor: fluentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.userSettings),
        backgroundColor: fluentTheme.scaffoldBackgroundColor,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        elevation: 0,
      ),
      body: ListView(
        children: [


          _SectionHeader(title: l10n.userInfo, icon: Icons.person_outline),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(l10n.userName),
            subtitle: Text(settingsState.userName.isNotEmpty
                ? settingsState.userName
                : l10n.user),
            trailing: const Icon(Icons.edit),
            onTap: () => _showTextEditor(
              context,
              l10n.userName,
              settingsState.userName,
              (value) => ref
                  .read(settingsProvider.notifier)
                  .setChatDisplaySettings(userName: value),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: settingsState.userAvatar?.isNotEmpty == true
                  ? FileImage(File(settingsState.userAvatar!))
                  : null,
              child: settingsState.userAvatar?.isNotEmpty != true
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            title: Text(l10n.userAvatar),
            subtitle: Text(l10n.clickToChangeAvatar),
            trailing: const Icon(Icons.image),
            onTap: () => _showAvatarPicker(isUser: true),
          ),
          const Divider(),
          _SectionHeader(title: l10n.aiInfo, icon: Icons.smart_toy_outlined),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(l10n.aiName),
            subtitle: Text(settingsState.llmName.isNotEmpty
                ? settingsState.llmName
                : 'Assistant'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showTextEditor(
              context,
              l10n.aiName,
              settingsState.llmName,
              (value) => ref
                  .read(settingsProvider.notifier)
                  .setChatDisplaySettings(llmName: value),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: settingsState.llmAvatar?.isNotEmpty == true
                  ? FileImage(File(settingsState.llmAvatar!))
                  : null,
              child: settingsState.llmAvatar?.isNotEmpty != true
                  ? const Icon(Icons.smart_toy, size: 20)
                  : null,
            ),
            title: Text(l10n.aiAvatar),
            subtitle: Text(l10n.clickToChangeAvatar),
            trailing: const Icon(Icons.image),
            onTap: () => _showAvatarPicker(isUser: false),
          ),
        ],
      ),
    );
  }

  void _showTextEditor(BuildContext context, String title, String currentValue,
      Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${l10n.edit}$title', style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '${l10n.pleaseEnter}$title',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        onSave(controller.text);
                        Navigator.pop(ctx);
                      },
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarPicker({required bool isUser}) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.changeAvatarTitle(isUser ? l10n.user : 'AI'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(l10n.camera),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera, isUser);
                  },
                ),
                ListTile(
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
                  ListTile(
                    leading:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    title: Text(l10n.removeAvatar,
                        style: const TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isUser) {
                        ref
                            .read(settingsProvider.notifier)
                            .setChatDisplaySettings(userAvatar: '');
                      } else {
                        ref
                            .read(settingsProvider.notifier)
                            .setChatDisplaySettings(llmAvatar: '');
                      }
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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
      if (Platform.isAndroid) {}
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

  void _showPermissionDialog(String name) {
    final l10n = AppLocalizations.of(context)!;
    final localizedName = name == '相机' ? l10n.camera : name;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.permissionRequired(localizedName)),
        content: Text(l10n.permissionContent(localizedName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(l10n.goToSettings),
          ),
        ],
      ),
    );
  }


}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
