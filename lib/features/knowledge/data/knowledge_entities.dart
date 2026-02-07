import 'package:isar/isar.dart';

part 'knowledge_entities.g.dart';

@collection
class KnowledgeBaseEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String baseId;

  late String name;
  String description = '';
  bool isEnabled = true;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;
}

@collection
class KnowledgeDocumentEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String documentId;

  @Index()
  late String baseId;

  late String fileName;
  String? sourcePath;
  String status = 'indexing'; // indexing | ready | failed
  String? error;
  int chunkCount = 0;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;
}

@collection
class KnowledgeChunkEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String chunkId;

  @Index()
  late String baseId;

  @Index()
  late String documentId;

  late int chunkIndex;
  late String text;

  // Space-separated normalized tokens used for keyword retrieval.
  late String tokens;

  late int tokenCount;
  late String sourceLabel;
  String? embeddingJson;

  @Index()
  late DateTime createdAt;
}
