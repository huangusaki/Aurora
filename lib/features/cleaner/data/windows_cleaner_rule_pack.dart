import 'dart:io';

import '../domain/cleaner_models.dart';

class WindowsCleanerRuleMatch {
  final CleanerCandidateKind kind;
  final List<String> tags;

  const WindowsCleanerRuleMatch({
    required this.kind,
    required this.tags,
  });
}

class WindowsCleanerRulePack {
  const WindowsCleanerRulePack._();

  static bool get isSupported => Platform.isWindows;

  static List<String> defaultRootPaths() {
    return buildDefaultRootPathsFromEnvironment(
      Platform.environment,
      isWindows: Platform.isWindows,
    );
  }

  static List<String> buildDefaultRootPathsFromEnvironment(
    Map<String, String> environment, {
    required bool isWindows,
  }) {
    if (!isWindows) {
      return const [];
    }

    final systemRoot = _env(
          environment,
          'SystemRoot',
        ) ??
        r'C:\Windows';
    final systemDrive = _env(
          environment,
          'SystemDrive',
        ) ??
        _extractDrive(systemRoot) ??
        'C:';
    final localAppData = _env(environment, 'LOCALAPPDATA');
    final appData = _env(environment, 'APPDATA');
    final userProfile = _env(environment, 'USERPROFILE');
    final programData = _env(environment, 'ProgramData');
    final temp = _env(environment, 'TEMP');
    final tmp = _env(environment, 'TMP');

    final roots = <String?>[
      temp,
      tmp,
      _joinWin(localAppData, 'Temp'),
      _joinWin(localAppData, r'CrashDumps'),
      _joinWin(localAppData, r'Microsoft\Windows\Explorer'),
      _joinWin(localAppData, r'Microsoft\Windows\INetCache'),
      _joinWin(localAppData, r'Microsoft\Windows\WER'),
      _joinWin(localAppData, r'Packages'),
      _joinWin(localAppData, r'NuGet\v3-cache'),
      _joinWin(localAppData, r'DBG'),
      _joinWin(localAppData, r'Microsoft\Web Platform Installer'),
      _joinWin(appData, 'Tencent'),
      _joinWin(appData, 'YY'),
      _joinWin(userProfile, '.nuget'),
      _joinWin(systemRoot, 'Temp'),
      _joinWin(systemRoot, 'Prefetch'),
      _joinWin(systemRoot, 'Logs'),
      _joinWin(systemRoot, r'WinSxS\Temp'),
      _joinWin(systemRoot, r'SoftwareDistribution\Download'),
      _joinWin(systemRoot, r'SoftwareDistribution\DeliveryOptimization'),
      _joinWin(systemRoot, r'LiveKernelReports'),
      _joinWin(systemDrive, 'Windows.old'),
      _joinWin(programData, r'Microsoft\Windows\WER'),
      _joinWin(programData, 'Package Cache'),
      _joinWin(programData, r'Microsoft\XDE'),
      _joinWin(programData, r'Microsoft\Windows\RetailDemo'),
      _joinWin(programData, r'Microsoft Visual Studio\10.0\TraceDebugging'),
    ];

    final normalized = <String>[];
    final seen = <String>{};
    for (final path in roots) {
      if (path == null) continue;
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      final dedupKey = _normalizeWindowsPathForDedup(trimmed);
      if (!seen.add(dedupKey)) {
        continue;
      }
      normalized.add(trimmed);
    }
    return normalized;
  }

  static WindowsCleanerRuleMatch? matchPath(String rawPath) {
    final normalizedPath = _normalizePath(rawPath);
    for (final rule in _rules) {
      if (!rule.matches(normalizedPath)) {
        continue;
      }
      return WindowsCleanerRuleMatch(
        kind: rule.kind,
        tags: <String>[
          'windows_rule',
          'windows_rule:${rule.id}',
          'windows_group:${rule.group}',
        ],
      );
    }
    return null;
  }

  static String? _env(Map<String, String> environment, String key) {
    final direct = environment[key];
    if (direct != null && direct.trim().isNotEmpty) {
      return direct;
    }
    final lower = key.toLowerCase();
    for (final entry in environment.entries) {
      if (entry.key.toLowerCase() == lower && entry.value.trim().isNotEmpty) {
        return entry.value;
      }
    }
    return null;
  }

  static String? _extractDrive(String path) {
    if (path.length < 2) return null;
    final letter = path[0];
    if (path[1] != ':') return null;
    return '$letter:';
  }

  static String? _joinWin(String? base, String child) {
    if (base == null || base.trim().isEmpty) return null;
    var normalizedBase = base.replaceAll('/', '\\');
    if (normalizedBase.endsWith('\\')) {
      normalizedBase = normalizedBase.substring(0, normalizedBase.length - 1);
    }
    return '$normalizedBase\\$child';
  }

  static String _normalizeWindowsPathForDedup(String path) {
    var normalized = path.trim().replaceAll('/', '\\');
    while (normalized.endsWith('\\') && normalized.length > 3) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized.toLowerCase();
  }

  static String _normalizePath(String rawPath) {
    final replaced = rawPath.toLowerCase().replaceAll('\\', '/');
    if (replaced.startsWith('/')) {
      return replaced;
    }
    return '/$replaced';
  }
}

class _WindowsPathRule {
  final String id;
  final String group;
  final CleanerCandidateKind kind;
  final List<String> allOf;
  final List<String> anyOf;
  final List<String> fileSuffixes;

  const _WindowsPathRule({
    required this.id,
    required this.group,
    required this.kind,
    this.allOf = const [],
    this.anyOf = const [],
    this.fileSuffixes = const [],
  });

  bool matches(String normalizedPath) {
    for (final token in allOf) {
      if (!normalizedPath.contains(token)) {
        return false;
      }
    }

    if (anyOf.isNotEmpty) {
      var found = false;
      for (final token in anyOf) {
        if (normalizedPath.contains(token)) {
          found = true;
          break;
        }
      }
      if (!found) {
        return false;
      }
    }

    if (fileSuffixes.isNotEmpty) {
      var suffixMatched = false;
      for (final suffix in fileSuffixes) {
        if (normalizedPath.endsWith(suffix)) {
          suffixMatched = true;
          break;
        }
      }
      if (!suffixMatched) {
        return false;
      }
    }

    return true;
  }
}

const List<_WindowsPathRule> _rules = <_WindowsPathRule>[
  _WindowsPathRule(
    id: 'windows_old',
    group: 'stale',
    kind: CleanerCandidateKind.staleFile,
    anyOf: <String>['/windows.old/'],
  ),
  _WindowsPathRule(
    id: 'windows_temp',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    anyOf: <String>['/windows/temp/'],
  ),
  _WindowsPathRule(
    id: 'user_temp',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    anyOf: <String>['/appdata/local/temp/'],
  ),
  _WindowsPathRule(
    id: 'appx_ac_temp',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    allOf: <String>['/appdata/local/packages/'],
    anyOf: <String>['/ac/temp/', '/ac/#!/', '/ac/#!'],
  ),
  _WindowsPathRule(
    id: 'appx_local_cache',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    allOf: <String>['/appdata/local/packages/'],
    anyOf: <String>['/localcache/', '/tempstate/'],
  ),
  _WindowsPathRule(
    id: 'wer_reports',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    anyOf: <String>[
      '/appdata/local/microsoft/windows/wer/',
      '/programdata/microsoft/windows/wer/',
    ],
  ),
  _WindowsPathRule(
    id: 'live_kernel_reports',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    anyOf: <String>['/windows/livekernelreports/'],
  ),
  _WindowsPathRule(
    id: 'windows_update_download',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/windows/softwaredistribution/download/'],
  ),
  _WindowsPathRule(
    id: 'delivery_optimization',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/windows/softwaredistribution/deliveryoptimization/'],
  ),
  _WindowsPathRule(
    id: 'prefetch',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/windows/prefetch/'],
  ),
  _WindowsPathRule(
    id: 'thumbnail_cache',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>[
      '/appdata/local/microsoft/windows/explorer/thumbcache_',
      '/appdata/local/microsoft/windows/explorer/iconcache.db',
    ],
  ),
  _WindowsPathRule(
    id: 'wininet_cache',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>[
      '/appdata/local/microsoft/windows/inetcache/',
      '/temporary internet files/',
    ],
  ),
  _WindowsPathRule(
    id: 'terminal_server_cache',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/appdata/local/microsoft/terminal server client/'],
  ),
  _WindowsPathRule(
    id: 'nuget_global_packages',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/.nuget/'],
  ),
  _WindowsPathRule(
    id: 'nuget_v3_cache',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/appdata/local/nuget/v3-cache/'],
  ),
  _WindowsPathRule(
    id: 'package_cache',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/programdata/package cache/'],
  ),
  _WindowsPathRule(
    id: 'xde_cache',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>[
      '/programdata/microsoft/xde/',
      '/appdata/local/microsoft/xde/',
    ],
  ),
  _WindowsPathRule(
    id: 'pdb_cache',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/appdata/local/dbg/'],
  ),
  _WindowsPathRule(
    id: 'webpi_cache',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/appdata/local/microsoft/web platform installer/'],
  ),
  _WindowsPathRule(
    id: 'vs_trace_debugging',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>[
      '/programdata/microsoft visual studio/10.0/tracedebugging/'
    ],
  ),
  _WindowsPathRule(
    id: 'windows_logs',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    anyOf: <String>['/windows/logs/'],
  ),
  _WindowsPathRule(
    id: 'winsxs_temp',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    anyOf: <String>['/windows/winsxs/temp/'],
  ),
  _WindowsPathRule(
    id: 'qq_logs',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    allOf: <String>['/appdata/roaming/tencent/'],
    anyOf: <String>['/logs/', '/setuplogs/', '/ssotemp/', '/wintemp/'],
  ),
  _WindowsPathRule(
    id: 'yy_temp',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    anyOf: <String>[
      '/appdata/roaming/yy/',
      '/appdata/roaming/duowan/',
    ],
  ),
  _WindowsPathRule(
    id: 'crash_dumps',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    anyOf: <String>['/crashdumps/'],
  ),
  _WindowsPathRule(
    id: 'dmp_files',
    group: 'temporary',
    kind: CleanerCandidateKind.temporary,
    fileSuffixes: <String>['.dmp'],
  ),
  _WindowsPathRule(
    id: 'retail_demo',
    group: 'cache',
    kind: CleanerCandidateKind.cache,
    anyOf: <String>['/microsoft/windows/retaildemo/'],
  ),
];
