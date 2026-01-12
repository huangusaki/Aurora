library;

import 'dart:async';
import 'search_result.dart';

enum MergeStrategy {
  interleave,
  sequential,
  byRelevance,
  bySpeed,
}

class ParallelSearchConfig {
  const ParallelSearchConfig({
    this.maxConcurrency = 5,
    this.failFast = false,
    this.minResults = 5,
    this.maxWaitTime = const Duration(seconds: 10),
    this.mergeStrategy = MergeStrategy.interleave,
    this.deduplicate = true,
    this.engineTimeout = const Duration(seconds: 5),
  });
  final int maxConcurrency;
  final bool failFast;
  final int minResults;
  final Duration maxWaitTime;
  final MergeStrategy mergeStrategy;
  final bool deduplicate;
  final Duration engineTimeout;
  static const fast = ParallelSearchConfig(
    maxConcurrency: 3,
    minResults: 3,
    maxWaitTime: Duration(seconds: 5),
  );
  static const comprehensive = ParallelSearchConfig(
    maxConcurrency: 10,
    minResults: 20,
    maxWaitTime: Duration(seconds: 15),
    mergeStrategy: MergeStrategy.byRelevance,
  );
}

class EngineResult<T extends SearchResult> {
  const EngineResult({
    required this.engine,
    required this.results,
    required this.duration,
    this.error,
  });
  final String engine;
  final List<T> results;
  final Duration duration;
  final String? error;
  bool get success => error == null;
}

class ParallelSearchResult<T extends SearchResult> {
  const ParallelSearchResult({
    required this.results,
    required this.engineResults,
    required this.totalDuration,
  });
  final List<T> results;
  final List<EngineResult<T>> engineResults;
  final Duration totalDuration;
  int get successfulEngines => engineResults.where((e) => e.success).length;
  int get failedEngines => engineResults.where((e) => !e.success).length;
  Duration get averageResponseTime {
    final successful = engineResults.where((e) => e.success);
    if (successful.isEmpty) return Duration.zero;
    final total = successful.fold<int>(
      0,
      (sum, e) => sum + e.duration.inMilliseconds,
    );
    return Duration(milliseconds: total ~/ successful.length);
  }

  Map<String, dynamic> toJson() => {
        'totalResults': results.length,
        'successfulEngines': successfulEngines,
        'failedEngines': failedEngines,
        'totalDuration': totalDuration.inMilliseconds,
        'averageResponseTime': averageResponseTime.inMilliseconds,
        'engineResults': engineResults
            .map(
              (e) => {
                'engine': e.engine,
                'resultCount': e.results.length,
                'duration': e.duration.inMilliseconds,
                'error': e.error,
              },
            )
            .toList(),
      };
}

class ResultMerger<T extends SearchResult> {
  ResultMerger({
    this.strategy = MergeStrategy.interleave,
    this.deduplicate = true,
  });
  final MergeStrategy strategy;
  final bool deduplicate;
  final Set<String> _seenUrls = {};
  List<T> merge(List<EngineResult<T>> engineResults) {
    if (engineResults.isEmpty) return [];
    final validResults = engineResults.where((e) => e.success).toList();
    if (validResults.isEmpty) return [];
    switch (strategy) {
      case MergeStrategy.interleave:
        return _interleave(validResults);
      case MergeStrategy.sequential:
        return _sequential(validResults);
      case MergeStrategy.byRelevance:
        return _byRelevance(validResults);
      case MergeStrategy.bySpeed:
        return _bySpeed(validResults);
    }
  }

  List<T> _interleave(List<EngineResult<T>> results) {
    final merged = <T>[];
    final iterators = results.map((e) => e.results.iterator).toList();
    var hasMore = true;
    while (hasMore) {
      hasMore = false;
      for (final iterator in iterators) {
        if (iterator.moveNext()) {
          hasMore = true;
          final result = iterator.current;
          if (_shouldInclude(result)) {
            merged.add(result);
          }
        }
      }
    }
    return merged;
  }

  List<T> _sequential(List<EngineResult<T>> results) {
    final merged = <T>[];
    for (final engineResult in results) {
      for (final result in engineResult.results) {
        if (_shouldInclude(result)) {
          merged.add(result);
        }
      }
    }
    return merged;
  }

  List<T> _byRelevance(List<EngineResult<T>> results) {
    final all = <T>[];
    for (final engineResult in results) {
      for (final result in engineResult.results) {
        if (_shouldInclude(result)) {
          all.add(result);
        }
      }
    }
    all.sort((a, b) {
      final scoreA = a.relevanceScore ?? 0;
      final scoreB = b.relevanceScore ?? 0;
      return scoreB.compareTo(scoreA);
    });
    return all;
  }

  List<T> _bySpeed(List<EngineResult<T>> results) {
    final sorted = List<EngineResult<T>>.from(results)
      ..sort((a, b) => a.duration.compareTo(b.duration));
    return _sequential(sorted);
  }

  bool _shouldInclude(T result) {
    if (!deduplicate) return true;
    final url = _getUrl(result);
    if (url == null || url.isEmpty) return true;
    if (_seenUrls.contains(url)) return false;
    _seenUrls.add(url);
    return true;
  }

  String? _getUrl(T result) {
    final json = result.toJson();
    return json['href'] as String? ??
        json['url'] as String? ??
        json['image'] as String? ??
        json['embed_url'] as String?;
  }

  void reset() => _seenUrls.clear();
}

class ConcurrentSearchManager {
  ConcurrentSearchManager({this.maxConcurrency = 5});
  final int maxConcurrency;
  int _activeRequests = 0;
  final _queue = <Completer<void>>[];
  Future<void> acquire() async {
    if (_activeRequests < maxConcurrency) {
      _activeRequests++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      final completer = _queue.removeAt(0);
      completer.complete();
    } else {
      _activeRequests--;
    }
  }

  Future<T> run<T>(Future<T> Function() task) async {
    await acquire();
    try {
      return await task();
    } finally {
      release();
    }
  }

  int get activeRequests => _activeRequests;
  int get queuedRequests => _queue.length;
}
