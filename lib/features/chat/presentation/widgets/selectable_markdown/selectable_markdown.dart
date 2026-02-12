import 'package:flutter/material.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'markdown_generator.dart';

/// A widget that renders markdown content with native text selection.
/// Uses SelectableText.rich for text blocks and specialized widgets for
/// code blocks, tables, and images.
class SelectableMarkdown extends StatefulWidget {
  final String data;
  final bool isDark;
  final Color textColor;
  final double baseFontSize;

  const SelectableMarkdown({
    super.key,
    required this.data,
    required this.isDark,
    required this.textColor,
    this.baseFontSize = 14.0,
  });

  @override
  State<SelectableMarkdown> createState() => _SelectableMarkdownState();
}

class _SelectableMarkdownState extends State<SelectableMarkdown> {
  late List<Widget> _children;

  @override
  void initState() {
    super.initState();
    _children = const [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _generateChildren();
  }

  @override
  void didUpdateWidget(SelectableMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.isDark != widget.isDark ||
        oldWidget.textColor != widget.textColor ||
        oldWidget.baseFontSize != widget.baseFontSize) {
      _generateChildren();
    }
  }

  void _generateChildren() {
    final l10n = AppLocalizations.of(context);
    final generator = MarkdownGenerator(
      isDark: widget.isDark,
      textColor: widget.textColor,
      baseFontSize: widget.baseFontSize,
      footnotesTitle: l10n?.footnotes ?? 'Footnotes',
      undefinedFootnoteText: (id) =>
          l10n?.undefinedFootnote(id) ?? 'Undefined footnote: $id',
    );
    _children = generator.generate(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    if (_children.isEmpty) {
      return const SizedBox.shrink();
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _children,
      ),
    );
  }
}
