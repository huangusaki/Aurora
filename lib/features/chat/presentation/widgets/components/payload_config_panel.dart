import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/services/llm_transport_mode.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';

class PayloadConfigPanel extends ConsumerStatefulWidget {
  final String providerId;
  final String modelName;

  const PayloadConfigPanel({
    super.key,
    required this.providerId,
    required this.modelName,
  });

  @override
  ConsumerState<PayloadConfigPanel> createState() => _PayloadConfigPanelState();
}

class _PayloadConfigPanelState extends ConsumerState<PayloadConfigPanel> {
  late Map<String, dynamic> _modelSettings;
  late TextEditingController _budgetController;
  late TextEditingController _tempController;
  late TextEditingController _ctxLenController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    final thinkingConfig = _modelSettings['_aurora_thinking_config'] ?? {};
    final generationConfig = _modelSettings['_aurora_generation_config'] ?? {};

    _budgetController =
        TextEditingController(text: thinkingConfig['budget']?.toString() ?? '');
    _tempController = TextEditingController(
        text: generationConfig['temperature']?.toString() ?? '');
    _ctxLenController = TextEditingController(
        text: generationConfig['context_length']?.toString() ?? '');
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _tempController.dispose();
    _ctxLenController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    _modelSettings = ref.read(settingsProvider.notifier).getModelSettings(
          widget.providerId,
          widget.modelName,
        );
  }

  void _saveSettings(Map<String, dynamic> settings) {
    setState(() {
      _modelSettings = settings;
    });
    ref.read(settingsProvider.notifier).updateModelSettings(
          providerId: widget.providerId,
          modelName: widget.modelName,
          settings: settings,
        );
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value == null) return false;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Widget child,
    Widget? headerAction,
  }) {
    final theme = FluentTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.resources.dividerStrokeColorDefault),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerAction == null)
            Row(
              children: [
                Icon(icon, size: 14, color: theme.accentColor),
                const SizedBox(width: 8),
                Expanded(child: child),
              ],
            )
          else ...[
            Row(
              children: [
                Icon(icon, size: 14, color: theme.accentColor),
                const SizedBox(width: 8),
                Expanded(child: child),
                headerAction,
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isImageModel = widget.modelName == 'gemini-3-pro-image-preview';

    if (isImageModel) {
      return _buildImageConfig(context);
    } else {
      return _buildReasoningConfig(context);
    }
  }

  Widget _buildImageConfig(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, dynamic> imageConfig = Map<String, dynamic>.from(
        _modelSettings['_aurora_image_config'] ??
            _modelSettings['image_config'] ??
            {});

    final String currentSize = imageConfig['image_size'] ?? '2K';

    final aspectRatios = [
      l10n.auto,
      "1:1",
      "2:3",
      "3:2",
      "3:4",
      "4:3",
      "4:5",
      "5:4",
      "9:16",
      "16:9",
      "21:9"
    ];
    final sizes = ["1K", "2K", "4K"];

    final String displayAspectRatio = imageConfig['aspect_ratio'] ?? l10n.auto;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoLabel(
          label: l10n.aspectRatio,
          child: ComboBox<String>(
            value: displayAspectRatio,
            isExpanded: true,
            items: aspectRatios.map((r) {
              return ComboBoxItem(
                value: r,
                child: Text(r),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                if (v == l10n.auto) {
                  imageConfig.remove('aspect_ratio');
                } else {
                  imageConfig['aspect_ratio'] = v;
                }
                final newSettings = Map<String, dynamic>.from(_modelSettings);
                // Remove old key if present to migrate
                newSettings.remove('image_config');
                newSettings['_aurora_image_config'] = imageConfig;
                _saveSettings(newSettings);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: l10n.imageSize,
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: sizes.indexOf(currentSize).toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  label: currentSize,
                  onChanged: (v) {
                    final newSize = sizes[v.toInt()];
                    imageConfig['image_size'] = newSize;
                    final newSettings =
                        Map<String, dynamic>.from(_modelSettings);
                    // Remove old key if present to migrate
                    newSettings.remove('image_config');
                    newSettings['_aurora_image_config'] = imageConfig;
                    _saveSettings(newSettings);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(currentSize,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasoningConfig(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = FluentTheme.of(context);
    final Map<String, dynamic> thinkingConfig = Map<String, dynamic>.from(
        _modelSettings['_aurora_thinking_config'] ?? {});
    final Map<String, dynamic> generationConfig = Map<String, dynamic>.from(
        _modelSettings['_aurora_generation_config'] ?? {});
    final LlmTransportMode transportMode =
        resolveTransportModeFromSettings(_modelSettings);
    final nativeToolRaw = _modelSettings[auroraGeminiNativeToolsKey];
    final nativeToolMap = nativeToolRaw is Map
        ? Map<String, dynamic>.from(nativeToolRaw)
        : <String, dynamic>{};
    final nativeGoogleSearch =
        _toBool(nativeToolMap[auroraGeminiNativeGoogleSearchKey]);
    final nativeUrlContext =
        _toBool(nativeToolMap[auroraGeminiNativeUrlContextKey]);
    final nativeCodeExecution =
        _toBool(nativeToolMap[auroraGeminiNativeCodeExecutionKey]);

    final bool thinkingEnabled = thinkingConfig['enabled'] == true;
    final String thinkingMode = thinkingConfig['mode']?.toString() ?? 'auto';

    String transportModeLabel(LlmTransportMode mode) {
      switch (mode) {
        case LlmTransportMode.auto:
          return l10n.transportModeAuto;
        case LlmTransportMode.openaiCompat:
          return l10n.transportModeOpenaiCompat;
        case LlmTransportMode.geminiNative:
          return l10n.transportModeGeminiNative;
      }
    }

    void saveNativeTools({
      bool? googleSearch,
      bool? urlContext,
      bool? codeExecution,
    }) {
      final config = GeminiNativeToolsConfig(
        googleSearch: googleSearch ?? nativeGoogleSearch,
        urlContext: urlContext ?? nativeUrlContext,
        codeExecution: codeExecution ?? nativeCodeExecution,
      );
      final newSettings = withGeminiNativeTools(_modelSettings, config);
      _saveSettings(newSettings);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          icon: AuroraIcons.globe,
          child: Text(l10n.transportMode,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        ComboBox<LlmTransportMode>(
          value: transportMode,
          isExpanded: true,
          items: LlmTransportMode.values
              .map((mode) => ComboBoxItem<LlmTransportMode>(
                    value: mode,
                    child: Text(transportModeLabel(mode)),
                  ))
              .toList(),
          onChanged: (mode) {
            if (mode == null) return;
            final newSettings = withTransportMode(_modelSettings, mode);
            _saveSettings(newSettings);
          },
        ),

        if (transportMode == LlmTransportMode.geminiNative) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: AuroraIcons.skills,
            child: Text(l10n.geminiNativeTools,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(l10n.geminiNativeGoogleSearch),
              ),
              ToggleSwitch(
                checked: nativeGoogleSearch,
                onChanged: (v) => saveNativeTools(googleSearch: v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(l10n.geminiNativeUrlContext),
              ),
              ToggleSwitch(
                checked: nativeUrlContext,
                onChanged: (v) => saveNativeTools(urlContext: v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(l10n.geminiNativeCodeExecution),
              ),
              ToggleSwitch(
                checked: nativeCodeExecution,
                onChanged: (v) => saveNativeTools(codeExecution: v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.resources.subtleFillColorSecondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l10n.geminiNativeSearchDisablesLegacySearch,
              style: TextStyle(
                fontSize: 12,
                color: theme.resources.textFillColorPrimary.withValues(
                  alpha: 0.82,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        _buildSectionCard(
          icon: AuroraIcons.lightbulb,
          child: Text(l10n.thinkingConfig,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          headerAction: ToggleSwitch(
            checked: thinkingEnabled,
            onChanged: (v) {
              thinkingConfig['enabled'] = v;
              final newSettings = Map<String, dynamic>.from(_modelSettings);
              newSettings['_aurora_thinking_config'] = thinkingConfig;
              _saveSettings(newSettings);
            },
          ),
        ),
        if (thinkingEnabled) ...[
          const SizedBox(height: 8),
          InfoLabel(
            label: l10n.thinkingBudget,
            child: TextBox(
              controller: _budgetController,
              placeholder: l10n.thinkingBudgetHint,
              onChanged: (v) {
                thinkingConfig['budget'] = v;
                final newSettings = Map<String, dynamic>.from(_modelSettings);
                newSettings['_aurora_thinking_config'] = thinkingConfig;
                _saveSettings(newSettings);
              },
            ),
          ),
          const SizedBox(height: 8),
          InfoLabel(
            label: l10n.transmissionMode,
            child: ComboBox<String>(
              value: thinkingMode,
              isExpanded: true,
              items: [
                ComboBoxItem(value: 'auto', child: Text(l10n.modeAuto)),
                ComboBoxItem(
                    value: 'extra_body', child: Text(l10n.modeExtraBody)),
                ComboBoxItem(
                    value: 'reasoning_effort',
                    child: Text(l10n.modeReasoningEffort)),
              ],
              onChanged: (v) {
                if (v != null) {
                  thinkingConfig['mode'] = v;
                  final newSettings = Map<String, dynamic>.from(_modelSettings);
                  newSettings['_aurora_thinking_config'] = thinkingConfig;
                  _saveSettings(newSettings);
                }
              },
            ),
          ),
        ],

        const SizedBox(height: 16),
        _buildSectionCard(
          icon: AuroraIcons.settings,
          child: Text(l10n.generationConfig,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        InfoLabel(
          label: l10n.temperature,
          child: TextBox(
            controller: _tempController,
            placeholder: l10n.temperatureHint,
            onChanged: (v) {
              generationConfig['temperature'] = v;
              final newSettings = Map<String, dynamic>.from(_modelSettings);
              newSettings['_aurora_generation_config'] = generationConfig;
              _saveSettings(newSettings);
            },
          ),
        ),
        const SizedBox(height: 8),
        InfoLabel(
          label: l10n.contextLength,
          child: TextBox(
            controller: _ctxLenController,
            placeholder: l10n.contextLengthHint,
            onChanged: (v) {
              generationConfig['context_length'] = v;
              final newSettings = Map<String, dynamic>.from(_modelSettings);
              newSettings['_aurora_generation_config'] = generationConfig;
              _saveSettings(newSettings);
            },
          ),
        ),
      ],
    );
  }
}
