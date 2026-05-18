import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_legacy.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'package:flutter/widgets.dart';

import '../domain/mcp_server_config.dart';
import 'mcp_connection_provider.dart';
import 'mcp_server_provider.dart';

Future<void> refreshMcpToolsCache({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required McpServerConfig server,
}) async {
  try {
    await ref.read(mcpConnectionProvider.notifier).listTools(
          server,
          forceRefresh: true,
        );
    if (!context.mounted) return;
    showAuroraNotice(
      context,
      l10n.mcpRefreshToolsCacheSuccess,
      icon: AuroraIcons.success,
    );
  } catch (error) {
    if (!context.mounted) return;
    showAuroraNotice(
      context,
      '${l10n.error}: $error',
      icon: AuroraIcons.error,
    );
  }
}

Future<void> reconnectMcpServer({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required McpServerConfig server,
}) async {
  try {
    await ref.read(mcpConnectionProvider.notifier).reconnect(server);
  } catch (error) {
    if (!context.mounted) return;
    showAuroraNotice(
      context,
      '${l10n.error}: $error',
      icon: AuroraIcons.error,
    );
  }
}

Future<void> disconnectMcpServer({
  required WidgetRef ref,
  required String serverId,
}) {
  return ref.read(mcpConnectionProvider.notifier).disconnect(serverId);
}

Future<void> deleteMcpServer({
  required BuildContext context,
  VoidCallback? onDeleted,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required String serverId,
}) async {
  await ref.read(mcpServerProvider.notifier).deleteServer(serverId);
  onDeleted?.call();
  if (!context.mounted) return;
  showAuroraNotice(
    context,
    l10n.deleteSuccess,
    icon: AuroraIcons.success,
  );
}
