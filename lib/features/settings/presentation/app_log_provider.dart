import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/utils/app_log_repository.dart';
import 'package:aurora/shared/utils/app_logger.dart';

final appLogRepositoryProvider =
    StateNotifierProvider<AppLogRepository, AppLogState>((ref) {
  return AppLogRepository();
});

final appLogFilterProvider = StateProvider<Set<AppLogLevel>>((ref) {
  return AppLogLevel.values.toSet();
});

final filteredAppLogEntriesProvider = Provider<List<AppLogEntry>>((ref) {
  final state = ref.watch(appLogRepositoryProvider);
  final selectedLevels = ref.watch(appLogFilterProvider);

  return state.entries
      .where((entry) => selectedLevels.contains(entry.level))
      .toList(growable: false)
      .reversed
      .toList(growable: false);
});
