// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_memory_job_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAssistantMemoryJobEntityCollection on Isar {
  IsarCollection<AssistantMemoryJobEntity> get assistantMemoryJobEntitys =>
      this.collection();
}

const AssistantMemoryJobEntitySchema = CollectionSchema(
  name: r'AssistantMemoryJobEntity',
  id: 110886049434871283,
  properties: {
    r'assistantId': PropertySchema(
      id: 0,
      name: r'assistantId',
      type: IsarType.string,
    ),
    r'attemptCount': PropertySchema(
      id: 1,
      name: r'attemptCount',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'endMessageId': PropertySchema(
      id: 3,
      name: r'endMessageId',
      type: IsarType.long,
    ),
    r'jobId': PropertySchema(
      id: 4,
      name: r'jobId',
      type: IsarType.string,
    ),
    r'lastError': PropertySchema(
      id: 5,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'lockedUntil': PropertySchema(
      id: 6,
      name: r'lockedUntil',
      type: IsarType.dateTime,
    ),
    r'nextRetryAt': PropertySchema(
      id: 7,
      name: r'nextRetryAt',
      type: IsarType.dateTime,
    ),
    r'startMessageId': PropertySchema(
      id: 8,
      name: r'startMessageId',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 9,
      name: r'status',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 10,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _assistantMemoryJobEntityEstimateSize,
  serialize: _assistantMemoryJobEntitySerialize,
  deserialize: _assistantMemoryJobEntityDeserialize,
  deserializeProp: _assistantMemoryJobEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'jobId': IndexSchema(
      id: 7916160552736803877,
      name: r'jobId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'jobId',
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _assistantMemoryJobEntityGetId,
  getLinks: _assistantMemoryJobEntityGetLinks,
  attach: _assistantMemoryJobEntityAttach,
  version: '3.1.0+1',
);

int _assistantMemoryJobEntityEstimateSize(
  AssistantMemoryJobEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assistantId.length * 3;
  bytesCount += 3 + object.jobId.length * 3;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _assistantMemoryJobEntitySerialize(
  AssistantMemoryJobEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assistantId);
  writer.writeLong(offsets[1], object.attemptCount);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.endMessageId);
  writer.writeString(offsets[4], object.jobId);
  writer.writeString(offsets[5], object.lastError);
  writer.writeDateTime(offsets[6], object.lockedUntil);
  writer.writeDateTime(offsets[7], object.nextRetryAt);
  writer.writeLong(offsets[8], object.startMessageId);
  writer.writeString(offsets[9], object.status);
  writer.writeDateTime(offsets[10], object.updatedAt);
}

AssistantMemoryJobEntity _assistantMemoryJobEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AssistantMemoryJobEntity();
  object.assistantId = reader.readString(offsets[0]);
  object.attemptCount = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.endMessageId = reader.readLong(offsets[3]);
  object.id = id;
  object.jobId = reader.readString(offsets[4]);
  object.lastError = reader.readStringOrNull(offsets[5]);
  object.lockedUntil = reader.readDateTimeOrNull(offsets[6]);
  object.nextRetryAt = reader.readDateTimeOrNull(offsets[7]);
  object.startMessageId = reader.readLong(offsets[8]);
  object.status = reader.readString(offsets[9]);
  object.updatedAt = reader.readDateTime(offsets[10]);
  return object;
}

P _assistantMemoryJobEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _assistantMemoryJobEntityGetId(AssistantMemoryJobEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _assistantMemoryJobEntityGetLinks(
    AssistantMemoryJobEntity object) {
  return [];
}

void _assistantMemoryJobEntityAttach(
    IsarCollection<dynamic> col, Id id, AssistantMemoryJobEntity object) {
  object.id = id;
}

extension AssistantMemoryJobEntityByIndex
    on IsarCollection<AssistantMemoryJobEntity> {
  Future<AssistantMemoryJobEntity?> getByJobId(String jobId) {
    return getByIndex(r'jobId', [jobId]);
  }

  AssistantMemoryJobEntity? getByJobIdSync(String jobId) {
    return getByIndexSync(r'jobId', [jobId]);
  }

  Future<bool> deleteByJobId(String jobId) {
    return deleteByIndex(r'jobId', [jobId]);
  }

  bool deleteByJobIdSync(String jobId) {
    return deleteByIndexSync(r'jobId', [jobId]);
  }

  Future<List<AssistantMemoryJobEntity?>> getAllByJobId(
      List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'jobId', values);
  }

  List<AssistantMemoryJobEntity?> getAllByJobIdSync(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'jobId', values);
  }

  Future<int> deleteAllByJobId(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'jobId', values);
  }

  int deleteAllByJobIdSync(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'jobId', values);
  }

  Future<Id> putByJobId(AssistantMemoryJobEntity object) {
    return putByIndex(r'jobId', object);
  }

  Id putByJobIdSync(AssistantMemoryJobEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'jobId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByJobId(List<AssistantMemoryJobEntity> objects) {
    return putAllByIndex(r'jobId', objects);
  }

  List<Id> putAllByJobIdSync(List<AssistantMemoryJobEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'jobId', objects, saveLinks: saveLinks);
  }
}

extension AssistantMemoryJobEntityQueryWhereSort on QueryBuilder<
    AssistantMemoryJobEntity, AssistantMemoryJobEntity, QWhere> {
  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AssistantMemoryJobEntityQueryWhere on QueryBuilder<
    AssistantMemoryJobEntity, AssistantMemoryJobEntity, QWhereClause> {
  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterWhereClause> jobIdEqualTo(String jobId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'jobId',
        value: [jobId],
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterWhereClause> jobIdNotEqualTo(String jobId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [],
              upper: [jobId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [jobId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [jobId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [],
              upper: [jobId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterWhereClause> assistantIdEqualTo(String assistantId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'assistantId',
        value: [assistantId],
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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
}

extension AssistantMemoryJobEntityQueryFilter on QueryBuilder<
    AssistantMemoryJobEntity, AssistantMemoryJobEntity, QFilterCondition> {
  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> assistantIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assistantId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> assistantIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assistantId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> attemptCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attemptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> attemptCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attemptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> attemptCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attemptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> attemptCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attemptCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> endMessageIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endMessageId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> endMessageIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endMessageId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> endMessageIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endMessageId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> endMessageIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endMessageId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> jobIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> jobIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> jobIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> jobIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jobId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> jobIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> jobIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
          QAfterFilterCondition>
      jobIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
          QAfterFilterCondition>
      jobIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jobId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> jobIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> jobIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jobId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
          QAfterFilterCondition>
      lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
          QAfterFilterCondition>
      lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lockedUntilIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lockedUntil',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lockedUntilIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lockedUntil',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lockedUntilEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lockedUntil',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lockedUntilGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lockedUntil',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lockedUntilLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lockedUntil',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> lockedUntilBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lockedUntil',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> nextRetryAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nextRetryAt',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> nextRetryAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nextRetryAt',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> nextRetryAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> nextRetryAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> nextRetryAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> nextRetryAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextRetryAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> startMessageIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startMessageId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> startMessageIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startMessageId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> startMessageIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startMessageId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> startMessageIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startMessageId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
          QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
          QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity,
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
}

extension AssistantMemoryJobEntityQueryObject on QueryBuilder<
    AssistantMemoryJobEntity, AssistantMemoryJobEntity, QFilterCondition> {}

extension AssistantMemoryJobEntityQueryLinks on QueryBuilder<
    AssistantMemoryJobEntity, AssistantMemoryJobEntity, QFilterCondition> {}

extension AssistantMemoryJobEntityQuerySortBy on QueryBuilder<
    AssistantMemoryJobEntity, AssistantMemoryJobEntity, QSortBy> {
  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByAssistantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByAssistantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByAttemptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByEndMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMessageId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByEndMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMessageId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByLockedUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedUntil', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByLockedUntilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedUntil', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByNextRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByNextRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByStartMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMessageId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByStartMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMessageId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AssistantMemoryJobEntityQuerySortThenBy on QueryBuilder<
    AssistantMemoryJobEntity, AssistantMemoryJobEntity, QSortThenBy> {
  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByAssistantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByAssistantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByAttemptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByEndMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMessageId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByEndMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMessageId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByLockedUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedUntil', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByLockedUntilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedUntil', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByNextRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByNextRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByStartMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMessageId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByStartMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMessageId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AssistantMemoryJobEntityQueryWhereDistinct on QueryBuilder<
    AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct> {
  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByAssistantId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assistantId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attemptCount');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByEndMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endMessageId');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByJobId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByLastError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByLockedUntil() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lockedUntil');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByNextRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextRetryAt');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByStartMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startMessageId');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, AssistantMemoryJobEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension AssistantMemoryJobEntityQueryProperty on QueryBuilder<
    AssistantMemoryJobEntity, AssistantMemoryJobEntity, QQueryProperty> {
  QueryBuilder<AssistantMemoryJobEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, String, QQueryOperations>
      assistantIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assistantId');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, int, QQueryOperations>
      attemptCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attemptCount');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, int, QQueryOperations>
      endMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endMessageId');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, String, QQueryOperations>
      jobIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobId');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, String?, QQueryOperations>
      lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, DateTime?, QQueryOperations>
      lockedUntilProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lockedUntil');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, DateTime?, QQueryOperations>
      nextRetryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextRetryAt');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, int, QQueryOperations>
      startMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startMessageId');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, String, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<AssistantMemoryJobEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
