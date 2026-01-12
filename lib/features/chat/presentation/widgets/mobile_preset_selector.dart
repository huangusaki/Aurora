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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.promptPresets,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.settings, size: 18),
                      label: Text(l10n.managePresets),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MobilePresetManagePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Icon(
                        isDefault ? Icons.check_circle : Icons.circle_outlined,
                        color:
                            isDefault ? Theme.of(context).primaryColor : null,
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
                    if (presets.isNotEmpty) const Divider(),
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
                        onTap: () {
                          ref
                              .read(chatSessionManagerProvider)
                              .getOrCreate(sessionId)
                              .updateSystemPrompt(
                                  preset.systemPrompt, preset.name);
                          Navigator.pop(ctx);
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
