import 'package:aurora/features/chat/data/chat_storage.dart';
import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/features/chat/presentation/chat_provider.dart';
import 'package:aurora/features/chat/presentation/widgets/chat_view.dart';
import 'package:aurora/features/settings/data/settings_storage.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatStorage extends Fake implements ChatStorage {}

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier()
      : super(
          storage: SettingsStorage(),
          initialProviders: [
            ProviderConfig(
              id: 'test',
              name: 'Test Provider',
              selectedChatModel: 'gemini-3.1-flash-image-preview',
            ),
          ],
          initialActiveId: 'test',
          language: 'en',
        );

  @override
  Future<void> loadPresets() async {}
}

Widget _buildApp(ProviderContainer container, {required String sessionId}) {
  return UncontrolledProviderScope(
    container: container,
    child: FluentApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FluentLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: material.Material(
        type: material.MaterialType.transparency,
        child: NavigationView(
          content: ScaffoldPage(
            content: ChatView(sessionId: sessionId),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('chat view leaves thinking state after a failed request',
      (tester) async {
    final settingsNotifier = _TestSettingsNotifier();
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => settingsNotifier),
        chatStorageProvider.overrideWithValue(_FakeChatStorage()),
      ],
    );
    addTearDown(container.dispose);

    const sessionId = 'new_chat';
    final notifier = container.read(chatSessionNotifierProvider(sessionId));
    final loadingMessage = Message.ai('');
    notifier.state = ChatState(
      messages: [loadingMessage],
      isLoading: true,
    );

    await tester.pumpWidget(_buildApp(container, sessionId: sessionId));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Thinking...'), findsOneWidget);
    expect(find.byIcon(AuroraIcons.stop), findsOneWidget);

    notifier.state = ChatState(
      messages: [
        loadingMessage.copyWith(
          content: '⚠️ **Request failed**\n\nHTTP 503',
        ),
      ],
      isLoading: false,
      error: 'HTTP 503',
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Thinking...'), findsNothing);
    expect(find.byIcon(AuroraIcons.stop), findsNothing);
    expect(find.byIcon(AuroraIcons.send), findsOneWidget);
  });
}
