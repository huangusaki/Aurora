import 'package:flutter/material.dart';

class CachedPageStack extends StatefulWidget {
  final String selectedKey;
  final Widget Function(BuildContext context, String key) itemBuilder;
  final int cacheSize;
  final Duration transitionDuration;

  const CachedPageStack({
    super.key,
    required this.selectedKey,
    required this.itemBuilder,
    this.cacheSize = 10,
    this.transitionDuration = const Duration(milliseconds: 800),
  });

  @override
  State<CachedPageStack> createState() => _CachedPageStackState();
}

class _CachedPageStackState extends State<CachedPageStack> {
  // Ordered list of keys (LRU: end is most recently used, start is least)
  // Actually usually easier: remove from list and append to end on use.
  final List<String> _keys = [];
  // Map of built widgets
  // We keep the Widget instances. To preserve state, they need to stay in the Element tree.
  // So we will render a Stack of ALL cached items, wrapping non-selected ones in Offstage.
  // HOWEVER, for transition animations, we need the "exiting" widget to be visible during transition.
  
  // To support AnimatedSwitcher-like transitions WITH state preservation, it's tricky.
  // Standard AnimatedSwitcher destroys the "old" child.
  // To preserve state, we must keep the widget in the tree.
  
  // Hybrid approach:
  // Use indexed stack-like approach with custom animations?
  // Or simply: 
  // The "Stack" contains all cached keys.
  // Only the `selectedKey` is visible (opacity 1, transform identity).
  // Others are hidden (Offstage or opacity 0).
  // BUT user wants animation.
  // So when `selectedKey` changes:
  // 1. Old key moves from "Active" to "Background" (animate out).
  // 2. New key moves from "Background/New" to "Active" (animate in).
  
  // Let's implement a custom layout that manages this.
  
  @override
  void initState() {
    super.initState();
    _updateCache(widget.selectedKey);
  }

  @override
  void didUpdateWidget(CachedPageStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedKey != oldWidget.selectedKey) {
      _updateCache(widget.selectedKey);
    }
  }

  void _updateCache(String newKey) {
    // If key exists, move to end (MRU)
    if (_keys.contains(newKey)) {
      _keys.remove(newKey);
      _keys.add(newKey);
    } else {
      // New key
      if (_keys.length >= widget.cacheSize) {
        // Remove LRU (first item)
        _keys.removeAt(0);
      }
      _keys.add(newKey);
    }
    // Force rebuild to update stack
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // We utilize a Stack so all cached widgets are physically present.
    // We control visibility via AnimatedOpacity/Offstage.
    // Specially, we need the "transition" effect.
    
    return Stack(
      fit: StackFit.expand,
      children: _keys.map((key) {
        final isSelected = key == widget.selectedKey;
        // If not selected, we want it hidden BUT after animation.
        // Simple AnimatedOpacity handles the "fade" part.
        // For "Slide", we can use AnimatedPositioned or AnimatedSlide.
        
        // Performance note: Keeping 10 text fields/lists active in Stack might be heavy on GPU if they all paint?
        // Offstage prevents painting. We should use Offstage for items that are NOT selected AND NOT animating.
        // But detecting "animating" status is hard in declarative UI without a controller.
        // However, standard implicit animations (AnimatedOpacity) have an 'onEnd'.
        
        // Let's use a wrapper that handles "Visible -> Animate -> Offstage".
        return _CachedPageItem(
          key: ValueKey(key), // Important: Keep state
          isVisible: isSelected,
          duration: widget.transitionDuration,
          child: widget.itemBuilder(context, key),
        );
      }).toList(),
    );
  }
}

class _CachedPageItem extends StatefulWidget {
  final bool isVisible;
  final Duration duration;
  final Widget child;

  const _CachedPageItem({
    super.key,
    required this.isVisible,
    required this.duration,
    required this.child,
  });

  @override
  State<_CachedPageItem> createState() => _CachedPageItemState();
}

class _CachedPageItemState extends State<_CachedPageItem> {
  bool _isOffstage = true;

  @override
  void initState() {
    super.initState();
    // If initially visible, not offstage.
    if (widget.isVisible) _isOffstage = false;
  }

  @override
  void didUpdateWidget(_CachedPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible) {
      // If becoming visible, immediately remove Offstage to start animation
      _isOffstage = false;
    } 
    // If becoming invisible, we wait for animation to finish before setting Offstage.
    // This is handled by onEnd of AnimatedOpacity.
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: _isOffstage && !widget.isVisible, // Only offstage if NOT visible AND animation done (implied by logic below)
      // Actually simpler:
      // If widget.isVisible is true, Offstage must be false.
      // If widget.isVisible is false, Offstage should be true ONLY after delay.
      // We'll manage _isOffstage via onEnd.
      child: AnimatedOpacity(
        opacity: widget.isVisible ? 1.0 : 0.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        onEnd: () {
          if (!widget.isVisible) {
            setState(() {
              _isOffstage = true;
            });
          }
        },
        child: AnimatedSlide(
          offset: widget.isVisible ? Offset.zero : const Offset(0.05, 0), // Slight slide for depth
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
