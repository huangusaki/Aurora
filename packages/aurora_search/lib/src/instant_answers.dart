library;

import 'dart:convert';
import 'http_client.dart';

enum InstantAnswerType {
  definition,
  calculation,
  conversion,
  translation,
  weather,
  wikipedia,
  infobox,
  relatedTopics,
  unknown,
}

class InstantAnswer {
  const InstantAnswer({
    required this.answer,
    required this.source,
    this.sourceUrl,
    this.type = InstantAnswerType.unknown,
    this.abstract,
    this.imageUrl,
    this.relatedTopics = const [],
    this.infobox,
  });
  final String answer;
  final String source;
  final String? sourceUrl;
  final InstantAnswerType type;
  final String? abstract;
  final String? imageUrl;
  final List<RelatedTopic> relatedTopics;
  final Map<String, String>? infobox;
  bool get hasContent => answer.isNotEmpty || (abstract?.isNotEmpty ?? false);
  Map<String, dynamic> toJson() => {
        'answer': answer,
        'source': source,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
        'type': type.name,
        if (abstract != null) 'abstract': abstract,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (relatedTopics.isNotEmpty)
          'relatedTopics': relatedTopics.map((t) => t.toJson()).toList(),
        if (infobox != null) 'infobox': infobox,
      };
}

class RelatedTopic {
  const RelatedTopic({
    required this.text,
    required this.url,
    this.icon,
  });
  final String text;
  final String url;
  final String? icon;
  Map<String, dynamic> toJson() => {
        'text': text,
        'url': url,
        if (icon != null) 'icon': icon,
      };
}

class SearchSuggestion {
  const SearchSuggestion({
    required this.suggestion,
    this.score = 0,
    this.category,
  });
  final String suggestion;
  final int score;
  final String? category;
  Map<String, dynamic> toJson() => {
        'suggestion': suggestion,
        'score': score,
        if (category != null) 'category': category,
      };
}

class InstantAnswerService {
  InstantAnswerService({
    String? proxy,
    Duration? timeout,
    bool verify = true,
  }) : _httpClient = HttpClient(
          proxy: proxy,
          timeout: timeout,
          verify: verify,
        );
  final HttpClient _httpClient;
  Future<InstantAnswer?> getInstantAnswer(String query) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('https://api.duckduckgo.com/'),
        params: {
          'q': query,
          'format': 'json',
          'no_redirect': '1',
          'no_html': '1',
          'skip_disambig': '1',
        },
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseInstantAnswer(data);
    } catch (e) {
      return null;
    }
  }

  InstantAnswer? _parseInstantAnswer(Map<String, dynamic> data) {
    final heading = data['Heading'] as String? ?? '';
    final abstractText = data['AbstractText'] as String? ?? '';
    final answer = data['Answer'] as String? ?? '';
    final definition = data['Definition'] as String? ?? '';
    final abstractSource = data['AbstractSource'] as String? ?? '';
    final abstractUrl = data['AbstractURL'] as String?;
    final imageUrl = data['Image'] as String?;
    var type = InstantAnswerType.unknown;
    var answerText = '';
    if (answer.isNotEmpty) {
      answerText = answer;
      type = _inferAnswerType(answer);
    } else if (definition.isNotEmpty) {
      answerText = definition;
      type = InstantAnswerType.definition;
    } else if (abstractText.isNotEmpty) {
      answerText = heading;
      type = InstantAnswerType.wikipedia;
    }
    final relatedTopics = <RelatedTopic>[];
    final relatedData = data['RelatedTopics'] as List<dynamic>? ?? [];
    for (final topic in relatedData.take(5)) {
      if (topic is Map<String, dynamic>) {
        final text = topic['Text'] as String? ?? '';
        final url = topic['FirstURL'] as String? ?? '';
        final icon = topic['Icon']?['URL'] as String?;
        if (text.isNotEmpty && url.isNotEmpty) {
          relatedTopics.add(RelatedTopic(text: text, url: url, icon: icon));
        }
      }
    }
    Map<String, String>? infobox;
    final infoboxData = data['Infobox'] as Map<String, dynamic>?;
    if (infoboxData != null) {
      final content = infoboxData['content'] as List<dynamic>? ?? [];
      infobox = {};
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final label = item['label'] as String? ?? '';
          final value = item['value']?.toString() ?? '';
          if (label.isNotEmpty && value.isNotEmpty) {
            infobox[label] = value;
          }
        }
      }
    }
    if (answerText.isEmpty && abstractText.isEmpty && relatedTopics.isEmpty) {
      return null;
    }
    return InstantAnswer(
      answer: answerText,
      source: abstractSource,
      sourceUrl: abstractUrl,
      type: type,
      abstract: abstractText.isNotEmpty ? abstractText : null,
      imageUrl: imageUrl?.isNotEmpty ?? false
          ? 'https://duckduckgo.com$imageUrl'
          : null,
      relatedTopics: relatedTopics,
      infobox: infobox?.isNotEmpty ?? false ? infobox : null,
    );
  }

  InstantAnswerType _inferAnswerType(String answer) {
    final lower = answer.toLowerCase();
    if (lower.contains('°c') ||
        lower.contains('°f') ||
        lower.contains('weather')) {
      return InstantAnswerType.weather;
    }
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(answer) || lower.contains('=')) {
      return InstantAnswerType.calculation;
    }
    if (lower.contains('km') ||
        lower.contains('miles') ||
        lower.contains('meters')) {
      return InstantAnswerType.conversion;
    }
    return InstantAnswerType.unknown;
  }

  Future<List<SearchSuggestion>> getSuggestions(String query) async {
    if (query.length < 2) return [];
    try {
      final response = await _httpClient.get(
        Uri.parse('https://duckduckgo.com/ac/'),
        params: {'q': query, 'type': 'list'},
      );
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final suggestions = <SearchSuggestion>[];
      if (data is List) {
        for (var i = 0; i < data.length && i < 10; i++) {
          final item = data[i];
          if (item is Map<String, dynamic>) {
            final phrase = item['phrase'] as String? ?? '';
            if (phrase.isNotEmpty) {
              suggestions.add(
                SearchSuggestion(
                  suggestion: phrase,
                  score: 100 - i * 10,
                ),
              );
            }
          } else if (item is String) {
            suggestions.add(
              SearchSuggestion(
                suggestion: item,
                score: 100 - i * 10,
              ),
            );
          }
        }
      }
      return suggestions;
    } catch (e) {
      return [];
    }
  }

  Future<String?> getSpellingCorrection(String query) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('https://api.duckduckgo.com/'),
        params: {'q': query, 'format': 'json'},
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final redirect = data['Redirect'] as String?;
      if (redirect != null && redirect.isNotEmpty) {
        final uri = Uri.tryParse(redirect);
        return uri?.queryParameters['q'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void close() {
    _httpClient.close();
  }
}
