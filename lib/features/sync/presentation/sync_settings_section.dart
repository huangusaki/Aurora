import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/webdav_config.dart';
import 'sync_provider.dart';

class SyncSettingsSection extends ConsumerStatefulWidget {
  const SyncSettingsSection({super.key});

  @override
  ConsumerState<SyncSettingsSection> createState() => _SyncSettingsSectionState();
}

class _SyncSettingsSectionState extends ConsumerState<SyncSettingsSection> {
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(syncProvider).config;
    _urlController = TextEditingController(text: config.url);
    _usernameController = TextEditingController(text: config.username);
    _passwordController = TextEditingController(text: config.password);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(syncProvider.notifier).updateConfig(WebDavConfig(
      url: _urlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      remotePath: '/aurora_backup', // Fixed for now
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syncProvider);
    final theme = FluentTheme.of(context);

    ref.listen(syncProvider, (previous, next) {
      if ((previous?.isConfigLoaded != true) && next.isConfigLoaded) {
        _urlController.text = next.config.url;
        _usernameController.text = next.config.username;
        _passwordController.text = next.config.password;
      }
    });

    if (!state.isConfigLoaded) {
       return const SizedBox(
         height: 300,
         child: Center(child: ProgressRing()),
       );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('WebDAV 云同步', style: theme.typography.subtitle),
            if (state.isBusy) const ProgressRing(strokeWidth: 2, activeColor: null /* default accent */),
          ],
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'WebDAV 地址 (URL)',
          child: TextBox(
            controller: _urlController,
            placeholder: 'https://dav.jianguoyun.com/dav/',
            onChanged: (_) => _save(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InfoLabel(
                label: '用户名',
                child: TextBox(
                  controller: _usernameController,
                  placeholder: 'email@example.com',
                  onChanged: (_) => _save(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoLabel(
                label: '密码 / 应用授权码',
                child: TextBox(
                  controller: _passwordController,
                  placeholder: 'Password',
                  obscureText: !_showPassword,
                  suffix: IconButton(
                    icon: Icon(_showPassword ? FluentIcons.hide : FluentIcons.red_eye),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  onChanged: (_) => _save(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton(
              onPressed: state.isBusy ? null : () => ref.read(syncProvider.notifier).testConnection(),
              child: const Text('测试连接 & 刷新'),
            ),
            const SizedBox(width: 12),
            Button(
              onPressed: state.isBusy ? null : () => ref.read(syncProvider.notifier).backup(),
              child: const Text('立即备份'),
            ),
          ],
        ),
        if (state.error != null)
           Padding(
             padding: const EdgeInsets.only(top: 8.0),
             child: Text(state.error!, style: TextStyle(color: Colors.red)),
           ),
        if (state.successMessage != null)
           Padding(
             padding: const EdgeInsets.only(top: 8.0),
             child: Text(state.successMessage!, style: TextStyle(color: Colors.green)),
           ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text('云端备份列表', style: theme.typography.bodyStrong),
        const SizedBox(height: 8),
        if (state.remoteBackups.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('暂无备份或未连接', style: TextStyle(color: Colors.grey)),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: state.remoteBackups.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = state.remoteBackups[index];
                final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.modified);
                final sizeMb = (item.size / 1024 / 1024).toStringAsFixed(2);
                
                return ListTile(
                  leading: const Icon(FluentIcons.folder_open),
                  title: Text(item.name),
                  subtitle: Text('$dateStr  •  $sizeMb MB'),
                  trailing: Button(
                    child: const Text('恢复'),
                    onPressed: state.isBusy ? null : () async {
                        showDialog(context: context, builder: (context) {
                            return ContentDialog(
                                title: const Text('确认恢复?'),
                                content: const Text('恢复操作将尝试合并云端数据到本地。如果存在冲突可能会更新本地数据。建议先备份当前数据。'),
                                actions: [
                                    Button(child: const Text('取消'), onPressed: () => Navigator.pop(context)),
                                    FilledButton(child: const Text('确定恢复'), onPressed: () {
                                        Navigator.pop(context);
                                        ref.read(syncProvider.notifier).restore(item);
                                    }),
                                ],
                            );
                        });
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
