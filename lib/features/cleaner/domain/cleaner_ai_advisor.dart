import 'cleaner_models.dart';

typedef CleanerAiProgressCallback = void Function(
  List<CleanerAiSuggestion> partialSuggestions,
  CleanerAiProgress progress,
);

abstract class CleanerAiAdvisor {
  Future<List<CleanerAiSuggestion>> suggest({
    required List<CleanerCandidate> candidates,
    required CleanerAiContext context,
    CleanerAiProgressCallback? onProgress,
    bool Function()? shouldStop,
  });
}
