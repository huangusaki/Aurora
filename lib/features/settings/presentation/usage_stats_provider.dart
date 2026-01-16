import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_storage.dart';
import '../../chat/data/message_entity.dart';
import '../../../core/error/app_error_type.dart';
import '../data/usage_stats_entity.dart';
import '../data/daily_usage_stats_entity.dart';
import 'settings_provider.dart';


typedef UsageStatsRecord = ({
  int success,
  int failure,
  int totalDurationMs,
  int validDurationCount,
  int totalFirstTokenMs,
  int validFirstTokenCount,
  int totalTokenCount,
  // Error counts
  int errorTimeoutCount,
  int errorNetworkCount,
  int errorBadRequestCount,
  int errorUnauthorizedCount,
  int errorServerCount,
  int errorRateLimitCount,
  int errorUnknownCount,
});

class UsageStatsState {
  final Map<String, UsageStatsRecord> stats;
  final List<DailyUsageStatsEntity> dailyStats;
  final bool isLoading;
  const UsageStatsState({
    this.stats = const <String, UsageStatsRecord>{},
    this.dailyStats = const [],
    this.isLoading = false,
  });
  UsageStatsState copyWith({
    Map<String, UsageStatsRecord>? stats,
    List<DailyUsageStatsEntity>? dailyStats,
    bool? isLoading,
  }) {
    return UsageStatsState(
      stats: stats ?? this.stats,
      dailyStats: dailyStats ?? this.dailyStats,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get totalCalls =>
      stats.values.fold(0, (sum, s) => sum + s.success + s.failure);
  int get totalSuccess => stats.values.fold(0, (sum, s) => sum + s.success);
  int get totalFailure => stats.values.fold(0, (sum, s) => sum + s.failure);
  int get totalTokens => stats.values.fold(0, (sum, s) => sum + s.totalTokenCount);
}

class UsageStatsNotifier extends StateNotifier<UsageStatsState> {
  final SettingsStorage _storage;
  UsageStatsNotifier(this._storage) : super(const UsageStatsState()) {
    loadStats();
  }
  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true);
    final entities = await _storage.loadAllUsageStats();
    final dailyParams = await _storage.loadDailyStats(30);

    final statsMap = <String, UsageStatsRecord>{};
    for (final e in entities) {
      statsMap[e.modelName] = (
        success: e.successCount,
        failure: e.failureCount,
        totalDurationMs: e.totalDurationMs,
        validDurationCount: e.validDurationCount,
        totalFirstTokenMs: e.totalFirstTokenMs,
        validFirstTokenCount: e.validFirstTokenCount,
        totalTokenCount: e.totalTokenCount,
        errorTimeoutCount: e.errorTimeoutCount,
        errorNetworkCount: e.errorNetworkCount,
        errorBadRequestCount: e.errorBadRequestCount,
        errorUnauthorizedCount: e.errorUnauthorizedCount,
        errorServerCount: e.errorServerCount,
        errorRateLimitCount: e.errorRateLimitCount,
        errorUnknownCount: e.errorUnknownCount,
      );
    }
    state = UsageStatsState(stats: statsMap, dailyStats: dailyParams, isLoading: false);
  }

  Future<void> incrementUsage(String modelName,
      {bool success = true,
      int durationMs = 0,
      int firstTokenMs = 0,
      int tokenCount = 0,
      AppErrorType? errorType}) async {
    await _storage.incrementUsage(modelName,
        success: success,
        durationMs: durationMs,
        firstTokenMs: firstTokenMs,
        tokenCount: tokenCount,
        errorType: errorType);
    final current = state.stats[modelName] ??
        (
          success: 0,
          failure: 0,
          totalDurationMs: 0,
          validDurationCount: 0,
          totalFirstTokenMs: 0,
          validFirstTokenCount: 0,
          totalTokenCount: 0,
          errorTimeoutCount: 0,
          errorNetworkCount: 0,
          errorBadRequestCount: 0,
          errorUnauthorizedCount: 0,
          errorServerCount: 0,
          errorRateLimitCount: 0,
          errorUnknownCount: 0,
        );
    final newStats = Map<String, UsageStatsRecord>.from(state.stats);
    newStats[modelName] = (
      success: current.success + (success ? 1 : 0),
      failure: current.failure + (success ? 0 : 1),
      totalDurationMs:
          current.totalDurationMs + (durationMs > 0 ? durationMs : 0),
      validDurationCount:
          current.validDurationCount + (durationMs > 0 ? 1 : 0),
      totalFirstTokenMs:
          current.totalFirstTokenMs + (firstTokenMs > 0 ? firstTokenMs : 0),
      validFirstTokenCount:
          current.validFirstTokenCount + (firstTokenMs > 0 ? 1 : 0),
      totalTokenCount: current.totalTokenCount + tokenCount,
      errorTimeoutCount: current.errorTimeoutCount + (errorType == AppErrorType.timeout ? 1 : 0),
      errorNetworkCount: current.errorNetworkCount + (errorType == AppErrorType.network ? 1 : 0),
      errorBadRequestCount: current.errorBadRequestCount + (errorType == AppErrorType.badRequest ? 1 : 0),
      errorUnauthorizedCount: current.errorUnauthorizedCount + (errorType == AppErrorType.unauthorized ? 1 : 0),
      errorServerCount: current.errorServerCount + (errorType == AppErrorType.serverError ? 1 : 0),
      errorRateLimitCount: current.errorRateLimitCount + (errorType == AppErrorType.rateLimit ? 1 : 0),
      errorUnknownCount: current.errorUnknownCount + (errorType == AppErrorType.unknown ? 1 : 0),
    );
    // Reload to get fresh daily stats
    loadStats();
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
