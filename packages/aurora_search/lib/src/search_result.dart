library;

import 'utils.dart';

sealed class SearchResult {
  const SearchResult({this.provider, this.relevanceScore});
  final String? provider;
  final int? relevanceScore;
  Map<String, dynamic> toJson();
  static SearchResult fromJson(Map<String, dynamic> json, String category) =>
      switch (category) {
        'text' => TextSearchResult.fromJson(json),
        'image' || 'images' => ImageSearchResult.fromJson(json),
        'video' || 'videos' => VideoSearchResult.fromJson(json),
        'news' => NewsSearchResult.fromJson(json),
        _ => TextSearchResult.fromJson(json),
      };
}

final class TextSearchResult extends SearchResult {
  const TextSearchResult({
    required this.title,
    required this.href,
    required this.body,
    this.favicon,
    this.publishedDate,
    super.provider,
    super.relevanceScore,
  });
  factory TextSearchResult.normalized({
    required String title,
    required String href,
    required String body,
    String? favicon,
    DateTime? publishedDate,
    String? provider,
    int? relevanceScore,
  }) =>
      TextSearchResult(
        title: normalizeText(title),
        href: normalizeUrl(href),
        body: normalizeText(body),
        favicon: favicon != null ? normalizeUrl(favicon) : null,
        publishedDate: publishedDate,
        provider: provider,
        relevanceScore: relevanceScore,
      );
  factory TextSearchResult.fromJson(Map<String, dynamic> json) =>
      TextSearchResult.normalized(
        title: json['title'] as String? ?? '',
        href: json['href'] as String? ?? json['url'] as String? ?? '',
        body: json['body'] as String? ?? json['description'] as String? ?? '',
        favicon: json['favicon'] as String?,
        publishedDate:
            DateTime.tryParse(json['publishedDate'] as String? ?? ''),
        provider: json['provider'] as String?,
        relevanceScore: json['relevanceScore'] as int?,
      );
  final String title;
  final String href;
  final String body;
  final String? favicon;
  final DateTime? publishedDate;
  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'href': href,
        'body': body,
        if (favicon != null) 'favicon': favicon,
        if (publishedDate != null)
          'publishedDate': publishedDate?.toIso8601String(),
        if (provider != null) 'provider': provider,
        if (relevanceScore != null) 'relevanceScore': relevanceScore,
      };
  @override
  String toString() => 'TextSearchResult(title: $title, href: $href)';
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextSearchResult && href == other.href;
  @override
  int get hashCode => href.hashCode;
}

final class ImageSearchResult extends SearchResult {
  const ImageSearchResult({
    required this.title,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.sourceUrl,
    this.width,
    this.height,
    this.source,
    this.format,
    this.fileSize,
    super.provider,
    super.relevanceScore,
  });
  factory ImageSearchResult.normalized({
    required String title,
    required String imageUrl,
    required String thumbnailUrl,
    required String sourceUrl,
    int? width,
    int? height,
    String? source,
    String? format,
    int? fileSize,
    String? provider,
    int? relevanceScore,
  }) =>
      ImageSearchResult(
        title: normalizeText(title),
        imageUrl: normalizeUrl(imageUrl),
        thumbnailUrl: normalizeUrl(thumbnailUrl),
        sourceUrl: normalizeUrl(sourceUrl),
        width: width,
        height: height,
        source: source != null ? normalizeText(source) : null,
        format: format != null ? normalizeText(format) : null,
        fileSize: fileSize,
        provider: provider,
        relevanceScore: relevanceScore,
      );
  factory ImageSearchResult.fromJson(Map<String, dynamic> json) =>
      ImageSearchResult.normalized(
        title: json['title'] as String? ?? '',
        imageUrl: json['image'] as String? ?? '',
        thumbnailUrl: json['thumbnail'] as String? ?? '',
        sourceUrl: json['url'] as String? ?? '',
        width: int.tryParse(json['width']?.toString() ?? ''),
        height: int.tryParse(json['height']?.toString() ?? ''),
        source: json['source'] as String?,
        format: json['format'] as String?,
        fileSize: json['fileSize'] as int?,
        provider: json['provider'] as String?,
      );
  final String title;
  final String imageUrl;
  final String thumbnailUrl;
  final String sourceUrl;
  final int? width;
  final int? height;
  final String? source;
  final String? format;
  final int? fileSize;
  double? get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return width! / height!;
    }
    return null;
  }

  bool get isLandscape => (aspectRatio ?? 1) > 1;
  bool get isPortrait => (aspectRatio ?? 1) < 1;
  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'image': imageUrl,
        'thumbnail': thumbnailUrl,
        'url': sourceUrl,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (source != null) 'source': source,
        if (format != null) 'format': format,
        if (fileSize != null) 'fileSize': fileSize,
        if (provider != null) 'provider': provider,
      };
  @override
  String toString() => 'ImageSearchResult(title: $title, imageUrl: $imageUrl)';
}

final class VideoSearchResult extends SearchResult {
  const VideoSearchResult({
    required this.title,
    required this.description,
    required this.embedUrl,
    this.embedHtml,
    this.thumbnailUrl,
    this.duration,
    this.publisher,
    this.publishedDate,
    this.viewCount,
    this.uploader,
    super.provider,
    super.relevanceScore,
  });
  factory VideoSearchResult.normalized({
    required String title,
    required String description,
    required String embedUrl,
    String? embedHtml,
    String? thumbnailUrl,
    Duration? duration,
    String? publisher,
    DateTime? publishedDate,
    int? viewCount,
    String? uploader,
    String? provider,
    int? relevanceScore,
  }) =>
      VideoSearchResult(
        title: normalizeText(title),
        description: normalizeText(description),
        embedUrl: normalizeUrl(embedUrl),
        embedHtml: embedHtml,
        thumbnailUrl: thumbnailUrl != null ? normalizeUrl(thumbnailUrl) : null,
        duration: duration,
        publisher: publisher != null ? normalizeText(publisher) : null,
        publishedDate: publishedDate,
        viewCount: viewCount,
        uploader: uploader != null ? normalizeText(uploader) : null,
        provider: provider,
        relevanceScore: relevanceScore,
      );
  factory VideoSearchResult.fromJson(Map<String, dynamic> json) =>
      VideoSearchResult.normalized(
        title: json['title'] as String? ?? '',
        description:
            json['description'] as String? ?? json['content'] as String? ?? '',
        embedUrl: json['embed_url'] as String? ?? '',
        embedHtml: json['embed_html'] as String?,
        thumbnailUrl: json['thumbnail'] as String?,
        duration: _parseDuration(json['duration'] as String?),
        publishedDate:
            DateTime.tryParse(json['publishedDate'] as String? ?? ''),
        viewCount: json['viewCount'] as int?,
        publisher: json['publisher'] as String?,
        uploader: json['uploader'] as String?,
        provider: json['provider'] as String?,
      );
  final String title;
  final String description;
  final String embedUrl;
  final String? embedHtml;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? publisher;
  final DateTime? publishedDate;
  final int? viewCount;
  final String? uploader;
  static Duration? _parseDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return null;
    try {
      final parts = durationStr.split(':').map(int.parse).toList();
      if (parts.length == 2) {
        return Duration(minutes: parts[0], seconds: parts[1]);
      } else if (parts.length == 3) {
        return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
      }
    } catch (_) {}
    return null;
  }

  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    final seconds = duration!.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'embed_url': embedUrl,
        if (embedHtml != null) 'embed_html': embedHtml,
        if (thumbnailUrl != null) 'thumbnail': thumbnailUrl,
        if (duration != null) 'duration': formattedDuration,
        if (publisher != null) 'publisher': publisher,
        if (publishedDate != null)
          'publishedDate': publishedDate?.toIso8601String(),
        if (viewCount != null) 'viewCount': viewCount,
        if (uploader != null) 'uploader': uploader,
        if (provider != null) 'provider': provider,
      };
  @override
  String toString() => 'VideoSearchResult(title: $title, embedUrl: $embedUrl)';
}

final class NewsSearchResult extends SearchResult {
  const NewsSearchResult({
    required this.title,
    required this.body,
    required this.url,
    this.imageUrl,
    this.source,
    this.dateRaw,
    this.publishedDate,
    this.author,
    this.category,
    super.provider,
    super.relevanceScore,
  });
  factory NewsSearchResult.normalized({
    required String title,
    required String body,
    required String url,
    String? imageUrl,
    String? source,
    String? dateRaw,
    DateTime? publishedDate,
    String? author,
    String? category,
    String? provider,
    int? relevanceScore,
  }) =>
      NewsSearchResult(
        title: normalizeText(title),
        body: normalizeText(body),
        url: normalizeUrl(url),
        imageUrl: imageUrl != null ? normalizeUrl(imageUrl) : null,
        source: source != null ? normalizeText(source) : null,
        dateRaw: dateRaw,
        publishedDate: publishedDate,
        author: author != null ? normalizeText(author) : null,
        category: category != null ? normalizeText(category) : null,
        provider: provider,
        relevanceScore: relevanceScore,
      );
  factory NewsSearchResult.fromJson(Map<String, dynamic> json) =>
      NewsSearchResult.normalized(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        url: json['url'] as String? ?? '',
        imageUrl: json['image'] as String?,
        source: json['source'] as String?,
        dateRaw: json['date'] as String?,
        publishedDate: DateTime.tryParse(json['date'] as String? ?? ''),
        author: json['author'] as String?,
        category: json['category'] as String?,
        provider: json['provider'] as String?,
      );
  final String title;
  final String body;
  final String url;
  final String? imageUrl;
  final String? source;
  final String? dateRaw;
  final DateTime? publishedDate;
  final String? author;
  final String? category;
  bool get isRecent {
    if (publishedDate == null) return false;
    return DateTime.now().difference(publishedDate!).inHours < 24;
  }

  String get relativeTime {
    if (publishedDate == null) return '';
    final diff = DateTime.now().difference(publishedDate!);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'url': url,
        if (imageUrl != null) 'image': imageUrl,
        if (source != null) 'source': source,
        if (publishedDate != null)
          'date': publishedDate!.toIso8601String()
        else if (dateRaw != null)
          'date': dateRaw,
        if (author != null) 'author': author,
        if (category != null) 'category': category,
        if (provider != null) 'provider': provider,
      };
  @override
  String toString() => 'NewsSearchResult(title: $title, url: $url)';
}
