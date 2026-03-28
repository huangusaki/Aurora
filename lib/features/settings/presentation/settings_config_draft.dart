import 'dart:convert';

import 'package:flutter/widgets.dart';

enum SettingsParamValueType {
  string,
  number,
  boolean,
  json,
}

SettingsParamValueType detectSettingsParamValueType(dynamic value) {
  if (value is bool) {
    return SettingsParamValueType.boolean;
  }
  if (value is num) {
    return SettingsParamValueType.number;
  }
  if (value is Map || value is List) {
    return SettingsParamValueType.json;
  }
  return SettingsParamValueType.string;
}

dynamic parseSettingsParamValue(
  SettingsParamValueType type,
  String rawValue,
) {
  switch (type) {
    case SettingsParamValueType.string:
      return rawValue;
    case SettingsParamValueType.number:
      return num.parse(rawValue);
    case SettingsParamValueType.boolean:
      final normalized = rawValue.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
      throw const FormatException('Expected true or false.');
    case SettingsParamValueType.json:
      return jsonDecode(rawValue);
  }
}

String formatSettingsParamValue(dynamic value) {
  if (value is String) {
    return '"$value"';
  }
  return jsonEncode(value);
}

class SettingsConfigDraft {
  SettingsConfigDraft._({
    required Map<String, dynamic> settings,
    required this.thinkingEnabled,
    required this.thinkingMode,
    required String thinkingBudget,
    required String temperature,
    required String maxTokens,
    required String contextLength,
  })  : _settings = settings,
        thinkingBudgetController = TextEditingController(text: thinkingBudget),
        temperatureController = TextEditingController(text: temperature),
        maxTokensController = TextEditingController(text: maxTokens),
        contextLengthController = TextEditingController(text: contextLength);

  factory SettingsConfigDraft.fromSettings(Map<String, dynamic> settings) {
    final normalizedSettings = Map<String, dynamic>.from(settings)
      ..remove('_aurora_thinking_enabled')
      ..remove('_aurora_thinking_value')
      ..remove('_aurora_thinking_mode');

    final thinkingConfig = settings['_aurora_thinking_config'];
    final legacyThinkingEnabled = settings['_aurora_thinking_enabled'] == true;
    final legacyThinkingBudget =
        settings['_aurora_thinking_value']?.toString() ?? '';
    final legacyThinkingMode =
        settings['_aurora_thinking_mode']?.toString() ?? 'auto';

    final thinkingEnabled = thinkingConfig is Map
        ? thinkingConfig['enabled'] == true
        : legacyThinkingEnabled;
    final thinkingBudget = thinkingConfig is Map
        ? thinkingConfig['budget']?.toString() ?? ''
        : legacyThinkingBudget;
    final thinkingMode = thinkingConfig is Map
        ? thinkingConfig['mode']?.toString() ?? 'auto'
        : legacyThinkingMode;

    final generationConfig = settings['_aurora_generation_config'];
    final temperature =
        generationConfig is Map ? generationConfig['temperature']?.toString() ?? '' : '';
    final maxTokens =
        generationConfig is Map ? generationConfig['max_tokens']?.toString() ?? '' : '';
    final contextLength = generationConfig is Map
        ? generationConfig['context_length']?.toString() ?? ''
        : '';

    return SettingsConfigDraft._(
      settings: normalizedSettings,
      thinkingEnabled: thinkingEnabled,
      thinkingMode: thinkingMode,
      thinkingBudget: thinkingBudget,
      temperature: temperature,
      maxTokens: maxTokens,
      contextLength: contextLength,
    );
  }

  Map<String, dynamic> _settings;
  bool thinkingEnabled;
  String thinkingMode;

  final TextEditingController thinkingBudgetController;
  final TextEditingController temperatureController;
  final TextEditingController maxTokensController;
  final TextEditingController contextLengthController;

  Map<String, dynamic> get settings => Map<String, dynamic>.from(_settings);

  Map<String, dynamic> get customParams => Map<String, dynamic>.fromEntries(
        _settings.entries.where((entry) => !entry.key.startsWith('_aurora_')),
      );

  Map<String, dynamic> buildSettings({
    Map<String, dynamic>? customParams,
  }) {
    final nextSettings = Map<String, dynamic>.from(_settings)
      ..remove('_aurora_thinking_config')
      ..remove('_aurora_generation_config');

    if (customParams != null) {
      nextSettings.removeWhere((key, _) => !key.startsWith('_aurora_'));
      nextSettings.addAll(customParams);
    }

    final thinkingBudget = thinkingBudgetController.text.trim();
    if (thinkingEnabled) {
      nextSettings['_aurora_thinking_config'] = {
        'enabled': true,
        'budget': thinkingBudget,
        'mode': thinkingMode,
      };
    }

    final temperature = temperatureController.text.trim();
    final maxTokens = maxTokensController.text.trim();
    final contextLength = contextLengthController.text.trim();
    if (temperature.isNotEmpty ||
        maxTokens.isNotEmpty ||
        contextLength.isNotEmpty) {
      nextSettings['_aurora_generation_config'] = {
        if (temperature.isNotEmpty) 'temperature': temperature,
        if (maxTokens.isNotEmpty) 'max_tokens': maxTokens,
        if (contextLength.isNotEmpty) 'context_length': contextLength,
      };
    }

    _settings = Map<String, dynamic>.from(nextSettings);
    return settings;
  }

  void replaceSettings(Map<String, dynamic> settings) {
    final refreshed = SettingsConfigDraft.fromSettings(settings);
    thinkingEnabled = refreshed.thinkingEnabled;
    thinkingMode = refreshed.thinkingMode;
    thinkingBudgetController.text = refreshed.thinkingBudgetController.text;
    temperatureController.text = refreshed.temperatureController.text;
    maxTokensController.text = refreshed.maxTokensController.text;
    contextLengthController.text = refreshed.contextLengthController.text;
    _settings = refreshed._settings;
    refreshed.dispose();
  }

  void dispose() {
    thinkingBudgetController.dispose();
    temperatureController.dispose();
    maxTokensController.dispose();
    contextLengthController.dispose();
  }
}
