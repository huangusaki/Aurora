import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// Generates a list of widgets from markdown text.
/// Continuous inline/block text is merged into SelectableText.rich,
/// while code blocks, tables, and images break the flow.
class MarkdownGenerator {
  final bool isDark;
  final Color textColor;
  final double baseFontSize;

  MarkdownGenerator({
    required this.isDark,
    required this.textColor,
    this.baseFontSize = 14.0,
  });

  /// Parse markdown and return a list of widgets
  List<Widget> generate(String markdownText) {
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      encodeHtml: false,
    );
    final nodes = document.parseLines(markdownText.split('\n'));

    final List<Widget> widgets = [];
    final List<InlineSpan> currentSpans = [];

    int widgetIndex = 0;

    void flushSpans() {
      // Remove trailing newlines to avoid extra spacing before barriers
      while (currentSpans.isNotEmpty &&
          currentSpans.last is TextSpan &&
          (currentSpans.last as TextSpan).text == '\n\n') {
        currentSpans.removeLast();
      }

      if (currentSpans.isNotEmpty) {
        widgets.add(
          SelectionArea(
            child: Text.rich(
              TextSpan(children: List.from(currentSpans)),
              key: ValueKey('text_${widgetIndex++}'),
              style: TextStyle(
                color: textColor,
                fontSize: baseFontSize,
                height: 1.5,
              ),
            ),
          ),
        );
        currentSpans.clear();
      }
    }

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is md.Element) {
        if (_isHardBarrier(node.tag)) {
          flushSpans();
          widgets.add(_buildBarrierWidget(node, widgetIndex++));
        } else {
          // Accumulate text spans
          final spans = _elementToSpans(node);
          currentSpans.addAll(spans);
          // Add paragraph break after block elements
          if (_isBlockElement(node.tag)) {
            if (node.tag.startsWith('h')) {
              currentSpans.add(const TextSpan(text: '\n'));
            } else if (node.tag == 'p' &&
                i + 1 < nodes.length &&
                nodes[i + 1] is md.Element &&
                ['ul', 'ol'].contains((nodes[i + 1] as md.Element).tag)) {
              // Should be tighter if followed by a list
              currentSpans.add(const TextSpan(text: '\n'));
            } else {
              currentSpans.add(const TextSpan(text: '\n\n'));
            }
          }
        }
      } else if (node is md.Text) {
        currentSpans.add(TextSpan(text: node.text));
      }
    }

    flushSpans();
    return widgets;
  }

  bool _isHardBarrier(String tag) {
    return tag == 'pre' || tag == 'table' || tag == 'img' || tag == 'hr';
  }

  bool _isBlockElement(String tag) {
    return ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'ul', 'ol']
        .contains(tag);
  }

  Widget _buildBarrierWidget(md.Element element, int index) {
    switch (element.tag) {
      case 'pre':
        return _buildCodeBlock(element, index);
      case 'table':
        return _buildTable(element, index);
      case 'img':
        return _buildImage(element, index);
      case 'hr':
        return const Divider(height: 24, thickness: 1);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCodeBlock(md.Element element, int index) {
    String code = '';
    String? language;

    // Extract code content and language
    if (element.children != null && element.children!.isNotEmpty) {
      final codeElement = element.children!.first;
      if (codeElement is md.Element && codeElement.tag == 'code') {
        code = codeElement.textContent;
        language = codeElement.attributes['class']?.replaceFirst('language-', '');
      } else {
        code = element.textContent;
      }
    } else {
      code = element.textContent;
    }

    // Remove trailing newline if present
    if (code.endsWith('\n')) {
      code = code.substring(0, code.length - 1);
    }

    return Container(
      key: ValueKey('code_$index'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language ?? 'code',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy,
                      size: 16,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code content
          SelectionArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                code,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(md.Element element, int index) {
    final List<TableRow> rows = [];

    for (final child in element.children ?? []) {
      if (child is md.Element) {
        if (child.tag == 'thead' || child.tag == 'tbody') {
          for (final rowNode in child.children ?? []) {
            if (rowNode is md.Element && rowNode.tag == 'tr') {
              rows.add(_buildTableRow(rowNode, isHeader: child.tag == 'thead'));
            }
          }
        } else if (child.tag == 'tr') {
          rows.add(_buildTableRow(child, isHeader: false));
        }
      }
    }

    return Container(
      key: ValueKey('table_$index'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        defaultColumnWidth: const FlexColumnWidth(),
        children: rows,
      ),
    );
  }

  TableRow _buildTableRow(md.Element rowElement, {required bool isHeader}) {
    final List<Widget> cells = [];

    for (final cellNode in rowElement.children ?? []) {
      if (cellNode is md.Element && (cellNode.tag == 'th' || cellNode.tag == 'td')) {
        cells.add(
          Padding(
            padding: const EdgeInsets.all(8),
            child: SelectionArea(
              child: Text(
                cellNode.textContent,
                style: TextStyle(
                  color: textColor,
                  fontSize: baseFontSize,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }
    }

    return TableRow(
      decoration: isHeader
          ? BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
            )
          : null,
      children: cells,
    );
  }

  Widget _buildImage(md.Element element, int index) {
    final src = element.attributes['src'] ?? '';
    final alt = element.attributes['alt'] ?? '';

    if (src.isEmpty) {
      return Text('[$alt]', style: TextStyle(color: textColor));
    }

    return Container(
      key: ValueKey('img_$index'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Image.network(
        src,
        errorBuilder: (context, error, stackTrace) {
          return Text('[$alt]', style: TextStyle(color: textColor));
        },
      ),
    );
  }

  /// Convert an element to a list of TextSpans
  List<InlineSpan> _elementToSpans(md.Element element) {
    final List<InlineSpan> spans = [];

    // Handle headers with size
    final headerStyle = _getHeaderStyle(element.tag);

    if (element.children != null) {
      for (final child in element.children!) {
        spans.addAll(_nodeToSpans(child, baseStyle: headerStyle));
      }
    }

    // Add list marker for list items
    if (element.tag == 'li') {
      spans.insert(0, const TextSpan(text: '  •  '));
      spans.add(const TextSpan(text: '\n'));
    }

    return spans;
  }

  TextStyle? _getHeaderStyle(String tag) {
    // User requested "original format" look with less font size variation.
    // Flattening the hierarchy to be mostly bold base size.
    switch (tag) {
      case 'h1':
      case 'h2':
        return TextStyle(
          fontSize: baseFontSize * 1.1,
          fontWeight: FontWeight.bold,
          color: textColor,
        );
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return TextStyle(
          fontSize: baseFontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        );
      default:
        return null;
    }
  }

  List<InlineSpan> _nodeToSpans(md.Node node, {TextStyle? baseStyle}) {
    if (node is md.Text) {
      return [TextSpan(text: node.text, style: baseStyle)];
    }

    if (node is md.Element) {
      final List<InlineSpan> childSpans = [];

      // Process children first
      for (final child in node.children ?? []) {
        childSpans.addAll(_nodeToSpans(child, baseStyle: baseStyle));
      }

      // Apply element-specific styling
      switch (node.tag) {
        case 'strong':
        case 'b':
          return [
            TextSpan(
              children: childSpans,
              style: (baseStyle ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          ];
        case 'em':
        case 'i':
          return [
            TextSpan(
              children: childSpans,
              style: (baseStyle ?? const TextStyle()).copyWith(
                fontStyle: FontStyle.italic,
              ),
            )
          ];
        case 'code':
          // Inline code
          return [
            TextSpan(
              text: node.textContent,
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                color: textColor,
              ),
            )
          ];
        case 'a':
          final href = node.attributes['href'] ?? '';
          return [
            TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  final uri = Uri.tryParse(href);
                  if (uri != null) {
                    launchUrl(uri);
                  }
                },
            )
          ];
        case 'del':
        case 's':
          return [
            TextSpan(
              children: childSpans,
              style: (baseStyle ?? const TextStyle()).copyWith(
                decoration: TextDecoration.lineThrough,
              ),
            )
          ];
        case 'br':
          return [const TextSpan(text: '\n')];
        default:
          return childSpans;
      }
    }

    return [];
  }
}
