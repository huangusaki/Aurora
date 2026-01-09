import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';

import '../../chat_provider.dart';
import '../../../../settings/presentation/settings_provider.dart';

class DesktopChatInputArea extends ConsumerWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onPickFiles;
  final VoidCallback onPaste;
  final Function(String message, IconData icon) onShowToast;

  const DesktopChatInputArea({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onPickFiles,
    required this.onPaste,
    required this.onShowToast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20), // Matches capsule look
        border: Border.all(
          color: theme.resources.dividerStrokeColorDefault,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // Tighter vertical padding
      child: Column(
        children: [
          Focus(
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final isControl = HardwareKeyboard.instance.isControlPressed;
              final isShift = HardwareKeyboard.instance.isShiftPressed;
              if ((isControl && event.logicalKey == LogicalKeyboardKey.keyV) ||
                  (isShift && event.logicalKey == LogicalKeyboardKey.insert)) {
                onPaste();
                return KeyEventResult.handled;
              }
              if (isControl && event.logicalKey == LogicalKeyboardKey.enter) {
                onSend();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: fluent.TextBox(
              controller: controller,
              placeholder: l10n.desktopInputHint,
              maxLines: 5,
              minLines: 1,
              // Completely transparent decoration to avoid "nested box" look
              decoration: const fluent.WidgetStatePropertyAll(fluent.BoxDecoration(
                color: Colors.transparent,
                border: Border.fromBorderSide(BorderSide.none),
              )),
              highlightColor: Colors.transparent,
              unfocusedColor: Colors.transparent,
              cursorColor: theme.accentColor,
              style: const TextStyle(fontSize: 14),
              foregroundDecoration: const fluent.WidgetStatePropertyAll(fluent.BoxDecoration(
                border: Border.fromBorderSide(BorderSide.none),
              )),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.attach, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(theme.resources.textFillColorSecondary),
                ),
                onPressed: onPickFiles,
              ),
              const SizedBox(width: 4),
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.add, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(theme.resources.textFillColorSecondary),
                ),
                onPressed: () {
                  ref.read(selectedHistorySessionIdProvider.notifier).state =
                      'new_chat';
                },
              ),
              const SizedBox(width: 4),
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.paste, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(theme.resources.textFillColorSecondary),
                ),
                onPressed: onPaste,
              ),
              const SizedBox(width: 4),

              // Clear Context
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.broom, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(theme.resources.textFillColorSecondary),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => fluent.ContentDialog(
                      title: Text(l10n.clearContext),
                      content: Text(l10n.clearContextConfirm),
                      actions: [
                        fluent.Button(
                          child: Text(l10n.cancel),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        fluent.FilledButton(
                          child: Text(l10n.confirm),
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(historyChatProvider).clearContext();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 4),

              // Stream Toggle
              fluent.IconButton(
                icon: Icon(
                  fluent.FluentIcons.lightning_bolt, 
                  size: 16,
                  color: settings.isStreamEnabled 
                      ? theme.accentColor 
                      : theme.resources.textFillColorSecondary,
                ),
                onPressed: () {
                  final newState = !settings.isStreamEnabled;
                  ref.read(settingsProvider.notifier).toggleStreamEnabled();
                  onShowToast(newState ? l10n.streamEnabled : l10n.streamDisabled, fluent.FluentIcons.lightning_bolt);
                },
                style: fluent.ButtonStyle(
                  backgroundColor: fluent.WidgetStateProperty.resolveWith((states) {
                     if (settings.isStreamEnabled) return theme.accentColor.withOpacity(0.1);
                     return Colors.transparent;
                  }),
                ),
              ),

              const SizedBox(width: 4),

              // Search Toggle (Simplified)
              fluent.IconButton(
                icon: Icon(
                  fluent.FluentIcons.globe,
                  size: 16,
                  color: settings.isSearchEnabled 
                      ? theme.accentColor 
                      : theme.resources.textFillColorSecondary,
                ),
                onPressed: () {
                   final newState = !settings.isSearchEnabled;
                   ref.read(historyChatProvider).toggleSearch();
                   onShowToast(newState ? l10n.searchEnabled : l10n.searchDisabled, fluent.FluentIcons.globe);
                },
                style: fluent.ButtonStyle(
                  backgroundColor: fluent.WidgetStateProperty.resolveWith((states) {
                     if (settings.isSearchEnabled) return theme.accentColor.withOpacity(0.1);
                     return Colors.transparent;
                  }),
                ),
              ),
              
              const Spacer(),
              
              if (isLoading)
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.stop_solid, size: 16, color: Colors.red),
                  onPressed: () => ref.read(historyChatProvider).abortGeneration(),
                )
              else
                fluent.IconButton(
                  icon: Icon(fluent.FluentIcons.send, size: 16, color: theme.accentColor),
                  onPressed: onSend,
                  style: fluent.ButtonStyle(
                    backgroundColor: fluent.WidgetStateProperty.resolveWith((states) {
                       if (states.isHovered || states.isPressed) return theme.accentColor.withOpacity(0.1);
                       return Colors.transparent;
                    }),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class MobileChatInputArea extends ConsumerWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final Function(String message, IconData icon) onShowToast;

  const MobileChatInputArea({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onAttachmentTap,
    required this.onShowToast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Text Field
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextField(
              controller: controller,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                hintText: l10n.mobileInputHint,
                hintStyle: const TextStyle(fontSize: 15, color: Colors.grey),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 16),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(height: 12),
          
          // 2. Action Icons Row
          Row(
            children: [
              // Left Side: Feature Toggles
              
              // Attachment Button
              InkWell(
                onTap: onAttachmentTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    fluent.FluentIcons.attach,
                    color: Theme.of(context).colorScheme.outline,
                    size: 26,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Clear Context
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.clearContext),
                      content: Text(l10n.clearContextConfirm),
                      actions: [
                        TextButton(
                          child: Text(l10n.cancel),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        FilledButton(
                          child: Text(l10n.confirm),
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(historyChatProvider).clearContext();
                          },
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    fluent.FluentIcons.broom,
                    color: Theme.of(context).colorScheme.outline,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Stream Toggle
              InkWell(
                onTap: () {
                  final newState = !settings.isStreamEnabled;
                  ref.read(settingsProvider.notifier).toggleStreamEnabled();
                  onShowToast(newState ? l10n.streamEnabled : l10n.streamDisabled, fluent.FluentIcons.lightning_bolt);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    fluent.FluentIcons.lightning_bolt,
                    color: settings.isStreamEnabled 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Search Toggle
               InkWell(
                onTap: () {
                   final newState = !settings.isSearchEnabled;
                   ref.read(historyChatProvider).toggleSearch();
                   onShowToast(newState ? l10n.searchEnabled : l10n.searchDisabled, fluent.FluentIcons.globe);
                },
                onLongPress: () {
                   // Todo: Show bottom sheet for engine selection
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    fluent.FluentIcons.globe,
                    color: settings.isSearchEnabled 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Send Button (Action depends on loading state)
              if (isLoading)
                IconButton(
                  icon: const Icon(fluent.FluentIcons.stop, color: Colors.red),
                  onPressed: () => ref.read(historyChatProvider).abortGeneration(),
                )
              else
                IconButton(
                  icon: Icon(fluent.FluentIcons.send, color: Theme.of(context).colorScheme.primary),
                  onPressed: onSend,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
