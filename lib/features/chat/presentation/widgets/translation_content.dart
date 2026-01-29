import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';
import '../chat_provider.dart';
import '../../domain/message.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

class TranslationContent extends ConsumerStatefulWidget {
  const TranslationContent({super.key});
  @override
  ConsumerState<TranslationContent> createState() => _TranslationContentState();
}

class _TranslationContentState extends ConsumerState<TranslationContent> {
  final TextEditingController _sourceController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _sourceLang = '自动检测';
  String _targetLang = '简体中文';
  bool _showComparison = true;
  bool _hasRestored = false;
  final List<String> _sourceLanguages = [
    '自动检测',
    '英语',
    '日语',
    '韩语',
    '简体中文',
    '繁体中文',
    '俄语',
    '法语',
    '德语'
  ];
  final List<String> _targetLanguages = [
    '简体中文',
    '英语',
    '日语',
    '韩语',
    '繁体中文',
    '俄语',
    '法语',
    '德语'
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryRestore();
    });
  }

  void _tryRestore() {
    if (_hasRestored) return;
    final chatState = ref.read(translationProvider);
    if (chatState.messages.isNotEmpty) {
      final lastUserMsg = chatState.messages.lastWhere((m) => m.isUser,
          orElse: () => Message(
              content: '', isUser: true, id: '', timestamp: DateTime.now()));
      if (lastUserMsg.content.isNotEmpty) {
        _sourceController.text = lastUserMsg.content;
      }
      _hasRestored = true;
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
    notifier.clearContext().then((_) {
      final sb = StringBuffer();
      sb.writeln(
          '你是一位精通多国语言的专业翻译专家。请将以下${_sourceLang == '自动检测' ? '' : _sourceLang}文本翻译成$_targetLang。');
      sb.writeln('要求：');
      sb.writeln('1. 翻译准确、地道，符合目标语言的表达习惯。');
      sb.writeln('2. 严格保留原文的换行格式和段落结构，不要合并段落。');
      sb.writeln('3. 只输出翻译后的内容，不要包含任何解释、前言或后缀。');
      sb.writeln('');
      sb.writeln('原文内容：');
      sb.writeln(_sourceController.text);
      notifier.sendMessage(_sourceController.text, apiContent: sb.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(translationProvider, (prev, next) {
      if (!_hasRestored && next.messages.isNotEmpty) {
        final lastUserMsg = next.messages.lastWhere((m) => m.isUser,
            orElse: () => Message(
                content: '', isUser: true, id: '', timestamp: DateTime.now()));
        if (lastUserMsg.content.isNotEmpty) {
          _sourceController.text = lastUserMsg.content;
          _hasRestored = true;
        }
      }
    });
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final chatState = ref.watch(translationProvider);
    final isWindows = PlatformUtils.isWindows;
    final fontFamily = isWindows ? 'Microsoft YaHei' : null;
    final aiMessage =
        chatState.messages.isNotEmpty && !chatState.messages.last.isUser
            ? chatState.messages.last
            : null;
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                fluent.Text(l10n.textTranslation,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 20),
                _buildLangSelector(
                    value: _sourceLang,
                    items: _sourceLanguages,
                    onChanged: (v) => setState(() => _sourceLang = v!)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(fluent.FluentIcons.forward,
                      size: 12, color: Colors.grey),
                ),
                _buildLangSelector(
                    value: _targetLang,
                    items: _targetLanguages,
                    onChanged: (v) => setState(() => _targetLang = v!)),
                const Spacer(),
                if (chatState.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: fluent.ProgressRing(
                        strokeWidth: 2.5, activeColor: Colors.blue),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildCard(
                      theme: theme,
                      title: l10n.sourceText,
                      fontFamily: fontFamily,
                      child: fluent.TextBox(
                        controller: _sourceController,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        placeholder: l10n.enterTextToTranslate,
                        decoration: null,
                        highlightColor: Colors.transparent,
                        unfocusedColor: Colors.transparent,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          fontFamily: fontFamily,
                          color: theme.typography.body?.color,
                        ),
                      ),
                      actions: [
                        if (_sourceController.text.isNotEmpty)
                          fluent.IconButton(
                            icon:
                                const Icon(fluent.FluentIcons.clear, size: 14),
                            onPressed: () => _sourceController.clear(),
                          ),
                        const SizedBox(width: 8),
                        fluent.Button(
                          style: fluent.ButtonStyle(
                            shape: fluent.ButtonState.all(
                                RoundedRectangleBorder(side: BorderSide.none)),
                            backgroundColor:
                                fluent.ButtonState.resolveWith((states) {
                              if (states.isHovering)
                                return theme.resources.subtleFillColorSecondary;
                              return Colors.transparent;
                            }),
                          ),
                          onPressed: chatState.isLoading ? null : _translate,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(fluent.FluentIcons.translate,
                                  size: 14, color: theme.accentColor),
                              const SizedBox(width: 6),
                              Text(
                                  chatState.isLoading
                                      ? '...'
                                      : l10n.translateButton,
                                  style: TextStyle(
                                      color: theme.accentColor,
                                      fontWeight: FontWeight.normal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      theme: theme,
                      title: l10n.targetText,
                      fontFamily: fontFamily,
                      actions: [
                        fluent.Tooltip(
                          message: _showComparison
                              ? l10n.disableCompare
                              : l10n.enableCompare,
                          child: fluent.IconButton(
                            icon: Icon(
                              fluent.FluentIcons.compare,
                              size: 16,
                              color: _showComparison ? theme.accentColor : null,
                            ),
                            onPressed: () => setState(
                                () => _showComparison = !_showComparison),
                          ),
                        ),
                        fluent.IconButton(
                          icon: const Icon(fluent.FluentIcons.copy, size: 16),
                          onPressed: () {
                            final text = aiMessage?.content;
                            if (text != null && text.isNotEmpty) {
                              final item = DataWriterItem();
                              item.add(Formats.plainText(text));
                              SystemClipboard.instance?.write([item]);
                            }
                          },
                        ),
                      ],
                      child: _buildTargetContent(
                          chatState, aiMessage, theme, fontFamily),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangSelector({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 200,
      child: fluent.ComboBox<String>(
        value: value,
        items: items
            .map((e) => fluent.ComboBoxItem(
                child: Text(_getDisplayLanguage(context, e),
                    style: const TextStyle(fontSize: 13)),
                value: e))
            .toList(),
        onChanged: onChanged,
        placeholder: Text(AppLocalizations.of(context)!.selectLanguage,
            style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  String _getDisplayLanguage(BuildContext context, String internalLang) {
    final l10n = AppLocalizations.of(context)!;
    switch (internalLang) {
      case '自动检测':
        return l10n.autoDetect;
      case '英语':
        return l10n.english;
      case '日语':
        return l10n.japanese;
      case '韩语':
        return l10n.korean;
      case '简体中文':
        return l10n.simplifiedChinese;
      case '繁体中文':
        return l10n.traditionalChinese;
      case '俄语':
        return l10n.russian;
      case '法语':
        return l10n.french;
      case '德语':
        return l10n.german;
      default:
        return internalLang;
    }
  }

  Widget _buildCard({
    required fluent.FluentThemeData theme,
    required String title,
    required Widget child,
    String? fontFamily,
    List<Widget>? actions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: theme.resources.surfaceStrokeColorDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                      color: theme.resources.textFillColorSecondary,
                      fontWeight: FontWeight.w600,
                    )),
                if (actions != null) Row(children: actions),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetContent(ChatState chatState, Message? aiMessage,
      fluent.FluentThemeData theme, String? fontFamily) {
    if (aiMessage == null && !chatState.isLoading) {
      return Center(
          child: Text(AppLocalizations.of(context)!.translationPlaceholder,
              style: TextStyle(color: theme.resources.textFillColorSecondary)));
    }
    final targetText = aiMessage?.content ?? '';
    if (chatState.isLoading && targetText.isEmpty) {
      return const Center(child: fluent.ProgressRing());
    }
    if (!_showComparison) {
      return SingleChildScrollView(
        child: SelectableText(
          targetText,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
            color: theme.typography.body?.color,
          ),
        ),
      );
    }
    String sourceText = _sourceController.text;
    if (sourceText.isEmpty && chatState.messages.isNotEmpty) {
      final lastUserMsg = chatState.messages.lastWhere((m) => m.isUser,
          orElse: () => Message(
              content: '', isUser: true, id: '', timestamp: DateTime.now()));
      sourceText = lastUserMsg.content;
    }
    final sourceLines = sourceText.split('\n');
    final targetLines = targetText.split('\n');
    final int itemCount = sourceLines.length > targetLines.length
        ? sourceLines.length
        : targetLines.length;
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (c, i) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final src = index < sourceLines.length ? sourceLines[index] : '';
        final tgt = index < targetLines.length ? targetLines[index] : '';
        if (src.trim().isEmpty && tgt.trim().isEmpty)
          return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (src.isNotEmpty)
              SelectableText(
                src,
                style: TextStyle(
                  color: theme.resources.textFillColorSecondary,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: fontFamily,
                ),
              ),
            if (src.isNotEmpty && tgt.isNotEmpty) const SizedBox(height: 8),
            if (tgt.isNotEmpty)
              SelectableText(
                tgt,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  fontFamily: fontFamily,
                  color: theme.typography.body?.color,
                ),
              ),
          ],
        );
      },
    );
  }
}
