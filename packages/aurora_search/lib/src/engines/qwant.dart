library;

import 'dart:convert';
import '../base_search_engine.dart';
import '../search_result.dart';

class QwantEngine extends BaseSearchEngine<TextSearchResult> {
  QwantEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'qwant';
  @override
  String get category => 'text';
  @override
  String get provider => 'qwant';
  @override
  double get priority => 1.1;
  @override
  String get searchUrl => 'https://api.qwant.com/v3/search/web';
  @override
  String get searchMethod => 'GET';
  @override
  Map<String, String> get searchHeaders => {
        'Accept': 'application/json',
        'Origin': 'https://www.qwant.com',
        'Referer': 'https://www.qwant.com/',
      };
  @override
  String get itemsSelector => '';
  @override
  Map<String, String> get elementsSelector => {};
  @override
  Map<String, String> buildPayload({
    required String query,
    required String region,
    required String safesearch,
    String? timelimit,
    int page = 1,
    Map<String, dynamic>? extra,
  }) {
    final parts = region.toLowerCase().split('-');
    final locale =
        parts.length > 1 ? '${parts[1]}_${parts[0].toUpperCase()}' : 'en_US';
    final safeLevel = {
      'off': '0',
      'moderate': '1',
      'on': '2',
    };
    final payload = <String, String>{
      'q': query,
      'count': '10',
      'offset': '${(page - 1) * 10}',
      'locale': locale,
      'safesearch': safeLevel[safesearch] ?? '1',
      't': 'web',
    };
    if (timelimit != null) {
      final freshness = {
        'd': 'day',
        'w': 'week',
        'm': 'month',
        'y': 'year',
      };
      if (freshness.containsKey(timelimit)) {
        payload['freshness'] = freshness[timelimit]!;
      }
    }
    return payload;
  }

  @override
  List<TextSearchResult> extractResults(String htmlText) {
    final results = <TextSearchResult>[];
    try {
      final json = jsonDecode(htmlText) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      final resultData = data?['result'] as Map<String, dynamic>?;
      final items = resultData?['items'] as Map<String, dynamic>?;
      final mainItems = items?['mainline'] as List<dynamic>? ?? [];
      for (final section in mainItems) {
        if (section is Map<String, dynamic> && section['type'] == 'web') {
          final webItems = section['items'] as List<dynamic>? ?? [];
          for (final item in webItems) {
            if (item is Map<String, dynamic>) {
              final title = item['title'] as String? ?? '';
              final url = item['url'] as String? ?? '';
              final desc = item['desc'] as String? ?? '';
              if (title.isNotEmpty && url.isNotEmpty) {
                results.add(
                  TextSearchResult.normalized(
                    title: title,
                    href: url,
                    body: desc,
                    provider: name,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      final document = extractTree(htmlText);
      final items = document.querySelectorAll('.result, .web-result');
      for (final item in items) {
        final titleEl = item.querySelector('a.result-title, h2 a');
        final bodyEl = item.querySelector('p.result-desc, .result-snippet');
        final title = titleEl?.text ?? '';
        final href = titleEl?.attributes['href'] ?? '';
        final body = bodyEl?.text ?? '';
        if (title.isNotEmpty && href.isNotEmpty) {
          results.add(
            TextSearchResult.normalized(
              title: title,
              href: href,
              body: body,
              provider: name,
            ),
          );
        }
      }
    }
    return results;
  }
}

class QwantImagesEngine extends BaseSearchEngine<ImageSearchResult> {
  QwantImagesEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'qwant_images';
  @override
  String get category => 'images';
  @override
  String get provider => 'qwant';
  @override
  String get searchUrl => 'https://api.qwant.com/v3/search/images';
  @override
  String get searchMethod => 'GET';
  @override
  Map<String, String> get searchHeaders => {
        'Accept': 'application/json',
        'Origin': 'https://www.qwant.com',
      };
  @override
  String get itemsSelector => '';
  @override
  Map<String, String> get elementsSelector => {};
  @override
  Map<String, String> buildPayload({
    required String query,
    required String region,
    required String safesearch,
    String? timelimit,
    int page = 1,
    Map<String, dynamic>? extra,
  }) {
    final parts = region.toLowerCase().split('-');
    final locale =
        parts.length > 1 ? '${parts[1]}_${parts[0].toUpperCase()}' : 'en_US';
    return {
      'q': query,
      'count': '20',
      'offset': '${(page - 1) * 20}',
      'locale': locale,
      't': 'images',
    };
  }

  @override
  List<ImageSearchResult> extractResults(String htmlText) {
    final results = <ImageSearchResult>[];
    try {
      final json = jsonDecode(htmlText) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      final resultData = data?['result'] as Map<String, dynamic>?;
      final items = resultData?['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final title = item['title'] as String? ?? '';
          final mediaUrl = item['media'] as String? ?? '';
          final thumbnailUrl = item['thumbnail'] as String? ?? '';
          final sourceUrl = item['url'] as String? ?? '';
          final width = int.tryParse(item['width']?.toString() ?? '');
          final height = int.tryParse(item['height']?.toString() ?? '');
          if (mediaUrl.isNotEmpty) {
            results.add(
              ImageSearchResult.normalized(
                title: title,
                imageUrl: mediaUrl,
                thumbnailUrl: thumbnailUrl,
                sourceUrl: sourceUrl,
                width: width,
                height: height,
                source: 'qwant',
                provider: name,
              ),
            );
          }
        }
      }
    } catch (_) {
      return results;
    }
    return results;
  }
}

class QwantNewsEngine extends BaseSearchEngine<NewsSearchResult> {
  QwantNewsEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'qwant_news';
  @override
  String get category => 'news';
  @override
  String get provider => 'qwant';
  @override
  String get searchUrl => 'https://api.qwant.com/v3/search/news';
  @override
  String get searchMethod => 'GET';
  @override
  Map<String, String> get searchHeaders => {
        'Accept': 'application/json',
        'Origin': 'https://www.qwant.com',
      };
  @override
  String get itemsSelector => '';
  @override
  Map<String, String> get elementsSelector => {};
  @override
  Map<String, String> buildPayload({
    required String query,
    required String region,
    required String safesearch,
    String? timelimit,
    int page = 1,
    Map<String, dynamic>? extra,
  }) {
    final parts = region.toLowerCase().split('-');
    final locale =
        parts.length > 1 ? '${parts[1]}_${parts[0].toUpperCase()}' : 'en_US';
    return {
      'q': query,
      'count': '20',
      'offset': '${(page - 1) * 20}',
      'locale': locale,
      't': 'news',
    };
  }

  @override
  List<NewsSearchResult> extractResults(String htmlText) {
    final results = <NewsSearchResult>[];
    try {
      final json = jsonDecode(htmlText) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      final resultData = data?['result'] as Map<String, dynamic>?;
      final items = resultData?['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final title = item['title'] as String? ?? '';
          final url = item['url'] as String? ?? '';
          final desc = item['desc'] as String? ?? '';
          final date = item['date']?.toString() ?? '';
          final source = item['source'] as String? ?? '';
          final thumbnail = item['thumbnail'] as String?;
          if (title.isNotEmpty && url.isNotEmpty) {
            results.add(
              NewsSearchResult.normalized(
                title: title,
                url: url,
                body: desc,
                dateRaw: date,
                publishedDate: DateTime.tryParse(date),
                source: source,
                imageUrl: thumbnail,
                provider: name,
              ),
            );
          }
        }
      }
    } catch (_) {
      return results;
    }
    return results;
  }
}
