library;

import 'dart:convert';
import '../base_search_engine.dart';
import '../search_result.dart';
import 'package:html/parser.dart' as html_parser;

class WikipediaEngine extends BaseSearchEngine<TextSearchResult> {
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
  List<TextSearchResult> extractResults(String htmlText) {
    final results = <TextSearchResult>[];
    try {
      final json = jsonDecode(htmlText) as Map<String, dynamic>;
      final query = json['query'] as Map<String, dynamic>?;
      final search = query?['search'] as List<dynamic>? ?? const [];
      for (final item in search) {
        if (item is! Map<String, dynamic>) continue;
        final title = item['title'] as String? ?? '';
        final snippet = item['snippet'] as String? ?? '';
        final pageId = item['pageid'];
        final href = pageId != null
            ? 'https://en.wikipedia.org/?curid=$pageId'
            : '';
        final body = html_parser.parseFragment(snippet).text ?? '';
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
    } catch (_) {
      return results;
    }
    return results;
  }
}
