import 'dart:convert';

import 'package:aurora/features/settings/data/settings_storage.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/sync/domain/remote_backup_file.dart';
import 'package:aurora/features/sync/domain/webdav_config.dart';
import 'package:aurora/features/sync/presentation/mobile_sync_settings_page.dart';
import 'package:aurora/features/sync/presentation/sync_provider.dart';
import 'package:aurora/features/sync/presentation/sync_settings_section.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier()
      : super(
          storage: SettingsStorage(),
          initialProviders: [ProviderConfig(id: 'p1', name: 'Provider A')],
          initialActiveId: 'p1',
        );

  @override
  Future<void> loadPresets() async {}
}

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier(super.ref, {required SyncState initialState}) {
    state = initialState;
  }

  RemoteBackupFile? deletedFile;

  @override
  Future<void> refreshBackups({
    bool preserveBusy = false,
    String? successMessage,
  }) async {}

  @override
  Future<void> restore(RemoteBackupFile file) async {}

  @override
  Future<void> deleteBackup(RemoteBackupFile file) async {
    deletedFile = file;
  }
}

void main() {
  const config = WebDavConfig(
    url: 'https://dav.example.com/dav/',
    username: 'demo',
    password: 'secret',
    remotePath: '/aurora_backup',
  );
  final backup = RemoteBackupFile(
    name: 'aurora_backup_20260314.zip',
    url: 'https://dav.example.com/dav/aurora_backup/aurora_backup_20260314.zip',
    modified: DateTime(2026, 3, 14, 10, 30),
    size: 2048,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'webdav_config': jsonEncode({
        'url': config.url,
        'username': config.username,
        'password': config.password,
        'remotePath': config.remotePath,
      }),
    });
  });

  testWidgets('desktop backup list requires confirmation before delete',
      (tester) async {
    late _FakeSyncNotifier syncNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncProvider.overrideWith((ref) {
            syncNotifier = _FakeSyncNotifier(
              ref,
              initialState: SyncState(
                config: config,
                isConfigLoaded: true,
                remoteBackups: [backup],
              ),
            );
            return syncNotifier;
          }),
        ],
        child: FluentApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NavigationView(
            content: ScaffoldPage(
              content: SyncSettingsSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();

    expect(syncNotifier.deletedFile, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(syncNotifier.deletedFile, isNull);

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(syncNotifier.deletedFile?.name, backup.name);
  });

  testWidgets('mobile backup list requires confirmation before delete',
      (tester) async {
    late _FakeSyncNotifier syncNotifier;
    final settingsNotifier = _FakeSettingsNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => settingsNotifier),
          syncProvider.overrideWith((ref) {
            syncNotifier = _FakeSyncNotifier(
              ref,
              initialState: SyncState(
                config: config,
                isConfigLoaded: true,
                remoteBackups: [backup],
              ),
            );
            return syncNotifier;
          }),
        ],
        child: material.MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MobileSyncSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();

    expect(syncNotifier.deletedFile, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(syncNotifier.deletedFile, isNull);

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(syncNotifier.deletedFile?.name, backup.name);
  });
}
