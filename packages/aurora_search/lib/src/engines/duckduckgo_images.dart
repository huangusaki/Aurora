library;

import '../base_search_engine.dart';
import '../search_result.dart';
import '../utils.dart';

class DuckDuckGoImagesEngine extends BaseSearchEngine<ImageSearchResult> {
  DuckDuckGoImagesEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'duckduckgo';
  @override
  String get category => 'images';
  @override
  String get provider => 'bing';
  @override
  String get searchUrl => 'https://duckduckgo.com/i.js';
  @override
  String get searchMethod => 'GET';
  @override
  Map<String, String> get searchHeaders => {
        'Referer': 'https://duckduckgo.com/',
        'Sec-Fetch-Mode': 'cors',
      };
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
    final safesearchMap = {'on': '1', 'moderate': '1', 'off': '-1'};
    final timelimitMap = {'d': 'Day', 'w': 'Week', 'm': 'Month', 'y': 'Year'};
    final payload = {
      'o': 'json',
      'q': query,
      'l': region,
      'p': safesearchMap[safesearch.toLowerCase()] ?? '1',
    };
    final filters = <String>[];
    if (timelimit != null && timelimitMap.containsKey(timelimit)) {
      filters.add('time:${timelimitMap[timelimit]}');
    }
    if (extra != null) {
      if (extra['size'] != null) filters.add('size:${extra['size']}');
      if (extra['color'] != null) filters.add('color:${extra['color']}');
      if (extra['type_image'] != null) {
        filters.add('type:${extra['type_image']}');
      }
      if (extra['layout'] != null) filters.add('layout:${extra['layout']}');
      if (extra['license_image'] != null) {
        filters.add('license:${extra['license_image']}');
      }
    }
    if (filters.isNotEmpty) {
      payload['f'] = filters.join(',');
    }
    if (page > 1) {
      payload['s'] = '${(page - 1) * 100}';
    }
    return payload;
  }

  @override
  Future<List<ImageSearchResult>?> search({
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
      headers: searchHeaders,
    );
    if (htmlText == null) return null;
    final results = extractResults(htmlText);
    return postExtractResults(results);
  }

  @override
  List<ImageSearchResult> extractResults(String htmlText) {
    final results = <ImageSearchResult>[];
    try {
      final jsonData = jsonDecode(htmlText) as Map<String, dynamic>;
      final items = jsonData['results'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        results.add(
          ImageSearchResult.normalized(
            title: item['title']?.toString() ?? '',
            imageUrl: item['image']?.toString() ?? '',
            thumbnailUrl: item['thumbnail']?.toString() ?? '',
            sourceUrl: item['url']?.toString() ?? '',
            height: int.tryParse(item['height']?.toString() ?? ''),
            width: int.tryParse(item['width']?.toString() ?? ''),
            source: item['source']?.toString() ?? '',
            provider: name,
          ),
        );
      }
    } catch (_) {
      return results;
    }
    return results;
  }
}
