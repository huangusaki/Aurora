import 'package:aurora/shared/theme/aurora_icons.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aurora/l10n/app_localizations.dart';

class BuildToolOutput extends StatefulWidget {
  final String content;
  const BuildToolOutput({super.key, required this.content});
  @override
  State<BuildToolOutput> createState() => _BuildToolOutputState();
}

class _BuildToolOutputState extends State<BuildToolOutput> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(widget.content);
    } catch (_) {}
    final l10n = AppLocalizations.of(context);
    final theme = fluent.FluentTheme.of(context);
    final results = data != null ? data['results'] as List? : null;
    final count = results?.length ?? 0;
    final engine = data?['engine'] ?? 'Search';

    final stdout = data?['stdout'] as String?;
    final stderr = data?['stderr'] as String?;
    final exitCode = data?['exitCode'] as int?;
    final error = data?['error'] as String?;

    // Handle Shell Tool Output (Terminal Style)
    if (stdout != null || stderr != null || exitCode != null) {
      return _buildTerminalOutput(l10n, theme, stdout, stderr, exitCode);
    }

    // Handle Generic Errors from Skill execution
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(AuroraIcons.error, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Skill Error',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 13, color: theme.typography.body?.color),
            ),
            if (data?['missing_parameters'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Missing: ${(data!['missing_parameters'] as List).join(', ')}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
              ),
            ],
          ],
        ),
      );
    }

    if (count == 0) {
      if (data?.containsKey('message') == true) {
        final message = data!['message'] as String;
        // Don't show "Tool Message:" prefix, just show the content
        // Also ensure it's selectable and wrapped nicely
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
             color: theme.accentColor.withOpacity(0.05),
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: theme.accentColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               GestureDetector(
                 onTap: () => setState(() => _isExpanded = !_isExpanded),
                 behavior: HitTestBehavior.opaque,
                 child: Container(
                   padding: const EdgeInsets.all(12),
                   child: Row(
                     children: [
                       Icon(AuroraIcons.robot, size: 14, color: theme.accentColor),
                       const SizedBox(width: 8),
                        Text(
                          l10n?.agentResponse ?? 'Agent Response',
                          style: TextStyle(
                           fontSize: 11,
                           fontWeight: FontWeight.bold,
                           color: theme.accentColor,
                         ),
                       ),
                       const Spacer(),
                       Icon(
                         _isExpanded
                             ? AuroraIcons.chevronUp
                             : AuroraIcons.chevronDown,
                         size: 10,
                         color: theme.accentColor.withOpacity(0.5),
                       ),
                     ],
                   ),
                 ),
               ),
               if (_isExpanded)
                 Padding(
                   padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                   child: SelectableText(
                     message,
                     style: TextStyle(color: theme.typography.body?.color, fontSize: 13),
                   ),
                 ),
            ],
          ),
        );
      }
      // Provide a fallback for plain string content passed as JSON if applicable
      // Or if the content is NOT json (which build method tries to catch)
      // Actually widget.content is passed. If jsonDecode fails, data is null.
      // If data is null, we should just show the content.
    }
    
    // Fallback for non-JSON content (raw text from Worker)
    if (data == null) {
       return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
             color: theme.accentColor.withOpacity(0.05),
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: theme.accentColor.withOpacity(0.2)),
          ),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               GestureDetector(
                 onTap: () => setState(() => _isExpanded = !_isExpanded),
                 behavior: HitTestBehavior.opaque,
                 child: Container(
                   padding: const EdgeInsets.all(12),
                   child: Row(
                     children: [
                       Icon(AuroraIcons.robot, size: 14, color: theme.accentColor),
                       const SizedBox(width: 8),
                        Text(
                          l10n?.agentOutput ?? 'Agent Output',
                          style: TextStyle(
                           fontSize: 11,
                           fontWeight: FontWeight.bold,
                           color: theme.accentColor,
                         ),
                       ),
                       const Spacer(),
                       Icon(
                         _isExpanded
                             ? AuroraIcons.chevronUp
                             : AuroraIcons.chevronDown,
                         size: 10,
                         color: theme.accentColor.withOpacity(0.5),
                       ),
                     ],
                   ),
                 ),
               ),
               if (_isExpanded)
                 Padding(
                   padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                   child: SelectableText(
                     widget.content,
                     style: TextStyle(color: theme.typography.body?.color, fontSize: 13),
                   ),
                 ),
             ],
          ),
       );
    }
    if (results != null && results.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.resources.controlStrokeColorDefault),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20.0 + (math.min(results.length, 3) - 1) * 12.0,
                        child: Stack(
                          children: List.generate(math.min(results.length, 3),
                              (index) {
                            final url = results[index]['link'] as String? ?? '';
                            Uri? uri;
                            try {
                              uri = Uri.parse(url);
                            } catch (_) {}
                            final domain = uri?.host ?? '';
                            final faviconUrl =
                                'https://www.google.com/s2/favicons?domain=$domain&sz=64';
                            return Positioned(
                              left: index * 12.0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: domain.isNotEmpty
                                      ? Image.network(
                                          faviconUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                  AuroraIcons.globe,
                                                  size: 12,
                                                  color: Colors.grey),
                                        )
                                      : const Icon(fluent.FluentIcons.globe,
                                          size: 12, color: Colors.grey),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n?.citationsCount(count) ?? '$count Citations',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.typography.body?.color?.withOpacity(0.9),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded
                            ? fluent.FluentIcons.chevron_up
                            : fluent.FluentIcons.chevron_down,
                        size: 10,
                        color: theme.typography.caption?.color,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: theme.resources.controlStrokeColorDefault)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: List.generate(results.length, (index) {
                      final item = results[index];
                      final idx = item['index'] ?? (index + 1);
                      return InkWell(
                        onTap: () async {
                          final link = item['link'] as String?;
                          if (link != null && link.isNotEmpty) {
                            final uri = Uri.tryParse(link);
                            if (uri != null) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.accentColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$idx',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item['link'] != null)
                                      Text(
                                        item['link'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              theme.typography.caption?.color,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? AuroraIcons.chevronDown
                      : AuroraIcons.chevronRight,
                  size: 10,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 8),
                Icon(AuroraIcons.search,
                    size: 14, color: theme.accentColor),
                const SizedBox(width: 8),
                Text(
                  l10n?.searchResultsWithEngine(count, engine) ?? '$count Search Results ($engine)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          ...results!.map((r) {
            final title = r['title'] ?? 'No Title';
            final link = r['link'] ?? '';
            final snippet = r['snippet'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: theme.resources.dividerStrokeColorDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  if (link.isNotEmpty)
                    Text(link,
                        style: TextStyle(color: Colors.blue, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(snippet,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              theme.typography.body!.color!.withOpacity(0.8)),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildTerminalOutput(AppLocalizations? l10n, fluent.FluentThemeData theme, String? stdout, String? stderr, int? exitCode) {
    final isError = (exitCode != null && exitCode != 0) || (stderr != null && stderr.isNotEmpty && (stdout == null || stdout.isEmpty));
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Terminal black
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isError ? Colors.red.withOpacity(0.5) : Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terminal Header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isError ? Colors.red.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                borderRadius: _isExpanded 
                    ? const BorderRadius.vertical(top: Radius.circular(8))
                    : BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? AuroraIcons.error : AuroraIcons.terminal,
                    size: 14,
                    color: isError ? Colors.red.shade300 : Colors.green.shade300,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isError 
                        ? (l10n?.terminalError(exitCode ?? 0) ?? 'Terminal Error (Code $exitCode)')
                        : (l10n?.terminalOutput ?? 'Terminal Output'),
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Consolas',
                      color: isError ? Colors.red.shade100 : Colors.grey.shade300,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? fluent.FluentIcons.chevron_up
                        : fluent.FluentIcons.chevron_down,
                    size: 10,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          // Terminal Content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stdout != null && stdout.isNotEmpty)
                    SelectableText(
                      stdout.trim(),
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: Color(0xFFD4D4D4),
                        height: 1.4,
                      ),
                    ),
                  if (stderr != null && stderr.isNotEmpty) ...[
                    if (stdout != null && stdout.isNotEmpty) const SizedBox(height: 8),
                    SelectableText(
                      stderr.trim(),
                      style: TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: Colors.red.shade300,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if ((stdout == null || stdout.isEmpty) && (stderr == null || stderr.isEmpty))
                    Text(
                      l10n?.noOutput ?? '[No output]',
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
