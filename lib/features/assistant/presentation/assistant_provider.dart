import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../settings/presentation/settings_provider.dart';
import '../data/assistant_entity.dart';
import '../domain/assistant.dart';

class AssistantState {
  final List<Assistant> assistants;
  final String? selectedAssistantId;
  final bool isLoading;

  AssistantState({
    this.assistants = const [],
    this.selectedAssistantId,
    this.isLoading = false,
  });

  Assistant? get selectedAssistant {
    if (selectedAssistantId == null) return null;
    try {
      return assistants.firstWhere((a) => a.id == selectedAssistantId);
    } catch (_) {
      return null;
    }
  }

  AssistantState copyWith({
    List<Assistant>? assistants,
    Object? selectedAssistantId = _sentinel,
    bool? isLoading,
  }) {
    return AssistantState(
      assistants: assistants ?? this.assistants,
      selectedAssistantId: selectedAssistantId == _sentinel
          ? this.selectedAssistantId
          : selectedAssistantId as String?,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

const Object _sentinel = Object();

class AssistantNotifier extends StateNotifier<AssistantState> {
  final Ref _ref;

  AssistantNotifier(this._ref) : super(AssistantState()) {
    loadAssistants();
  }

  Future<void> loadAssistants() async {
    state = state.copyWith(isLoading: true);
    final storage = _ref.read(settingsStorageProvider);
    final entities = await storage.loadAssistants();

    final assistants = entities
        .map((e) => Assistant(
              id: e.assistantId,
              name: e.name,
              avatar: e.avatar,
              description: e.description ?? '',
              systemPrompt: e.systemPrompt,
              preferredModel: e.preferredModel,
              providerId: e.providerId,
              skillIds: e.skillIds,
              knowledgeBaseIds: e.knowledgeBaseIds,
              enableMemory: e.enableMemory,
              memoryProviderId: (e.memoryProviderId?.isEmpty ?? true)
                  ? null
                  : e.memoryProviderId,
              memoryModel:
                  (e.memoryModel?.isEmpty ?? true) ? null : e.memoryModel,
            ))
        .toList();

    final appSettings = await storage.loadAppSettings();
    final lastId = appSettings?.lastAssistantId;

    state = state.copyWith(
      assistants: assistants,
      selectedAssistantId: lastId,
      isLoading: false,
    );
  }

  Future<void> selectAssistant(String? id) async {
    state = state.copyWith(selectedAssistantId: id);
    final storage = _ref.read(settingsStorageProvider);
    await storage.saveLastAssistantId(id);
  }

  Future<void> saveAssistant(Assistant assistant) async {
    final storage = _ref.read(settingsStorageProvider);
    final entity = AssistantEntity()
      ..assistantId = assistant.id
      ..name = assistant.name
      ..avatar = assistant.avatar
      ..description = assistant.description
      ..systemPrompt = assistant.systemPrompt
      ..preferredModel = assistant.preferredModel
      ..providerId = assistant.providerId
      ..skillIds = assistant.skillIds
      ..knowledgeBaseIds = assistant.knowledgeBaseIds
      ..enableMemory = assistant.enableMemory
      ..memoryProviderId = assistant.memoryProviderId
      ..memoryModel = assistant.memoryModel
      ..updatedAt = DateTime.now();

    await storage.saveAssistant(entity);
    await loadAssistants();
  }

  Future<Assistant> createAssistant({
    required String name,
    String? avatar,
    String systemPrompt = '',
  }) async {
    final newAssistant = Assistant(
      id: const Uuid().v4(),
      name: name,
      avatar: avatar,
      systemPrompt: systemPrompt,
    );
    await saveAssistant(newAssistant);
    return newAssistant;
  }

  Future<void> deleteAssistant(String id) async {
    final storage = _ref.read(settingsStorageProvider);
    await storage.deleteAssistant(id);
    if (state.selectedAssistantId == id) {
      await selectAssistant(null);
    }
    await loadAssistants();
  }
}

final assistantProvider =
    StateNotifierProvider<AssistantNotifier, AssistantState>((ref) {
  return AssistantNotifier(ref);
});

final selectedAssistantProvider = Provider<Assistant?>((ref) {
  return ref.watch(assistantProvider).selectedAssistant;
});
