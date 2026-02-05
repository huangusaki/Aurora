library;

import '../base_search_engine.dart';
import '../search_result.dart';

class StartPageEngine extends BaseSearchEngine<TextSearchResult> {
  StartPageEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'startpage';
  @override
  String get category => 'text';
  @override
  String get provider => 'startpage';
  @override
  double get priority => 1.3;
  @override
  String get searchUrl => 'https://www.startpage.com/sp/search';
  @override
  String get searchMethod => 'POST';
  @override
  Map<String, String> get searchHeaders => {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'text/html,application/xhtml+xml',
      };
  @override
  String get itemsSelector => '.w-gl__result';
  @override
  Map<String, String> get elementsSelector => {
        'title': '.w-gl__result-title',
        'href': 'a.w-gl__result-url',
        'body': '.w-gl__description',
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
    final parts = region.toLowerCase().split('-');
    final lang = parts.length > 1 ? parts[1] : 'en';
    final payload = <String, String>{
      'query': query,
      'cat': 'web',
      'language': lang,
      'abp': '-1',
    };
    if (page > 1) {
      payload['page'] = '$page';
    }
    if (timelimit != null) {
      final dateRestrict = {
        'd': 'd',
        'w': 'w',
        'm': 'm',
        'y': 'y',
      };
      if (dateRestrict.containsKey(timelimit)) {
        payload['with_date'] = dateRestrict[timelimit]!;
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
        items = document.querySelectorAll('article.result');
      }
    }
    for (final item in items) {
      var titleElement = item.querySelector(elementsSelector['title']!);
      titleElement ??= item.querySelector('h3, h2');
      final title = titleElement?.text ?? '';
      var linkElement = item.querySelector(elementsSelector['href']!);
      linkElement ??= item.querySelector('a[href^="http"]');
      final href = linkElement?.attributes['href'] ?? '';
      var bodyElement = item.querySelector(elementsSelector['body']!);
      bodyElement ??= item.querySelector('p, .description');
      final body = bodyElement?.text ?? '';
      if (title.isNotEmpty &&
          href.isNotEmpty &&
          !href.contains('startpage.com')) {
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
