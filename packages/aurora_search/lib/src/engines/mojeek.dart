library;

import '../base_search_engine.dart';
import '../search_result.dart';

class MojeekEngine extends BaseSearchEngine<TextSearchResult> {
  MojeekEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'mojeek';
  @override
  String get category => 'text';
  @override
  String get provider => 'mojeek';
  @override
  String get searchUrl => 'https://www.mojeek.com/search';
  @override
  String get searchMethod => 'GET';
  @override
  String get itemsSelector => 'ul.results li';
  @override
  Map<String, String> get elementsSelector => {
        'title': 'h2',
        'href': 'h2 a',
        'body': 'p.s',
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
    };
    if (safesearch == 'on') {
      payload['safe'] = '1';
    }
    if (page > 1) {
      payload['s'] = '${(page - 1) * 10 + 1}';
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
