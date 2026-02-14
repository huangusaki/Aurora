part of '../openai_llm_service.dart';

enum _ThinkingTier { minimal, low, medium, high, xhigh }

enum _ModelFamily { gemini, gemini3, anthropic, openai, unknown }

class _ThinkingInput {
  final String raw;
  final int? budgetTokens;
  final _ThinkingTier? tier;

  const _ThinkingInput({required this.raw, this.budgetTokens, this.tier});
}

const Map<_ThinkingTier, int> _defaultBudgetTokensByTier = {
  _ThinkingTier.minimal: 512,
  _ThinkingTier.low: 1024,
  _ThinkingTier.medium: 4096,
  _ThinkingTier.high: 8192,
  _ThinkingTier.xhigh: 32576,
};

_ThinkingInput _parseThinkingInput(String raw) {
  final trimmed = raw.trim();
  final budget = int.tryParse(trimmed);
  if (budget != null) return _ThinkingInput(raw: trimmed, budgetTokens: budget);
  final tier = _tryParseThinkingTier(trimmed);
  return _ThinkingInput(raw: trimmed, tier: tier);
}

_ThinkingTier? _tryParseThinkingTier(String raw) {
  final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  switch (normalized) {
    case 'minimal':
    case 'min':
    case 'mini':
    case 'tiny':
    case 'least':
    case 'lowest':
    case '最小':
    case '最低':
      return _ThinkingTier.minimal;
    case 'low':
    case 'l':
    case 'small':
    case '弱':
    case '低':
      return _ThinkingTier.low;
    case 'medium':
    case 'med':
    case 'mid':
    case 'middle':
    case 'm':
    case '中':
    case '中等':
      return _ThinkingTier.medium;
    case 'high':
    case 'h':
    case 'big':
    case 'strong':
    case '高':
      return _ThinkingTier.high;
    case 'xhigh':
    case 'xh':
    case 'veryhigh':
    case 'ultra':
    case 'max':
    case 'extreme':
    case '最高':
    case '极高':
    case '超高':
      return _ThinkingTier.xhigh;
  }
  return null;
}

_ModelFamily _inferModelFamily(String model) {
  final lower = model.toLowerCase();
  final isAnthropic = lower.contains('claude') || lower.contains('anthropic');

  // Special case: "gemini-claude-*" are Claude models behind OpenAI-compatible
  // proxies (e.g. Antigravity) where thinking is controlled via reasoning_effort.
  // Treat them as OpenAI-family so numeric input can be mapped to effort tiers.
  if (lower.contains('gemini') && isAnthropic) return _ModelFamily.openai;

  final isGemini = lower.contains('gemini');
  final isGemini3 = isGemini &&
      (lower.contains('gemini-3') ||
          lower.contains('gemini_3') ||
          lower.contains('gemini3'));
  if (isGemini3) return _ModelFamily.gemini3;
  if (isGemini) return _ModelFamily.gemini;
  if (isAnthropic) return _ModelFamily.anthropic;

  final isOpenAI = lower.contains('openai') ||
      lower.contains('gpt') ||
      RegExp(r'(^|[\/_-])o[1-9](\b|[\/_-])').hasMatch(lower);
  if (isOpenAI) return _ModelFamily.openai;

  return _ModelFamily.unknown;
}

_ThinkingTier _tierFromBudgetForGemini3(int budgetTokens) {
  final budget = budgetTokens.clamp(0, 1 << 30);
  if (budget <= 512) return _ThinkingTier.minimal;
  if (budget <= 1024) return _ThinkingTier.low;
  if (budget <= 8192) return _ThinkingTier.medium;
  return _ThinkingTier.high;
}

_ThinkingTier _tierFromBudgetForOpenAI(int budgetTokens) {
  final budget = budgetTokens.clamp(0, 1 << 30);
  if (budget <= _defaultBudgetTokensByTier[_ThinkingTier.low]!) {
    return _ThinkingTier.low;
  }
  if (budget <= _defaultBudgetTokensByTier[_ThinkingTier.medium]!) {
    return _ThinkingTier.medium;
  }
  if (budget <= _defaultBudgetTokensByTier[_ThinkingTier.high]!) {
    return _ThinkingTier.high;
  }
  return _ThinkingTier.xhigh;
}

_ThinkingTier _coerceTierForGemini3(_ThinkingTier tier) {
  if (tier == _ThinkingTier.xhigh) return _ThinkingTier.high;
  return tier;
}

_ThinkingTier _coerceTierForOpenAI(_ThinkingTier tier) {
  if (tier == _ThinkingTier.minimal) return _ThinkingTier.low;
  return tier;
}

String _thinkingTierToGeminiEffort(_ThinkingTier tier) {
  final coerced = _coerceTierForGemini3(tier);
  switch (coerced) {
    case _ThinkingTier.minimal:
      return 'minimal';
    case _ThinkingTier.low:
      return 'low';
    case _ThinkingTier.medium:
      return 'medium';
    case _ThinkingTier.high:
      return 'high';
    case _ThinkingTier.xhigh:
      return 'high';
  }
}

bool _supportsXHighReasoningEffort(String baseUrl, String model) {
  final lowerModel = model.toLowerCase();
  if (lowerModel.contains('gemini') &&
      (lowerModel.contains('claude') || lowerModel.contains('anthropic'))) {
    return true;
  }
  final uri = Uri.tryParse(baseUrl);
  final host =
      (uri?.host.isNotEmpty == true ? uri!.host : baseUrl).toLowerCase();
  if (host.contains('openrouter')) return true;
  if (host.endsWith('openai.com') ||
      host.contains('openai.azure.com') ||
      host.contains('azure.com')) {
    return false;
  }
  return false;
}

String _thinkingTierToOpenAIEffort(_ThinkingTier tier,
    {required bool supportsXHigh}) {
  final coerced = _coerceTierForOpenAI(tier);
  if (coerced == _ThinkingTier.xhigh && !supportsXHigh) return 'high';
  switch (coerced) {
    case _ThinkingTier.minimal:
      return 'low';
    case _ThinkingTier.low:
      return 'low';
    case _ThinkingTier.medium:
      return 'medium';
    case _ThinkingTier.high:
      return 'high';
    case _ThinkingTier.xhigh:
      return 'xhigh';
  }
}

String? _thinkingInputToCompatReasoningEffort(
  _ThinkingInput input, {
  required _ModelFamily modelFamily,
  required bool supportsXHigh,
}) {
  final normalizedRaw = input.raw.trim().toLowerCase();
  if (normalizedRaw.isEmpty) return null;

  if (normalizedRaw == 'auto' || normalizedRaw == '-1') return 'auto';
  if (normalizedRaw == 'none' || normalizedRaw == 'off') return 'none';

  if (input.budgetTokens != null) {
    final budget = input.budgetTokens!;
    if (budget < 0) return 'auto';
    if (budget == 0) return 'none';
    final tier = modelFamily == _ModelFamily.gemini3
        ? _tierFromBudgetForGemini3(budget)
        : _tierFromBudgetForOpenAI(budget);
    return _thinkingTierToOpenAIEffort(tier, supportsXHigh: supportsXHigh);
  }

  if (input.tier != null) {
    return _thinkingTierToOpenAIEffort(input.tier!,
        supportsXHigh: supportsXHigh);
  }

  // Allow explicit effort strings if user typed them directly.
  if (normalizedRaw == 'low' ||
      normalizedRaw == 'medium' ||
      normalizedRaw == 'high' ||
      normalizedRaw == 'xhigh') {
    return normalizedRaw;
  }

  return null;
}

bool _isOfficialGeminiOpenAIEndpoint(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  final host = (uri?.host ?? '').toLowerCase();
  if (host.isNotEmpty) {
    return host == 'generativelanguage.googleapis.com';
  }
  return baseUrl.toLowerCase().contains('generativelanguage.googleapis.com');
}

void _removeGoogleThinkingConfigFromRequest(Map<String, dynamic> requestData) {
  final extraBody = _safeStringKeyedMap(requestData['extra_body']);
  if (extraBody.isEmpty) return;
  final google = _safeStringKeyedMap(extraBody['google']);
  if (google.isEmpty) return;

  google.remove('thinking_config');
  if (google.isEmpty) {
    extraBody.remove('google');
  } else {
    extraBody['google'] = google;
  }

  if (extraBody.isEmpty) {
    requestData.remove('extra_body');
  } else {
    requestData['extra_body'] = extraBody;
  }
}

void _applyGeminiExtraBodyReasoningCompat({
  required Map<String, dynamic> requestData,
  required _ThinkingInput input,
  required _ModelFamily modelFamily,
  required String baseUrl,
  required String selectedModel,
}) {
  if (modelFamily != _ModelFamily.gemini &&
      modelFamily != _ModelFamily.gemini3) {
    return;
  }
  if (_isOfficialGeminiOpenAIEndpoint(baseUrl)) return;
  if (requestData.containsKey('reasoning_effort')) return;

  final effort = _thinkingInputToCompatReasoningEffort(
    input,
    modelFamily: modelFamily,
    supportsXHigh: _supportsXHighReasoningEffort(baseUrl, selectedModel),
  );
  if (effort == null || effort.isEmpty) return;
  requestData['reasoning_effort'] = effort;
}

bool _isClaudeRoutedModel(String model) {
  final lowerModel = model.toLowerCase();
  return lowerModel.contains('claude') || lowerModel.contains('anthropic');
}

int? _reasoningEffortToBudgetTokens(String effort) {
  switch (effort.trim().toLowerCase()) {
    case 'minimal':
      return 512;
    case 'low':
      return 1024;
    case 'medium':
      return 8192;
    case 'high':
      return 24576;
    case 'xhigh':
      return 32768;
    default:
      return null;
  }
}

void _ensureReasoningEffortCompatibleMaxTokens({
  required Map<String, dynamic> requestData,
  required String selectedModel,
}) {
  if (!_isClaudeRoutedModel(selectedModel)) return;

  final candidates = <int>[];
  final effortRaw = requestData['reasoning_effort'];
  if (effortRaw != null) {
    final budget = _reasoningEffortToBudgetTokens(effortRaw.toString());
    if (budget != null && budget > 0) candidates.add(budget);
  }
  final extraBody = _safeStringKeyedMap(requestData['extra_body']);
  final anthropic = _safeStringKeyedMap(extraBody['anthropic']);
  final thinking = _safeStringKeyedMap(anthropic['thinking']);
  final budgetRaw = thinking['budget_tokens'];
  final anthropicBudget =
      budgetRaw == null ? null : int.tryParse(budgetRaw.toString().trim());
  if (anthropicBudget != null && anthropicBudget > 0) {
    candidates.add(anthropicBudget);
  }
  if (candidates.isEmpty) return;
  final budgetTokens = candidates.reduce(max);

  final maxTokensRaw = requestData['max_tokens'];
  final maxTokens = maxTokensRaw == null
      ? null
      : int.tryParse(maxTokensRaw.toString().trim());
  if (maxTokens != null) {
    if (maxTokens > budgetTokens) return;
    requestData['max_tokens'] = budgetTokens + 1;
    return;
  }

  // Some Claude-compatible backends apply a low implicit max_tokens default.
  // Always set an explicit compatible value when thinking budget is enabled.
  requestData['max_tokens'] = budgetTokens + 1;
}

int? _budgetTokensFromThinkingInput(_ThinkingInput input) {
  if (input.budgetTokens != null) return input.budgetTokens!.clamp(0, 1 << 30);
  if (input.tier != null) return _defaultBudgetTokensByTier[input.tier!];
  return null;
}

Map<String, dynamic> _safeStringKeyedMap(dynamic value) {
  if (value is! Map) return {};
  final Map<String, dynamic> result = {};
  value.forEach((key, val) {
    if (key is String) result[key] = val;
  });
  return result;
}

void _mergeExtraBodyProvider(
  Map<String, dynamic> requestData, {
  required String providerKey,
  required Map<String, dynamic> providerData,
}) {
  final Map<String, dynamic> extraBody =
      _safeStringKeyedMap(requestData['extra_body']);

  final Map<String, dynamic> mergedProvider =
      _safeStringKeyedMap(extraBody[providerKey]);
  mergedProvider.addAll(providerData);

  extraBody[providerKey] = mergedProvider;
  requestData['extra_body'] = extraBody;
}

bool _isAutoAspectRatio(String raw) {
  final v = raw.trim().toLowerCase();
  return v.isEmpty || v == 'auto' || v == '自动';
}

void _applyImageConfigToRequest({
  required Map<String, dynamic> requestData,
  required Map<String, dynamic> activeParams,
  required String selectedModel,
}) {
  final imageConfig =
      activeParams['_aurora_image_config'] ?? activeParams['image_config'];
  if (imageConfig is! Map) return;

  final isGemini = selectedModel.toLowerCase().contains('gemini');
  if (!isGemini) return;

  final aspectRatioRaw = imageConfig['aspect_ratio']?.toString();
  final imageSizeRaw = imageConfig['image_size']?.toString();

  final aspectRatio =
      (aspectRatioRaw == null || _isAutoAspectRatio(aspectRatioRaw))
          ? null
          : aspectRatioRaw.trim();
  final imageSize = (imageSizeRaw == null || imageSizeRaw.trim().isEmpty)
      ? null
      : imageSizeRaw.trim();

  if (aspectRatio == null && imageSize == null) return;

  requestData['image_config'] = {
    if (aspectRatio != null) 'aspect_ratio': aspectRatio,
    if (imageSize != null) 'image_size': imageSize,
  };
}

void _applyThinkingConfigToRequest({
  required Map<String, dynamic> requestData,
  required Map<String, dynamic> activeParams,
  required String selectedModel,
  required String baseUrl,
}) {
  final thinkingConfig = activeParams['_aurora_thinking_config'];
  bool thinkingEnabled = false;
  String thinkingValue = '';
  String thinkingMode = 'auto';

  if (thinkingConfig != null && thinkingConfig is Map) {
    thinkingEnabled = thinkingConfig['enabled'] == true;
    thinkingValue = thinkingConfig['budget']?.toString() ?? '';
    thinkingMode = thinkingConfig['mode']?.toString() ?? 'auto';
  } else {
    thinkingEnabled = activeParams['_aurora_thinking_enabled'] == true;
    thinkingValue = activeParams['_aurora_thinking_value']?.toString() ?? '';
    thinkingMode = activeParams['_aurora_thinking_mode']?.toString() ?? 'auto';
  }

  if (!thinkingEnabled) return;
  final raw = thinkingValue.trim();
  if (raw.isEmpty) return;

  final modelFamily = _inferModelFamily(selectedModel);
  final isOfficialGeminiOpenAI = _isOfficialGeminiOpenAIEndpoint(baseUrl);
  if (isOfficialGeminiOpenAI) {
    // Official Gemini OpenAI-compatible endpoint requires strict mutual exclusion:
    // Gemini 2.x => thinking_config, Gemini 3.x => reasoning_effort.
    if (modelFamily == _ModelFamily.gemini) {
      thinkingMode = 'extra_body';
    } else if (modelFamily == _ModelFamily.gemini3) {
      thinkingMode = 'reasoning_effort';
    }
  }
  if (thinkingMode == 'auto') {
    if (modelFamily == _ModelFamily.gemini) {
      thinkingMode = 'extra_body';
    } else if (modelFamily == _ModelFamily.gemini3 ||
        modelFamily == _ModelFamily.openai) {
      thinkingMode = 'reasoning_effort';
    } else if (modelFamily == _ModelFamily.anthropic) {
      thinkingMode = 'extra_body';
    } else {
      thinkingMode = 'reasoning_effort';
    }
  }

  final input = _parseThinkingInput(raw);

  if (thinkingMode == 'extra_body') {
    if (modelFamily == _ModelFamily.gemini ||
        modelFamily == _ModelFamily.gemini3) {
      final isGemini3 = modelFamily == _ModelFamily.gemini3;
      if (isGemini3) {
        final String level;
        if (input.budgetTokens != null) {
          level = _thinkingTierToGeminiEffort(
              _tierFromBudgetForGemini3(input.budgetTokens!));
        } else if (input.tier != null) {
          level =
              _thinkingTierToGeminiEffort(_coerceTierForGemini3(input.tier!));
        } else {
          level = input.raw.toLowerCase();
        }
        _mergeExtraBodyProvider(
          requestData,
          providerKey: 'google',
          providerData: {
            'thinking_config': {
              'thinkingLevel': level,
              'includeThoughts': true,
            }
          },
        );
      } else {
        final budgetTokens = _budgetTokensFromThinkingInput(input);
        if (budgetTokens == null) return;
        _mergeExtraBodyProvider(
          requestData,
          providerKey: 'google',
          providerData: {
            'thinking_config': {
              'thinking_budget': budgetTokens,
              'include_thoughts': true,
            }
          },
        );
      }

      // Compatibility for legacy CPA translators:
      // they may ignore extra_body.google.thinking_config but support reasoning_effort.
      _applyGeminiExtraBodyReasoningCompat(
        requestData: requestData,
        input: input,
        modelFamily: modelFamily,
        baseUrl: baseUrl,
        selectedModel: selectedModel,
      );
    } else if (modelFamily == _ModelFamily.anthropic) {
      final budgetTokens = _budgetTokensFromThinkingInput(input);
      if (budgetTokens == null) return;
      _mergeExtraBodyProvider(
        requestData,
        providerKey: 'anthropic',
        providerData: {
          'thinking': {
            'type': 'enabled',
            'budget_tokens': budgetTokens,
          }
        },
      );
    }
  } else if (thinkingMode == 'reasoning_effort') {
    final supportsXHigh = _supportsXHighReasoningEffort(baseUrl, selectedModel);
    String effort;
    if (modelFamily == _ModelFamily.gemini3) {
      if (input.budgetTokens != null) {
        effort = _thinkingTierToGeminiEffort(
            _tierFromBudgetForGemini3(input.budgetTokens!));
      } else if (input.tier != null) {
        effort =
            _thinkingTierToGeminiEffort(_coerceTierForGemini3(input.tier!));
      } else {
        effort = input.raw.toLowerCase();
      }
    } else if (modelFamily == _ModelFamily.openai) {
      if (input.budgetTokens != null) {
        effort = _thinkingTierToOpenAIEffort(
            _tierFromBudgetForOpenAI(input.budgetTokens!),
            supportsXHigh: supportsXHigh);
      } else if (input.tier != null) {
        effort = _thinkingTierToOpenAIEffort(_coerceTierForOpenAI(input.tier!),
            supportsXHigh: supportsXHigh);
      } else {
        effort = input.raw.toLowerCase();
      }
    } else {
      effort = input.raw;
    }
    requestData['reasoning_effort'] = effort;
  }

  // Enforce official Gemini endpoint mutual exclusion even if user/custom params
  // pre-populated one side before compatibility mapping runs.
  if (isOfficialGeminiOpenAI) {
    if (modelFamily == _ModelFamily.gemini) {
      requestData.remove('reasoning_effort');
    } else if (modelFamily == _ModelFamily.gemini3) {
      _removeGoogleThinkingConfigFromRequest(requestData);
    }
  }
}
