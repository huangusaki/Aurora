import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:aurora/l10n/app_localizations.dart';

import '../domain/webdav_config.dart';
import '../domain/backup_options.dart';
import 'sync_provider.dart';
import 'widgets/backup_options_selector.dart';

class MobileSyncSettingsPage extends ConsumerStatefulWidget {
  const MobileSyncSettingsPage({super.key});

  @override
  ConsumerState<MobileSyncSettingsPage> createState() => _MobileSyncSettingsPageState();
}

class _MobileSyncSettingsPageState extends ConsumerState<MobileSyncSettingsPage> {
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
      remotePath: '/aurora_backup',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syncProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(syncProvider, (previous, next) {
      if ((previous?.isConfigLoaded != true) && next.isConfigLoaded) {
        _urlController.text = next.config.url;
        _usernameController.text = next.config.username;
        _passwordController.text = next.config.password;
      }
    });

    if (!state.isConfigLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cloudSync)),
        body: const Center(child: CircularProgressIndicator()),
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
      
      for (final entry in translations.entries) {
        if (message.startsWith(entry.key)) {
          return message.replaceFirst(entry.key, entry.value);
        }
      }
      return translations[message] ?? message;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cloudSync),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.isBusy)
            const LinearProgressIndicator(),
          if (state.error != null)
             MaterialBanner(
                 content: Text(translateMessage(state.error!), style: const TextStyle(color: Colors.white)),
                 backgroundColor: Colors.red,
                 actions: [TextButton(onPressed: () => ref.refresh(syncProvider), child: const Text('DISMISS', style: TextStyle(color: Colors.white)))],
             ),
           if (state.successMessage != null)
             MaterialBanner(
                 content: Text(translateMessage(state.successMessage!), style: const TextStyle(color: Colors.white)),
                 backgroundColor: Colors.green,
                 actions: [TextButton(onPressed: () => ref.refresh(syncProvider), child: const Text('OK', style: TextStyle(color: Colors.white)))],
             ),

          const SizedBox(height: 16),
          Text(l10n.webdavConfig, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: l10n.webdavUrl,
              hintText: l10n.webdavUrlHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: l10n.username,
              hintText: l10n.usernameHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: l10n.passwordOrToken,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isBusy ? null : () => ref.read(syncProvider.notifier).testConnection(),
                  child: Text(l10n.testConnection),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: state.isBusy ? null : () async {
                    BackupOptions selectedOptions = const BackupOptions();
                    final confirmed = await AuroraBottomSheet.show(
                      context: context,
                      builder: (ctx) => StatefulBuilder(
                        builder: (context, setModalState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AuroraBottomSheet.buildTitle(context, l10n.selectiveBackup),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: BackupOptionsSelector(
                                  options: selectedOptions,
                                  onChanged: (newOptions) {
                                    setModalState(() {
                                      selectedOptions = newOptions;
                                    });
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: selectedOptions.isNoneSelected 
                                      ? null 
                                      : () => Navigator.pop(ctx, true),
                                    child: Text(l10n.confirm),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                    );
                    
                    if (confirmed == true) {
                      ref.read(syncProvider.notifier).backup(options: selectedOptions);
                    }
                  },
                  child: Text(l10n.backupNow),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                 Text(l10n.cloudBackupList, style: theme.textTheme.titleMedium),
                 IconButton(
                     icon: const Icon(Icons.refresh),
                     onPressed: state.isBusy ? null : () => ref.read(syncProvider.notifier).refreshBackups(),
                 )
             ]
          ),
          if (state.remoteBackups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(l10n.noBackupsOrNotConnected, style: const TextStyle(color: Colors.grey))),
            )
          else
            ...state.remoteBackups.map((item) {
              final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.modified);
              final sizeMb = (item.size / 1024 / 1024).toStringAsFixed(2);
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(item.name),
                  subtitle: Text('$dateStr  •  $sizeMb MB'),
                  trailing: TextButton(
                    child: Text(l10n.restore),
                    onPressed: state.isBusy ? null : () async {
                        final confirmed = await AuroraBottomSheet.showConfirm(
                          context: context,
                          title: l10n.confirmRestore,
                          content: l10n.restoreWarning,
                          confirmText: l10n.confirmRestoreButton,
                        );
                        if (confirmed == true) {
                          ref.read(syncProvider.notifier).restore(item);
                        }
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
