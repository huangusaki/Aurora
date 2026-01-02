import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'dart:async';

class ReasoningDisplay extends StatefulWidget {
  final String content;
  final bool isWindows;
  final bool isRunning;
  final double? duration;
  final DateTime? startTime;

  const ReasoningDisplay({
    super.key,
    required this.content,
    required this.isWindows,
    this.isRunning = false,
    this.duration,
    this.startTime,
  });
  @override
  State<ReasoningDisplay> createState() => _ReasoningDisplayState();
}

class _ReasoningDisplayState extends State<ReasoningDisplay>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  
  Timer? _timer;
  double _currentDuration = 0;
  
  @override
  void initState() {
    super.initState();
    if (widget.isRunning) {
      _isExpanded = true;
      _startTimer();
    }
  }
  
  void _startTimer() {
    _timer?.cancel();
    if (widget.startTime != null) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted) {
          setState(() {
            _currentDuration = DateTime.now()
                    .difference(widget.startTime!)
                    .inMilliseconds
                    .toDouble() /
                1000.0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(ReasoningDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !oldWidget.isRunning) {
      setState(() => _isExpanded = true);
      _startTimer();
    }
    if (!widget.isRunning && oldWidget.isRunning) {
      _timer?.cancel();
      setState(() => _isExpanded = false);
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) return const SizedBox.shrink();
    final isDark = widget.isWindows
        ? fluent.FluentTheme.of(context).brightness == fluent.Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final iconColor = isDark ? Colors.white54 : Colors.black54;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    widget.isWindows
                        ? fluent.FluentIcons.lightbulb
                        : Icons.lightbulb_outline,
                    size: 18,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isRunning
                        ? '深度思考中... (${_currentDuration.toStringAsFixed(1)}s)'
                        : (widget.duration != null
                            ? '已深度思考 (用时 ${widget.duration!.toStringAsFixed(1)} 秒)'
                            : '思维链'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? (widget.isWindows
                            ? fluent.FluentIcons.chevron_up
                            : Icons.keyboard_arrow_up)
                        : (widget.isWindows
                            ? fluent.FluentIcons.chevron_down
                            : Icons.keyboard_arrow_down),
                    size: 16,
                    color: iconColor,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 0.5,
              ))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'Consolas',
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topLeft,
          ),
        ],
      ),
    );
  }
}
