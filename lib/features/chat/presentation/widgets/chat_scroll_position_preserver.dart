class ChatScrollPositionPreserver {
  ChatScrollPositionPreserver({
    this.autoScrollPinnedThreshold = 100,
    this.recentInteractionHold = const Duration(milliseconds: 300),
  });

  final double autoScrollPinnedThreshold;
  final Duration recentInteractionHold;

  DateTime? _lastUserInteractionAt;

  bool isAutoScroll(double pixels) => pixels < autoScrollPinnedThreshold;

  void reset() {
    _lastUserInteractionAt = null;
  }

  void recordUserInteraction([DateTime? now]) {
    _lastUserInteractionAt = now ?? DateTime.now();
  }

  bool hasRecentUserInteraction([DateTime? now]) {
    final lastUserInteractionAt = _lastUserInteractionAt;
    if (lastUserInteractionAt == null) return false;
    return (now ?? DateTime.now()).difference(lastUserInteractionAt) <
        recentInteractionHold;
  }
}
