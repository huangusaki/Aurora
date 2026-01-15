import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/settings_provider.dart';
import 'custom_dropdown_overlay.dart';
import '../chat_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';

class ModelSelector extends ConsumerStatefulWidget {
  final bool isWindows;
  const ModelSelector({super.key, this.isWindows = true});
  @override
  ConsumerState<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends ConsumerState<ModelSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final theme = fluent.FluentTheme.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => CustomDropdownOverlay(
        onDismiss: _removeOverlay,
        layerLink: _layerLink,
        offset: const Offset(0, 36),
        child: AnimatedDropdownList(
          backgroundColor: theme.menuColor,
          borderColor: theme.resources.surfaceStrokeColorDefault,
          width: 280,
          coloredItems: _buildColoredItems(theme),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  List<ColoredDropdownItem> _buildColoredItems(fluent.FluentThemeData theme) {
    final settingsState = ref.watch(settingsProvider);
    final selected = settingsState.selectedModel;
    final activeProvider = settingsState.activeProvider;
    final providers = settingsState.providers;
    final List<ColoredDropdownItem> items = [];
    Future<void> switchModel(String providerId, String model) async {
      _removeOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(settingsProvider.notifier).selectProvider(providerId);
        await ref.read(settingsProvider.notifier).setSelectedModel(model);
      });
    }

    for (final provider in providers) {
      if (!provider.isEnabled || provider.models.isEmpty) continue;

      // Get provider color: use set color or generate from ID
      Color providerColor;
      if (provider.color != null && provider.color!.isNotEmpty) {
        providerColor = Color(
            int.tryParse(provider.color!.replaceFirst('#', '0xFF')) ??
                0xFF000000);
      } else {
        providerColor = generateColorFromString(provider.id);
      }

      // Add provider header
      items.add(ColoredDropdownItem(
        label: provider.name,
        backgroundColor: providerColor,
        isBold: true,
        textColor: theme.typography.caption?.color ?? fluent.Colors.grey,
      ));

      // Add models
      for (final model in provider.models) {
        final isSelected =
            activeProvider.id == provider.id && selected == model;
        items.add(ColoredDropdownItem(
          label: model,
          onPressed: () => switchModel(provider.id, model),
          backgroundColor: providerColor,
          isSelected: isSelected,
          textColor: isSelected ? theme.accentColor : null,
          icon: isSelected
              ? fluent.Icon(fluent.FluentIcons.check_mark,
                  size: 12, color: theme.accentColor)
              : null,
        ));
      }

      // Add separator
      if (provider != providers.last &&
          providers.any((p) =>
              providers.indexOf(p) > providers.indexOf(provider) &&
              p.models.isNotEmpty)) {
        items.add(const DropdownSeparator());
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final selected = settingsState.selectedModel;
    final activeProvider = settingsState.activeProvider;
    final providers = settingsState.providers;
    final hasAnyModels = providers.any((p) => p.models.isNotEmpty);
    if (!hasAnyModels) {
      return const SizedBox.shrink();
    }
    Future<void> switchModel(String providerId, String model) async {
      await ref.read(settingsProvider.notifier).selectProvider(providerId);
      await ref.read(settingsProvider.notifier).setSelectedModel(model);
    }

    if (widget.isWindows) {
      final theme = fluent.FluentTheme.of(context);
      return CompositedTransformTarget(
        link: _layerLink,
        child: fluent.HoverButton(
          onPressed: _toggleDropdown,
          builder: (context, states) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isOpen || states.isHovering
                    ? theme.resources.subtleFillColorSecondary
                    : fluent.Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 200,
                    child: fluent.Text(
                      selected ?? AppLocalizations.of(context)!.selectModel,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (activeProvider.name.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    fluent.Text('|',
                        style: TextStyle(
                            color: fluent.Colors.grey.withOpacity(0.5))),
                    const SizedBox(width: 8),
                    fluent.Text(
                      activeProvider.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.typography.caption?.color,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  fluent.Icon(
                      _isOpen
                          ? fluent.FluentIcons.chevron_up
                          : fluent.FluentIcons.chevron_down,
                      size: 8,
                      color: theme.typography.caption?.color),
                ],
              ),
            );
          },
        ),
      );
    } else {
      final List<PopupMenuEntry<String>> items = [];
      for (final provider in providers) {
        if (!provider.isEnabled || provider.models.isEmpty) continue;
        items.add(PopupMenuItem<String>(
          enabled: false,
          child: Text(provider.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
        ));
        for (final model in provider.models) {
          items.add(PopupMenuItem<String>(
            value: '${provider.id}|$model',
            height: 32,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(model),
                  if (activeProvider.id == provider.id && selected == model)
                    const Icon(Icons.check, size: 16, color: Colors.blue),
                ],
              ),
            ),
          ));
        }
        if (provider != providers.last) {
          items.add(const PopupMenuDivider());
        }
      }
      return PopupMenuButton<String>(
        tooltip: AppLocalizations.of(context)!.switchModel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) {
          final parts = value.split('|');
          if (parts.length == 2) {
            switchModel(parts[0], parts[1]);
          }
        },
        itemBuilder: (context) => items,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  selected ?? AppLocalizations.of(context)!.selectModel,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (activeProvider.name.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('|',
                    style: TextStyle(color: Colors.grey.withOpacity(0.5))),
                const SizedBox(width: 8),
                Text(
                  activeProvider.name.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      );
    }
  }
}
