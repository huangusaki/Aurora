import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

import '../domain/mcp_server_config.dart';
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
                    const Icon(AuroraIcons.mcp,
                        size: 48, color: Colors.grey),
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: fluent.Expander(
                      header: _buildServerHeader(
                        context,
                        theme,
                        l10n,
                        server,
                      ),
                      content: _buildServerDetails(theme, l10n, server),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServerHeader(
    BuildContext context,
    fluent.FluentThemeData theme,
    AppLocalizations l10n,
    McpServerConfig server,
  ) {
    final isTesting = _testingServerIds.contains(server.id);
    final commandSummary = [
      server.command,
      ...server.args,
    ].where((s) => s.trim().isNotEmpty).join(' ');

    return Row(
      children: [
        Icon(
          AuroraIcons.mcp,
          size: 16,
          color: server.enabled ? theme.accentColor : theme.typography.caption?.color,
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
                  color: server.enabled ? null : theme.typography.caption?.color,
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
        fluent.ToggleSwitch(
          checked: server.enabled,
          onChanged: (v) => ref
              .read(mcpServerProvider.notifier)
              .toggleEnabled(server.id, v),
        ),
        const SizedBox(width: 8),
        fluent.Tooltip(
          message: l10n.mcpTestConnection,
          child: fluent.IconButton(
            icon: isTesting
                ? const SizedBox(
                    width: 14, height: 14, child: fluent.ProgressRing(strokeWidth: 2))
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
    fluent.FluentThemeData theme,
    AppLocalizations l10n,
    McpServerConfig server,
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          kv(l10n.mcpCommand, server.command),
          kv(l10n.mcpArgs,
              server.args.isEmpty ? l10n.none : server.args.join('\n')),
          kv(l10n.mcpCwd, server.cwd ?? l10n.none),
          kv(l10n.mcpEnv, envText),
          kv(l10n.mcpRunInShell, server.runInShell ? l10n.yes : l10n.no),
        ],
      ),
    );
  }

  Future<void> _testServer(BuildContext context, McpServerConfig server) async {
    setState(() => _testingServerIds.add(server.id));
    final result = await ref.read(mcpServerProvider.notifier).testConnection(server);
    if (!context.mounted) return;
    setState(() => _testingServerIds.remove(server.id));
    _showTestResultDialog(context, server, result);
  }

  void _showTestResultDialog(
    BuildContext context,
    McpServerConfig server,
    McpTestResult result,
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

  Widget _formatToolsResult(AppLocalizations l10n, McpTestResult result) {
    final tools = result.tools;
    final toolNames = tools.map((t) => t.name).where((s) => s.isNotEmpty).toList()
      ..sort();
    final stderr = result.stderrLines.join('\n').trim();

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
          child: Text(
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
            child: Text(
              stderr,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _formatErrorResult(AppLocalizations l10n, McpTestResult result) {
    final stderr = result.stderrLines.join('\n').trim();
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
            child: Text(
              stderr,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, McpServerConfig server) async {
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
              await ref.read(mcpServerProvider.notifier).deleteServer(server.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              showAuroraNotice(context, l10n.deleteSuccess, icon: AuroraIcons.success);
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
    final commandController = TextEditingController(text: server?.command ?? '');
    final argsController =
        TextEditingController(text: (server?.args ?? const []).join('\n'));
    final cwdController = TextEditingController(text: server?.cwd ?? '');
    final envController = TextEditingController(
        text: (server?.env.entries.map((e) => '${e.key}=${e.value}').toList() ??
                const <String>[])
            .join('\n'));

    bool enabled = server?.enabled ?? true;
    bool runInShell = server?.runInShell ?? Platform.isWindows;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return fluent.ContentDialog(
            title: Text(server == null ? l10n.mcpAddServer : l10n.mcpEditServer),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mcpServerName,
                        style: themeTextLabel(ctx)),
                    const SizedBox(height: 6),
                    fluent.TextBox(
                      controller: nameController,
                      placeholder: l10n.mcpServerNameHint,
                    ),
                    const SizedBox(height: 12),
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
                      placeholder: l10n.mcpEnvHint,
                      maxLines: null,
                    ),
                    const SizedBox(height: 12),
                    fluent.Checkbox(
                      checked: enabled,
                      onChanged: (v) => setState(() => enabled = v ?? true),
                      content: Text(l10n.enabledStatus),
                    ),
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
                  if (name.isEmpty || command.isEmpty) {
                    showAuroraNotice(
                      context,
                      l10n.mcpValidationError,
                      icon: AuroraIcons.error,
                    );
                    return;
                  }

                  final args = const LineSplitter()
                      .convert(argsController.text)
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(growable: false);
                  final cwd = cwdController.text.trim().isEmpty
                      ? null
                      : cwdController.text.trim();
                  final env = _parseEnv(envController.text);

                  if (server == null) {
                    await ref.read(mcpServerProvider.notifier).addServer(
                          name: name,
                          command: command,
                          args: args,
                          cwd: cwd,
                          env: env,
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
                          command: command,
                          args: args,
                          cwd: cwd,
                          env: env,
                          enabled: enabled,
                          runInShell: runInShell,
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

  Map<String, String> _parseEnv(String raw) {
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
