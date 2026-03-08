const String officialGeminiNativeBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/';

bool isOfficialGeminiNativeBaseUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl.trim());
  final host = (uri?.host ?? '').toLowerCase();
  if (host.isNotEmpty) {
    return host == 'generativelanguage.googleapis.com';
  }
  return baseUrl.toLowerCase().contains('generativelanguage.googleapis.com');
}

bool looksLikeGeminiNativeBaseUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl.trim());
  if (uri == null || uri.host.isEmpty) return false;

  final lowerSegments = uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .map((segment) => segment.toLowerCase())
      .toList();
  final versionIndex = _findGeminiVersionIndex(lowerSegments);

  if (versionIndex != -1) {
    final trailing = lowerSegments.skip(versionIndex + 1);
    return !trailing.contains('openai');
  }

  return isOfficialGeminiNativeBaseUrl(baseUrl) &&
      !lowerSegments.contains('openai');
}

String normalizeGeminiNativeBaseUrl(
  String rawBase, {
  String fallback = officialGeminiNativeBaseUrl,
}) {
  final parsed = Uri.tryParse(rawBase.trim());
  if (parsed == null || parsed.host.isEmpty) return fallback;

  final originalSegments =
      parsed.pathSegments.where((segment) => segment.isNotEmpty).toList();
  final lowerSegments =
      originalSegments.map((segment) => segment.toLowerCase()).toList();
  final versionIndex = _findGeminiVersionIndex(lowerSegments);

  late final List<String> normalizedSegments;
  if (versionIndex != -1) {
    normalizedSegments = originalSegments.sublist(0, versionIndex + 1);
  } else {
    normalizedSegments = _stripTrailingEndpointSegments(originalSegments);
    if (normalizedSegments.isNotEmpty &&
        normalizedSegments.last.toLowerCase() == 'v1') {
      normalizedSegments[normalizedSegments.length - 1] = 'v1beta';
    } else {
      normalizedSegments.add('v1beta');
    }
  }

  final normalized = parsed.replace(
    pathSegments: normalizedSegments,
    query: null,
    fragment: null,
  );

  var base = normalized.toString();
  if (!base.endsWith('/')) {
    base = '$base/';
  }
  return base;
}

List<String> _stripTrailingEndpointSegments(List<String> segments) {
  final trimmed = List<String>.from(segments);

  while (trimmed.isNotEmpty) {
    final last = trimmed.last.toLowerCase();

    if (last == 'openai' ||
        last == 'models' ||
        (last == 'completions' &&
            trimmed.length >= 2 &&
            trimmed[trimmed.length - 2].toLowerCase() == 'chat')) {
      trimmed.removeLast();
      if (last == 'completions' &&
          trimmed.isNotEmpty &&
          trimmed.last.toLowerCase() == 'chat') {
        trimmed.removeLast();
      }
      continue;
    }

    if (last.contains(':') &&
        trimmed.length >= 2 &&
        trimmed[trimmed.length - 2].toLowerCase() == 'models') {
      trimmed.removeLast();
      trimmed.removeLast();
      continue;
    }

    break;
  }

  return trimmed;
}

int _findGeminiVersionIndex(List<String> lowerSegments) {
  final betaIndex = lowerSegments.indexOf('v1beta');
  if (betaIndex != -1) return betaIndex;

  final v1Index = lowerSegments.indexOf('v1');
  if (v1Index == -1) return -1;

  final trailing = lowerSegments.skip(v1Index + 1);
  if (trailing.contains('models') || trailing.any(_looksLikeGeminiAction)) {
    return v1Index;
  }

  return -1;
}

bool _looksLikeGeminiAction(String segment) {
  final lower = segment.toLowerCase();
  return lower.contains(':generatecontent') ||
      lower.contains(':streamgeneratecontent') ||
      lower.contains(':embedcontent') ||
      lower.contains(':batchembedcontents');
}
