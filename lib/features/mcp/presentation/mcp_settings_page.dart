import 'dart:async';
import 'dart:convert';

import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'package:aurora/shared/widgets/aurora_selection.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/mcp_server_config.dart';
import 'mcp_connection_provider.dart';
import 'mcp_server_provider.dart';

class McpSettingsPage extends ConsumerStatefulWidget {
  const McpSettingsPage({super.key});

  @override
  ConsumerState<McpSettingsPage> createState() => _McpSettingsPageState();
}

class _McpSettingsPageState extends ConsumerState<McpSettingsPage> {
  final Set<String> _testingServerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mcpServerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mcpState = ref.watch(mcpServerProvider);
    final connectionState = ref.watch(mcpConnectionProvider);
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.mcpTitle,
                  style: theme.typography.subtitle,
                ),
                Row(
                  children: [
                    fluent.FilledButton(
                      onPressed: () => _showEditServerDialog(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(AuroraIcons.add, size: 14),
                          const SizedBox(width: 8),
                          Text(l10n.mcpAddServer),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    fluent.Button(
                      onPressed: () =>
                          ref.read(mcpServerProvider.notifier).refresh(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(AuroraIcons.refresh, size: 14),
                          const SizedBox(width: 8),
                          Text(l10n.refreshList),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (mcpState.isLoading)
            const Expanded(child: Center(child: fluent.ProgressRing()))
          else if (mcpState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                '${l10n.error}: ${mcpState.error}',
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (mcpState.servers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AuroraIcons.mcp, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(l10n.mcpNoServers),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: mcpState.servers.length,
                itemBuilder: (context, index) {
                  final server = mcpState.servers[index];
                  final info = connectionState.connections[server.id] ??
                      const McpConnectionInfo(
                        status: McpConnectionStatus.disconnected,
                      );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: fluent.Expander(
                      header: _buildServerHeader(
                        context,
                        theme,
                        l10n,
                        server,
                        info,
                      ),
                      content: _buildServerDetails(
                          context, theme, l10n, server, info),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, McpConnectionStatus status) {
    switch (status) {
      case McpConnectionStatus.ready:
        return l10n.mcpStatusConnected;
      case McpConnectionStatus.connecting:
        return l10n.mcpStatusConnecting;
      case McpConnectionStatus.error:
        return l10n.error;
      case McpConnectionStatus.disconnected:
        return l10n.mcpStatusDisconnected;
    }
  }

  Color _statusColor(fluent.FluentThemeData theme, McpConnectionStatus status) {
    switch (status) {
      case McpConnectionStatus.ready:
        return theme.accentColor;
      case McpConnectionStatus.connecting:
        return Colors.orange;
      case McpConnectionStatus.error:
        return Colors.red;
      case McpConnectionStatus.disconnected:
        return theme.typography.caption?.color ?? Colors.grey;
    }
  }

  Widget _buildStatusBadge(
    fluent.FluentThemeData theme,
    AppLocalizations l10n,
    McpConnectionInfo info,
  ) {
    final color = _statusColor(theme, info.status);
    final label = _statusLabel(l10n, info.status);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final lastError = info.lastError;
    if (lastError != null && lastError.trim().isNotEmpty) {
      return fluent.Tooltip(
        message: lastError,
        child: badge,
      );
    }
    return badge;
  }

  Widget _buildServerHeader(
    BuildContext context,
    fluent.FluentThemeData theme,
    AppLocalizations l10n,
    McpServerConfig server,
    McpConnectionInfo info,
  ) {
    final isTesting = _testingServerIds.contains(server.id);
    final commandSummary = server.transport == McpServerTransport.http
        ? server.url.trim()
        : [
            server.command,
            ...server.args,
          ].where((s) => s.trim().isNotEmpty).join(' ');
    final lastCallMs = info.lastCallDurationMs;

    return Row(
      children: [
        Icon(
          AuroraIcons.mcp,
          size: 16,
          color: server.enabled
              ? theme.accentColor
              : theme.typography.caption?.color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                server.name.isNotEmpty ? server.name : l10n.unknown,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      server.enabled ? null : theme.typography.caption?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                commandSummary,
                style: TextStyle(
                  fontSize: 12,
                  color: server.enabled
                      ? theme.typography.caption?.color
                      : theme.typography.caption?.color?.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusBadge(theme, l10n, info),
        if (lastCallMs != null) ...[
          const SizedBox(width: 8),
          Text(
            '${lastCallMs}ms',
            style: TextStyle(
              fontSize: 12,
              color: theme.typography.caption?.color,
            ),
          ),
        ],
        const SizedBox(width: 8),
        fluent.ToggleSwitch(
          checked: server.enabled,
          onChanged: (v) =>
              ref.read(mcpServerProvider.notifier).toggleEnabled(server.id, v),
        ),
        const SizedBox(width: 8),
        fluent.Tooltip(
          message: l10n.mcpTestConnection,
          child: fluent.IconButton(
            icon: isTesting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: fluent.ProgressRing(strokeWidth: 2))
                : const Icon(AuroraIcons.play, size: 14),
            onPressed: isTesting ? null : () => _testServer(context, server),
          ),
        ),
        fluent.Tooltip(
          message: l10n.edit,
          child: fluent.IconButton(
            icon: const Icon(AuroraIcons.edit, size: 14),
            onPressed: () => _showEditServerDialog(context, server: server),
          ),
        ),
        fluent.Tooltip(
          message: l10n.delete,
          child: fluent.IconButton(
            icon: const Icon(AuroraIcons.delete, size: 14),
            onPressed: () => _confirmDelete(context, server),
          ),
        ),
      ],
    );
  }

  Widget _buildServerDetails(
    BuildContext context,
    fluent.FluentThemeData theme,
    AppLocalizations l10n,
    McpServerConfig server,
    McpConnectionInfo info,
  ) {
    Widget kv(String key, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                key,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 13,
                  color: theme.resources.textFillColorPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final envText = server.env.isEmpty
        ? l10n.none
        : server.env.entries.map((e) => '${e.key}=${e.value}').join('\n');
    final headersText = server.headers.isEmpty
        ? l10n.none
        : server.headers.entries.map((e) => '${e.key}=${e.value}').join('\n');
    final stderrText = info.stderrTail.join('\n').trim();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          kv(
            l10n.mcpTransport,
            server.transport == McpServerTransport.http
                ? l10n.mcpTransportHttp
                : l10n.mcpTransportStdio,
          ),
          if (server.transport == McpServerTransport.http) ...[
            kv(l10n.mcpUrl, server.url.trim().isEmpty ? l10n.none : server.url),
            kv(l10n.mcpHeaders, headersText),
          ] else ...[
            kv(l10n.mcpCommand, server.command),
            kv(l10n.mcpArgs,
                server.args.isEmpty ? l10n.none : server.args.join('\n')),
            kv(l10n.mcpCwd, server.cwd ?? l10n.none),
            kv(l10n.mcpEnv, envText),
            kv(l10n.mcpRunInShell, server.runInShell ? l10n.yes : l10n.no),
          ],
          const fluent.Divider(),
          kv(l10n.mcpStatus, _statusLabel(l10n, info.status)),
          kv(
            l10n.mcpLastError,
            (info.lastError == null || info.lastError!.trim().isEmpty)
                ? l10n.none
                : info.lastError!,
          ),
          kv(
            l10n.mcpLastConnectedAt,
            info.lastConnectedAt == null
                ? l10n.none
                : '${info.lastConnectedAt}',
          ),
          kv(
            l10n.mcpLastPingAt,
            info.lastPingAt == null ? l10n.none : '${info.lastPingAt}',
          ),
          kv(
            l10n.mcpLastToolListAt,
            info.lastToolListAt == null ? l10n.none : '${info.lastToolListAt}',
          ),
          kv(
            l10n.mcpLastCallAt,
            info.lastCallAt == null ? l10n.none : '${info.lastCallAt}',
          ),
          kv(
            l10n.mcpCachedToolsCount,
            info.cachedToolsCount?.toString() ?? l10n.none,
          ),
          kv(
            l10n.mcpLastToolListDuration,
            info.lastToolListDurationMs == null
                ? l10n.none
                : '${info.lastToolListDurationMs}ms',
          ),
          kv(
            l10n.mcpLastCallDuration,
            info.lastCallDurationMs == null
                ? l10n.none
                : '${info.lastCallDurationMs}ms',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              fluent.Button(
                onPressed: () async {
                  try {
                    await ref
                        .read(mcpConnectionProvider.notifier)
                        .listTools(server, forceRefresh: true);
                    if (!context.mounted) return;
                    showAuroraNotice(
                      context,
                      l10n.mcpRefreshToolsCacheSuccess,
                      icon: AuroraIcons.success,
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    showAuroraNotice(
                      context,
                      '${l10n.error}: $e',
                      icon: AuroraIcons.error,
                    );
                  }
                },
                child: Text(l10n.mcpRefreshToolsCache),
              ),
              fluent.Button(
                onPressed: () async {
                  try {
                    await ref
                        .read(mcpConnectionProvider.notifier)
                        .reconnect(server);
                  } catch (e) {
                    if (!context.mounted) return;
                    showAuroraNotice(
                      context,
                      '${l10n.error}: $e',
                      icon: AuroraIcons.error,
                    );
                  }
                },
                child: Text(l10n.mcpReconnect),
              ),
              fluent.Button(
                onPressed: () async {
                  await ref
                      .read(mcpConnectionProvider.notifier)
                      .disconnect(server.id);
                },
                child: Text(l10n.mcpDisconnect),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                l10n.mcpStderrTail,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              fluent.IconButton(
                icon: const Icon(AuroraIcons.copy, size: 14),
                onPressed: stderrText.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                            ClipboardData(text: stderrText));
                        if (!context.mounted) return;
                        showAuroraNotice(
                          context,
                          l10n.copied,
                          icon: AuroraIcons.success,
                        );
                      },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 160),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AuroraSelectionArea(
              child: SingleChildScrollView(
                child: AuroraSelectableText(
                  stderrText.isEmpty ? l10n.none : stderrText,
                  useSelectionArea: false,
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testServer(BuildContext context, McpServerConfig server) async {
    setState(() => _testingServerIds.add(server.id));
    final result =
        await ref.read(mcpConnectionProvider.notifier).testConnection(server);
    if (!context.mounted) return;
    setState(() => _testingServerIds.remove(server.id));
    _showTestResultDialog(context, server, result);
  }

  void _showTestResultDialog(
    BuildContext context,
    McpServerConfig server,
    McpConnectionTestResult result,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        final body = result.success
            ? _formatToolsResult(l10n, result)
            : _formatErrorResult(l10n, result);
        return fluent.ContentDialog(
          title: Text('${l10n.mcpTestResultTitle}: ${server.name}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(child: body),
          ),
          actions: [
            fluent.Button(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  Widget _formatToolsResult(
      AppLocalizations l10n, McpConnectionTestResult result) {
    final tools = result.tools;
    final toolNames =
        tools.map((t) => t.name).where((s) => s.isNotEmpty).toList()..sort();
    final stderr = result.stderrTail.join('\n').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.mcpToolsCount}: ${toolNames.length}'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AuroraSelectableText(
            toolNames.isEmpty ? l10n.none : toolNames.join('\n'),
            style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
          ),
        ),
        if (stderr.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.mcpStderr),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AuroraSelectableText(
              stderr,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _formatErrorResult(
      AppLocalizations l10n, McpConnectionTestResult result) {
    final stderr = result.stderrTail.join('\n').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.error}: ${result.error ?? l10n.unknown}'),
        if (stderr.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.mcpStderr),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AuroraSelectableText(
              stderr,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, McpServerConfig server) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (ctx) => fluent.ContentDialog(
        title: Text(l10n.mcpDeleteServerTitle),
        content: Text(l10n.mcpDeleteServerConfirm),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          fluent.FilledButton(
            onPressed: () async {
              await ref
                  .read(mcpServerProvider.notifier)
                  .deleteServer(server.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              showAuroraNotice(context, l10n.deleteSuccess,
                  icon: AuroraIcons.success);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditServerDialog(
    BuildContext context, {
    McpServerConfig? server,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: server?.name ?? '');
    McpServerTransport transport =
        server?.transport ?? McpServerTransport.stdio;
    final commandController =
        TextEditingController(text: server?.command ?? '');
    final argsController =
        TextEditingController(text: (server?.args ?? const []).join('\n'));
    final cwdController = TextEditingController(text: server?.cwd ?? '');
    final envController = TextEditingController(
        text: (server?.env.entries.map((e) => '${e.key}=${e.value}').toList() ??
                const <String>[])
            .join('\n'));
    final urlController = TextEditingController(text: server?.url ?? '');
    final headersController = TextEditingController(
        text: (server?.headers.entries
                    .map((e) => '${e.key}=${e.value}')
                    .toList() ??
                const <String>[])
            .join('\n'));

    bool enabled = server?.enabled ?? true;
    bool runInShell = server?.runInShell ?? PlatformUtils.isWindows;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return fluent.ContentDialog(
            title:
                Text(server == null ? l10n.mcpAddServer : l10n.mcpEditServer),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mcpServerName, style: themeTextLabel(ctx)),
                    const SizedBox(height: 6),
                    fluent.TextBox(
                      controller: nameController,
                      placeholder: l10n.mcpServerNameHint,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.mcpTransport, style: themeTextLabel(ctx)),
                    const SizedBox(height: 6),
                    fluent.ComboBox<McpServerTransport>(
                      value: transport,
                      items: [
                        fluent.ComboBoxItem(
                          value: McpServerTransport.stdio,
                          child: Text(l10n.mcpTransportStdio),
                        ),
                        fluent.ComboBoxItem(
                          value: McpServerTransport.http,
                          child: Text(l10n.mcpTransportHttp),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          transport = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (transport == McpServerTransport.http) ...[
                      Text(l10n.mcpUrl, style: themeTextLabel(ctx)),
                      const SizedBox(height: 6),
                      fluent.TextBox(
                        controller: urlController,
                        placeholder: l10n.mcpUrlHint,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.mcpHeaders, style: themeTextLabel(ctx)),
                      const SizedBox(height: 6),
                      fluent.TextBox(
                        controller: headersController,
                        placeholder: l10n.keyValuePerLineHint,
                        maxLines: null,
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text(l10n.mcpCommand, style: themeTextLabel(ctx)),
                      const SizedBox(height: 6),
                      fluent.TextBox(
                        controller: commandController,
                        placeholder: l10n.mcpCommandHint,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.mcpArgs, style: themeTextLabel(ctx)),
                      const SizedBox(height: 6),
                      fluent.TextBox(
                        controller: argsController,
                        placeholder: l10n.mcpArgsHint,
                        maxLines: null,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.mcpCwd, style: themeTextLabel(ctx)),
                      const SizedBox(height: 6),
                      fluent.TextBox(
                        controller: cwdController,
                        placeholder: l10n.optional,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.mcpEnv, style: themeTextLabel(ctx)),
                      const SizedBox(height: 6),
                      fluent.TextBox(
                        controller: envController,
                        placeholder: l10n.keyValuePerLineHint,
                        maxLines: null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    fluent.Checkbox(
                      checked: enabled,
                      onChanged: (v) => setState(() => enabled = v ?? true),
                      content: Text(l10n.enabledStatus),
                    ),
                    if (transport == McpServerTransport.stdio)
                      fluent.Checkbox(
                        checked: runInShell,
                        onChanged: (v) =>
                            setState(() => runInShell = v ?? false),
                        content: Text(l10n.mcpRunInShell),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              fluent.Button(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              fluent.FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final command = commandController.text.trim();
                  final url = urlController.text.trim();
                  if (name.isEmpty) {
                    showAuroraNotice(
                      context,
                      l10n.mcpValidationErrorName,
                      icon: AuroraIcons.error,
                    );
                    return;
                  }

                  var args = const <String>[];
                  String? cwd;
                  Map<String, String> env = const {};
                  Map<String, String> headers = const {};
                  if (transport == McpServerTransport.http) {
                    if (url.isEmpty) {
                      showAuroraNotice(
                        context,
                        l10n.mcpValidationErrorUrl,
                        icon: AuroraIcons.error,
                      );
                      return;
                    }
                    headers = _parseKeyValueLines(headersController.text);
                  } else {
                    if (command.isEmpty) {
                      showAuroraNotice(
                        context,
                        l10n.mcpValidationErrorCommand,
                        icon: AuroraIcons.error,
                      );
                      return;
                    }
                    args = const LineSplitter()
                        .convert(argsController.text)
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList(growable: false);
                    cwd = cwdController.text.trim().isEmpty
                        ? null
                        : cwdController.text.trim();
                    env = _parseKeyValueLines(envController.text);
                  }

                  if (server == null) {
                    await ref.read(mcpServerProvider.notifier).addServer(
                          name: name,
                          transport: transport,
                          command: command,
                          args: args,
                          cwd: cwd,
                          env: env,
                          url: url,
                          headers: headers,
                          enabled: enabled,
                          runInShell: runInShell,
                        );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    showAuroraNotice(context, l10n.saveSuccess,
                        icon: AuroraIcons.success);
                    return;
                  }

                  await ref.read(mcpServerProvider.notifier).updateServer(
                        server.copyWith(
                          name: name,
                          transport: transport,
                          command: command,
                          args: args,
                          cwd: cwd,
                          env: env,
                          enabled: enabled,
                          runInShell: runInShell,
                          url: url,
                          headers: headers,
                        ),
                      );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  showAuroraNotice(context, l10n.saveSuccess,
                      icon: AuroraIcons.success);
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  TextStyle themeTextLabel(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    return TextStyle(
      fontWeight: FontWeight.w600,
      color: theme.resources.textFillColorSecondary,
    );
  }

  Map<String, String> _parseKeyValueLines(String raw) {
    final result = <String, String>{};
    for (final line in const LineSplitter().convert(raw)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final idx = trimmed.indexOf('=');
      if (idx <= 0) continue;
      final key = trimmed.substring(0, idx).trim();
      final value = trimmed.substring(idx + 1).trim();
      if (key.isEmpty) continue;
      result[key] = value;
    }
    return result;
  }
}
