library;

import 'dart:math';
import '../base_search_engine.dart';
import '../search_result.dart';

class YandexEngine extends BaseSearchEngine<TextSearchResult> {
  YandexEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'yandex';
  @override
  String get category => 'text';
  @override
  String get provider => 'yandex';
  @override
  String get searchUrl => 'https://yandex.com/search/site/';
  @override
  String get searchMethod => 'GET';
  @override
  String get itemsSelector => 'li.serp-item';
  @override
  Map<String, String> get elementsSelector => {
        'title': 'h3',
        'href': 'h3 a',
        'body': 'div.text',
      };
  @override
  Map<String, String> buildPayload({
    required String query,
    required String region,
    required String safesearch,
    String? timelimit,
    int page = 1,
    Map<String, dynamic>? extra,
  }) {
    final random = Random.secure();
    final payload = {
      'text': query,
      'web': '1',
      'searchid': '${random.nextInt(9000000) + 1000000}',
    };
    if (page > 1) {
      payload['p'] = '${page - 1}';
    }
    return payload;
  }

  @override
  List<TextSearchResult> extractResults(String htmlText) {
    final results = <TextSearchResult>[];
    final document = extractTree(htmlText);
    final items = document.querySelectorAll(itemsSelector);
    for (final item in items) {
      final titleElement = item.querySelector(elementsSelector['title']!);
      final hrefElement = item.querySelector(elementsSelector['href']!);
      final bodyElement = item.querySelector(elementsSelector['body']!);
      final title = titleElement?.text ?? '';
      final href = hrefElement?.attributes['href'] ?? '';
      final body = bodyElement?.text ?? '';
      if (title.isNotEmpty || href.isNotEmpty) {
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
    return results;
  }
}
