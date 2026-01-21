import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../domain/remote_backup_file.dart';
import '../domain/webdav_config.dart';

class WebDavService {
  final WebDavConfig config;
  final Dio _dio = Dio();

  WebDavService(this.config);

  String get _baseUrl => config.url.endsWith('/') ? config.url : '${config.url}/';

  // Basic Auth Header
  String get _authHeader {
    final bytes = utf8.encode('${config.username}:${config.password}');
    return 'Basic ${base64.encode(bytes)}';
  }

  Options get _options => Options(
        headers: {
          HttpHeaders.authorizationHeader: _authHeader,
        },
        validateStatus: (status) => status != null && status < 400,
      );

  Future<bool> checkConnection() async {
    try {
      final response = await _dio.request(
        _baseUrl,
        options: _options.copyWith(method: 'PROPFIND', headers: {
          HttpHeaders.authorizationHeader: _authHeader,
          'Depth': '0',
        }),
      );
      return response.statusCode != null && response.statusCode! < 400;
    } catch (e) {
      return false;
    }
  }

  Future<void> uploadFile(File file, String remoteName) async {
    final remoteUrl = '$_baseUrl${config.remotePath}/$remoteName'.replaceAll('//', '/').replaceFirst(':/', '://');
    
    // Ensure directory exists
    await _ensureDirectory(config.remotePath);

    final bytes = await file.readAsBytes();
    await _dio.put(
      remoteUrl,
      data: Stream.fromIterable([bytes]),
      options: _options.copyWith(
        headers: {
          HttpHeaders.authorizationHeader: _authHeader,
          HttpHeaders.contentLengthHeader: bytes.length,
        },
      ),
    );
  }

  Future<File> downloadFile(String remoteName, String localPath) async {
    final remoteUrl = '$_baseUrl${config.remotePath}/$remoteName'.replaceAll('//', '/').replaceFirst(':/', '://');
    await _dio.download(
      remoteUrl,
      localPath,
      options: _options,
    );
    return File(localPath);
  }

  Future<List<RemoteBackupFile>> listBackups() async {
     // Ensure directory first
    try {
      await _ensureDirectory(config.remotePath);
    } catch (e) {
       // Ignore error if directory creation fails or exists
    }

    final remoteUrl = '$_baseUrl${config.remotePath}'.replaceAll('//', '/').replaceFirst(':/', '://');
    final response = await _dio.request(
      remoteUrl,
      options: _options.copyWith(
        method: 'PROPFIND',
        headers: {
          HttpHeaders.authorizationHeader: _authHeader,
          'Depth': '1',
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 207) {
      final document = XmlDocument.parse(response.data.toString());
      final responses = document.findAllElements('d:response');
      final backups = <RemoteBackupFile>[];

      for (var resp in responses) {
        final href = resp.findAllElements('d:href').first.text;
        final prop = resp.findAllElements('d:prop').first;
        
        final displayNameElement = prop.findAllElements('d:displayname').isEmpty ? null : prop.findAllElements('d:displayname').first;
        final getContentLengthElement = prop.findAllElements('d:getcontentlength').isEmpty ? null : prop.findAllElements('d:getcontentlength').first;
        final getLastModifiedElement = prop.findAllElements('d:getlastmodified').isEmpty ? null : prop.findAllElements('d:getlastmodified').first;
        final resourceTypeElement = prop.findAllElements('d:resourcetype').first;

        // Skip directories
        if (resourceTypeElement.findAllElements('d:collection').isNotEmpty) {
           continue;
        }

        final name = displayNameElement?.text ?? href.split('/').last;
        // Filter for our backup files
        if (!name.endsWith('.zip')) continue;

        final size = int.tryParse(getContentLengthElement?.text ?? '0') ?? 0;
        final modifiedStr = getLastModifiedElement?.text;
        DateTime modified = DateTime.now();
        if (modifiedStr != null) {
          try {
             modified = HttpDate.parse(modifiedStr);
          } catch (_) {}
        }

        backups.add(RemoteBackupFile(
          name: name,
          url: href,
          modified: modified,
          size: size,
        ));
      }
      
      // Sort by modified desc
      backups.sort((a, b) => b.modified.compareTo(a.modified));
      return backups;
    }
    return [];
  }

  Future<void> _ensureDirectory(String path) async {
    // A simple implementation that tries to create the directory
    // In a real robust app, we might need to recursively create directories
    final remoteUrl = '$_baseUrl$path'.replaceAll('//', '/').replaceFirst(':/', '://');
    try {
       await _dio.request(
        remoteUrl,
        options: _options.copyWith(method: 'MKCOL'),
      );
    } catch (e) {
      // 405 Method Not Allowed means it likely already exists
    }
  }
}
