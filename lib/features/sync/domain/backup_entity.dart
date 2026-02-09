class BackupEntity {
  final int version;
  final DateTime createdAt;
  final List<SessionBackup> sessions;
  final List<MessageBackup> messages;
  final List<TopicBackup> topics;
  final List<ChatPresetBackup> chatPresets;
  final List<ProviderConfigBackup> providerConfigs;
  final Map<String, dynamic>? studioContent;
  final Map<String, dynamic> preferences;

  BackupEntity({
    required this.version,
    required this.createdAt,
    this.sessions = const [],
    this.messages = const [],
    this.topics = const [],
    this.chatPresets = const [],
    this.providerConfigs = const [],
    this.studioContent,
    this.preferences = const {},
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'topics': topics.map((t) => t.toJson()).toList(),
        'chatPresets': chatPresets.map((p) => p.toJson()).toList(),
        'providerConfigs': providerConfigs.map((c) => c.toJson()).toList(),
        'studioContent': studioContent,
        'preferences': preferences,
      };

  factory BackupEntity.fromJson(Map<String, dynamic> json) => BackupEntity(
        version: json['version'] as int? ?? 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        sessions: (json['sessions'] as List<dynamic>?)
                ?.map((e) => SessionBackup.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        messages: (json['messages'] as List<dynamic>?)
                ?.map((e) => MessageBackup.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        topics: (json['topics'] as List<dynamic>?)
                ?.map((e) => TopicBackup.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        chatPresets: (json['chatPresets'] as List<dynamic>?)
                ?.map(
                    (e) => ChatPresetBackup.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        providerConfigs: (json['providerConfigs'] as List<dynamic>?)
                ?.map((e) =>
                    ProviderConfigBackup.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        studioContent: json['studioContent'] as Map<String, dynamic>?,
        preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      );
}

class SessionBackup {
  final String sessionId;
  final String title;
  final DateTime lastMessageTime;
  final String? snippet;
  final int? topicId;
  final String? topicName;
  final String? presetId;
  final int totalTokens;

  SessionBackup({
    required this.sessionId,
    required this.title,
    required this.lastMessageTime,
    this.snippet,
    this.topicId,
    this.topicName,
    this.presetId,
    this.totalTokens = 0,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'title': title,
        'lastMessageTime': lastMessageTime.toIso8601String(),
        'snippet': snippet,
        'topicId': topicId,
        'topicName': topicName,
        'presetId': presetId,
        'totalTokens': totalTokens,
      };

  factory SessionBackup.fromJson(Map<String, dynamic> json) => SessionBackup(
        sessionId: json['sessionId'] as String,
        title: json['title'] as String,
        lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
        snippet: json['snippet'] as String?,
        topicId: json['topicId'] as int?,
        topicName: json['topicName'] as String?,
        presetId: json['presetId'] as String?,
        totalTokens: json['totalTokens'] as int? ?? 0,
      );
}

class MessageBackup {
  final DateTime timestamp;
  final bool isUser;
  final String content;
  final String? reasoningContent;
  final List<String> attachments;
  final List<String> images;
  final String? sessionId;
  final String? assistantId;
  final String? requestId;
  final String? model;
  final String? provider;
  final double? reasoningDurationSeconds;
  final String? role;
  final String? toolCallId;
  final String? toolCallsJson;
  final int? tokenCount;
  final int? promptTokens;
  final int? completionTokens;
  final int? reasoningTokens;
  final int? firstTokenMs;
  final int? durationMs;

  MessageBackup({
    required this.timestamp,
    required this.isUser,
    required this.content,
    this.reasoningContent,
    this.attachments = const [],
    this.images = const [],
    this.sessionId,
    this.assistantId,
    this.requestId,
    this.model,
    this.provider,
    this.reasoningDurationSeconds,
    this.role,
    this.toolCallId,
    this.toolCallsJson,
    this.tokenCount,
    this.promptTokens,
    this.completionTokens,
    this.reasoningTokens,
    this.firstTokenMs,
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'isUser': isUser,
        'content': content,
        'reasoningContent': reasoningContent,
        'attachments': attachments,
        'images': images,
        'sessionId': sessionId,
        'assistantId': assistantId,
        'requestId': requestId,
        'model': model,
        'provider': provider,
        'reasoningDurationSeconds': reasoningDurationSeconds,
        'role': role,
        'toolCallId': toolCallId,
        'toolCallsJson': toolCallsJson,
        'tokenCount': tokenCount,
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'reasoningTokens': reasoningTokens,
        'firstTokenMs': firstTokenMs,
        'durationMs': durationMs,
      };

  factory MessageBackup.fromJson(Map<String, dynamic> json) => MessageBackup(
        timestamp: DateTime.parse(json['timestamp'] as String),
        isUser: json['isUser'] as bool,
        content: json['content'] as String,
        reasoningContent: json['reasoningContent'] as String?,
        attachments:
            (json['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
        images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
        sessionId: json['sessionId'] as String?,
        assistantId: json['assistantId'] as String?,
        requestId: json['requestId'] as String?,
        model: json['model'] as String?,
        provider: json['provider'] as String?,
        reasoningDurationSeconds:
            (json['reasoningDurationSeconds'] as num?)?.toDouble(),
        role: json['role'] as String?,
        toolCallId: json['toolCallId'] as String?,
        toolCallsJson: json['toolCallsJson'] as String?,
        tokenCount: json['tokenCount'] as int?,
        promptTokens: json['promptTokens'] as int?,
        completionTokens: json['completionTokens'] as int?,
        reasoningTokens: json['reasoningTokens'] as int?,
        firstTokenMs: json['firstTokenMs'] as int?,
        durationMs: json['durationMs'] as int?,
      );
}

class TopicBackup {
  final String name;
  final DateTime createdAt;

  TopicBackup({
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TopicBackup.fromJson(Map<String, dynamic> json) => TopicBackup(
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class ChatPresetBackup {
  final String presetId;
  final String name;
  final String? description;
  final String systemPrompt;

  ChatPresetBackup({
    required this.presetId,
    required this.name,
    this.description,
    required this.systemPrompt,
  });

  Map<String, dynamic> toJson() => {
        'presetId': presetId,
        'name': name,
        'description': description,
        'systemPrompt': systemPrompt,
      };

  factory ChatPresetBackup.fromJson(Map<String, dynamic> json) =>
      ChatPresetBackup(
        presetId: json['presetId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        systemPrompt: json['systemPrompt'] as String,
      );
}

class ProviderConfigBackup {
  final String providerId;
  final String name;
  final String? color;
  final List<String> apiKeys;
  final int currentKeyIndex;
  final bool autoRotateKeys;
  final String baseUrl;
  final bool isCustom;
  final String? customParametersJson;
  final String? modelSettingsJson;
  final String? globalSettingsJson;
  final List<String> globalExcludeModels;
  final List<String> savedModels;
  final String? lastSelectedModel;
  final bool isActive;
  final bool isEnabled;

  ProviderConfigBackup({
    required this.providerId,
    required this.name,
    this.color,
    required this.apiKeys,
    this.currentKeyIndex = 0,
    this.autoRotateKeys = false,
    required this.baseUrl,
    this.isCustom = false,
    this.customParametersJson,
    this.modelSettingsJson,
    this.globalSettingsJson,
    this.globalExcludeModels = const [],
    this.savedModels = const [],
    this.lastSelectedModel,
    this.isActive = false,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'name': name,
        'color': color,
        'apiKeys': apiKeys,
        'currentKeyIndex': currentKeyIndex,
        'autoRotateKeys': autoRotateKeys,
        'baseUrl': baseUrl,
        'isCustom': isCustom,
        'customParametersJson': customParametersJson,
        'modelSettingsJson': modelSettingsJson,
        'globalSettingsJson': globalSettingsJson,
        'globalExcludeModels': globalExcludeModels,
        'savedModels': savedModels,
        'lastSelectedModel': lastSelectedModel,
        'isActive': isActive,
        'isEnabled': isEnabled,
      };

  factory ProviderConfigBackup.fromJson(Map<String, dynamic> json) =>
      ProviderConfigBackup(
        providerId: json['providerId'] as String,
        name: json['name'] as String,
        color: json['color'] as String?,
        apiKeys: (json['apiKeys'] as List<dynamic>?)?.cast<String>() ?? [],
        currentKeyIndex: json['currentKeyIndex'] as int? ?? 0,
        autoRotateKeys: json['autoRotateKeys'] as bool? ?? false,
        baseUrl: json['baseUrl'] as String,
        isCustom: json['isCustom'] as bool? ?? false,
        customParametersJson: json['customParametersJson'] as String?,
        modelSettingsJson: json['modelSettingsJson'] as String?,
        globalSettingsJson: json['globalSettingsJson'] as String?,
        globalExcludeModels:
            (json['globalExcludeModels'] as List<dynamic>?)?.cast<String>() ??
                [],
        savedModels:
            (json['savedModels'] as List<dynamic>?)?.cast<String>() ?? [],
        lastSelectedModel: json['lastSelectedModel'] as String?,
        isActive: json['isActive'] as bool? ?? false,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );
}
