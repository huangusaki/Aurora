import 'dart:async';
import 'dart:convert';

import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'package:flutter/material.dart';
import '../../settings/presentation/widgets/mobile_settings_widgets.dart';
import '../domain/mcp_server_config.dart';
import 'mcp_connection_provider.dart';
import 'mcp_server_provider.dart';

class MobileMcpSettingsPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const MobileMcpSettingsPage({super.key, this.onBack});

  @override
  ConsumerState<MobileMcpSettingsPage> createState() =>
      _MobileMcpSettingsPageState();
}

class _MobileMcpSettingsPageState extends ConsumerState<MobileMcpSettingsPage> {
  final Set<String> _testingServerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mcpServerProvider.notifier).load();
    });
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

  Future<void> _testServer(BuildContext context, McpServerConfig server) async {
    setState(() => _testingServerIds.add(server.id));
    final result =
        await ref.read(mcpConnectionProvider.notifier).testConnection(server);
    if (!context.mounted) return;
    setState(() => _testingServerIds.remove(server.id));

    final l10n = AppLocalizations.of(context)!;
    final toolNames = result.tools
        .map((t) => t.name)
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();
    final stderr = result.stderrTail.join('\n').trim();
    final content = result.success
        ? '${l10n.mcpToolsCount}: ${toolNames.length}\n\n${toolNames.isEmpty ? l10n.none : toolNames.join('\n')}${stderr.isNotEmpty ? '\n\n${l10n.mcpStderrTail}\n$stderr' : ''}'
        : '${l10n.error}: ${result.error ?? l10n.unknown}${stderr.isNotEmpty ? '\n\n${l10n.mcpStderrTail}\n$stderr' : ''}';

    if (!context.mounted) return;
    await AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${l10n.mcpTestResultTitle}: ${server.name}',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  content,
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditServerSheet(BuildContext context,
      {McpServerConfig? server}) async {
    final l10n = AppLocalizations.of(context)!;

    final nameController = TextEditingController(text: server?.name ?? '');
    McpServerTransport transport = server?.transport ?? McpServerTransport.http;
    final commandController =
        TextEditingController(text: server?.command ?? '');
    final argsController =
        TextEditingController(text: (server?.args ?? const []).join('\n'));
    final cwdController = TextEditingController(text: server?.cwd ?? '');
    final envController = TextEditingController(
      text: (server?.env.entries.map((e) => '${e.key}=${e.value}').toList() ??
              const <String>[])
          .join('\n'),
    );
    final urlController = TextEditingController(text: server?.url ?? '');
    final headersController = TextEditingController(
      text:
          (server?.headers.entries.map((e) => '${e.key}=${e.value}').toList() ??
                  const <String>[])
              .join('\n'),
    );

    bool enabled = server?.enabled ?? true;
    bool runInShell = server?.runInShell ?? false;

    Map<String, String> parseKeyValue(String raw) {
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

    await AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isHttp = transport == McpServerTransport.http;
          return SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  server == null ? l10n.mcpAddServer : l10n.mcpEditServer,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.mcpServerName,
                    hintText: l10n.mcpServerNameHint,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<McpServerTransport>(
                  initialValue: transport,
                  decoration: InputDecoration(
                    labelText: l10n.mcpTransport,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: McpServerTransport.stdio,
                      child: Text(l10n.mcpTransportStdio),
                    ),
                    DropdownMenuItem(
                      value: McpServerTransport.http,
                      child: Text(l10n.mcpTransportHttp),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => transport = v);
                  },
                ),
                const SizedBox(height: 12),
                if (isHttp) ...[
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: l10n.mcpUrl,
                      hintText: l10n.mcpUrlHint,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: headersController,
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: l10n.mcpHeaders,
                      hintText: l10n.keyValuePerLineHint,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  TextField(
                    controller: commandController,
                    decoration: InputDecoration(
                      labelText: l10n.mcpCommand,
                      hintText: l10n.mcpCommandHint,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: argsController,
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: l10n.mcpArgs,
                      hintText: l10n.mcpArgsHint,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cwdController,
                    decoration: InputDecoration(
                      labelText: l10n.mcpCwd,
                      hintText: l10n.optional,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: envController,
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: l10n.mcpEnv,
                      hintText: l10n.keyValuePerLineHint,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SwitchListTile.adaptive(
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                  title: Text(l10n.enabledStatus),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!isHttp)
                  SwitchListTile.adaptive(
                    value: runInShell,
                    onChanged: (v) => setState(() => runInShell = v),
                    title: Text(l10n.mcpRunInShell),
                    contentPadding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
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
                          if (isHttp) {
                            if (url.isEmpty) {
                              showAuroraNotice(
                                context,
                                l10n.mcpValidationErrorUrl,
                                icon: AuroraIcons.error,
                              );
                              return;
                            }
                          } else {
                            if (command.isEmpty) {
                              showAuroraNotice(
                                context,
                                l10n.mcpValidationErrorCommand,
                                icon: AuroraIcons.error,
                              );
                              return;
                            }
                          }

                          final args = const LineSplitter()
                              .convert(argsController.text)
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList(growable: false);
                          final cwd = cwdController.text.trim().isEmpty
                              ? null
                              : cwdController.text.trim();
                          final env = parseKeyValue(envController.text);
                          final headers = parseKeyValue(headersController.text);

                          if (server == null) {
                            await ref
                                .read(mcpServerProvider.notifier)
                                .addServer(
                                  name: name,
                                  transport: transport,
                                  command: isHttp ? '' : command,
                                  args: isHttp ? const [] : args,
                                  cwd: isHttp ? null : cwd,
                                  env: isHttp ? const {} : env,
                                  url: isHttp ? url : '',
                                  headers: isHttp ? headers : const {},
                                  enabled: enabled,
                                  runInShell: isHttp ? false : runInShell,
                                );
                          } else {
                            await ref
                                .read(mcpServerProvider.notifier)
                                .updateServer(
                                  server.copyWith(
                                    name: name,
                                    transport: transport,
                                    command: isHttp ? '' : command,
                                    args: isHttp ? const [] : args,
                                    cwd: isHttp ? null : cwd,
                                    env: isHttp ? const {} : env,
                                    url: isHttp ? url : '',
                                    headers: isHttp ? headers : const {},
                                    enabled: enabled,
                                    runInShell: isHttp ? false : runInShell,
                                  ),
                                );
                          }

                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          showAuroraNotice(context, l10n.saveSuccess,
                              icon: AuroraIcons.success);
                        },
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showServerActionsSheet(
    BuildContext context, {
    required McpServerConfig server,
    required McpConnectionInfo info,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final summary = server.transport == McpServerTransport.http
        ? server.url.trim()
        : [
            server.command,
            ...server.args,
          ].where((s) => s.trim().isNotEmpty).join(' ');
    final stderrText = info.stderrTail.join('\n').trim();

    await AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(
                ctx, server.name.isNotEmpty ? server.name : l10n.unknown),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  Text(
                    summary.isEmpty ? l10n.none : summary,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Consolas',
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${l10n.mcpStatus}: ${_statusLabel(l10n, info.status)}',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  if (info.lastError != null &&
                      info.lastError!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.mcpLastError}: ${info.lastError}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                  if (info.lastCallDurationMs != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.mcpLastCallDuration}: ${info.lastCallDurationMs}ms',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                  if (stderrText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.mcpStderrTail,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).cardColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        stderrText,
                        style: const TextStyle(
                            fontFamily: 'Consolas', fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  MobileSettingsSection(
                    children: [
                      MobileSettingsTile(
                        leading: const Icon(Icons.play_arrow_rounded),
                        title: l10n.mcpTestConnection,
                        showChevron: false,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _testServer(context, server);
                        },
                      ),
                      MobileSettingsTile(
                        leading: const Icon(Icons.refresh_rounded),
                        title: l10n.mcpRefreshToolsCache,
                        showChevron: false,
                        onTap: () async {
                          Navigator.pop(ctx);
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
                      ),
                      MobileSettingsTile(
                        leading: const Icon(Icons.link_rounded),
                        title: l10n.mcpReconnect,
                        showChevron: false,
                        onTap: () async {
                          Navigator.pop(ctx);
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
                      ),
                      MobileSettingsTile(
                        leading: const Icon(Icons.link_off_rounded),
                        title: l10n.mcpDisconnect,
                        showChevron: false,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await ref
                              .read(mcpConnectionProvider.notifier)
                              .disconnect(server.id);
                        },
                      ),
                      MobileSettingsTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: l10n.edit,
                        showChevron: false,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _showEditServerSheet(context, server: server);
                        },
                      ),
                      MobileSettingsTile(
                        leading: const Icon(Icons.delete_outline_rounded),
                        title: l10n.delete,
                        isDestructive: true,
                        showChevron: false,
                        onTap: () async {
                          final ok = await AuroraBottomSheet.showConfirm(
                            context: context,
                            title: l10n.mcpDeleteServerTitle,
                            content: l10n.mcpDeleteServerConfirm,
                            isDestructive: true,
                          );
                          if (ok != true) return;
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          await ref
                              .read(mcpServerProvider.notifier)
                              .deleteServer(server.id);
                          if (!context.mounted) return;
                          showAuroraNotice(
                            context,
                            l10n.deleteSuccess,
                            icon: AuroraIcons.success,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final serverState = ref.watch(mcpServerProvider);
    final connectionState = ref.watch(mcpConnectionProvider);

    Widget body;
    if (serverState.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (serverState.error != null) {
      body = Center(child: Text('${l10n.error}: ${serverState.error}'));
    } else if (serverState.servers.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AuroraIcons.mcp, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.mcpNoServers),
          ],
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          MobileSettingsSection(
            title: l10n.mcpTitle,
            children: serverState.servers.map((server) {
              final info = connectionState.connections[server.id] ??
                  const McpConnectionInfo(
                    status: McpConnectionStatus.disconnected,
                  );
              final summary = server.transport == McpServerTransport.http
                  ? server.url.trim()
                  : [
                      server.command,
                      ...server.args,
                    ].where((s) => s.trim().isNotEmpty).join(' ');
              final status = _statusLabel(l10n, info.status);
              final subtitle =
                  '${summary.isEmpty ? l10n.none : summary}\n$status';
              final isTesting = _testingServerIds.contains(server.id);
              return MobileSettingsTile(
                leading: const Icon(AuroraIcons.mcp),
                title: server.name.isNotEmpty ? server.name : l10n.unknown,
                subtitle: subtitle,
                showChevron: false,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: isTesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      onPressed:
                          isTesting ? null : () => _testServer(context, server),
                    ),
                    Switch.adaptive(
                      value: server.enabled,
                      onChanged: (v) => ref
                          .read(mcpServerProvider.notifier)
                          .toggleEnabled(server.id, v),
                    ),
                  ],
                ),
                onTap: () => _showServerActionsSheet(
                  context,
                  server: server,
                  info: info,
                ),
              );
            }).toList(growable: false),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.mcpTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditServerSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(mcpServerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: body,
    );
  }
}
