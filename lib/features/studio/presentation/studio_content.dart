import 'package:fluent_ui/fluent_ui.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'novel/novel_writing_page.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';

class StudioContent extends StatefulWidget {
  const StudioContent({super.key});

  @override
  State<StudioContent> createState() => _StudioContentState();
}

class _StudioContentState extends State<StudioContent> {
  // 0: Dashboard, 1: Novel Writing
  int _viewIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_viewIndex == 1) {
      return NovelWritingPage(
        onBack: () {
          setState(() {
            _viewIndex = 0;
          });
        },
      );
    }

    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    // Dashboard View
    return Container(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AuroraIcons.studio,
                size: 64,
                color: theme.accentColor,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.studio,
                style: theme.typography.title,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.studioDescription, 
                style: theme.typography.body,
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureCard(
                    context,
                    icon: AuroraIcons.edit,
                    title: l10n.novelWriting,
                    description: l10n.novelWritingDescription,
                    onTap: () {
                      setState(() {
                        _viewIndex = 1;
                      });
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    icon: AuroraIcons.calendar,
                    title: l10n.schedulePlanning,
                    description: l10n.schedulePlanningDescription,
                    comingSoon: true,
                    onTap: null,
                  ),
                  _buildFeatureCard(
                    context,
                    icon: AuroraIcons.image,
                    title: l10n.imageManagement,
                    description: l10n.imageManagementDescription,
                    comingSoon: true,
                    onTap: null,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    bool comingSoon = false,
    VoidCallback? onTap,
  }) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      child: HoverButton(
        onPressed: onTap,
        cursor: comingSoon ? SystemMouseCursors.basic : SystemMouseCursors.click,
        builder: (context, states) {
          return Container(
            width: 220,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: states.isHovered && !comingSoon 
                  ? theme.accentColor.withAlpha(15) 
                  : Colors.transparent,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Badge or Placeholder for alignment
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: comingSoon ? theme.accentColor.withAlpha(30) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.comingSoon,
                    style: theme.typography.caption?.copyWith(
                      color: comingSoon ? theme.accentColor : Colors.transparent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  icon, 
                  size: 32, 
                  color: comingSoon 
                      ? theme.inactiveColor 
                      : theme.accentColor,
                ),
                const SizedBox(height: 12),
                Text(
                  title, 
                  style: theme.typography.bodyStrong?.copyWith( // Reduced from subtitle
                    fontSize: 16,
                    color: comingSoon ? theme.inactiveColor : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Center( // Center content vertically in remaining space
                    child: Text(
                      description,
                      style: theme.typography.caption?.copyWith(
                        color: comingSoon ? theme.inactiveColor : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
