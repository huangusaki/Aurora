import 'dart:async';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'exceptions.dart';
import 'package:http/io_client.dart';

class HttpResponse {
  HttpResponse({
    required this.statusCode,
    required this.body,
    required this.bodyBytes,
  });
  final int statusCode;
  final String body;
  final List<int> bodyBytes;
}

class HttpClient {
  HttpClient({
    this.proxy,
    Duration? timeout,
    this.verify = true,
  }) : timeout = timeout ?? const Duration(seconds: 10) {
    if (proxy != null && proxy!.isNotEmpty) {
      final httpClient = io.HttpClient();
      httpClient.findProxy = (uri) => 'PROXY $proxy';
      httpClient.badCertificateCallback = (cert, host, port) => !verify;
      _client = IOClient(httpClient);
    } else {
      _client = http.Client();
    }
  }
  final String? proxy;
  final Duration timeout;
  final bool verify;
  late final http.Client _client;
  Future<HttpResponse> request(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Map<String, String>? params,
    dynamic body,
  }) async {
    try {
      if (params != null && params.isNotEmpty) {
        url = url.replace(
          queryParameters: {
            ...url.queryParameters,
            ...params,
          },
        );
      }
      http.Response response;
      final requestHeaders = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        ...?headers,
      };
      switch (method.toUpperCase()) {
        case 'GET':
          response =
              await _client.get(url, headers: requestHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await _client
              .post(url, headers: requestHeaders, body: body)
              .timeout(timeout);
          break;
        default:
          throw AuroraSearchException('Unsupported HTTP method: $method');
      }
      return HttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        bodyBytes: response.bodyBytes,
      );
    } on io.SocketException catch (e) {
      throw AuroraSearchException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw AuroraSearchException('HTTP client error: $e');
    } on TimeoutException catch (e) {
      throw AuroraSearchTimeoutException('Request timed out: $e');
    } catch (e) {
      throw AuroraSearchException('Request failed: $e');
    }
  }

  Future<HttpResponse> get(
    Uri url, {
    Map<String, String>? headers,
    Map<String, String>? params,
  }) =>
      request('GET', url, headers: headers, params: params);
  Future<HttpResponse> post(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
  }) =>
      request('POST', url, headers: headers, body: body);
  void close() {
    _client.close();
  }
}
