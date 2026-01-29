import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aurora/l10n/app_localizations.dart';

import '../domain/webdav_config.dart';
import '../domain/backup_options.dart';
import 'sync_provider.dart';
import 'widgets/backup_options_dialog.dart';

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
    final l10n = AppLocalizations.of(context)!;

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

    // Helper to translate message keys
    String translateMessage(String message) {
      final translations = {
        SyncMessageKeys.connectionSuccess: l10n.connectionSuccess,
        SyncMessageKeys.connectionFailed: l10n.connectionFailed,
        SyncMessageKeys.connectionError: l10n.connectionError,
        SyncMessageKeys.backupSuccess: l10n.backupSuccess,
        SyncMessageKeys.backupFailed: l10n.backupFailed,
        SyncMessageKeys.restoreSuccess: l10n.restoreSuccess,
        SyncMessageKeys.restoreFailed: l10n.restoreFailed,
        SyncMessageKeys.fetchBackupListFailed: l10n.fetchBackupListFailed,
      };
      
      // Check if message starts with a known key
      for (final entry in translations.entries) {
        if (message.startsWith(entry.key)) {
          return message.replaceFirst(entry.key, entry.value);
        }
      }
      return translations[message] ?? message;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.cloudSync, style: theme.typography.subtitle),
            if (state.isBusy) const ProgressRing(strokeWidth: 2, activeColor: null /* default accent */),
          ],
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: l10n.webdavUrl,
          child: TextBox(
            controller: _urlController,
            placeholder: l10n.webdavUrlHint,
            onChanged: (_) => _save(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InfoLabel(
                label: l10n.username,
                child: TextBox(
                  controller: _usernameController,
                  placeholder: l10n.usernameHint,
                  onChanged: (_) => _save(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoLabel(
                label: l10n.passwordOrToken,
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
              child: Text(l10n.testConnection),
            ),
            const SizedBox(width: 12),
            Button(
              onPressed: state.isBusy ? null : () async {
                final options = await showDialog<BackupOptions>(
                  context: context,
                  builder: (context) => BackupOptionsDialog(title: l10n.selectiveBackup),
                );
                if (options != null) {
                  ref.read(syncProvider.notifier).backup(options: options);
                }
              },
              child: Text(l10n.backupNow),
            ),
          ],
        ),
        if (state.error != null)
           Padding(
             padding: const EdgeInsets.only(top: 8.0),
             child: Text(translateMessage(state.error!), style: TextStyle(color: Colors.red)),
           ),
        if (state.successMessage != null)
           Padding(
             padding: const EdgeInsets.only(top: 8.0),
             child: Text(translateMessage(state.successMessage!), style: TextStyle(color: Colors.green)),
           ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(l10n.cloudBackupList, style: theme.typography.bodyStrong),
        const SizedBox(height: 8),
        if (state.remoteBackups.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(l10n.noBackupsOrNotConnected, style: const TextStyle(color: Colors.grey)),
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
                    child: Text(l10n.restore),
                    onPressed: state.isBusy ? null : () async {
                        showDialog(context: context, builder: (context) {
                            return ContentDialog(
                                title: Text(l10n.confirmRestore),
                                content: Text(l10n.restoreWarning),
                                actions: [
                                    Button(child: Text(l10n.cancel), onPressed: () => Navigator.pop(context)),
                                    FilledButton(child: Text(l10n.confirmRestoreButton), onPressed: () {
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
