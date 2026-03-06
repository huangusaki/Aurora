import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

class DeferredFluentSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChangeCommitted;
  final String? Function(double value)? labelBuilder;
  final Widget Function(BuildContext context, double value)? trailingBuilder;
  final double trailingSpacing;

  const DeferredFluentSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChangeCommitted,
    this.divisions,
    this.labelBuilder,
    this.trailingBuilder,
    this.trailingSpacing = 12,
  });

  @override
  State<DeferredFluentSlider> createState() => _DeferredFluentSliderState();
}

class _DeferredFluentSliderState extends State<DeferredFluentSlider> {
  late double _draftValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _draftValue = widget.value.clamp(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(covariant DeferredFluentSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.value.clamp(widget.min, widget.max);
    if (!_isDragging && nextValue != _draftValue) {
      _draftValue = nextValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slider = fluent.Slider(
      value: _draftValue,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: widget.labelBuilder?.call(_draftValue),
      onChangeStart: (_) {
        if (!_isDragging) {
          setState(() => _isDragging = true);
        }
      },
      onChanged: (value) {
        if (value == _draftValue) return;
        setState(() {
          _isDragging = true;
          _draftValue = value.clamp(widget.min, widget.max);
        });
      },
      onChangeEnd: (value) {
        final committedValue = value.clamp(widget.min, widget.max);
        setState(() {
          _isDragging = false;
          _draftValue = committedValue;
        });
        widget.onChangeCommitted(committedValue);
      },
    );

    final trailingBuilder = widget.trailingBuilder;
    if (trailingBuilder == null) {
      return slider;
    }

    return Row(
      children: [
        Expanded(child: slider),
        SizedBox(width: widget.trailingSpacing),
        trailingBuilder(context, _draftValue),
      ],
    );
  }
}
