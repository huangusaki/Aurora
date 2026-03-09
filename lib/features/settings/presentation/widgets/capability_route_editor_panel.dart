import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';

import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/features/settings/domain/provider_route_config.dart';
import 'package:aurora/features/settings/presentation/provider_route_labels.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/model_routed_llm_service.dart';
import 'package:aurora/shared/services/provider_capability_gateway.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_dropdown.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';

class CapabilityRouteEditorPanel extends ConsumerWidget {
  const CapabilityRouteEditorPanel({
    super.key,
    required this.provider,
    this.modelName,
  });

  final ProviderConfig provider;
  final String? modelName;

  bool get _isModelOverride => modelName != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ProviderCapability.values.map((capability) {
        final route = _currentRoute(capability);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Expander(
            header: Row(
              children: [
                Icon(_iconForCapability(capability), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capabilityLabel(context, capability),
                        style: theme.typography.bodyStrong,
                      ),
                      Text(
                        capabilityDescription(context, capability),
                        style: theme.typography.caption,
                      ),
                    ],
                  ),
                ),
                if (_isModelOverride && route.isEmpty)
                  Text(
                    l10n.inheritProviderRoute,
                    style: theme.typography.caption,
                  ),
              ],
            ),
            content: _CapabilityRouteEditorCard(
              provider: provider,
              capability: capability,
              modelName: modelName,
              route: route,
              isModelOverride: _isModelOverride,
            ),
          ),
        );
      }).toList(),
    );
  }

  CapabilityRouteConfig _currentRoute(ProviderCapability capability) {
    if (_isModelOverride) {
      return provider.modelCapabilityOverrides[modelName!]
              ?.routeFor(capability) ??
          const CapabilityRouteConfig();
    }
    return provider.capabilityConfig.routeFor(capability) ??
        const CapabilityRouteConfig();
  }
}

class _CapabilityRouteEditorCard extends ConsumerWidget {
  const _CapabilityRouteEditorCard({
    required this.provider,
    required this.capability,
    required this.route,
    required this.isModelOverride,
    this.modelName,
  });

  final ProviderConfig provider;
  final ProviderCapability capability;
  final CapabilityRouteConfig route;
  final bool isModelOverride;
  final String? modelName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = FluentTheme.of(context);
    final presetOptions = _presetsForCapability(capability)
        .map(
          (preset) => AuroraDropdownOption<ProtocolPreset?>(
            value: preset,
            label: protocolPresetLabel(context, preset),
          ),
        )
        .toList();
    final fallbackOptions = <AuroraDropdownOption<ProtocolPreset?>>[
      AuroraDropdownOption<ProtocolPreset?>(
        value: null,
        label: l10n.routeNoFallback,
      ),
      ...presetOptions,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.resources.cardStrokeColorDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final presetField = AuroraFluentDropdownField<ProtocolPreset?>(
                value: route.preset,
                options: presetOptions,
                onChanged: (value) {
                  _saveRoute(ref, route.copyWith(preset: value));
                },
              );
              final controls = Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ToggleSwitch(
                    checked: route.enabled ?? true,
                    content: Text(l10n.enabled),
                    onChanged: (value) {
                      _saveRoute(ref, route.copyWith(enabled: value));
                    },
                  ),
                  Button(
                    child: Text(l10n.routeTestButton),
                    onPressed: () => _runRouteTest(context, ref),
                  ),
                  Button(
                    child: Text(l10n.reset),
                    onPressed: () =>
                        _saveRoute(ref, const CapabilityRouteConfig()),
                  ),
                ],
              );
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    presetField,
                    const SizedBox(height: 12),
                    controls,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: presetField),
                  const SizedBox(width: 12),
                  Flexible(child: controls),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: l10n.routeBaseUrlOverride,
            child: _CommittedTextBox(
              value: route.baseUrlOverride ?? '',
              placeholder: provider.baseUrl,
              onCommitted: (value) =>
                  _saveRoute(ref, route.copyWith(baseUrlOverride: value)),
            ),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: l10n.routePathOverride,
            child: _CommittedTextBox(
              value: route.pathOverride ?? '',
              placeholder: _defaultPathForCapability(capability),
              onCommitted: (value) =>
                  _saveRoute(ref, route.copyWith(pathOverride: value)),
            ),
          ),
          const SizedBox(height: 12),
          Expander(
            header: Text(l10n.routeAdvancedOptions),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                InfoLabel(
                  label: l10n.routeMethodOverride,
                  child: _CommittedTextBox(
                    value: route.methodOverride ?? '',
                    placeholder: 'POST',
                    onCommitted: (value) =>
                        _saveRoute(ref, route.copyWith(methodOverride: value)),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: l10n.routeAuthMode,
                  child: AuroraFluentDropdownField<RouteAuthMode?>(
                    value: route.authMode,
                    options: [
                      AuroraDropdownOption<RouteAuthMode?>(
                        value: null,
                        label: l10n.routePresetDefault,
                      ),
                      ...RouteAuthMode.values.map(
                        (mode) => AuroraDropdownOption<RouteAuthMode?>(
                          value: mode,
                          label: authModeLabel(context, mode),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        _saveRoute(ref, route.copyWith(authMode: value)),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: l10n.routeAuthHeaderName,
                  child: _CommittedTextBox(
                    value: route.authHeaderName ?? '',
                    placeholder: 'Authorization',
                    onCommitted: (value) =>
                        _saveRoute(ref, route.copyWith(authHeaderName: value)),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: l10n.routeAuthQueryKey,
                  child: _CommittedTextBox(
                    value: route.authQueryKey ?? '',
                    placeholder: 'api_key',
                    onCommitted: (value) =>
                        _saveRoute(ref, route.copyWith(authQueryKey: value)),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: l10n.routeApiKeyOverride,
                  child: _CommittedTextBox(
                    value: route.apiKeyOverride ?? '',
                    placeholder: l10n.routeUseProviderApiKeyWhenEmpty,
                    onCommitted: (value) =>
                        _saveRoute(ref, route.copyWith(apiKeyOverride: value)),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: l10n.routeStreamMode,
                  child: AuroraFluentDropdownField<RouteStreamMode?>(
                    value: route.streamMode,
                    options: [
                      AuroraDropdownOption<RouteStreamMode?>(
                        value: null,
                        label: l10n.routePresetDefault,
                      ),
                      ...RouteStreamMode.values.map(
                        (mode) => AuroraDropdownOption<RouteStreamMode?>(
                          value: mode,
                          label: streamModeLabel(context, mode),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        _saveRoute(ref, route.copyWith(streamMode: value)),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: l10n.routeTimeoutMs,
                  child: _CommittedTextBox(
                    value: route.timeoutOverrideMs?.toString() ?? '',
                    placeholder: l10n.routeUseDefaultWhenEmpty,
                    onCommitted: (value) => _saveRoute(
                      ref,
                      route.copyWith(
                        timeoutOverrideMs: value.trim().isEmpty
                            ? null
                            : int.tryParse(value.trim()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: l10n.routeFallbackPreset,
                  child: AuroraFluentDropdownField<ProtocolPreset?>(
                    value: route.fallbackPreset,
                    options: fallbackOptions,
                    onChanged: (value) =>
                        _saveRoute(ref, route.copyWith(fallbackPreset: value)),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: l10n.routeStaticHeadersJson,
                  child: _CommittedTextBox(
                    value: _encodeMap(route.staticHeaders),
                    minLines: 2,
                    maxLines: 4,
                    placeholder: '{"x-header":"value"}',
                    onCommitted: (value) => _saveRoute(
                      ref,
                      route.copyWith(staticHeaders: _decodeStringMap(value)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: l10n.routeStaticQueryJson,
                  child: _CommittedTextBox(
                    value: _encodeMap(route.staticQuery),
                    minLines: 2,
                    maxLines: 4,
                    placeholder: '{"region":"us"}',
                    onCommitted: (value) => _saveRoute(
                      ref,
                      route.copyWith(staticQuery: _decodeStringMap(value)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runRouteTest(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(settingsProvider);
    final liveProvider = settings.providers.firstWhere(
      (item) => item.id == provider.id,
      orElse: () => provider,
    );
    final gateway = ProviderCapabilityGateway();
    final effectiveModel = modelName ??
        liveProvider.selectedModel ??
        (liveProvider.models.isNotEmpty ? liveProvider.models.first : null);

    try {
      switch (capability) {
        case ProviderCapability.chat:
          if (effectiveModel == null || effectiveModel.isEmpty) {
            throw Exception(l10n.routeSelectModelFirst);
          }
          final testSettings = SettingsState(
            providers: [liveProvider],
            activeProviderId: liveProvider.id,
            viewingProviderId: liveProvider.id,
            language: Localizations.localeOf(context).languageCode,
          );
          final response =
              await ModelRoutedLlmService(testSettings).getResponse(
            [Message.user(l10n.routeReplyWithOk)],
            model: effectiveModel,
            providerId: liveProvider.id,
          );
          if (!context.mounted) return;
          showAuroraNotice(
            context,
            response.content?.isNotEmpty == true
                ? l10n.routeChatTestSucceeded(response.content!)
                : l10n.routeChatTestCompleted,
            icon: AuroraIcons.success,
          );
          break;
        case ProviderCapability.models:
          final models = await gateway.fetchModels(provider: liveProvider);
          if (!context.mounted) return;
          showAuroraNotice(
            context,
            l10n.routeModelListTestSucceeded(models.length),
            icon: AuroraIcons.success,
          );
          break;
        case ProviderCapability.embeddings:
          if (effectiveModel == null || effectiveModel.isEmpty) {
            throw Exception(l10n.routeSelectModelFirst);
          }
          final vectors = await gateway.embedTexts(
            provider: liveProvider,
            model: effectiveModel,
            inputs: const ['aurora capability test'],
          );
          if (!context.mounted) return;
          showAuroraNotice(
            context,
            l10n.routeEmbeddingTestSucceeded(
              vectors.isEmpty ? 0 : vectors.first.length,
            ),
            icon: AuroraIcons.success,
          );
          break;
        case ProviderCapability.images:
          if (effectiveModel == null || effectiveModel.isEmpty) {
            throw Exception(l10n.routeSelectModelFirst);
          }
          final result = await gateway.generateImages(
            provider: liveProvider,
            model: effectiveModel,
            prompt: l10n.capabilityLabDefaultImagePrompt,
          );
          if (!context.mounted) return;
          showAuroraNotice(
            context,
            l10n.routeImageTestSucceeded(result.images.length),
            icon: AuroraIcons.success,
          );
          break;
        case ProviderCapability.speech:
          if (effectiveModel == null || effectiveModel.isEmpty) {
            throw Exception(l10n.routeSelectModelFirst);
          }
          final result = await gateway.synthesizeSpeech(
            provider: liveProvider,
            model: effectiveModel,
            input: l10n.capabilityLabDefaultSpeechText,
          );
          if (!context.mounted) return;
          showAuroraNotice(
            context,
            l10n.routeSpeechTestSucceeded(
              result.bytes.length,
              result.contentType,
            ),
            icon: AuroraIcons.success,
          );
          break;
        case ProviderCapability.transcriptions:
        case ProviderCapability.translations:
          if (effectiveModel == null || effectiveModel.isEmpty) {
            throw Exception(l10n.routeSelectModelFirst);
          }
          final file = await openFile(
            acceptedTypeGroups: const [
              XTypeGroup(
                label: 'audio',
                extensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
              ),
            ],
          );
          if (file == null) return;
          final result = capability == ProviderCapability.transcriptions
              ? await gateway.transcribeAudio(
                  provider: liveProvider,
                  model: effectiveModel,
                  filePath: file.path,
                )
              : await gateway.translateAudio(
                  provider: liveProvider,
                  model: effectiveModel,
                  filePath: file.path,
                );
          if (!context.mounted) return;
          showAuroraNotice(
            context,
            l10n.routeAudioTestSucceeded(result.text),
            icon: AuroraIcons.success,
          );
          break;
      }
    } catch (error) {
      if (!context.mounted) return;
      showAuroraNotice(
        context,
        l10n.routeTestFailed(error.toString()),
        icon: AuroraIcons.error,
      );
    }
  }

  void _saveRoute(WidgetRef ref, CapabilityRouteConfig next) {
    final notifier = ref.read(settingsProvider.notifier);
    if (isModelOverride && modelName != null) {
      notifier.updateModelCapabilityRoute(
        providerId: provider.id,
        modelName: modelName!,
        capability: capability,
        route: next,
      );
    } else {
      notifier.updateCapabilityRoute(
        providerId: provider.id,
        capability: capability,
        route: next,
      );
    }
  }
}

class _CommittedTextBox extends StatefulWidget {
  const _CommittedTextBox({
    required this.value,
    required this.onCommitted,
    this.placeholder,
    this.minLines,
    this.maxLines = 1,
  });

  final String value;
  final String? placeholder;
  final int? minLines;
  final int maxLines;
  final ValueChanged<String> onCommitted;

  @override
  State<_CommittedTextBox> createState() => _CommittedTextBoxState();
}

class _CommittedTextBoxState extends State<_CommittedTextBox> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _CommittedTextBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextBox(
      controller: _controller,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      placeholder: widget.placeholder,
      onSubmitted: widget.onCommitted,
      onTapOutside: (_) => widget.onCommitted(_controller.text),
    );
  }
}

List<ProtocolPreset> _presetsForCapability(ProviderCapability capability) {
  return switch (capability) {
    ProviderCapability.chat => [
        ProtocolPreset.openaiChatCompletions,
        ProtocolPreset.openaiResponses,
        ProtocolPreset.anthropicMessages,
        ProtocolPreset.geminiNativeGenerateContent,
        ProtocolPreset.geminiOpenaiChatCompletions,
        ProtocolPreset.customJson,
      ],
    ProviderCapability.models => [
        ProtocolPreset.openaiModels,
        ProtocolPreset.anthropicModels,
        ProtocolPreset.geminiModels,
        ProtocolPreset.customJson,
      ],
    ProviderCapability.embeddings => [
        ProtocolPreset.openaiEmbeddings,
        ProtocolPreset.geminiEmbedContent,
        ProtocolPreset.customJson,
      ],
    ProviderCapability.images => [
        ProtocolPreset.openaiImages,
        ProtocolPreset.openaiResponses,
        ProtocolPreset.customJson,
      ],
    ProviderCapability.speech => [
        ProtocolPreset.openaiAudioSpeech,
        ProtocolPreset.customJson,
      ],
    ProviderCapability.transcriptions => [
        ProtocolPreset.openaiAudioTranscriptions,
        ProtocolPreset.customMultipart,
        ProtocolPreset.customJson,
      ],
    ProviderCapability.translations => [
        ProtocolPreset.openaiAudioTranslations,
        ProtocolPreset.customMultipart,
        ProtocolPreset.customJson,
      ],
  };
}

IconData _iconForCapability(ProviderCapability capability) {
  return switch (capability) {
    ProviderCapability.chat => AuroraIcons.robot,
    ProviderCapability.models => AuroraIcons.model,
    ProviderCapability.embeddings => AuroraIcons.database,
    ProviderCapability.images => AuroraIcons.image,
    ProviderCapability.speech => AuroraIcons.audio,
    ProviderCapability.transcriptions => AuroraIcons.terminal,
    ProviderCapability.translations => AuroraIcons.translation,
  };
}

String _defaultPathForCapability(ProviderCapability capability) {
  return switch (capability) {
    ProviderCapability.chat => 'chat/completions',
    ProviderCapability.models => 'models',
    ProviderCapability.embeddings => 'embeddings',
    ProviderCapability.images => 'images/generations',
    ProviderCapability.speech => 'audio/speech',
    ProviderCapability.transcriptions => 'audio/transcriptions',
    ProviderCapability.translations => 'audio/translations',
  };
}

String _encodeMap(Map<String, String> values) {
  if (values.isEmpty) return '';
  return const JsonEncoder.withIndent('  ').convert(values);
}

Map<String, String> _decodeStringMap(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const {};
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    }
  } catch (_) {}
  return const {};
}
