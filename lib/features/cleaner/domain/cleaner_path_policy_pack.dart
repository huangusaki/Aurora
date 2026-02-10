import 'dart:io';

class CleanerPathPolicy {
  final List<String> protectedPathPrefixes;
  final List<String> excludedPathPrefixes;
  final List<String> allowedPathPrefixes;

  const CleanerPathPolicy({
    this.protectedPathPrefixes = const [],
    this.excludedPathPrefixes = const [],
    this.allowedPathPrefixes = const [],
  });

  static const CleanerPathPolicy empty = CleanerPathPolicy();
}

class CleanerPathPolicyPack {
  const CleanerPathPolicyPack._();

  static CleanerPathPolicy defaultsForCurrentPlatform() {
    if (Platform.isWindows) {
      final systemRoot = _env('SystemRoot') ?? r'C:\Windows';
      final programFiles = _env('ProgramFiles') ?? r'C:\Program Files';
      final programFilesX86 =
          _env('ProgramFiles(x86)') ?? r'C:\Program Files (x86)';
      final systemDrive = _env('SystemDrive') ?? 'C:';
      final userProfile = _env('USERPROFILE');
      final oneDrive = _env('OneDrive');
      final oneDriveCommercial = _env('OneDriveCommercial');
      final oneDriveConsumer = _env('OneDriveConsumer');
      final bootRoot = '$systemDrive\\Boot';
      final recoveryRoot = '$systemDrive\\Recovery';
      final userDataPrefixes = _normalizePrefixes([
        if (_hasText(userProfile)) _joinWin(userProfile!, 'Desktop'),
        if (_hasText(userProfile)) _joinWin(userProfile!, 'Documents'),
        if (_hasText(userProfile)) _joinWin(userProfile!, 'Pictures'),
        if (_hasText(userProfile)) _joinWin(userProfile!, 'Music'),
        if (_hasText(userProfile)) _joinWin(userProfile!, 'Videos'),
        if (_hasText(oneDrive)) oneDrive!,
        if (_hasText(oneDriveCommercial)) oneDriveCommercial!,
        if (_hasText(oneDriveConsumer)) oneDriveConsumer!,
      ]);

      final protectedPrefixes = _normalizePrefixes([
        '$systemRoot\\System32',
        '$systemRoot\\SysWOW64',
        '$systemRoot\\WinSxS',
        '$systemRoot\\servicing',
        '$systemRoot\\Fonts',
        '$systemRoot\\SystemApps',
        programFiles,
        programFilesX86,
        bootRoot,
        recoveryRoot,
        ...userDataPrefixes,
      ]);

      final excludedPrefixes = _normalizePrefixes([
        '$systemRoot\\System32',
        '$systemRoot\\WinSxS',
        '$systemRoot\\servicing',
        '$systemRoot\\Installer',
        bootRoot,
        recoveryRoot,
        ...userDataPrefixes,
      ]);

      return CleanerPathPolicy(
        protectedPathPrefixes: protectedPrefixes,
        excludedPathPrefixes: excludedPrefixes,
      );
    }

    if (Platform.isMacOS) {
      final home = _env('HOME');
      final userDataPrefixes = _normalizePrefixes([
        if (_hasText(home)) _joinPosix(home!, 'Desktop'),
        if (_hasText(home)) _joinPosix(home!, 'Documents'),
        if (_hasText(home)) _joinPosix(home!, 'Pictures'),
        if (_hasText(home)) _joinPosix(home!, 'Movies'),
        if (_hasText(home)) _joinPosix(home!, 'Music'),
        if (_hasText(home)) _joinPosix(home!, 'Library/Mobile Documents'),
      ]);
      final protectedPrefixes = _normalizePrefixes([
        '/System',
        '/Applications',
        '/Library',
        '/usr/bin',
        '/usr/sbin',
        '/usr/lib',
        '/private/var/db',
        '/Library/Extensions',
        ...userDataPrefixes,
      ]);
      final excludedPrefixes = _normalizePrefixes([
        '/System',
        '/Applications',
        '/Library',
        '/private/var/db',
        ...userDataPrefixes,
      ]);
      return CleanerPathPolicy(
        protectedPathPrefixes: protectedPrefixes,
        excludedPathPrefixes: excludedPrefixes,
      );
    }

    if (Platform.isLinux) {
      final home = _env('HOME');
      final userDataPrefixes = _normalizePrefixes([
        if (_hasText(home)) _joinPosix(home!, 'Desktop'),
        if (_hasText(home)) _joinPosix(home!, 'Documents'),
        if (_hasText(home)) _joinPosix(home!, 'Pictures'),
        if (_hasText(home)) _joinPosix(home!, 'Videos'),
        if (_hasText(home)) _joinPosix(home!, 'Music'),
      ]);
      final protectedPrefixes = _normalizePrefixes([
        '/bin',
        '/sbin',
        '/usr/bin',
        '/usr/sbin',
        '/usr/lib',
        '/etc',
        '/boot',
        '/proc',
        '/sys',
        '/dev',
        '/run',
        '/lib',
        '/lib64',
        ...userDataPrefixes,
      ]);
      final excludedPrefixes = _normalizePrefixes([
        '/proc',
        '/sys',
        '/dev',
        '/run',
        ...userDataPrefixes,
      ]);
      return CleanerPathPolicy(
        protectedPathPrefixes: protectedPrefixes,
        excludedPathPrefixes: excludedPrefixes,
      );
    }

    if (Platform.isAndroid) {
      const sharedMediaPrefixes = <String>[
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Podcasts',
        '/storage/emulated/0/Ringtones',
        '/storage/emulated/0/Alarms',
        '/storage/emulated/0/Notifications',
        '/storage/emulated/0/Documents',
        '/sdcard/DCIM',
        '/sdcard/Pictures',
        '/sdcard/Movies',
        '/sdcard/Music',
        '/sdcard/Podcasts',
        '/sdcard/Ringtones',
        '/sdcard/Alarms',
        '/sdcard/Notifications',
        '/sdcard/Documents',
      ];
      final protectedPrefixes = _normalizePrefixes([
        '/system',
        '/vendor',
        '/product',
        '/apex',
        '/data/system',
        '/data/dalvik-cache',
        '/storage/emulated/0/Android/data',
        '/storage/emulated/0/Android/obb',
        ...sharedMediaPrefixes,
      ]);
      final excludedPrefixes = _normalizePrefixes([
        '/system',
        '/vendor',
        '/product',
        '/apex',
        '/data/system',
        '/data/dalvik-cache',
        ...sharedMediaPrefixes,
      ]);
      return CleanerPathPolicy(
        protectedPathPrefixes: protectedPrefixes,
        excludedPathPrefixes: excludedPrefixes,
      );
    }

    if (Platform.isIOS) {
      final home = _env('HOME');
      final userDataPrefixes = _normalizePrefixes([
        if (_hasText(home)) _joinPosix(home!, 'Documents'),
        if (_hasText(home)) _joinPosix(home!, 'Library/Application Support'),
        if (_hasText(home)) _joinPosix(home!, 'Library/CloudStorage'),
      ]);
      final protectedPrefixes = _normalizePrefixes([
        '/System',
        '/private/var/mobile/Library',
        ...userDataPrefixes,
      ]);
      final excludedPrefixes = _normalizePrefixes([
        '/System',
        ...userDataPrefixes,
      ]);
      return CleanerPathPolicy(
        protectedPathPrefixes: protectedPrefixes,
        excludedPathPrefixes: excludedPrefixes,
      );
    }

    return CleanerPathPolicy.empty;
  }

  static List<String> normalizePrefixes(Iterable<String> rawPrefixes) {
    return _normalizePrefixes(rawPrefixes);
  }

  static bool matchesAnyPrefix(
      String path, Iterable<String> normalizedPrefixes) {
    final normalizedPath = _normalizePath(path);
    for (final rawPrefix in normalizedPrefixes) {
      final prefix = _normalizePath(rawPrefix);
      if (prefix.isEmpty) continue;
      if (normalizedPath.startsWith(prefix)) return true;
    }
    return false;
  }

  static bool allowedByPrefixes(
    String path,
    Iterable<String> normalizedAllowedPrefixes,
  ) {
    final allowed = normalizedAllowedPrefixes.toList(growable: false);
    if (allowed.isEmpty) return true;
    return matchesAnyPrefix(path, allowed);
  }

  static String _normalizePath(String raw) {
    var value = raw.trim().replaceAll('\\', '/');
    if (value.isEmpty) return '';
    if (!value.startsWith('/')) value = '/$value';
    while (value.contains('//')) {
      value = value.replaceAll('//', '/');
    }
    if (!value.endsWith('/')) value = '$value/';
    return value.toLowerCase();
  }

  static List<String> _normalizePrefixes(Iterable<String> rawPrefixes) {
    final set = <String>{};
    for (final raw in rawPrefixes) {
      final normalized = _normalizePath(raw);
      if (normalized.isEmpty) continue;
      set.add(normalized);
    }
    return set.toList()..sort();
  }

  static String? _env(String key) {
    final direct = Platform.environment[key];
    if (direct != null && direct.trim().isNotEmpty) {
      return direct;
    }
    final lower = key.toLowerCase();
    for (final entry in Platform.environment.entries) {
      if (entry.key.toLowerCase() == lower && entry.value.trim().isNotEmpty) {
        return entry.value;
      }
    }
    return null;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String _joinWin(String base, String child) {
    var normalizedBase = base.trim().replaceAll('/', '\\');
    while (normalizedBase.endsWith('\\') && normalizedBase.length > 3) {
      normalizedBase = normalizedBase.substring(0, normalizedBase.length - 1);
    }
    return '$normalizedBase\\$child';
  }

  static String _joinPosix(String base, String child) {
    var normalizedBase = base.trim().replaceAll('\\', '/');
    while (normalizedBase.endsWith('/') && normalizedBase.length > 1) {
      normalizedBase = normalizedBase.substring(0, normalizedBase.length - 1);
    }
    return '$normalizedBase/$child';
  }
}
