import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'assistant_provider.dart';
import '../domain/assistant.dart';
import 'widgets/assistant_avatar.dart';
import 'mobile_assistant_detail_page.dart';
import '../../settings/presentation/widgets/mobile_settings_widgets.dart';

class MobileAssistantPage extends ConsumerWidget {
  final VoidCallback? onBack;

  const MobileAssistantPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistantState = ref.watch(assistantProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.assistantSystem),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: onBack,
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: MobileSettingsSection(
              children: [
                MobileSettingsTile(
                  leading: const Icon(Icons.autorenew, size: 24),
                  title: l10n.defaultAssistant,
                  subtitle: l10n.noSpecificAssistant,
                  showChevron: false,
                  trailing: IconButton(
                    icon: Icon(
                      ref.watch(assistantProvider).selectedAssistantId == null
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: ref.watch(assistantProvider).selectedAssistantId ==
                              null
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    onPressed: () {
                      ref
                          .read(assistantProvider.notifier)
                          .selectAssistant(null);
                    },
                  ),
                  onTap: () {
                    ref.read(assistantProvider.notifier).selectAssistant(null);
                  },
                ),
              ],
            ),
          ),
          ...assistantState.assistants.map((assistant) {
            final isSelected =
                ref.watch(assistantProvider).selectedAssistantId ==
                    assistant.id;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: MobileSettingsSection(
                children: [
                  MobileSettingsTile(
                    leading: _buildAvatar(context, assistant, size: 36),
                    title: assistant.name,
                    subtitle: assistant.description.isNotEmpty
                        ? assistant.description
                        : l10n.noAssistantDescription,
                    showChevron: false,
                    trailing: IconButton(
                      icon: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                      onPressed: () {
                        ref
                            .read(assistantProvider.notifier)
                            .selectAssistant(assistant.id);
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (context, animation,
                                  secondaryAnimation) =>
                              MobileAssistantDetailPage(assistant: assistant),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newAssistant =
              await ref.read(assistantProvider.notifier).createAssistant(
                    name: l10n.newAssistant,
                  );
          if (context.mounted) {
            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MobileAssistantDetailPage(assistant: newAssistant),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Assistant assistant,
      {double size = 40}) {
    return AssistantAvatar(assistant: assistant, size: size);
  }
}
