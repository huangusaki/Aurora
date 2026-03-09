import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aurora/features/settings/domain/provider_route_config.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/provider_capability_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderCapabilityGateway', () {
    test('speech requests use response_format', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? requestedPath;
      Map<String, dynamic>? payload;
      final sub = server.listen((request) async {
        requestedPath = request.uri.path;
        final raw = await utf8.decoder.bind(request).join();
        payload = jsonDecode(raw) as Map<String, dynamic>;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType('audio', 'mpeg');
        request.response.add([1, 2, 3]);
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final provider = ProviderConfig(
        id: 'openai',
        name: 'OpenAI',
        apiKeys: const ['key'],
        capabilityConfig: ProviderCapabilityConfig(
          routes: {
            ProviderCapability.speech: CapabilityRouteConfig(
              preset: ProtocolPreset.openaiAudioSpeech,
              baseUrlOverride:
                  'http://${server.address.host}:${server.port}/v1',
            ),
          },
        ),
      );

      final result = await ProviderCapabilityGateway().synthesizeSpeech(
        provider: provider,
        model: 'gpt-4o-mini-tts',
        input: 'hello',
      );

      expect(requestedPath, '/v1/audio/speech');
      expect(payload?['response_format'], 'mp3');
      expect(payload?.containsKey('format'), isFalse);
      expect(result.bytes, Uint8List.fromList([1, 2, 3]));
    });

    test('openai chat preset sends multimodal audio json', () async {
      final audioFile = await _createTempAudioFile('mp3');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? requestedPath;
      Map<String, dynamic>? payload;
      final sub = server.listen((request) async {
        requestedPath = request.uri.path;
        final raw = await utf8.decoder.bind(request).join();
        payload = jsonDecode(raw) as Map<String, dynamic>;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'choices': [
            {
              'message': {'content': 'transcript ok'}
            }
          ]
        }));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final provider = ProviderConfig(
        id: 'openai',
        name: 'OpenAI',
        apiKeys: const ['key'],
        capabilityConfig: ProviderCapabilityConfig(
          routes: {
            ProviderCapability.transcriptions: CapabilityRouteConfig(
              preset: ProtocolPreset.openaiChatCompletions,
              baseUrlOverride:
                  'http://${server.address.host}:${server.port}/v1',
            ),
          },
        ),
      );

      final result = await ProviderCapabilityGateway().transcribeAudio(
        provider: provider,
        model: 'gpt-audio',
        filePath: audioFile.path,
      );

      expect(requestedPath, '/v1/chat/completions');
      final content =
          (payload?['messages'] as List).first['content'] as List<dynamic>;
      expect(content[1]['type'], 'input_audio');
      expect(content[1]['input_audio']['format'], 'mp3');
      expect(
        (content[1]['input_audio']['data'] as String).isNotEmpty,
        isTrue,
      );
      expect(result.text, 'transcript ok');
    });

    test('customJson audio routes send json instead of multipart', () async {
      final audioFile = await _createTempAudioFile('wav');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? requestedPath;
      String? contentType;
      Map<String, dynamic>? payload;
      final sub = server.listen((request) async {
        requestedPath = request.uri.path;
        contentType = request.headers.contentType?.mimeType;
        final raw = await utf8.decoder.bind(request).join();
        payload = jsonDecode(raw) as Map<String, dynamic>;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'choices': [
            {
              'message': {'content': 'translation ok'}
            }
          ]
        }));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final provider = ProviderConfig(
        id: 'custom',
        name: 'Custom',
        apiKeys: const ['key'],
        capabilityConfig: ProviderCapabilityConfig(
          routes: {
            ProviderCapability.translations: CapabilityRouteConfig(
              preset: ProtocolPreset.customJson,
              baseUrlOverride:
                  'http://${server.address.host}:${server.port}/v1',
            ),
          },
        ),
      );

      final result = await ProviderCapabilityGateway().translateAudio(
        provider: provider,
        model: 'mystery-audio-model',
        filePath: audioFile.path,
      );

      expect(requestedPath, '/v1/chat/completions');
      expect(contentType, 'application/json');
      expect(payload?['messages'], isNotNull);
      expect(result.text, 'translation ok');
    });

    test('customMultipart audio routes keep multipart payload', () async {
      final audioFile = await _createTempAudioFile(
        'mp3',
        bytes: utf8.encode('aurora-audio'),
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? requestedPath;
      String? contentType;
      String? rawBody;
      final sub = server.listen((request) async {
        requestedPath = request.uri.path;
        contentType = request.headers.contentType?.mimeType;
        final builder = BytesBuilder(copy: false);
        await for (final chunk in request) {
          builder.add(chunk);
        }
        rawBody = latin1.decode(builder.takeBytes());
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'text': 'multipart ok'}));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final provider = ProviderConfig(
        id: 'custom',
        name: 'Custom',
        apiKeys: const ['key'],
        capabilityConfig: ProviderCapabilityConfig(
          routes: {
            ProviderCapability.transcriptions: CapabilityRouteConfig(
              preset: ProtocolPreset.customMultipart,
              baseUrlOverride:
                  'http://${server.address.host}:${server.port}/v1',
              pathOverride: 'upload/audio',
            ),
          },
        ),
      );

      final result = await ProviderCapabilityGateway().transcribeAudio(
        provider: provider,
        model: 'custom-audio-model',
        filePath: audioFile.path,
        prompt: 'transcribe it',
      );

      expect(requestedPath, '/v1/upload/audio');
      expect(contentType, 'multipart/form-data');
      expect(rawBody, contains('name="model"'));
      expect(rawBody, contains('name="prompt"'));
      expect(rawBody, contains('filename="sample.mp3"'));
      expect(result.text, 'multipart ok');
    });

    test('gemini native audio routes send inlineData payload', () async {
      final audioFile = await _createTempAudioFile('mp3');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? requestedPath;
      Map<String, dynamic>? payload;
      final sub = server.listen((request) async {
        requestedPath = request.uri.path;
        final raw = await utf8.decoder.bind(request).join();
        payload = jsonDecode(raw) as Map<String, dynamic>;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'gemini native ok'}
                ]
              }
            }
          ]
        }));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final provider = ProviderConfig(
        id: 'gemini',
        name: 'Gemini',
        apiKeys: const ['key'],
        capabilityConfig: ProviderCapabilityConfig(
          routes: {
            ProviderCapability.transcriptions: CapabilityRouteConfig(
              preset: ProtocolPreset.geminiNativeGenerateContent,
              baseUrlOverride:
                  'http://${server.address.host}:${server.port}/v1beta',
            ),
          },
        ),
      );

      final result = await ProviderCapabilityGateway().transcribeAudio(
        provider: provider,
        model: 'gemini-2.5-flash',
        filePath: audioFile.path,
      );

      expect(
        requestedPath,
        '/v1beta/models/gemini-2.5-flash:generateContent',
      );
      final contents = payload?['contents'] as List<dynamic>;
      final parts = (contents.first as Map<String, dynamic>)['parts'] as List;
      expect(parts[1]['inlineData']['mimeType'], 'audio/mpeg');
      expect(result.text, 'gemini native ok');
    });

    test('legacy audio preset aliases to chat completions path', () async {
      final audioFile = await _createTempAudioFile('mp3');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? requestedPath;
      final sub = server.listen((request) async {
        requestedPath = request.uri.path;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'choices': [
            {
              'message': {'content': 'legacy ok'}
            }
          ]
        }));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final provider = ProviderConfig(
        id: 'legacy',
        name: 'Legacy',
        apiKeys: const ['key'],
        capabilityConfig: ProviderCapabilityConfig(
          routes: {
            ProviderCapability.translations: CapabilityRouteConfig(
              preset: ProtocolPreset.openaiAudioTranslations,
              baseUrlOverride:
                  'http://${server.address.host}:${server.port}/v1',
            ),
          },
        ),
      );

      final result = await ProviderCapabilityGateway().translateAudio(
        provider: provider,
        model: 'gpt-audio',
        filePath: audioFile.path,
      );

      expect(requestedPath, '/v1/chat/completions');
      expect(result.text, 'legacy ok');
    });
  });
}

Future<File> _createTempAudioFile(
  String extension, {
  List<int>? bytes,
}) async {
  final directory =
      await Directory.systemTemp.createTemp('aurora_gateway_audio_test_');
  final file = File(
    '${directory.path}${Platform.pathSeparator}sample.$extension',
  );
  await file.writeAsBytes(bytes ?? <int>[0, 1, 2, 3, 4]);
  addTearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
  return file;
}
