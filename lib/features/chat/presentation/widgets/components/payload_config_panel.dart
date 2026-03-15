import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/services/llm_transport_mode.dart';
import 'package:aurora/shared/services/model_capability_registry.dart';
import 'package:aurora/shared/widgets/aurora_dropdown.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';

final RegExp _gemini3ImageModelPattern =
    RegExp(r'gemini.*3.*image.*', caseSensitive: false);

String _normalizeModelNameForPattern(String modelName) {
  return modelName
      .trim()
      .toLowerCase()
      .replaceAll('（', '(')
      .replaceAll('）', ')')
      .replaceAll(RegExp(r'\s+'), '');
}

bool _isGemini3ImageModel(String modelName) {
  final normalized = _normalizeModelNameForPattern(modelName);
  if (normalized.isEmpty) return false;
  return _gemini3ImageModelPattern.hasMatch(normalized);
}

class PayloadConfigPanel extends ConsumerStatefulWidget {
  final String providerId;
  final String modelName;
  final bool forceImageConfig;

  const PayloadConfigPanel({
    super.key,
    required this.providerId,
    required this.modelName,
    this.forceImageConfig = false,
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

  /// 构建统一的卡片式配置区块，与 GlobalConfigDialog 风格一致
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Widget? headerAction,
    Widget? child,
  }) {
    final theme = FluentTheme.of(context);
    return Card(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: theme.accentColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: theme.typography.bodyStrong),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }

  /// 构建行内开关控件，用于 Gemini 原生工具等场景
  Widget _buildToggleRow({
    required String label,
    required bool checked,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.resources.textFillColorPrimary,
              ),
            ),
          ),
          ToggleSwitch(checked: checked, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isImageModel =
        widget.forceImageConfig || _isGemini3ImageModel(widget.modelName);

    if (isImageModel) {
      return _buildImageConfig(context);
    } else {
      return _buildReasoningConfig(context);
    }
  }

  Widget _buildImageConfig(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imageConfig = resolveAuroraImageConfig(_modelSettings);
    final String currentSize = imageConfig.imageSize ?? '2K';
    final String currentMode = imageConfig.mode.wireName;

    final aspectRatios = [
      l10n.auto,
      "1:1",
      "2:3",
      "3:2",
      "1:4",
      "4:1",
      "3:4",
      "4:3",
      "4:5",
      "5:4",
      "8:1",
      "1:8",
      "9:16",
      "16:9",
      "21:9"
    ];
    final sizes = ["0.5K", "1K", "2K", "4K"];

    final String displayAspectRatio = imageConfig.aspectRatio ?? l10n.auto;

    void saveImageConfig(AuroraImageConfig config) {
      final newSettings = withAuroraImageConfig(_modelSettings, config);
      _saveSettings(newSettings);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: l10n.imageTransmissionMode,
          icon: AuroraIcons.settings,
          child: AuroraAdaptiveDropdownField<String>(
            label: l10n.imageTransmissionMode,
            value: currentMode,
            options: [
              AuroraDropdownOption(
                value: ImageConfigTransportMode.auto.wireName,
                label: l10n.imageModeAuto,
              ),
              AuroraDropdownOption(
                value: ImageConfigTransportMode.openaiImageConfig.wireName,
                label: l10n.imageModeOpenaiImageConfig,
              ),
              AuroraDropdownOption(
                value: ImageConfigTransportMode.googleExtraBody.wireName,
                label: l10n.imageModeGoogleExtraBody,
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              saveImageConfig(
                AuroraImageConfig(
                  mode: ImageConfigTransportMode.fromRaw(v),
                  aspectRatio: imageConfig.aspectRatio,
                  imageSize: imageConfig.imageSize,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildSectionCard(
          title: l10n.aspectRatio,
          icon: AuroraIcons.settings,
          child: AuroraAdaptiveDropdownField<String>(
            label: l10n.aspectRatio,
            value: displayAspectRatio,
            options: aspectRatios
                .map((ratio) => AuroraDropdownOption<String>(
                      value: ratio,
                      label: ratio,
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                saveImageConfig(
                  AuroraImageConfig(
                    mode: imageConfig.mode,
                    aspectRatio: v == l10n.auto ? null : v,
                    imageSize: imageConfig.imageSize,
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildSectionCard(
          title: l10n.imageSize,
          icon: AuroraIcons.settings,
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: sizes
                      .indexOf(currentSize)
                      .clamp(0, sizes.length - 1)
                      .toDouble(),
                  min: 0,
                  max: (sizes.length - 1).toDouble(),
                  divisions: sizes.length - 1,
                  label: currentSize,
                  onChanged: (v) {
                    final newSize = sizes[v.toInt()];
                    saveImageConfig(
                      AuroraImageConfig(
                        mode: imageConfig.mode,
                        aspectRatio: imageConfig.aspectRatio,
                        imageSize: newSize,
                      ),
                    );
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
    final settings = ref.watch(settingsProvider);
    final provider = settings.providers.firstWhere(
      (item) => item.id == widget.providerId,
      orElse: () => settings.activeProvider,
    );
    final Map<String, dynamic> thinkingConfig = Map<String, dynamic>.from(
        _modelSettings['_aurora_thinking_config'] ?? {});
    final Map<String, dynamic> generationConfig = Map<String, dynamic>.from(
        _modelSettings['_aurora_generation_config'] ?? {});
    final showGeminiNativeTools =
        provider.providerFamily == ProviderModelFamily.geminiNative;
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
        if (showGeminiNativeTools) ...[
          _buildSectionCard(
            title: l10n.geminiNativeTools,
            icon: AuroraIcons.skills,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildToggleRow(
                  label: l10n.geminiNativeGoogleSearch,
                  checked: nativeGoogleSearch,
                  onChanged: (v) => saveNativeTools(googleSearch: v),
                ),
                _buildToggleRow(
                  label: l10n.geminiNativeUrlContext,
                  checked: nativeUrlContext,
                  onChanged: (v) => saveNativeTools(urlContext: v),
                ),
                _buildToggleRow(
                  label: l10n.geminiNativeCodeExecution,
                  checked: nativeCodeExecution,
                  onChanged: (v) => saveNativeTools(codeExecution: v),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.resources.subtleFillColorSecondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.geminiNativeSearchDisablesLegacySearch,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.resources.textFillColorPrimary
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ── 思考配置 ──
        _buildSectionCard(
          title: l10n.thinkingConfig,
          icon: AuroraIcons.lightbulb,
          headerAction: ToggleSwitch(
            checked: thinkingEnabled,
            onChanged: (v) {
              thinkingConfig['enabled'] = v;
              final newSettings = Map<String, dynamic>.from(_modelSettings);
              newSettings['_aurora_thinking_config'] = thinkingConfig;
              _saveSettings(newSettings);
            },
          ),
          child: thinkingEnabled
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoLabel(
                      label: l10n.thinkingBudget,
                      child: TextBox(
                        controller: _budgetController,
                        placeholder: l10n.thinkingBudgetHint,
                        onChanged: (v) {
                          thinkingConfig['budget'] = v;
                          final newSettings =
                              Map<String, dynamic>.from(_modelSettings);
                          newSettings['_aurora_thinking_config'] =
                              thinkingConfig;
                          _saveSettings(newSettings);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    AuroraAdaptiveDropdownField<String>(
                      label: l10n.transmissionMode,
                      value: thinkingMode,
                      options: [
                        AuroraDropdownOption(
                            value: 'auto', label: l10n.modeAuto),
                        AuroraDropdownOption(
                          value: 'extra_body',
                          label: l10n.modeExtraBody,
                        ),
                        AuroraDropdownOption(
                          value: 'reasoning_effort',
                          label: l10n.modeReasoningEffort,
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          thinkingConfig['mode'] = v;
                          final newSettings =
                              Map<String, dynamic>.from(_modelSettings);
                          newSettings['_aurora_thinking_config'] =
                              thinkingConfig;
                          _saveSettings(newSettings);
                        }
                      },
                    ),
                  ],
                )
              : null,
        ),

        const SizedBox(height: 8),

        // ── 生成配置 ──
        _buildSectionCard(
          title: l10n.generationConfig,
          icon: AuroraIcons.settings,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLabel(
                label: l10n.temperature,
                child: TextBox(
                  controller: _tempController,
                  placeholder: l10n.temperatureHint,
                  onChanged: (v) {
                    generationConfig['temperature'] = v;
                    final newSettings =
                        Map<String, dynamic>.from(_modelSettings);
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
                    final newSettings =
                        Map<String, dynamic>.from(_modelSettings);
                    newSettings['_aurora_generation_config'] = generationConfig;
                    _saveSettings(newSettings);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
