// Utilities to prevent message metadata fields (requestId/model/provider/role…)
// from being polluted by unexpectedly large strings.
//
// These fields are treated as metadata and may be indexed in Isar. Storing
// large values here can cause severe database bloat.

const int kMaxMessageRequestIdChars = 128;
const int kMaxMessageModelChars = 128;
const int kMaxMessageProviderChars = 128;
const int kMaxMessageRoleChars = 32;
const int kMaxMessageAssistantIdChars = 128;
const int kMaxMessageToolCallIdChars = 128;

String? _sanitizeShortSingleLine(String? value, {required int maxChars}) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.length > maxChars) return null;
  if (trimmed.contains('\u0000')) return null;
  if (trimmed.contains('\n') || trimmed.contains('\r')) return null;
  return trimmed;
}

String? sanitizeMessageRequestId(String? value) =>
    _sanitizeShortSingleLine(value, maxChars: kMaxMessageRequestIdChars);

String? sanitizeMessageModel(String? value) =>
    _sanitizeShortSingleLine(value, maxChars: kMaxMessageModelChars);

String? sanitizeMessageProvider(String? value) =>
    _sanitizeShortSingleLine(value, maxChars: kMaxMessageProviderChars);

String? sanitizeMessageAssistantId(String? value) =>
    _sanitizeShortSingleLine(value, maxChars: kMaxMessageAssistantIdChars);

String? sanitizeMessageToolCallId(String? value) =>
    _sanitizeShortSingleLine(value, maxChars: kMaxMessageToolCallIdChars);

String? sanitizeMessageRole(String? value) {
  final cleaned =
      _sanitizeShortSingleLine(value, maxChars: kMaxMessageRoleChars);
  return cleaned?.toLowerCase();
}
