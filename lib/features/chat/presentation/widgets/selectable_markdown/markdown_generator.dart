import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';

/// Generates a list of widgets from markdown text.
/// Continuous inline/block text is merged into SelectableText.rich,
/// while code blocks, tables, and images break the flow.
import 'package:flutter_math_fork/flutter_math.dart';

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
    final preprocessedText = _preprocessMarkdown(markdownText);
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      encodeHtml: false,
      blockSyntaxes: [
        const LatexBlockSyntax(),
        const FootnoteDefinitionSyntax(), // Added footnote definition support
        md.HtmlBlockSyntax(), // Explicitly include HTML block syntax
      ],
      inlineSyntaxes: [
        GeneralBoldSyntax(), // General bold syntax for edge cases
        CjkBoldSyntax(),
        CjkSuffixBoldSyntax(),
        LatexInlineSyntax(),
        FootnoteReferenceSyntax(), // Added footnote reference support
        md.InlineHtmlSyntax(), // Explicitly include inline HTML syntax
      ],
    );
    // Track footnotes for the document
    final footnoteDefinitions = <String, md.Node>{};
    final footnoteIndices = <String, int>{};
    int nextFootnoteIndex = 1;

    final nodes = document.parseLines(preprocessedText.split('\n'));

    // First pass: extract footnote definitions and map reference keys to indices
    final List<md.Node> filteredNodes = [];
    for (final node in nodes) {
      if (node is md.Element && node.tag == 'footnote_def') {
        final id = node.attributes['id'] ?? '';
        if (id.isNotEmpty) {
          footnoteDefinitions[id] = node;
        }
      } else {
        filteredNodes.add(node);
      }
    }

    final context = GeneratorContext(
      footnoteIndices: footnoteIndices,
      nextFootnoteIndex: () => nextFootnoteIndex++,
    );

    final widgets = _generateWidgets(filteredNodes, context);

    // Append footnotes section if any references were found
    if (footnoteIndices.isNotEmpty) {
      widgets
          .addAll(_buildFootnotesSection(footnoteIndices, footnoteDefinitions));
    }

    return widgets;
  }

  List<Widget> _generateWidgets(List<md.Node> nodes, GeneratorContext context) {
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
      // Also trim single newlines at the very end
      if (currentSpans.isNotEmpty &&
          currentSpans.last is TextSpan &&
          (currentSpans.last as TextSpan).text == '\n') {
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
      if (node is md.Element && _isHardBarrier(node.tag)) {
        flushSpans();
        widgets.add(_buildBarrierWidget(node, context, widgetIndex++));
      } else {
        final spans = _visit(node, context);

        // Remove trailing newline from the block's content itself
        if (spans.isNotEmpty) {
          if (spans.last is TextSpan && (spans.last as TextSpan).text == '\n') {
            spans.removeLast();
          }
        }

        currentSpans.addAll(spans);

        // Add block separation if needed
        if (_isBlockElement(node is md.Element ? node.tag : '')) {
          if (i < nodes.length - 1) {
            currentSpans.add(const TextSpan(text: '\n\n'));
          }
        } else {
          currentSpans.add(const TextSpan(text: '\n'));
        }
      }
    }

    flushSpans();
    return widgets;
  }

  List<Widget> _buildFootnotesSection(
    Map<String, int> footnoteIndices,
    Map<String, md.Node> footnoteDefinitions,
  ) {
    final List<InlineSpan> footnoteSpans = [
      const TextSpan(text: '\n'),
      TextSpan(
        text: '脚注',
        style: TextStyle(
          fontSize: baseFontSize * 0.9,
          fontWeight: FontWeight.bold,
          color: textColor.withValues(alpha: 0.7),
        ),
      ),
      const TextSpan(text: '\n'),
    ];

    // Sort by index to maintain appearance order
    final sortedIds = footnoteIndices.keys.toList()
      ..sort((a, b) => footnoteIndices[a]!.compareTo(footnoteIndices[b]!));

    final context = GeneratorContext(
      footnoteIndices: footnoteIndices,
      nextFootnoteIndex: () => 0, // Not used here
    );

    for (final id in sortedIds) {
      final index = footnoteIndices[id]!;
      final defNode = footnoteDefinitions[id];

      footnoteSpans.add(TextSpan(
        text: '[$index] ',
        style: TextStyle(
          fontSize: baseFontSize * 0.85,
          fontWeight: FontWeight.bold,
          color: textColor.withValues(alpha: 0.6),
        ),
      ));

      if (defNode != null && defNode is md.Element) {
        final defSpans = _visit(
            defNode,
            context.copyWith(
              currentStyle: TextStyle(
                fontSize: baseFontSize * 0.85,
                color: textColor.withValues(alpha: 0.8),
              ),
            ));
        footnoteSpans.addAll(defSpans);
      } else {
        footnoteSpans.add(TextSpan(
          text: '未定义脚注: $id',
          style: TextStyle(
            fontSize: baseFontSize * 0.85,
            fontStyle: FontStyle.italic,
            color: textColor.withValues(alpha: 0.5),
          ),
        ));
      }
      footnoteSpans.add(const TextSpan(text: '\n'));
    }

    return [
      SelectionArea(
        child: Text.rich(
          TextSpan(children: footnoteSpans),
          style: TextStyle(
            color: textColor,
            fontSize: baseFontSize,
            height: 1.5,
          ),
        ),
      )
    ];
  }

  /// Preprocess markdown to enforce hard line breaks for single newlines,
  /// except inside code blocks.
  String _preprocessMarkdown(String text) {
    // Normalize newlines to ensure consistent processing regardless of platform (CRLF -> LF).
    // This prevents issues where 'blank' lines containing only \r are treated as content,
    // breaking block termination (e.g., HTML blocks).
    text = text.replaceAll(RegExp(r'\r\n?'), '\n');

    final StringBuffer buffer = StringBuffer();
    final lines = text.split('\n');

    _FenceInfo? openFence;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final hasNewlineAfter = i < lines.length - 1;

      if (openFence != null) {
        buffer.write(line);
        if (hasNewlineAfter) buffer.write('\n');

        if (_isClosingFenceLine(line, openFence)) {
          openFence = null;
        }
        continue;
      }

      final fence = _matchOpeningFenceLine(line);
      if (fence != null) {
        openFence = fence;
        buffer.write(line);
        if (hasNewlineAfter) buffer.write('\n');
        continue;
      }

      if (!hasNewlineAfter) {
        buffer.write(line);
        continue;
      }

      if (_shouldAddHardLineBreak(line)) {
        buffer.write('$line  \n');
      } else {
        buffer.write('$line\n');
      }
    }

    return buffer.toString();
  }

  /// Strips leading blockquote markers (`> `) for parsing heuristics.
  /// This is used only for detection (list markers / fences), not for output.
  _BlockQuoteStripResult _stripBlockQuotePrefixForCheck(
    String line, {
    int? maxMarkers,
  }) {
    var s = line.trimLeft();
    var markerCount = 0;
    var i = 0;

    while (i < s.length &&
        s[i] == '>' &&
        (maxMarkers == null || markerCount < maxMarkers)) {
      markerCount++;
      i++; // consume '>'
      if (i < s.length && s[i] == ' ') i++; // optional space

      // Support nested blockquotes like `> > foo` without eating content indentation.
      var peek = i;
      while (peek < s.length && (s[peek] == ' ' || s[peek] == '\t')) {
        peek++;
      }
      if (peek < s.length &&
          s[peek] == '>' &&
          (maxMarkers == null || markerCount < maxMarkers)) {
        i = peek;
        continue;
      }

      break;
    }

    return _BlockQuoteStripResult(
      content: s.substring(i),
      blockQuoteLevel: markerCount,
    );
  }

  _FenceInfo? _matchOpeningFenceLine(String line) {
    final stripped = _stripBlockQuotePrefixForCheck(line);
    final content = stripped.content;
    var i = 0;
    while (i < content.length &&
        (content.codeUnitAt(i) == 0x20 || content.codeUnitAt(i) == 0x09)) {
      i++;
    }
    if (i >= content.length) return null;

    final first = content[i];
    if (first != '`' && first != '~') return null;

    var run = 0;
    while (i + run < content.length && content[i + run] == first) {
      run++;
    }
    if (run < 3) return null;

    return _FenceInfo(
      markerChar: first,
      markerLength: run,
      blockQuoteLevel: stripped.blockQuoteLevel,
    );
  }

  bool _isClosingFenceLine(String line, _FenceInfo openFence) {
    final content = openFence.blockQuoteLevel > 0
        ? _stripBlockQuotePrefixForCheck(line, maxMarkers: openFence.blockQuoteLevel)
            .content
        : line;
    var i = 0;
    while (i < content.length &&
        (content.codeUnitAt(i) == 0x20 || content.codeUnitAt(i) == 0x09)) {
      i++;
    }
    if (i >= content.length) return false;
    if (content[i] != openFence.markerChar) return false;

    var run = 0;
    while (i + run < content.length && content[i + run] == openFence.markerChar) {
      run++;
    }
    if (run < openFence.markerLength) return false;

    for (var j = i + run; j < content.length; j++) {
      final cu = content.codeUnitAt(j);
      if (cu != 0x20 && cu != 0x09) return false;
    }

    return true;
  }

  bool _shouldAddHardLineBreak(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (line.trimRight().endsWith('  ')) return false;

    final content = _stripBlockQuotePrefixForCheck(line).content;
    final contentTrimmed = content.trim();

    final isHtmlTag = contentTrimmed.startsWith('<') &&
        (contentTrimmed.endsWith('>') || !contentTrimmed.contains(' '));
    final isListMarker =
        RegExp(r'^(\s*)([*+-]|\d+\.)\s').hasMatch(content);

    return !isHtmlTag && !isListMarker;
  }

  bool _isHardBarrier(String tag) {
    return tag == 'pre' ||
        tag == 'table' ||
        tag == 'img' ||
        tag == 'hr' ||
        tag == 'latex_block' ||
        tag == 'blockquote';
  }

  bool _isBlockElement(String tag) {
    return [
      'p',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'blockquote',
      'ul',
      'ol',
      'ol',
      'div',
      'span',
      'section',
      'header',
      'footer',
      'article',
      'aside',
      'nav',
      'main',
      'figure',
      'figcaption'
    ].contains(tag);
  }

  /// The main recursive visitor
  List<InlineSpan> _visit(md.Node node, GeneratorContext context) {
    if (node is md.Text) {
      // Check if text is just a newline or empty?
      // Preprocessing usually handles line breaks.
      return [TextSpan(text: node.text, style: context.currentStyle)];
    }

    if (node is md.Element) {
      final tag = node.tag;

      if (_isHardBarrier(tag)) {
        final barrierWidget = _buildBarrierWidget(node, context);

        // Hard barriers embedded inside list items need explicit line breaks,
        // otherwise they can end up laid out "inline" right after the marker.
        if (context.indentLevel > 0) {
          final baseIndent =
              context.indentLevel > 1 ? ('    ' * (context.indentLevel - 1)) : '';
          final markerIndent = context.listType == 'ol'
              ? ('${context.listIndex + 1}. '.length)
              : 2;
          final indentText = '$baseIndent${' ' * markerIndent}';

          return [
            const TextSpan(text: '\n'),
            if (indentText.isNotEmpty) TextSpan(text: indentText),
            WidgetSpan(
              child: barrierWidget,
              alignment: PlaceholderAlignment.middle,
            ),
            const TextSpan(text: '\n'),
          ];
        }

        return [
          WidgetSpan(
            child: barrierWidget,
            alignment: PlaceholderAlignment.middle,
          ),
        ];
      }

      // --- Block Elements ---

      if (tag == 'ul' || tag == 'ol') {
        final List<InlineSpan> spans = [];
        // If this list is nested (indent > 0), ensure we start on a new line?
        // Handled by parent li processing generally.

        // For ordered lists, respect the 'start' attribute if present
        int startIndex = 0;
        if (tag == 'ol') {
          final startAttr = node.attributes['start'];
          if (startAttr != null) {
            startIndex =
                (int.tryParse(startAttr) ?? 1) - 1; // Convert to 0-indexed
          }
        }

        int listIndex = startIndex;
        for (final child in node.children ?? []) {
          if (child is md.Element && child.tag == 'li') {
            // Pass context to li
            final childContext = context.copyWith(
              indentLevel: context.indentLevel + 1,
              listType: tag,
              listIndex: listIndex,
            );
            spans.addAll(_processListItem(child, childContext));
            listIndex++;
          } else {
            // Non-li child in list? Just visit.
            spans.addAll(_visit(child, context));
          }
        }
        return spans;
      }

      // --- Inline / formatting Elements ---

      // Calculate style for this element
      TextStyle? style = context.currentStyle;

      switch (tag) {
        case 'h1':
          style = _headingStyle(1);
          break;
        case 'h2':
          style = _headingStyle(2);
          break;
        case 'h3':
          style = _headingStyle(3);
          break;
        case 'h4':
          style = _headingStyle(4);
          break;
        case 'h5':
          style = _headingStyle(5);
          break;
        case 'h6':
          style = _headingStyle(6);
          break;
        case 'strong':
        case 'b':
          style = (style ?? const TextStyle())
              .copyWith(fontWeight: FontWeight.bold);
          break;
        case 'em':
        case 'i':
          // Use bold styling (same as **text**)
          style = (style ?? const TextStyle())
              .copyWith(fontWeight: FontWeight.bold);
          break;
        case 'del':
        case 's':
          style = (style ?? const TextStyle())
              .copyWith(decoration: TextDecoration.lineThrough);
          break;
        case 'a':
          style = (style ?? const TextStyle())
              .copyWith(decoration: TextDecoration.underline);
          break;
        case 'code':
          // We use WidgetSpan now for rounded corners, handled below
          break;
      }

      // Handle 'code' explicitly to use WidgetSpan (TextSpan doesn't support border radius)
      if (tag == 'code') {
        final codeText = node.textContent;
        return [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                codeText,
                style: (context.currentStyle ?? const TextStyle()).copyWith(
                  fontFamily: 'monospace',
                  color: textColor, // Ensure text is visible
                  fontSize: (baseFontSize - 1), // Slightly smaller for code
                ),
              ),
            ),
          )
        ];
      }

      if (tag == 'latex_inline') {
        final latex = node.textContent;
        final isBold = context.currentStyle?.fontWeight == FontWeight.bold;
        final displayLatex = isBold ? '\\boldsymbol{$latex}' : latex;

        // Use WidgetSpan for inline math
        return [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Render the math
                Math.tex(
                  displayLatex,
                  textStyle:
                      (context.currentStyle ?? const TextStyle()).copyWith(
                    // Ensure color is respected if not overridden by latex
                    color: textColor,
                    fontSize: baseFontSize,
                  ),
                ),
                // Invisible text overlay for selection/copying
                // We use a small font size text that contains the source.
                // Positioned.fill ensures it covers the area for selection hit-testing.
                Semantics(
                  label: latex,
                  child: Opacity(
                    opacity: 0.0,
                    child: Text(
                      latex,
                      style: const TextStyle(
                          color: Colors.transparent, fontSize: 1),
                    ),
                  ),
                ),
              ],
            ),
          )
        ];
      }

      final childContext = context.copyWith(currentStyle: style);
      final List<InlineSpan> childrenSpans = [];

      for (final child in node.children ?? []) {
        childrenSpans.addAll(_visit(child, childContext));
      }

      // Post-process specific tags
      if (tag == 'footnote_ref') {
        final id = node.attributes['id'] ?? '';
        if (id.isEmpty) return [];

        // Assign index if not already assigned
        if (!context.footnoteIndices.containsKey(id)) {
          context.footnoteIndices[id] = context.nextFootnoteIndex();
        }
        final index = context.footnoteIndices[id]!;

        return [
          TextSpan(
            text: '[$index]',
            style: (context.currentStyle ?? const TextStyle()).copyWith(
              fontSize: (context.currentStyle?.fontSize ?? baseFontSize) * 0.75,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
            ),
          )
        ];
      } else if (tag == 'a') {
        final href = node.attributes['href'] ?? '';
        // Check if link text is a citation number (pure digits)
        final linkText = node.textContent.trim();
        final isCitationNumber = RegExp(r'^\d+$').hasMatch(linkText);

        final tapRecognizer = TapGestureRecognizer()
          ..onTap = () async {
            if (href.isEmpty) return;
            var urlStr = href;
            // Basic URL normalization for common cases
            if (!urlStr.contains('://') && !urlStr.startsWith('mailto:')) {
              urlStr = 'https://$urlStr';
            }
            final uri = Uri.tryParse(urlStr);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          };

        if (isCitationNumber) {
          // Wrap citation numbers in brackets: "5" -> "[5]"
          // Use text directly for proper tap recognition
          return [
            TextSpan(
              text: '[$linkText]',
              style: style?.copyWith(
                fontSize:
                    (style.fontSize ?? baseFontSize) * 0.75, // Slightly smaller
                decoration: TextDecoration.none, // Remove underline
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF64B5F6)
                    : const Color(0xFF1976D2), // Better blue
                // Lift it slightly visually (not actual superscript but helps)
                height: 1.0,
              ),
              recognizer: tapRecognizer,
              mouseCursor: SystemMouseCursors.click,
            ),
          ];
        } else {
          // Use text property instead of children for normal links
          // This ensures the recognizer correctly captures hits within SelectionArea
          return [
            TextSpan(
              text: node.textContent,
              style: style,
              recognizer: tapRecognizer,
              mouseCursor: SystemMouseCursors.click,
            )
          ];
        }
      } else if (tag == 'p') {
        // Return children. Top level loop adds spacing.
        // If nested deeply, might need check.
        return childrenSpans;
      } else if (tag == 'br') {
        return [const TextSpan(text: '\n')];
      } else if (tag.startsWith('h')) {
        // Headings usually block
        return [
          TextSpan(children: childrenSpans),
        ];
        // Note: we might want explicit \n here if not handled at top level?
      }

      // Default: return styled children
      return [TextSpan(children: childrenSpans, style: style)];
    }

    return [];
  }

  List<InlineSpan> _processListItem(md.Element li, GeneratorContext context) {
    final List<InlineSpan> spans = [];

    // 1. Newline
    // Only add newline if it's NOT the first item of a top-level list.
    // Top-level blocks are separated by \n\n in the main loop.
    // Nested items always need a newline to separate from parent text.
    if (context.indentLevel > 1 || context.listIndex > 0) {
      spans.add(const TextSpan(text: '\n'));
    }

    // 2. Indentation
    // Level 0 is inside the first ul/ol (so indentation 1 conceptually?)
    // User wants hierarchy.
    // context.indentLevel starts at 1 for the first level typically.
    if (context.indentLevel > 1) {
      spans.add(TextSpan(text: '    ' * (context.indentLevel - 1)));
    }

    // 3. Marker
    String marker;
    if (context.listType == 'ol') {
      marker = '${context.listIndex + 1}. ';
    } else {
      // Vary bullet based on indentation level
      // Level 1: • (Disc)
      // Level 2: ◦ (Circle)
      // Level 3: ▪ (Square)
      final int styleIndex = (context.indentLevel - 1) % 3;
      switch (styleIndex) {
        case 1:
          marker = '◦ ';
          break;
        case 2:
          marker = '▪ ';
          break;
        case 0:
        default:
          marker = '• ';
          break;
      }
    }

    spans.add(TextSpan(
      text: marker,
      style: (context.currentStyle ?? const TextStyle()).copyWith(
        fontFamily: 'monospace',
      ),
    ));

    // 4. Content
    // Recursively visit children.
    // IMPORTANT: Children might include nested lists (ul/ol).
    // Nested lists will trigger _visit('ul') -> calls _processListItem with increased indent.
    for (final child in li.children ?? []) {
      spans.addAll(_visit(child, context));
    }

    return spans;
  }

  TextStyle _headingStyle(int level) {
    double size = baseFontSize;
    switch (level) {
      case 1:
        size *= 1.5;
        break;
      case 2:
        size *= 1.4;
        break;
      case 3:
        size *= 1.3;
        break;
      case 4:
        size *= 1.2;
        break;
      case 5:
        size *= 1.1;
        break;
      case 6:
        size *= 1.0;
        break;
    }
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }

  // ... _buildBarrierWidget methods (copy from original) ...
  Widget _buildBarrierWidget(md.Element element, GeneratorContext context,
      [int index = 0]) {
    switch (element.tag) {
      case 'pre':
        return _buildCodeBlock(element, index);
      case 'table':
        return _buildTable(element, index);
      case 'img':
        return _buildImage(element, index);
      case 'hr':
        return const Divider(height: 24, thickness: 1);
      case 'latex_block':
        return _buildLatex(element, index);
      case 'blockquote':
        return _buildBlockquote(element, context, index);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBlockquote(
      md.Element element, GeneratorContext context, int index) {
    final children = _generateWidgets(element.children ?? [], context);

    return Container(
      key: ValueKey('blockquote_$index'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildLatex(md.Element element, int index) {
    final latex = element.textContent;
    return _LatexBlock(
      key: ValueKey('latex_$index'),
      latex: latex,
      textColor: textColor,
      baseFontSize: baseFontSize,
    );
  }

  Widget _buildCodeBlock(md.Element element, int index) {
    String code = '';
    String? language;

    if (element.children != null && element.children!.isNotEmpty) {
      final codeElement = element.children!.first;
      if (codeElement is md.Element && codeElement.tag == 'code') {
        code = codeElement.textContent;
        language =
            codeElement.attributes['class']?.replaceFirst('language-', '');
      } else {
        code = element.textContent;
      }
    } else {
      code = element.textContent;
    }

    if (code.endsWith('\n')) {
      code = code.substring(0, code.length - 1);
    }

    return _ExpandableCodeBlock(
      key: ValueKey('code_$index'),
      code: code,
      language: language,
      isDark: isDark,
      textColor: textColor,
    );
  }

  Widget _buildTable(md.Element element, int index) {
    final List<TableRow> rows = [];
    final Map<int, int> colMaxLengths = {};
    int colCount = 0;

    // Helper to process rows and gather stats
    void processRow(md.Element row, {required bool isHeader}) {
      int cellIndex = 0;
      final List<Widget> cells = [];
      for (final cellNode in row.children ?? []) {
        if (cellNode is md.Element &&
            (cellNode.tag == 'th' || cellNode.tag == 'td')) {
          final text = cellNode.textContent;
          final len = text.length;
          final currentMax = colMaxLengths[cellIndex] ?? 0;
          colMaxLengths[cellIndex] = currentMax < len ? len : currentMax;

          cells.add(
            Padding(
              padding: const EdgeInsets.all(8),
              child: SelectionArea(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: baseFontSize,
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
          cellIndex++;
        }
      }
      if (cellIndex > colCount) colCount = cellIndex;

      rows.add(TableRow(
        decoration: isHeader
            ? BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
              )
            : null,
        children: cells,
      ));
    }

    for (final child in element.children ?? []) {
      if (child is md.Element) {
        if (child.tag == 'thead' || child.tag == 'tbody') {
          for (final rowNode in child.children ?? []) {
            if (rowNode is md.Element && rowNode.tag == 'tr') {
              processRow(rowNode, isHeader: child.tag == 'thead');
            }
          }
        } else if (child.tag == 'tr') {
          processRow(child, isHeader: false);
        }
      }
    }

    // Calculate column widths
    // We use FlexColumnWidth based on max character length.
    // Minimum flex is 1. We might want to cap the ratio or use a heuristic.
    // E.g. Header keys are usually short (~10), Content is long (~100).
    // Ratio 1:10.
    final Map<int, TableColumnWidth> columnWidths = {};
    for (int i = 0; i < colCount; i++) {
      // Estimate width:
      // Chinese characters are visual wide, but length is 1.
      // We can just use raw length as a rough proxy.
      // Add a base buffer of 5 to avoid crushing very short columns too much.
      int length = colMaxLengths[i] ?? 0;
      double flex = (length + 5).toDouble();
      columnWidths[i] = FlexColumnWidth(flex);
    }

    // Fallback if empty
    if (columnWidths.isEmpty && colCount > 0) {
      for (int i = 0; i < colCount; i++) {
        columnWidths[i] = const FlexColumnWidth();
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
        columnWidths: columnWidths,
        defaultColumnWidth: const FlexColumnWidth(),
        children: rows,
      ),
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
}

/// Context passed down during recursive traversal
class GeneratorContext {
  final int indentLevel;
  final String? listType; // 'ul' or 'ol'
  final int listIndex;
  final TextStyle? currentStyle;
  final Map<String, int> footnoteIndices;
  final int Function() nextFootnoteIndex;

  GeneratorContext({
    this.indentLevel = 0,
    this.listType,
    this.listIndex = 0,
    this.currentStyle,
    required this.footnoteIndices,
    required this.nextFootnoteIndex,
  });

  GeneratorContext copyWith({
    int? indentLevel,
    String? listType,
    int? listIndex,
    TextStyle? currentStyle,
    Map<String, int>? footnoteIndices,
    int Function()? nextFootnoteIndex,
  }) {
    return GeneratorContext(
      indentLevel: indentLevel ?? this.indentLevel,
      listType: listType ?? this.listType,
      listIndex: listIndex ?? this.listIndex,
      currentStyle: currentStyle ?? this.currentStyle,
      footnoteIndices: footnoteIndices ?? this.footnoteIndices,
      nextFootnoteIndex: nextFootnoteIndex ?? this.nextFootnoteIndex,
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  final Color color;

  const _CopyButton({required this.text, required this.color});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _hasCopied = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        if (mounted) {
          setState(() {
            _hasCopied = true;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _hasCopied = false;
              });
            }
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          _hasCopied ? Icons.check : Icons.copy,
          size: 16,
          color: _hasCopied ? Colors.green : widget.color,
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final String code;
  final String? language;
  final Color color;

  const _DownloadButton({
    required this.code,
    this.language,
    required this.color,
  });

  String _getFileExtension(String? language) {
    if (language == null) return '.txt';

    switch (language.toLowerCase()) {
      case 'dart':
        return '.dart';
      case 'python':
      case 'py':
        return '.py';
      case 'javascript':
      case 'js':
        return '.js';
      case 'typescript':
      case 'ts':
        return '.ts';
      case 'html':
        return '.html';
      case 'css':
        return '.css';
      case 'json':
        return '.json';
      case 'xml':
        return '.xml';
      case 'yaml':
      case 'yml':
        return '.yaml';
      case 'c':
        return '.c';
      case 'cpp':
      case 'c++':
        return '.cpp';
      case 'h':
        return '.h';
      case 'hpp':
        return '.hpp';
      case 'java':
        return '.java';
      case 'kotlin':
      case 'kt':
        return '.kt';
      case 'swift':
        return '.swift';
      case 'php':
        return '.php';
      case 'go':
        return '.go';
      case 'rust':
      case 'rs':
        return '.rs';
      case 'ruby':
      case 'rb':
        return '.rb';
      case 'shell':
      case 'sh':
      case 'bash':
        return '.sh';
      case 'powershell':
      case 'ps1':
        return '.ps1';
      case 'sql':
        return '.sql';
      case 'markdown':
      case 'md':
        return '.md';
      default:
        return '.txt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ext = _getFileExtension(language);
        final fileName = 'code$ext';

        try {
          final FileSaveLocation? result = await getSaveLocation(
            suggestedName: fileName,
            acceptedTypeGroups: [
              XTypeGroup(
                label: language ?? 'Text',
                extensions: [ext.replaceAll('.', '')],
              ),
            ],
          );

          if (result != null) {
            final file = File(result.path);
            await file.writeAsString(code);
          }
        } catch (e) {
          debugPrint('Error saving file: $e');
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.download_rounded,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

class _ExpandableCodeBlock extends StatefulWidget {
  final String code;
  final String? language;
  final bool isDark;
  final Color textColor;

  const _ExpandableCodeBlock({
    super.key,
    required this.code,
    this.language,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_ExpandableCodeBlock> createState() => _ExpandableCodeBlockState();
}

class _ExpandableCodeBlockState extends State<_ExpandableCodeBlock> {
  bool _isExpanded = true;
  bool _isHovering = false;
  final GlobalKey _headerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.6)
            : const Color(0xFFF5F5F5).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDark ? Colors.white24 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _headerKey.currentContext != null) {
                  Scrollable.ensureVisible(
                    _headerKey.currentContext!,
                    duration: const Duration(milliseconds: 300),
                    alignment: 0.5,
                    curve: Curves.easeInOut,
                  );
                }
              });
            },
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: Container(
                key: _headerKey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? (_isHovering ? Colors.white24 : Colors.white10)
                      : (_isHovering
                          ? Colors.black.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(7),
                      bottom:
                          _isExpanded ? Radius.zero : const Radius.circular(7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.language ?? 'code',
                        style: TextStyle(
                          color: widget.textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontFamily: 'monospace',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DownloadButton(
                          code: widget.code,
                          language: widget.language,
                          color: widget.textColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        _CopyButton(
                          text: widget.code,
                          color: widget.textColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: widget.textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isExpanded)
            SelectionArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.code,
                  style: TextStyle(
                    color: widget.textColor,
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
}

/// Custom syntax to handle CJK (Chinese/Japanese/Korean) bold rendering issues.
/// Standard markdown parsers often fail to recognize `**` as bold markers when
/// they are directly adjacent to CJK characters (without spaces), especially
/// when followed by punctuation (e.g. `是**“foo”**`).
///
/// This syntax uses a regex to explicitly catch `[CJK Char]**[Content]**` patterns
/// and force them to be parsed as Strong/Bold elements.
class CjkBoldSyntax extends md.InlineSyntax {
  // Regex matches:
  // Group 1: A CJK character (Unified Ideographs 4E00-9FFF), Fullwidth Punctuation (FF00-FFEF),
  //         or CJK Symbols and Punctuation (3000-303F, e.g. 、。).
  //         This ensures we only trigger this specific CJK fix and don't interfere with normal text.
  // Group 2: The content inside the bold markers (Lazy match).
  //         We use a negative lookahead `(?![...])` to ensure the content does NOT start with
  //         punctuation or whitespace. This prevents falsy matches where a confusing closing `**`
  //         (followed by a comma) is mistaken for a new opening `**`.
  CjkBoldSyntax()
      : super(
            r'([\u4e00-\u9fff\u3000-\u303f\uff00-\uffef])\*\*(?![，。、；：？！”’）》\],.\?!\s])(.+?)\*\*');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // 1. Add the preceding character back as a Text node.
    // We consumed it in the regex, so we must restore it.
    parser.addNode(md.Text(match[1]!));

    // 2. Parse the inner content recursively.
    // This ensures that markdown inside the bold tags (like `*italics*`) is still processed.
    final innerContent = match[2]!;
    final innerParser = md.InlineParser(innerContent, parser.document);
    final children = innerParser.parse();

    // 3. Create and add the Strong element.
    final element = md.Element('strong', children);
    parser.addNode(element);

    return true;
  }
}

class _FenceInfo {
  final String markerChar;
  final int markerLength;
  final int blockQuoteLevel;

  _FenceInfo({
    required this.markerChar,
    required this.markerLength,
    required this.blockQuoteLevel,
  });
}

class _BlockQuoteStripResult {
  final String content;
  final int blockQuoteLevel;

  _BlockQuoteStripResult({required this.content, required this.blockQuoteLevel});
}

class LatexBlockSyntax extends md.BlockSyntax {
  const LatexBlockSyntax();

  @override
  RegExp get pattern => RegExp(r'^(\$\$)', multiLine: true);

  @override
  md.Node parse(md.BlockParser parser) {
    // The current line strictly matches the pattern (starts with $$)
    final line = parser.current.content;

    // Check for single line: $$ content $$
    // We want to avoid matching just "$$" as single line empty block if it's meant to be start of multiline.
    if (line.trim().length > 2 && line.trim().endsWith(r'$$')) {
      final content = line.trim().substring(2, line.trim().length - 2);
      parser.advance();
      return md.Element('latex_block', [md.Text(content)]);
    }

    // Multiline
    final childLines = <String>[];
    parser.advance(); // consume opening $$

    while (!parser.isDone) {
      final currentLine = parser.current.content;
      if (currentLine.trim().startsWith(r'$$')) {
        parser.advance(); // consume closing $$
        break;
      }
      childLines.add(currentLine);
      parser.advance();
    }

    return md.Element('latex_block', [md.Text(childLines.join('\n'))]);
  }
}

class LatexInlineSyntax extends md.InlineSyntax {
  // Match single $ but not double $$.
  // Be careful not to match currency like $100.
  // Usually math requires $...$ with no space after first $ and no space before last $.
  // Regex: \$[^$]+\$
  // To avoid matching $100, checking for non-digit might be too aggressive.
  // Standard latex in markdown often uses: (?<!\\)\$((?:\\.|[^\\$])*?)(?<!\\)\$

  LatexInlineSyntax() : super(r'(?<!\\)\$((?:\\.|[^\\$])*?)(?<!\\)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // If the match is empty or just $, ignore?
    // The regex captures the content in group 1.

    final content = match[1]!;
    // Avoid empty
    if (content.trim().isEmpty) return false;

    final element = md.Element('latex_inline', [md.Text(content)]);
    parser.addNode(element);
    return true;
  }
}

/// Custom syntax for footnote references like `[^1]` or `[^label]`.
class FootnoteReferenceSyntax extends md.InlineSyntax {
  FootnoteReferenceSyntax() : super(r'\[\^([^\]]+)\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final id = match[1]!;
    final element = md.Element.empty('footnote_ref');
    element.attributes['id'] = id;
    parser.addNode(element);
    return true;
  }
}

/// Custom syntax for footnote definitions like `[^1]: content`.
/// This is a block syntax as it typically starts at the beginning of a line.
class FootnoteDefinitionSyntax extends md.BlockSyntax {
  const FootnoteDefinitionSyntax();

  @override
  RegExp get pattern => RegExp(r'^\[\^([^\]]+)\]:\s*(.*)$');

  @override
  md.Node? parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match == null) return null;

    final id = match[1]!;
    var content = match[2]!;
    parser.advance();

    // Collect subsequent lines if they are indented
    final childLines = [content];
    while (!parser.isDone &&
        (parser.current.content.startsWith('    ') ||
            parser.current.content.isEmpty)) {
      childLines.add(parser.current.content.replaceFirst(RegExp(r'^    '), ''));
      parser.advance();
    }

    // Parse the content as inline markdown for simplicity in this implementation
    final inlineParser =
        md.InlineParser(childLines.join('\n'), parser.document);
    final element = md.Element('footnote_def', inlineParser.parse());
    element.attributes['id'] = id;
    return element;
  }
}

/// Matches `**content**` when followed immediately by a CJK character or punctuation.
/// This fixes cases where standard markdown fails to recognize the closing `**` because
/// the following CJK character is treated as a word character (making `**` left-flanking).
class CjkSuffixBoldSyntax extends md.InlineSyntax {
  CjkSuffixBoldSyntax()
      : super(r'\*\*(.+?)\*\*(?=[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef])');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final innerContent = match[1]!;
    final innerParser = md.InlineParser(innerContent, parser.document);
    final children = innerParser.parse();
    final element = md.Element('strong', children);
    parser.addNode(element);
    return true;
  }
}

/// General bold syntax that handles edge cases where standard markdown
/// and CJK-specific syntaxes fail to match.
/// This matches `**content**` where content does not start or end with whitespace.
class GeneralBoldSyntax extends md.InlineSyntax {
  GeneralBoldSyntax() : super(r'\*\*(?!\s)(.+?)(?<!\s)\*\*');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final innerContent = match[1]!;
    // Don't match if it looks like it should be handled by other syntaxes
    // or if content is empty
    if (innerContent.trim().isEmpty) return false;

    final innerParser = md.InlineParser(innerContent, parser.document);
    final children = innerParser.parse();
    final element = md.Element('strong', children);
    parser.addNode(element);
    return true;
  }
}

class _LatexBlock extends StatefulWidget {
  final String latex;
  final Color textColor;
  final double baseFontSize;

  const _LatexBlock({
    super.key,
    required this.latex,
    required this.textColor,
    required this.baseFontSize,
  });

  @override
  State<_LatexBlock> createState() => _LatexBlockState();
}

class _LatexBlockState extends State<_LatexBlock> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: constraints.maxWidth,
          alignment: Alignment.center,
          child: Scrollbar(
            controller: _controller,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 4, bottom: 16),
              child: Math.tex(
                widget.latex,
                textStyle: TextStyle(
                  fontSize: widget.baseFontSize + 2,
                  color: widget.textColor,
                ),
                onErrorFallback: (error) {
                  return Text(
                    widget.latex,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.baseFontSize,
                      color: widget.textColor,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
