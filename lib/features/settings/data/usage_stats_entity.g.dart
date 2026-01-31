// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_stats_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUsageStatsEntityCollection on Isar {
  IsarCollection<UsageStatsEntity> get usageStatsEntitys => this.collection();
}

const UsageStatsEntitySchema = CollectionSchema(
  name: r'UsageStatsEntity',
  id: 4367195191658653319,
  properties: {
    r'completionTokenCount': PropertySchema(
      id: 0,
      name: r'completionTokenCount',
      type: IsarType.long,
    ),
    r'errorBadRequestCount': PropertySchema(
      id: 1,
      name: r'errorBadRequestCount',
      type: IsarType.long,
    ),
    r'errorNetworkCount': PropertySchema(
      id: 2,
      name: r'errorNetworkCount',
      type: IsarType.long,
    ),
    r'errorRateLimitCount': PropertySchema(
      id: 3,
      name: r'errorRateLimitCount',
      type: IsarType.long,
    ),
    r'errorServerCount': PropertySchema(
      id: 4,
      name: r'errorServerCount',
      type: IsarType.long,
    ),
    r'errorTimeoutCount': PropertySchema(
      id: 5,
      name: r'errorTimeoutCount',
      type: IsarType.long,
    ),
    r'errorUnauthorizedCount': PropertySchema(
      id: 6,
      name: r'errorUnauthorizedCount',
      type: IsarType.long,
    ),
    r'errorUnknownCount': PropertySchema(
      id: 7,
      name: r'errorUnknownCount',
      type: IsarType.long,
    ),
    r'failureCount': PropertySchema(
      id: 8,
      name: r'failureCount',
      type: IsarType.long,
    ),
    r'modelName': PropertySchema(
      id: 9,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'promptTokenCount': PropertySchema(
      id: 10,
      name: r'promptTokenCount',
      type: IsarType.long,
    ),
    r'reasoningTokenCount': PropertySchema(
      id: 11,
      name: r'reasoningTokenCount',
      type: IsarType.long,
    ),
    r'successCount': PropertySchema(
      id: 12,
      name: r'successCount',
      type: IsarType.long,
    ),
    r'totalDurationMs': PropertySchema(
      id: 13,
      name: r'totalDurationMs',
      type: IsarType.long,
    ),
    r'totalFirstTokenMs': PropertySchema(
      id: 14,
      name: r'totalFirstTokenMs',
      type: IsarType.long,
    ),
    r'totalTokenCount': PropertySchema(
      id: 15,
      name: r'totalTokenCount',
      type: IsarType.long,
    ),
    r'validDurationCount': PropertySchema(
      id: 16,
      name: r'validDurationCount',
      type: IsarType.long,
    ),
    r'validFirstTokenCount': PropertySchema(
      id: 17,
      name: r'validFirstTokenCount',
      type: IsarType.long,
    )
  },
  estimateSize: _usageStatsEntityEstimateSize,
  serialize: _usageStatsEntitySerialize,
  deserialize: _usageStatsEntityDeserialize,
  deserializeProp: _usageStatsEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'modelName': IndexSchema(
      id: -5766876836036160997,
      name: r'modelName',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'modelName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _usageStatsEntityGetId,
  getLinks: _usageStatsEntityGetLinks,
  attach: _usageStatsEntityAttach,
  version: '3.1.0+1',
);

int _usageStatsEntityEstimateSize(
  UsageStatsEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.modelName.length * 3;
  return bytesCount;
}

void _usageStatsEntitySerialize(
  UsageStatsEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.completionTokenCount);
  writer.writeLong(offsets[1], object.errorBadRequestCount);
  writer.writeLong(offsets[2], object.errorNetworkCount);
  writer.writeLong(offsets[3], object.errorRateLimitCount);
  writer.writeLong(offsets[4], object.errorServerCount);
  writer.writeLong(offsets[5], object.errorTimeoutCount);
  writer.writeLong(offsets[6], object.errorUnauthorizedCount);
  writer.writeLong(offsets[7], object.errorUnknownCount);
  writer.writeLong(offsets[8], object.failureCount);
  writer.writeString(offsets[9], object.modelName);
  writer.writeLong(offsets[10], object.promptTokenCount);
  writer.writeLong(offsets[11], object.reasoningTokenCount);
  writer.writeLong(offsets[12], object.successCount);
  writer.writeLong(offsets[13], object.totalDurationMs);
  writer.writeLong(offsets[14], object.totalFirstTokenMs);
  writer.writeLong(offsets[15], object.totalTokenCount);
  writer.writeLong(offsets[16], object.validDurationCount);
  writer.writeLong(offsets[17], object.validFirstTokenCount);
}

UsageStatsEntity _usageStatsEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UsageStatsEntity();
  object.completionTokenCount = reader.readLong(offsets[0]);
  object.errorBadRequestCount = reader.readLong(offsets[1]);
  object.errorNetworkCount = reader.readLong(offsets[2]);
  object.errorRateLimitCount = reader.readLong(offsets[3]);
  object.errorServerCount = reader.readLong(offsets[4]);
  object.errorTimeoutCount = reader.readLong(offsets[5]);
  object.errorUnauthorizedCount = reader.readLong(offsets[6]);
  object.errorUnknownCount = reader.readLong(offsets[7]);
  object.failureCount = reader.readLong(offsets[8]);
  object.id = id;
  object.modelName = reader.readString(offsets[9]);
  object.promptTokenCount = reader.readLong(offsets[10]);
  object.reasoningTokenCount = reader.readLong(offsets[11]);
  object.successCount = reader.readLong(offsets[12]);
  object.totalDurationMs = reader.readLong(offsets[13]);
  object.totalFirstTokenMs = reader.readLong(offsets[14]);
  object.totalTokenCount = reader.readLong(offsets[15]);
  object.validDurationCount = reader.readLong(offsets[16]);
  object.validFirstTokenCount = reader.readLong(offsets[17]);
  return object;
}

P _usageStatsEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _usageStatsEntityGetId(UsageStatsEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _usageStatsEntityGetLinks(UsageStatsEntity object) {
  return [];
}

void _usageStatsEntityAttach(
    IsarCollection<dynamic> col, Id id, UsageStatsEntity object) {
  object.id = id;
}

extension UsageStatsEntityByIndex on IsarCollection<UsageStatsEntity> {
  Future<UsageStatsEntity?> getByModelName(String modelName) {
    return getByIndex(r'modelName', [modelName]);
  }

  UsageStatsEntity? getByModelNameSync(String modelName) {
    return getByIndexSync(r'modelName', [modelName]);
  }

  Future<bool> deleteByModelName(String modelName) {
    return deleteByIndex(r'modelName', [modelName]);
  }

  bool deleteByModelNameSync(String modelName) {
    return deleteByIndexSync(r'modelName', [modelName]);
  }

  Future<List<UsageStatsEntity?>> getAllByModelName(
      List<String> modelNameValues) {
    final values = modelNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'modelName', values);
  }

  List<UsageStatsEntity?> getAllByModelNameSync(List<String> modelNameValues) {
    final values = modelNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'modelName', values);
  }

  Future<int> deleteAllByModelName(List<String> modelNameValues) {
    final values = modelNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'modelName', values);
  }

  int deleteAllByModelNameSync(List<String> modelNameValues) {
    final values = modelNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'modelName', values);
  }

  Future<Id> putByModelName(UsageStatsEntity object) {
    return putByIndex(r'modelName', object);
  }

  Id putByModelNameSync(UsageStatsEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'modelName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByModelName(List<UsageStatsEntity> objects) {
    return putAllByIndex(r'modelName', objects);
  }

  List<Id> putAllByModelNameSync(List<UsageStatsEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'modelName', objects, saveLinks: saveLinks);
  }
}

extension UsageStatsEntityQueryWhereSort
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QWhere> {
  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UsageStatsEntityQueryWhere
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QWhereClause> {
  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterWhereClause>
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

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterWhereClause>
      modelNameEqualTo(String modelName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'modelName',
        value: [modelName],
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterWhereClause>
      modelNameNotEqualTo(String modelName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'modelName',
              lower: [],
              upper: [modelName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'modelName',
              lower: [modelName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'modelName',
              lower: [modelName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'modelName',
              lower: [],
              upper: [modelName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension UsageStatsEntityQueryFilter
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QFilterCondition> {
  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      completionTokenCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completionTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      completionTokenCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completionTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      completionTokenCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completionTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      completionTokenCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completionTokenCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorBadRequestCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorBadRequestCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorBadRequestCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorBadRequestCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorBadRequestCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorBadRequestCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorBadRequestCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorBadRequestCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorNetworkCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorNetworkCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorNetworkCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorNetworkCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorNetworkCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorNetworkCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorNetworkCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorNetworkCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorRateLimitCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorRateLimitCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorRateLimitCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorRateLimitCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorRateLimitCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorRateLimitCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorRateLimitCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorRateLimitCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorServerCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorServerCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorServerCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorServerCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorServerCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorServerCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorServerCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorServerCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorTimeoutCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorTimeoutCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorTimeoutCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorTimeoutCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorTimeoutCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorTimeoutCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorTimeoutCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorTimeoutCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorUnauthorizedCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorUnauthorizedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorUnauthorizedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorUnauthorizedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorUnauthorizedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorUnauthorizedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorUnauthorizedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorUnauthorizedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorUnknownCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorUnknownCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorUnknownCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorUnknownCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorUnknownCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorUnknownCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      errorUnknownCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorUnknownCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      failureCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failureCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      failureCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failureCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      failureCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failureCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      failureCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failureCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
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

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
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

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
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

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modelName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modelName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelName',
        value: '',
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      modelNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modelName',
        value: '',
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      promptTokenCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      promptTokenCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'promptTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      promptTokenCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'promptTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      promptTokenCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'promptTokenCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      reasoningTokenCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reasoningTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      reasoningTokenCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reasoningTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      reasoningTokenCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reasoningTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      reasoningTokenCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reasoningTokenCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      successCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'successCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      successCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'successCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      successCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'successCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      successCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'successCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalDurationMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalDurationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalDurationMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalDurationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalDurationMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalDurationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalDurationMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalDurationMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalFirstTokenMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalFirstTokenMs',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalFirstTokenMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalFirstTokenMs',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalFirstTokenMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalFirstTokenMs',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalFirstTokenMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalFirstTokenMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalTokenCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalTokenCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalTokenCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      totalTokenCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalTokenCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      validDurationCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'validDurationCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      validDurationCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'validDurationCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      validDurationCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'validDurationCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      validDurationCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'validDurationCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      validFirstTokenCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'validFirstTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      validFirstTokenCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'validFirstTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      validFirstTokenCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'validFirstTokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterFilterCondition>
      validFirstTokenCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'validFirstTokenCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension UsageStatsEntityQueryObject
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QFilterCondition> {}

extension UsageStatsEntityQueryLinks
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QFilterCondition> {}

extension UsageStatsEntityQuerySortBy
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QSortBy> {
  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByCompletionTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByCompletionTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionTokenCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorBadRequestCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorBadRequestCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorBadRequestCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorBadRequestCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorNetworkCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorNetworkCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorNetworkCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorNetworkCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorRateLimitCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorRateLimitCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorRateLimitCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorRateLimitCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorServerCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorServerCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorServerCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorServerCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorTimeoutCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorTimeoutCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorTimeoutCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorTimeoutCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorUnauthorizedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorUnauthorizedCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorUnauthorizedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorUnauthorizedCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorUnknownCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorUnknownCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByErrorUnknownCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorUnknownCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByFailureCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByFailureCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByPromptTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByPromptTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokenCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByReasoningTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByReasoningTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningTokenCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortBySuccessCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByTotalDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationMs', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByTotalDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationMs', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByTotalFirstTokenMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFirstTokenMs', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByTotalFirstTokenMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFirstTokenMs', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByTotalTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByTotalTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokenCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByValidDurationCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validDurationCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByValidDurationCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validDurationCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByValidFirstTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validFirstTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      sortByValidFirstTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validFirstTokenCount', Sort.desc);
    });
  }
}

extension UsageStatsEntityQuerySortThenBy
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QSortThenBy> {
  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByCompletionTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByCompletionTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionTokenCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorBadRequestCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorBadRequestCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorBadRequestCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorBadRequestCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorNetworkCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorNetworkCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorNetworkCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorNetworkCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorRateLimitCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorRateLimitCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorRateLimitCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorRateLimitCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorServerCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorServerCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorServerCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorServerCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorTimeoutCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorTimeoutCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorTimeoutCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorTimeoutCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorUnauthorizedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorUnauthorizedCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorUnauthorizedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorUnauthorizedCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorUnknownCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorUnknownCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByErrorUnknownCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorUnknownCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByFailureCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByFailureCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByPromptTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByPromptTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokenCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByReasoningTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByReasoningTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningTokenCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenBySuccessCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByTotalDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationMs', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByTotalDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationMs', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByTotalFirstTokenMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFirstTokenMs', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByTotalFirstTokenMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFirstTokenMs', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByTotalTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByTotalTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokenCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByValidDurationCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validDurationCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByValidDurationCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validDurationCount', Sort.desc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByValidFirstTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validFirstTokenCount', Sort.asc);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QAfterSortBy>
      thenByValidFirstTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validFirstTokenCount', Sort.desc);
    });
  }
}

extension UsageStatsEntityQueryWhereDistinct
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct> {
  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByCompletionTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completionTokenCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByErrorBadRequestCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorBadRequestCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByErrorNetworkCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorNetworkCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByErrorRateLimitCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorRateLimitCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByErrorServerCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorServerCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByErrorTimeoutCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorTimeoutCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByErrorUnauthorizedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorUnauthorizedCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByErrorUnknownCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorUnknownCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByFailureCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failureCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByModelName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByPromptTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptTokenCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByReasoningTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reasoningTokenCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'successCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByTotalDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalDurationMs');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByTotalFirstTokenMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalFirstTokenMs');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByTotalTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalTokenCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByValidDurationCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'validDurationCount');
    });
  }

  QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct>
      distinctByValidFirstTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'validFirstTokenCount');
    });
  }
}

extension UsageStatsEntityQueryProperty
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QQueryProperty> {
  QueryBuilder<UsageStatsEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      completionTokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completionTokenCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      errorBadRequestCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorBadRequestCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      errorNetworkCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorNetworkCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      errorRateLimitCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorRateLimitCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      errorServerCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorServerCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      errorTimeoutCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorTimeoutCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      errorUnauthorizedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorUnauthorizedCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      errorUnknownCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorUnknownCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations> failureCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failureCount');
    });
  }

  QueryBuilder<UsageStatsEntity, String, QQueryOperations> modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      promptTokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptTokenCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      reasoningTokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reasoningTokenCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations> successCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'successCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      totalDurationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalDurationMs');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      totalFirstTokenMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalFirstTokenMs');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      totalTokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalTokenCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      validDurationCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'validDurationCount');
    });
  }

  QueryBuilder<UsageStatsEntity, int, QQueryOperations>
      validFirstTokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'validFirstTokenCount');
    });
  }
}
