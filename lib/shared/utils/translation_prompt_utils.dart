class TranslationPromptUtils {
  static const String _sourceMarker = '原文内容：';
  static const String _promptHint = '你是一位精通多国语言的专业翻译专家';

  static String extractSourceText(String content) {
    final markerIndex = content.lastIndexOf(_sourceMarker);
    if (markerIndex == -1) return content;

    final prefix = content.substring(0, markerIndex);
    if (!prefix.contains(_promptHint)) return content;

    var extracted = content.substring(markerIndex + _sourceMarker.length);
    if (extracted.startsWith('\r\n')) {
      extracted = extracted.substring(2);
    } else if (extracted.startsWith('\n') || extracted.startsWith('\r')) {
      extracted = extracted.substring(1);
    }
    return extracted;
  }
}
