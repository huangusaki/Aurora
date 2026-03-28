import 'package:aurora/features/chat/presentation/widgets/components/attachment_aware_paste_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const PasteTextIntent _pasteIntent = PasteTextIntent(
  SelectionChangedCause.keyboard,
);

const Map<ShortcutActivator, Intent> _pasteShortcuts =
    <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.keyV, control: true): _pasteIntent,
  SingleActivator(LogicalKeyboardKey.insert, shift: true): _pasteIntent,
  SingleActivator(LogicalKeyboardKey.paste): _pasteIntent,
};

class _RecordingPasteAction extends Action<PasteTextIntent> {
  bool invoked = false;

  @override
  Object? invoke(PasteTextIntent intent) {
    invoked = true;
    return null;
  }
}

class _PasteableBox extends StatelessWidget {
  const _PasteableBox({required this.defaultAction});

  final Action<PasteTextIntent> defaultAction;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _pasteShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          PasteTextIntent: Action.overridable(
            defaultAction: defaultAction,
            context: context,
          ),
        },
        child: const Focus(
          autofocus: true,
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );
  }
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Future<bool> Function() onCustomPaste,
  Future<bool> Function()? onFallbackPaste,
  required _RecordingPasteAction defaultAction,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Actions(
        actions: <Type, Action<Intent>>{
          PasteTextIntent: AttachmentAwarePasteAction(
            onCustomPaste: onCustomPaste,
            onFallbackPaste: onFallbackPaste,
          ),
        },
        child: Center(child: _PasteableBox(defaultAction: defaultAction)),
      ),
    ),
  );
}

Future<void> _sendCtrlV(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
}

Future<void> _sendShiftInsert(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.insert);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.insert);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
}

Future<void> _sendPasteKey(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.paste);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.paste);
}

void main() {
  testWidgets('falls back to default paste when custom paste is not handled',
      (tester) async {
    final defaultAction = _RecordingPasteAction();
    await _pumpHarness(
      tester,
      onCustomPaste: () async => false,
      defaultAction: defaultAction,
    );

    expect(primaryFocus, isNotNull);

    await _sendCtrlV(tester);
    await tester.pumpAndSettle();

    expect(defaultAction.invoked, isTrue);
  });

  testWidgets(
      'falls back to default paste when explicit fallback also does not handle',
      (tester) async {
    final defaultAction = _RecordingPasteAction();
    var fallbackInvoked = false;
    await _pumpHarness(
      tester,
      onCustomPaste: () async => false,
      onFallbackPaste: () async {
        fallbackInvoked = true;
        return false;
      },
      defaultAction: defaultAction,
    );

    expect(primaryFocus, isNotNull);

    await _sendShiftInsert(tester);
    await tester.pumpAndSettle();

    expect(fallbackInvoked, isTrue);
    expect(defaultAction.invoked, isTrue);
  });

  testWidgets('uses explicit fallback before default paste', (tester) async {
    final defaultAction = _RecordingPasteAction();
    var fallbackInvoked = false;
    await _pumpHarness(
      tester,
      onCustomPaste: () async => false,
      onFallbackPaste: () async {
        fallbackInvoked = true;
        return true;
      },
      defaultAction: defaultAction,
    );

    expect(primaryFocus, isNotNull);

    await _sendShiftInsert(tester);
    await tester.pumpAndSettle();

    expect(fallbackInvoked, isTrue);
    expect(defaultAction.invoked, isFalse);
  });

  testWidgets('skips default paste when custom paste handles the clipboard',
      (tester) async {
    final defaultAction = _RecordingPasteAction();
    var customInvoked = false;
    await _pumpHarness(
      tester,
      onCustomPaste: () async {
        customInvoked = true;
        return true;
      },
      defaultAction: defaultAction,
    );

    expect(primaryFocus, isNotNull);

    await _sendPasteKey(tester);
    await tester.pumpAndSettle();

    expect(customInvoked, isTrue);
    expect(defaultAction.invoked, isFalse);
  });
}
