import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';

class MobileAppSettingsPage extends ConsumerWidget {
  final VoidCallback? onBack;
  const MobileAppSettingsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final fluentTheme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: fluentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: fluentTheme.scaffoldBackgroundColor,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _SectionHeader(
              title: l10n.displaySettings, icon: Icons.palette_outlined),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(settingsState.language == 'zh' ? '简体中文' : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n.themeMode),
            subtitle: Text(_getThemeModeLabel(settingsState.themeMode, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeModePicker(context, ref, settingsState, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text(l10n.accentColor),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getAccentColorPreview(settingsState.themeColor),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            onTap: () => _showAccentColorPicker(context, ref, settingsState),
          ),
          ListTile(
            leading: const Icon(Icons.gradient),
            title: Text(l10n.backgroundStyle),
            subtitle: Text(_getBackgroundStyleLabel(settingsState.backgroundColor, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackgroundStylePicker(context, ref, settingsState, l10n),
          ),
          const Divider(),
          _SectionHeader(
              title: l10n.chatExperience, icon: Icons.chat_bubble_outline),
          SwitchListTile(
            title: Text(l10n.smartTopicGeneration),
            subtitle: Text(l10n.smartTopicDescription),
            value: settingsState.enableSmartTopic,
            onChanged: (bool value) {
              ref
                  .read(settingsProvider.notifier)
                  .toggleSmartTopicEnabled(value);
            },
          ),
          if (settingsState.enableSmartTopic)
            ListTile(
              title: Text(l10n.generationModel),
              subtitle: Text(settingsState.topicGenerationModel == null
                  ? l10n.notSelectedFallback
                  : settingsState.topicGenerationModel!.split('@').last),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showModelPicker(context, ref, settingsState);
              },
            ),

          const Divider(),
          _SectionHeader(title: l10n.about, icon: Icons.info_outline),
          ListTile(
            leading: const Icon(Icons.stars),
            title: const Text('Aurora'),
            subtitle: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('v1.0.0'),
                Text('一款优雅的跨平台 AI 对话助手', style: TextStyle(fontSize: 12)),
              ],
            ),
            onTap: () {},
          ),
           ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.githubProject),
             trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () async {
              const url = 'https://github.com/huangusaki/Aurora';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = ref.read(settingsProvider).language;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('简体中文'),
              trailing: currentLang == 'zh' ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLanguage('zh');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: currentLang == 'en' ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getThemeModeLabel(String mode, AppLocalizations l10n) {
    switch (mode) {
      case 'light': return l10n.themeLight;
      case 'dark': return l10n.themeDark;
      default: return l10n.themeSystem;
    }
  }

  Color _getAccentColorPreview(String colorName) {
    switch (colorName) {
      case 'teal': return Colors.teal;
      case 'blue': return Colors.blue;
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'green': return Colors.green;
      case 'purple': return Colors.purple;
      case 'magenta': return Colors.pink;
      case 'yellow': return Colors.yellow;
      default: return Colors.teal;
    }
  }

  String _getBackgroundStyleLabel(String style, AppLocalizations l10n) {
    switch (style) {
      case 'default': return l10n.bgDefault;
      case 'pure_black': return l10n.bgPureBlack;
      case 'warm': return l10n.bgWarm;
      case 'cool': return l10n.bgCool;
      case 'rose': return l10n.bgRose;
      case 'lavender': return l10n.bgLavender;
      case 'mint': return l10n.bgMint;
      case 'sky': return l10n.bgSky;
      case 'gray': return l10n.bgGray;
      case 'sunset': return l10n.bgSunset;
      case 'ocean': return l10n.bgOcean;
      case 'forest': return l10n.bgForest;
      case 'dream': return l10n.bgDream;
      case 'aurora': return l10n.bgAurora;
      case 'volcano': return l10n.bgVolcano;
      case 'midnight': return l10n.bgMidnight;
      case 'dawn': return l10n.bgDawn;
      case 'neon': return l10n.bgNeon;
      case 'blossom': return l10n.bgBlossom;
      default: return l10n.bgDefault;
    }
  }

  void _showThemeModePicker(BuildContext context, WidgetRef ref, SettingsState settings, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.themeMode, style: Theme.of(context).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.light_mode, color: settings.themeMode == 'light' ? Theme.of(context).primaryColor : null),
              title: Text(l10n.themeLight),
              trailing: settings.themeMode == 'light' ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setThemeMode('light');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode, color: settings.themeMode == 'dark' ? Theme.of(context).primaryColor : null),
              title: Text(l10n.themeDark),
              trailing: settings.themeMode == 'dark' ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setThemeMode('dark');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.brightness_auto, color: settings.themeMode == 'system' ? Theme.of(context).primaryColor : null),
              title: Text(l10n.themeSystem),
              trailing: settings.themeMode == 'system' ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setThemeMode('system');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAccentColorPicker(BuildContext context, WidgetRef ref, SettingsState settings) {
    final colors = [
      ('Teal', 'teal', Colors.teal),
      ('Blue', 'blue', Colors.blue),
      ('Red', 'red', Colors.red),
      ('Orange', 'orange', Colors.orange),
      ('Green', 'green', Colors.green),
      ('Purple', 'purple', Colors.purple),
      ('Magenta', 'magenta', Colors.pink),
      ('Yellow', 'yellow', Colors.yellow),
    ];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.accentColor, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((c) {
                final isSelected = settings.themeColor == c.$2;
                return GestureDetector(
                  onTap: () {
                    ref.read(settingsProvider.notifier).setThemeColor(c.$2);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.$3,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: isSelected ? [BoxShadow(color: c.$3.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null,
                    ),
                    child: isSelected ? Icon(Icons.check, color: c.$2 == 'yellow' ? Colors.black : Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showBackgroundStylePicker(BuildContext context, WidgetRef ref, SettingsState settings, AppLocalizations l10n) {
    final styles = [
      ('default', l10n.bgDefault),
      ('pure_black', l10n.bgPureBlack),
      ('warm', l10n.bgWarm),
      ('cool', l10n.bgCool),
      ('rose', l10n.bgRose),
      ('lavender', l10n.bgLavender),
      ('mint', l10n.bgMint),
      ('sky', l10n.bgSky),
      ('gray', l10n.bgGray),
      ('sunset', l10n.bgSunset),
      ('ocean', l10n.bgOcean),
      ('forest', l10n.bgForest),
      ('dream', l10n.bgDream),
      ('aurora', l10n.bgAurora),
      ('volcano', l10n.bgVolcano),
      ('midnight', l10n.bgMidnight),
      ('dawn', l10n.bgDawn),
      ('neon', l10n.bgNeon),
      ('blossom', l10n.bgBlossom),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.backgroundStyle, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: styles.length,
                itemBuilder: (context, index) {
                  final style = styles[index];
                  final isSelected = settings.backgroundColor == style.$1;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                    title: Text(style.$2),
                    selected: isSelected,
                    onTap: () {
                      ref.read(settingsProvider.notifier).setBackgroundColor(style.$1);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(BuildContext context, WidgetRef ref, SettingsState settings) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(l10n.selectGenerationModel,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final provider in settings.providers)
                      if (provider.isEnabled)
                        for (final model in provider.models)
                          ListTile(
                            title: Text(model),
                            subtitle: Text(provider.name),
                            selected: settings.topicGenerationModel ==
                                '${provider.id}@$model',
                            onTap: () {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setTopicGenerationModel(
                                      '${provider.id}@$model');
                              Navigator.pop(context);
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
