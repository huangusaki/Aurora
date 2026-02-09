import 'package:aurora/features/cleaner/data/windows_cleaner_rule_pack.dart';
import 'package:aurora/features/cleaner/domain/cleaner_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowsCleanerRulePack', () {
    test('matches windows.old entries as stale candidates', () {
      final match = WindowsCleanerRulePack.matchPath(
        r'C:\Windows.old\Users\demo\AppData\Local\Temp\foo.bin',
      );

      expect(match, isNotNull);
      expect(match!.kind, CleanerCandidateKind.staleFile);
      expect(match.tags, contains('windows_rule:windows_old'));
      expect(match.tags, contains('windows_group:stale'));
    });

    test('matches QQ log/temp files as temporary candidates', () {
      final match = WindowsCleanerRulePack.matchPath(
        r'C:\Users\demo\AppData\Roaming\Tencent\TXSSO\SetupLogs\a.log',
      );

      expect(match, isNotNull);
      expect(match!.kind, CleanerCandidateKind.temporary);
      expect(match.tags, contains('windows_rule:qq_logs'));
      expect(match.tags, contains('windows_group:temporary'));
    });

    test('returns null for non-rule paths', () {
      final match = WindowsCleanerRulePack.matchPath(
        r'C:\Users\demo\Documents\Project\report.docx',
      );

      expect(match, isNull);
    });

    test('builds root list from environment with dedupe', () {
      final roots = WindowsCleanerRulePack.buildDefaultRootPathsFromEnvironment(
        const {
          'SystemRoot': r'C:\Windows',
          'SystemDrive': 'C:',
          'LOCALAPPDATA': r'C:\Users\demo\AppData\Local',
          'APPDATA': r'C:\Users\demo\AppData\Roaming',
          'USERPROFILE': r'C:\Users\demo',
          'ProgramData': r'C:\ProgramData',
          'TEMP': r'C:\Users\demo\AppData\Local\Temp',
          'TMP': r'C:\Users\demo\AppData\Local\Temp',
        },
        isWindows: true,
      );

      expect(
        roots
            .where(
              (path) =>
                  path.toLowerCase() ==
                  r'c:\users\demo\appdata\local\temp'.toLowerCase(),
            )
            .length,
        1,
      );
      expect(roots, contains(r'C:\ProgramData\Package Cache'));
      expect(roots, contains(r'C:\Windows\SoftwareDistribution\Download'));
      expect(roots, contains(r'C:\Users\demo\.nuget'));
    });
  });
}
