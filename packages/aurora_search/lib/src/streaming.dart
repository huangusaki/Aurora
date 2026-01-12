library;

import 'dart:async';
import 'search_result.dart';

class SearchResultChunk<T extends SearchResult> {
  const SearchResultChunk({
    required this.results,
    required this.engine,
    this.isFinal = false,
    this.totalResultsSoFar = 0,
    this.fetchDuration = Duration.zero,
  });
  final List<T> results;
  final String engine;
  final bool isFinal;
  final int totalResultsSoFar;
  final Duration fetchDuration;
  @override
  String toString() => 'SearchResultChunk(engine: $engine, '
      'results: ${results.length}, isFinal: $isFinal)';
}

class SearchProgress {
  const SearchProgress({
    required this.enginesQueried,
    required this.totalEngines,
    required this.resultsFound,
    this.completedEngines = const [],
    this.failedEngines = const [],
    this.status = '',
  });
  final int enginesQueried;
  final int totalEngines;
  final int resultsFound;
  final List<String> completedEngines;
  final List<String> failedEngines;
  final String status;
  double get progressPercent =>
      totalEngines > 0 ? enginesQueried / totalEngines * 100 : 0;
  bool get isComplete => enginesQueried >= totalEngines;
  @override
  String toString() => 'SearchProgress($enginesQueried/$totalEngines engines, '
      '$resultsFound results)';
}

sealed class SearchEvent<T extends SearchResult> {
  const SearchEvent();
}

class ResultsEvent<T extends SearchResult> extends SearchEvent<T> {
  const ResultsEvent(this.chunk);
  final SearchResultChunk<T> chunk;
}

class ProgressEvent<T extends SearchResult> extends SearchEvent<T> {
  const ProgressEvent(this.progress);
  final SearchProgress progress;
}

class ErrorEvent<T extends SearchResult> extends SearchEvent<T> {
  const ErrorEvent(this.engine, this.error);
  final String engine;
  final String error;
}

class CompletedEvent<T extends SearchResult> extends SearchEvent<T> {
  const CompletedEvent({
    required this.allResults,
    required this.totalDuration,
    required this.finalProgress,
  });
  final List<T> allResults;
  final Duration totalDuration;
  final SearchProgress finalProgress;
}

class StreamingSearchController<T extends SearchResult> {
  final _controller = StreamController<SearchEvent<T>>.broadcast();
  final List<T> _allResults = [];
  bool _isCancelled = false;
  DateTime? _startTime;
  Stream<SearchEvent<T>> get stream => _controller.stream;
  List<T> get results => List.unmodifiable(_allResults);
  bool get isCancelled => _isCancelled;
  void start() {
    _startTime = DateTime.now();
  }

  void addResults(SearchResultChunk<T> chunk) {
    if (_isCancelled) return;
    _allResults.addAll(chunk.results);
    _controller.add(ResultsEvent(chunk));
  }

  void updateProgress(SearchProgress progress) {
    if (_isCancelled) return;
    _controller.add(ProgressEvent(progress));
  }

  void addError(String engine, String error) {
    if (_isCancelled) return;
    _controller.add(ErrorEvent(engine, error));
  }

  void complete(SearchProgress finalProgress) {
    if (_isCancelled) return;
    _controller.add(
      CompletedEvent(
        allResults: _allResults,
        totalDuration: _startTime != null
            ? DateTime.now().difference(_startTime!)
            : Duration.zero,
        finalProgress: finalProgress,
      ),
    );
    _controller.close();
  }

  void cancel() {
    _isCancelled = true;
    _controller.close();
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class RateLimiter {
  RateLimiter({
    this.maxRequestsPerSecond = 5,
    this.windowDuration = const Duration(seconds: 1),
  });
  final int maxRequestsPerSecond;
  final Duration windowDuration;
  final Map<String, List<DateTime>> _requestTimes = {};
  bool canMakeRequest(String engine) {
    _cleanupOldRequests(engine);
    final times = _requestTimes[engine] ?? [];
    return times.length < maxRequestsPerSecond;
  }

  void recordRequest(String engine) {
    _requestTimes.putIfAbsent(engine, () => []);
    _requestTimes[engine]!.add(DateTime.now());
  }

  Future<void> waitForSlot(String engine) async {
    while (!canMakeRequest(engine)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Duration? timeUntilNextSlot(String engine) {
    _cleanupOldRequests(engine);
    final times = _requestTimes[engine] ?? [];
    if (times.length < maxRequestsPerSecond) return Duration.zero;
    final oldestInWindow = times.first;
    final nextAvailable = oldestInWindow.add(windowDuration);
    final waitTime = nextAvailable.difference(DateTime.now());
    return waitTime.isNegative ? Duration.zero : waitTime;
  }

  void _cleanupOldRequests(String engine) {
    final cutoff = DateTime.now().subtract(windowDuration);
    _requestTimes[engine]?.removeWhere((t) => t.isBefore(cutoff));
  }

  void reset() => _requestTimes.clear();
  void resetEngine(String engine) => _requestTimes.remove(engine);
}

class RetryConfig {
  const RetryConfig({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.exponentialBackoff = true,
    this.retryableStatusCodes = const {408, 429, 500, 502, 503, 504},
  });
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final bool exponentialBackoff;
  final Set<int> retryableStatusCodes;
  static const none = RetryConfig(maxRetries: 0);
  static const aggressive = RetryConfig(
    maxRetries: 5,
    baseDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 30),
  );
  Duration getDelay(int attempt) {
    if (!exponentialBackoff) return baseDelay;
    final delay = baseDelay * (1 << attempt);
    return delay > maxDelay ? maxDelay : delay;
  }

  bool shouldRetry(int statusCode) => retryableStatusCodes.contains(statusCode);
}
