String extractModelDisplayName(String modelId) {
  final trimmedId = modelId.trim();
  final match = RegExp(r'[^/]+$').firstMatch(trimmedId);
  final normalizedName = match?.group(0)?.trim();
  if (normalizedName == null || normalizedName.isEmpty) {
    return trimmedId;
  }
  return normalizedName;
}

String resolveModelDisplayName(
  String modelId,
  Map<String, int> displayNameCounts,
) {
  final displayName = extractModelDisplayName(modelId);
  if ((displayNameCounts[displayName] ?? 0) > 1) {
    return modelId;
  }
  return displayName;
}

Map<String, int> buildModelDisplayNameCounts(List<String> modelIds) {
  final counts = <String, int>{};
  for (final modelId in modelIds) {
    final displayName = extractModelDisplayName(modelId);
    counts[displayName] = (counts[displayName] ?? 0) + 1;
  }
  return counts;
}
