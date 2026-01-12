library;

import '../base_search_engine.dart';
import '../results.dart';

class WikipediaEngine extends BaseSearchEngine<TextResult> {
  WikipediaEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'wikipedia';
  @override
  String get category => 'text';
  @override
  String get provider => 'wikipedia';
  @override
  String get searchUrl => 'https://en.wikipedia.org/w/api.php';
  @override
  String get searchMethod => 'GET';
  @override
  String get itemsSelector => '.mw-search-result';
  @override
  Map<String, String> get elementsSelector => {
        'title': '.mw-search-result-heading',
        'href': '.mw-search-result-heading a',
        'body': '.searchresult',
      };
  @override
  Map<String, String> buildPayload({
    required String query,
    required String region,
    required String safesearch,
    String? timelimit,
    int page = 1,
    Map<String, dynamic>? extra,
  }) =>
      {
        'action': 'query',
        'list': 'search',
        'srsearch': query,
        'format': 'json',
        'srlimit': '10',
        'sroffset': ((page - 1) * 10).toString(),
      };
  @override
  List<TextResult> extractResults(String htmlText) {
    final results = <TextResult>[];
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
        final fullHref =
            href.startsWith('http') ? href : 'https://en.wikipedia.org$href';
        results.add(TextResult(title: title, href: fullHref, body: body));
      }
    }
    return results;
  }
}
