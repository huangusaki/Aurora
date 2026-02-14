import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum AppLogLevel { debug, info, warn, error }

class AppLogger {
  AppLogger._();

  static void _emit(String? message, {int? wrapWidth}) {
    if (message == null || message.isEmpty) return;
    Zone.root.print(message);
  }

  static bool _installed = false;
  static bool _useColor = true;
  static bool _prettyJson = true;
  static AppLogLevel _minLevel = AppLogLevel.debug;

  static const String _reset = '\x1B[0m';
  static const String _dim = '\x1B[90m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';

  static void install({
    bool useColor = true,
    bool prettyJson = true,
    bool allowVerboseInRelease = false,
    AppLogLevel? minLevel,
  }) {
    if (_installed) return;
    _useColor = useColor;
    _prettyJson = prettyJson;
    final verboseRelease =
        allowVerboseInRelease || _envFlag('AURORA_VERBOSE_LOGS');
    _minLevel = minLevel ??
        (kReleaseMode && !verboseRelease
            ? AppLogLevel.warn
            : AppLogLevel.debug);

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message == null || message.trim().isEmpty) return;
      raw(message, wrapWidth: wrapWidth);
    };

    _installed = true;
  }

  static AppLogLevel get minLevel => _minLevel;

  static void setMinLevel(AppLogLevel level) {
    _minLevel = level;
  }

  static ZoneSpecification zoneSpecification() {
    return ZoneSpecification(
      print: (self, parent, zone, line) {
        if (line.trim().isEmpty) return;
        raw(line);
      },
    );
  }

  static void debug(String channel, String message,
      {String? category, Object? data}) {
    _write(
      level: AppLogLevel.debug,
      channel: channel,
      category: category,
      message: message,
      data: data,
    );
  }

  static void info(String channel, String message,
      {String? category, Object? data}) {
    _write(
      level: AppLogLevel.info,
      channel: channel,
      category: category,
      message: message,
      data: data,
    );
  }

  static void warn(String channel, String message,
      {String? category, Object? data}) {
    _write(
      level: AppLogLevel.warn,
      channel: channel,
      category: category,
      message: message,
      data: data,
    );
  }

  static void error(String channel, String message,
      {String? category, Object? data}) {
    _write(
      level: AppLogLevel.error,
      channel: channel,
      category: category,
      message: message,
      data: data,
    );
  }

  static void llmRequest({required String url, Object? payload}) {
    _write(
      level: AppLogLevel.info,
      channel: 'LLM',
      category: 'REQUEST',
      message: url,
      data: payload,
      colorOverride: _yellow,
    );
  }

  static void llmResponse({Object? payload}) {
    _write(
      level: AppLogLevel.info,
      channel: 'LLM',
      category: 'RESPONSE',
      message: 'received',
      data: payload,
      colorOverride: _green,
    );
  }

  static void raw(String message, {int? wrapWidth}) {
    final parsed = _parseLegacy(message);
    _write(
      level: parsed.level,
      channel: parsed.channel,
      category: parsed.category,
      message: parsed.message,
      wrapWidth: wrapWidth,
    );
  }

  static void _write({
    required AppLogLevel level,
    required String channel,
    String? category,
    required String message,
    Object? data,
    String? colorOverride,
    int? wrapWidth,
  }) {
    if (!_shouldLog(level)) return;

    final sanitizedMessage = _sanitizeText(message).trim();
    final sanitizedData = _sanitizeData(data);

    final header = StringBuffer();
    header.write('[${_timestamp()}]');
    header.write('[${_levelName(level)}]');
    header.write('[$channel]');
    if (category != null && category.isNotEmpty) {
      header.write('[$category]');
    }
    if (sanitizedMessage.isNotEmpty) {
      header.write(' $sanitizedMessage');
    }

    final dataText = _formatData(sanitizedData);
    final text = dataText.isEmpty
        ? header.toString()
        : '${header.toString()}\n${_indent(dataText, 2)}';

    final color = colorOverride ?? _colorFor(level, channel, category);
    _emit(_applyColor(text, color), wrapWidth: wrapWidth);
  }

  static _ParsedLog _parseLegacy(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      return const _ParsedLog(
        level: AppLogLevel.debug,
        channel: 'APP',
        message: '',
      );
    }

    final normalizedMatch = RegExp(
      r'^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]\[(DEBUG|INFO|WARN|ERROR)\]\[([^\]]+)\](?:\[([^\]]+)\])?\s*(.*)$',
    ).firstMatch(input);
    if (normalizedMatch != null) {
      return _ParsedLog(
        level: _levelFromString(normalizedMatch.group(2)),
        channel: normalizedMatch.group(3)!,
        category: normalizedMatch.group(4),
        message: normalizedMatch.group(5)?.trim() ?? '',
      );
    }

    final novelMatch = RegExp(r'^\[NOVEL\]\[(DEBUG|INFO|WARN|ERROR)\]\s*(.*)$')
        .firstMatch(input);
    if (novelMatch != null) {
      return _ParsedLog(
        level: _levelFromString(novelMatch.group(1)),
        channel: 'NOVEL',
        message: novelMatch.group(2)?.trim() ?? '',
      );
    }

    if (input.startsWith('[AURORA_BOOT]')) {
      final isError = input.contains('[ERROR]');
      final stageMatch = RegExp(r'\[ERROR\]\[([^\]]+)\]').firstMatch(input);
      final stage = stageMatch?.group(1);
      final message = input
          .replaceFirst(
            RegExp(
                r'^\[AURORA_BOOT\](?:\[[^\]]+\])?(?:\[ERROR\])?(?:\[[^\]]+\])?\s*'),
            '',
          )
          .trim();
      return _ParsedLog(
        level: isError ? AppLogLevel.error : AppLogLevel.info,
        channel: 'BOOT',
        category: stage,
        message: message,
      );
    }

    if (input.startsWith('ChatStorage:')) {
      return _ParsedLog(
        level: _guessLevelFromText(input),
        channel: 'CHAT_STORAGE',
        message: input.substring('ChatStorage:'.length).trim(),
      );
    }

    if (input.startsWith('SettingsNotifier')) {
      return _ParsedLog(
        level: _guessLevelFromText(input),
        channel: 'SETTINGS',
        message: input,
      );
    }

    if (input.startsWith('Restoring session') ||
        input.startsWith('Restored topic')) {
      return _ParsedLog(
        level: AppLogLevel.info,
        channel: 'SESSION',
        message: input,
      );
    }

    return _ParsedLog(
      level: _guessLevelFromText(input),
      channel: 'APP',
      message: input,
    );
  }

  static AppLogLevel _guessLevelFromText(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('error') ||
        lower.contains('failed') ||
        lower.contains('exception')) {
      return AppLogLevel.error;
    }
    if (lower.contains('warn') || lower.contains('timeout')) {
      return AppLogLevel.warn;
    }
    return AppLogLevel.info;
  }

  static AppLogLevel _levelFromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'DEBUG':
        return AppLogLevel.debug;
      case 'WARN':
        return AppLogLevel.warn;
      case 'ERROR':
        return AppLogLevel.error;
      case 'INFO':
      default:
        return AppLogLevel.info;
    }
  }

  static String _formatData(Object? data) {
    if (data == null) return '';
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return '';
      if (_looksLikeJson(trimmed)) {
        try {
          final decoded = jsonDecode(trimmed);
          return _jsonText(decoded);
        } catch (_) {
          return trimmed;
        }
      }
      return trimmed;
    }
    if (data is Map || data is List) {
      return _jsonText(data);
    }
    return data.toString();
  }

  static bool _looksLikeJson(String text) {
    return (text.startsWith('{') && text.endsWith('}')) ||
        (text.startsWith('[') && text.endsWith(']'));
  }

  static String _jsonText(Object value) {
    if (_prettyJson) {
      const pretty = JsonEncoder.withIndent('  ');
      return pretty.convert(value);
    }
    return jsonEncode(value);
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  static String _levelName(AppLogLevel level) {
    switch (level) {
      case AppLogLevel.debug:
        return 'DEBUG';
      case AppLogLevel.info:
        return 'INFO';
      case AppLogLevel.warn:
        return 'WARN';
      case AppLogLevel.error:
        return 'ERROR';
    }
  }

  static String _colorFor(AppLogLevel level, String channel, String? category) {
    if (channel == 'LLM' && category == 'REQUEST') return _yellow;
    if (channel == 'LLM' && category == 'RESPONSE') return _green;
    if (channel == 'BOOT') return _cyan;
    switch (level) {
      case AppLogLevel.debug:
        return _dim;
      case AppLogLevel.info:
        return _dim;
      case AppLogLevel.warn:
        return _yellow;
      case AppLogLevel.error:
        return _red;
    }
  }

  static String _applyColor(String text, String color) {
    if (!_useColor || _disableAnsiByEnv()) return text;
    if (Platform.isIOS || Platform.isAndroid) return text;
    return '$color$text$_reset';
  }

  static bool _disableAnsiByEnv() {
    return Platform.environment.containsKey('NO_COLOR');
  }

  static bool _shouldLog(AppLogLevel level) {
    return _levelWeight(level) >= _levelWeight(_minLevel);
  }

  static int _levelWeight(AppLogLevel level) {
    switch (level) {
      case AppLogLevel.debug:
        return 10;
      case AppLogLevel.info:
        return 20;
      case AppLogLevel.warn:
        return 30;
      case AppLogLevel.error:
        return 40;
    }
  }

  static bool _envFlag(String name) {
    final raw = Platform.environment[name];
    if (raw == null) return false;
    final normalized = raw.trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }

  static Object? _sanitizeData(Object? value,
      {String? keyHint, List<String> path = const []}) {
    if (value == null) return null;
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      value.forEach((key, mapValue) {
        final textKey = key.toString();
        final childPath = [...path, textKey];
        if (_isSensitiveKey(textKey)) {
          sanitized[textKey] = '[REDACTED]';
          return;
        }
        sanitized[textKey] =
            _sanitizeData(mapValue, keyHint: textKey, path: childPath);
      });
      return sanitized;
    }
    if (value is List) {
      return value
          .map((item) => _sanitizeData(item, keyHint: keyHint, path: path))
          .toList();
    }
    if (value is String) {
      if (keyHint != null) {
        if (_isSensitiveKey(keyHint)) return '[REDACTED]';
        // Keep backend error messages visible for troubleshooting.
        if (_isErrorMessagePath(path)) return _sanitizeText(value);
        if (_isContentKey(keyHint) && value.trim().isNotEmpty) {
          return '[REDACTED_TEXT len=${value.length}]';
        }
      }
      return _sanitizeText(value);
    }
    return value;
  }

  static bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    const hints = [
      'api_key',
      'apikey',
      'key',
      'token',
      'password',
      'secret',
      'authorization',
      'cookie',
    ];
    for (final hint in hints) {
      if (lower.contains(hint)) return true;
    }
    return false;
  }

  static bool _isContentKey(String key) {
    final lower = key.toLowerCase();
    // Only redact actual payload text fields, not metadata like content_type.
    if (lower == 'content' ||
        lower == 'text' ||
        lower == 'prompt' ||
        lower == 'reasoning' ||
        lower == 'reasoning_content') {
      return true;
    }
    if (lower.endsWith('_content') && !lower.endsWith('content_type')) {
      return true;
    }
    // Keep generic message fields redacted by default unless they are under
    // error objects (handled in _sanitizeData).
    return lower == 'message' || lower == 'messages';
  }

  static bool _isErrorMessagePath(List<String> path) {
    if (path.isEmpty) return false;
    final normalized = path.map((p) => p.toLowerCase()).toList();
    if (normalized.last != 'message') return false;
    return normalized.contains('error') || normalized.contains('errors');
  }

  static String _sanitizeText(String input) {
    var output = input;

    output = output.replaceAllMapped(
      RegExp(r'\b(bearer)\s+[A-Za-z0-9._~+\-/=]{12,}\b', caseSensitive: false),
      (match) => '${match.group(1)} [REDACTED]',
    );
    output = output.replaceAllMapped(
      RegExp(r'\bsk-[A-Za-z0-9_-]{12,}\b', caseSensitive: false),
      (_) => 'sk-[REDACTED]',
    );
    output = output.replaceAllMapped(
      RegExp(r'\b[A-Z]:\\[^\s"]+', caseSensitive: false),
      (match) => _redactPathToken(match.group(0)!),
    );
    output = output.replaceAllMapped(
      RegExp(r'/(?:Users|home|var|private|tmp|data)/[^\s"]+'),
      (match) => _redactPathToken(match.group(0)!),
    );

    return output;
  }

  static String _redactPathToken(String rawPath) {
    final normalized = rawPath.replaceAll('\\', '/');
    final parts =
        normalized.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '<path>';
    return '<path:${parts.last}>';
  }

  static String _indent(String text, int spaces) {
    final pad = ' ' * spaces;
    return text.split('\n').map((line) => '$pad$line').join('\n');
  }
}

class _ParsedLog {
  final AppLogLevel level;
  final String channel;
  final String? category;
  final String message;

  const _ParsedLog({
    required this.level,
    required this.channel,
    this.category,
    required this.message,
  });
}
