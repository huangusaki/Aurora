import 'package:aurora/features/assistant/presentation/widgets/assistant_avatar.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/features/assistant/presentation/assistant_provider.dart';

import 'package:aurora/l10n/app_localizations.dart';

import 'custom_dropdown_overlay.dart';
import 'selector_overlay_scaffold.dart';

class AssistantSelector extends SelectorOverlayScaffold {
  final String sessionId;
  const AssistantSelector({super.key, required this.sessionId})
      : super(overlayWidth: 220);

  @override
  SelectorTriggerContentBuilder get triggerContentBuilder =>
      _buildTriggerContent;

  @override
  SelectorOverlayItemsBuilder get overlayItemsBuilder => _buildDropdownItems;

  Widget _buildTriggerContent(BuildContext context, WidgetRef ref,
      fluent.FluentThemeData theme, AppLocalizations l10n) {
    final assistantState = ref.watch(assistantProvider);
    final selectedId = assistantState.selectedAssistantId;
    final assistants = assistantState.assistants;
    final selectedAssistant =
        assistants.where((a) => a.id == selectedId).firstOrNull;
    final textStyle = theme.typography.body?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AssistantAvatar(
          assistant: selectedAssistant,
          size: 18,
        ),
        const SizedBox(width: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 120),
          child: fluent.Text(
            selectedAssistant?.name ?? l10n.defaultAssistant,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<ColoredDropdownItem> _buildDropdownItems(
    BuildContext context,
    WidgetRef ref,
    fluent.FluentThemeData theme,
    AppLocalizations l10n,
    VoidCallback dismissOverlay,
  ) {
    final assistants = ref.watch(assistantProvider).assistants;
    final List<ColoredDropdownItem> items = [];

    items.add(ColoredDropdownItem(
      onPressed: () {
        ref.read(assistantProvider.notifier).selectAssistant(null);
        dismissOverlay();
      },
      child: Row(
        children: [
          AssistantAvatar(assistant: null, size: 24),
          const SizedBox(width: 8),
          Text(l10n.defaultAssistant,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    ));

    if (assistants.isEmpty) {
      return items;
    }

    for (final assistant in assistants) {
      items.add(ColoredDropdownItem(
        onPressed: () {
          ref.read(assistantProvider.notifier).selectAssistant(assistant.id);
          dismissOverlay();
        },
        child: Row(
          children: [
            AssistantAvatar(
              assistant: assistant,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(assistant.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (assistant.description.isNotEmpty)
                    Text(assistant.description,
                        style: TextStyle(
                            fontSize: 10,
                            color: theme.typography.caption?.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    return items;
  }
}
