class McpServerConfig {
  final String id;
  final String name;
  final bool enabled;
  final String command;
  final List<String> args;
  final String? cwd;
  final Map<String, String> env;
  final bool runInShell;

  const McpServerConfig({
    required this.id,
    required this.name,
    required this.command,
    this.args = const [],
    this.enabled = true,
    this.cwd,
    this.env = const {},
    this.runInShell = false,
  });

  McpServerConfig copyWith({
    String? id,
    String? name,
    bool? enabled,
    String? command,
    List<String>? args,
    String? cwd,
    Map<String, String>? env,
    bool? runInShell,
  }) {
    return McpServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      command: command ?? this.command,
      args: args ?? this.args,
      cwd: cwd ?? this.cwd,
      env: env ?? this.env,
      runInShell: runInShell ?? this.runInShell,
    );
  }

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    final rawArgs = json['args'];
    final args = rawArgs is List
        ? rawArgs.map((e) => e.toString()).toList()
        : const <String>[];

    final rawEnv = json['env'];
    final env = <String, String>{};
    if (rawEnv is Map) {
      for (final entry in rawEnv.entries) {
        env[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }

    final rawCwd = json['cwd']?.toString();
    final cwd = (rawCwd != null && rawCwd.trim().isNotEmpty) ? rawCwd : null;

    return McpServerConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      enabled: json['enabled'] == true,
      command: json['command']?.toString() ?? '',
      args: args,
      cwd: cwd,
      env: env,
      runInShell: json['runInShell'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'command': command,
      'args': args,
      'cwd': cwd,
      'env': env,
      'runInShell': runInShell,
    };
  }
}

