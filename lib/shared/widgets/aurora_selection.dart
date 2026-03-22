import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Shared selection container used across Aurora output surfaces.
///
/// It snaps selection gestures that start in whitespace back onto the nearest
/// selectable child so desktop drag-selection remains stable inside padded and
/// mixed-content layouts.
class AuroraSelectionArea extends StatefulWidget {
  const AuroraSelectionArea({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AuroraSelectionArea> createState() => _AuroraSelectionAreaState();
}

class _AuroraSelectionAreaState extends State<AuroraSelectionArea> {
  late final AuroraSnappingSelectionContainerDelegate _delegate;

  @override
  void initState() {
    super.initState();
    _delegate = AuroraSnappingSelectionContainerDelegate();
  }

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SelectionContainer(
        delegate: _delegate,
        child: widget.child,
      ),
    );
  }
}

class AuroraSelectableText extends StatelessWidget {
  // Output surfaces should route through this wrapper instead of raw
  // SelectableText so desktop drag-selection stays on the shared snapping path.
  const AuroraSelectableText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.useSelectionArea = true,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final bool useSelectionArea;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
    if (!useSelectionArea) {
      return text;
    }
    return AuroraSelectionArea(child: text);
  }
}

class AuroraSnappingSelectionContainerDelegate
    extends StaticSelectionContainerDelegate {
  @override
  SelectionResult handleSelectionEdgeUpdate(SelectionEdgeUpdateEvent event) {
    final Offset? snapped = _maybeSnapPosition(event.globalPosition);
    if (snapped == null) {
      return super.handleSelectionEdgeUpdate(event);
    }

    final SelectionEdgeUpdateEvent snappedEvent =
        event.type == SelectionEventType.startEdgeUpdate
            ? SelectionEdgeUpdateEvent.forStart(
                globalPosition: snapped,
                granularity: event.granularity,
              )
            : SelectionEdgeUpdateEvent.forEnd(
                globalPosition: snapped,
                granularity: event.granularity,
              );
    return super.handleSelectionEdgeUpdate(snappedEvent);
  }

  @override
  SelectionResult handleSelectWord(SelectWordSelectionEvent event) {
    final Offset? snapped = _maybeSnapPosition(event.globalPosition);
    if (snapped == null) {
      return super.handleSelectWord(event);
    }
    return super
        .handleSelectWord(SelectWordSelectionEvent(globalPosition: snapped));
  }

  @override
  SelectionResult handleSelectParagraph(SelectParagraphSelectionEvent event) {
    final Offset? snapped = _maybeSnapPosition(event.globalPosition);
    if (snapped == null) {
      return super.handleSelectParagraph(event);
    }
    return super.handleSelectParagraph(
      SelectParagraphSelectionEvent(
        globalPosition: snapped,
        absorb: event.absorb,
      ),
    );
  }

  Offset? _maybeSnapPosition(Offset globalPosition) {
    if (!hasSize || selectables.isEmpty) return null;

    final Rect globalContainerRect = MatrixUtils.transformRect(
      getTransformTo(null),
      Offset.zero & containerSize,
    );
    if (!globalContainerRect.contains(globalPosition)) return null;

    final Rect? nearest = _nearestSelectableRect(globalPosition);
    if (nearest == null || nearest.contains(globalPosition)) return null;

    return _clampOffsetToRect(globalPosition, nearest);
  }

  Rect? _nearestSelectableRect(Offset globalPosition) {
    Rect? bestRect;
    double bestDy = double.infinity;
    double bestDx = double.infinity;

    for (final Selectable selectable in selectables) {
      if (selectable.boundingBoxes.isEmpty) continue;
      final Rect localRect = _unionRects(selectable.boundingBoxes);
      if (localRect.isEmpty) continue;
      final Rect rect = MatrixUtils.transformRect(
        selectable.getTransformTo(null),
        localRect,
      );
      if (rect.isEmpty) continue;
      if (rect.contains(globalPosition)) {
        return rect;
      }

      final double dy =
          _distanceToRange(globalPosition.dy, rect.top, rect.bottom);
      final double dx =
          _distanceToRange(globalPosition.dx, rect.left, rect.right);

      const double epsilon = 0.5;
      final bool betterDy = dy < bestDy - epsilon;
      final bool equalDy = (dy - bestDy).abs() <= epsilon;
      if (betterDy || (equalDy && dx < bestDx)) {
        bestRect = rect;
        bestDy = dy;
        bestDx = dx;
      }
    }

    return bestRect;
  }

  static double _distanceToRange(double value, double min, double max) {
    if (value < min) return min - value;
    if (value > max) return value - max;
    return 0.0;
  }

  static Rect _unionRects(List<Rect> rects) {
    Rect result = rects.first;
    for (int i = 1; i < rects.length; i += 1) {
      result = result.expandToInclude(rects[i]);
    }
    return result;
  }

  static Offset _clampOffsetToRect(Offset value, Rect rect) {
    const double epsilon = 0.5;

    final double xMin = rect.left + epsilon;
    final double xMax = rect.right - epsilon;
    final double yMin = rect.top + epsilon;
    final double yMax = rect.bottom - epsilon;

    final double x =
        xMin <= xMax ? value.dx.clamp(xMin, xMax).toDouble() : rect.center.dx;
    final double y =
        yMin <= yMax ? value.dy.clamp(yMin, yMax).toDouble() : rect.center.dy;

    return Offset(x, y);
  }
}
