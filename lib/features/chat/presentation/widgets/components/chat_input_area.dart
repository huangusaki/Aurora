
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../../chat_provider.dart';
import '../../../../settings/presentation/settings_provider.dart';
import '../custom_dropdown_overlay.dart'; // for generateColorFromString

class ModelOption {
  final String providerId;
  final String providerName;
  final String modelId;
  final String? color;

  ModelOption({
    required this.providerId,
    required this.providerName,
    required this.modelId,
    this.color,
  });

  String get displayName => '$modelId ($providerName)';
}

class PresetOption {
  final String? id;
  final String name;
  final String systemPrompt;

  PresetOption({
    this.id,
    required this.name,
    required this.systemPrompt,
  });
}

class DesktopChatInputArea extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onPickFiles;
  final Future<void> Function() onPaste;
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
  // Model selector state
  OverlayEntry? _overlayEntry;
  int _selectedIndex = 0;
  List<ModelOption> _allAvailableModels = [];
  List<ModelOption> _filteredModels = [];
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 40.0;
  int? _triggerIndex;
  
  // Preset selector state
  OverlayEntry? _presetOverlayEntry;
  int _presetSelectedIndex = 0;
  List<PresetOption> _filteredPresets = [];
  final ScrollController _presetScrollController = ScrollController();
  int? _presetTriggerIndex;
  
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
      duration: const Duration(milliseconds: 100),
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
    _removePresetOverlay();
    _scrollController.dispose();
    _presetScrollController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Handle model overlay (@)
    if (_triggerIndex != null) {
      final text = widget.controller.text;
      final cursor = widget.controller.selection.baseOffset;

      // Close if cursor moves before trigger
      if (cursor <= _triggerIndex! || text.length <= _triggerIndex! || text[_triggerIndex!] != '@') {
        _animateClose();
        return;
      }

      // Calculate search query
      final query = text.substring(_triggerIndex! + 1, cursor).toLowerCase();

      // Close if query contains space
      if (query.contains(' ')) {
        _animateClose();
        return;
      }

      // Filter models
      final newFiltered = _allAvailableModels
          .where((m) =>
              m.modelId.toLowerCase().contains(query) ||
              m.providerName.toLowerCase().contains(query))
          .toList();

      if (newFiltered.isEmpty) {
        if (_overlayEntry != null) {
          _removeOverlayOnly(); // Hide but keep state
        }
      } else {
        _filteredModels = newFiltered;
        _selectedIndex = _selectedIndex.clamp(0, _filteredModels.length - 1);
        if (_overlayEntry == null) {
          // Re-show if matches found and we have a valid trigger
          _showOverlayOnly();
        } else {
          _updateOverlay();
        }
      }
    }
    // Handle preset overlay (/)
    if (_presetOverlayEntry != null && _presetTriggerIndex != null) {
      if (widget.controller.text.length <= _presetTriggerIndex! ||
          widget.controller.text[_presetTriggerIndex!] != '/' ||
          widget.controller.selection.baseOffset <= _presetTriggerIndex! ||
          widget.controller.selection.baseOffset > _presetTriggerIndex! + 1) {
        _animateClosePreset();
      }
    }
  }

  void _removeOverlay() {
    _removeOverlayOnly();
    _allAvailableModels = [];
    _filteredModels = [];
    _selectedIndex = 0;
    _triggerIndex = null;
  }

  void _removeOverlayOnly() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlayOnly() {
    if (_overlayEntry != null || _triggerIndex == null) return;
    _overlayEntry = _createModelOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward(from: 0.0);
  }

  Future<void> _animateClose() async {
    if (_overlayEntry == null) return;
    _animationController
        .reverse(); // Don't await - let animation play while overlay is removed
    _removeOverlay();
  }

  void _cancelTrigger() {
    if (_triggerIndex != null &&
        _triggerIndex! < widget.controller.text.length) {
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

  // ========== Preset Overlay Methods ==========
  
  void _removePresetOverlay() {
    _presetOverlayEntry?.remove();
    _presetOverlayEntry = null;
    _filteredPresets = [];
    _presetSelectedIndex = 0;
    _presetTriggerIndex = null;
  }

  Future<void> _animateClosePreset() async {
    if (_presetOverlayEntry == null) return;
    _animationController.reverse();
    _removePresetOverlay();
  }

  void _cancelPresetTrigger() {
    if (_presetTriggerIndex != null &&
        _presetTriggerIndex! < widget.controller.text.length) {
      final text = widget.controller.text;
      // Remove the '/' character
      final newText = text.replaceRange(_presetTriggerIndex!, _presetTriggerIndex! + 1, '');
      final newSelection = TextSelection.collapsed(offset: _presetTriggerIndex!);
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: newSelection,
      );
    }
    _animateClosePreset();
  }

  void _scrollToPresetIndex(int index) {
    if (!_presetScrollController.hasClients) return;

    final double targetOffset = index * _itemHeight;
    final double currentOffset = _presetScrollController.offset;
    final double viewportHeight = _presetScrollController.position.viewportDimension;

    if (targetOffset < currentOffset) {
      _presetScrollController.jumpTo(targetOffset);
    } else if (targetOffset + _itemHeight > currentOffset + viewportHeight) {
      _presetScrollController.jumpTo(targetOffset + _itemHeight - viewportHeight);
    }
  }

  void _showPresetSelector(BuildContext context, List<PresetOption> presets) {
    if (_presetOverlayEntry != null) return;

    // Capture where the '/' WILL BE inserted
    if (widget.controller.selection.isValid) {
      _presetTriggerIndex = widget.controller.selection.baseOffset;
    } else {
      _presetTriggerIndex = widget.controller.text.length;
    }

    _filteredPresets = List.from(presets);
    _presetSelectedIndex = 0;

    // Scroll to initial selection after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToPresetIndex(_presetSelectedIndex);
      _animationController.forward(from: 0.0);
    });

    _presetOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _cancelPresetTrigger,
            ),
            Positioned(
              width: 300,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.bottomLeft,
                offset: const Offset(0, -8),
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
                              controller: _presetScrollController,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shrinkWrap: true,
                              itemCount: _filteredPresets.length,
                              itemExtent: _itemHeight,
                              itemBuilder: (context, index) {
                                final isSelected = index == _presetSelectedIndex;
                                final preset = _filteredPresets[index];
                                final theme = fluent.FluentTheme.of(context);
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: isSelected
                                        ? theme.accentColor.withOpacity(0.1)
                                        : Colors.transparent,
                                  ),
                                  child: fluent.ListTile(
                                    title: Text(
                                      preset.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    onPressed: () =>
                                        _selectPreset(_filteredPresets[index]),
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

    Overlay.of(context).insert(_presetOverlayEntry!);
  }

  void _updatePresetOverlay() {
    _presetOverlayEntry?.markNeedsBuild();
    _scrollToPresetIndex(_presetSelectedIndex);
  }

  void _selectPreset(PresetOption option) {
    final sessionId = ref.read(selectedHistorySessionIdProvider);
    if (sessionId != null) {
      ref
          .read(chatSessionManagerProvider)
          .getOrCreate(sessionId)
          .updateSystemPrompt(option.systemPrompt, option.id == null ? null : option.name);
    }

    // Remove the '/' character using the captured trigger index
    if (_presetTriggerIndex != null &&
        _presetTriggerIndex! < widget.controller.text.length &&
        widget.controller.text[_presetTriggerIndex!] == '/') {
      final text = widget.controller.text;
      final newText = text.replaceRange(_presetTriggerIndex!, _presetTriggerIndex! + 1, '');

      int newSelectionIndex = widget.controller.selection.baseOffset;
      if (newSelectionIndex > _presetTriggerIndex!) {
        newSelectionIndex -= 1;
      }

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newSelectionIndex),
      );
    }

    _animateClosePreset();
    // Restore focus to input
    _focusNode.requestFocus();
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
      BuildContext context, List<ModelOption> models, String currentModelId) {
    if (_overlayEntry != null) return;

    // Capture where the '@' WILL BE inserted (key event fires before character is typed)
    // Current cursor position is where @ will appear
    if (widget.controller.selection.isValid) {
      _triggerIndex = widget.controller.selection.baseOffset;
    } else {
      _triggerIndex = widget.controller.text.length;
    }

    _allAvailableModels = List.from(models);
    _filteredModels = List.from(models);
    _selectedIndex =
        _filteredModels.indexWhere((m) => m.modelId == currentModelId);
    if (_selectedIndex == -1) _selectedIndex = 0;

    // Scroll to initial selection after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(_selectedIndex);
      _animationController.forward(from: 0.0);
    });

    _overlayEntry = _createModelOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createModelOverlay() {
    return OverlayEntry(
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
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.bottomLeft,
                offset: const Offset(0, -8), // Grow upwards from the input
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
                              itemExtent: _itemHeight,
                              itemBuilder: (context, index) {
                                final isSelected = index == _selectedIndex;
                                final model = _filteredModels[index];
                                final theme = fluent.FluentTheme.of(context);
                                Color? itemColor;
                                if (model.color != null &&
                                    model.color!.isNotEmpty) {
                                  itemColor = Color(int.tryParse(model.color!
                                          .replaceFirst('#', '0xFF')) ??
                                      0xFF000000);
                                }
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: isSelected
                                        ? (itemColor?.withOpacity(0.3) ??
                                            theme.accentColor.withOpacity(0.1))
                                        : (itemColor?.withOpacity(0.1) ??
                                            Colors.transparent),
                                  ),
                                  child: fluent.ListTile(
                                    title: Text(
                                      model.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
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
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
    _scrollToIndex(_selectedIndex);
  }

  void _selectModel(ModelOption option) async {
    // If the selected model belongs to a different provider, switch provider first
    final settings = ref.read(settingsProvider);
    if (settings.activeProviderId != option.providerId) {
      await ref
          .read(settingsProvider.notifier)
          .selectProvider(option.providerId);
    }

    ref.read(settingsProvider.notifier).setSelectedModel(option.modelId);

    // Remove the '@query' string
    if (_triggerIndex != null &&
        _triggerIndex! < widget.controller.text.length &&
        widget.controller.text[_triggerIndex!] == '@') {
      final text = widget.controller.text;
      final cursor = widget.controller.selection.baseOffset;
      // Range is from '@' to the current cursor (where the query ends)
      final newText = text.replaceRange(_triggerIndex!, cursor, '');

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: _triggerIndex!),
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

    // Aggregate models from all enabled providers
    final List<ModelOption> allModels = [];
    for (final provider in settings.providers) {
      if (provider.isEnabled && provider.models.isNotEmpty) {
        // Get color: use set color or generate from provider ID
        String? colorValue = provider.color;
        if (colorValue == null || colorValue.isEmpty) {
          // Generate a hex color string from the provider ID
          final generatedColor = generateColorFromString(provider.id);
          colorValue =
              '#${generatedColor.value.toRadixString(16).substring(2).toUpperCase()}';
        }
        for (final model in provider.models) {
          if (!provider.isModelEnabled(model)) continue;
          allModels.add(ModelOption(
            providerId: provider.id,
            providerName: provider.name,
            modelId: model,
            color: colorValue,
          ));
        }
      }
    }

    // Aggregate presets for '/' trigger
    final List<PresetOption> allPresets = [
      PresetOption(id: null, name: l10n.defaultPreset, systemPrompt: ''),
      ...settings.presets.map((p) => PresetOption(
        id: p.id,
        name: p.name,
        systemPrompt: p.systemPrompt,
      )),
    ];

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
                // Allow both KeyDownEvent and KeyRepeatEvent for continuous scrolling
                if (event is! KeyDownEvent && event is! KeyRepeatEvent)
                  return KeyEventResult.ignored;

                final isControl = HardwareKeyboard.instance.isControlPressed;
                final isShift = HardwareKeyboard.instance.isShiftPressed;

                // Handle Model Overlay Navigation (@)
                if (_overlayEntry != null) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    // Cycle to first item if at the end
                    if (_selectedIndex < _filteredModels.length - 1) {
                      _selectedIndex++;
                    } else {
                      _selectedIndex = 0;
                    }
                    _updateOverlay();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    // Cycle to last item if at the beginning
                    if (_selectedIndex > 0) {
                      _selectedIndex--;
                    } else {
                      _selectedIndex = _filteredModels.length - 1;
                    }
                    _updateOverlay();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _selectModel(_filteredModels[_selectedIndex]);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _removeOverlay();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    // Close overlay when cursor moves horizontally
                    _animateClose();
                    return KeyEventResult
                        .ignored; // Let the text field handle cursor movement
                  }
                }

                // Handle Preset Overlay Navigation (/)
                if (_presetOverlayEntry != null) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_presetSelectedIndex < _filteredPresets.length - 1) {
                      _presetSelectedIndex++;
                    } else {
                      _presetSelectedIndex = 0;
                    }
                    _updatePresetOverlay();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (_presetSelectedIndex > 0) {
                      _presetSelectedIndex--;
                    } else {
                      _presetSelectedIndex = _filteredPresets.length - 1;
                    }
                    _updatePresetOverlay();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _selectPreset(_filteredPresets[_presetSelectedIndex]);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _cancelPresetTrigger();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    _animateClosePreset();
                    return KeyEventResult.ignored;
                  }
                }

                // Handle Shortcuts
                if ((isControl &&
                        event.logicalKey == LogicalKeyboardKey.keyV) ||
                    (isShift &&
                        event.logicalKey == LogicalKeyboardKey.insert)) {
                  widget.onPaste().then((_) {
                    // Restore focus after paste
                    _focusNode.requestFocus();
                  });
                  return KeyEventResult.handled;
                }

                if (isControl && event.logicalKey == LogicalKeyboardKey.enter) {
                  widget.onSend();
                  return KeyEventResult.handled;
                }

                // Handle '@' trigger
                if (isShift && event.logicalKey == LogicalKeyboardKey.digit2) {
                  if (_overlayEntry != null) {
                    // If overlay is already open, update trigger index synchronously
                    // Current cursor position is where the new @ will be inserted
                    if (widget.controller.selection.isValid) {
                      _triggerIndex = widget.controller.selection.baseOffset;
                    }
                  } else if (allModels.isNotEmpty) {
                    // Show model selector for the first '@'
                    _showModelSelector(
                        context, allModels, settings.selectedModel ?? '');
                  }
                }

                // Handle '/' trigger for preset selector
                if (event.character == '/') {
                  if (_presetOverlayEntry != null) {
                    // If preset overlay is already open, update trigger index
                    if (widget.controller.selection.isValid) {
                      _presetTriggerIndex = widget.controller.selection.baseOffset;
                    }
                  } else if (allPresets.isNotEmpty) {
                    // Show preset selector for the first '/'
                    _showPresetSelector(context, allPresets);
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
                icon: const Icon(AuroraIcons.attach, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(
                      theme.resources.textFillColorSecondary),
                ),
                onPressed: widget.onPickFiles,
              ),
              const SizedBox(width: 4),
              fluent.IconButton(
                icon: const Icon(AuroraIcons.add, size: 16),
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
                icon: const Icon(AuroraIcons.copy, size: 16),
                style: fluent.ButtonStyle(
                  foregroundColor: fluent.WidgetStatePropertyAll(
                      theme.resources.textFillColorSecondary),
                ),
                onPressed: () {
                  widget.onPaste().then((_) {
                    _focusNode.requestFocus();
                  });
                },
              ),
              const SizedBox(width: 4),
              fluent.IconButton(
                icon: const Icon(AuroraIcons.broom, size: 16),
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
                  AuroraIcons.zap,
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
                      AuroraIcons.zap);
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
                  AuroraIcons.globe,
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
                      AuroraIcons.globe);
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
                  icon: const Icon(AuroraIcons.stop,
                      size: 16, color: Colors.red),
                  onPressed: () =>
                      ref.read(historyChatProvider).abortGeneration(),
                )
              else
                fluent.IconButton(
                   icon: Icon(AuroraIcons.send,
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
                    AuroraIcons.attach,
                    color: Theme.of(context).colorScheme.outline,
                    size: 18,
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
                    AuroraIcons.broom,
                    color: Theme.of(context).colorScheme.outline,
                    size: 18,
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
                      AuroraIcons.zap);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    AuroraIcons.zap,
                    color: settings.isStreamEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    size: 18,
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
                      AuroraIcons.globe);
                },
                onLongPress: () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    AuroraIcons.globe,
                    color: settings.isSearchEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              if (isLoading)
                IconButton(
                  icon: const Icon(AuroraIcons.stop,
                      color: Colors.red, size: 18),
                  onPressed: () =>
                      ref.read(historyChatProvider).abortGeneration(),
                )
              else
                IconButton(
                  icon: Icon(AuroraIcons.send,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                  onPressed: onSend,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
