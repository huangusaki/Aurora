library;

import '../base_search_engine.dart';
import '../search_result.dart';

String extractYahooUrl(String u) {
  try {
    final parts = u.split('/RU=');
    if (parts.length < 2) return u;
    final decoded =
        Uri.decodeComponent(parts[1].split('/RK=')[0].split('/RS=')[0]);
    return decoded;
  } catch (e) {
    return u;
  }
}

class YahooEngine extends BaseSearchEngine<TextSearchResult> {
  YahooEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'yahoo';
  @override
  String get category => 'text';
  @override
  String get provider => 'bing';
  @override
  String get searchUrl => 'https://search.yahoo.com/search';
  @override
  String get searchMethod => 'GET';
  @override
  String get itemsSelector => 'div.relsrch';
  @override
  Map<String, String> get elementsSelector => {
        'title': 'div.Title h3',
        'href': 'div.Title a',
        'body': 'div.Text',
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
      'p': query,
    };
    if (page > 1) {
      payload['b'] = '${(page - 1) * 7 + 1}';
    }
    if (timelimit != null) {
      payload['btf'] = timelimit;
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
      var href = hrefElement?.attributes['href'] ?? '';
      final body = bodyElement?.text ?? '';
      if (href.contains('/RU=')) {
        href = extractYahooUrl(href);
      }
      if ((title.isNotEmpty || href.isNotEmpty) &&
          !href.startsWith('https://www.bing.com/aclick?')) {
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
