import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:aurora/shared/riverpod_legacy.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/settings/presentation/mobile_preset_manage_page.dart';
import 'package:aurora/shared/widgets/aurora_page_route.dart';
import '../chat_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';

class MobilePresetSelector extends ConsumerWidget {
  final String sessionId;
  const MobilePresetSelector({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.tune),
      tooltip: l10n.promptPresets,
      onPressed: () => _showPresetSheet(context, ref),
    );
  }

  void _showPresetSheet(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final presets = settings.presets;
    final l10n = AppLocalizations.of(context)!;
    ref.read(chatStateUpdateTriggerProvider);
    final chatState = ref
        .read(chatSessionManagerProvider)
        .getOrCreate(sessionId)
        .currentState;
    String? activePresetName = chatState.activePresetName;
    final isDefault = activePresetName == null;

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(
            context,
            l10n.promptPresets,
            trailing: TextButton.icon(
              icon: const Icon(Icons.settings, size: 18),
              label: Text(l10n.managePresets),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  AuroraMobilePageRoute(
                    builder: (context) => const MobilePresetManagePage(),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // --- Assistants Section ---
                // Removed to separate concerns based on user feedback.
                // --- Presets Section ---
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    l10n.promptPresets,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    isDefault ? Icons.check_circle : Icons.circle_outlined,
                    color: isDefault ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(l10n.defaultPreset),
                  onTap: () {
                    ref
                        .read(chatSessionManagerProvider)
                        .getOrCreate(sessionId)
                        .updateSystemPrompt('', null);
                    Navigator.pop(ctx);
                  },
                ),
                for (final preset in presets)
                  ListTile(
                    leading: Icon(
                      activePresetName == preset.name
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: activePresetName == preset.name
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    title: Text(preset.name),
                    subtitle: preset.description.isNotEmpty
                        ? Text(preset.description)
                        : null,
                    onTap: () {
                      ref
                          .read(chatSessionManagerProvider)
                          .getOrCreate(sessionId)
                          .updateSystemPrompt(preset.systemPrompt, preset.name);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


