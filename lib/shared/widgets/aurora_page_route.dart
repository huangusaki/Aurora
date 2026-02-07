import 'package:aurora/shared/widgets/global_background.dart';
import 'package:flutter/material.dart';

/// A mobile-friendly push route that avoids "previous page bleeding through"
/// when the destination page uses transparent / glass backgrounds.
///
/// It briefly renders an opaque global background *above* the previous route
/// during the push transition, so the old page won't overlap with the new page.
class AuroraMobilePageRoute<T> extends PageRouteBuilder<T> {
  AuroraMobilePageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 280),
    super.reverseTransitionDuration = const Duration(milliseconds: 240),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              _AuroraRoutePage(child: builder(context)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final slide = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curve);

            final fade = Tween<double>(begin: 0, end: 1).animate(curve);

            final bool showCover =
                animation.status == AnimationStatus.forward ||
                    animation.status == AnimationStatus.dismissed;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (showCover) const _AuroraRouteCover(),
                SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: fade, child: child),
                ),
              ],
            );
          },
        );
}

class _AuroraRouteCover extends StatelessWidget {
  const _AuroraRouteCover();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        // Ensures we always cover the previous route even if the theme uses
        // translucent scaffold backgrounds (custom wallpaper mode).
        color: Theme.of(context).scaffoldBackgroundColor.withAlpha(255),
        child: const GlobalBackground(child: SizedBox.expand()),
      ),
    );
  }
}

class _AuroraRoutePage extends StatelessWidget {
  final Widget child;

  const _AuroraRoutePage({required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // Provide a concrete base color for transparent destination pages.
      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(255),
      child: GlobalBackground(child: child),
    );
  }
}
