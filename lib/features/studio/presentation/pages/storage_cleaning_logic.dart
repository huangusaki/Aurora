import 'package:aurora/features/cleaner/domain/cleaner_models.dart';
import 'package:aurora/features/cleaner/presentation/cleaner_provider.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/riverpod_legacy.dart';

const String storageCleaningDefaultExecutionModelKey =
    '__default_execution_model__';

enum StorageCleaningSizeFilter {
  all,
  oneToTenMb,
  tenToHundredMb,
  overHundredMb,
}

class StorageCleaningExecutionModelChoice {
  final String key;
  final String label;
  final String? model;
  final String? providerId;

  const StorageCleaningExecutionModelChoice({
    required this.key,
    required this.label,
    required this.model,
    required this.providerId,
  });
}

class StorageCleaningLogic {
  static const int _bytesPerMb = 1024 * 1024;

  static List<StorageCleaningExecutionModelChoice> buildExecutionModelChoices({
    required SettingsState settings,
    required String defaultKey,
    required String defaultLabel,
  }) {
    final choices = <StorageCleaningExecutionModelChoice>[
      StorageCleaningExecutionModelChoice(
        key: defaultKey,
        label: defaultLabel,
        model: null,
        providerId: null,
      ),
    ];

    for (final provider in settings.providers) {
      if (!provider.isEnabled || provider.models.isEmpty) {
        continue;
      }
      for (final model in provider.models) {
        if (!provider.isModelEnabled(model)) {
          continue;
        }
        choices.add(
          StorageCleaningExecutionModelChoice(
            key: '${provider.id}::$model',
            label: '${provider.name} - $model',
            model: model,
            providerId: provider.id,
          ),
        );
      }
    }
    return choices;
  }

  static String currentExecutionModelChoiceKey({
    required SettingsState settings,
    required List<StorageCleaningExecutionModelChoice> choices,
    required String defaultKey,
  }) {
    final model = settings.executionModel;
    if (model == null || model.trim().isEmpty) {
      return defaultKey;
    }

    final providerId =
        (settings.executionProviderId ?? settings.activeProviderId).trim();
    final key = '$providerId::$model';
    final exists = choices.any((choice) => choice.key == key);
    return exists ? key : defaultKey;
  }

  static void setExecutionModelByKey({
    required WidgetRef ref,
    required String key,
    required List<StorageCleaningExecutionModelChoice> choices,
    required String defaultKey,
  }) {
    if (key == defaultKey) {
      ref
          .read(settingsProvider.notifier)
          .setExecutionSettings(model: null, providerId: null);
      return;
    }

    for (final choice in choices) {
      if (choice.key != key) {
        continue;
      }
      ref.read(settingsProvider.notifier).setExecutionSettings(
            model: choice.model,
            providerId: choice.providerId,
          );
      return;
    }
  }

  static Future<Set<String>> runAnalyze({
    required WidgetRef ref,
    required List<String> selectedRoots,
    required bool detectDuplicates,
  }) async {
    final notifier = ref.read(cleanerProvider.notifier);
    final roots = List<String>.from(selectedRoots);
    final hasUserRoots = roots.isNotEmpty;

    await notifier.analyze(
      options: CleanerScanOptions(
        includeAppCache: true,
        includeTemporary: true,
        includeCommonUserRoots: true,
        additionalRootPaths: roots,
        includeUserSelectedRoots: hasUserRoots,
        includeUnknownInUserSelectedRoots: hasUserRoots,
        detectDuplicates: detectDuplicates,
      ),
    );

    final result = ref.read(cleanerProvider).runResult;
    if (result == null) {
      return const <String>{};
    }
    return recommendedCandidateIds(result.items);
  }

  static Future<Set<String>> continueAnalyze({
    required WidgetRef ref,
  }) async {
    await ref.read(cleanerProvider.notifier).continueAnalyze();
    final result = ref.read(cleanerProvider).runResult;
    if (result == null) {
      return const <String>{};
    }
    return recommendedCandidateIds(result.items);
  }

  static Future<void> deleteSelected({
    required WidgetRef ref,
    required Set<String> selectedCandidateIds,
  }) async {
    if (selectedCandidateIds.isEmpty) {
      return;
    }
    await ref
        .read(cleanerProvider.notifier)
        .deleteByIds(selectedCandidateIds.toList());
  }

  static Future<void> deleteByRecommendation({
    required WidgetRef ref,
    required bool includeReviewRequired,
  }) {
    return ref.read(cleanerProvider.notifier).deleteRecommended(
          includeReviewRequired: includeReviewRequired,
        );
  }

  static Set<String> recommendedCandidateIds(
      Iterable<CleanerReviewItem> items) {
    return items
        .where((item) => item.finalDecision == CleanerDecision.deleteRecommend)
        .map((item) => item.candidate.id)
        .toSet();
  }

  static List<CleanerReviewItem> applyFilters({
    required Iterable<CleanerReviewItem> items,
    required StorageCleaningSizeFilter sizeFilter,
    required CleanerRiskLevel? riskFilter,
  }) {
    return items.where((item) {
      if (!matchesSizeFilter(
          bytes: item.candidate.sizeBytes, filter: sizeFilter)) {
        return false;
      }
      if (riskFilter != null && item.finalRiskLevel != riskFilter) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  static Map<StorageCleaningSizeFilter, int> buildSizeCounts(
    Iterable<CleanerReviewItem> items,
  ) {
    final counts = <StorageCleaningSizeFilter, int>{
      StorageCleaningSizeFilter.oneToTenMb: 0,
      StorageCleaningSizeFilter.tenToHundredMb: 0,
      StorageCleaningSizeFilter.overHundredMb: 0,
    };
    for (final item in items) {
      final bucket = sizeBucketForBytes(item.candidate.sizeBytes);
      if (bucket == null) {
        continue;
      }
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  static Map<CleanerRiskLevel, int> buildRiskCounts(
    Iterable<CleanerReviewItem> items,
  ) {
    final counts = <CleanerRiskLevel, int>{
      CleanerRiskLevel.low: 0,
      CleanerRiskLevel.medium: 0,
      CleanerRiskLevel.high: 0,
    };
    for (final item in items) {
      counts[item.finalRiskLevel] = (counts[item.finalRiskLevel] ?? 0) + 1;
    }
    return counts;
  }

  static bool matchesSizeFilter({
    required int bytes,
    required StorageCleaningSizeFilter filter,
  }) {
    switch (filter) {
      case StorageCleaningSizeFilter.all:
        return true;
      case StorageCleaningSizeFilter.oneToTenMb:
        return bytes >= _bytesPerMb && bytes < 10 * _bytesPerMb;
      case StorageCleaningSizeFilter.tenToHundredMb:
        return bytes >= 10 * _bytesPerMb && bytes < 100 * _bytesPerMb;
      case StorageCleaningSizeFilter.overHundredMb:
        return bytes >= 100 * _bytesPerMb;
    }
  }

  static StorageCleaningSizeFilter? sizeBucketForBytes(int bytes) {
    if (bytes >= 100 * _bytesPerMb) {
      return StorageCleaningSizeFilter.overHundredMb;
    }
    if (bytes >= 10 * _bytesPerMb) {
      return StorageCleaningSizeFilter.tenToHundredMb;
    }
    if (bytes >= _bytesPerMb) {
      return StorageCleaningSizeFilter.oneToTenMb;
    }
    return null;
  }

  static String sizeBucketLabel(int bytes) {
    final bucket = sizeBucketForBytes(bytes);
    if (bucket == null) {
      return '<1MB';
    }

    return switch (bucket) {
      StorageCleaningSizeFilter.oneToTenMb => '1-10MB',
      StorageCleaningSizeFilter.tenToHundredMb => '10-100MB',
      StorageCleaningSizeFilter.overHundredMb => '>=100MB',
      StorageCleaningSizeFilter.all => '<1MB',
    };
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    final fractionDigits = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
    return '${value.toStringAsFixed(fractionDigits)} ${units[index]}';
  }
}
