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
  final List<String> _keys = [];
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
    if (_keys.contains(newKey)) {
      _keys.remove(newKey);
      _keys.add(newKey);
    } else {
      if (_keys.length >= widget.cacheSize) {
        final removedKey = _keys.removeAt(0);
        _cachedWidgets.remove(removedKey);
      }
      _keys.add(newKey);
    }
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
          key: ValueKey(key),
          isVisible: isSelected,
          duration: widget.transitionDuration,
          child: _getOrBuildWidget(context, key),
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
    if (widget.isVisible) _isOffstage = false;
  }

  @override
  void didUpdateWidget(_CachedPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible) {
      _isOffstage = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: _isOffstage && !widget.isVisible,
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
          offset: widget.isVisible ? Offset.zero : const Offset(0.05, 0),
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
