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
  })  : _proxy = expandProxyTbAlias(proxy) ??
            Platform.environment['AURORA_SEARCH_PROXY'],
        _timeout = timeout ?? const Duration(seconds: 5),
        _verify = verify,
        _cache = cacheConfig.enabled ? ResultCache(cacheConfig) : null,
        _rateLimiter = RateLimiter(maxRequestsPerSecond: maxRequestsPerSecond);
  final String? _proxy;
  final Duration _timeout;
  final bool _verify;
  final Map<String, BaseSearchEngine<SearchResult>> _enginesCache = {};
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
    final categoryEngines = engines[category];
    if (categoryEngines == null || categoryEngines.isEmpty) {
      return const [];
    }

    final backendList = backend
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    final engineKeys = categoryEngines.keys.toList();
    engineKeys.shuffle();

    List<String> keys;
    final autoSelect = backendList.isEmpty ||
        backendList.contains('auto') ||
        backendList.contains('all');
    if (autoSelect) {
      keys = engineKeys;
      if (category == 'text') {
        keys = ['wikipedia', ...keys.where((k) => k != 'wikipedia')];
      }
    } else {
      keys = backendList.where(categoryEngines.containsKey).toList();
      if (keys.isEmpty) {
        keys = engineKeys;
      }
    }

    final instances = <BaseSearchEngine<SearchResult>>[];
    for (final key in keys) {
      final engineFactory = categoryEngines[key];
      if (engineFactory == null) continue;

      final cacheKey = '$category::$key';
      final instance = _enginesCache.putIfAbsent(
        cacheKey,
        () => engineFactory(
          proxy: _proxy,
          timeout: _timeout,
          verify: _verify,
        ),
      );
      instances.add(instance);
    }

    final insertionOrder = <BaseSearchEngine<SearchResult>, int>{};
    for (var i = 0; i < instances.length; i++) {
      insertionOrder[instances[i]] = i;
    }

    instances.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return insertionOrder[a]!.compareTo(insertionOrder[b]!);
    });

    return instances;
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
    if (maxResults != null && maxResults <= 0) {
      return const [];
    }

    final enginesList = _getEngines(category, backend);
    if (enginesList.isEmpty) {
      return const [];
    }

    final uniqueProviders = enginesList.map((e) => e.provider).toSet();
    final scheduledProviders = <String>{};
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
    final manager = ConcurrentSearchManager(
      maxConcurrency: max(1, maxWorkers),
    );
    final futures = <Future<void>>[];
    for (final engine in enginesList) {
      if (!scheduledProviders.add(engine.provider)) {
        continue;
      }
      final future = manager.run(
        () => _executeEngineSearch(
          engine,
          query,
          region,
          safesearch,
          timelimit,
          page,
          extra,
          resultsAggregator,
        ),
      );
      futures.add(future);
    }
    await Future.wait(futures);

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
      }
    } catch (e) {
      print('Error in engine ${engine.name}: $e');
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
