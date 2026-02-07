class KnowledgeBaseSummary {
  final String baseId;
  final String name;
  final String description;
  final bool isEnabled;
  final int documentCount;
  final int chunkCount;
  final DateTime updatedAt;

  const KnowledgeBaseSummary({
    required this.baseId,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.documentCount,
    required this.chunkCount,
    required this.updatedAt,
  });
}

class RetrievedKnowledgeChunk {
  final String chunkId;
  final String baseId;
  final String documentId;
  final String sourceLabel;
  final String text;
  final double lexicalScore;
  final double semanticScore;
  final double finalScore;

  const RetrievedKnowledgeChunk({
    required this.chunkId,
    required this.baseId,
    required this.documentId,
    required this.sourceLabel,
    required this.text,
    required this.lexicalScore,
    required this.semanticScore,
    required this.finalScore,
  });
}

class KnowledgeRetrievalResult {
  final List<RetrievedKnowledgeChunk> chunks;
  final bool usedEmbedding;

  const KnowledgeRetrievalResult({
    this.chunks = const [],
    this.usedEmbedding = false,
  });

  bool get hasContext => chunks.isNotEmpty;

  String toPromptContext() {
    if (chunks.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## Local Knowledge Base Context');
    buffer.writeln(
        'Use the context snippets below when relevant. If you cite a snippet, use [KBn] markers.');
    buffer.writeln();

    for (int i = 0; i < chunks.length; i++) {
      final index = i + 1;
      final chunk = chunks[i];
      buffer.writeln('[KB$index] ${chunk.sourceLabel}');
      buffer.writeln(chunk.text);
      buffer.writeln();
    }

    buffer.writeln(
        'If the context is insufficient, explicitly state uncertainty instead of guessing.');
    return buffer.toString().trim();
  }
}
