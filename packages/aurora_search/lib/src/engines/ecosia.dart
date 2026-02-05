library;

import '../base_search_engine.dart';
import '../search_result.dart';

class EcosiaEngine extends BaseSearchEngine<TextSearchResult> {
  EcosiaEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'ecosia';
  @override
  String get category => 'text';
  @override
  String get provider => 'ecosia';
  @override
  double get priority => 1.2;
  @override
  String get searchUrl => 'https://www.ecosia.org/search';
  @override
  String get searchMethod => 'GET';
  @override
  Map<String, String> get searchHeaders => {
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'en-US,en;q=0.9',
      };
  @override
  String get itemsSelector => 'article.result';
  @override
  Map<String, String> get elementsSelector => {
        'title': 'a.result-title',
        'href': 'a.result-title',
        'body': 'p.result-snippet',
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
    final payload = <String, String>{
      'q': query,
      'p': '${page - 1}',
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
    final document = extractTree(htmlText);
    var items = document.querySelectorAll(itemsSelector);
    if (items.isEmpty) {
      items = document.querySelectorAll('.result');
      if (items.isEmpty) {
        items = document.querySelectorAll('div[data-test-id="organic-result"]');
      }
    }
    for (final item in items) {
      final titleElement = item.querySelector(elementsSelector['title']!) ??
          item.querySelector('h2 a') ??
          item.querySelector('a[href]');
      final bodyElement = item.querySelector(elementsSelector['body']!) ??
          item.querySelector('.result-snippet') ??
          item.querySelector('p');
      final title = titleElement?.text ?? '';
      final href = titleElement?.attributes['href'] ?? '';
      final body = bodyElement?.text ?? '';
      if (title.isNotEmpty && href.isNotEmpty && href.startsWith('http')) {
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
