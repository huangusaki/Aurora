import 'package:path/path.dart' as p;

import '../domain/cleaner_directory_planner.dart';
import '../domain/cleaner_models.dart';

class HeuristicCleanerDirectoryPlanner implements CleanerDirectoryPlanner {
  const HeuristicCleanerDirectoryPlanner();

  @override
  Future<CleanerDirectoryPlan> plan({
    required List<CleanerDirectoryProfile> profiles,
    required CleanerScanOptions options,
    bool Function()? shouldStop,
  }) async {
    if (profiles.isEmpty) {
      return const CleanerDirectoryPlan(
        selectedPaths: <String>[],
        source: 'heuristic',
      );
    }

    if (shouldStop?.call() ?? false) {
      return const CleanerDirectoryPlan(
        selectedPaths: <String>[],
        source: 'heuristic',
      );
    }

    final suspicious = profiles
        .where((profile) =>
            profile.suspicionScore > 0 ||
            profile.immediateBytes >= options.profileSuspiciousMinBytes)
        .toList(growable: false);
    if (suspicious.isEmpty) {
      return const CleanerDirectoryPlan(
        selectedPaths: <String>[],
        source: 'heuristic',
      );
    }

    final sorted = suspicious.toList(growable: false)
      ..sort((a, b) {
        final byRoot = (b.userSelectedRoot ? 1 : 0) - (a.userSelectedRoot ? 1 : 0);
        if (byRoot != 0) return byRoot;
        final byScore = b.suspicionScore.compareTo(a.suspicionScore);
        if (byScore != 0) return byScore;
        final byBytes = b.immediateBytes.compareTo(a.immediateBytes);
        if (byBytes != 0) return byBytes;
        return a.depth.compareTo(b.depth);
      });

    final maxSelected = options.profileSuspiciousDirCount < 1
        ? 1
        : options.profileSuspiciousDirCount;
    final selectedPaths = <String>[];

    for (final profile in sorted) {
      if (selectedPaths.length >= maxSelected) {
        break;
      }
      final normalized = p.normalize(profile.path);
      if (_hasPathOverlap(normalized, selectedPaths)) {
        continue;
      }
      selectedPaths.add(normalized);
    }

    return CleanerDirectoryPlan(
      selectedPaths: selectedPaths,
      source: 'heuristic',
    );
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
}

