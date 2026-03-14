import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ViewportPreservingTrackedItem extends SingleChildRenderObjectWidget {
  const ViewportPreservingTrackedItem({
    super.key,
    required this.itemId,
    required super.child,
  });

  final String itemId;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderViewportPreservingTrackedItem(itemId);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderObject renderObject,
  ) {
    (renderObject as _RenderViewportPreservingTrackedItem).itemId = itemId;
  }
}

class _RenderViewportPreservingTrackedItem extends RenderProxyBox {
  _RenderViewportPreservingTrackedItem(this.itemId);

  String itemId;
}

class ViewportPreservingSliverList extends SliverMultiBoxAdaptorWidget {
  const ViewportPreservingSliverList({
    super.key,
    required super.delegate,
    this.trackedChildIndex = 0,
    this.preserveScrollOffset = false,
    this.onTrackedChildExtentChanged,
  });

  final int trackedChildIndex;
  final bool preserveScrollOffset;
  final VoidCallback? onTrackedChildExtentChanged;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderViewportPreservingSliverList createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderViewportPreservingSliverList(
      childManager: element,
      trackedChildIndex: trackedChildIndex,
      preserveScrollOffset: preserveScrollOffset,
      onTrackedChildExtentChanged: onTrackedChildExtentChanged,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderViewportPreservingSliverList renderObject,
  ) {
    renderObject
      ..trackedChildIndex = trackedChildIndex
      ..preserveScrollOffset = preserveScrollOffset
      .._onTrackedChildExtentChanged = onTrackedChildExtentChanged;
  }
}

class RenderViewportPreservingSliverList extends RenderSliverList {
  RenderViewportPreservingSliverList({
    required super.childManager,
    required int trackedChildIndex,
    required bool preserveScrollOffset,
    VoidCallback? onTrackedChildExtentChanged,
  })  : _trackedChildIndex = trackedChildIndex,
        _preserveScrollOffset = preserveScrollOffset,
        _onTrackedChildExtentChanged = onTrackedChildExtentChanged;

  int get trackedChildIndex => _trackedChildIndex;
  int _trackedChildIndex;
  set trackedChildIndex(int value) {
    if (value == _trackedChildIndex) return;
    _trackedChildIndex = value;
    markNeedsLayout();
  }

  bool get preserveScrollOffset => _preserveScrollOffset;
  bool _preserveScrollOffset;
  set preserveScrollOffset(bool value) {
    if (value == _preserveScrollOffset) return;
    _preserveScrollOffset = value;
    markNeedsLayout();
  }

  VoidCallback? _onTrackedChildExtentChanged;

  double? _previousTrackedExtent;
  String? _previousTrackedItemId;

  @override
  void performLayout() {
    super.performLayout();

    final trackedChild = _findTrackedChild();
    final trackedExtent =
        trackedChild != null ? paintExtentOf(trackedChild) : null;
    final trackedItemId = _trackedItemIdFor(trackedChild);

    if (trackedExtent == null || trackedItemId == null) {
      if (!preserveScrollOffset) {
        _previousTrackedExtent = null;
        _previousTrackedItemId = null;
      }
      return;
    }

    final previousTrackedExtent = _previousTrackedExtent;
    final previousTrackedItemId = _previousTrackedItemId;
    _previousTrackedExtent = trackedExtent;
    _previousTrackedItemId = trackedItemId;

    if (previousTrackedExtent == null || previousTrackedItemId == null) {
      return;
    }

    final extentDelta = previousTrackedItemId == trackedItemId
        ? trackedExtent - previousTrackedExtent
        : trackedExtent;
    if (extentDelta.abs() < 0.5) return;

    _onTrackedChildExtentChanged?.call();

    if (!preserveScrollOffset) return;
    if (geometry?.scrollOffsetCorrection != null) return;

    geometry = SliverGeometry(
      scrollOffsetCorrection: extentDelta,
    );
  }

  RenderBox? _findTrackedChild() {
    RenderBox? child = firstChild;
    while (child != null) {
      final childIndex = indexOf(child);
      if (childIndex == trackedChildIndex) {
        return child;
      }
      child = childAfter(child);
    }
    return null;
  }

  String? _trackedItemIdFor(RenderBox? child) {
    if (child is _RenderViewportPreservingTrackedItem) {
      return child.itemId;
    }
    return null;
  }
}
