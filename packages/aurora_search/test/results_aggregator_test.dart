import 'package:aurora_search/aurora_search.dart';
import 'package:test/test.dart';

void main() {
  test('ResultsAggregator deduplicates by unique fields', () {
    final aggregator = ResultsAggregator<TextSearchResult>({'href'});

    aggregator.add(
      TextSearchResult.normalized(
        title: 'First',
        href: 'https://example.com',
        body: 'One',
      ),
    );

    aggregator.add(
      TextSearchResult.normalized(
        title: 'Second',
        href: 'https://example.com',
        body: 'Two',
      ),
    );

    expect(aggregator.length, 1);
    expect(aggregator.results.single.href, 'https://example.com');
  });
}

