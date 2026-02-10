import 'package:fluent_ui/fluent_ui.dart';

class StudioPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool hasBackground;
  final Clip clipBehavior;

  const StudioPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 10,
    this.hasBackground = false,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final neutralStroke = isDark
        ? Colors.white.withValues(alpha: hasBackground ? 0.16 : 0.10)
        : Colors.black.withValues(alpha: hasBackground ? 0.12 : 0.08);
    final surface = hasBackground
        ? (isDark
            ? theme.cardColor.withValues(alpha: 0.46)
            : Colors.white.withValues(alpha: 0.72))
        : (isDark
            ? Color.lerp(theme.cardColor, Colors.black, 0.10)!
            : Color.lerp(theme.cardColor, Colors.white, 0.45)!);
    final strokeColor = hasBackground
        ? theme.resources.surfaceStrokeColorDefault
            .withValues(alpha: isDark ? 0.78 : 0.62)
        : neutralStroke;
    final shadowColor = Colors.black.withValues(
      alpha: hasBackground ? (isDark ? 0.28 : 0.08) : (isDark ? 0.22 : 0.06),
    );

    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: strokeColor),
        color: surface,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isDark ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class StudioSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const StudioSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: theme.accentColor),
            const SizedBox(width: 6),
            Text(title, style: theme.typography.bodyStrong),
          ],
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: theme.typography.caption),
      ],
    );
  }
}

class StudioEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;

  const StudioEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 26,
              height: 26,
              child: ProgressRing(strokeWidth: 2),
            )
          else
            Icon(icon, size: 30, color: theme.inactiveColor),
          const SizedBox(height: 10),
          Text(title, style: theme.typography.bodyStrong),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.typography.caption),
        ],
      ),
    );
  }
}
