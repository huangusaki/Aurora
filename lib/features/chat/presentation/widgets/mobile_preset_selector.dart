import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../settings/presentation/mobile_preset_manage_page.dart';
import '../chat_provider.dart';

import 'package:aurora/l10n/app_localizations.dart';

class MobilePresetSelector extends ConsumerWidget {
  final String sessionId;

  const MobilePresetSelector({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final presets = settings.presets;
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.tune), // Or another suitable icon like bookmark/dataset. Tune implies settings/presets.
      tooltip: l10n.promptPresets,
      onSelected: (value) {
        if (value == '__manage__') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MobilePresetManagePage(),
            ),
          );
        } else if (value == '__default__') {
          ref.read(chatSessionManagerProvider).getOrCreate(sessionId).updateSystemPrompt('', null);
        } else {
          // Find preset
          final preset = presets.firstWhere((p) => p.id == value, orElse: () => presets.first);
          ref.read(chatSessionManagerProvider).getOrCreate(sessionId).updateSystemPrompt(preset.systemPrompt, preset.name);
        }
      },
      itemBuilder: (context) {
        return [
           PopupMenuItem<String>(
            value: '__default__',
            child: Text(l10n.defaultPreset),
          ),
          if (presets.isNotEmpty) const PopupMenuDivider(),
          ...presets.map((preset) {
            return PopupMenuItem<String>(
              value: preset.id,
              child: Text(preset.name),
            );
          }),
          if (presets.isNotEmpty) const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '__manage__',
            child: Row(
              children: [
                const Icon(Icons.settings, size: 18),
                const SizedBox(width: 8),
                Text(l10n.managePresets),
              ],
            ),
          ),
        ];
      },
    );
  }
}
