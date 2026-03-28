import 'package:aurora_search/aurora_search.dart';
import 'package:test/test.dart';

void main() {
  test('SearchOptions only exposes effective knobs', () {
    const options = SearchOptions(
      region: SearchRegion.canadaEnglish,
      safeSearch: SafeSearchLevel.strict,
      timeLimit: TimeLimit.week,
      maxResults: 25,
      page: 3,
      backend: 'duckduckgo,google',
    );

    final copied = options.copyWith(page: 4, backend: 'google');

    expect(copied.region, options.region);
    expect(copied.safeSearch, options.safeSearch);
    expect(copied.timeLimit, options.timeLimit);
    expect(copied.maxResults, options.maxResults);
    expect(copied.page, 4);
    expect(copied.backend, 'google');
  });

  test('books is no longer exposed as a supported category', () {
    expect(supportedCategories, isNot(contains('books')));
    expect(getAvailableEngines('books'), isEmpty);
    expect(isEngineAvailable('books', 'anything'), isFalse);
  });
}
