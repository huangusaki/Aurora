import 'package:flutter/material.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_selection.dart';
import 'markdown_generator.dart';

enum SelectableMarkdownRenderMode {
  markdown,
  plainTextPreview,
}

/// A widget that renders markdown content with native text selection.
/// Uses SelectableText.rich for text blocks and specialized widgets for
/// code blocks, tables, and images.
class SelectableMarkdown extends StatefulWidget {
  final String data;
  final bool isDark;
  final Color textColor;
  final double baseFontSize;
  final bool useSelectionArea;
  final SelectableMarkdownRenderMode renderMode;

  const SelectableMarkdown({
    super.key,
    required this.data,
    required this.isDark,
    required this.textColor,
    this.baseFontSize = 14.0,
    this.useSelectionArea = true,
    this.renderMode = SelectableMarkdownRenderMode.markdown,
  });

  @override
  State<SelectableMarkdown> createState() => _SelectableMarkdownState();
}

class _SelectableMarkdownState extends State<SelectableMarkdown> {
  List<Widget> _children = const [];
  int _generationToken = 0;
  bool _isGenerating = false;

  String? _generatedData;
  bool? _generatedIsDark;
  Color? _generatedTextColor;
  double? _generatedBaseFontSize;
  Locale? _generatedLocale;

  String? _pendingData;
  bool? _pendingIsDark;
  Color? _pendingTextColor;
  double? _pendingBaseFontSize;
  Locale? _pendingLocale;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleGenerationIfNeeded();
  }

  @override
  void didUpdateWidget(SelectableMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data &&
        oldWidget.isDark == widget.isDark &&
        oldWidget.textColor == widget.textColor &&
        oldWidget.baseFontSize == widget.baseFontSize &&
        oldWidget.renderMode == widget.renderMode) {
      return;
    }
    _scheduleGenerationIfNeeded();
  }

  bool _sameLocale(Locale? left, Locale? right) {
    return left?.languageCode == right?.languageCode &&
        left?.scriptCode == right?.scriptCode &&
        left?.countryCode == right?.countryCode;
  }

  bool _matchesGeneratedInput(Locale? locale) {
    return _generatedData == widget.data &&
        _generatedIsDark == widget.isDark &&
        _generatedTextColor == widget.textColor &&
        _generatedBaseFontSize == widget.baseFontSize &&
        _sameLocale(_generatedLocale, locale);
  }

  bool _matchesPendingInput(Locale? locale) {
    return _pendingData == widget.data &&
        _pendingIsDark == widget.isDark &&
        _pendingTextColor == widget.textColor &&
        _pendingBaseFontSize == widget.baseFontSize &&
        _sameLocale(_pendingLocale, locale);
  }

  void _cancelPendingGeneration() {
    _generationToken++;
    _pendingData = null;
    _pendingIsDark = null;
    _pendingTextColor = null;
    _pendingBaseFontSize = null;
    _pendingLocale = null;
    _isGenerating = false;
  }

  void _scheduleGenerationIfNeeded() {
    if (widget.renderMode != SelectableMarkdownRenderMode.markdown) {
      _cancelPendingGeneration();
      return;
    }

    final locale = Localizations.maybeLocaleOf(context);
    if (_matchesGeneratedInput(locale) || _matchesPendingInput(locale)) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final data = widget.data;
    final isDark = widget.isDark;
    final textColor = widget.textColor;
    final baseFontSize = widget.baseFontSize;
    final footnotesTitle = l10n?.footnotes ?? 'Footnotes';
    final generationToken = ++_generationToken;

    _pendingData = data;
    _pendingIsDark = isDark;
    _pendingTextColor = textColor;
    _pendingBaseFontSize = baseFontSize;
    _pendingLocale = locale;
    _isGenerating = true;

    Future<void>(() {
      if (!mounted ||
          generationToken != _generationToken ||
          widget.renderMode != SelectableMarkdownRenderMode.markdown) {
        return;
      }

      final generator = MarkdownGenerator(
        isDark: isDark,
        textColor: textColor,
        baseFontSize: baseFontSize,
        footnotesTitle: footnotesTitle,
        undefinedFootnoteText: (id) =>
            l10n?.undefinedFootnote(id) ?? 'Undefined footnote: $id',
      );
      final children = generator.generate(data);

      if (!mounted ||
          generationToken != _generationToken ||
          widget.renderMode != SelectableMarkdownRenderMode.markdown) {
        return;
      }

      setState(() {
        _children = children;
        _generatedData = data;
        _generatedIsDark = isDark;
        _generatedTextColor = textColor;
        _generatedBaseFontSize = baseFontSize;
        _generatedLocale = locale;
        _pendingData = null;
        _pendingIsDark = null;
        _pendingTextColor = null;
        _pendingBaseFontSize = null;
        _pendingLocale = null;
        _isGenerating = false;
      });
    });
  }

  Widget _buildPlainTextPreview() {
    final previewText =
        MarkdownGenerator.buildStreamingPreviewText(widget.data);
    if (previewText.isEmpty) {
      return const SizedBox.shrink();
    }
    return AuroraSelectableText(
      previewText,
      useSelectionArea: widget.useSelectionArea,
      style: TextStyle(
        color: widget.textColor,
        fontSize: widget.baseFontSize,
        height: 1.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.renderMode == SelectableMarkdownRenderMode.plainTextPreview) {
      return _buildPlainTextPreview();
    }

    final locale = Localizations.maybeLocaleOf(context);
    final isCurrentMarkdown = !_isGenerating && _matchesGeneratedInput(locale);
    if (!isCurrentMarkdown) {
      return _buildPlainTextPreview();
    }

    if (_children.isEmpty) {
      return const SizedBox.shrink();
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _children,
    );
    if (!widget.useSelectionArea) {
      return content;
    }

    return AuroraSelectionArea(child: content);
  }
}
