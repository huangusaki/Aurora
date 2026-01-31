class StatsCalculator {
  /// Calculates Tokens Per Second (TPS) representing generation speed.
  /// 
  /// Formula: (Completion + Reasoning) / (Duration - TTFT)
  /// 
  /// [completionTokens]: Number of tokens in the final text response.
  /// [reasoningTokens]: Number of tokens used for reasoning (if applicable).
  /// [durationMs]: Total request duration in milliseconds.
  /// [firstTokenMs]: Time to first token in milliseconds (latency).
  /// 
  /// Returns 0.0 if duration is invalid or no tokens generated.
  static double calculateTPS({
    required int completionTokens,
    required int reasoningTokens,
    required int durationMs,
    required int firstTokenMs,
  }) {
    // 1. Calculate effective generation duration
    // If we have a valid TTFT that is smaller than total duration, exclude it.
    // Otherwise, use total duration (fallback).
    int generationDurationMs = durationMs;
    if (firstTokenMs > 0 && firstTokenMs < durationMs) {
      generationDurationMs = durationMs - firstTokenMs;
    }

    if (generationDurationMs <= 0) return 0.0;

    // 2. Calculate total generated tokens (Strictly excluding prompt)
    final totalGenerated = completionTokens + reasoningTokens;
    if (totalGenerated <= 0) return 0.0;

    // 3. Calculate TPS
    final seconds = generationDurationMs / 1000.0;
    return totalGenerated / seconds;
  }
}
