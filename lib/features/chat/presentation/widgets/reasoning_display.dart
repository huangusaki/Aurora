import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:aurora/l10n/app_localizations.dart';

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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;
  Timer? _timer;
  double _currentDuration = 0;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.isRunning) {
      _isExpanded = true;
      _controller.value = 1.0;
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
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReasoningDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !oldWidget.isRunning) {
      setState(() => _isExpanded = true);
      _controller.forward();
      _startTimer();
    }
    if (!widget.isRunning && oldWidget.isRunning) {
      _timer?.cancel();
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.content.isEmpty) return const SizedBox.shrink();
    final isDark =
        fluent.FluentTheme.of(context).brightness == fluent.Brightness.dark;
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
                      AuroraIcons.lightbulb,
                      size: 18,
                      color: iconColor,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isRunning
                        ? '${AppLocalizations.of(context)!.deepThinking} (${_currentDuration.toStringAsFixed(1)}s)'
                        : (widget.duration != null
                            ? AppLocalizations.of(context)!.deepThoughtFinished(
                                widget.duration!.toStringAsFixed(1))
                            : AppLocalizations.of(context)!.thoughtChain),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
                    child: Icon(
                      AuroraIcons.chevronDown,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isDismissed) {
                return const SizedBox.shrink();
              }
              return SizeTransition(
                sizeFactor: _animation,
                axisAlignment: -1.0,
                child: Container(
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
                          fontFamily: widget.isWindows ? 'Consolas' : null,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        selectionControls: widget.isWindows 
                            ? fluent.fluentTextSelectionControls 
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
