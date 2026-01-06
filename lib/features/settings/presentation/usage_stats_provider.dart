import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_storage.dart';
import 'settings_provider.dart';

class UsageStatsState {
  final Map<String, ({int success, int failure})> stats;
  final bool isLoading;

  const UsageStatsState({
    this.stats = const {},
    this.isLoading = false,
  });

  UsageStatsState copyWith({
    Map<String, ({int success, int failure})>? stats,
    bool? isLoading,
  }) {
    return UsageStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get totalCalls => stats.values.fold(0, (sum, s) => sum + s.success + s.failure);
  int get totalSuccess => stats.values.fold(0, (sum, s) => sum + s.success);
  int get totalFailure => stats.values.fold(0, (sum, s) => sum + s.failure);
}

class UsageStatsNotifier extends StateNotifier<UsageStatsState> {
  final SettingsStorage _storage;

  UsageStatsNotifier(this._storage) : super(const UsageStatsState()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true);
    final entities = await _storage.loadAllUsageStats();
    final statsMap = <String, ({int success, int failure})>{};
    for (final e in entities) {
      statsMap[e.modelName] = (success: e.successCount, failure: e.failureCount);
    }
    state = UsageStatsState(stats: statsMap, isLoading: false);
  }

  Future<void> incrementUsage(String modelName, {bool success = true}) async {
    await _storage.incrementUsage(modelName, success: success);
    // Update local state
    final current = state.stats[modelName] ?? (success: 0, failure: 0);
    final newStats = Map<String, ({int success, int failure})>.from(state.stats);
    newStats[modelName] = (
      success: current.success + (success ? 1 : 0),
      failure: current.failure + (success ? 0 : 1),
    );
    state = state.copyWith(stats: newStats);
  }

  Future<void> clearStats() async {
    await _storage.clearUsageStats();
    state = const UsageStatsState();
  }
}

final usageStatsProvider =
    StateNotifierProvider<UsageStatsNotifier, UsageStatsState>((ref) {
  final storage = ref.watch(settingsStorageProvider);
  return UsageStatsNotifier(storage);
});
