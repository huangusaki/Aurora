library;

import '../base_search_engine.dart';
import '../search_result.dart';
import '../utils.dart';

class DuckDuckGoVideosEngine extends BaseSearchEngine<VideoSearchResult> {
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
  Future<List<VideoSearchResult>?> search({
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
  List<VideoSearchResult> extractResults(String htmlText) {
    final results = <VideoSearchResult>[];
    try {
      final jsonData = jsonDecode(htmlText) as Map<String, dynamic>;
      final items = jsonData['results'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final title = item['title']?.toString() ?? '';
        final content = item['content']?.toString() ?? '';
        final description = item['description']?.toString() ?? '';
        final embedUrl = item['embed_url']?.toString() ?? '';
        final images = item['images'] as Map<String, dynamic>?;
        final thumbnail = images == null ? null : _pickThumbnail(images);
        final result = VideoSearchResult.fromJson({
          'title': title,
          'description': description.isNotEmpty ? description : content,
          'embed_url': embedUrl,
          'embed_html': item['embed_html']?.toString(),
          'thumbnail': thumbnail,
          'duration': item['duration']?.toString(),
          'publisher': item['publisher']?.toString(),
          'uploader': item['uploader']?.toString(),
          'publishedDate': item['published']?.toString(),
          'provider': name,
        });
        if (title.isNotEmpty && embedUrl.isNotEmpty) {
          results.add(result);
        }
      }
    } catch (_) {
      return results;
    }
    return results;
  }

  String? _pickThumbnail(Map<String, dynamic> images) {
    const preferredKeys = ['medium', 'small', 'large', 'thumbnail'];
    for (final key in preferredKeys) {
      final value = images[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    for (final value in images.values) {
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}
