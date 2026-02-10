import 'cleaner_models.dart';

class CleanerDirectoryProfile {
  final String path;
  final String source;
  final int depth;
  final int immediateBytes;
  final int immediateFiles;
  final int immediateDirs;
  final int suspicionScore;
  final bool userSelectedRoot;

  const CleanerDirectoryProfile({
    required this.path,
    required this.source,
    required this.depth,
    required this.immediateBytes,
    required this.immediateFiles,
    required this.immediateDirs,
    required this.suspicionScore,
    required this.userSelectedRoot,
  });

  Map<String, dynamic> toAiInput({required bool redactPath}) {
    return <String, dynamic>{
      'path': redactPath ? _redactPath(path) : path,
      'source': source,
      'depth': depth,
      'immediate_bytes': immediateBytes,
      'immediate_files': immediateFiles,
      'immediate_dirs': immediateDirs,
      'suspicion_score': suspicionScore,
      'user_selected_root': userSelectedRoot,
    };
  }

  static String _redactPath(String rawPath) {
    final normalized = rawPath.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return '[REDACTED]';
    }

    var prefix = '';
    var pathBody = normalized;
    final driveMatch = RegExp(r'^[a-zA-Z]:').firstMatch(normalized);
    if (driveMatch != null) {
      prefix = '${driveMatch.group(0)}/';
      pathBody = normalized.substring(driveMatch.group(0)!.length);
    } else if (normalized.startsWith('/')) {
      prefix = '/';
    }

    final segments =
        pathBody.split('/').where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) {
      return prefix.isEmpty ? '[REDACTED]' : '$prefix...';
    }
    if (segments.length <= 4) {
      return '$prefix${segments.join('/')}';
    }
    final tail = segments.sublist(segments.length - 4);
    return '$prefix.../${tail.join('/')}';
  }
}

class CleanerDirectoryPlan {
  final List<String> selectedPaths;
  final String source;

  const CleanerDirectoryPlan({
    required this.selectedPaths,
    required this.source,
  });
}

abstract class CleanerDirectoryPlanner {
  Future<CleanerDirectoryPlan> plan({
    required List<CleanerDirectoryProfile> profiles,
    required CleanerScanOptions options,
    bool Function()? shouldStop,
  });
}

