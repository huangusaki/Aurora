import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'novel/novel_writing_page.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import '../../settings/presentation/settings_provider.dart';
import 'pages/storage_cleaning_page.dart';

class StudioContent extends ConsumerStatefulWidget {
  const StudioContent({super.key});

  @override
  ConsumerState<StudioContent> createState() => _StudioContentState();
}

class _StudioContentState extends ConsumerState<StudioContent> {
  // 0: Dashboard, 1: Novel Writing, 2: Storage Cleaning
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
    if (_viewIndex == 2) {
      return StudioStorageCleaningPage(
        onBack: () {
          setState(() {
            _viewIndex = 0;
          });
        },
      );
    }

    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isZh =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';
    final settings = ref.watch(settingsProvider);
    final hasBackground = settings.useCustomTheme &&
        settings.backgroundImagePath != null &&
        settings.backgroundImagePath!.isNotEmpty;

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
                    hasBackground: hasBackground,
                    onTap: () {
                      setState(() {
                        _viewIndex = 1;
                      });
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    icon: AuroraIcons.broom,
                    title: isZh ? '智能清理' : 'AI Cleanup',
                    description: isZh
                        ? '扫描可访问目录并给出 AI 删除建议'
                        : 'Scan accessible files and get AI cleanup advice',
                    hasBackground: hasBackground,
                    onTap: () {
                      setState(() {
                        _viewIndex = 2;
                      });
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    icon: AuroraIcons.image,
                    title: l10n.imageManagement,
                    description: l10n.imageManagementDescription,
                    comingSoon: true,
                    hasBackground: hasBackground,
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
    bool hasBackground = false,
    VoidCallback? onTap,
  }) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      backgroundColor:
          hasBackground ? theme.cardColor.withValues(alpha: 0.7) : null,
      child: HoverButton(
        onPressed: onTap,
        cursor:
            comingSoon ? SystemMouseCursors.basic : SystemMouseCursors.click,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: comingSoon
                        ? theme.accentColor.withAlpha(30)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.comingSoon,
                    style: theme.typography.caption?.copyWith(
                      color:
                          comingSoon ? theme.accentColor : Colors.transparent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  icon,
                  size: 32,
                  color: comingSoon ? theme.inactiveColor : theme.accentColor,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.typography.bodyStrong?.copyWith(
                    // Reduced from subtitle
                    fontSize: 16,
                    color: comingSoon ? theme.inactiveColor : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Center(
                    // Center content vertically in remaining space
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
