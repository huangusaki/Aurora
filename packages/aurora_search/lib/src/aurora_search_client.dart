library;

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'base_search_engine.dart';
import 'engines/engines.dart';
import 'exceptions.dart';
import 'instant_answers.dart';
import 'parallel_search.dart';
import 'results.dart';
import 'search_options.dart';
import 'search_result.dart';
import 'streaming.dart';
import 'utils.dart';

class AuroraSearch {
  AuroraSearch({
    String? proxy,
    Duration? timeout,
    bool verify = true,
    CacheConfig cacheConfig = CacheConfig.disabled,
    int maxRequestsPerSecond = 10,
  })  : _proxy =
            expandProxyTbAlias(proxy) ??
            Platform.environment['AURORA_SEARCH_PROXY'],
        _timeout = timeout ?? const Duration(seconds: 5),
        _verify = verify,
        _cache = cacheConfig.enabled ? ResultCache(cacheConfig) : null,
        _rateLimiter = RateLimiter(maxRequestsPerSecond: maxRequestsPerSecond);
  final String? _proxy;
  final Duration _timeout;
  final bool _verify;
  final Map<Type, BaseSearchEngine<SearchResult>> _enginesCache = {};
  final ResultCache? _cache;
  final RateLimiter _rateLimiter;
  InstantAnswerService? _instantAnswerService;
  int? threads;
  InstantAnswerService get instantAnswerService {
    _instantAnswerService ??= InstantAnswerService(
      proxy: _proxy,
      timeout: _timeout,
      verify: _verify,
    );
    return _instantAnswerService!;
  }

  List<BaseSearchEngine<SearchResult>> _getEngines(
      String category, String backend) {
    final backendList = backend.split(',').map((e) => e.trim()).toList();
    final engineKeys = engines[category]?.keys.toList() ?? [];
    engineKeys.shuffle();
    List<String> keys;
    if (backendList.contains('auto') || backendList.contains('all')) {
      keys = engineKeys;
      if (category == 'text') {
        keys = ['wikipedia', ...keys.where((k) => k != 'wikipedia')];
      }
    } else {
      keys = backendList;
    }
    try {
      final instances = <BaseSearchEngine<SearchResult>>[];
      for (final key in keys) {
        final engineClass = engines[category]?[key];
        if (engineClass == null) continue;
        if (_enginesCache.containsKey(engineClass.runtimeType)) {
          instances.add(_enginesCache[engineClass.runtimeType]!);
        } else {
          final instance = engineClass(
            proxy: _proxy,
            timeout: _timeout,
            verify: _verify,
          );
          _enginesCache[engineClass.runtimeType] = instance;
          instances.add(instance);
        }
      }
      instances.sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return Random().nextBool() ? 1 : -1;
      });
      return instances;
    } catch (e) {
      return _getEngines(category, 'auto');
    }
  }

  Future<List<SearchResult>> _searchTyped({
    required String category,
    required String query,
    String region = 'us-en',
    String safesearch = 'moderate',
    String? timelimit,
    int? maxResults = 10,
    int page = 1,
    String backend = 'auto',
    Map<String, dynamic>? extra,
  }) async {
    if (query.isEmpty) {
      throw AuroraSearchException('query is mandatory.');
    }
    final enginesList = _getEngines(category, backend);
    final uniqueProviders = enginesList.map((e) => e.provider).toSet();
    final seenProviders = <String>{};
    final Set<String> uniqueFields;
    switch (category) {
      case 'images':
        uniqueFields = {'image', 'url'};
        break;
      case 'videos':
        uniqueFields = {'embed_url'};
        break;
      default:
        uniqueFields = {'href', 'url'};
    }
    final resultsAggregator = ResultsAggregator<SearchResult>(uniqueFields);
    final maxWorkers = maxResults != null
        ? min(uniqueProviders.length, (maxResults / 10).ceil() + 1)
        : uniqueProviders.length;
    final futures = <Future<void>>[];
    var workersStarted = 0;
    for (final engine in enginesList) {
      if (seenProviders.contains(engine.provider)) {
        continue;
      }
      final future = _executeEngineSearch(
        engine,
        query,
        region,
        safesearch,
        timelimit,
        page,
        extra,
        resultsAggregator,
        seenProviders,
      );
      futures.add(future);
      workersStarted++;
      if (workersStarted >= maxWorkers) {
        await Future.wait(futures);
        futures.clear();
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    final allResults = resultsAggregator.results;
    if (maxResults != null && allResults.length > maxResults) {
      return allResults.take(maxResults).toList();
    }
    return allResults;
  }

  Future<List<Map<String, dynamic>>> _search({
    required String category,
    required String query,
    String region = 'us-en',
    String safesearch = 'moderate',
    String? timelimit,
    int? maxResults = 10,
    int page = 1,
    String backend = 'auto',
    Map<String, dynamic>? extra,
  }) async {
    final results = await _searchTyped(
      category: category,
      query: query,
      region: region,
      safesearch: safesearch,
      timelimit: timelimit,
      maxResults: maxResults,
      page: page,
      backend: backend,
      extra: extra,
    );
    return results.map((r) => r.toJson()).toList();
  }

  Future<void> _executeEngineSearch(
    BaseSearchEngine<SearchResult> engine,
    String query,
    String region,
    String safesearch,
    String? timelimit,
    int page,
    Map<String, dynamic>? extra,
    ResultsAggregator<SearchResult> resultsAggregator,
    Set<String> seenProviders,
  ) async {
    try {
      await _rateLimiter.waitForSlot(engine.name);
      _rateLimiter.recordRequest(engine.name);
      final results = await engine
          .search(
            query: query,
            region: region,
            safesearch: safesearch,
            timelimit: timelimit,
            page: page,
            extra: extra,
          )
          .timeout(_timeout);
      if (results != null && results.isNotEmpty) {
        resultsAggregator.addAll(results);
        seenProviders.add(engine.provider);
      }
    } catch (e) {
      stderr.writeln('Error in engine ${engine.name}: $e');
    }
  }

  Future<List<Map<String, dynamic>>> text(
    String query, {
    String region = 'us-en',
    String safesearch = 'moderate',
    String? timelimit,
    int? maxResults = 10,
    int page = 1,
    String backend = 'auto',
  }) =>
      _search(
        category: 'text',
        query: query,
        region: region,
        safesearch: safesearch,
        timelimit: timelimit,
        maxResults: maxResults,
        page: page,
        backend: backend,
      );
  Future<List<Map<String, dynamic>>> images(
    String query, {
    String region = 'us-en',
    String safesearch = 'moderate',
    String? timelimit,
    int? maxResults = 10,
    int page = 1,
    String backend = 'auto',
  }) =>
      _search(
        category: 'images',
        query: query,
        region: region,
        safesearch: safesearch,
        timelimit: timelimit,
        maxResults: maxResults,
        page: page,
        backend: backend,
      );
  Future<List<Map<String, dynamic>>> videos(
    String query, {
    String region = 'us-en',
    String safesearch = 'moderate',
    String? timelimit,
    int? maxResults = 10,
    int page = 1,
    String backend = 'auto',
  }) =>
      _search(
        category: 'videos',
        query: query,
        region: region,
        safesearch: safesearch,
        timelimit: timelimit,
        maxResults: maxResults,
        page: page,
        backend: backend,
      );
  Future<List<Map<String, dynamic>>> news(
    String query, {
    String region = 'us-en',
    String safesearch = 'moderate',
    String? timelimit,
    int? maxResults = 10,
    int page = 1,
    String backend = 'auto',
  }) =>
      _search(
        category: 'news',
        query: query,
        region: region,
        safesearch: safesearch,
        timelimit: timelimit,
        maxResults: maxResults,
        page: page,
        backend: backend,
      );
  Future<List<Map<String, dynamic>>> books(
    String query, {
    String region = 'us-en',
    String safesearch = 'moderate',
    int? maxResults = 10,
    int page = 1,
    String backend = 'auto',
  }) =>
      _search(
        category: 'books',
        query: query,
        region: region,
        safesearch: safesearch,
        maxResults: maxResults,
        page: page,
        backend: backend,
      );
  Future<List<TextSearchResult>> textTyped(
    String query, {
    SearchOptions options = const SearchOptions(),
  }) async {
    final results = await _searchTyped(
      category: 'text',
      query: query,
      region: options.region.code,
      safesearch: options.safeSearch.code,
      timelimit: options.timeLimit.code,
      maxResults: options.maxResults,
      page: options.page,
      backend: options.backend,
    );
    return results.whereType<TextSearchResult>().toList();
  }

  Future<List<ImageSearchResult>> imagesTyped(
    String query, {
    SearchOptions options = const SearchOptions(),
  }) async {
    final results = await _searchTyped(
      category: 'images',
      query: query,
      region: options.region.code,
      safesearch: options.safeSearch.code,
      timelimit: options.timeLimit.code,
      maxResults: options.maxResults,
      page: options.page,
      backend: options.backend,
    );
    return results.whereType<ImageSearchResult>().toList();
  }

  Future<List<VideoSearchResult>> videosTyped(
    String query, {
    SearchOptions options = const SearchOptions(),
  }) async {
    final results = await _searchTyped(
      category: 'videos',
      query: query,
      region: options.region.code,
      safesearch: options.safeSearch.code,
      timelimit: options.timeLimit.code,
      maxResults: options.maxResults,
      page: options.page,
      backend: options.backend,
    );
    return results.whereType<VideoSearchResult>().toList();
  }

  Future<List<NewsSearchResult>> newsTyped(
    String query, {
    SearchOptions options = const SearchOptions(),
  }) async {
    final results = await _searchTyped(
      category: 'news',
      query: query,
      region: options.region.code,
      safesearch: options.safeSearch.code,
      timelimit: options.timeLimit.code,
      maxResults: options.maxResults,
      page: options.page,
      backend: options.backend,
    );
    return results.whereType<NewsSearchResult>().toList();
  }

  Future<InstantAnswer?> instantAnswer(String query) =>
      instantAnswerService.getInstantAnswer(query);
  Future<List<SearchSuggestion>> suggestions(String query) =>
      instantAnswerService.getSuggestions(query);
  Future<String?> spellingCorrection(String query) =>
      instantAnswerService.getSpellingCorrection(query);
  Future<List<Map<String, dynamic>>> searchWithOptions(
    String query, {
    required String category,
    SearchOptions options = const SearchOptions(),
  }) {
    final cached = _cache?.get(category, query, options);
    if (cached != null) return Future.value(cached);
    return _search(
      category: category,
      query: query,
      region: options.region.code,
      safesearch: options.safeSearch.code,
      timelimit: options.timeLimit.code,
      maxResults: options.maxResults,
      page: options.page,
      backend: options.backend,
    ).then((results) {
      _cache?.put(category, query, options, results);
      return results;
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> batchSearch(
    List<String> queries, {
    String category = 'text',
    SearchOptions options = const SearchOptions(),
    int maxConcurrency = 3,
  }) async {
    final results = <String, List<Map<String, dynamic>>>{};
    final manager = ConcurrentSearchManager(maxConcurrency: maxConcurrency);
    final futures = queries.map(
      (query) async => manager.run(() async {
        final queryResults = await searchWithOptions(
          query,
          category: category,
          options: options,
        );
        return MapEntry(query, queryResults);
      }),
    );
    final entries = await Future.wait(futures);
    for (final entry in entries) {
      results[entry.key] = entry.value;
    }
    return results;
  }

  List<String> getAvailableEnginesFor(String category) =>
      engines[category]?.keys.toList() ?? [];
  CacheStats? get cacheStats => _cache?.stats;
  void clearCache() => _cache?.clear();
  void close() {
    for (final engine in _enginesCache.values) {
      engine.close();
    }
    _enginesCache.clear();
    _instantAnswerService?.close();
    _rateLimiter.reset();
  }
}
