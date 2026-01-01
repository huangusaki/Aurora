import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'settings_provider.dart';

/// Mobile User Profile Page - Display settings only (User/AI names & avatars)
class MobileUserPage extends ConsumerStatefulWidget {
  const MobileUserPage({super.key});

  @override
  ConsumerState<MobileUserPage> createState() => _MobileUserPageState();
}

class _MobileUserPageState extends ConsumerState<MobileUserPage> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final fluentTheme = fluent.FluentTheme.of(context);

    return Scaffold(
      backgroundColor: fluentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('用户设置'),
        backgroundColor: fluentTheme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // --- User Section ---
          _SectionHeader(title: '用户信息', icon: Icons.person_outline),
          
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('用户名称'),
            subtitle: Text(settingsState.userName.isNotEmpty ? settingsState.userName : '用户'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showTextEditor(
              context, 
              '用户名称', 
              settingsState.userName,
              (value) => ref.read(settingsProvider.notifier).setChatDisplaySettings(userName: value),
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
            title: const Text('用户头像'),
            subtitle: const Text('点击更换头像'),
            trailing: const Icon(Icons.image),
            onTap: () => _pickAvatar(isUser: true),
          ),

          const Divider(),

          // --- AI Section ---
          _SectionHeader(title: 'AI 信息', icon: Icons.smart_toy_outlined),
          
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('AI 名称'),
            subtitle: Text(settingsState.llmName.isNotEmpty ? settingsState.llmName : 'Assistant'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showTextEditor(
              context, 
              'AI 名称', 
              settingsState.llmName,
              (value) => ref.read(settingsProvider.notifier).setChatDisplaySettings(llmName: value),
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
            title: const Text('AI 头像'),
            subtitle: const Text('点击更换头像'),
            trailing: const Icon(Icons.image),
            onTap: () => _pickAvatar(isUser: false),
          ),
        ],
      ),
    );
  }

  void _showTextEditor(BuildContext context, String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑$title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '请输入$title',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar({required bool isUser}) async {
    final result = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp']),
      ],
    );
    if (result != null) {
      if (isUser) {
        ref.read(settingsProvider.notifier).setChatDisplaySettings(userAvatar: result.path);
      } else {
        ref.read(settingsProvider.notifier).setChatDisplaySettings(llmAvatar: result.path);
      }
    }
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
