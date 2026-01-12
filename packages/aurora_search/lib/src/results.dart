library;

import 'utils.dart';

abstract class BaseResult {
  static final Map<String, String Function(String)> _normalizers = {
    'title': normalizeText,
    'body': normalizeText,
    'href': normalizeUrl,
    'url': normalizeUrl,
    'thumbnail': normalizeUrl,
    'image': normalizeUrl,
    'date': normalizeDate,
    'author': normalizeText,
    'publisher': normalizeText,
    'info': normalizeText,
  };
  String normalizeField(String fieldName, String value) {
    final normalizer = _normalizers[fieldName];
    return normalizer != null ? normalizer(value) : value;
  }

  Map<String, dynamic> toJson();
}

class TextResult extends BaseResult {
  TextResult({this.title = '', this.href = '', this.body = ''}) {
    title = normalizeField('title', title);
    href = normalizeField('href', href);
    body = normalizeField('body', body);
  }
  String title;
  String href;
  String body;
  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'href': href,
        'body': body,
      };
}

class ImagesResult extends BaseResult {
  ImagesResult({
    this.title = '',
    this.image = '',
    this.thumbnail = '',
    this.url = '',
    this.height = '',
    this.width = '',
    this.source = '',
  }) {
    title = normalizeField('title', title);
    image = normalizeField('image', image);
    thumbnail = normalizeField('thumbnail', thumbnail);
    url = normalizeField('url', url);
  }
  String title;
  String image;
  String thumbnail;
  String url;
  String height;
  String width;
  String source;
  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'image': image,
        'thumbnail': thumbnail,
        'url': url,
        'height': height,
        'width': width,
        'source': source,
      };
}

class NewsResult extends BaseResult {
  NewsResult({
    this.date = '',
    this.title = '',
    this.body = '',
    this.url = '',
    this.image = '',
    this.source = '',
  }) {
    date = normalizeField('date', date);
    title = normalizeField('title', title);
    body = normalizeField('body', body);
    url = normalizeField('url', url);
    image = normalizeField('image', image);
  }
  String date;
  String title;
  String body;
  String url;
  String image;
  String source;
  @override
  Map<String, dynamic> toJson() => {
        'date': date,
        'title': title,
        'body': body,
        'url': url,
        'image': image,
        'source': source,
      };
}

class VideosResult extends BaseResult {
  VideosResult({
    this.title = '',
    this.content = '',
    this.description = '',
    this.duration = '',
    this.embedHtml = '',
    this.embedUrl = '',
    this.imageToken = '',
    Map<String, String>? images,
    this.provider = '',
    this.published = '',
    this.publisher = '',
    Map<String, String>? statistics,
    this.uploader = '',
  })  : images = images ?? {},
        statistics = statistics ?? {} {
    title = normalizeField('title', title);
    publisher = normalizeField('publisher', publisher);
  }
  String title;
  String content;
  String description;
  String duration;
  String embedHtml;
  String embedUrl;
  String imageToken;
  Map<String, String> images;
  String provider;
  String published;
  String publisher;
  Map<String, String> statistics;
  String uploader;
  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'description': description,
        'duration': duration,
        'embed_html': embedHtml,
        'embed_url': embedUrl,
        'image_token': imageToken,
        'images': images,
        'provider': provider,
        'published': published,
        'publisher': publisher,
        'statistics': statistics,
        'uploader': uploader,
      };
}

class BooksResult extends BaseResult {
  BooksResult({
    this.title = '',
    this.author = '',
    this.publisher = '',
    this.info = '',
    this.url = '',
  }) {
    title = normalizeField('title', title);
    author = normalizeField('author', author);
    publisher = normalizeField('publisher', publisher);
    info = normalizeField('info', info);
    url = normalizeField('url', url);
  }
  String title;
  String author;
  String publisher;
  String info;
  String url;
  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'publisher': publisher,
        'info': info,
        'url': url,
      };
}

class ResultsAggregator<T extends BaseResult> {
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

  void addAll(List<T> results) {
    for (final result in results) {
      add(result);
    }
  }

  List<T> get results => List.unmodifiable(_results);
  int get length => _results.length;
}
