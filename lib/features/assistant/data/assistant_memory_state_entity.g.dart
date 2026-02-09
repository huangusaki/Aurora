// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_memory_state_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAssistantMemoryStateEntityCollection on Isar {
  IsarCollection<AssistantMemoryStateEntity> get assistantMemoryStateEntitys =>
      this.collection();
}

const AssistantMemoryStateEntitySchema = CollectionSchema(
  name: r'AssistantMemoryStateEntity',
  id: 6590434823646838567,
  properties: {
    r'assistantId': PropertySchema(
      id: 0,
      name: r'assistantId',
      type: IsarType.string,
    ),
    r'consolidatedUntilMessageId': PropertySchema(
      id: 1,
      name: r'consolidatedUntilMessageId',
      type: IsarType.long,
    ),
    r'lastObservedMessageAt': PropertySchema(
      id: 2,
      name: r'lastObservedMessageAt',
      type: IsarType.dateTime,
    ),
    r'lastSuccessfulRunAt': PropertySchema(
      id: 3,
      name: r'lastSuccessfulRunAt',
      type: IsarType.dateTime,
    ),
    r'runsDayKey': PropertySchema(
      id: 4,
      name: r'runsDayKey',
      type: IsarType.string,
    ),
    r'runsToday': PropertySchema(
      id: 5,
      name: r'runsToday',
      type: IsarType.long,
    )
  },
  estimateSize: _assistantMemoryStateEntityEstimateSize,
  serialize: _assistantMemoryStateEntitySerialize,
  deserialize: _assistantMemoryStateEntityDeserialize,
  deserializeProp: _assistantMemoryStateEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'assistantId': IndexSchema(
      id: 6881749177497878227,
      name: r'assistantId',
      unique: true,
      replace: true,
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
  getId: _assistantMemoryStateEntityGetId,
  getLinks: _assistantMemoryStateEntityGetLinks,
  attach: _assistantMemoryStateEntityAttach,
  version: '3.1.0+1',
);

int _assistantMemoryStateEntityEstimateSize(
  AssistantMemoryStateEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assistantId.length * 3;
  {
    final value = object.runsDayKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _assistantMemoryStateEntitySerialize(
  AssistantMemoryStateEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assistantId);
  writer.writeLong(offsets[1], object.consolidatedUntilMessageId);
  writer.writeDateTime(offsets[2], object.lastObservedMessageAt);
  writer.writeDateTime(offsets[3], object.lastSuccessfulRunAt);
  writer.writeString(offsets[4], object.runsDayKey);
  writer.writeLong(offsets[5], object.runsToday);
}

AssistantMemoryStateEntity _assistantMemoryStateEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AssistantMemoryStateEntity();
  object.assistantId = reader.readString(offsets[0]);
  object.consolidatedUntilMessageId = reader.readLong(offsets[1]);
  object.id = id;
  object.lastObservedMessageAt = reader.readDateTimeOrNull(offsets[2]);
  object.lastSuccessfulRunAt = reader.readDateTimeOrNull(offsets[3]);
  object.runsDayKey = reader.readStringOrNull(offsets[4]);
  object.runsToday = reader.readLong(offsets[5]);
  return object;
}

P _assistantMemoryStateEntityDeserializeProp<P>(
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
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _assistantMemoryStateEntityGetId(AssistantMemoryStateEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _assistantMemoryStateEntityGetLinks(
    AssistantMemoryStateEntity object) {
  return [];
}

void _assistantMemoryStateEntityAttach(
    IsarCollection<dynamic> col, Id id, AssistantMemoryStateEntity object) {
  object.id = id;
}

extension AssistantMemoryStateEntityByIndex
    on IsarCollection<AssistantMemoryStateEntity> {
  Future<AssistantMemoryStateEntity?> getByAssistantId(String assistantId) {
    return getByIndex(r'assistantId', [assistantId]);
  }

  AssistantMemoryStateEntity? getByAssistantIdSync(String assistantId) {
    return getByIndexSync(r'assistantId', [assistantId]);
  }

  Future<bool> deleteByAssistantId(String assistantId) {
    return deleteByIndex(r'assistantId', [assistantId]);
  }

  bool deleteByAssistantIdSync(String assistantId) {
    return deleteByIndexSync(r'assistantId', [assistantId]);
  }

  Future<List<AssistantMemoryStateEntity?>> getAllByAssistantId(
      List<String> assistantIdValues) {
    final values = assistantIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'assistantId', values);
  }

  List<AssistantMemoryStateEntity?> getAllByAssistantIdSync(
      List<String> assistantIdValues) {
    final values = assistantIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'assistantId', values);
  }

  Future<int> deleteAllByAssistantId(List<String> assistantIdValues) {
    final values = assistantIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'assistantId', values);
  }

  int deleteAllByAssistantIdSync(List<String> assistantIdValues) {
    final values = assistantIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'assistantId', values);
  }

  Future<Id> putByAssistantId(AssistantMemoryStateEntity object) {
    return putByIndex(r'assistantId', object);
  }

  Id putByAssistantIdSync(AssistantMemoryStateEntity object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'assistantId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByAssistantId(
      List<AssistantMemoryStateEntity> objects) {
    return putAllByIndex(r'assistantId', objects);
  }

  List<Id> putAllByAssistantIdSync(List<AssistantMemoryStateEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'assistantId', objects, saveLinks: saveLinks);
  }
}

extension AssistantMemoryStateEntityQueryWhereSort on QueryBuilder<
    AssistantMemoryStateEntity, AssistantMemoryStateEntity, QWhere> {
  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AssistantMemoryStateEntityQueryWhere on QueryBuilder<
    AssistantMemoryStateEntity, AssistantMemoryStateEntity, QWhereClause> {
  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterWhereClause> assistantIdEqualTo(String assistantId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'assistantId',
        value: [assistantId],
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

extension AssistantMemoryStateEntityQueryFilter on QueryBuilder<
    AssistantMemoryStateEntity, AssistantMemoryStateEntity, QFilterCondition> {
  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> assistantIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assistantId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> assistantIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assistantId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> consolidatedUntilMessageIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consolidatedUntilMessageId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> consolidatedUntilMessageIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'consolidatedUntilMessageId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> consolidatedUntilMessageIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'consolidatedUntilMessageId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> consolidatedUntilMessageIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'consolidatedUntilMessageId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
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

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastObservedMessageAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastObservedMessageAt',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastObservedMessageAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastObservedMessageAt',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastObservedMessageAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastObservedMessageAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastObservedMessageAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastObservedMessageAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastObservedMessageAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastObservedMessageAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastObservedMessageAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastObservedMessageAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastSuccessfulRunAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSuccessfulRunAt',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastSuccessfulRunAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSuccessfulRunAt',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastSuccessfulRunAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSuccessfulRunAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastSuccessfulRunAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSuccessfulRunAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastSuccessfulRunAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSuccessfulRunAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> lastSuccessfulRunAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSuccessfulRunAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'runsDayKey',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'runsDayKey',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'runsDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'runsDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'runsDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'runsDayKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'runsDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'runsDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
          QAfterFilterCondition>
      runsDayKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'runsDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
          QAfterFilterCondition>
      runsDayKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'runsDayKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'runsDayKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsDayKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'runsDayKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsTodayEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'runsToday',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsTodayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'runsToday',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsTodayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'runsToday',
        value: value,
      ));
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterFilterCondition> runsTodayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'runsToday',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AssistantMemoryStateEntityQueryObject on QueryBuilder<
    AssistantMemoryStateEntity, AssistantMemoryStateEntity, QFilterCondition> {}

extension AssistantMemoryStateEntityQueryLinks on QueryBuilder<
    AssistantMemoryStateEntity, AssistantMemoryStateEntity, QFilterCondition> {}

extension AssistantMemoryStateEntityQuerySortBy on QueryBuilder<
    AssistantMemoryStateEntity, AssistantMemoryStateEntity, QSortBy> {
  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByAssistantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByAssistantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByConsolidatedUntilMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consolidatedUntilMessageId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByConsolidatedUntilMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consolidatedUntilMessageId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByLastObservedMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastObservedMessageAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByLastObservedMessageAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastObservedMessageAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByLastSuccessfulRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulRunAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByLastSuccessfulRunAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulRunAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByRunsDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runsDayKey', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByRunsDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runsDayKey', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByRunsToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runsToday', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> sortByRunsTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runsToday', Sort.desc);
    });
  }
}

extension AssistantMemoryStateEntityQuerySortThenBy on QueryBuilder<
    AssistantMemoryStateEntity, AssistantMemoryStateEntity, QSortThenBy> {
  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByAssistantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByAssistantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByConsolidatedUntilMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consolidatedUntilMessageId', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByConsolidatedUntilMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consolidatedUntilMessageId', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByLastObservedMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastObservedMessageAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByLastObservedMessageAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastObservedMessageAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByLastSuccessfulRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulRunAt', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByLastSuccessfulRunAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulRunAt', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByRunsDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runsDayKey', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByRunsDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runsDayKey', Sort.desc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByRunsToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runsToday', Sort.asc);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QAfterSortBy> thenByRunsTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runsToday', Sort.desc);
    });
  }
}

extension AssistantMemoryStateEntityQueryWhereDistinct on QueryBuilder<
    AssistantMemoryStateEntity, AssistantMemoryStateEntity, QDistinct> {
  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QDistinct> distinctByAssistantId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assistantId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QDistinct> distinctByConsolidatedUntilMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'consolidatedUntilMessageId');
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QDistinct> distinctByLastObservedMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastObservedMessageAt');
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QDistinct> distinctByLastSuccessfulRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSuccessfulRunAt');
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QDistinct> distinctByRunsDayKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'runsDayKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, AssistantMemoryStateEntity,
      QDistinct> distinctByRunsToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'runsToday');
    });
  }
}

extension AssistantMemoryStateEntityQueryProperty on QueryBuilder<
    AssistantMemoryStateEntity, AssistantMemoryStateEntity, QQueryProperty> {
  QueryBuilder<AssistantMemoryStateEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, String, QQueryOperations>
      assistantIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assistantId');
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, int, QQueryOperations>
      consolidatedUntilMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'consolidatedUntilMessageId');
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, DateTime?, QQueryOperations>
      lastObservedMessageAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastObservedMessageAt');
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, DateTime?, QQueryOperations>
      lastSuccessfulRunAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSuccessfulRunAt');
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, String?, QQueryOperations>
      runsDayKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'runsDayKey');
    });
  }

  QueryBuilder<AssistantMemoryStateEntity, int, QQueryOperations>
      runsTodayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'runsToday');
    });
  }
}
