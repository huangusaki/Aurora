import 'package:aurora/features/chat/presentation/widgets/mobile_model_switcher_sheet.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ModelSheetHost extends StatefulWidget {
  const _ModelSheetHost({required this.providers});

  final List<ProviderConfig> providers;

  @override
  State<_ModelSheetHost> createState() => _ModelSheetHostState();
}

class _ModelSheetHostState extends State<_ModelSheetHost> {
  late String _activeProviderId;
  late String _selectedModel;

  @override
  void initState() {
    super.initState();
    _activeProviderId = widget.providers.last.id;
    _selectedModel = '${widget.providers.last.id}-model-18';
  }

  @override
  Widget build(BuildContext context) {
    final activeProvider = widget.providers
        .firstWhere((provider) => provider.id == _activeProviderId);
    return Scaffold(
      body: Column(
        children: [
          Text('current $_selectedModel'),
          Expanded(
            child: SizedBox(
              width: 430,
              child: MobileModelSwitcherList(
                providers: widget.providers,
                activeProvider: activeProvider,
                selectedModel: _selectedModel,
                onSwitchModel: (providerId, modelId) async {
                  setState(() {
                    _activeProviderId = providerId;
                    _selectedModel = modelId;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildApp(List<ProviderConfig> providers) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: _ModelSheetHost(providers: providers),
  );
}

List<ProviderConfig> _buildProviders() {
  return [
    ProviderConfig(
      id: 'alpha',
      name: 'Alpha',
      models: List<String>.generate(24, (index) => 'alpha-model-$index'),
      selectedChatModel: 'alpha-model-0',
    ),
    ProviderConfig(
      id: 'beta',
      name: 'Beta',
      models: List<String>.generate(30, (index) => 'beta-model-$index'),
      selectedChatModel: 'beta-model-18',
    ),
  ];
}

Finder _listFinder() {
  return find.byKey(const ValueKey<String>('mobile-model-switcher-list'));
}

Finder _itemFinder(String providerId, String modelId) {
  return find.byKey(ValueKey<String>('mobile-model-item:$providerId:$modelId'));
}

void _expectItemCentered(WidgetTester tester, Finder itemFinder) {
  final listRect = tester.getRect(_listFinder());
  final itemRect = tester.getRect(itemFinder);
  expect(
    (itemRect.center.dy - listRect.center.dy).abs(),
    lessThan(listRect.height * 0.25),
  );
}

void main() {
  testWidgets('selected mobile model is centered when the list is shown',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final providers = _buildProviders();
    await tester.pumpWidget(_buildApp(providers));
    await tester.pumpAndSettle();

    _expectItemCentered(
      tester,
      _itemFinder('beta', 'beta-model-18'),
    );
  });

  testWidgets('changing the selected model re-centers the new selection',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final providers = _buildProviders();
    await tester.pumpWidget(_buildApp(providers));
    await tester.pumpAndSettle();

    await tester.tap(_itemFinder('beta', 'beta-model-21'));
    await tester.pumpAndSettle();

    expect(find.text('current beta-model-21'), findsOneWidget);
    _expectItemCentered(
      tester,
      _itemFinder('beta', 'beta-model-21'),
    );
  });
}
