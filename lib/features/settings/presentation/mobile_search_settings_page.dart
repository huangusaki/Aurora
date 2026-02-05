import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:aurora_search/aurora_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import 'widgets/mobile_settings_widgets.dart';

class MobileSearchSettingsPage extends ConsumerWidget {
  const MobileSearchSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    String safeSearchLabel(String code) {
      switch (code) {
        case 'off':
          return l10n.searchSafeSearchOff;
        case 'moderate':
          return l10n.searchSafeSearchModerate;
        case 'on':
          return l10n.searchSafeSearchStrict;
        default:
          return code;
      }
    }

    final region = SearchRegion.fromCode(settingsState.searchRegion);
    final safeSearchCode = settingsState.searchSafeSearch.trim().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.searchSettings),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          MobileSettingsSection(
            title: l10n.searchSettings,
            children: [

              MobileSettingsTile(
                leading: const Icon(AuroraIcons.search),
                title: l10n.searchEngine,
                subtitle: settingsState.searchEngine,
                onTap: () => _showEnginePicker(context, ref, settingsState),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.public),
                title: l10n.searchRegion,
                subtitle: '${region.code} - ${region.displayName}',
                onTap: () => _showRegionPicker(context, ref, settingsState),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.shield_outlined),
                title: l10n.searchSafeSearch,
                subtitle: safeSearchLabel(safeSearchCode),
                onTap: () => _showSafeSearchPicker(context, ref, settingsState),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.format_list_numbered),
                title: l10n.searchMaxResults,
                subtitle: settingsState.searchMaxResults.toString(),
                onTap: () => _editMaxResults(context, ref, settingsState),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.timer_outlined),
                title: l10n.searchTimeoutSeconds,
                subtitle: '${settingsState.searchTimeoutSeconds}s',
                onTap: () => _editTimeoutSeconds(context, ref, settingsState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEnginePicker(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final engines = <String>{
      ...getAvailableEngines('text'),
      settings.searchEngine,
    }.toList()
      ..sort();

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(ctx, l10n.searchEngine),
            const Divider(height: 1),
            ...engines.map((engine) {
              final selected = engine == settings.searchEngine;
              return AuroraBottomSheet.buildListItem(
                context: ctx,
                title: Text(engine),
                selected: selected,
                trailing: selected
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).primaryColor, size: 18)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setSearchEngine(engine);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRegionPicker(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final selectedRegion = SearchRegion.fromCode(settings.searchRegion);

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(ctx, l10n.searchRegion),
            const Divider(height: 1),
            ...SearchRegion.values.map((region) {
              final selected = region.code == selectedRegion.code;
              return AuroraBottomSheet.buildListItem(
                context: ctx,
                title: Text('${region.code} - ${region.displayName}'),
                selected: selected,
                trailing: selected
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).primaryColor, size: 18)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setSearchRegion(region.code);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSafeSearchPicker(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final safeSearchCode = settings.searchSafeSearch.trim().toLowerCase();

    String safeSearchLabel(String code) {
      switch (code) {
        case 'off':
          return l10n.searchSafeSearchOff;
        case 'moderate':
          return l10n.searchSafeSearchModerate;
        case 'on':
          return l10n.searchSafeSearchStrict;
        default:
          return code;
      }
    }

    const levels = ['off', 'moderate', 'on'];

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(ctx, l10n.searchSafeSearch),
            const Divider(height: 1),
            ...levels.map((level) {
              final selected = level == safeSearchCode;
              return AuroraBottomSheet.buildListItem(
                context: ctx,
                title: Text(safeSearchLabel(level)),
                selected: selected,
                trailing: selected
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).primaryColor, size: 18)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setSearchSafeSearch(level);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editMaxResults(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final input = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.searchMaxResults,
      hintText: '1-50',
      initialValue: settings.searchMaxResults.toString(),
      confirmText: l10n.confirm,
      cancelText: l10n.cancel,
    );
    if (input == null) return;
    final parsed = int.tryParse(input);
    if (parsed == null) return;
    await ref.read(settingsProvider.notifier).setSearchMaxResults(parsed);
  }

  Future<void> _editTimeoutSeconds(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final input = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.searchTimeoutSeconds,
      hintText: '5-60',
      initialValue: settings.searchTimeoutSeconds.toString(),
      confirmText: l10n.confirm,
      cancelText: l10n.cancel,
    );
    if (input == null) return;
    final parsed = int.tryParse(input);
    if (parsed == null) return;
    await ref.read(settingsProvider.notifier).setSearchTimeoutSeconds(parsed);
  }
}

