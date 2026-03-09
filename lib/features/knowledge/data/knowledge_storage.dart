import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:aurora/shared/services/provider_capability_gateway.dart';

import '../../settings/data/settings_storage.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/knowledge_models.dart';
import 'knowledge_entities.dart';

class KnowledgeIngestReport {
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const KnowledgeIngestReport({
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });
}

class KnowledgeStorage {
  KnowledgeStorage(SettingsStorage settingsStorage)
      : _isar = settingsStorage.isar;

  final Isar _isar;
  final ProviderCapabilityGateway _gateway = ProviderCapabilityGateway();

  Future<List<KnowledgeBaseSummary>> loadBaseSummaries({
    String? scope,
    String? ownerProjectId,
  }) async {
    final allBases = await _isar.knowledgeBaseEntitys.where().findAll();
    await _normalizeLegacyBaseScopes(allBases);
    final bases = allBases.where((base) {
      final baseScope = _effectiveScope(base);
      if (scope != null && baseScope != scope) {
        return false;
      }
      if (ownerProjectId != null && base.ownerProjectId != ownerProjectId) {
        return false;
      }
      return true;
    }).toList(growable: false);

    final docs = await _isar.knowledgeDocumentEntitys.where().findAll();
    final chunks = await _isar.knowledgeChunkEntitys.where().findAll();

    final docCountByBase = <String, int>{};
    for (final doc in docs) {
      docCountByBase[doc.baseId] = (docCountByBase[doc.baseId] ?? 0) + 1;
    }

    final chunkCountByBase = <String, int>{};
    for (final chunk in chunks) {
      chunkCountByBase[chunk.baseId] =
          (chunkCountByBase[chunk.baseId] ?? 0) + 1;
    }

    final summaries = bases
        .map(
          (base) => KnowledgeBaseSummary(
            baseId: base.baseId,
            name: base.name,
            description: base.description,
            isEnabled: base.isEnabled,
            documentCount: docCountByBase[base.baseId] ?? 0,
            chunkCount: chunkCountByBase[base.baseId] ?? 0,
            updatedAt: base.updatedAt,
          ),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return summaries;
  }

  Future<String> createBase({
    required String name,
    String description = '',
    String scope = KnowledgeBaseScope.chat,
    String? ownerProjectId,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final entity = KnowledgeBaseEntity()
      ..baseId = id
      ..scope = scope
      ..ownerProjectId = ownerProjectId
      ..name = name.trim()
      ..description = description.trim()
      ..isEnabled = true
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.knowledgeBaseEntitys.put(entity);
    });

    return id;
  }

  Future<void> updateBase({
    required String baseId,
    String? name,
    String? description,
    bool? isEnabled,
  }) async {
    await _isar.writeTxn(() async {
      final base = await _isar.knowledgeBaseEntitys
          .filter()
          .baseIdEqualTo(baseId)
          .findFirst();
      if (base == null) return;

      if (name != null) {
        base.name = name.trim();
      }
      if (description != null) {
        base.description = description.trim();
      }
      if (isEnabled != null) {
        base.isEnabled = isEnabled;
      }
      base.updatedAt = DateTime.now();
      await _isar.knowledgeBaseEntitys.put(base);
    });
  }

  Future<String> ensureProjectBase({
    required String projectId,
    required String projectName,
    String? existingBaseId,
  }) async {
    final expectedName = '${projectName.trim()} - Knowledge';

    if (existingBaseId != null && existingBaseId.trim().isNotEmpty) {
      final byId = await _isar.knowledgeBaseEntitys
          .filter()
          .baseIdEqualTo(existingBaseId.trim())
          .findFirst();
      if (byId != null &&
          byId.scope == KnowledgeBaseScope.studioProject &&
          byId.ownerProjectId == projectId) {
        if (byId.name != expectedName) {
          byId.name = expectedName;
          byId.updatedAt = DateTime.now();
          await _isar.writeTxn(() async {
            await _isar.knowledgeBaseEntitys.put(byId);
          });
        }
        return byId.baseId;
      }
    }

    final existingByProject = await _isar.knowledgeBaseEntitys
        .filter()
        .scopeEqualTo(KnowledgeBaseScope.studioProject)
        .ownerProjectIdEqualTo(projectId)
        .findFirst();
    if (existingByProject != null) {
      if (existingByProject.name != expectedName) {
        existingByProject.name = expectedName;
        existingByProject.updatedAt = DateTime.now();
        await _isar.writeTxn(() async {
          await _isar.knowledgeBaseEntitys.put(existingByProject);
        });
      }
      return existingByProject.baseId;
    }

    return createBase(
      name: expectedName,
      description: 'Project dedicated knowledge base.',
      scope: KnowledgeBaseScope.studioProject,
      ownerProjectId: projectId,
    );
  }

  Future<void> deleteProjectBase(String projectId) async {
    final existing = await _isar.knowledgeBaseEntitys
        .filter()
        .scopeEqualTo(KnowledgeBaseScope.studioProject)
        .ownerProjectIdEqualTo(projectId)
        .findFirst();
    if (existing == null) return;
    await deleteBase(existing.baseId);
  }

  Future<KnowledgeBaseSummary?> loadBaseSummaryById(String baseId) async {
    final all = await loadBaseSummaries();
    final matched = all
        .where((summary) => summary.baseId == baseId)
        .toList(growable: false);
    if (matched.isEmpty) return null;
    return matched.first;
  }

  Future<KnowledgeBaseSummary?> loadProjectBaseSummary(String projectId) async {
    final all = await loadBaseSummaries(
      scope: KnowledgeBaseScope.studioProject,
      ownerProjectId: projectId,
    );
    if (all.isEmpty) return null;
    return all.first;
  }

  Future<void> deleteBase(String baseId) async {
    await _isar.writeTxn(() async {
      final docs = await _isar.knowledgeDocumentEntitys
          .filter()
          .baseIdEqualTo(baseId)
          .findAll();

      for (final doc in docs) {
        await _isar.knowledgeChunkEntitys
            .filter()
            .documentIdEqualTo(doc.documentId)
            .deleteAll();
      }

      await _isar.knowledgeDocumentEntitys
          .filter()
          .baseIdEqualTo(baseId)
          .deleteAll();

      await _isar.knowledgeBaseEntitys
          .filter()
          .baseIdEqualTo(baseId)
          .deleteAll();
    });
  }

  Future<KnowledgeIngestReport> ingestFiles({
    required String baseId,
    required List<String> filePaths,
    bool useEmbedding = false,
    String? embeddingModel,
    ProviderConfig? embeddingProvider,
  }) async {
    var success = 0;
    var failed = 0;
    final errors = <String>[];

    final cleanedPaths = filePaths
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    for (final filePath in cleanedPaths) {
      final now = DateTime.now();
      final docId = const Uuid().v4();
      final fileName = p.basename(filePath);

      await _replaceSameSource(baseId: baseId, sourcePath: filePath);

      final doc = KnowledgeDocumentEntity()
        ..documentId = docId
        ..baseId = baseId
        ..fileName = fileName
        ..sourcePath = filePath
        ..status = 'indexing'
        ..createdAt = now
        ..updatedAt = now;

      await _isar.writeTxn(() async {
        await _isar.knowledgeDocumentEntitys.put(doc);
      });

      try {
        final extracted = await _extractTextFromFile(filePath);
        if (extracted == null || extracted.trim().isEmpty) {
          throw Exception('No extractable text content.');
        }

        final chunkTexts = _splitIntoChunks(extracted);
        if (chunkTexts.isEmpty) {
          throw Exception('No valid chunks were produced.');
        }

        List<List<double>>? vectors;
        final canEmbed = useEmbedding &&
            (embeddingModel != null && embeddingModel.trim().isNotEmpty) &&
            embeddingProvider != null;

        if (canEmbed) {
          try {
            vectors = await _embedTexts(
              chunkTexts,
              model: embeddingModel.trim(),
              provider: embeddingProvider,
            );
          } catch (e) {
            errors.add(
                '$fileName: embedding failed, fallback to lexical only ($e)');
          }
        }

        final createdAt = DateTime.now();
        final chunks = <KnowledgeChunkEntity>[];
        for (int i = 0; i < chunkTexts.length; i++) {
          final text = chunkTexts[i];
          final tokens = _tokenizeForSearch(text);
          final tokenString = tokens.join(' ');

          final chunk = KnowledgeChunkEntity()
            ..chunkId = const Uuid().v4()
            ..baseId = baseId
            ..documentId = docId
            ..chunkIndex = i
            ..text = text
            ..tokens = tokenString
            ..tokenCount = tokens.length
            ..sourceLabel = '$fileName#${i + 1}'
            ..embeddingJson = (vectors != null && i < vectors.length)
                ? jsonEncode(vectors[i])
                : null
            ..createdAt = createdAt;
          chunks.add(chunk);
        }

        await _isar.writeTxn(() async {
          await _isar.knowledgeChunkEntitys.putAll(chunks);
          final stored = await _isar.knowledgeDocumentEntitys
              .filter()
              .documentIdEqualTo(docId)
              .findFirst();
          if (stored != null) {
            stored.status = 'ready';
            stored.error = null;
            stored.chunkCount = chunks.length;
            stored.updatedAt = DateTime.now();
            await _isar.knowledgeDocumentEntitys.put(stored);
          }

          final base = await _isar.knowledgeBaseEntitys
              .filter()
              .baseIdEqualTo(baseId)
              .findFirst();
          if (base != null) {
            base.updatedAt = DateTime.now();
            await _isar.knowledgeBaseEntitys.put(base);
          }
        });

        success++;
      } catch (e) {
        failed++;
        errors.add('$fileName: $e');

        await _isar.writeTxn(() async {
          final stored = await _isar.knowledgeDocumentEntitys
              .filter()
              .documentIdEqualTo(docId)
              .findFirst();
          if (stored != null) {
            stored.status = 'failed';
            stored.error = e.toString();
            stored.updatedAt = DateTime.now();
            await _isar.knowledgeDocumentEntitys.put(stored);
          }
        });
      }
    }

    return KnowledgeIngestReport(
      successCount: success,
      failureCount: failed,
      errors: errors,
    );
  }

  Future<KnowledgeRetrievalResult> retrieveContext({
    required String query,
    required List<String> baseIds,
    int topK = 5,
    bool useEmbedding = false,
    String? embeddingModel,
    ProviderConfig? embeddingProvider,
    String? requiredScope,
    String? requiredProjectId,
  }) async {
    final trimmedQuery = query.trim();
    final pickedBaseIds = baseIds.toSet().toList();
    if (trimmedQuery.isEmpty || pickedBaseIds.isEmpty) {
      return const KnowledgeRetrievalResult();
    }

    final allBases = await _isar.knowledgeBaseEntitys.where().findAll();
    await _normalizeLegacyBaseScopes(allBases);
    final allowedBaseIds = allBases
        .where((base) {
          final baseScope = _effectiveScope(base);
          if (!pickedBaseIds.contains(base.baseId)) {
            return false;
          }
          if (requiredScope != null && baseScope != requiredScope) {
            return false;
          }
          if (requiredProjectId != null &&
              base.ownerProjectId != requiredProjectId) {
            return false;
          }
          return true;
        })
        .map((base) => base.baseId)
        .toSet();
    if (allowedBaseIds.isEmpty) {
      return const KnowledgeRetrievalResult();
    }

    final allChunks = await _isar.knowledgeChunkEntitys.where().findAll();
    final chunks =
        allChunks.where((c) => allowedBaseIds.contains(c.baseId)).toList();
    if (chunks.isEmpty) {
      return const KnowledgeRetrievalResult();
    }

    final queryTerms = _tokenizeForSearch(trimmedQuery);
    if (queryTerms.isEmpty) {
      return const KnowledgeRetrievalResult();
    }

    final docsTokens = <List<String>>[];
    final termFreqByDoc = <Map<String, int>>[];
    final docLengths = <int>[];

    for (final chunk in chunks) {
      final tokens = chunk.tokens
          .split(' ')
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      docsTokens.add(tokens);

      final tf = <String, int>{};
      for (final token in tokens) {
        tf[token] = (tf[token] ?? 0) + 1;
      }
      termFreqByDoc.add(tf);
      docLengths.add(tokens.length);
    }

    final uniqueQueryTerms = queryTerms.toSet().toList(growable: false);
    final df = <String, int>{for (final term in uniqueQueryTerms) term: 0};

    for (final tf in termFreqByDoc) {
      for (final term in uniqueQueryTerms) {
        if (tf.containsKey(term)) {
          df[term] = (df[term] ?? 0) + 1;
        }
      }
    }

    final n = chunks.length;
    final avgDl = docLengths.isEmpty
        ? 1.0
        : docLengths.reduce((a, b) => a + b) / docLengths.length;
    const k1 = 1.5;
    const b = 0.75;

    final lexicalScores = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final tf = termFreqByDoc[i];
      final dl = max(docLengths[i], 1);
      var score = 0.0;

      for (final term in uniqueQueryTerms) {
        final termTf = tf[term] ?? 0;
        if (termTf <= 0) continue;

        final termDf = df[term] ?? 0;
        final idf = log(((n - termDf + 0.5) / (termDf + 0.5)) + 1.0);
        final numerator = termTf * (k1 + 1.0);
        final denominator =
            termTf + k1 * (1.0 - b + b * (dl / max(avgDl, 1.0)));
        score += idf * (numerator / denominator);
      }

      lexicalScores[i] = score;
    }

    final lexicalMin = lexicalScores.reduce(min);
    final lexicalMax = lexicalScores.reduce(max);
    double normalizeLexical(double v) {
      if ((lexicalMax - lexicalMin).abs() < 1e-9) {
        return v > 0 ? 1.0 : 0.0;
      }
      return (v - lexicalMin) / (lexicalMax - lexicalMin);
    }

    var usedEmbedding = false;
    final semanticScores = List<double>.filled(n, 0);

    final canEmbed = useEmbedding &&
        (embeddingModel != null && embeddingModel.trim().isNotEmpty) &&
        embeddingProvider != null;

    if (canEmbed) {
      try {
        final queryVector = (await _embedTexts(
          [trimmedQuery],
          model: embeddingModel.trim(),
          provider: embeddingProvider,
        ))
            .first;

        for (int i = 0; i < n; i++) {
          final embJson = chunks[i].embeddingJson;
          if (embJson == null || embJson.isEmpty) {
            semanticScores[i] = 0;
            continue;
          }
          final parsed = jsonDecode(embJson);
          if (parsed is! List) {
            semanticScores[i] = 0;
            continue;
          }
          final chunkVector =
              parsed.map((e) => (e as num).toDouble()).toList(growable: false);
          semanticScores[i] = _cosineSimilarity(queryVector, chunkVector);
        }

        usedEmbedding = true;
      } catch (_) {
        usedEmbedding = false;
      }
    }

    double normalizeSemantic(double v) {
      // Cosine range is [-1, 1], project to [0, 1].
      return ((v + 1.0) / 2.0).clamp(0.0, 1.0);
    }

    final scored = <RetrievedKnowledgeChunk>[];
    for (int i = 0; i < n; i++) {
      final lexical = normalizeLexical(lexicalScores[i]);
      final semantic = normalizeSemantic(semanticScores[i]);
      final finalScore =
          usedEmbedding ? (0.65 * lexical + 0.35 * semantic) : lexical;

      if (finalScore <= 0) continue;

      final chunk = chunks[i];
      scored.add(
        RetrievedKnowledgeChunk(
          chunkId: chunk.chunkId,
          baseId: chunk.baseId,
          documentId: chunk.documentId,
          sourceLabel: chunk.sourceLabel,
          text: chunk.text,
          lexicalScore: lexical,
          semanticScore: semantic,
          finalScore: finalScore,
        ),
      );
    }

    scored.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    final limitedTopK = topK.clamp(1, 20);
    final top = scored.take(limitedTopK).toList(growable: false);

    return KnowledgeRetrievalResult(chunks: top, usedEmbedding: usedEmbedding);
  }

  Future<void> _replaceSameSource({
    required String baseId,
    required String sourcePath,
  }) async {
    await _isar.writeTxn(() async {
      final existingDocs = await _isar.knowledgeDocumentEntitys
          .filter()
          .baseIdEqualTo(baseId)
          .sourcePathEqualTo(sourcePath)
          .findAll();
      if (existingDocs.isEmpty) return;

      for (final doc in existingDocs) {
        await _isar.knowledgeChunkEntitys
            .filter()
            .documentIdEqualTo(doc.documentId)
            .deleteAll();
      }

      await _isar.knowledgeDocumentEntitys
          .filter()
          .baseIdEqualTo(baseId)
          .sourcePathEqualTo(sourcePath)
          .deleteAll();
    });
  }

  Future<String?> _extractTextFromFile(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    switch (ext) {
      case '.txt':
      case '.md':
      case '.csv':
      case '.json':
      case '.xml':
      case '.yaml':
      case '.yml':
        return file.readAsString();
      case '.docx':
        final bytes = await file.readAsBytes();
        return _extractDocxText(bytes);
      case '.pdf':
      case '.doc':
      case '.xlsx':
      case '.pptx':
        throw Exception('Unsupported file type for local indexing: $ext');
      default:
        throw Exception('Unsupported file extension: $ext');
    }
  }

  String _extractDocxText(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) return '';

    final content = utf8.decode(documentFile.content as List<int>);
    final paragraphRegExp = RegExp(r'<w:p[^>]*>(.*?)</w:p>');
    final textRegExp = RegExp(r'<w:t[^>]*>(.*?)</w:t>');

    final sb = StringBuffer();
    final matches = paragraphRegExp.allMatches(content);
    for (final paragraph in matches) {
      final inner = paragraph.group(1) ?? '';
      for (final t in textRegExp.allMatches(inner)) {
        sb.write(_xmlDecode(t.group(1) ?? ''));
      }
      sb.writeln();
    }

    return sb.toString().trim();
  }

  String _xmlDecode(String input) {
    return input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  List<String> _splitIntoChunks(
    String text, {
    int chunkSize = 700,
    int chunkOverlap = 100,
  }) {
    final words = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList(growable: false);

    if (words.isEmpty) return const [];
    if (words.length <= chunkSize) return [words.join(' ')];

    final chunks = <String>[];
    var start = 0;
    while (start < words.length) {
      final end = min(start + chunkSize, words.length);
      final chunkWords = words.sublist(start, end);
      chunks.add(chunkWords.join(' '));
      if (end >= words.length) break;

      final nextStart = end - chunkOverlap;
      start = nextStart > start ? nextStart : end;
    }

    return chunks;
  }

  List<String> _tokenizeForSearch(String text) {
    final lower = text.toLowerCase();
    final regex = RegExp(r'[a-z0-9]+|[\u4e00-\u9fff]');
    return regex
        .allMatches(lower)
        .map((m) => m.group(0)!)
        .where((token) => token.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<List<double>>> _embedTexts(
    List<String> inputs, {
    required String model,
    required ProviderConfig provider,
  }) async {
    if (inputs.isEmpty) return const [];
    return _gateway.embedTexts(
      provider: provider,
      model: model,
      inputs: inputs,
    );
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) {
      return 0.0;
    }

    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA <= 0 || normB <= 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  Future<void> _normalizeLegacyBaseScopes(
      List<KnowledgeBaseEntity> bases) async {
    final legacy = bases
        .where((base) => base.scope.trim().isEmpty)
        .toList(growable: false);
    if (legacy.isEmpty) return;

    await _isar.writeTxn(() async {
      final now = DateTime.now();
      for (final base in legacy) {
        base.scope = KnowledgeBaseScope.chat;
        base.updatedAt = now;
      }
      await _isar.knowledgeBaseEntitys.putAll(legacy);
    });
  }

  String _effectiveScope(KnowledgeBaseEntity base) {
    final scope = base.scope.trim();
    return scope.isEmpty ? KnowledgeBaseScope.chat : scope;
  }
}
