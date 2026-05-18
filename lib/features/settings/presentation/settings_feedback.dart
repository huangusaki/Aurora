import 'package:flutter/material.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';

void showModelRefreshNotice(
  BuildContext context, {
  required AppLocalizations l10n,
  required String? errorMessage,
  required bool success,
  IconData successIcon = AuroraIcons.success,
  IconData errorIcon = AuroraIcons.error,
}) {
  if (!context.mounted) return;
  if (success) {
    showAuroraNotice(
      context,
      '${l10n.fetchModelList} ${l10n.success}',
      icon: successIcon,
    );
    return;
  }

  final message = (errorMessage?.isNotEmpty ?? false)
      ? '${l10n.fetchModelList} ${l10n.failed}: $errorMessage'
      : '${l10n.fetchModelList} ${l10n.failed}';
  showAuroraNotice(
    context,
    message,
    icon: errorIcon,
  );
}
