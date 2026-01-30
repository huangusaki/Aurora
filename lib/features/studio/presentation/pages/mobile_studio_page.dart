import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:flutter/material.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'mobile_novel_writing_page.dart';

class MobileStudioPage extends StatefulWidget {
  final VoidCallback? onBack;
  const MobileStudioPage({super.key, this.onBack});

  @override
  State<MobileStudioPage> createState() => _MobileStudioPageState();
}

class _MobileStudioPageState extends State<MobileStudioPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.studio),
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(AuroraIcons.back),
                onPressed: widget.onBack,
              )
            : null,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(
              AuroraIcons.repair,
              size: 64,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.studio,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.studioDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildFeatureCard(
                  context,
                  icon: AuroraIcons.edit,
                  title: l10n.novelWriting,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MobileNovelWritingPage(
                          onBack: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: AuroraIcons.calendar,
                  title: l10n.schedulePlanning,
                  comingSoon: true,
                ),
                _buildFeatureCard(
                  context,
                  icon: AuroraIcons.image,
                  title: l10n.imageManagement,
                  comingSoon: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool comingSoon = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      color: theme.cardColor,
      child: InkWell(
        onTap: comingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (comingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.comingSoon,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                )
              else
                const SizedBox(height: 18),
              const SizedBox(height: 8),
              Icon(
                icon,
                size: 32,
                color: comingSoon ? theme.disabledColor : theme.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: comingSoon ? theme.disabledColor : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
