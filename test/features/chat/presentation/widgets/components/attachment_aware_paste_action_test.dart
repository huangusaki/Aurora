import 'package:aurora/features/chat/presentation/widgets/components/attachment_aware_paste_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyV, control: true):
            PasteTextIntent(SelectionChangedCause.keyboard),
      },
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

void main() {
  Future<void> pumpHarness(
    WidgetTester tester, {
    required Future<bool> Function() onCustomPaste,
    required _RecordingPasteAction defaultAction,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Actions(
          actions: <Type, Action<Intent>>{
            PasteTextIntent: AttachmentAwarePasteAction(
              onCustomPaste: onCustomPaste,
            ),
          },
          child: Center(child: _PasteableBox(defaultAction: defaultAction)),
        ),
      ),
    );
  }

  testWidgets('falls back to default paste when custom paste is not handled',
      (tester) async {
    final defaultAction = _RecordingPasteAction();
    await pumpHarness(
      tester,
      onCustomPaste: () async => false,
      defaultAction: defaultAction,
    );

    expect(primaryFocus, isNotNull);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    expect(defaultAction.invoked, isTrue);
  });

  testWidgets('skips default paste when custom paste handles the clipboard',
      (tester) async {
    final defaultAction = _RecordingPasteAction();
    await pumpHarness(
      tester,
      onCustomPaste: () async => true,
      defaultAction: defaultAction,
    );

    expect(primaryFocus, isNotNull);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    expect(defaultAction.invoked, isFalse);
  });
}
