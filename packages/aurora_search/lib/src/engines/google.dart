library;

import '../base_search_engine.dart';
import '../search_result.dart';

class GoogleEngine extends BaseSearchEngine<TextSearchResult> {
  GoogleEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'google';
  @override
  String get category => 'text';
  @override
  String get provider => 'google';
  @override
  double get priority => 1.5;
  @override
  String get searchUrl => 'https://www.google.com/search';
  @override
  String get searchMethod => 'GET';
  @override
  Map<String, String> get searchHeaders => {
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'en-US,en;q=0.9',
        'DNT': '1',
      };
  @override
  String get itemsSelector => 'div.g, div.xpd, div.mnr-c';
  @override
  Map<String, String> get elementsSelector => {
        'title': 'h3',
        'href': 'a',
        'body': 'div[data-snf], div.VwiC3b, span.aCOpRe',
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
    final country = parts.isNotEmpty ? parts[0] : 'us';
    final payload = <String, String>{
      'q': query,
      'hl': lang,
      'gl': country,
      'num': '10',
    };
    if (safesearch == 'off') {
      payload['safe'] = 'off';
    } else if (safesearch == 'on') {
      payload['safe'] = 'active';
    }
    if (timelimit != null) {
      final tbs = {
        'd': 'qdr:d',
        'w': 'qdr:w',
        'm': 'qdr:m',
        'y': 'qdr:y',
      };
      if (tbs.containsKey(timelimit)) {
        payload['tbs'] = tbs[timelimit]!;
      }
    }
    if (page > 1) {
      payload['start'] = '${(page - 1) * 10}';
    }
    return payload;
  }

  @override
  List<TextSearchResult> extractResults(String htmlText) {
    final results = <TextSearchResult>[];
    final document = extractTree(htmlText);
    var items = document.querySelectorAll(itemsSelector);
    if (items.isEmpty) {
      items = document.querySelectorAll('div[data-sokoban-container]');
    }
    for (final item in items) {
      final titleElement = item.querySelector('h3');
      final title = titleElement?.text ?? '';
      var linkElement = item.querySelector('a[href^="http"]');
      linkElement ??= item.querySelector('a[data-ved]');
      var href = linkElement?.attributes['href'] ?? '';
      if (href.startsWith('/url?')) {
        final uri = Uri.tryParse('https://google.com$href');
        href = uri?.queryParameters['q'] ?? href;
      }
      var bodyElement = item.querySelector('div[data-snf]');
      bodyElement ??= item.querySelector('div.VwiC3b');
      bodyElement ??= item.querySelector('span.aCOpRe');
      bodyElement ??= item.querySelector('div[style*="line-clamp"]');
      final body = bodyElement?.text ?? '';
      if (title.isNotEmpty &&
          href.isNotEmpty &&
          !href.contains('google.com/search')) {
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

class GoogleImagesEngine extends BaseSearchEngine<ImageSearchResult> {
  GoogleImagesEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'google_images';
  @override
  String get category => 'images';
  @override
  String get provider => 'google';
  @override
  String get searchUrl => 'https://www.google.com/search';
  @override
  String get searchMethod => 'GET';
  @override
  String get itemsSelector => 'div[data-ri]';
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
    final lang = parts.length > 1 ? parts[1] : 'en';
    return {
      'q': query,
      'tbm': 'isch',
      'hl': lang,
      if (safesearch == 'on') 'safe': 'active',
    };
  }

  @override
  List<ImageSearchResult> extractResults(String htmlText) {
    final results = <ImageSearchResult>[];
    final regex =
        RegExp(r'\["(https?://[^"]+\.(jpg|jpeg|png|gif|webp))"[^\]]*\]');
    final matches = regex.allMatches(htmlText);
    for (final match in matches.take(20)) {
      final imageUrl = match.group(1);
      if (imageUrl != null && !imageUrl.contains('gstatic.com')) {
        results.add(
          ImageSearchResult.normalized(
            title: 'Google Image',
            imageUrl: imageUrl,
            thumbnailUrl: imageUrl,
            sourceUrl: imageUrl,
            source: 'google',
            provider: name,
          ),
        );
      }
    }
    return results;
  }
}
