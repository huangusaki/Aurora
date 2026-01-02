import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrafficLightButton(
            color: const Color(0xFFFEBC2E), // MacOS Yellow
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
                color: const Color(0xFF28C840), // MacOS Green
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
            color: const Color(0xFFFF5F57), // MacOS Red
            icon: Icons.close,
            showIcon: _isHovering,
            onTap: windowManager.close,
          ),
          const SizedBox(width: 10), // Padding from edge
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
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}
