import 'app_logger.dart';

class LlmStreamLogAccumulator {
  LlmStreamLogAccumulator({
    required this.providerId,
    required this.model,
  }) : _stopwatch = Stopwatch()..start();

  final String providerId;
  final String model;
  final Stopwatch _stopwatch;

  int _sseEvents = 0;
  int _emittedChunks = 0;
  int _contentChars = 0;
  int _reasoningChars = 0;
  int _imageCount = 0;
  int _parseErrorCount = 0;
  bool _doneMarkerSeen = false;
  String? _finishReason;
  int? _usage;
  int? _promptTokens;
  int? _completionTokens;
  int? _reasoningTokens;
  bool _logged = false;

  void recordSseEvent() {
    _sseEvents++;
  }

  void recordDoneMarkerSeen() {
    _doneMarkerSeen = true;
  }

  void recordParseError() {
    _parseErrorCount++;
  }

  void recordUsage({
    int? usage,
    int? promptTokens,
    int? completionTokens,
    int? reasoningTokens,
  }) {
    if (usage != null) _usage = usage;
    if (promptTokens != null) _promptTokens = promptTokens;
    if (completionTokens != null) _completionTokens = completionTokens;
    if (reasoningTokens != null) _reasoningTokens = reasoningTokens;
  }

  void recordEmission({
    String? content,
    String? reasoning,
    int imageCount = 0,
    String? finishReason,
  }) {
    _emittedChunks++;
    if (content != null) _contentChars += content.length;
    if (reasoning != null) _reasoningChars += reasoning.length;
    _imageCount += imageCount;

    final normalizedFinishReason = finishReason?.trim();
    if (normalizedFinishReason != null && normalizedFinishReason.isNotEmpty) {
      _finishReason = normalizedFinishReason;
    }
  }

  void logCompleted() {
    _log(outcome: 'completed', message: 'stream completed');
  }

  void logCancelled() {
    _log(outcome: 'cancelled', message: 'stream cancelled');
  }

  void _log({
    required String outcome,
    required String message,
  }) {
    if (_logged) return;
    _logged = true;
    _stopwatch.stop();

    AppLogger.info(
      'LLM',
      message,
      category: 'STREAM',
      data: {
        'outcome': outcome,
        'provider_id': providerId,
        'model': model,
        'duration_ms': _stopwatch.elapsedMilliseconds,
        'sse_events': _sseEvents,
        'emitted_chunks': _emittedChunks,
        'done_marker_seen': _doneMarkerSeen,
        'finish_reason': _finishReason,
        'content_chars': _contentChars,
        'reasoning_chars': _reasoningChars,
        'image_count': _imageCount,
        'parse_error_count': _parseErrorCount,
        'prompt_tokens': _promptTokens,
        'completion_tokens': _completionTokens,
        'reasoning_tokens': _reasoningTokens,
        'usage': _usage,
      },
    );
  }
}
