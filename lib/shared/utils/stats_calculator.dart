class StatsCalculator {
  static const int _bufferedTailThresholdMs = 120;
  static const int _smallestSampleWindowMs = 250;
  static const int _smallSampleWindowMs = 200;
  static const int _mediumSampleWindowMs = 150;

  /// Calculates Tokens Per Second (TPS) representing generation speed.
  ///
  /// Formula: (Completion + Reasoning) / effectiveDuration.
  ///
  /// [completionTokens]: Number of tokens in the final text response.
  /// [reasoningTokens]: Number of tokens used for reasoning (if applicable).
  /// [durationMs]: Total request duration in milliseconds.
  /// [firstTokenMs]: Time to first token in milliseconds (latency).
  /// [sampleCount]: Number of aggregated samples represented by the inputs.
  ///
  /// Returns 0.0 if duration is invalid or no tokens generated.
  static double calculateTPS({
    required int completionTokens,
    required int reasoningTokens,
    required int durationMs,
    required int firstTokenMs,
    int sampleCount = 1,
  }) {
    final totalGenerated = completionTokens + reasoningTokens;
    if (durationMs <= 0 || totalGenerated <= 0) return 0.0;

    final normalizedSampleCount = sampleCount <= 0 ? 1 : sampleCount;
    final hasValidFirstToken = firstTokenMs > 0 && firstTokenMs < durationMs;
    final rawGenerationDurationMs =
        hasValidFirstToken ? (durationMs - firstTokenMs) : durationMs;
    if (rawGenerationDurationMs <= 0) return 0.0;

    var effectiveDurationMs = rawGenerationDurationMs;
    final averageGeneratedPerSample = totalGenerated / normalizedSampleCount;

    // If nearly all time was spent waiting for the first packet and the payload
    // arrived in a tiny tail window, treat it like a buffered/non-streaming
    // response instead of subtracting TTFT.
    final looksLikeBufferedResponse = hasValidFirstToken &&
        rawGenerationDurationMs <=
            (_bufferedTailThresholdMs * normalizedSampleCount) &&
        (rawGenerationDurationMs * 5) <= durationMs;
    if (looksLikeBufferedResponse) {
      effectiveDurationMs = durationMs;
    }

    final minimumObservationWindowMs = _minimumObservationWindowMs(
      averageGeneratedPerSample: averageGeneratedPerSample,
      sampleCount: normalizedSampleCount,
    );
    if (effectiveDurationMs < minimumObservationWindowMs) {
      effectiveDurationMs = minimumObservationWindowMs;
    }

    final seconds = effectiveDurationMs / 1000.0;
    return totalGenerated / seconds;
  }

  static int _minimumObservationWindowMs({
    required double averageGeneratedPerSample,
    required int sampleCount,
  }) {
    int perSampleWindowMs;
    if (averageGeneratedPerSample <= 32) {
      perSampleWindowMs = _smallestSampleWindowMs;
    } else if (averageGeneratedPerSample <= 64) {
      perSampleWindowMs = _smallSampleWindowMs;
    } else if (averageGeneratedPerSample <= 128) {
      perSampleWindowMs = _mediumSampleWindowMs;
    } else {
      perSampleWindowMs = 0;
    }

    return perSampleWindowMs * sampleCount;
  }
}
