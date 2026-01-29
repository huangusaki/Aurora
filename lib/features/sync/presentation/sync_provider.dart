import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/presentation/settings_provider.dart';
import '../../chat/presentation/topic_provider.dart';
import '../../chat/presentation/chat_provider.dart';
import '../../studio/presentation/novel/novel_provider.dart';
import '../application/backup_service.dart';
import '../data/webdav_service.dart';
import '../domain/backup_entity.dart';
import '../domain/backup_options.dart';
import '../domain/remote_backup_file.dart';
import '../domain/webdav_config.dart';

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

final backupServiceProvider = Provider<BackupService>((ref) {
   // Access Storage from existing SettingsProvider
   final storage = ref.read(settingsProvider.notifier).storage;
   return BackupService(storage);
});

// Message keys for localization in UI layer
class SyncMessageKeys {
  static const connectionSuccess = 'connectionSuccess';
  static const connectionFailed = 'connectionFailed';
  static const connectionError = 'connectionError';
  static const backupSuccess = 'backupSuccess';
  static const backupFailed = 'backupFailed';
  static const restoreSuccess = 'restoreSuccess';
  static const restoreFailed = 'restoreFailed';
  static const fetchBackupListFailed = 'fetchBackupListFailed';
}

class SyncState {
  final WebDavConfig config;
  final bool isBusy;
  final String? error;
  final String? successMessage;
  final List<RemoteBackupFile> remoteBackups;
  final bool isConfigLoaded;

  SyncState({
    this.config = const WebDavConfig(),
    this.isBusy = false,
    this.error,
    this.successMessage,
    this.remoteBackups = const [],
    this.isConfigLoaded = false,
  });
  
  SyncState copyWith({
    WebDavConfig? config,
    bool? isBusy,
    String? error,
    String? successMessage,
    List<RemoteBackupFile>? remoteBackups,
    bool? isConfigLoaded,
  }) {
    return SyncState(
      config: config ?? this.config,
      isBusy: isBusy ?? this.isBusy,
      error: error,
      successMessage: successMessage,
      remoteBackups: remoteBackups ?? this.remoteBackups,
      isConfigLoaded: isConfigLoaded ?? this.isConfigLoaded,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref ref;
  
  SyncNotifier(this.ref) : super(SyncState()) {
      _loadConfig();
  }

  Future<void> _loadConfig() async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('webdav_config');
      if (jsonStr != null) {
          try {
              final json = jsonDecode(jsonStr);
              state = state.copyWith(
                  config: WebDavConfig.fromJson(json),
                  isConfigLoaded: true,
              );
              return;
          } catch (_) {}
      }
      state = state.copyWith(isConfigLoaded: true);
  }

  Future<void> _saveConfig(WebDavConfig config) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('webdav_config', jsonEncode(config.toJson()));
  }
  
  void updateConfig(WebDavConfig config) {
      state = state.copyWith(config: config);
      _saveConfig(config);
  }

  Future<void> testConnection() async {
      state = state.copyWith(isBusy: true, error: null, successMessage: null);
      try {
          final service = WebDavService(state.config);
          final success = await service.checkConnection();
          if (success) {
              state = state.copyWith(isBusy: false, successMessage: SyncMessageKeys.connectionSuccess);
              refreshBackups();
          } else {
              state = state.copyWith(isBusy: false, error: SyncMessageKeys.connectionFailed);
          }
      } catch (e) {
          state = state.copyWith(isBusy: false, error: '${SyncMessageKeys.connectionError}: $e');
      }
  }

  Future<void> backup({BackupOptions options = const BackupOptions()}) async {
      state = state.copyWith(isBusy: true, error: null, successMessage: null);
      try {
        await ref.read(backupServiceProvider).backup(state.config, options: options);
        state = state.copyWith(isBusy: false, successMessage: SyncMessageKeys.backupSuccess);
        refreshBackups();
      } catch(e) {
        state = state.copyWith(isBusy: false, error: '${SyncMessageKeys.backupFailed}: $e');
      }
  }

  Future<void> restore(RemoteBackupFile file) async {
      state = state.copyWith(isBusy: true, error: null, successMessage: null);
      try {
          await ref.read(backupServiceProvider).restore(state.config, file.name);
          await refreshAllStates();
          state = state.copyWith(isBusy: false, successMessage: SyncMessageKeys.restoreSuccess);
      } catch(e) {
          state = state.copyWith(isBusy: false, error: '${SyncMessageKeys.restoreFailed}: $e');
      }
  }

  Future<void> refreshAllStates() async {
      // Refresh all states after restore or local import
      await ref.read(settingsProvider.notifier).refreshSettings();
      await ref.read(novelProvider.notifier).loadState();
      ref.read(sessionsProvider.notifier).loadSessions();
      ref.invalidate(topicsProvider);
      ref.invalidate(chatSessionManagerProvider);
  }

  Future<void> refreshBackups() async {
      state = state.copyWith(isBusy: true, error: null);
      try {
          final service = WebDavService(state.config);
          final backups = await service.listBackups();
          state = state.copyWith(isBusy: false, remoteBackups: backups);
      } catch (e) {
           state = state.copyWith(isBusy: false, error: '${SyncMessageKeys.fetchBackupListFailed}: $e');
      }
  }
}

