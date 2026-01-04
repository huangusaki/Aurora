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
  final List<String> _keys = [];
  // Cache of built widgets - only call itemBuilder once per key
  final Map<String, Widget> _cachedWidgets = {};
  
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
        // Remove LRU (first item) and its cached widget
        final removedKey = _keys.removeAt(0);
        _cachedWidgets.remove(removedKey);
      }
      _keys.add(newKey);
    }
    // Force rebuild to update stack
    setState(() {});
  }
  
  Widget _getOrBuildWidget(BuildContext context, String key) {
    if (!_cachedWidgets.containsKey(key)) {
      _cachedWidgets[key] = widget.itemBuilder(context, key);
    }
    return _cachedWidgets[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: _keys.map((key) {
        final isSelected = key == widget.selectedKey;
        
        return _CachedPageItem(
          key: ValueKey(key), // Important: Keep state
          isVisible: isSelected,
          duration: widget.transitionDuration,
          child: _getOrBuildWidget(context, key), // Use cached widget
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
