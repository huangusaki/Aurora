import 'dart:convert';

import 'package:aurora/features/chat/presentation/widgets/chat_image_bubble.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

String _buildDataUrl({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  final bytes = img.encodePng(image);
  return 'data:image/png;base64,${base64Encode(bytes)}';
}

Widget _buildApp(String imageUrl) {
  return FluentApp(
    home: material.Material(
      type: material.MaterialType.transparency,
      child: Center(
        child: ChatImageBubble(imageUrl: imageUrl),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('portrait thumbnails preserve aspect ratio', (tester) async {
    final imageUrl = _buildDataUrl(width: 40, height: 80);

    await tester.pumpWidget(_buildApp(imageUrl));
    await tester.pumpAndSettle();

    final bubbleFinder = find.byType(ChatImageBubble);
    final gestureFinder = find.descendant(
      of: bubbleFinder,
      matching: find.byType(GestureDetector),
    );

    final size = tester.getSize(gestureFinder.first);
    expect(size.height, greaterThan(size.width));
  });

  testWidgets('chat thumbnails do not use fixed square decode hints',
      (tester) async {
    final imageUrl = _buildDataUrl(width: 40, height: 80);

    await tester.pumpWidget(_buildApp(imageUrl));
    await tester.pumpAndSettle();

    final bubbleFinder = find.byType(ChatImageBubble);
    final imageFinder = find.descendant(
      of: bubbleFinder,
      matching: find.byType(Image),
    );

    final imageWidget = tester.widget<Image>(imageFinder.first);
    expect(imageWidget.image, isNot(isA<ResizeImage>()));
  });
}
