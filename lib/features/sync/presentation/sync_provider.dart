import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/presentation/settings_provider.dart';
import '../application/backup_service.dart';
import '../data/webdav_service.dart';
import '../domain/webdav_config.dart';
import '../domain/remote_backup_file.dart';

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

final backupServiceProvider = Provider<BackupService>((ref) {
   // Access Storage from existing SettingsProvider
   final storage = ref.read(settingsProvider.notifier).storage;
   return BackupService(storage);
});

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
              state = state.copyWith(isBusy: false, successMessage: '连接成功');
              refreshBackups();
          } else {
              state = state.copyWith(isBusy: false, error: '连接失败: 请检查配置');
          }
      } catch (e) {
          state = state.copyWith(isBusy: false, error: '连接异常: $e');
      }
  }

  Future<void> backup() async {
      state = state.copyWith(isBusy: true, error: null, successMessage: null);
      try {
        await ref.read(backupServiceProvider).backup(state.config);
        state = state.copyWith(isBusy: false, successMessage: '备份上传成功');
        refreshBackups();
      } catch(e) {
        state = state.copyWith(isBusy: false, error: '备份失败: $e');
      }
  }

  Future<void> restore(RemoteBackupFile file) async {
      state = state.copyWith(isBusy: true, error: null, successMessage: null);
      try {
          await ref.read(backupServiceProvider).restore(state.config, file.name);
          state = state.copyWith(isBusy: false, successMessage: '数据恢复成功');
      } catch(e) {
          state = state.copyWith(isBusy: false, error: '恢复失败: $e');
      }
  }

  Future<void> refreshBackups() async {
      state = state.copyWith(isBusy: true, error: null);
      try {
          final service = WebDavService(state.config);
          final backups = await service.listBackups();
          state = state.copyWith(isBusy: false, remoteBackups: backups);
      } catch (e) {
           state = state.copyWith(isBusy: false, error: '获取备份列表失败: $e');
      }
  }
}
