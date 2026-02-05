library;

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'http_client.dart';
import 'search_result.dart';

abstract class BaseSearchEngine<T extends SearchResult> {
  BaseSearchEngine({
    String? proxy,
    Duration? timeout,
    bool verify = true,
  }) : httpClient = HttpClient(
          proxy: proxy,
          timeout: timeout,
          verify: verify,
        );
  String get name;
  String get category;
  String get provider;
  bool get disabled => false;
  double get priority => 1;
  String get searchUrl;
  String get searchMethod;
  Map<String, String> get searchHeaders => {};
  String get itemsSelector;
  Map<String, String> get elementsSelector;
  final HttpClient httpClient;
  Map<String, String> buildPayload({
    required String query,
    required String region,
    required String safesearch,
    String? timelimit,
    int page = 1,
    Map<String, dynamic>? extra,
  });
  Map<String, String> buildHeaders({
    required String region,
    Map<String, dynamic>? extra,
  }) =>
      searchHeaders;
  Future<String?> request(
    String method,
    String url, {
    Map<String, String>? params,
    Map<String, String>? headers,
    dynamic data,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await httpClient.request(
        method,
        uri,
        params: params,
        headers: headers,
        body: data,
      );
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Document extractTree(String htmlText) => html_parser.parse(htmlText);
  String preProcessHtml(String htmlText) => htmlText;
  List<T> extractResults(String htmlText);
  List<T> postExtractResults(List<T> results) => results;
  Future<List<T>?> search({
    required String query,
    String region = 'us-en',
    String safesearch = 'moderate',
    String? timelimit,
    int page = 1,
    Map<String, dynamic>? extra,
  }) async {
    final payload = buildPayload(
      query: query,
      region: region,
      safesearch: safesearch,
      timelimit: timelimit,
      page: page,
      extra: extra,
    );
    final headers = buildHeaders(region: region, extra: extra);
    String? htmlText;
    if (searchMethod.toUpperCase() == 'GET') {
      htmlText = await request(
        searchMethod,
        searchUrl,
        params: payload,
        headers: headers,
      );
    } else {
      htmlText = await request(
        searchMethod,
        searchUrl,
        data: payload,
        headers: headers,
      );
    }
    if (htmlText == null) {
      return null;
    }
    final results = extractResults(htmlText);
    return postExtractResults(results);
  }

  void close() {
    httpClient.close();
  }
}
