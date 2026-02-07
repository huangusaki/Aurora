// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_entities.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKnowledgeBaseEntityCollection on Isar {
  IsarCollection<KnowledgeBaseEntity> get knowledgeBaseEntitys =>
      this.collection();
}

const KnowledgeBaseEntitySchema = CollectionSchema(
  name: r'KnowledgeBaseEntity',
  id: -2194443618291703972,
  properties: {
    r'baseId': PropertySchema(
      id: 0,
      name: r'baseId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'isEnabled': PropertySchema(
      id: 3,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _knowledgeBaseEntityEstimateSize,
  serialize: _knowledgeBaseEntitySerialize,
  deserialize: _knowledgeBaseEntityDeserialize,
  deserializeProp: _knowledgeBaseEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'baseId': IndexSchema(
      id: 3304293301281094907,
      name: r'baseId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'baseId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _knowledgeBaseEntityGetId,
  getLinks: _knowledgeBaseEntityGetLinks,
  attach: _knowledgeBaseEntityAttach,
  version: '3.1.0+1',
);

int _knowledgeBaseEntityEstimateSize(
  KnowledgeBaseEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.baseId.length * 3;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _knowledgeBaseEntitySerialize(
  KnowledgeBaseEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.baseId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.description);
  writer.writeBool(offsets[3], object.isEnabled);
  writer.writeString(offsets[4], object.name);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

KnowledgeBaseEntity _knowledgeBaseEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KnowledgeBaseEntity();
  object.baseId = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.description = reader.readString(offsets[2]);
  object.id = id;
  object.isEnabled = reader.readBool(offsets[3]);
  object.name = reader.readString(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _knowledgeBaseEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _knowledgeBaseEntityGetId(KnowledgeBaseEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _knowledgeBaseEntityGetLinks(
    KnowledgeBaseEntity object) {
  return [];
}

void _knowledgeBaseEntityAttach(
    IsarCollection<dynamic> col, Id id, KnowledgeBaseEntity object) {
  object.id = id;
}

extension KnowledgeBaseEntityByIndex on IsarCollection<KnowledgeBaseEntity> {
  Future<KnowledgeBaseEntity?> getByBaseId(String baseId) {
    return getByIndex(r'baseId', [baseId]);
  }

  KnowledgeBaseEntity? getByBaseIdSync(String baseId) {
    return getByIndexSync(r'baseId', [baseId]);
  }

  Future<bool> deleteByBaseId(String baseId) {
    return deleteByIndex(r'baseId', [baseId]);
  }

  bool deleteByBaseIdSync(String baseId) {
    return deleteByIndexSync(r'baseId', [baseId]);
  }

  Future<List<KnowledgeBaseEntity?>> getAllByBaseId(List<String> baseIdValues) {
    final values = baseIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'baseId', values);
  }

  List<KnowledgeBaseEntity?> getAllByBaseIdSync(List<String> baseIdValues) {
    final values = baseIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'baseId', values);
  }

  Future<int> deleteAllByBaseId(List<String> baseIdValues) {
    final values = baseIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'baseId', values);
  }

  int deleteAllByBaseIdSync(List<String> baseIdValues) {
    final values = baseIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'baseId', values);
  }

  Future<Id> putByBaseId(KnowledgeBaseEntity object) {
    return putByIndex(r'baseId', object);
  }

  Id putByBaseIdSync(KnowledgeBaseEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'baseId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBaseId(List<KnowledgeBaseEntity> objects) {
    return putAllByIndex(r'baseId', objects);
  }

  List<Id> putAllByBaseIdSync(List<KnowledgeBaseEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'baseId', objects, saveLinks: saveLinks);
  }
}

extension KnowledgeBaseEntityQueryWhereSort
    on QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QWhere> {
  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhere>
      anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhere>
      anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension KnowledgeBaseEntityQueryWhere
    on QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QWhereClause> {
  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      baseIdEqualTo(String baseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'baseId',
        value: [baseId],
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      baseIdNotEqualTo(String baseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [],
              upper: [baseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [baseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [baseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [],
              upper: [baseId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      updatedAtEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAt',
        value: [updatedAt],
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      updatedAtNotEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      updatedAtGreaterThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [updatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      updatedAtLessThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [],
        upper: [updatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterWhereClause>
      updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [lowerUpdatedAt],
        includeLower: includeLower,
        upper: [upperUpdatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension KnowledgeBaseEntityQueryFilter on QueryBuilder<KnowledgeBaseEntity,
    KnowledgeBaseEntity, QFilterCondition> {
  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'baseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      baseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'baseId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      createdAtGreaterThan(
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      createdAtLessThan(
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      createdAtBetween(
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      isEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      updatedAtGreaterThan(
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      updatedAtLessThan(
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

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterFilterCondition>
      updatedAtBetween(
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

extension KnowledgeBaseEntityQueryObject on QueryBuilder<KnowledgeBaseEntity,
    KnowledgeBaseEntity, QFilterCondition> {}

extension KnowledgeBaseEntityQueryLinks on QueryBuilder<KnowledgeBaseEntity,
    KnowledgeBaseEntity, QFilterCondition> {}

extension KnowledgeBaseEntityQuerySortBy
    on QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QSortBy> {
  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByBaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByBaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension KnowledgeBaseEntityQuerySortThenBy
    on QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QSortThenBy> {
  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByBaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByBaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension KnowledgeBaseEntityQueryWhereDistinct
    on QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QDistinct> {
  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QDistinct>
      distinctByBaseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QDistinct>
      distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension KnowledgeBaseEntityQueryProperty
    on QueryBuilder<KnowledgeBaseEntity, KnowledgeBaseEntity, QQueryProperty> {
  QueryBuilder<KnowledgeBaseEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<KnowledgeBaseEntity, String, QQueryOperations> baseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseId');
    });
  }

  QueryBuilder<KnowledgeBaseEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<KnowledgeBaseEntity, String, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<KnowledgeBaseEntity, bool, QQueryOperations>
      isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<KnowledgeBaseEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<KnowledgeBaseEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKnowledgeDocumentEntityCollection on Isar {
  IsarCollection<KnowledgeDocumentEntity> get knowledgeDocumentEntitys =>
      this.collection();
}

const KnowledgeDocumentEntitySchema = CollectionSchema(
  name: r'KnowledgeDocumentEntity',
  id: -9027517006300557542,
  properties: {
    r'baseId': PropertySchema(
      id: 0,
      name: r'baseId',
      type: IsarType.string,
    ),
    r'chunkCount': PropertySchema(
      id: 1,
      name: r'chunkCount',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'documentId': PropertySchema(
      id: 3,
      name: r'documentId',
      type: IsarType.string,
    ),
    r'error': PropertySchema(
      id: 4,
      name: r'error',
      type: IsarType.string,
    ),
    r'fileName': PropertySchema(
      id: 5,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'sourcePath': PropertySchema(
      id: 6,
      name: r'sourcePath',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 7,
      name: r'status',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _knowledgeDocumentEntityEstimateSize,
  serialize: _knowledgeDocumentEntitySerialize,
  deserialize: _knowledgeDocumentEntityDeserialize,
  deserializeProp: _knowledgeDocumentEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'documentId': IndexSchema(
      id: 4187168439921340405,
      name: r'documentId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'documentId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'baseId': IndexSchema(
      id: 3304293301281094907,
      name: r'baseId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'baseId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _knowledgeDocumentEntityGetId,
  getLinks: _knowledgeDocumentEntityGetLinks,
  attach: _knowledgeDocumentEntityAttach,
  version: '3.1.0+1',
);

int _knowledgeDocumentEntityEstimateSize(
  KnowledgeDocumentEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.baseId.length * 3;
  bytesCount += 3 + object.documentId.length * 3;
  {
    final value = object.error;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.fileName.length * 3;
  {
    final value = object.sourcePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _knowledgeDocumentEntitySerialize(
  KnowledgeDocumentEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.baseId);
  writer.writeLong(offsets[1], object.chunkCount);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.documentId);
  writer.writeString(offsets[4], object.error);
  writer.writeString(offsets[5], object.fileName);
  writer.writeString(offsets[6], object.sourcePath);
  writer.writeString(offsets[7], object.status);
  writer.writeDateTime(offsets[8], object.updatedAt);
}

KnowledgeDocumentEntity _knowledgeDocumentEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KnowledgeDocumentEntity();
  object.baseId = reader.readString(offsets[0]);
  object.chunkCount = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.documentId = reader.readString(offsets[3]);
  object.error = reader.readStringOrNull(offsets[4]);
  object.fileName = reader.readString(offsets[5]);
  object.id = id;
  object.sourcePath = reader.readStringOrNull(offsets[6]);
  object.status = reader.readString(offsets[7]);
  object.updatedAt = reader.readDateTime(offsets[8]);
  return object;
}

P _knowledgeDocumentEntityDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _knowledgeDocumentEntityGetId(KnowledgeDocumentEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _knowledgeDocumentEntityGetLinks(
    KnowledgeDocumentEntity object) {
  return [];
}

void _knowledgeDocumentEntityAttach(
    IsarCollection<dynamic> col, Id id, KnowledgeDocumentEntity object) {
  object.id = id;
}

extension KnowledgeDocumentEntityByIndex
    on IsarCollection<KnowledgeDocumentEntity> {
  Future<KnowledgeDocumentEntity?> getByDocumentId(String documentId) {
    return getByIndex(r'documentId', [documentId]);
  }

  KnowledgeDocumentEntity? getByDocumentIdSync(String documentId) {
    return getByIndexSync(r'documentId', [documentId]);
  }

  Future<bool> deleteByDocumentId(String documentId) {
    return deleteByIndex(r'documentId', [documentId]);
  }

  bool deleteByDocumentIdSync(String documentId) {
    return deleteByIndexSync(r'documentId', [documentId]);
  }

  Future<List<KnowledgeDocumentEntity?>> getAllByDocumentId(
      List<String> documentIdValues) {
    final values = documentIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'documentId', values);
  }

  List<KnowledgeDocumentEntity?> getAllByDocumentIdSync(
      List<String> documentIdValues) {
    final values = documentIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'documentId', values);
  }

  Future<int> deleteAllByDocumentId(List<String> documentIdValues) {
    final values = documentIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'documentId', values);
  }

  int deleteAllByDocumentIdSync(List<String> documentIdValues) {
    final values = documentIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'documentId', values);
  }

  Future<Id> putByDocumentId(KnowledgeDocumentEntity object) {
    return putByIndex(r'documentId', object);
  }

  Id putByDocumentIdSync(KnowledgeDocumentEntity object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'documentId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDocumentId(List<KnowledgeDocumentEntity> objects) {
    return putAllByIndex(r'documentId', objects);
  }

  List<Id> putAllByDocumentIdSync(List<KnowledgeDocumentEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'documentId', objects, saveLinks: saveLinks);
  }
}

extension KnowledgeDocumentEntityQueryWhereSort
    on QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QWhere> {
  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterWhere>
      anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterWhere>
      anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension KnowledgeDocumentEntityQueryWhere on QueryBuilder<
    KnowledgeDocumentEntity, KnowledgeDocumentEntity, QWhereClause> {
  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> documentIdEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'documentId',
        value: [documentId],
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> documentIdNotEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [],
              upper: [documentId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [documentId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [documentId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [],
              upper: [documentId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> baseIdEqualTo(String baseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'baseId',
        value: [baseId],
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> baseIdNotEqualTo(String baseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [],
              upper: [baseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [baseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [baseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [],
              upper: [baseId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> updatedAtEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAt',
        value: [updatedAt],
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> updatedAtNotEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> updatedAtGreaterThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [updatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> updatedAtLessThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [],
        upper: [updatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterWhereClause> updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [lowerUpdatedAt],
        includeLower: includeLower,
        upper: [upperUpdatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension KnowledgeDocumentEntityQueryFilter on QueryBuilder<
    KnowledgeDocumentEntity, KnowledgeDocumentEntity, QFilterCondition> {
  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> baseIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> baseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> baseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> baseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> baseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> baseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      baseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      baseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'baseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> baseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> baseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'baseId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> chunkCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chunkCount',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> chunkCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chunkCount',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> chunkCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chunkCount',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> chunkCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chunkCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> documentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> documentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> documentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> documentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'documentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> documentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> documentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      documentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      documentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'documentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> documentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> documentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'documentId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'error',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'error',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'error',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      errorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      errorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'error',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'error',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> errorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'error',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> fileNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> fileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourcePath',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourcePath',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourcePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      sourcePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourcePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
          QAfterFilterCondition>
      sourcePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourcePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourcePath',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> sourcePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourcePath',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity,
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

extension KnowledgeDocumentEntityQueryObject on QueryBuilder<
    KnowledgeDocumentEntity, KnowledgeDocumentEntity, QFilterCondition> {}

extension KnowledgeDocumentEntityQueryLinks on QueryBuilder<
    KnowledgeDocumentEntity, KnowledgeDocumentEntity, QFilterCondition> {}

extension KnowledgeDocumentEntityQuerySortBy
    on QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QSortBy> {
  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByBaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByBaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByChunkCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkCount', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByChunkCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkCount', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortBySourcePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePath', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortBySourcePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePath', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension KnowledgeDocumentEntityQuerySortThenBy on QueryBuilder<
    KnowledgeDocumentEntity, KnowledgeDocumentEntity, QSortThenBy> {
  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByBaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByBaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByChunkCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkCount', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByChunkCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkCount', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenBySourcePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePath', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenBySourcePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePath', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension KnowledgeDocumentEntityQueryWhereDistinct on QueryBuilder<
    KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct> {
  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct>
      distinctByBaseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct>
      distinctByChunkCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chunkCount');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct>
      distinctByDocumentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct>
      distinctByError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'error', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct>
      distinctByFileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct>
      distinctBySourcePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourcePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, KnowledgeDocumentEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension KnowledgeDocumentEntityQueryProperty on QueryBuilder<
    KnowledgeDocumentEntity, KnowledgeDocumentEntity, QQueryProperty> {
  QueryBuilder<KnowledgeDocumentEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, String, QQueryOperations>
      baseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseId');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, int, QQueryOperations>
      chunkCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chunkCount');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, String, QQueryOperations>
      documentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentId');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, String?, QQueryOperations>
      errorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'error');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, String, QQueryOperations>
      fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, String?, QQueryOperations>
      sourcePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourcePath');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, String, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<KnowledgeDocumentEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKnowledgeChunkEntityCollection on Isar {
  IsarCollection<KnowledgeChunkEntity> get knowledgeChunkEntitys =>
      this.collection();
}

const KnowledgeChunkEntitySchema = CollectionSchema(
  name: r'KnowledgeChunkEntity',
  id: 1168682035057780648,
  properties: {
    r'baseId': PropertySchema(
      id: 0,
      name: r'baseId',
      type: IsarType.string,
    ),
    r'chunkId': PropertySchema(
      id: 1,
      name: r'chunkId',
      type: IsarType.string,
    ),
    r'chunkIndex': PropertySchema(
      id: 2,
      name: r'chunkIndex',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'documentId': PropertySchema(
      id: 4,
      name: r'documentId',
      type: IsarType.string,
    ),
    r'embeddingJson': PropertySchema(
      id: 5,
      name: r'embeddingJson',
      type: IsarType.string,
    ),
    r'sourceLabel': PropertySchema(
      id: 6,
      name: r'sourceLabel',
      type: IsarType.string,
    ),
    r'text': PropertySchema(
      id: 7,
      name: r'text',
      type: IsarType.string,
    ),
    r'tokenCount': PropertySchema(
      id: 8,
      name: r'tokenCount',
      type: IsarType.long,
    ),
    r'tokens': PropertySchema(
      id: 9,
      name: r'tokens',
      type: IsarType.string,
    )
  },
  estimateSize: _knowledgeChunkEntityEstimateSize,
  serialize: _knowledgeChunkEntitySerialize,
  deserialize: _knowledgeChunkEntityDeserialize,
  deserializeProp: _knowledgeChunkEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'chunkId': IndexSchema(
      id: 7020861766424886656,
      name: r'chunkId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'chunkId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'baseId': IndexSchema(
      id: 3304293301281094907,
      name: r'baseId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'baseId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'documentId': IndexSchema(
      id: 4187168439921340405,
      name: r'documentId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'documentId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _knowledgeChunkEntityGetId,
  getLinks: _knowledgeChunkEntityGetLinks,
  attach: _knowledgeChunkEntityAttach,
  version: '3.1.0+1',
);

int _knowledgeChunkEntityEstimateSize(
  KnowledgeChunkEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.baseId.length * 3;
  bytesCount += 3 + object.chunkId.length * 3;
  bytesCount += 3 + object.documentId.length * 3;
  {
    final value = object.embeddingJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sourceLabel.length * 3;
  bytesCount += 3 + object.text.length * 3;
  bytesCount += 3 + object.tokens.length * 3;
  return bytesCount;
}

void _knowledgeChunkEntitySerialize(
  KnowledgeChunkEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.baseId);
  writer.writeString(offsets[1], object.chunkId);
  writer.writeLong(offsets[2], object.chunkIndex);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.documentId);
  writer.writeString(offsets[5], object.embeddingJson);
  writer.writeString(offsets[6], object.sourceLabel);
  writer.writeString(offsets[7], object.text);
  writer.writeLong(offsets[8], object.tokenCount);
  writer.writeString(offsets[9], object.tokens);
}

KnowledgeChunkEntity _knowledgeChunkEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KnowledgeChunkEntity();
  object.baseId = reader.readString(offsets[0]);
  object.chunkId = reader.readString(offsets[1]);
  object.chunkIndex = reader.readLong(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.documentId = reader.readString(offsets[4]);
  object.embeddingJson = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.sourceLabel = reader.readString(offsets[6]);
  object.text = reader.readString(offsets[7]);
  object.tokenCount = reader.readLong(offsets[8]);
  object.tokens = reader.readString(offsets[9]);
  return object;
}

P _knowledgeChunkEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _knowledgeChunkEntityGetId(KnowledgeChunkEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _knowledgeChunkEntityGetLinks(
    KnowledgeChunkEntity object) {
  return [];
}

void _knowledgeChunkEntityAttach(
    IsarCollection<dynamic> col, Id id, KnowledgeChunkEntity object) {
  object.id = id;
}

extension KnowledgeChunkEntityByIndex on IsarCollection<KnowledgeChunkEntity> {
  Future<KnowledgeChunkEntity?> getByChunkId(String chunkId) {
    return getByIndex(r'chunkId', [chunkId]);
  }

  KnowledgeChunkEntity? getByChunkIdSync(String chunkId) {
    return getByIndexSync(r'chunkId', [chunkId]);
  }

  Future<bool> deleteByChunkId(String chunkId) {
    return deleteByIndex(r'chunkId', [chunkId]);
  }

  bool deleteByChunkIdSync(String chunkId) {
    return deleteByIndexSync(r'chunkId', [chunkId]);
  }

  Future<List<KnowledgeChunkEntity?>> getAllByChunkId(
      List<String> chunkIdValues) {
    final values = chunkIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'chunkId', values);
  }

  List<KnowledgeChunkEntity?> getAllByChunkIdSync(List<String> chunkIdValues) {
    final values = chunkIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'chunkId', values);
  }

  Future<int> deleteAllByChunkId(List<String> chunkIdValues) {
    final values = chunkIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'chunkId', values);
  }

  int deleteAllByChunkIdSync(List<String> chunkIdValues) {
    final values = chunkIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'chunkId', values);
  }

  Future<Id> putByChunkId(KnowledgeChunkEntity object) {
    return putByIndex(r'chunkId', object);
  }

  Id putByChunkIdSync(KnowledgeChunkEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'chunkId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByChunkId(List<KnowledgeChunkEntity> objects) {
    return putAllByIndex(r'chunkId', objects);
  }

  List<Id> putAllByChunkIdSync(List<KnowledgeChunkEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'chunkId', objects, saveLinks: saveLinks);
  }
}

extension KnowledgeChunkEntityQueryWhereSort
    on QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QWhere> {
  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhere>
      anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension KnowledgeChunkEntityQueryWhere
    on QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QWhereClause> {
  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      chunkIdEqualTo(String chunkId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'chunkId',
        value: [chunkId],
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      chunkIdNotEqualTo(String chunkId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chunkId',
              lower: [],
              upper: [chunkId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chunkId',
              lower: [chunkId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chunkId',
              lower: [chunkId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chunkId',
              lower: [],
              upper: [chunkId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      baseIdEqualTo(String baseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'baseId',
        value: [baseId],
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      baseIdNotEqualTo(String baseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [],
              upper: [baseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [baseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [baseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'baseId',
              lower: [],
              upper: [baseId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      documentIdEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'documentId',
        value: [documentId],
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      documentIdNotEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [],
              upper: [documentId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [documentId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [documentId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'documentId',
              lower: [],
              upper: [documentId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterWhereClause>
      createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension KnowledgeChunkEntityQueryFilter on QueryBuilder<KnowledgeChunkEntity,
    KnowledgeChunkEntity, QFilterCondition> {
  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> baseIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> baseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> baseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> baseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> baseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> baseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      baseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'baseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      baseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'baseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> baseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> baseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'baseId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chunkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chunkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chunkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chunkId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'chunkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'chunkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      chunkIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'chunkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      chunkIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'chunkId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chunkId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'chunkId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chunkIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chunkIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chunkIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> chunkIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chunkIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
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

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
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

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
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

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> documentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> documentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> documentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> documentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'documentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> documentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> documentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      documentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'documentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      documentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'documentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> documentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> documentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'documentId',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'embeddingJson',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'embeddingJson',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'embeddingJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      embeddingJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'embeddingJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      embeddingJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'embeddingJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'embeddingJson',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> embeddingJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'embeddingJson',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
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

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
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

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
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

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> sourceLabelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> sourceLabelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> sourceLabelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> sourceLabelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceLabel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> sourceLabelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> sourceLabelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      sourceLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      sourceLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceLabel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> sourceLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> sourceLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokenCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokenCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokenCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokenCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tokenCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokensEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokensGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokensLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokensBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tokens',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokensStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokensEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      tokensContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tokens',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
          QAfterFilterCondition>
      tokensMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tokens',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokensIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokens',
        value: '',
      ));
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity,
      QAfterFilterCondition> tokensIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tokens',
        value: '',
      ));
    });
  }
}

extension KnowledgeChunkEntityQueryObject on QueryBuilder<KnowledgeChunkEntity,
    KnowledgeChunkEntity, QFilterCondition> {}

extension KnowledgeChunkEntityQueryLinks on QueryBuilder<KnowledgeChunkEntity,
    KnowledgeChunkEntity, QFilterCondition> {}

extension KnowledgeChunkEntityQuerySortBy
    on QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QSortBy> {
  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByBaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByBaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByChunkId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByChunkIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByChunkIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkIndex', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByChunkIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkIndex', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByEmbeddingJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByEmbeddingJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortBySourceLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLabel', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortBySourceLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLabel', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokens', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      sortByTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokens', Sort.desc);
    });
  }
}

extension KnowledgeChunkEntityQuerySortThenBy
    on QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QSortThenBy> {
  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByBaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByBaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByChunkId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByChunkIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByChunkIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkIndex', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByChunkIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkIndex', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByEmbeddingJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByEmbeddingJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingJson', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenBySourceLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLabel', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenBySourceLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLabel', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.desc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokens', Sort.asc);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QAfterSortBy>
      thenByTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokens', Sort.desc);
    });
  }
}

extension KnowledgeChunkEntityQueryWhereDistinct
    on QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct> {
  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctByBaseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctByChunkId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chunkId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctByChunkIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chunkIndex');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctByDocumentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctByEmbeddingJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'embeddingJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctBySourceLabel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceLabel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctByText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctByTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tokenCount');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, KnowledgeChunkEntity, QDistinct>
      distinctByTokens({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tokens', caseSensitive: caseSensitive);
    });
  }
}

extension KnowledgeChunkEntityQueryProperty on QueryBuilder<
    KnowledgeChunkEntity, KnowledgeChunkEntity, QQueryProperty> {
  QueryBuilder<KnowledgeChunkEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, String, QQueryOperations>
      baseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseId');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, String, QQueryOperations>
      chunkIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chunkId');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, int, QQueryOperations>
      chunkIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chunkIndex');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, String, QQueryOperations>
      documentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentId');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, String?, QQueryOperations>
      embeddingJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'embeddingJson');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, String, QQueryOperations>
      sourceLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceLabel');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, String, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, int, QQueryOperations>
      tokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tokenCount');
    });
  }

  QueryBuilder<KnowledgeChunkEntity, String, QQueryOperations>
      tokensProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tokens');
    });
  }
}
