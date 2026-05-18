import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'selectable_markdown.dart';

class AnimatedStreamingMarkdown extends StatefulWidget {
  final String data;
  final bool isDark;
  final Color textColor;
  final double baseFontSize;
  final bool animate;
  final bool streamingActive;
  final bool useSelectionArea;

  const AnimatedStreamingMarkdown({
    super.key,
    required this.data,
    required this.isDark,
    required this.textColor,
    this.baseFontSize = 14.0,
    this.animate = true,
    this.streamingActive = false,
    this.useSelectionArea = true,
  });

  @override
  State<AnimatedStreamingMarkdown> createState() =>
      _AnimatedStreamingMarkdownState();
}

class _AnimatedStreamingMarkdownState extends State<AnimatedStreamingMarkdown> {
  static const Duration _markdownSettleDelay = Duration(milliseconds: 180);

  late String _displayedData;
  Timer? _timer;
  Timer? _settleTimer;
  int _activePointers = 0;
  bool _suspendAnimation = false;
  bool _useStreamingPreview = false;

  @override
  void initState() {
    super.initState();
    _displayedData = widget.data;
    _useStreamingPreview =
        widget.animate && widget.streamingActive && widget.data.isNotEmpty;
  }

  @override
  void didUpdateWidget(AnimatedStreamingMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate) {
      if (_displayedData != widget.data ||
          oldWidget.animate != widget.animate ||
          _useStreamingPreview) {
        _displayedData = widget.data;
        _stopAnimation();
        _cancelSettleTimer();
        _useStreamingPreview = false;
        if (mounted) setState(() {});
      }
      return;
    }

    if (widget.data != oldWidget.data) {
      // If widget.data is shorter or not a prefix (e.g. edit/delete), sync immediately.
      // This should take precedence even if we're suspending animation.
      if (_displayedData.length > widget.data.length ||
          !widget.data.startsWith(_displayedData)) {
        _displayedData = widget.data;
        _stopAnimation();
        _cancelSettleTimer();
        _useStreamingPreview = widget.streamingActive;
        if (mounted) setState(() {});
        return;
      }

      _activateStreamingPreview();
      _maybeScheduleMarkdownCommit();

      if (_suspendAnimation) {
        // Freeze the current render tree while the user is interacting (selection),
        // and catch up on pointer up.
        return;
      }

      _startAnimation();
    }

    if (oldWidget.streamingActive && !widget.streamingActive) {
      _maybeScheduleMarkdownCommit();
    }
  }

  void _startAnimation() {
    if (_suspendAnimation || !widget.animate) return;

    // If widget.data is shorter or not a prefix (e.g. edit/delete), sync immediately
    if (_displayedData.length > widget.data.length ||
        !widget.data.startsWith(_displayedData)) {
      _displayedData = widget.data;
      _stopAnimation();
      _cancelSettleTimer();
      _useStreamingPreview = widget.streamingActive;
      // Force rebuild to show immediate change
      if (mounted) setState(() {});
      return;
    }

    // If already equal, do nothing
    if (_displayedData.length == widget.data.length) {
      _maybeScheduleMarkdownCommit();
      return;
    }

    // If timer is already running, let it continue, but it will use the new widget.data
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || _suspendAnimation) {
        timer.cancel();
        _timer = null;
        return;
      }

      final totalLength = widget.data.length;
      final currentLength = _displayedData.length;

      if (currentLength >= totalLength) {
        _displayedData = widget.data;
        timer.cancel();
        _timer = null;
        _maybeScheduleMarkdownCommit();
        setState(() {});
        return;
      }

      final distance = totalLength - currentLength;

      // Dynamic step size for smooth catch-up
      // Min 1 char, max proportional to distance (distance/20)
      // This creates an ease-out effect
      int step = max(1, (distance / 20).ceil());
      // Increase minimum speed slightly to avoid crawling at the end
      if (step < 2) step = 2;

      final nextEnd = min(totalLength, currentLength + step);
      setState(() {
        _displayedData = widget.data.substring(0, nextEnd);
      });
    });
  }

  void _activateStreamingPreview() {
    if (_useStreamingPreview) return;
    _useStreamingPreview = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _stopAnimation() {
    _timer?.cancel();
    _timer = null;
  }

  void _cancelSettleTimer() {
    _settleTimer?.cancel();
    _settleTimer = null;
  }

  void _scheduleMarkdownCommit() {
    _cancelSettleTimer();
    if (!widget.animate || widget.streamingActive) return;
    _settleTimer = Timer(_markdownSettleDelay, () {
      if (!mounted) return;
      if (_suspendAnimation) {
        _scheduleMarkdownCommit();
        return;
      }
      if (_displayedData != widget.data) {
        _scheduleMarkdownCommit();
        return;
      }
      if (_useStreamingPreview) {
        setState(() {
          _useStreamingPreview = false;
        });
      }
    });
  }

  void _maybeScheduleMarkdownCommit() {
    if (!_useStreamingPreview) {
      _cancelSettleTimer();
      return;
    }
    if (!widget.animate || widget.streamingActive) {
      _cancelSettleTimer();
      return;
    }
    _scheduleMarkdownCommit();
  }

  @override
  void dispose() {
    _stopAnimation();
    _cancelSettleTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (!widget.animate) return;
        // Only interfere while the streaming timer is actively mutating the tree.
        if (_timer == null || !_timer!.isActive) return;
        // Only suspend for primary button on mouse; touch selection uses different gestures.
        if (event.kind == PointerDeviceKind.mouse &&
            (event.buttons & kPrimaryButton) == 0) {
          return;
        }
        _activePointers++;
        _suspendAnimation = true;
        _stopAnimation();
      },
      onPointerUp: (_) {
        if (!widget.animate) return;
        if (_activePointers > 0) _activePointers--;
        if (_activePointers == 0 && _suspendAnimation) {
          _suspendAnimation = false;
          if (_displayedData != widget.data && mounted) {
            setState(() {
              _displayedData = widget.data;
            });
          }
          _maybeScheduleMarkdownCommit();
        }
      },
      onPointerCancel: (_) {
        if (!widget.animate) return;
        if (_activePointers > 0) _activePointers--;
        if (_activePointers == 0 && _suspendAnimation) {
          _suspendAnimation = false;
          if (_displayedData != widget.data && mounted) {
            setState(() {
              _displayedData = widget.data;
            });
          }
          _maybeScheduleMarkdownCommit();
        }
      },
      child: SelectableMarkdown(
        data: _displayedData,
        isDark: widget.isDark,
        textColor: widget.textColor,
        baseFontSize: widget.baseFontSize,
        useSelectionArea:
            widget.useSelectionArea && !(_timer?.isActive ?? false),
        renderMode: _useStreamingPreview
            ? SelectableMarkdownRenderMode.plainTextPreview
            : SelectableMarkdownRenderMode.markdown,
      ),
    );
  }
}
