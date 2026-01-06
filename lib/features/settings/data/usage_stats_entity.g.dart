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
    r'failureCount': PropertySchema(
      id: 0,
      name: r'failureCount',
      type: IsarType.long,
    ),
    r'modelName': PropertySchema(
      id: 1,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'successCount': PropertySchema(
      id: 2,
      name: r'successCount',
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
  writer.writeLong(offsets[0], object.failureCount);
  writer.writeString(offsets[1], object.modelName);
  writer.writeLong(offsets[2], object.successCount);
}

UsageStatsEntity _usageStatsEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UsageStatsEntity();
  object.failureCount = reader.readLong(offsets[0]);
  object.id = id;
  object.modelName = reader.readString(offsets[1]);
  object.successCount = reader.readLong(offsets[2]);
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
      return (reader.readString(offset)) as P;
    case 2:
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
}

extension UsageStatsEntityQueryObject
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QFilterCondition> {}

extension UsageStatsEntityQueryLinks
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QFilterCondition> {}

extension UsageStatsEntityQuerySortBy
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QSortBy> {
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
}

extension UsageStatsEntityQuerySortThenBy
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QSortThenBy> {
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
}

extension UsageStatsEntityQueryWhereDistinct
    on QueryBuilder<UsageStatsEntity, UsageStatsEntity, QDistinct> {
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
      distinctBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'successCount');
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

  QueryBuilder<UsageStatsEntity, int, QQueryOperations> successCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'successCount');
    });
  }
}
