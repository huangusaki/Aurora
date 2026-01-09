import 'dart:convert';
import 'dart:math' as math;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

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
    // Try parse JSON
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(widget.content);
    } catch (_) {}

    final theme = fluent.FluentTheme.of(context);
    final results = data != null ? data['results'] as List? : null;
    final count = results?.length ?? 0;
    final engine = data?['engine'] ?? 'Search';

    if (count == 0) {
      if (data?.containsKey('message') == true) {
         return Text(
           'Search Error: ${data!['message']}', 
           style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 13)
         );
      }
      return const SizedBox.shrink(); // Hide empty
    }

    // Check for search results structure
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Favicon Pile
                      SizedBox(
                        height: 20,
                        width: 20.0 + (math.min(results.length, 3) - 1) * 12.0,
                        child: Stack(
                          children: List.generate(math.min(results.length, 3), (index) {
                            final url = results[index]['link'] as String? ?? '';
                            Uri? uri;
                            try { uri = Uri.parse(url); } catch (_) {}
                            final domain = uri?.host ?? '';
                            final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
                            
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
                                    width: 2
                                  ),
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
                                        errorBuilder: (_, __, ___) => const Icon(fluent.FluentIcons.globe, size: 12, color: Colors.grey),
                                      )
                                    : const Icon(fluent.FluentIcons.globe, size: 12, color: Colors.grey),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$count 个引用内容', 
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.typography.body?.color?.withOpacity(0.9),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded ? fluent.FluentIcons.chevron_up : fluent.FluentIcons.chevron_down,
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
                    border: Border(top: BorderSide(color: theme.resources.controlStrokeColorDefault)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: List.generate(results.length, (index) {
                      final item = results[index];
                      final idx = item['index'] ?? (index + 1);
                      return InkWell(
                        onTap: () async {
                           final link = item['link'] as String?;
                           if (link != null) {
                             // Try open link
                              // Since we don't have launchUrl readily available in this context without imports checking, 
                              // we assume specific implementation or just ignore for now as this is UI focused.
                           }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                          color: theme.typography.caption?.color,
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
                  _isExpanded ? fluent.FluentIcons.chevron_down : fluent.FluentIcons.chevron_right,
                  size: 10,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 8),
                Icon(fluent.FluentIcons.search, size: 14, color: theme.accentColor),
                const SizedBox(width: 8),
                Text(
                  '$count Search Results ($engine)',
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
                border: Border.all(color: theme.resources.dividerStrokeColorDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (link.isNotEmpty)
                    Text(link, style: TextStyle(color: Colors.blue, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(snippet, style: TextStyle(fontSize: 12, color: theme.typography.body!.color!.withOpacity(0.8)), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}
