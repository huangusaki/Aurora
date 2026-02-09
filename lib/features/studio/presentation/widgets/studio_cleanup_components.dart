import 'package:fluent_ui/fluent_ui.dart';

class StudioStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StudioStatusChip({
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

class StudioKpiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool hasBackground;

  const StudioKpiChip({
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

class StudioStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool wide;
  final bool hasBackground;

  const StudioStatTile({
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

class StudioTag extends StatelessWidget {
  final String text;
  final Color color;
  final bool hasBackground;

  const StudioTag({
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
