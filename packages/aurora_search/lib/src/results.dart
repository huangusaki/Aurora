library;

import 'search_result.dart';

class ResultsAggregator<T extends SearchResult> {
  ResultsAggregator(this._uniqueFields);

  final List<T> _results = [];
  final Set<String> _seenKeys = {};
  final Set<String> _uniqueFields;

  void add(T result) {
    final json = result.toJson();
    final key = _uniqueFields
        .map((field) => json[field]?.toString() ?? '')
        .where((val) => val.isNotEmpty)
        .join('|');
    if (key.isNotEmpty && !_seenKeys.contains(key)) {
      _seenKeys.add(key);
      _results.add(result);
    }
  }

  void addAll(Iterable<T> results) {
    for (final result in results) {
      add(result);
    }
  }

  List<T> get results => List.unmodifiable(_results);

  int get length => _results.length;
}

