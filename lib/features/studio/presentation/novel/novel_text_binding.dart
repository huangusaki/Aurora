import 'package:flutter/widgets.dart';

void syncBoundTextController({
  required String? currentBoundId,
  required String? nextBoundId,
  required TextEditingController controller,
  required String nextText,
  required void Function(String?) onBoundIdChanged,
  required void Function(bool) onSyncingChanged,
}) {
  if (currentBoundId == nextBoundId && controller.text == nextText) {
    return;
  }

  onBoundIdChanged(nextBoundId);
  onSyncingChanged(true);
  controller.value = TextEditingValue(
    text: nextText,
    selection: TextSelection.collapsed(offset: nextText.length),
  );
  onSyncingChanged(false);
}
