import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Custom code block builder that adds a copy button to code blocks
class CodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDarkMode;

  CodeBlockBuilder({required this.isDarkMode});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Extract code content
    String codeContent = element.textContent;
    
    // Try to extract language from info string (e.g., ```python)
    String? language;
    if (element.attributes['class'] != null) {
      final className = element.attributes['class']!;
      if (className.startsWith('language-')) {
        language = className.substring('language-'.length);
      }
    }

    return _CodeBlockWithCopyButton(
      code: codeContent,
      language: language,
      isDarkMode: isDarkMode,
    );
  }
}

class _CodeBlockWithCopyButton extends StatefulWidget {
  final String code;
  final String? language;
  final bool isDarkMode;

  const _CodeBlockWithCopyButton({
    required this.code,
    this.language,
    required this.isDarkMode,
  });

  @override
  State<_CodeBlockWithCopyButton> createState() => _CodeBlockWithCopyButtonState();
}

class _CodeBlockWithCopyButtonState extends State<_CodeBlockWithCopyButton> {
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
    final backgroundColor = widget.isDarkMode
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF5F5F5);
    final borderColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.1);
    final textColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.85);
    final headerColor = widget.isDarkMode
        ? const Color(0xFF2D2D2D)
        : const Color(0xFFE8E8E8);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language and copy button
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
                // Language label
                Text(
                  widget.language ?? 'code',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                    fontFamily: 'monospace',
                  ),
                ),
                // Copy button - simplified to avoid GlobalKey issues
                GestureDetector(
                  onTap: _copyToClipboard,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
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
          // Code content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                widget.code.trimRight(),
                style: TextStyle(
                  fontSize: Platform.isWindows ? 13 : 12,
                  fontFamily: 'monospace',
                  color: textColor,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
