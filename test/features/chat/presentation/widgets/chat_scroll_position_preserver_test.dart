import 'package:aurora/features/chat/presentation/widgets/chat_scroll_position_preserver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recent user interaction expires after hold window', () {
    final preserver = ChatScrollPositionPreserver(
      recentInteractionHold: const Duration(milliseconds: 300),
    );
    final now = DateTime(2026, 3, 14, 12);
    preserver.recordUserInteraction(now);

    expect(
      preserver.hasRecentUserInteraction(
        now.add(const Duration(milliseconds: 200)),
      ),
      isTrue,
    );
    expect(
      preserver.hasRecentUserInteraction(
        now.add(const Duration(milliseconds: 301)),
      ),
      isFalse,
    );
  });

  test('reset clears metrics and interaction snapshot', () {
    final preserver = ChatScrollPositionPreserver();
    preserver.recordUserInteraction(DateTime(2026, 3, 14, 12));

    preserver.reset();

    expect(preserver.hasRecentUserInteraction(DateTime(2026, 3, 14, 12, 0, 1)),
        isFalse);
  });

  test('auto-scroll threshold only pins when near the bottom', () {
    final preserver =
        ChatScrollPositionPreserver(autoScrollPinnedThreshold: 100);

    expect(preserver.isAutoScroll(80), isTrue);
    expect(preserver.isAutoScroll(140), isFalse);
  });
}
