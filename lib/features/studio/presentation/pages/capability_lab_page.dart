import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';

import 'package:aurora/features/settings/presentation/provider_route_labels.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/settings/domain/provider_route_config.dart';
import 'package:aurora/shared/services/capability_route_resolver.dart';
import 'package:aurora/shared/services/model_capability_registry.dart';
import 'package:aurora/shared/services/provider_capability_gateway.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_dropdown.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';

class CapabilityLabPage extends ConsumerStatefulWidget {
  const CapabilityLabPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<CapabilityLabPage> createState() => _CapabilityLabPageState();
}

class _CapabilityLabPageState extends ConsumerState<CapabilityLabPage> {
  final ProviderCapabilityGateway _gateway = ProviderCapabilityGateway();
  final CapabilityRouteResolver _resolver = const CapabilityRouteResolver();
  final TextEditingController _imagePromptController = TextEditingController();
  final TextEditingController _speechTextController = TextEditingController();
  final TextEditingController _audioTextResultController =
      TextEditingController();
  String? _audioFilePath;
  bool _isRunning = false;
  int _tabIndex = 0;
  List<String> _generatedImages = const [];
  String? _speechSummary;
  String? _audioTextResult;
  bool _seededLocalizedDefaults = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededLocalizedDefaults) return;
    final l10n = AppLocalizations.of(context)!;
    _imagePromptController.text = l10n.capabilityLabDefaultImagePrompt;
    _speechTextController.text = l10n.capabilityLabDefaultSpeechText;
    _seededLocalizedDefaults = true;
  }

  @override
  void dispose() {
    _imagePromptController.dispose();
    _speechTextController.dispose();
    _audioTextResultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      ProviderCapability.images,
      ProviderCapability.speech,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    ];

    return ScaffoldPage.withPadding(
      header: PageHeader(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(AuroraIcons.back),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(l10n.capabilityLabTitle),
      ),
      content: TabView(
        currentIndex: _tabIndex,
        onChanged: (value) => setState(() => _tabIndex = value),
        tabs: tabs.map(
          (capability) {
            final selection = _selectionForCapability(settings, capability);
            final provider = selection.provider?.isEnabled == true
                ? selection.provider
                : null;
            final modelOptions = _buildModelOptions(provider, capability);
            final selectedModel =
                _resolveSelectedCapabilityModel(selection.model, modelOptions);
            final invalidSelectedModelMessage = _invalidSelectedModelMessage(
              context,
              provider: provider,
              capability: capability,
              storedModel: selection.model,
              selectedModel: selectedModel,
              modelOptions: modelOptions,
            );
            return Tab(
              text: Text(capabilityLabel(context, capability)),
              icon: Icon(_iconFor(capability), size: 16),
              body: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12, right: 4),
                child: _buildCapabilityBody(
                  context: context,
                  settings: settings,
                  capability: capability,
                  provider: provider,
                  modelOptions: modelOptions,
                  selectedModel: selectedModel,
                  invalidSelectedModelMessage: invalidSelectedModelMessage,
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildCapabilityBody({
    required BuildContext context,
    required SettingsState settings,
    required ProviderCapability capability,
    required ProviderConfig? provider,
    required List<_CapabilityModelOption> modelOptions,
    required String? selectedModel,
    required String? invalidSelectedModelMessage,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final availableProviders = settings.providers
        .where((item) => item.isEnabled)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 680;
            final children = [
              SizedBox(
                width:
                    narrow ? double.infinity : (constraints.maxWidth - 12) / 2,
                child: InfoLabel(
                  label: l10n.providerLabel,
                  child: AuroraFluentDropdownField<String>(
                    value: provider?.id,
                    options: availableProviders
                        .map(
                          (item) => AuroraDropdownOption<String>(
                            value: item.id,
                            label: item.name,
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        _updateProviderSelection(capability, value),
                  ),
                ),
              ),
              SizedBox(
                width:
                    narrow ? double.infinity : (constraints.maxWidth - 12) / 2,
                child: InfoLabel(
                  label: l10n.model,
                  child: AuroraFluentDropdownField<String>(
                    value: selectedModel,
                    options: modelOptions
                        .map(
                          (option) => AuroraDropdownOption<String>(
                            value: option.value,
                            label: option.label,
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        _updateModelSelection(capability, value),
                  ),
                ),
              ),
            ];
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  children[0],
                  const SizedBox(height: 12),
                  children[1],
                ],
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: children,
            );
          },
        ),
        if (invalidSelectedModelMessage != null) ...[
          const SizedBox(height: 12),
          InfoBar(
            severity: InfoBarSeverity.warning,
            title: Text(invalidSelectedModelMessage),
          ),
        ],
        const SizedBox(height: 16),
        if (capability == ProviderCapability.images)
          _buildImageTab(provider, selectedModel)
        else if (capability == ProviderCapability.speech)
          _buildSpeechTab(provider, selectedModel)
        else
          _buildAudioTextTab(capability, provider, selectedModel),
      ],
    );
  }

  Widget _buildImageTab(ProviderConfig? provider, String? model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoLabel(
          label: AppLocalizations.of(context)!.capabilityLabPromptLabel,
          child: TextBox(
            controller: _imagePromptController,
            minLines: 3,
            maxLines: 6,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _isRunning || provider == null || model == null
              ? null
              : () => _runImageGeneration(provider, model),
          child: Text(AppLocalizations.of(context)!.capabilityLabGenerateImage),
        ),
        const SizedBox(height: 16),
        if (_generatedImages.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _generatedImages
                .map((image) => _ImagePreviewCard(image: image))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildSpeechTab(ProviderConfig? provider, String? model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoLabel(
          label: AppLocalizations.of(context)!.capabilityLabInputTextLabel,
          child: TextBox(
            controller: _speechTextController,
            minLines: 3,
            maxLines: 6,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _isRunning || provider == null || model == null
              ? null
              : () => _runSpeech(provider, model),
          child:
              Text(AppLocalizations.of(context)!.capabilityLabSynthesizeSpeech),
        ),
        if (_speechSummary != null) ...[
          const SizedBox(height: 16),
          InfoBar(
            title: Text(_speechSummary!),
            severity: InfoBarSeverity.success,
          ),
        ],
      ],
    );
  }

  Widget _buildAudioTextTab(
    ProviderCapability capability,
    ProviderConfig? provider,
    String? model,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final pickerText =
                AppLocalizations.of(context)!.capabilityLabSelectAudio;
            final fileText = _audioFilePath == null
                ? AppLocalizations.of(context)!.capabilityLabNoAudioFile
                : _audioFilePath!;
            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAudioFileText(fileText, maxLines: 3),
                  const SizedBox(height: 12),
                  Button(
                    onPressed: _pickAudioFile,
                    child: Text(pickerText),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildAudioFileText(fileText),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: _pickAudioFile,
                  child: Text(pickerText),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _isRunning ||
                  provider == null ||
                  model == null ||
                  _audioFilePath == null
              ? null
              : () => _runAudioText(capability, provider, model),
          child: Text(
            capability == ProviderCapability.transcriptions
                ? AppLocalizations.of(context)!.capabilityLabTranscribeAudio
                : AppLocalizations.of(context)!.capabilityLabTranslateAudio,
          ),
        ),
        if (_audioTextResult != null) ...[
          const SizedBox(height: 16),
          InfoLabel(
            label: AppLocalizations.of(context)!.capabilityLabOutputTextLabel,
            child: TextBox(
              controller: _audioTextResultController,
              minLines: 5,
              maxLines: 10,
              readOnly: true,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickAudioFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'audio',
          extensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
        ),
      ],
    );
    if (file == null) return;
    setState(() {
      _audioFilePath = file.path;
      _audioTextResult = null;
      _audioTextResultController.clear();
    });
  }

  Future<void> _runImageGeneration(
      ProviderConfig provider, String model) async {
    await _guardedRun(() async {
      final result = await _gateway.generateImages(
        provider: provider,
        model: model,
        prompt: _imagePromptController.text.trim(),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _generatedImages = result.images;
      });
      showAuroraNotice(
        context,
        l10n.capabilityLabImageGenerated(result.images.length),
        icon: AuroraIcons.success,
      );
    });
  }

  Future<void> _runSpeech(ProviderConfig provider, String model) async {
    await _guardedRun(() async {
      final result = await _gateway.synthesizeSpeech(
        provider: provider,
        model: model,
        input: _speechTextController.text.trim(),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _speechSummary = l10n.capabilityLabSpeechGenerated(
          result.bytes.length,
          result.contentType,
        );
      });
      showAuroraNotice(
        context,
        _speechSummary!,
        icon: AuroraIcons.success,
      );
    });
  }

  Future<void> _runAudioText(
    ProviderCapability capability,
    ProviderConfig provider,
    String model,
  ) async {
    await _guardedRun(() async {
      final result = capability == ProviderCapability.transcriptions
          ? await _gateway.transcribeAudio(
              provider: provider,
              model: model,
              filePath: _audioFilePath!,
            )
          : await _gateway.translateAudio(
              provider: provider,
              model: model,
              filePath: _audioFilePath!,
            );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _audioTextResult = result.text;
        _audioTextResultController.text = result.text;
      });
      showAuroraNotice(
        context,
        l10n.capabilityLabAudioProcessed,
        icon: AuroraIcons.success,
      );
    });
  }

  Future<void> _guardedRun(Future<void> Function() action) async {
    setState(() => _isRunning = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showAuroraNotice(
        context,
        l10n.capabilityLabRequestFailed(_formatErrorMessage(error)),
        icon: AuroraIcons.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  Widget _buildAudioFileText(String text, {int maxLines = 2}) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatErrorMessage(Object error) {
    if (error is DioException) {
      final responseMessage = _extractErrorMessage(error.response?.data);
      final statusCode = error.response?.statusCode;
      if (responseMessage != null && responseMessage.isNotEmpty) {
        return statusCode == null
            ? responseMessage
            : 'HTTP $statusCode: $responseMessage';
      }
      if (statusCode != null) {
        return 'HTTP $statusCode';
      }
      final dioMessage = error.message?.trim();
      if (dioMessage != null && dioMessage.isNotEmpty) {
        return dioMessage;
      }
    }

    final raw = error.toString().trim();
    const exceptionPrefix = 'Exception: ';
    if (raw.startsWith(exceptionPrefix)) {
      return raw.substring(exceptionPrefix.length);
    }
    return raw;
  }

  String? _extractErrorMessage(dynamic payload) {
    final normalized = switch (payload) {
      String text => _tryDecodeJson(text),
      _ => payload,
    };
    if (normalized is Map) {
      final nestedError = normalized['error'];
      if (nestedError is Map) {
        return nestedError['message']?.toString() ??
            nestedError['detail']?.toString() ??
            nestedError['error']?.toString();
      }
      return normalized['message']?.toString() ??
          normalized['detail']?.toString() ??
          normalized['error']?.toString();
    }
    if (normalized is String) {
      final text = normalized.trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  dynamic _tryDecodeJson(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return raw;
    try {
      return jsonDecode(text);
    } catch (_) {
      return raw;
    }
  }

  List<_CapabilityModelOption> _buildModelOptions(
    ProviderConfig? provider,
    ProviderCapability capability,
  ) {
    if (provider == null) {
      return const [];
    }
    final options = <_CapabilityModelOption>[];
    for (final model in provider.models) {
      if (!provider.isModelEnabled(model)) continue;
      final route = _resolver.resolve(
        provider: provider,
        capability: capability,
        modelName: model,
      );
      final assessment = matchModelCapability(
        capability: capability,
        model: model,
        baseUrl: route.baseUrl,
        preset: route.preset,
        routeEnabled: route.enabled,
      );
      if (assessment.isKnownUnsupported) {
        continue;
      }
      options.add(
        _CapabilityModelOption(
          value: model,
          label: '${displayCapabilityMarker(assessment)} $model',
        ),
      );
    }
    return options;
  }

  String? _resolveSelectedCapabilityModel(
    String? storedModel,
    List<_CapabilityModelOption> options,
  ) {
    if (storedModel == null) return null;
    for (final option in options) {
      if (option.value == storedModel) {
        return storedModel;
      }
    }
    return null;
  }

  String? _invalidSelectedModelMessage(
    BuildContext context, {
    required ProviderConfig? provider,
    required ProviderCapability capability,
    required String? storedModel,
    required String? selectedModel,
    required List<_CapabilityModelOption> modelOptions,
  }) {
    if (provider == null || storedModel == null || selectedModel != null) {
      return null;
    }
    final locale = Localizations.localeOf(context).languageCode;
    final route = _resolver.resolve(
      provider: provider,
      capability: capability,
      modelName: storedModel,
    );
    final assessment = matchModelCapability(
      capability: capability,
      model: storedModel,
      baseUrl: route.baseUrl,
      preset: route.preset,
      routeEnabled: route.enabled,
    );
    final capabilityText = capabilityLabel(context, capability);
    if (assessment.isKnownUnsupported) {
      return locale == 'zh'
          ? '已保存的模型“$storedModel”明确不支持$capabilityText，请重新选择模型。'
          : 'Saved model "$storedModel" does not support $capabilityText. Choose another model.';
    }
    final stillExists = provider.models.contains(storedModel);
    final available = modelOptions.isNotEmpty;
    if (!stillExists) {
      return locale == 'zh'
          ? '已保存的模型“$storedModel”已不在当前 Provider 的模型列表中，请重新选择模型。'
          : 'Saved model "$storedModel" is no longer available on this provider. Choose another model.';
    }
    if (!available) {
      return locale == 'zh'
          ? '当前 Provider 没有可用于$capabilityText的兼容模型。'
          : 'No compatible models are available for $capabilityText on this provider.';
    }
    return locale == 'zh'
        ? '已保存的模型“$storedModel”当前不可用于$capabilityText，请重新选择模型。'
        : 'Saved model "$storedModel" is not currently usable for $capabilityText. Choose another model.';
  }

  void _updateProviderSelection(
      ProviderCapability capability, String? providerId) {
    switch (capability) {
      case ProviderCapability.images:
        ref.read(settingsProvider.notifier).setImageSettings(
              providerId: providerId,
              model: null,
            );
        break;
      case ProviderCapability.speech:
        ref.read(settingsProvider.notifier).setSpeechSettings(
              providerId: providerId,
              model: null,
            );
        break;
      case ProviderCapability.transcriptions:
        ref.read(settingsProvider.notifier).setTranscriptionSettings(
              providerId: providerId,
              model: null,
            );
        break;
      case ProviderCapability.translations:
        ref.read(settingsProvider.notifier).setTranslationSettings(
              providerId: providerId,
              model: null,
            );
        break;
      case ProviderCapability.chat:
      case ProviderCapability.models:
      case ProviderCapability.embeddings:
        break;
    }
  }

  void _updateModelSelection(ProviderCapability capability, String? model) {
    switch (capability) {
      case ProviderCapability.images:
        ref.read(settingsProvider.notifier).setImageSettings(
              providerId: _selectionForCapability(
                ref.read(settingsProvider),
                capability,
              ).provider?.id,
              model: model,
            );
        break;
      case ProviderCapability.speech:
        ref.read(settingsProvider.notifier).setSpeechSettings(
              providerId: _selectionForCapability(
                ref.read(settingsProvider),
                capability,
              ).provider?.id,
              model: model,
            );
        break;
      case ProviderCapability.transcriptions:
        ref.read(settingsProvider.notifier).setTranscriptionSettings(
              providerId: _selectionForCapability(
                ref.read(settingsProvider),
                capability,
              ).provider?.id,
              model: model,
            );
        break;
      case ProviderCapability.translations:
        ref.read(settingsProvider.notifier).setTranslationSettings(
              providerId: _selectionForCapability(
                ref.read(settingsProvider),
                capability,
              ).provider?.id,
              model: model,
            );
        break;
      case ProviderCapability.chat:
      case ProviderCapability.models:
      case ProviderCapability.embeddings:
        break;
    }
  }

  _CapabilitySelection _selectionForCapability(
    SettingsState settings,
    ProviderCapability capability,
  ) {
    final providerId = switch (capability) {
      ProviderCapability.images =>
        settings.imageProviderId ?? settings.activeProviderId,
      ProviderCapability.speech =>
        settings.speechProviderId ?? settings.activeProviderId,
      ProviderCapability.transcriptions =>
        settings.transcriptionProviderId ?? settings.activeProviderId,
      ProviderCapability.translations =>
        settings.translationProviderId ?? settings.activeProviderId,
      _ => settings.activeProviderId,
    };
    final provider =
        settings.providers.where((item) => item.id == providerId).firstOrNull ??
            settings.activeProvider;
    final model = switch (capability) {
      ProviderCapability.images => settings.imageModel ??
          provider.selectedModel ??
          provider.models.firstOrNull,
      ProviderCapability.speech => settings.speechModel ??
          provider.selectedModel ??
          provider.models.firstOrNull,
      ProviderCapability.transcriptions => settings.transcriptionModel ??
          provider.selectedModel ??
          provider.models.firstOrNull,
      ProviderCapability.translations => settings.translationModel ??
          provider.selectedModel ??
          provider.models.firstOrNull,
      _ => provider.selectedModel ?? provider.models.firstOrNull,
    };
    return _CapabilitySelection(provider: provider, model: model);
  }
}

class _CapabilitySelection {
  final ProviderConfig? provider;
  final String? model;

  const _CapabilitySelection({
    required this.provider,
    required this.model,
  });
}

class _CapabilityModelOption {
  final String value;
  final String label;

  const _CapabilityModelOption({
    required this.value,
    required this.label,
  });
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider();
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: FluentTheme.of(context).resources.cardStrokeColorDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: provider == null
          ? Center(
              child: Text(
                image,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : Image(
              image: provider,
              fit: BoxFit.cover,
            ),
    );
  }

  ImageProvider? _imageProvider() {
    if (image.startsWith('data:')) {
      final match = RegExp(r'^data:([^;]+);base64,(.+)$').firstMatch(image);
      if (match == null) return null;
      return MemoryImage(base64Decode(match.group(2)!));
    }
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return NetworkImage(image);
    }
    return null;
  }
}

IconData _iconFor(ProviderCapability capability) {
  return switch (capability) {
    ProviderCapability.images => AuroraIcons.image,
    ProviderCapability.speech => AuroraIcons.audio,
    ProviderCapability.transcriptions => AuroraIcons.terminal,
    ProviderCapability.translations => AuroraIcons.translation,
    _ => AuroraIcons.model,
  };
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
