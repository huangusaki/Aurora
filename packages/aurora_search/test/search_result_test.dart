import 'package:aurora_search/aurora_search.dart';
import 'package:test/test.dart';

void main() {
  test('TextSearchResult.normalized normalizes text and URLs', () {
    final result = TextSearchResult.normalized(
      title: '  hello   world  ',
      href: ' https://example.com/test ',
      body: '  a   b  ',
    );

    expect(result.title, 'hello world');
    expect(result.href, 'https://example.com/test');
    expect(result.body, 'a b');
  });

  test('NewsSearchResult.toJson uses dateRaw when parse fails', () {
    final result = NewsSearchResult.normalized(
      title: 'Title',
      body: 'Body',
      url: 'https://example.com',
      dateRaw: 'not-a-date',
      publishedDate: null,
    );

    expect(result.toJson()['date'], 'not-a-date');
  });

  test('SearchResult.fromJson accepts plural categories', () {
    final result = SearchResult.fromJson(
      {
        'title': 'Img',
        'image': 'https://example.com/img.png',
        'thumbnail': 'https://example.com/thumb.png',
        'url': 'https://example.com/page',
      },
      'images',
    );

    expect(result, isA<ImageSearchResult>());
  });
}

