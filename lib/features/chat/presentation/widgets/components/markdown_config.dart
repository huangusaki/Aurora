import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';

/// Creates a MarkdownConfig for rendering markdown content
MarkdownConfig getMarkdownConfig({
  required bool isDark,
  required Color textColor,
}) {
  final baseConfig = isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
  
  final codeWrapper = (Widget child, String code, String language) {
    return CodeWrapperWidget(child: child, code: code, language: language, isDark: isDark);
  };
  
  return baseConfig.copy(configs: [
    PConfig(textStyle: TextStyle(
      fontSize: 14,
      height: 1.5,
      color: textColor,
      fontFamily: Platform.isWindows ? 'Microsoft YaHei' : null,
    )),
    H1Config(style: TextStyle(
      fontSize: Platform.isWindows ? 28 : 20,
      fontWeight: FontWeight.bold,
      height: 1.4,
      color: textColor,
    )),
    H2Config(style: TextStyle(
      fontSize: Platform.isWindows ? 24 : 18,
      fontWeight: FontWeight.bold,
      height: 1.4,
      color: textColor,
    )),
    H3Config(style: TextStyle(
      fontSize: Platform.isWindows ? 20 : 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: textColor,
    )),
    H4Config(style: TextStyle(
      fontSize: Platform.isWindows ? 18 : 15,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: textColor,
    )),
    H5Config(style: TextStyle(
      fontSize: Platform.isWindows ? 16 : 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: textColor,
    )),
    H6Config(style: TextStyle(
      fontSize: Platform.isWindows ? 14 : 13,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: textColor,
    )),
    CodeConfig(style: TextStyle(
      color: isDark ? const Color(0xFFE5C07B) : const Color(0xFF986801),
      fontSize: Platform.isWindows ? 13 : 12,
      fontFamily: Platform.isWindows ? 'Consolas' : 'monospace',
    )),
    PreConfig(
      theme: {},  // Empty theme to avoid italics from syntax highlighting
      wrapper: codeWrapper,
      decoration: const BoxDecoration(),  // No decoration - wrapper provides it
      padding: EdgeInsets.zero,  // No padding - wrapper provides it
      textStyle: TextStyle(
        fontSize: Platform.isWindows ? 13 : 12,
        fontFamily: Platform.isWindows ? 'Consolas' : 'monospace',
        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.85),
        height: 1.5,
        fontStyle: FontStyle.normal,  // Ensure no italics
      ),
    ),
    BlockquoteConfig(textColor: textColor.withOpacity(0.8)),
    TableConfig(
      defaultColumnWidth: const FlexColumnWidth(),
      bodyStyle: TextStyle(
        fontSize: Platform.isWindows ? 14 : 12,
        color: textColor,
      ),
      headerStyle: TextStyle(
        fontSize: Platform.isWindows ? 14 : 12,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
    ListConfig(
      marker: (isOrdered, depth, index) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Text(
            isOrdered ? '${index + 1}.' : '•',
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        );
      },
    ),
  ]);
}

/// Widget that wraps code blocks with a copy button
class CodeWrapperWidget extends StatefulWidget {
  final Widget child;
  final String code;
  final String language;
  final bool isDark;
  
  const CodeWrapperWidget({
    super.key,
    required this.child,
    required this.code,
    required this.language,
    required this.isDark,
  });

  @override
  State<CodeWrapperWidget> createState() => _CodeWrapperWidgetState();
}

class _CodeWrapperWidgetState extends State<CodeWrapperWidget> {
  bool _copied = false;
  
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = widget.isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE8E8E8);
    final textColor = widget.isDark
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.85);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.language.isNotEmpty ? widget.language : 'code',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                    fontFamily: 'monospace',
                  ),
                ),
                GestureDetector(
                  onTap: _copyToClipboard,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _copied ? Icons.check : Icons.copy,
                            size: 14,
                            color: _copied ? Colors.green : textColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _copied ? 'Copied!' : 'Copy',
                            style: TextStyle(
                              fontSize: 11,
                              color: _copied ? Colors.green : textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
