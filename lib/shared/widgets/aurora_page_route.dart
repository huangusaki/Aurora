import 'package:aurora/shared/widgets/global_background.dart';
import 'package:flutter/material.dart';

/// A mobile-friendly push route using fade + subtle scale for smooth,
/// consistent transitions that match the main navigation style.
///
/// The destination page is wrapped in [_AuroraRoutePage] to provide an opaque
/// base, preventing transparent scaffold backgrounds from "bleeding through".
class AuroraMobilePageRoute<T> extends PageRouteBuilder<T> {
  AuroraMobilePageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 260),
    super.reverseTransitionDuration = const Duration(milliseconds: 200),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              _AuroraRoutePage(child: builder(context)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final fade = Tween<double>(begin: 0, end: 1).animate(curve);
            final scale = Tween<double>(begin: 0.96, end: 1.0).animate(curve);

            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
        );
}

/// A shared fade route for full-screen viewers and special pages.
/// Keeps transition behavior centralized instead of scattering
/// ad-hoc PageRouteBuilder implementations across features.
class AuroraFadePageRoute<T> extends PageRouteBuilder<T> {
  AuroraFadePageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.opaque = true,
    super.transitionDuration = const Duration(milliseconds: 220),
    super.reverseTransitionDuration = const Duration(milliseconds: 180),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
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
