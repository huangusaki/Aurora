import 'dart:async';

import 'package:aurora/features/sync/data/webdav_service.dart';
import 'package:aurora/features/sync/domain/remote_backup_file.dart';
import 'package:aurora/features/sync/domain/webdav_config.dart';
import 'package:aurora/features/sync/presentation/sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWebDavController {
  List<RemoteBackupFile> backups = [];
  final List<String> deletedNames = [];
  Object? deleteError;
  Completer<void>? deleteCompleter;
}

class _FakeWebDavService extends WebDavService {
  _FakeWebDavService(super.config, this.controller);

  final _FakeWebDavController controller;

  @override
  Future<bool> checkConnection() async => true;

  @override
  Future<List<RemoteBackupFile>> listBackups() async {
    return List<RemoteBackupFile>.from(controller.backups);
  }

  @override
  Future<void> deleteBackup(String remoteName) async {
    controller.deletedNames.add(remoteName);
    final completer = controller.deleteCompleter;
    if (completer != null) {
      await completer.future;
    }
    final error = controller.deleteError;
    if (error != null) {
      throw error;
    }
    controller.backups = controller.backups
        .where((backup) => backup.name != remoteName)
        .toList();
  }
}

void main() {
  const config = WebDavConfig(
    url: 'https://dav.example.com/dav/',
    username: 'demo',
    password: 'secret',
    remotePath: '/aurora_backup',
  );

  RemoteBackupFile buildBackup(String name) {
    return RemoteBackupFile(
      name: name,
      url: 'https://dav.example.com/dav/aurora_backup/$name',
      modified: DateTime(2026, 3, 14, 10, 0),
      size: 1024,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('deleteBackup removes the remote item and keeps success state',
      () async {
    final controller = _FakeWebDavController()
      ..backups = [buildBackup('a.zip'), buildBackup('b.zip')];
    final container = ProviderContainer(
      overrides: [
        webDavServiceFactoryProvider.overrideWithValue(
          (config) => _FakeWebDavService(config, controller),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(syncProvider.notifier);
    notifier.updateConfig(config);

    await notifier.refreshBackups();
    expect(container.read(syncProvider).remoteBackups, hasLength(2));

    await notifier.deleteBackup(buildBackup('a.zip'));

    final state = container.read(syncProvider);
    expect(controller.deletedNames, ['a.zip']);
    expect(state.isBusy, isFalse);
    expect(state.successMessage, SyncMessageKeys.deleteBackupSuccess);
    expect(state.remoteBackups.map((file) => file.name), ['b.zip']);
  });

  test('deleteBackup surfaces failures and clears busy state', () async {
    final controller = _FakeWebDavController()
      ..backups = [buildBackup('a.zip')]
      ..deleteError = Exception('boom');
    final container = ProviderContainer(
      overrides: [
        webDavServiceFactoryProvider.overrideWithValue(
          (config) => _FakeWebDavService(config, controller),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(syncProvider.notifier);
    notifier.updateConfig(config);

    await notifier.refreshBackups();
    await notifier.deleteBackup(buildBackup('a.zip'));

    final state = container.read(syncProvider);
    expect(controller.deletedNames, ['a.zip']);
    expect(state.isBusy, isFalse);
    expect(state.error, startsWith(SyncMessageKeys.deleteBackupFailed));
    expect(state.remoteBackups.map((file) => file.name), ['a.zip']);
  });

  test('deleteBackup ignores duplicate requests while busy', () async {
    final controller = _FakeWebDavController()
      ..backups = [buildBackup('a.zip')]
      ..deleteCompleter = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        webDavServiceFactoryProvider.overrideWithValue(
          (config) => _FakeWebDavService(config, controller),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(syncProvider.notifier);
    notifier.updateConfig(config);

    await notifier.refreshBackups();

    unawaited(notifier.deleteBackup(buildBackup('a.zip')));
    await Future<void>.delayed(Duration.zero);

    await notifier.deleteBackup(buildBackup('a.zip'));
    controller.deleteCompleter!.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.deletedNames, ['a.zip']);
  });
}
