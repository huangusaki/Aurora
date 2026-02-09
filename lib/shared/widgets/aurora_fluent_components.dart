import 'package:fluent_ui/fluent_ui.dart';

class AuroraPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool hasBackground;

  const AuroraPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 10,
    this.hasBackground = false,
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
            ? theme.cardColor.withValues(alpha: 0.58)
            : Colors.white.withValues(alpha: 0.82))
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

class AuroraSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuroraSectionHeader({
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

class AuroraStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const AuroraStatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AuroraKpiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool hasBackground;

  const AuroraKpiChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hasBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = hasBackground
        ? (isDark
            ? theme.cardColor.withValues(alpha: 0.56)
            : Colors.white.withValues(alpha: 0.76))
        : (isDark
            ? Color.lerp(theme.cardColor, Colors.black, 0.16)!
            : Color.lerp(theme.cardColor, Colors.black, 0.06)!);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: hasBackground ? 0.14 : 0.10)
        : Colors.black.withValues(alpha: hasBackground ? 0.12 : 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: fill,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.accentColor),
          const SizedBox(width: 6),
          Text('$label: ', style: theme.typography.caption),
          Text(value, style: theme.typography.bodyStrong),
        ],
      ),
    );
  }
}

class AuroraStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool wide;
  final bool hasBackground;

  const AuroraStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
    this.hasBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillAlpha =
        hasBackground ? (isDark ? 0.22 : 0.14) : (isDark ? 0.16 : 0.10);
    return Container(
      width: wide ? 248 : 164,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: fillAlpha),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.typography.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.typography.bodyStrong?.copyWith(
              color: color,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class AuroraTag extends StatelessWidget {
  final String text;
  final Color color;
  final bool hasBackground;

  const AuroraTag({
    super.key,
    required this.text,
    required this.color,
    this.hasBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillAlpha =
        hasBackground ? (isDark ? 0.28 : 0.16) : (isDark ? 0.22 : 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: fillAlpha),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AuroraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;

  const AuroraEmptyState({
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
