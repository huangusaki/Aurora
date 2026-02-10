import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/cleaner_directory_planner.dart';
import '../domain/cleaner_models.dart';
import '../domain/cleaner_path_policy_pack.dart';
import '../domain/cleaner_services.dart';
import 'windows_cleaner_rule_pack.dart';

class CleanerScanService implements CleanerScanner {
  final CleanerDirectoryPlanner? directoryPlanner;

  const CleanerScanService({
    this.directoryPlanner,
  });

  @override
  Future<List<CleanerCandidate>> scan(
    CleanerScanOptions options, {
    bool Function()? shouldStop,
  }) async {
    bool isStopRequested() => shouldStop?.call() ?? false;
    final effectivePolicy = _resolveEffectivePathPolicy(options);

    final roots = await _resolveRoots(options, policy: effectivePolicy);
    if (roots.isEmpty) {
      return const <CleanerCandidate>[];
    }
    final scanRoots = await _selectDetailedRoots(
      roots,
      options: options,
      policy: effectivePolicy,
      shouldStop: isStopRequested,
    );
    final candidatesByPath = <String, CleanerCandidate>{};
    final duplicateGroups = <String, List<_DuplicateProbe>>{};
    var scannedFiles = 0;

    for (final root in scanRoots) {
      if (isStopRequested()) break;
      if (scannedFiles >= options.maxScannedFiles) break;
      final normalizedRootPath = p.normalize(root.directory.path);
      if (_isPathExcluded(normalizedRootPath, effectivePolicy)) continue;
      if (!_isPathAllowed(normalizedRootPath, effectivePolicy)) continue;
      if (!await root.directory.exists()) continue;

      final queue = <_ScanDirFrame>[
        _ScanDirFrame(
          directory: root.directory,
          source: root.source,
          depth: 0,
        ),
      ];

      try {
        while (queue.isNotEmpty) {
          if (isStopRequested()) break;
          if (scannedFiles >= options.maxScannedFiles) break;

          final frame = queue.removeLast();
          final normalizedFramePath = p.normalize(frame.directory.path);
          if (_isPathExcluded(normalizedFramePath, effectivePolicy)) continue;
          if (!_isPathAllowed(normalizedFramePath, effectivePolicy)) continue;
          if (!await frame.directory.exists()) continue;

          var listedEntries = 0;
          await for (final entity in frame.directory.list(
            recursive: false,
            followLinks: false,
          )) {
            if (isStopRequested()) break;
            if (scannedFiles >= options.maxScannedFiles) break;

            listedEntries++;
            if (listedEntries > options.maxEntriesPerDirectory) {
              break;
            }

            if (entity is Directory) {
              if (frame.depth + 1 > options.maxDirectoryDepth) {
                continue;
              }

              final normalizedDirPath = p.normalize(entity.path);
              if (_isPathExcluded(normalizedDirPath, effectivePolicy)) {
                continue;
              }
              if (!_isPathAllowed(normalizedDirPath, effectivePolicy)) {
                continue;
              }
              if (options.skipShallowDirectories &&
                  _isShallowDirectory(
                    normalizedDirPath,
                    options.shallowDirectoryNames,
                  )) {
                continue;
              }

              queue.add(_ScanDirFrame(
                directory: entity,
                source: frame.source,
                depth: frame.depth + 1,
              ));
              continue;
            }

            if (entity is! File) continue;
            scannedFiles++;

            try {
              final stat = await entity.stat();
              if (stat.type != FileSystemEntityType.file) continue;

              final normalizedPath = p.normalize(entity.path);
              if (_isPathExcluded(normalizedPath, effectivePolicy)) continue;
              if (!_isPathAllowed(normalizedPath, effectivePolicy)) continue;

              final isProtected =
                  _isProtectedPath(normalizedPath, effectivePolicy);
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
                  frame.source == 'user_selected' &&
                      options.includeUnknownInUserSelectedRoots;
              if (kind != CleanerCandidateKind.unknown ||
                  includeUnknownFromUserSelected ||
                  windowsRuleMatch != null) {
                final tags = <String>[
                  frame.source,
                  kind.name,
                  if (isProtected) 'protected_path_policy',
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
                    source: frame.source,
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
                      source: frame.source,
                    ));
              }
            } catch (_) {
              // Skip unreadable files and continue scanning.
            }
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

  Future<List<_ScanRoot>> _resolveRoots(
    CleanerScanOptions options, {
    required _ResolvedPathPolicy policy,
  }) async {
    final roots = <_ScanRoot>[];
    final seen = <String>{};

    Future<void> addRoot(
      Directory dir,
      String source,
    ) async {
      final normalized = p.normalize(dir.path).toLowerCase();
      if (seen.contains(normalized)) return;
      if (_isPathExcluded(normalized, policy)) return;
      if (!_isPathAllowed(normalized, policy)) return;
      seen.add(normalized);
      roots.add(_ScanRoot(directory: dir, source: source));
    }

    if (options.includeWindowsRuleRoots && WindowsCleanerRulePack.isSupported) {
      for (final path in WindowsCleanerRulePack.defaultRootPaths()) {
        await addRoot(Directory(path), 'windows_rule');
      }
    }

    if (options.includeAppCache) {
      try {
        await addRoot(await getApplicationCacheDirectory(), 'app_cache');
      } catch (_) {}
    }

    if (options.includeTemporary) {
      try {
        await addRoot(await getTemporaryDirectory(), 'temporary');
      } catch (_) {}
    }

    if (options.includeCommonUserRoots) {
      final commonRoots = await _resolveCommonUserRoots();
      for (final dir in commonRoots) {
        await addRoot(dir, 'common_user');
      }
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

  _ResolvedPathPolicy _resolveEffectivePathPolicy(CleanerScanOptions options) {
    final defaults = options.useDefaultPathPolicy
        ? CleanerPathPolicyPack.defaultsForCurrentPlatform()
        : CleanerPathPolicy.empty;

    final protectedPrefixes = CleanerPathPolicyPack.normalizePrefixes([
      ...defaults.protectedPathPrefixes,
      ...options.protectedPathPrefixes,
    ]);
    final excludedPrefixes = CleanerPathPolicyPack.normalizePrefixes([
      ...defaults.excludedPathPrefixes,
      ...options.excludedPathPrefixes,
    ]);
    final allowedPrefixes = CleanerPathPolicyPack.normalizePrefixes([
      ...defaults.allowedPathPrefixes,
      ...options.allowedPathPrefixes,
    ]);

    return _ResolvedPathPolicy(
      protectedPrefixes: protectedPrefixes,
      excludedPrefixes: excludedPrefixes,
      allowedPrefixes: allowedPrefixes,
    );
  }

  Future<List<_ScanRoot>> _selectDetailedRoots(
    List<_ScanRoot> roots, {
    required CleanerScanOptions options,
    required _ResolvedPathPolicy policy,
    required bool Function() shouldStop,
  }) async {
    if (!options.enableTwoPhaseDirectoryScan) {
      return roots;
    }

    final queue = <_ProfileFrame>[
      for (final root in roots)
        _ProfileFrame(
          directory: root.directory,
          source: root.source,
          depth: 0,
        ),
    ];
    final seen = <String>{};
    final profiles = <CleanerDirectoryProfile>[];

    while (queue.isNotEmpty &&
        profiles.length < options.profileMaxDirectories &&
        !shouldStop()) {
      final frame = queue.removeLast();
      final normalizedPath = p.normalize(frame.directory.path);
      final dedupKey = normalizedPath.toLowerCase();
      if (!seen.add(dedupKey)) continue;

      if (_isPathExcluded(normalizedPath, policy)) continue;
      if (!_isPathAllowed(normalizedPath, policy)) continue;
      if (!await frame.directory.exists()) continue;

      var listedEntries = 0;
      var immediateBytes = 0;
      var immediateFiles = 0;
      var immediateDirs = 0;

      try {
        await for (final entity in frame.directory.list(
          recursive: false,
          followLinks: false,
        )) {
          if (shouldStop()) break;

          listedEntries++;
          if (listedEntries > options.maxEntriesPerDirectory) {
            break;
          }

          if (entity is Directory) {
            final normalizedChildPath = p.normalize(entity.path);
            if (_isPathExcluded(normalizedChildPath, policy)) continue;
            if (!_isPathAllowed(normalizedChildPath, policy)) continue;
            if (options.skipShallowDirectories &&
                _isShallowDirectory(
                  normalizedChildPath,
                  options.shallowDirectoryNames,
                )) {
              continue;
            }

            immediateDirs++;
            if (frame.depth + 1 <= options.profileMaxDepth) {
              queue.add(_ProfileFrame(
                directory: entity,
                source: frame.source,
                depth: frame.depth + 1,
              ));
            }
            continue;
          }

          if (entity is! File) continue;

          immediateFiles++;
          try {
            final stat = await entity.stat();
            if (stat.type == FileSystemEntityType.file && stat.size > 0) {
              immediateBytes += stat.size;
            }
          } catch (_) {
            // Skip unreadable file metadata during profile scan.
          }
        }
      } catch (_) {
        // Skip unreadable directories during profile scan.
      }

      profiles.add(CleanerDirectoryProfile(
        path: normalizedPath,
        source: frame.source,
        depth: frame.depth,
        immediateBytes: immediateBytes,
        immediateFiles: immediateFiles,
        immediateDirs: immediateDirs,
        suspicionScore: _directorySuspicionScore(
          path: normalizedPath,
          source: frame.source,
          immediateBytes: immediateBytes,
          immediateFiles: immediateFiles,
          immediateDirs: immediateDirs,
          options: options,
        ),
        userSelectedRoot: frame.source == 'user_selected',
      ));
    }

    if (profiles.isEmpty) {
      return roots;
    }

    final plan = await _buildDirectoryPlan(
      profiles: profiles,
      options: options,
      shouldStop: shouldStop,
    );
    final maxSelected = options.profileSuspiciousDirCount < 1
        ? 1
        : options.profileSuspiciousDirCount;

    final profileByPath = <String, CleanerDirectoryProfile>{
      for (final profile in profiles) p.normalize(profile.path).toLowerCase(): profile,
    };
    final selected = <_ScanRoot>[];
    final selectedPaths = <String>[];

    void trySelectPath(String rawPath, {String? fallbackSource}) {
      final normalized = p.normalize(rawPath);
      if (_hasPathOverlap(normalized, selectedPaths)) {
        return;
      }
      if (_isPathExcluded(normalized, policy) || !_isPathAllowed(normalized, policy)) {
        return;
      }
      final key = normalized.toLowerCase();
      final source = profileByPath[key]?.source ?? fallbackSource ?? 'llm_plan';
      selected.add(_ScanRoot(
        directory: Directory(normalized),
        source: source,
      ));
      selectedPaths.add(normalized);
    }

    for (final path in plan.selectedPaths) {
      trySelectPath(path);
      if (selected.length >= maxSelected) {
        break;
      }
    }

    if (selected.isEmpty) {
      for (final root in roots.where((root) => root.source == 'user_selected')) {
        trySelectPath(root.directory.path, fallbackSource: root.source);
      }
    }

    if (selected.isEmpty) {
      final fallbackPlan = await _fallbackDirectoryPlan(
        profiles: profiles,
        options: options,
        shouldStop: shouldStop,
      );
      for (final path in fallbackPlan.selectedPaths) {
        trySelectPath(path);
        if (selected.length >= maxSelected) {
          break;
        }
      }
    }

    if (selected.isEmpty) {
      return roots;
    }
    return selected;
  }

  Future<CleanerDirectoryPlan> _buildDirectoryPlan({
    required List<CleanerDirectoryProfile> profiles,
    required CleanerScanOptions options,
    required bool Function() shouldStop,
  }) async {
    if (!options.enableLlmDirectoryPlanning || directoryPlanner == null) {
      return _fallbackDirectoryPlan(
        profiles: profiles,
        options: options,
        shouldStop: shouldStop,
      );
    }

    final maxInput = options.llmDirectoryPlanningMaxInputDirectories < 1
        ? 1
        : options.llmDirectoryPlanningMaxInputDirectories;
    final prioritizedInputs = profiles.toList(growable: false)
      ..sort((a, b) {
        final byRoot =
            (b.userSelectedRoot ? 1 : 0) - (a.userSelectedRoot ? 1 : 0);
        if (byRoot != 0) return byRoot;
        final byScore = b.suspicionScore.compareTo(a.suspicionScore);
        if (byScore != 0) return byScore;
        final byBytes = b.immediateBytes.compareTo(a.immediateBytes);
        if (byBytes != 0) return byBytes;
        return a.depth.compareTo(b.depth);
      });
    final llmInputs = prioritizedInputs.length <= maxInput
        ? prioritizedInputs
        : prioritizedInputs.sublist(0, maxInput);

    final plan = await directoryPlanner!.plan(
      profiles: llmInputs,
      options: options,
      shouldStop: shouldStop,
    );
    if (plan.selectedPaths.isEmpty) {
      return _fallbackDirectoryPlan(
        profiles: profiles,
        options: options,
        shouldStop: shouldStop,
      );
    }
    return plan;
  }

  Future<CleanerDirectoryPlan> _fallbackDirectoryPlan({
    required List<CleanerDirectoryProfile> profiles,
    required CleanerScanOptions options,
    required bool Function() shouldStop,
  }) async {
    final maxSelected = options.profileSuspiciousDirCount < 1
        ? 1
        : options.profileSuspiciousDirCount;
    final suspicious = profiles
        .where((profile) =>
            profile.suspicionScore > 0 ||
            profile.immediateBytes >= options.profileSuspiciousMinBytes)
        .toList(growable: false);
    if (suspicious.isEmpty) {
      return const CleanerDirectoryPlan(
        selectedPaths: <String>[],
        source: 'heuristic_internal',
      );
    }
    final sorted = suspicious.toList(growable: false)
      ..sort((a, b) {
        final byRoot =
            (b.userSelectedRoot ? 1 : 0) - (a.userSelectedRoot ? 1 : 0);
        if (byRoot != 0) return byRoot;
        final byScore = b.suspicionScore.compareTo(a.suspicionScore);
        if (byScore != 0) return byScore;
        final byBytes = b.immediateBytes.compareTo(a.immediateBytes);
        if (byBytes != 0) return byBytes;
        return a.depth.compareTo(b.depth);
      });

    final selected = <String>[];
    for (final profile in sorted) {
      if (shouldStop()) break;
      final normalized = p.normalize(profile.path);
      if (_hasPathOverlap(normalized, selected)) {
        continue;
      }
      selected.add(normalized);
      if (selected.length >= maxSelected) {
        break;
      }
    }

    return CleanerDirectoryPlan(
      selectedPaths: selected,
      source: 'heuristic_internal',
    );
  }

  Future<List<Directory>> _resolveCommonUserRoots() async {
    final dirs = <Directory>[];

    void addPath(String? raw) {
      final trimmed = raw?.trim() ?? '';
      if (trimmed.isEmpty) return;
      dirs.add(Directory(trimmed));
    }

    void addJoin(String? base, List<String> segments) {
      final normalizedBase = base?.trim() ?? '';
      if (normalizedBase.isEmpty) return;
      addPath(p.joinAll([normalizedBase, ...segments]));
    }

    String? env(String key) {
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

    if (Platform.isWindows) {
      final home = env('USERPROFILE');
      final systemDrive = env('SystemDrive');
      addJoin(home, const ['Downloads']);
      if (systemDrive != null && systemDrive.trim().isNotEmpty) {
        addPath(p.join(systemDrive.trim(), r'$Recycle.Bin'));
      }
    }

    if (Platform.isMacOS) {
      final home = env('HOME');
      addJoin(home, const ['Downloads']);
      addJoin(home, const ['Library', 'Caches']);
      addJoin(home, const ['Library', 'Logs']);
      addJoin(home, const ['Library', 'Application Support', 'CrashReporter']);
      addPath('/tmp');
      addPath('/private/var/tmp');
    }

    if (Platform.isLinux) {
      final home = env('HOME');
      addJoin(home, const ['Downloads']);
      addJoin(home, const ['.cache']);
      addJoin(home, const ['.local', 'share', 'Trash', 'files']);
      addPath('/tmp');
      addPath('/var/tmp');
    }

    if (Platform.isAndroid) {
      try {
        final external = await getExternalStorageDirectory();
        if (external != null) {
          final sharedRoot = _inferAndroidSharedRoot(external.path);
          if (sharedRoot != null && sharedRoot.trim().isNotEmpty) {
            addPath(p.join(sharedRoot, 'Download'));
            addPath(p.join(sharedRoot, 'DCIM', '.thumbnails'));
            addPath(p.join(sharedRoot, 'Pictures', '.thumbnails'));
          }
        }
      } catch (_) {}

      try {
        final externalCaches = await getExternalCacheDirectories();
        if (externalCaches != null) {
          for (final dir in externalCaches) {
            addPath(dir.path);
          }
        }
      } catch (_) {}
    }

    return dirs;
  }

  String? _inferAndroidSharedRoot(String rawPath) {
    final normalized = rawPath.replaceAll('\\', '/');
    const marker = '/Android/data/';
    final markerIndex = normalized.indexOf(marker);
    if (markerIndex > 0) {
      return normalized.substring(0, markerIndex);
    }
    return null;
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

  bool _isShallowDirectory(String normalizedPath, List<String> names) {
    if (names.isEmpty) return false;
    final directoryName = p.basename(normalizedPath).toLowerCase();
    for (final name in names) {
      final normalizedName = name.trim().toLowerCase();
      if (normalizedName.isEmpty) continue;
      if (directoryName == normalizedName) return true;
    }
    return false;
  }

  int _directorySuspicionScore({
    required String path,
    required String source,
    required int immediateBytes,
    required int immediateFiles,
    required int immediateDirs,
    required CleanerScanOptions options,
  }) {
    var score = 0;

    if (source == 'windows_rule') {
      score += 3;
    } else if (source == 'app_cache' || source == 'temporary') {
      score += 2;
    } else if (source == 'user_selected') {
      score += 1;
    }

    for (final token in const [
      'cache',
      'tmp',
      'temp',
      'log',
      'logs',
      'download',
      'downloads',
      'trash',
      'recycle',
      'thumbnail',
      'thumbnails',
      'crash',
    ]) {
      if (_containsSegment(path.toLowerCase().replaceAll('\\', '/'), token)) {
        score += 2;
      }
    }

    if (immediateBytes >= options.profileLargeDirectoryThresholdBytes) {
      score += 4;
    } else if (immediateBytes >= options.profileSuspiciousMinBytes) {
      score += 2;
    } else if (immediateBytes >= options.profileSuspiciousMinBytes ~/ 2) {
      score += 1;
    }

    if (immediateFiles >= 1000) {
      score += 2;
    } else if (immediateFiles >= 200) {
      score += 1;
    }

    if (immediateDirs >= 80) {
      score += 1;
    }

    return score;
  }

  bool _hasPathOverlap(String path, List<String> selectedPaths) {
    for (final selected in selectedPaths) {
      if (_isSameOrUnderPath(path, selected) ||
          _isSameOrUnderPath(selected, path)) {
        return true;
      }
    }
    return false;
  }

  bool _isSameOrUnderPath(String path, String base) {
    var normalizedPath = path.toLowerCase().replaceAll('\\', '/');
    var normalizedBase = base.toLowerCase().replaceAll('\\', '/');
    while (normalizedPath.contains('//')) {
      normalizedPath = normalizedPath.replaceAll('//', '/');
    }
    while (normalizedBase.contains('//')) {
      normalizedBase = normalizedBase.replaceAll('//', '/');
    }
    if (normalizedPath == normalizedBase) {
      return true;
    }
    if (!normalizedBase.endsWith('/')) {
      normalizedBase = '$normalizedBase/';
    }
    return normalizedPath.startsWith(normalizedBase);
  }

  bool _isProtectedPath(String path, _ResolvedPathPolicy policy) {
    return CleanerPathPolicyPack.matchesAnyPrefix(
        path, policy.protectedPrefixes);
  }

  bool _isPathExcluded(String path, _ResolvedPathPolicy policy) {
    return CleanerPathPolicyPack.matchesAnyPrefix(
        path, policy.excludedPrefixes);
  }

  bool _isPathAllowed(String path, _ResolvedPathPolicy policy) {
    return CleanerPathPolicyPack.allowedByPrefixes(
        path, policy.allowedPrefixes);
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

class _ScanDirFrame {
  final Directory directory;
  final String source;
  final int depth;

  const _ScanDirFrame({
    required this.directory,
    required this.source,
    required this.depth,
  });
}

class _ProfileFrame {
  final Directory directory;
  final String source;
  final int depth;

  const _ProfileFrame({
    required this.directory,
    required this.source,
    required this.depth,
  });
}

class _ResolvedPathPolicy {
  final List<String> protectedPrefixes;
  final List<String> excludedPrefixes;
  final List<String> allowedPrefixes;

  const _ResolvedPathPolicy({
    required this.protectedPrefixes,
    required this.excludedPrefixes,
    required this.allowedPrefixes,
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
