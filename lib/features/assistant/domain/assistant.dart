const Object _assistantSentinel = Object();

class Assistant {
  final String id;
  final String name;
  final String? avatar;
  final String description;
  final String systemPrompt;
  final String? preferredModel;
  final String? providerId;
  final List<String> skillIds;
  final List<String> knowledgeBaseIds;
  final bool enableMemory;
  final String? memoryProviderId;
  final String? memoryModel;

  const Assistant({
    required this.id,
    required this.name,
    this.avatar,
    this.description = '',
    this.systemPrompt = '',
    this.preferredModel,
    this.providerId,
    this.skillIds = const [],
    this.knowledgeBaseIds = const [],
    this.enableMemory = false,
    this.memoryProviderId,
    this.memoryModel,
  });

  Assistant copyWith({
    String? name,
    String? avatar,
    String? description,
    String? systemPrompt,
    String? preferredModel,
    String? providerId,
    List<String>? skillIds,
    List<String>? knowledgeBaseIds,
    bool? enableMemory,
    Object? memoryProviderId = _assistantSentinel,
    Object? memoryModel = _assistantSentinel,
  }) {
    return Assistant(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      preferredModel: preferredModel ?? this.preferredModel,
      providerId: providerId ?? this.providerId,
      skillIds: skillIds ?? this.skillIds,
      knowledgeBaseIds: knowledgeBaseIds ?? this.knowledgeBaseIds,
      enableMemory: enableMemory ?? this.enableMemory,
      memoryProviderId: memoryProviderId == _assistantSentinel
          ? this.memoryProviderId
          : memoryProviderId as String?,
      memoryModel: memoryModel == _assistantSentinel
          ? this.memoryModel
          : memoryModel as String?,
    );
  }
}
