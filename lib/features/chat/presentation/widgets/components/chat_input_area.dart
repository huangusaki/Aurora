import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../../chat_provider.dart';
import '../../../../settings/presentation/settings_provider.dart';

class DesktopChatInputArea extends ConsumerStatefulWidget {
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
  ConsumerState<DesktopChatInputArea> createState() =>
      _DesktopChatInputAreaState();
}

class _DesktopChatInputAreaState extends ConsumerState<DesktopChatInputArea>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  int _selectedIndex = 0;
  List<String> _filteredModels = [];
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 40.0;
  int? _triggerIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    _scrollController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }




  void _onTextChanged() {
    if (_overlayEntry != null && _triggerIndex != null) {
      // If the trigger character is gone or changed, close the overlay
      if (widget.controller.text.length <= _triggerIndex! ||
          widget.controller.text[_triggerIndex!] != '@') {
        _animateClose();
      }
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _filteredModels = [];
    _selectedIndex = 0;
    _triggerIndex = null;
  }

  Future<void> _animateClose() async {
    if (_overlayEntry == null) return;
    await _animationController.reverse();
    _removeOverlay();
  }

  void _cancelTrigger() {
    if (_triggerIndex != null && _triggerIndex! < widget.controller.text.length) {
      final text = widget.controller.text;
      // Remove the '@' character
      final newText = text.replaceRange(_triggerIndex!, _triggerIndex! + 1, '');
      final newSelection = TextSelection.collapsed(offset: _triggerIndex!);
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: newSelection,
      );
    }
    _animateClose();
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    final double targetOffset = index * _itemHeight;
    final double currentOffset = _scrollController.offset;
    final double viewportHeight = _scrollController.position.viewportDimension;

    if (targetOffset < currentOffset) {
      _scrollController.jumpTo(targetOffset);
    } else if (targetOffset + _itemHeight > currentOffset + viewportHeight) {
      _scrollController.jumpTo(targetOffset + _itemHeight - viewportHeight);
    }
  }

  void _showModelSelector(
      BuildContext context, List<String> models, String currentModel) {
    if (_overlayEntry != null) return;

    // Capture where the '@' is. Assuming current selection is just after '@'.
    // If not valid, fallback to current selection end.
    if (widget.controller.selection.isValid &&
        widget.controller.selection.baseOffset > 0) {
      _triggerIndex = widget.controller.selection.baseOffset - 1;
    } else {
      // Should not happen if triggered by key press correctly, but safe guard
      _triggerIndex = widget.controller.text.length - 1;
      if (_triggerIndex! < 0) _triggerIndex = 0;
    }

    _filteredModels = List.from(models);
    _selectedIndex = _filteredModels.indexOf(currentModel);
    if (_selectedIndex == -1) _selectedIndex = 0;

    // Scroll to initial selection after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(_selectedIndex);
      _animationController.forward(from: 0.0);
    });

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _cancelTrigger,
            ),
            Positioned(
              width: 300,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, -200), // Show above the input
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      color: fluent.FluentTheme.of(context).menuColor,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: fluent.FluentTheme.of(context)
                                .resources
                                .dividerStrokeColorDefault,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shrinkWrap: true,
                              itemCount: _filteredModels.length,
                              itemExtent:
                                  _itemHeight, // Optimize for fixed height
                              itemBuilder: (context, index) {
                                final isSelected = index == _selectedIndex;
                                final theme = fluent.FluentTheme.of(context);
                                return Container(
                                  color: isSelected
                                      ? theme.accentColor.withOpacity(0.1)
                                      : Colors.transparent,
                                  child: fluent.ListTile(
                                    title: Text(
                                      _filteredModels[index],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize:
                                              13), // Adjust font size for compact list
                                    ),
                                    onPressed: () =>
                                        _selectModel(_filteredModels[index]),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
    _scrollToIndex(_selectedIndex);
  }

  void _selectModel(String model) {
    ref.read(settingsProvider.notifier).setSelectedModel(model);

    // Remove the '@' character using the captured trigger index
    if (_triggerIndex != null && 
        _triggerIndex! < widget.controller.text.length &&
        widget.controller.text[_triggerIndex!] == '@') {
      
      final text = widget.controller.text;
      final newText = text.replaceRange(_triggerIndex!, _triggerIndex! + 1, '');
      
      int newSelectionIndex = widget.controller.selection.baseOffset;
      if (newSelectionIndex > _triggerIndex!) {
        newSelectionIndex -= 1;
      }
      
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newSelectionIndex),
      );
    }
    
    _animateClose();
    // Restore focus to input
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final models = settings.providers
            .firstWhere((p) => p.id == settings.activeProviderId,
                orElse: () => settings.providers.first)
            .models ??
        [];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.resources.dividerStrokeColorDefault,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          CompositedTransformTarget(
            link: _layerLink,
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                
                final isControl = HardwareKeyboard.instance.isControlPressed;
                final isShift = HardwareKeyboard.instance.isShiftPressed;

                // Handle Overlay Navigation
                if (_overlayEntry != null) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_selectedIndex < _filteredModels.length - 1) {
                      _selectedIndex++;
                      _updateOverlay();
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (_selectedIndex > 0) {
                      _selectedIndex--;
                      _updateOverlay();
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _selectModel(_filteredModels[_selectedIndex]);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _removeOverlay();
                    return KeyEventResult.handled;
                  }
                }

                // Handle Shortcuts
                if ((isControl && event.logicalKey == LogicalKeyboardKey.keyV) ||
                    (isShift && event.logicalKey == LogicalKeyboardKey.insert)) {
                  widget.onPaste();
                  return KeyEventResult.handled;
                }
                
                if (isControl && event.logicalKey == LogicalKeyboardKey.enter) {
                  widget.onSend();
                  return KeyEventResult.handled;
                }

                // Handle '@' trigger
                if (isShift && event.logicalKey == LogicalKeyboardKey.digit2) {
                   // Using addPostFrameCallback to ensure the character is input first (if we wanted to filter later)
                   // But here we want to trigger on the key press.
                   // Note: TextField will still receive the '@' character.
                   if (_overlayEntry == null && models.isNotEmpty) {
                     _showModelSelector(context, models, settings.selectedModel ?? '');
                   }
                }

                return KeyEventResult.ignored;
              },
              child: fluent.TextBox(
                controller: widget.controller,
                focusNode: _focusNode,
                placeholder: l10n.desktopInputHint,
                maxLines: 5,
                minLines: 1,
                decoration:
                    const fluent.WidgetStatePropertyAll(fluent.BoxDecoration(
                  color: Colors.transparent,
                  border: Border.fromBorderSide(BorderSide.none),
                )),
                highlightColor: Colors.transparent,
                unfocusedColor: Colors.transparent,
                cursorColor: theme.accentColor,
                style: const TextStyle(fontSize: 14),
                foregroundDecoration:
                    const fluent.WidgetStatePropertyAll(fluent.BoxDecoration(
                  border: Border.fromBorderSide(BorderSide.none),
                )),
                // Close overlay if user clicks away or types something else (simple version)
                onTap: _removeOverlay,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.attach, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(
                      theme.resources.textFillColorSecondary),
                ),
                onPressed: widget.onPickFiles,
              ),
              const SizedBox(width: 4),
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.add, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(
                      theme.resources.textFillColorSecondary),
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
                  foregroundColor: fluent.WidgetStatePropertyAll(
                      theme.resources.textFillColorSecondary),
                ),
                onPressed: widget.onPaste,
              ),
              const SizedBox(width: 4),
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.broom, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(
                      theme.resources.textFillColorSecondary),
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
                  widget.onShowToast(
                      newState ? l10n.streamEnabled : l10n.streamDisabled,
                      fluent.FluentIcons.lightning_bolt);
                },
                style: fluent.ButtonStyle(
                  backgroundColor:
                      fluent.WidgetStateProperty.resolveWith((states) {
                    if (settings.isStreamEnabled)
                      return theme.accentColor.withOpacity(0.1);
                    return Colors.transparent;
                  }),
                ),
              ),
              const SizedBox(width: 4),
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
                  widget.onShowToast(
                      newState ? l10n.searchEnabled : l10n.searchDisabled,
                      fluent.FluentIcons.globe);
                },
                style: fluent.ButtonStyle(
                  backgroundColor:
                      fluent.WidgetStateProperty.resolveWith((states) {
                    if (settings.isSearchEnabled)
                      return theme.accentColor.withOpacity(0.1);
                    return Colors.transparent;
                  }),
                ),
              ),
              const Spacer(),
              if (widget.isLoading)
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.stop_solid,
                      size: 16, color: Colors.red),
                  onPressed: () =>
                      ref.read(historyChatProvider).abortGeneration(),
                )
              else
                fluent.IconButton(
                  icon: Icon(fluent.FluentIcons.send,
                      size: 16, color: theme.accentColor),
                  onPressed: widget.onSend,
                  style: fluent.ButtonStyle(
                    backgroundColor:
                        fluent.WidgetStateProperty.resolveWith((states) {
                      if (states.isHovered || states.isPressed)
                        return theme.accentColor.withOpacity(0.1);
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
          Row(
            children: [
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
              InkWell(
                onTap: () {
                  final newState = !settings.isStreamEnabled;
                  ref.read(settingsProvider.notifier).toggleStreamEnabled();
                  onShowToast(
                      newState ? l10n.streamEnabled : l10n.streamDisabled,
                      fluent.FluentIcons.lightning_bolt);
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
              InkWell(
                onTap: () {
                  final newState = !settings.isSearchEnabled;
                  ref.read(historyChatProvider).toggleSearch();
                  onShowToast(
                      newState ? l10n.searchEnabled : l10n.searchDisabled,
                      fluent.FluentIcons.globe);
                },
                onLongPress: () {},
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
              if (isLoading)
                IconButton(
                  icon: const Icon(fluent.FluentIcons.stop, color: Colors.red),
                  onPressed: () =>
                      ref.read(historyChatProvider).abortGeneration(),
                )
              else
                IconButton(
                  icon: Icon(fluent.FluentIcons.send,
                      color: Theme.of(context).colorScheme.primary),
                  onPressed: onSend,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
