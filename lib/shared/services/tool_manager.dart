import 'dart:convert';
import 'package:ddgs/ddgs.dart';

class ToolManager {
  final DDGS _ddgs = DDGS();
  List<Map<String, dynamic>> getTools() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'search_web',
          'description':
              'Search the web for current information. Use this when the user asks about up-to-date events, news, or specific knowledge that might be recent.',
          'parameters': {
            'type': 'object',
            'required': ['query'],
            'properties': {
              'query': {
                'type': 'string',
                'description': 'The search query to execute.'
              },
              'region': {
                'type': 'string',
                'description':
                    'The region to search in. PREFER "us-en" for high-quality results. Defaults to "us-en".',
                'enum': ['us-en', 'wt-wt', 'zh-cn', 'jp-jp', 'de-de', 'fr-fr']
              }
            }
          }
        }
      }
    ];
  }

  Future<String> executeTool(String name, Map<String, dynamic> args,
      {String preferredEngine = 'duckduckgo'}) async {
    if (name == 'search_web') {
      final query = args['query'] as String;
      final region = args['region'] as String? ?? 'us-en';
      final result = await _searchWeb(query, preferredEngine, region: region);
      return result;
    }
    return jsonEncode({'error': 'Tool not found: $name'});
  }

  Future<String> _searchWeb(String query, String preferredEngine,
      {String region = 'us-en'}) async {
    final enginesToTry = {
      preferredEngine,
      'duckduckgo',
      'bing',
      'google',
    }.toList();
    List<Map<String, dynamic>> finalResults = [];
    String successfulEngine = '';
    List<String> errors = [];
    for (final engine in enginesToTry) {
      if (finalResults.isNotEmpty) break;
      try {
        final results = await _ddgs
            .text(
              query,
              region: region,
              backend: engine,
              maxResults: 5,
            )
            .timeout(const Duration(seconds: 10));
        if (results.isNotEmpty) {
          finalResults = results;
          successfulEngine = engine;
        }
      } catch (e) {
        errors.add('$engine: $e');
      }
    }
    if (finalResults.isEmpty) {
      return jsonEncode({
        'status': 'error',
        'message':
            'No results found after trying mechanisms: ${enginesToTry.join(', ')}. Errors: ${errors.join('; ')}'
      });
    }
    final formattedResults = finalResults.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final r = entry.value;
      return {
        'index': index,
        'title': r['title'],
        'link': r['href'],
        'snippet': r['body'],
      };
    }).toList();
    return jsonEncode({
      'status': 'success',
      'engine': successfulEngine,
      'results': formattedResults
    });
  }
}
