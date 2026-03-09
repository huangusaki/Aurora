import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';

import 'package:aurora/features/settings/presentation/provider_route_labels.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/settings/domain/provider_route_config.dart';
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
  final TextEditingController _imagePromptController = TextEditingController();
  final TextEditingController _speechTextController = TextEditingController();
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
    final currentCapability = tabs[_tabIndex];
    final selection = _selectionForCapability(settings, currentCapability);
    final provider = selection.provider;
    final models = provider?.models ?? const <String>[];

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
        tabs: tabs
            .map(
              (capability) => Tab(
                text: Text(capabilityLabel(context, capability)),
                icon: Icon(_iconFor(capability), size: 16),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 12, right: 4),
                  child: _buildCapabilityBody(
                    context: context,
                    settings: settings,
                    capability: capability,
                    provider: provider,
                    models: models,
                    selectedModel: selection.model,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCapabilityBody({
    required BuildContext context,
    required SettingsState settings,
    required ProviderCapability capability,
    required ProviderConfig? provider,
    required List<String> models,
    required String? selectedModel,
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
                    options: models
                        .map(
                          (model) => AuroraDropdownOption<String>(
                            value: model,
                            label: model,
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
                  Text(fileText),
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
                Expanded(child: Text(fileText)),
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
              controller: TextEditingController(text: _audioTextResult),
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
        l10n.capabilityLabRequestFailed(error.toString()),
        icon: AuroraIcons.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
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
