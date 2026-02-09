import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/cleaner_models.dart';
import '../domain/cleaner_services.dart';
import 'windows_cleaner_rule_pack.dart';

class CleanerScanService implements CleanerScanner {
  const CleanerScanService();

  @override
  Future<List<CleanerCandidate>> scan(
    CleanerScanOptions options, {
    bool Function()? shouldStop,
  }) async {
    bool isStopRequested() => shouldStop?.call() ?? false;

    final roots = await _resolveRoots(options);
    final candidatesByPath = <String, CleanerCandidate>{};
    final duplicateGroups = <String, List<_DuplicateProbe>>{};
    var scannedFiles = 0;

    for (final root in roots) {
      if (isStopRequested()) break;
      if (scannedFiles >= options.maxScannedFiles) break;
      if (!await root.directory.exists()) continue;

      try {
        await for (final entity in root.directory.list(
          recursive: true,
          followLinks: false,
        )) {
          if (isStopRequested()) break;
          if (scannedFiles >= options.maxScannedFiles) break;
          if (entity is! File) continue;
          scannedFiles++;

          try {
            final stat = await entity.stat();
            if (stat.type != FileSystemEntityType.file) continue;

            final normalizedPath = p.normalize(entity.path);
            final isProtected =
                _isProtectedPath(normalizedPath, options.protectedPathPrefixes);
            var kind = _detectKind(
              normalizedPath: normalizedPath,
              stat: stat,
              options: options,
            );
            final windowsRuleMatch = options.includeWindowsRuleRoots
                ? WindowsCleanerRulePack.matchPath(normalizedPath)
                : null;
            if (windowsRuleMatch != null) {
              kind = _preferKind(kind, windowsRuleMatch.kind);
            }

            final includeUnknownFromUserSelected =
                root.source == 'user_selected' &&
                    options.includeUnknownInUserSelectedRoots;
            if (kind != CleanerCandidateKind.unknown ||
                includeUnknownFromUserSelected ||
                windowsRuleMatch != null) {
              final tags = <String>[
                root.source,
                kind.name,
                if (windowsRuleMatch != null) ...windowsRuleMatch.tags,
              ];
              _upsertCandidate(
                map: candidatesByPath,
                candidate: CleanerCandidate(
                  id: _buildCandidateId(
                    path: normalizedPath,
                    sizeBytes: stat.size,
                    modifiedAt: stat.modified.toUtc(),
                  ),
                  path: normalizedPath,
                  sizeBytes: stat.size,
                  modifiedAt: stat.modified.toUtc(),
                  accessedAt: stat.accessed.toUtc(),
                  kind: kind,
                  recoverable: true,
                  isProtected: isProtected,
                  source: root.source,
                  tags: tags,
                ),
              );
            }

            if (options.detectDuplicates && stat.size > 0) {
              final key = await _buildDuplicateKey(entity, stat);
              duplicateGroups.putIfAbsent(key, () => []).add(_DuplicateProbe(
                    path: normalizedPath,
                    sizeBytes: stat.size,
                    modifiedAt: stat.modified.toUtc(),
                    accessedAt: stat.accessed.toUtc(),
                    isProtected: isProtected,
                    source: root.source,
                  ));
            }
          } catch (_) {
            // Skip unreadable files and continue scanning.
          }
        }
      } catch (_) {
        // Skip unreadable roots and continue scanning.
      }

      if (isStopRequested()) {
        break;
      }
    }

    if (options.detectDuplicates) {
      _applyDuplicateCandidates(
        candidatesByPath: candidatesByPath,
        duplicateGroups: duplicateGroups,
      );
    }

    final candidates = candidatesByPath.values.toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    if (candidates.length > options.maxCandidates) {
      return candidates.sublist(0, options.maxCandidates);
    }
    return candidates;
  }

  Future<List<_ScanRoot>> _resolveRoots(CleanerScanOptions options) async {
    final roots = <_ScanRoot>[];
    final seen = <String>{};
    final hasUserSelectedRoots = options.includeUserSelectedRoots &&
        options.additionalRootPaths.any((raw) => raw.trim().isNotEmpty);
    // If user explicitly provides roots, avoid mixing in app cache/temp.
    final includeDefaultRoots = !hasUserSelectedRoots;

    Future<void> addRoot(
      Directory dir,
      String source,
    ) async {
      final normalized = p.normalize(dir.path).toLowerCase();
      if (seen.contains(normalized)) return;
      seen.add(normalized);
      roots.add(_ScanRoot(directory: dir, source: source));
    }

    if (includeDefaultRoots &&
        options.includeWindowsRuleRoots &&
        WindowsCleanerRulePack.isSupported) {
      for (final path in WindowsCleanerRulePack.defaultRootPaths()) {
        await addRoot(Directory(path), 'windows_rule');
      }
    }

    if (includeDefaultRoots && options.includeAppCache) {
      try {
        await addRoot(await getApplicationCacheDirectory(), 'app_cache');
      } catch (_) {}
    }

    if (includeDefaultRoots && options.includeTemporary) {
      try {
        await addRoot(await getTemporaryDirectory(), 'temporary');
      } catch (_) {}
    }

    if (options.includeUserSelectedRoots) {
      for (final raw in options.additionalRootPaths) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) continue;
        final dir = Directory(trimmed);
        await addRoot(dir, 'user_selected');
      }
    }

    return roots;
  }

  CleanerCandidateKind _detectKind({
    required String normalizedPath,
    required FileStat stat,
    required CleanerScanOptions options,
  }) {
    final pathForMatch = normalizedPath.toLowerCase().replaceAll('\\', '/');
    if (_containsSegment(pathForMatch, 'cache')) {
      return CleanerCandidateKind.cache;
    }
    if (_containsSegment(pathForMatch, 'tmp') ||
        _containsSegment(pathForMatch, 'temp')) {
      return CleanerCandidateKind.temporary;
    }
    if (stat.size >= options.largeFileThresholdBytes) {
      return CleanerCandidateKind.largeFile;
    }
    final age = DateTime.now().toUtc().difference(stat.modified.toUtc());
    if (age >= options.staleThreshold) {
      return CleanerCandidateKind.staleFile;
    }
    return CleanerCandidateKind.unknown;
  }

  bool _containsSegment(String normalizedPath, String segment) {
    final escaped = RegExp.escape(segment.toLowerCase());
    return RegExp('(^|/)$escaped(/|\$)').hasMatch(normalizedPath);
  }

  bool _isProtectedPath(String path, List<String> prefixes) {
    final normalized = path.toLowerCase().replaceAll('\\', '/');
    for (final prefix in prefixes) {
      final check = prefix.trim().toLowerCase().replaceAll('\\', '/');
      if (check.isEmpty) continue;
      if (normalized.startsWith(check)) return true;
    }
    return false;
  }

  void _upsertCandidate({
    required Map<String, CleanerCandidate> map,
    required CleanerCandidate candidate,
  }) {
    final existing = map[candidate.path];
    if (existing == null) {
      map[candidate.path] = candidate;
      return;
    }

    map[candidate.path] = existing.copyWith(
      kind: _preferKind(existing.kind, candidate.kind),
      isProtected: existing.isProtected || candidate.isProtected,
      recoverable: existing.recoverable && candidate.recoverable,
      tags: _mergeTags(existing.tags, candidate.tags),
    );
  }

  void _applyDuplicateCandidates({
    required Map<String, CleanerCandidate> candidatesByPath,
    required Map<String, List<_DuplicateProbe>> duplicateGroups,
  }) {
    for (final group in duplicateGroups.values) {
      if (group.length < 2) continue;

      for (final probe in group) {
        final existing = candidatesByPath[probe.path];
        if (existing != null) {
          candidatesByPath[probe.path] = existing.copyWith(
            kind: _preferKind(existing.kind, CleanerCandidateKind.duplicate),
            tags: _mergeTags(existing.tags, const ['duplicate']),
          );
          continue;
        }

        final candidate = CleanerCandidate(
          id: _buildCandidateId(
            path: probe.path,
            sizeBytes: probe.sizeBytes,
            modifiedAt: probe.modifiedAt,
          ),
          path: probe.path,
          sizeBytes: probe.sizeBytes,
          modifiedAt: probe.modifiedAt,
          accessedAt: probe.accessedAt,
          kind: CleanerCandidateKind.duplicate,
          recoverable: true,
          isProtected: probe.isProtected,
          source: probe.source,
          tags: const ['duplicate'],
        );
        candidatesByPath[probe.path] = candidate;
      }
    }
  }

  CleanerCandidateKind _preferKind(
    CleanerCandidateKind current,
    CleanerCandidateKind incoming,
  ) {
    if (_kindScore(incoming) > _kindScore(current)) {
      return incoming;
    }
    return current;
  }

  int _kindScore(CleanerCandidateKind kind) {
    switch (kind) {
      case CleanerCandidateKind.cache:
      case CleanerCandidateKind.temporary:
        return 5;
      case CleanerCandidateKind.duplicate:
        return 4;
      case CleanerCandidateKind.largeFile:
        return 3;
      case CleanerCandidateKind.staleFile:
        return 2;
      case CleanerCandidateKind.unknown:
        return 1;
    }
  }

  List<String> _mergeTags(List<String> a, List<String> b) {
    return {...a, ...b}.toList()..sort();
  }

  String _buildCandidateId({
    required String path,
    required int sizeBytes,
    required DateTime modifiedAt,
  }) {
    final raw = '$path|$sizeBytes|${modifiedAt.millisecondsSinceEpoch}';
    return base64UrlEncode(utf8.encode(raw)).replaceAll('=', '');
  }

  Future<String> _buildDuplicateKey(File file, FileStat stat) async {
    final size = stat.size;
    if (size <= 0) return '0:${p.extension(file.path).toLowerCase()}';

    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final headSize = min(4096, size);
      final head = await raf.read(headSize);

      List<int> tail = const [];
      if (size > 4096) {
        final tailSize = min(4096, size - headSize);
        await raf.setPosition(size - tailSize);
        tail = await raf.read(tailSize);
      }

      final checksum =
          _rollingChecksum(head, seed: 17) ^ _rollingChecksum(tail, seed: 37);
      final ext = p.extension(file.path).toLowerCase();
      return '$size:$checksum:$ext';
    } catch (_) {
      return '$size:${p.extension(file.path).toLowerCase()}';
    } finally {
      await raf?.close();
    }
  }

  int _rollingChecksum(List<int> bytes, {required int seed}) {
    var hash = seed;
    for (final b in bytes) {
      hash = ((hash * 131) ^ b) & 0x7fffffff;
    }
    return hash;
  }
}

class _ScanRoot {
  final Directory directory;
  final String source;

  const _ScanRoot({
    required this.directory,
    required this.source,
  });
}

class _DuplicateProbe {
  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;
  final DateTime? accessedAt;
  final bool isProtected;
  final String source;

  const _DuplicateProbe({
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.accessedAt,
    required this.isProtected,
    required this.source,
  });
}
