import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/utils/avatar_cropper.dart';
import 'settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';

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
          _SectionHeader(
              title: l10n.displaySettings, icon: Icons.palette_outlined),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(settingsState.language == 'zh' ? '简体中文' : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text(l10n.language),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        ref.read(settingsProvider.notifier).setLanguage('zh');
                        Navigator.pop(context);
                      },
                      child: const Text('简体中文'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        ref.read(settingsProvider.notifier).setLanguage('en');
                        Navigator.pop(context);
                      },
                      child: const Text('English'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          _SectionHeader(
              title: l10n.chatExperience, icon: Icons.chat_bubble_outline),
          SwitchListTile(
            title: Text(l10n.smartTopicGeneration),
            subtitle: Text(l10n.smartTopicDescription),
            value: settingsState.enableSmartTopic,
            onChanged: (bool value) {
              ref
                  .read(settingsProvider.notifier)
                  .toggleSmartTopicEnabled(value);
            },
          ),
          if (settingsState.enableSmartTopic)
            ListTile(
              title: Text(l10n.generationModel),
              subtitle: Text(settingsState.topicGenerationModel == null
                  ? l10n.notSelectedFallback
                  : settingsState.topicGenerationModel!.split('@').last),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showModelPicker(context, settingsState);
              },
            ),
          const Divider(),
          const Divider(),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.edit}$title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '${l10n.pleaseEnter}$title',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
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
          if (isUser) {
            ref
                .read(settingsProvider.notifier)
                .setChatDisplaySettings(userAvatar: croppedPath);
          } else {
            ref
                .read(settingsProvider.notifier)
                .setChatDisplaySettings(llmAvatar: croppedPath);
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

  void _showModelPicker(BuildContext context, SettingsState settings) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(l10n.selectGenerationModel,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final provider in settings.providers)
                      if (provider.isEnabled)
                        for (final model in provider.models)
                          ListTile(
                            title: Text(model),
                            subtitle: Text(provider.name),
                            selected: settings.topicGenerationModel ==
                                '${provider.id}@$model',
                            onTap: () {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setTopicGenerationModel(
                                      '${provider.id}@$model');
                              Navigator.pop(context);
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
