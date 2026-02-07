import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/settings_provider.dart';
import '../data/knowledge_storage.dart';
import '../domain/knowledge_models.dart';

class KnowledgeState {
  final List<KnowledgeBaseSummary> bases;
  final bool isLoading;
  final bool isWorking;
  final String? error;

  const KnowledgeState({
    this.bases = const [],
    this.isLoading = false,
    this.isWorking = false,
    this.error,
  });

  KnowledgeState copyWith({
    List<KnowledgeBaseSummary>? bases,
    bool? isLoading,
    bool? isWorking,
    String? error,
  }) {
    return KnowledgeState(
      bases: bases ?? this.bases,
      isLoading: isLoading ?? this.isLoading,
      isWorking: isWorking ?? this.isWorking,
      error: error,
    );
  }
}

class KnowledgeNotifier extends StateNotifier<KnowledgeState> {
  KnowledgeNotifier(this._storage) : super(const KnowledgeState()) {
    loadBases();
  }

  final KnowledgeStorage _storage;

  Future<void> loadBases() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bases = await _storage.loadBaseSummaries();
      state = state.copyWith(bases: bases, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createBase(
      {required String name, String description = ''}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(isWorking: true, error: null);
    try {
      await _storage.createBase(name: trimmed, description: description);
      await loadBases();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isWorking: false);
    }
  }

  Future<void> deleteBase(String baseId) async {
    state = state.copyWith(isWorking: true, error: null);
    try {
      await _storage.deleteBase(baseId);
      await loadBases();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isWorking: false);
    }
  }

  Future<void> setBaseEnabled(String baseId, bool enabled) async {
    try {
      await _storage.updateBase(baseId: baseId, isEnabled: enabled);
      await loadBases();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<KnowledgeIngestReport> ingestFiles({
    required String baseId,
    required List<String> paths,
    required SettingsState settings,
  }) async {
    state = state.copyWith(isWorking: true, error: null);
    try {
      final provider = _resolveEmbeddingProvider(settings);
      final report = await _storage.ingestFiles(
        baseId: baseId,
        filePaths: paths,
        useEmbedding: settings.knowledgeUseEmbedding,
        embeddingModel: settings.knowledgeEmbeddingModel,
        embeddingProvider: provider,
      );
      await loadBases();
      return report;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isWorking: false);
    }
  }

  ProviderConfig? _resolveEmbeddingProvider(SettingsState settings) {
    final providerId =
        settings.knowledgeEmbeddingProviderId ?? settings.activeProviderId;
    for (final provider in settings.providers) {
      if (provider.id == providerId) return provider;
    }
    return null;
  }
}

final knowledgeStorageProvider = Provider<KnowledgeStorage>((ref) {
  final settingsStorage = ref.watch(settingsStorageProvider);
  return KnowledgeStorage(settingsStorage);
});

final knowledgeProvider =
    StateNotifierProvider<KnowledgeNotifier, KnowledgeState>((ref) {
  final storage = ref.watch(knowledgeStorageProvider);
  return KnowledgeNotifier(storage);
});
