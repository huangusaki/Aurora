import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:flutter/material.dart';

typedef MobileModelSwitchCallback = Future<void> Function(
  String providerId,
  String modelId,
);

Future<void> showMobileModelSwitcherSheet({
  required BuildContext context,
  required List<ProviderConfig> providers,
  required ProviderConfig activeProvider,
  required String? selectedModel,
  required MobileModelSwitchCallback onSwitchModel,
  String? title,
  double selectedAlignment = 0.5,
}) {
  final l10n = AppLocalizations.of(context)!;
  return AuroraBottomSheet.show<void>(
    context: context,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(
            context,
            title ?? l10n.switchModel,
          ),
          const Divider(height: 1),
          Flexible(
            child: MobileModelSwitcherList(
              providers: providers,
              activeProvider: activeProvider,
              selectedModel: selectedModel,
              selectedAlignment: selectedAlignment,
              onSwitchModel: (providerId, modelId) async {
                Navigator.pop(sheetContext);
                await onSwitchModel(providerId, modelId);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

class MobileModelSwitcherList extends StatefulWidget {
  const MobileModelSwitcherList({
    super.key,
    required this.providers,
    required this.activeProvider,
    required this.selectedModel,
    required this.onSwitchModel,
    this.selectedAlignment = 0.5,
  });

  final List<ProviderConfig> providers;
  final ProviderConfig activeProvider;
  final String? selectedModel;
  final MobileModelSwitchCallback onSwitchModel;
  final double selectedAlignment;

  @override
  State<MobileModelSwitcherList> createState() =>
      _MobileModelSwitcherListState();
}

class _MobileModelSwitcherListState extends State<MobileModelSwitcherList> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _selectedItemKey = GlobalKey();
  bool _didScheduleSelectedScroll = false;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToSelectedItem();
  }

  @override
  void didUpdateWidget(covariant MobileModelSwitcherList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProvider.id != widget.activeProvider.id ||
        oldWidget.selectedModel != widget.selectedModel ||
        oldWidget.providers != widget.providers) {
      _didScheduleSelectedScroll = false;
      _scheduleScrollToSelectedItem();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToSelectedItem() {
    if (_didScheduleSelectedScroll) return;
    _didScheduleSelectedScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelectedItem();
    });
  }

  void _scrollToSelectedItem() {
    final selectedContext = _selectedItemKey.currentContext;
    if (selectedContext == null) return;
    Scrollable.ensureVisible(
      selectedContext,
      alignment: widget.selectedAlignment,
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabledProviders = widget.providers
        .where((provider) => provider.isEnabled && provider.models.isNotEmpty)
        .toList(growable: false);

    return SingleChildScrollView(
      key: const ValueKey<String>('mobile-model-switcher-list'),
      controller: _scrollController,
      child: Column(
        children: [
          for (final provider in enabledProviders) ...[
            ListTile(
              dense: true,
              enabled: false,
              title: Text(
                provider.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            for (final model in provider.models)
              if (provider.isModelEnabled(model))
                Builder(
                  builder: (context) {
                    final isSelected =
                        widget.activeProvider.id == provider.id &&
                            widget.selectedModel == model;
                    Widget tile = ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 32, right: 16),
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                      ),
                      title: Text(model),
                      onTap: () => widget.onSwitchModel(provider.id, model),
                    );
                    if (isSelected) {
                      tile = KeyedSubtree(
                        key: _selectedItemKey,
                        child: tile,
                      );
                    }
                    return KeyedSubtree(
                      key: ValueKey<String>(
                        'mobile-model-item:${provider.id}:$model',
                      ),
                      child: tile,
                    );
                  },
                ),
            if (provider != enabledProviders.last) const Divider(),
          ],
        ],
      ),
    );
  }
}
