// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_usage_stats_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyUsageStatsEntityCollection on Isar {
  IsarCollection<DailyUsageStatsEntity> get dailyUsageStatsEntitys =>
      this.collection();
}

const DailyUsageStatsEntitySchema = CollectionSchema(
  name: r'DailyUsageStatsEntity',
  id: 8392148394920235382,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'failureCount': PropertySchema(
      id: 1,
      name: r'failureCount',
      type: IsarType.long,
    ),
    r'successCount': PropertySchema(
      id: 2,
      name: r'successCount',
      type: IsarType.long,
    ),
    r'tokenCount': PropertySchema(
      id: 3,
      name: r'tokenCount',
      type: IsarType.long,
    ),
    r'totalCalls': PropertySchema(
      id: 4,
      name: r'totalCalls',
      type: IsarType.long,
    )
  },
  estimateSize: _dailyUsageStatsEntityEstimateSize,
  serialize: _dailyUsageStatsEntitySerialize,
  deserialize: _dailyUsageStatsEntityDeserialize,
  deserializeProp: _dailyUsageStatsEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyUsageStatsEntityGetId,
  getLinks: _dailyUsageStatsEntityGetLinks,
  attach: _dailyUsageStatsEntityAttach,
  version: '3.1.0+1',
);

int _dailyUsageStatsEntityEstimateSize(
  DailyUsageStatsEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _dailyUsageStatsEntitySerialize(
  DailyUsageStatsEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeLong(offsets[1], object.failureCount);
  writer.writeLong(offsets[2], object.successCount);
  writer.writeLong(offsets[3], object.tokenCount);
  writer.writeLong(offsets[4], object.totalCalls);
}

DailyUsageStatsEntity _dailyUsageStatsEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyUsageStatsEntity();
  object.date = reader.readDateTime(offsets[0]);
  object.failureCount = reader.readLong(offsets[1]);
  object.id = id;
  object.successCount = reader.readLong(offsets[2]);
  object.tokenCount = reader.readLong(offsets[3]);
  object.totalCalls = reader.readLong(offsets[4]);
  return object;
}

P _dailyUsageStatsEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyUsageStatsEntityGetId(DailyUsageStatsEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyUsageStatsEntityGetLinks(
    DailyUsageStatsEntity object) {
  return [];
}

void _dailyUsageStatsEntityAttach(
    IsarCollection<dynamic> col, Id id, DailyUsageStatsEntity object) {
  object.id = id;
}

extension DailyUsageStatsEntityByIndex
    on IsarCollection<DailyUsageStatsEntity> {
  Future<DailyUsageStatsEntity?> getByDate(DateTime date) {
    return getByIndex(r'date', [date]);
  }

  DailyUsageStatsEntity? getByDateSync(DateTime date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(DateTime date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(DateTime date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<DailyUsageStatsEntity?>> getAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<DailyUsageStatsEntity?> getAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(DailyUsageStatsEntity object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(DailyUsageStatsEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<DailyUsageStatsEntity> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<DailyUsageStatsEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension DailyUsageStatsEntityQueryWhereSort
    on QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QWhere> {
  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhere>
      anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension DailyUsageStatsEntityQueryWhere on QueryBuilder<DailyUsageStatsEntity,
    DailyUsageStatsEntity, QWhereClause> {
  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
      dateEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
      dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterWhereClause>
      dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyUsageStatsEntityQueryFilter on QueryBuilder<
    DailyUsageStatsEntity, DailyUsageStatsEntity, QFilterCondition> {
  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> failureCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failureCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> failureCountGreaterThan(
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> failureCountLessThan(
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> failureCountBetween(
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> successCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'successCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> successCountGreaterThan(
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> successCountLessThan(
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> successCountBetween(
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> tokenCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
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

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> totalCallsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCalls',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> totalCallsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCalls',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> totalCallsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCalls',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity,
      QAfterFilterCondition> totalCallsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCalls',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyUsageStatsEntityQueryObject on QueryBuilder<
    DailyUsageStatsEntity, DailyUsageStatsEntity, QFilterCondition> {}

extension DailyUsageStatsEntityQueryLinks on QueryBuilder<DailyUsageStatsEntity,
    DailyUsageStatsEntity, QFilterCondition> {}

extension DailyUsageStatsEntityQuerySortBy
    on QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QSortBy> {
  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortByFailureCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortByFailureCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.desc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortBySuccessCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.desc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortByTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortByTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.desc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortByTotalCalls() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalls', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      sortByTotalCallsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalls', Sort.desc);
    });
  }
}

extension DailyUsageStatsEntityQuerySortThenBy
    on QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QSortThenBy> {
  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenByFailureCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenByFailureCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.desc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenBySuccessCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.desc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenByTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenByTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.desc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenByTotalCalls() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalls', Sort.asc);
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QAfterSortBy>
      thenByTotalCallsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalls', Sort.desc);
    });
  }
}

extension DailyUsageStatsEntityQueryWhereDistinct
    on QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QDistinct> {
  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QDistinct>
      distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QDistinct>
      distinctByFailureCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failureCount');
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QDistinct>
      distinctBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'successCount');
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QDistinct>
      distinctByTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tokenCount');
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DailyUsageStatsEntity, QDistinct>
      distinctByTotalCalls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCalls');
    });
  }
}

extension DailyUsageStatsEntityQueryProperty on QueryBuilder<
    DailyUsageStatsEntity, DailyUsageStatsEntity, QQueryProperty> {
  QueryBuilder<DailyUsageStatsEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyUsageStatsEntity, DateTime, QQueryOperations>
      dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailyUsageStatsEntity, int, QQueryOperations>
      failureCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failureCount');
    });
  }

  QueryBuilder<DailyUsageStatsEntity, int, QQueryOperations>
      successCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'successCount');
    });
  }

  QueryBuilder<DailyUsageStatsEntity, int, QQueryOperations>
      tokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tokenCount');
    });
  }

  QueryBuilder<DailyUsageStatsEntity, int, QQueryOperations>
      totalCallsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCalls');
    });
  }
}
