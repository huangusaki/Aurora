library;

import '../base_search_engine.dart';
import '../results.dart';
import '../utils.dart';

class DuckDuckGoVideosEngine extends BaseSearchEngine<VideosResult> {
  DuckDuckGoVideosEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'duckduckgo';
  @override
  String get category => 'videos';
  @override
  String get provider => 'bing';
  @override
  String get searchUrl => 'https://duckduckgo.com/v.js';
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
    final filters = <String>[];
    if (timelimit != null) {
      filters.add('publishedAfter:$timelimit');
    }
    if (extra != null) {
      if (extra['resolution'] != null) {
        filters.add('videoDefinition:${extra['resolution']}');
      }
      if (extra['duration'] != null) {
        filters.add('videoDuration:${extra['duration']}');
      }
      if (extra['license_videos'] != null) {
        filters.add('videoLicense:${extra['license_videos']}');
      }
    }
    final payload = {
      'l': region,
      'o': 'json',
      'q': query,
      'f': filters.join(','),
      'p': safesearchMap[safesearch.toLowerCase()] ?? '-1',
    };
    if (page > 1) {
      payload['s'] = '${(page - 1) * 60}';
    }
    return payload;
  }

  @override
  Future<List<VideosResult>?> search({
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
  List<VideosResult> extractResults(String htmlText) {
    final results = <VideosResult>[];
    try {
      final jsonData = jsonDecode(htmlText) as Map<String, dynamic>;
      final items = jsonData['results'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final images = item['images'] as Map<String, dynamic>?;
        final statistics = item['statistics'] as Map<String, dynamic>?;
        results.add(
          VideosResult(
            title: item['title']?.toString() ?? '',
            content: item['content']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
            duration: item['duration']?.toString() ?? '',
            embedHtml: item['embed_html']?.toString() ?? '',
            embedUrl: item['embed_url']?.toString() ?? '',
            imageToken: item['image_token']?.toString() ?? '',
            images: images?.map((k, v) => MapEntry(k, v.toString())) ?? {},
            provider: item['provider']?.toString() ?? '',
            published: item['published']?.toString() ?? '',
            publisher: item['publisher']?.toString() ?? '',
            statistics:
                statistics?.map((k, v) => MapEntry(k, v.toString())) ?? {},
            uploader: item['uploader']?.toString() ?? '',
          ),
        );
      }
    } catch (e) {}
    return results;
  }
}
