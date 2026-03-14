import 'package:aurora/features/chat/presentation/widgets/selectable_markdown/animated_streaming_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildWidget({
  required String data,
  required bool animate,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AnimatedStreamingMarkdown(
        data: data,
        isDark: false,
        textColor: Colors.black,
        animate: animate,
      ),
    ),
  );
}

void main() {
  testWidgets('disabling animation syncs streamed markdown immediately',
      (tester) async {
    await tester.pumpWidget(_buildWidget(data: 'Hello', animate: false));
    expect(find.text('Hello'), findsOneWidget);

    await tester.pumpWidget(_buildWidget(data: 'Hello world', animate: false));
    await tester.pump();

    expect(find.text('Hello world'), findsOneWidget);
  });

  testWidgets('enabled animation does not render the full update immediately',
      (tester) async {
    await tester.pumpWidget(_buildWidget(data: 'Hello', animate: true));
    expect(find.text('Hello'), findsOneWidget);

    await tester.pumpWidget(_buildWidget(data: 'Hello world', animate: true));
    await tester.pump();

    expect(find.text('Hello world'), findsNothing);

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Hello world'), findsOneWidget);
  });
}
