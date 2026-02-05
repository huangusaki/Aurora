library;

import '../base_search_engine.dart';
import '../search_result.dart';

class BraveEngine extends BaseSearchEngine<TextSearchResult> {
  BraveEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'brave';
  @override
  String get category => 'text';
  @override
  String get provider => 'brave';
  @override
  String get searchUrl => 'https://search.brave.com/search';
  @override
  String get searchMethod => 'GET';
  @override
  String get itemsSelector => 'div[data-type="web"]';
  @override
  Map<String, String> get elementsSelector => {
        'title': 'div.title, div.sitename-container',
        'href': 'a',
        'body': 'div.description',
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
    final payload = {
      'q': query,
      'source': 'web',
    };
    if (timelimit != null) {
      payload['tf'] = {'d': 'pd', 'w': 'pw', 'm': 'pm', 'y': 'py'}[timelimit]!;
    }
    if (page > 1) {
      payload['offset'] = '${page - 1}';
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
