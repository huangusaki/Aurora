import 'dart:async';

import 'package:flutter/material.dart';

class AttachmentAwarePasteAction extends Action<PasteTextIntent> {
  AttachmentAwarePasteAction({
    required this.onCustomPaste,
    this.onFallbackPaste,
    this.onAfterPaste,
  });

  final Future<bool> Function() onCustomPaste;
  final Future<bool> Function()? onFallbackPaste;
  final VoidCallback? onAfterPaste;

  @override
  Object? invoke(PasteTextIntent intent) {
    final fallbackAction = callingAction;
    unawaited(_handlePaste(intent, fallbackAction));
    return null;
  }

  Future<void> _handlePaste(
    PasteTextIntent intent,
    Action<PasteTextIntent>? fallbackAction,
  ) async {
    bool handled = false;
    try {
      handled = await onCustomPaste();
    } catch (_) {
      handled = false;
    }

    if (!handled && onFallbackPaste != null) {
      try {
        handled = await onFallbackPaste!.call();
      } catch (_) {
        handled = false;
      }
    }

    if (!handled) {
      fallbackAction?.invoke(intent);
    }
    onAfterPaste?.call();
  }

  @override
  bool get isActionEnabled => callingAction?.isActionEnabled ?? true;

  @override
  bool consumesKey(PasteTextIntent intent) =>
      callingAction?.consumesKey(intent) ?? true;
}
