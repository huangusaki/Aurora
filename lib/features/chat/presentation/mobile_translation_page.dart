import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/message.dart';
import 'chat_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/translation_prompt_utils.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';

class MobileTranslationPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const MobileTranslationPage({super.key, this.onBack});
  @override
  ConsumerState<MobileTranslationPage> createState() =>
      _MobileTranslationPageState();
}

class _MobileTranslationPageState extends ConsumerState<MobileTranslationPage> {
  final TextEditingController _sourceController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _sourceLang = 'auto';
  String _targetLang = 'zh_hans';
  bool _showComparison = true;
  bool _hasRestored = false;
  final List<String> _sourceLanguages = [
    'auto',
    'en',
    'ja',
    'ko',
    'zh_hans',
    'zh_hant',
    'ru',
    'fr',
    'de',
  ];
  final List<String> _targetLanguages = [
    'zh_hans',
    'en',
    'ja',
    'ko',
    'zh_hant',
    'ru',
    'fr',
    'de',
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryRestore());
  }

  void _tryRestore() {
    if (_hasRestored) return;
    final chatState = ref.read(translationProvider);
    if (chatState.messages.isNotEmpty) {
      final lastUserMsg = chatState.messages.lastWhere((m) => m.isUser,
          orElse: () => Message(
              content: '', isUser: true, id: '', timestamp: DateTime.now()));
      final sourceText =
          TranslationPromptUtils.extractSourceText(lastUserMsg.content);
      if (sourceText.isNotEmpty) {
        _sourceController.text = sourceText;
        _hasRestored = true;
      }
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _translate() {
    if (_sourceController.text.trim().isEmpty) return;
    final notifier = ref.read(translationProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final sourceLabel = _languageLabel(_sourceLang, l10n);
    final targetLabel = _languageLabel(_targetLang, l10n);
    notifier.clearContext().then((_) {
      final sb = StringBuffer();
      sb.writeln(_sourceLang == 'auto'
          ? l10n.translationPromptIntroAuto(targetLabel)
          : l10n.translationPromptIntro(sourceLabel, targetLabel));
      sb.writeln(l10n.translationPromptRequirements);
      sb.writeln(l10n.translationPromptRequirement1);
      sb.writeln(l10n.translationPromptRequirement2);
      sb.writeln(l10n.translationPromptRequirement3);
      sb.writeln();
      sb.writeln(l10n.translationPromptSourceText);
      sb.writeln(_sourceController.text);
      notifier.sendMessage(_sourceController.text, apiContent: sb.toString());
    });
  }

  String _languageLabel(String code, AppLocalizations l10n) {
    switch (code) {
      case 'auto':
        return l10n.autoDetect;
      case 'en':
        return l10n.english;
      case 'ja':
        return l10n.japanese;
      case 'ko':
        return l10n.korean;
      case 'zh_hans':
        return l10n.simplifiedChinese;
      case 'zh_hant':
        return l10n.traditionalChinese;
      case 'ru':
        return l10n.russian;
      case 'fr':
        return l10n.french;
      case 'de':
        return l10n.german;
      default:
        return code;
    }
  }

  void _openModelSwitcher() {
    final settingsState = ref.read(settingsProvider);
    final provider = settingsState.activeProvider;
    final l10n = AppLocalizations.of(context)!;
    if (provider.models.isEmpty) {
      showAuroraNotice(
        context,
        l10n.noModelsFetch,
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(
                context, AppLocalizations.of(context)!.selectModel),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final model in provider.models)
                    if (provider.isModelEnabled(model))
                      ListTile(
                        leading: Icon(
                          model == settingsState.selectedModel
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: model == settingsState.selectedModel
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        title: Text(model),
                        onTap: () {
                          ref.read(settingsProvider.notifier).updateProvider(
                                id: provider.id,
                                selectedModel: model,
                              );
                          ref
                              .read(settingsProvider.notifier)
                              .selectProvider(provider.id);
                          Navigator.pop(ctx);
                        },
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(translationProvider, (prev, next) {
      if (!_hasRestored && next.messages.isNotEmpty) {
        final lastUserMsg = next.messages.lastWhere((m) => m.isUser,
            orElse: () => Message(
                content: '', isUser: true, id: '', timestamp: DateTime.now()));
        final sourceText =
            TranslationPromptUtils.extractSourceText(lastUserMsg.content);
        if (sourceText.isNotEmpty) {
          _sourceController.text = sourceText;
          _hasRestored = true;
        }
      }
    });
    final chatState = ref.watch(translationProvider);
    final settingsState = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final aiMessage =
        chatState.messages.isNotEmpty && !chatState.messages.last.isUser
            ? chatState.messages.last
            : null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openModelSwitcher,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  settingsState.selectedModel ?? l10n.modelNotSelected,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon:
                Icon(_showComparison ? Icons.view_agenda : Icons.view_headline),
            tooltip: _showComparison
                ? l10n.closeComparison
                : l10n.bilingualComparison,
            onPressed: () => setState(() => _showComparison = !_showComparison),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.clear,
            onPressed: () {
              _sourceController.clear();
              ref.read(translationProvider.notifier).clearContext();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LanguageDropdown(
                    value: _sourceLang,
                    items: _sourceLanguages,
                    onChanged: (v) => setState(() => _sourceLang = v!),
                    labelBuilder: (value) => _languageLabel(value, l10n),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 22),
                  onPressed: () {
                    if (_sourceLang != 'auto' && _targetLang != _sourceLang) {
                      setState(() {
                        final temp = _sourceLang;
                        _sourceLang = _targetLang;
                        _targetLang = temp;
                      });
                    }
                  },
                ),
                Expanded(
                  child: _LanguageDropdown(
                    value: _targetLang,
                    items: _targetLanguages,
                    onChanged: (v) => setState(() => _targetLang = v!),
                    labelBuilder: (value) => _languageLabel(value, l10n),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.sourceText,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                      if (_sourceController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => _sourceController.clear(),
                          child: Icon(Icons.close,
                              size: 18, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _sourceController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: l10n.enterTextToTranslate,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor),
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: ElevatedButton.icon(
                    onPressed: chatState.isLoading ? null : _translate,
                    icon: chatState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.translate, size: 18),
                    label: Text(chatState.isLoading
                        ? l10n.translating
                        : l10n.translateButton),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.2),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          _showComparison
                              ? l10n.bilingualComparison
                              : l10n.targetText,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                      if (aiMessage != null)
                        GestureDetector(
                          onTap: () {},
                          child: Icon(Icons.copy,
                              size: 18, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildTranslationResult(aiMessage),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationResult(Message? aiMessage) {
    if (aiMessage == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translationResultPlaceholder,
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }
    final sourceLines = _sourceController.text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final targetLines = aiMessage.content
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final itemCount = _showComparison
        ? (sourceLines.length > targetLines.length
            ? sourceLines.length
            : targetLines.length)
        : targetLines.length;
    if (itemCount == 0 && aiMessage.content.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tgt = index < targetLines.length ? targetLines[index] : '';
        if (!_showComparison) {
          return SelectableText(
            tgt,
            style: const TextStyle(fontSize: 16, height: 1.5),
          );
        }
        final src = index < sourceLines.length ? sourceLines[index] : '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (src.isNotEmpty)
              SelectableText(
                src,
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 14, height: 1.4),
              ),
            if (src.isNotEmpty && tgt.isNotEmpty) const SizedBox(height: 4),
            if (tgt.isNotEmpty)
              SelectableText(
                tgt,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
              ),
          ],
        );
      },
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String value) labelBuilder;
  const _LanguageDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelBuilder,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        items: items.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Text(
              labelBuilder(e),
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
