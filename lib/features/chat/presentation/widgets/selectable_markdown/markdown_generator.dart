import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import 'dart:convert';

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
    final preprocessedText = _preprocessMarkdown(markdownText);
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      encodeHtml: false,
      inlineSyntaxes: [CjkBoldSyntax()],
    );
    final nodes = document.parseLines(preprocessedText.split('\n'));

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
        widgets.add(_buildBarrierWidget(node, widgetIndex++));
      } else {
        // Use the new context-aware traversal
        final spans = _visit(node, GeneratorContext());

        // Remove trailing newline from the block's content itself
        // (This handles the case where preprocessing added a hard break at the end of a block)
        if (spans.isNotEmpty) {
          if (spans.last is TextSpan && (spans.last as TextSpan).text == '\n') {
            spans.removeLast();
          }
        }

        currentSpans.addAll(spans);

        // Add block separation if needed
        if (_isBlockElement(node is md.Element ? node.tag : '')) {
          // Ensure double newline after top-level blocks for spacing,
          // but check if we are not the last node
          if (i < nodes.length - 1) {
            currentSpans.add(const TextSpan(text: '\n\n'));
          }
        } else {
          // For text nodes or others at top level, a single newline is usually implicit from split handling
          // but standard markdown accumulates.
          // We add a newline to simulate line break if it was a distinct line in source.
          currentSpans.add(const TextSpan(text: '\n'));
        }
      }
    }

    flushSpans();
    return widgets;
  }

  /// Preprocess markdown to enforce hard line breaks for single newlines,
  /// except inside code blocks.
  String _preprocessMarkdown(String text) {
    final StringBuffer buffer = StringBuffer();
    final List<String> segments = text.split('```');

    for (int i = 0; i < segments.length; i++) {
      String segment = segments[i];
      if (i % 2 == 0) {
        // Outside code block: replace newlines with double space + newline
        // (Markdown hard break).
        // We avoid replacing newlines that are already followed by spaces or other structure if possible,
        // but broadly replacing \n with "  \n" works for "Chat" style.
        // Also need to be careful not to break list markers.
        // Actually, just replacing \n with "  \n" is risky for lists.
        // BUT, since we are doing custom list rendering, maybe we don't need to force markdown parser to see hard breaks?
        // If we want "text\ntext" to be distinct lines, the parser treats it as one p block "text text".
        // Use "  \n" makes it "text<br>text".

        // We will do a simple pass: Regex remove single newlines?
        // No, let's try a safer approach:
        // Identify lines. If line ends with non-space, add "  ".
        final lines = segment.split('\n');
        for (int j = 0; j < lines.length; j++) {
          String line = lines[j];
          if (line.trim().isNotEmpty && !line.trimRight().endsWith('  ')) {
            buffer.write('$line  \n');
          } else {
            buffer.write('$line\n');
          }
        }
      } else {
        // Inside code block: keep as is, just re-add the backticks we split by
        buffer.write('```$segment```');
      }
    }
    return buffer.toString();
  }

  bool _isHardBarrier(String tag) {
    return tag == 'pre' || tag == 'table' || tag == 'img' || tag == 'hr';
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
      'div'
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

      // --- Block Elements ---

      if (tag == 'ul' || tag == 'ol') {
        final List<InlineSpan> spans = [];
        // If this list is nested (indent > 0), ensure we start on a new line?
        // Handled by parent li processing generally.

        int listIndex = 0;
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



      final childContext = context.copyWith(currentStyle: style);
      final List<InlineSpan> childrenSpans = [];

      for (final child in node.children ?? []) {
        childrenSpans.addAll(_visit(child, childContext));
      }

      // Post-process specific tags
      if (tag == 'a') {
        final href = node.attributes['href'] ?? '';
        // Check if link text is a citation number (pure digits)
        final linkText = node.textContent.trim();
        final isCitationNumber = RegExp(r'^\d+$').hasMatch(linkText);
        
        final tapRecognizer = TapGestureRecognizer()
          ..onTap = () {
            final uri = Uri.tryParse(href);
            if (uri != null) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          };
        
        if (isCitationNumber) {
          // Wrap citation numbers in brackets: "5" -> "[5]"
          // Use text directly for proper tap recognition
          return [
            TextSpan(
              text: '[$linkText]',
              style: style?.copyWith(
                fontSize: (style.fontSize ?? baseFontSize) * 0.75, // Slightly smaller
                decoration: TextDecoration.none, // Remove underline
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2), // Better blue
                // Lift it slightly visually (not actual superscript but helps)
                height: 1.0, 
              ),
              recognizer: tapRecognizer,
            ),
          ];
        } else {
          return [
            TextSpan(
              children: childrenSpans,
              style: style,
              recognizer: tapRecognizer,
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
      } else if (tag == 'blockquote') {
        // Wrap in a visual indicator?
        // Hard to do in TextSpan.
        // We can prefix lines with "> ".
        // But children are flattened.
        // Let's just return children with italic style logic above.
        return childrenSpans;
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
          colMaxLengths[cellIndex] = (colMaxLengths[cellIndex] ?? 0) < len
              ? len
              : colMaxLengths[cellIndex]!;

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
                    ? Colors.white10
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

  GeneratorContext({
    this.indentLevel = 0,
    this.listType,
    this.listIndex = 0,
    this.currentStyle,
  });

  GeneratorContext copyWith({
    int? indentLevel,
    String? listType,
    int? listIndex,
    TextStyle? currentStyle,
  }) {
    return GeneratorContext(
      indentLevel: indentLevel ?? this.indentLevel,
      listType: listType ?? this.listType,
      listIndex: listIndex ?? this.listIndex,
      currentStyle: currentStyle ?? this.currentStyle,
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
      case 'dart': return '.dart';
      case 'python': 
      case 'py': return '.py';
      case 'javascript':
      case 'js': return '.js';
      case 'typescript':
      case 'ts': return '.ts';
      case 'html': return '.html';
      case 'css': return '.css';
      case 'json': return '.json';
      case 'xml': return '.xml';
      case 'yaml':
      case 'yml': return '.yaml';
      case 'c': return '.c';
      case 'cpp':
      case 'c++': return '.cpp';
      case 'h': return '.h';
      case 'hpp': return '.hpp';
      case 'java': return '.java';
      case 'kotlin':
      case 'kt': return '.kt';
      case 'swift': return '.swift';
      case 'php': return '.php';
      case 'go': return '.go';
      case 'rust':
      case 'rs': return '.rs';
      case 'ruby':
      case 'rb': return '.rb';
      case 'shell':
      case 'sh':
      case 'bash': return '.sh';
      case 'powershell':
      case 'ps1': return '.ps1';
      case 'sql': return '.sql';
      case 'markdown':
      case 'md': return '.md';
      default: return '.txt';
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
        color: widget.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  // Group 1: A CJK character (Unified Ideographs 4E00-9FFF) or Fullwidth Punctuation (FF00-FFEF).
  //         This ensures we only trigger this specific CJK fix and don't interfere with normal text.
  // Group 2: The content inside the bold markers (Lazy match).
  //         We use a negative lookahead `(?![...])` to ensure the content does NOT start with
  //         punctuation or whitespace. This prevents falsy matches where a confusing closing `**`
  //         (followed by a comma) is mistaken for a new opening `**`.
  CjkBoldSyntax() : super(r'([\u4e00-\u9fff\uff00-\uffef])\*\*(?![，。、；：？！”’）》\],.\?!\s])(.+?)\*\*');

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
