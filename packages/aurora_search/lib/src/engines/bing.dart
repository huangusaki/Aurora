library;

import '../base_search_engine.dart';
import '../search_result.dart';

class BingEngine extends BaseSearchEngine<TextSearchResult> {
  BingEngine({super.proxy, super.timeout, super.verify});
  @override
  String get name => 'bing';
  @override
  String get category => 'text';
  @override
  String get provider => 'bing';
  @override
  double get priority => 1.0;
  @override
  String get searchUrl => 'https://www.bing.com/search';
  @override
  String get searchMethod => 'GET';
  @override
  Map<String, String> get searchHeaders => {
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'en-US,en;q=0.9',
        'DNT': '1',
      };
  @override
  String get itemsSelector => '#b_results .b_algo';
  @override
  Map<String, String> get elementsSelector => {
        'title': 'h2 a',
        'href': 'h2 a',
        'body': '.b_caption p, .b_algoSlug',
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
    final lang = parts.isNotEmpty ? parts[0] : 'en';
    final country = parts.length > 1 ? parts[1].toUpperCase() : 'US';
    final payload = <String, String>{
      'q': query,
      'setlang': lang,
      'cc': country,
      'ensearch': '1',
      'mkt': 'en-US',
    };
    if (safesearch == 'off') {
      payload['adlt'] = 'off';
    } else if (safesearch == 'on') {
      payload['adlt'] = 'strict';
    } else {
      payload['adlt'] = 'moderate';
    }
    if (timelimit != null) {
      final filters = {
        'd': 'Day',
        'w': 'Week',
        'm': 'Month',
        'y': 'Year',
      };
      if (filters.containsKey(timelimit)) {
        payload['filters'] = 'ex1:"ez5_${filters[timelimit]}"';
      }
    }
    if (page > 1) {
      payload['first'] = '${(page - 1) * 10 + 1}';
    }
    return payload;
  }

  @override
  List<TextSearchResult> extractResults(String htmlText) {
    final results = <TextSearchResult>[];
    final document = extractTree(htmlText);
    final items = document.querySelectorAll(itemsSelector);
    for (final item in items) {
      final titleElement = item.querySelector('h2 a');
      final title = titleElement?.text ?? '';
      var href = titleElement?.attributes['href'] ?? '';
      if (href.contains('/ck/a?') && href.contains('&u=')) {
        href = _decodeBingRedirectUrl(href) ?? href;
      }
      var bodyElement = item.querySelector('.b_caption p');
      bodyElement ??= item.querySelector('.b_algoSlug');
      bodyElement ??= item.querySelector('p');
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

  String? _decodeBingRedirectUrl(String bingUrl) {
    try {
      final uri = Uri.tryParse(bingUrl);
      if (uri == null) return null;
      final encodedUrl = uri.queryParameters['u'];
      if (encodedUrl == null || encodedUrl.length < 3) return null;
      final base64Part = encodedUrl.substring(2);
      final decoded = Uri.decodeFull(
        String.fromCharCodes(_base64Decode(base64Part)),
      );
      if (decoded.startsWith('http')) {
        return decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<int> _base64Decode(String input) {
    try {
      var padded = input;
      while (padded.length % 4 != 0) {
        padded += '=';
      }
      padded = padded.replaceAll('-', '+').replaceAll('_', '/');
      return _decodeBase64(padded);
    } catch (e) {
      return [];
    }
  }

  List<int> _decodeBase64(String input) {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final output = <int>[];
    var buffer = 0;
    var bitsCollected = 0;
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '=') break;
      final value = alphabet.indexOf(char);
      if (value == -1) continue;
      buffer = (buffer << 6) | value;
      bitsCollected += 6;
      if (bitsCollected >= 8) {
        bitsCollected -= 8;
        output.add((buffer >> bitsCollected) & 0xFF);
      }
    }
    return output;
  }
}
