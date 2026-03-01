import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});
  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> with WindowListener {
  bool _isHovering = false;
  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isWindows || PlatformUtils.isLinux) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CaptionButton(
            icon: Icons.remove,
            onTap: windowManager.minimize,
          ),
          FutureBuilder<bool>(
            future: windowManager.isMaximized(),
            builder: (context, snapshot) {
              final isMaximized = snapshot.data ?? false;
              return _CaptionButton(
                icon: isMaximized ? Icons.filter_none : Icons.crop_square,
                onTap: () {
                  if (isMaximized) {
                    windowManager.restore();
                  } else {
                    windowManager.maximize();
                  }
                  setState(() {});
                },
              );
            },
          ),
          _CaptionButton(
            icon: Icons.close,
            isClose: true,
            onTap: windowManager.close,
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrafficLightButton(
            color: const Color(0xFFFEBC2E),
            icon: Icons.remove,
            showIcon: _isHovering,
            onTap: windowManager.minimize,
          ),
          const SizedBox(width: 8),
          FutureBuilder<bool>(
            future: windowManager.isMaximized(),
            builder: (context, snapshot) {
              final isMaximized = snapshot.data ?? false;
              return _TrafficLightButton(
                color: const Color(0xFF28C840),
                icon: isMaximized ? Icons.zoom_in_map : Icons.zoom_out_map,
                showIcon: _isHovering,
                onTap: () {
                  if (isMaximized) {
                    windowManager.restore();
                  } else {
                    windowManager.maximize();
                  }
                  setState(() {});
                },
              );
            },
          ),
          const SizedBox(width: 8),
          _TrafficLightButton(
            color: const Color(0xFFFF5F57),
            icon: Icons.close,
            showIcon: _isHovering,
            onTap: windowManager.close,
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  @override
  void onWindowMaximize() => setState(() {});
  @override
  void onWindowUnmaximize() => setState(() {});
  @override
  void onWindowRestore() => setState(() {});
}

class _TrafficLightButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool showIcon;
  final VoidCallback onTap;
  const _TrafficLightButton({
    required this.color,
    required this.icon,
    required this.showIcon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: showIcon ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 100),
            child: Icon(
              icon,
              size: 8,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  final IconData icon;
  final bool isClose;
  final VoidCallback onTap;

  const _CaptionButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseIconColor = Theme.of(context).iconTheme.color ??
        (brightness == Brightness.dark ? Colors.white : Colors.black87);
    final backgroundColor = widget.isClose
        ? (_hovering ? const Color(0xFFE81123) : Colors.transparent)
        : (_hovering
            ? baseIconColor.withValues(alpha: 0.12)
            : Colors.transparent);
    final iconColor =
        (widget.isClose && _hovering) ? Colors.white : baseIconColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 46,
          height: 32,
          color: backgroundColor,
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}
