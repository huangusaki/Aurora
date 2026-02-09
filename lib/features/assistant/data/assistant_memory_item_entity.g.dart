// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_memory_item_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAssistantMemoryItemEntityCollection on Isar {
  IsarCollection<AssistantMemoryItemEntity> get assistantMemoryItemEntitys =>
      this.collection();
}

const AssistantMemoryItemEntitySchema = CollectionSchema(
  name: r'AssistantMemoryItemEntity',
  id: 2570904579221099293,
  properties: {
    r'assistantId': PropertySchema(
      id: 0,
      name: r'assistantId',
      type: IsarType.string,
    ),
    r'confidence': PropertySchema(
      id: 1,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'evidenceMessageIds': PropertySchema(
      id: 3,
      name: r'evidenceMessageIds',
      type: IsarType.longList,
    ),
    r'isActive': PropertySchema(
      id: 4,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'key': PropertySchema(
      id: 5,
      name: r'key',
      type: IsarType.string,
    ),
    r'lastSeenAt': PropertySchema(
      id: 6,
      name: r'lastSeenAt',
      type: IsarType.dateTime,
    ),
    r'memoryId': PropertySchema(
      id: 7,
      name: r'memoryId',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'valueJson': PropertySchema(
      id: 9,
      name: r'valueJson',
      type: IsarType.string,
    )
  },
  estimateSize: _assistantMemoryItemEntityEstimateSize,
  serialize: _assistantMemoryItemEntitySerialize,
  deserialize: _assistantMemoryItemEntityDeserialize,
  deserializeProp: _assistantMemoryItemEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'memoryId': IndexSchema(
      id: -5774343511955247558,
      name: r'memoryId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'memoryId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'assistantId': IndexSchema(
      id: 6881749177497878227,
      name: r'assistantId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'assistantId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _assistantMemoryItemEntityGetId,
  getLinks: _assistantMemoryItemEntityGetLinks,
  attach: _assistantMemoryItemEntityAttach,
  version: '3.1.0+1',
);

int _assistantMemoryItemEntityEstimateSize(
  AssistantMemoryItemEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assistantId.length * 3;
  bytesCount += 3 + object.evidenceMessageIds.length * 8;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.memoryId.length * 3;
  bytesCount += 3 + object.valueJson.length * 3;
  return bytesCount;
}

void _assistantMemoryItemEntitySerialize(
  AssistantMemoryItemEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assistantId);
  writer.writeDouble(offsets[1], object.confidence);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLongList(offsets[3], object.evidenceMessageIds);
  writer.writeBool(offsets[4], object.isActive);
  writer.writeString(offsets[5], object.key);
  writer.writeDateTime(offsets[6], object.lastSeenAt);
  writer.writeString(offsets[7], object.memoryId);
  writer.writeDateTime(offsets[8], object.updatedAt);
  writer.writeString(offsets[9], object.valueJson);
}

AssistantMemoryItemEntity _assistantMemoryItemEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AssistantMemoryItemEntity();
  object.assistantId = reader.readString(offsets[0]);
  object.confidence = reader.readDouble(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.evidenceMessageIds = reader.readLongList(offsets[3]) ?? [];
  object.id = id;
  object.isActive = reader.readBool(offsets[4]);
  object.key = reader.readString(offsets[5]);
  object.lastSeenAt = reader.readDateTimeOrNull(offsets[6]);
  object.memoryId = reader.readString(offsets[7]);
  object.updatedAt = reader.readDateTime(offsets[8]);
  object.valueJson = reader.readString(offsets[9]);
  return object;
}

P _assistantMemoryItemEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLongList(offset) ?? []) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _assistantMemoryItemEntityGetId(AssistantMemoryItemEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _assistantMemoryItemEntityGetLinks(
    AssistantMemoryItemEntity object) {
  return [];
}

void _assistantMemoryItemEntityAttach(
    IsarCollection<dynamic> col, Id id, AssistantMemoryItemEntity object) {
  object.id = id;
}

extension AssistantMemoryItemEntityByIndex
    on IsarCollection<AssistantMemoryItemEntity> {
  Future<AssistantMemoryItemEntity?> getByMemoryId(String memoryId) {
    return getByIndex(r'memoryId', [memoryId]);
  }

  AssistantMemoryItemEntity? getByMemoryIdSync(String memoryId) {
    return getByIndexSync(r'memoryId', [memoryId]);
  }

  Future<bool> deleteByMemoryId(String memoryId) {
    return deleteByIndex(r'memoryId', [memoryId]);
  }

  bool deleteByMemoryIdSync(String memoryId) {
    return deleteByIndexSync(r'memoryId', [memoryId]);
  }

  Future<List<AssistantMemoryItemEntity?>> getAllByMemoryId(
      List<String> memoryIdValues) {
    final values = memoryIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'memoryId', values);
  }

  List<AssistantMemoryItemEntity?> getAllByMemoryIdSync(
      List<String> memoryIdValues) {
    final values = memoryIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'memoryId', values);
  }

  Future<int> deleteAllByMemoryId(List<String> memoryIdValues) {
    final values = memoryIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'memoryId', values);
  }

  int deleteAllByMemoryIdSync(List<String> memoryIdValues) {
    final values = memoryIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'memoryId', values);
  }

  Future<Id> putByMemoryId(AssistantMemoryItemEntity object) {
    return putByIndex(r'memoryId', object);
  }

  Id putByMemoryIdSync(AssistantMemoryItemEntity object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'memoryId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMemoryId(List<AssistantMemoryItemEntity> objects) {
    return putAllByIndex(r'memoryId', objects);
  }

  List<Id> putAllByMemoryIdSync(List<AssistantMemoryItemEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'memoryId', objects, saveLinks: saveLinks);
  }
}

extension AssistantMemoryItemEntityQueryWhereSort on QueryBuilder<
    AssistantMemoryItemEntity, AssistantMemoryItemEntity, QWhere> {
  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AssistantMemoryItemEntityQueryWhere on QueryBuilder<
    AssistantMemoryItemEntity, AssistantMemoryItemEntity, QWhereClause> {
  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> memoryIdEqualTo(String memoryId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'memoryId',
        value: [memoryId],
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> memoryIdNotEqualTo(String memoryId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memoryId',
              lower: [],
              upper: [memoryId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memoryId',
              lower: [memoryId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memoryId',
              lower: [memoryId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memoryId',
              lower: [],
              upper: [memoryId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> assistantIdEqualTo(String assistantId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'assistantId',
        value: [assistantId],
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> assistantIdNotEqualTo(String assistantId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'assistantId',
              lower: [],
              upper: [assistantId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'assistantId',
              lower: [assistantId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'assistantId',
              lower: [assistantId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'assistantId',
              lower: [],
              upper: [assistantId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'key',
        value: [key],
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterWhereClause> keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ));
      }
    });
  }
}

extension AssistantMemoryItemEntityQueryFilter on QueryBuilder<
    AssistantMemoryItemEntity, AssistantMemoryItemEntity, QFilterCondition> {
  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> assistantIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assistantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> assistantIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assistantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> assistantIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assistantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> assistantIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assistantId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> assistantIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assistantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> assistantIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assistantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
          QAfterFilterCondition>
      assistantIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assistantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
          QAfterFilterCondition>
      assistantIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assistantId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> assistantIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assistantId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> assistantIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assistantId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> confidenceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> confidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> confidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> confidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'evidenceMessageIds',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'evidenceMessageIds',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'evidenceMessageIds',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'evidenceMessageIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'evidenceMessageIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'evidenceMessageIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'evidenceMessageIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'evidenceMessageIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'evidenceMessageIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> evidenceMessageIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'evidenceMessageIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'key',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
          QAfterFilterCondition>
      keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
          QAfterFilterCondition>
      keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> lastSeenAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSeenAt',
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> lastSeenAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSeenAt',
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> lastSeenAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSeenAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> lastSeenAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSeenAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> lastSeenAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSeenAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> lastSeenAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSeenAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> memoryIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> memoryIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'memoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> memoryIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'memoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> memoryIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'memoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> memoryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'memoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> memoryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'memoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
          QAfterFilterCondition>
      memoryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'memoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
          QAfterFilterCondition>
      memoryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'memoryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> memoryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> memoryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'memoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> valueJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> valueJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'valueJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> valueJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'valueJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> valueJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'valueJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> valueJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'valueJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> valueJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'valueJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
          QAfterFilterCondition>
      valueJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'valueJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
          QAfterFilterCondition>
      valueJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'valueJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> valueJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueJson',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterFilterCondition> valueJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'valueJson',
        value: '',
      ));
    });
  }
}

extension AssistantMemoryItemEntityQueryObject on QueryBuilder<
    AssistantMemoryItemEntity, AssistantMemoryItemEntity, QFilterCondition> {}

extension AssistantMemoryItemEntityQueryLinks on QueryBuilder<
    AssistantMemoryItemEntity, AssistantMemoryItemEntity, QFilterCondition> {}

extension AssistantMemoryItemEntityQuerySortBy on QueryBuilder<
    AssistantMemoryItemEntity, AssistantMemoryItemEntity, QSortBy> {
  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByAssistantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByAssistantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByLastSeenAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeenAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByLastSeenAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeenAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByMemoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByMemoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByValueJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueJson', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> sortByValueJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueJson', Sort.desc);
    });
  }
}

extension AssistantMemoryItemEntityQuerySortThenBy on QueryBuilder<
    AssistantMemoryItemEntity, AssistantMemoryItemEntity, QSortThenBy> {
  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByAssistantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByAssistantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByLastSeenAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeenAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByLastSeenAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeenAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByMemoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByMemoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByValueJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueJson', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity,
      QAfterSortBy> thenByValueJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueJson', Sort.desc);
    });
  }
}

extension AssistantMemoryItemEntityQueryWhereDistinct on QueryBuilder<
    AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct> {
  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByAssistantId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assistantId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidence');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByEvidenceMessageIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'evidenceMessageIds');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByLastSeenAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSeenAt');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByMemoryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memoryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, AssistantMemoryItemEntity, QDistinct>
      distinctByValueJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valueJson', caseSensitive: caseSensitive);
    });
  }
}

extension AssistantMemoryItemEntityQueryProperty on QueryBuilder<
    AssistantMemoryItemEntity, AssistantMemoryItemEntity, QQueryProperty> {
  QueryBuilder<AssistantMemoryItemEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, String, QQueryOperations>
      assistantIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assistantId');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, double, QQueryOperations>
      confidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidence');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, List<int>, QQueryOperations>
      evidenceMessageIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'evidenceMessageIds');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, bool, QQueryOperations>
      isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, String, QQueryOperations>
      keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, DateTime?, QQueryOperations>
      lastSeenAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSeenAt');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, String, QQueryOperations>
      memoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memoryId');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<AssistantMemoryItemEntity, String, QQueryOperations>
      valueJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valueJson');
    });
  }
}
