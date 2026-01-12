library;

import '../base_search_engine.dart';
import '../results.dart';
import '../utils.dart';

class DuckDuckGoNewsEngine extends BaseSearchEngine<NewsResult> {
  DuckDuckGoNewsEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'duckduckgo';
  @override
  String get category => 'news';
  @override
  String get provider => 'bing';
  @override
  String get searchUrl => 'https://duckduckgo.com/news.js';
  @override
  String get searchMethod => 'GET';
  @override
  String get itemsSelector => '';
  @override
  Map<String, String> get elementsSelector => {};
  Future<String?> _getVqd(String query) async {
    try {
      final response = await httpClient.get(
        Uri.parse('https://duckduckgo.com'),
        params: {'q': query},
      );
      return extractVqd(response.body, query);
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, String> buildPayload({
    required String query,
    required String region,
    required String safesearch,
    String? timelimit,
    int page = 1,
    Map<String, dynamic>? extra,
  }) {
    final safesearchMap = {'on': '1', 'moderate': '-1', 'off': '-2'};
    final payload = {
      'l': region,
      'o': 'json',
      'noamp': '1',
      'q': query,
      'p': safesearchMap[safesearch.toLowerCase()] ?? '-1',
    };
    if (timelimit != null) {
      payload['df'] = timelimit;
    }
    if (page > 1) {
      payload['s'] = '${(page - 1) * 30}';
    }
    return payload;
  }

  @override
  Future<List<NewsResult>?> search({
    required String query,
    String region = 'us-en',
    String safesearch = 'moderate',
    String? timelimit,
    int page = 1,
    Map<String, dynamic>? extra,
  }) async {
    final vqd = await _getVqd(query);
    if (vqd == null) return null;
    final payload = buildPayload(
      query: query,
      region: region,
      safesearch: safesearch,
      timelimit: timelimit,
      page: page,
      extra: extra,
    );
    payload['vqd'] = vqd;
    final htmlText = await request(
      searchMethod,
      searchUrl,
      params: payload,
    );
    if (htmlText == null) return null;
    final results = extractResults(htmlText);
    return postExtractResults(results);
  }

  @override
  List<NewsResult> extractResults(String htmlText) {
    final results = <NewsResult>[];
    try {
      final jsonData = jsonDecode(htmlText) as Map<String, dynamic>;
      final items = jsonData['results'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        results.add(
          NewsResult(
            date: item['date']?.toString() ?? '',
            title: item['title']?.toString() ?? '',
            body: item['excerpt']?.toString() ?? '',
            url: item['url']?.toString() ?? '',
            image: item['image']?.toString() ?? '',
            source: item['source']?.toString() ?? '',
          ),
        );
      }
    } catch (e) {}
    return results;
  }
}
