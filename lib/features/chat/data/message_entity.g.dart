// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMessageEntityCollection on Isar {
  IsarCollection<MessageEntity> get messageEntitys => this.collection();
}

const MessageEntitySchema = CollectionSchema(
  name: r'MessageEntity',
  id: 2569526783852321106,
  properties: {
    r'assistantId': PropertySchema(
      id: 0,
      name: r'assistantId',
      type: IsarType.string,
    ),
    r'attachments': PropertySchema(
      id: 1,
      name: r'attachments',
      type: IsarType.stringList,
    ),
    r'completionTokens': PropertySchema(
      id: 2,
      name: r'completionTokens',
      type: IsarType.long,
    ),
    r'content': PropertySchema(
      id: 3,
      name: r'content',
      type: IsarType.string,
    ),
    r'durationMs': PropertySchema(
      id: 4,
      name: r'durationMs',
      type: IsarType.long,
    ),
    r'firstTokenMs': PropertySchema(
      id: 5,
      name: r'firstTokenMs',
      type: IsarType.long,
    ),
    r'images': PropertySchema(
      id: 6,
      name: r'images',
      type: IsarType.stringList,
    ),
    r'isUser': PropertySchema(
      id: 7,
      name: r'isUser',
      type: IsarType.bool,
    ),
    r'model': PropertySchema(
      id: 8,
      name: r'model',
      type: IsarType.string,
    ),
    r'promptTokens': PropertySchema(
      id: 9,
      name: r'promptTokens',
      type: IsarType.long,
    ),
    r'provider': PropertySchema(
      id: 10,
      name: r'provider',
      type: IsarType.string,
    ),
    r'reasoningContent': PropertySchema(
      id: 11,
      name: r'reasoningContent',
      type: IsarType.string,
    ),
    r'reasoningDurationSeconds': PropertySchema(
      id: 12,
      name: r'reasoningDurationSeconds',
      type: IsarType.double,
    ),
    r'reasoningTokens': PropertySchema(
      id: 13,
      name: r'reasoningTokens',
      type: IsarType.long,
    ),
    r'requestId': PropertySchema(
      id: 14,
      name: r'requestId',
      type: IsarType.string,
    ),
    r'role': PropertySchema(
      id: 15,
      name: r'role',
      type: IsarType.string,
    ),
    r'sessionId': PropertySchema(
      id: 16,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 17,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'tokenCount': PropertySchema(
      id: 18,
      name: r'tokenCount',
      type: IsarType.long,
    ),
    r'toolCallId': PropertySchema(
      id: 19,
      name: r'toolCallId',
      type: IsarType.string,
    ),
    r'toolCallsJson': PropertySchema(
      id: 20,
      name: r'toolCallsJson',
      type: IsarType.string,
    )
  },
  estimateSize: _messageEntityEstimateSize,
  serialize: _messageEntitySerialize,
  deserialize: _messageEntityDeserialize,
  deserializeProp: _messageEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'sessionId': IndexSchema(
      id: 6949518585047923839,
      name: r'sessionId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionId',
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
    r'requestId': IndexSchema(
      id: 938047444593699237,
      name: r'requestId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'requestId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _messageEntityGetId,
  getLinks: _messageEntityGetLinks,
  attach: _messageEntityAttach,
  version: '3.1.0+1',
);

int _messageEntityEstimateSize(
  MessageEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.assistantId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.attachments.length * 3;
  {
    for (var i = 0; i < object.attachments.length; i++) {
      final value = object.attachments[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.images.length * 3;
  {
    for (var i = 0; i < object.images.length; i++) {
      final value = object.images[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.model;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.provider;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.reasoningContent;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.requestId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.role;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sessionId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.toolCallId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.toolCallsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _messageEntitySerialize(
  MessageEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assistantId);
  writer.writeStringList(offsets[1], object.attachments);
  writer.writeLong(offsets[2], object.completionTokens);
  writer.writeString(offsets[3], object.content);
  writer.writeLong(offsets[4], object.durationMs);
  writer.writeLong(offsets[5], object.firstTokenMs);
  writer.writeStringList(offsets[6], object.images);
  writer.writeBool(offsets[7], object.isUser);
  writer.writeString(offsets[8], object.model);
  writer.writeLong(offsets[9], object.promptTokens);
  writer.writeString(offsets[10], object.provider);
  writer.writeString(offsets[11], object.reasoningContent);
  writer.writeDouble(offsets[12], object.reasoningDurationSeconds);
  writer.writeLong(offsets[13], object.reasoningTokens);
  writer.writeString(offsets[14], object.requestId);
  writer.writeString(offsets[15], object.role);
  writer.writeString(offsets[16], object.sessionId);
  writer.writeDateTime(offsets[17], object.timestamp);
  writer.writeLong(offsets[18], object.tokenCount);
  writer.writeString(offsets[19], object.toolCallId);
  writer.writeString(offsets[20], object.toolCallsJson);
}

MessageEntity _messageEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MessageEntity();
  object.assistantId = reader.readStringOrNull(offsets[0]);
  object.attachments = reader.readStringList(offsets[1]) ?? [];
  object.completionTokens = reader.readLongOrNull(offsets[2]);
  object.content = reader.readString(offsets[3]);
  object.durationMs = reader.readLongOrNull(offsets[4]);
  object.firstTokenMs = reader.readLongOrNull(offsets[5]);
  object.id = id;
  object.images = reader.readStringList(offsets[6]) ?? [];
  object.isUser = reader.readBool(offsets[7]);
  object.model = reader.readStringOrNull(offsets[8]);
  object.promptTokens = reader.readLongOrNull(offsets[9]);
  object.provider = reader.readStringOrNull(offsets[10]);
  object.reasoningContent = reader.readStringOrNull(offsets[11]);
  object.reasoningDurationSeconds = reader.readDoubleOrNull(offsets[12]);
  object.reasoningTokens = reader.readLongOrNull(offsets[13]);
  object.requestId = reader.readStringOrNull(offsets[14]);
  object.role = reader.readStringOrNull(offsets[15]);
  object.sessionId = reader.readStringOrNull(offsets[16]);
  object.timestamp = reader.readDateTime(offsets[17]);
  object.tokenCount = reader.readLongOrNull(offsets[18]);
  object.toolCallId = reader.readStringOrNull(offsets[19]);
  object.toolCallsJson = reader.readStringOrNull(offsets[20]);
  return object;
}

P _messageEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringList(offset) ?? []) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readDateTime(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _messageEntityGetId(MessageEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _messageEntityGetLinks(MessageEntity object) {
  return [];
}

void _messageEntityAttach(
    IsarCollection<dynamic> col, Id id, MessageEntity object) {
  object.id = id;
}

extension MessageEntityQueryWhereSort
    on QueryBuilder<MessageEntity, MessageEntity, QWhere> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension MessageEntityQueryWhere
    on QueryBuilder<MessageEntity, MessageEntity, QWhereClause> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      sessionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [null],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      sessionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sessionId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      sessionIdEqualTo(String? sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [sessionId],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      sessionIdNotEqualTo(String? sessionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      assistantIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'assistantId',
        value: [null],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      assistantIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'assistantId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      assistantIdEqualTo(String? assistantId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'assistantId',
        value: [assistantId],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      assistantIdNotEqualTo(String? assistantId) {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      requestIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'requestId',
        value: [null],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      requestIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'requestId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      requestIdEqualTo(String? requestId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'requestId',
        value: [requestId],
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterWhereClause>
      requestIdNotEqualTo(String? requestId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'requestId',
              lower: [],
              upper: [requestId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'requestId',
              lower: [requestId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'requestId',
              lower: [requestId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'requestId',
              lower: [],
              upper: [requestId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MessageEntityQueryFilter
    on QueryBuilder<MessageEntity, MessageEntity, QFilterCondition> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'assistantId',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'assistantId',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdEqualTo(
    String? value, {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdGreaterThan(
    String? value, {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdLessThan(
    String? value, {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdStartsWith(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdEndsWith(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assistantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assistantId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assistantId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      assistantIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assistantId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachments',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attachments',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attachments',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attachments',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'attachments',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'attachments',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'attachments',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'attachments',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachments',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'attachments',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      attachmentsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      completionTokensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completionTokens',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      completionTokensIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completionTokens',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      completionTokensEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completionTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      completionTokensGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completionTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      completionTokensLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completionTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      completionTokensBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completionTokens',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      durationMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationMs',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      durationMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationMs',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      durationMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      durationMsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      durationMsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      durationMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      firstTokenMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'firstTokenMs',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      firstTokenMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'firstTokenMs',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      firstTokenMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firstTokenMs',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      firstTokenMsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firstTokenMs',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      firstTokenMsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firstTokenMs',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      firstTokenMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firstTokenMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'images',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'images',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'images',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'images',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      imagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      isUserEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUser',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'model',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'model',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'model',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'model',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'model',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'model',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      modelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'model',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      promptTokensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'promptTokens',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      promptTokensIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'promptTokens',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      promptTokensEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      promptTokensGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'promptTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      promptTokensLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'promptTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      promptTokensBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'promptTokens',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'provider',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'provider',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'provider',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'provider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      providerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'provider',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reasoningContent',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reasoningContent',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reasoningContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reasoningContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reasoningContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reasoningContent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reasoningContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reasoningContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reasoningContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reasoningContent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reasoningContent',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningContentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reasoningContent',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningDurationSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reasoningDurationSeconds',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningDurationSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reasoningDurationSeconds',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningDurationSecondsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reasoningDurationSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningDurationSecondsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reasoningDurationSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningDurationSecondsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reasoningDurationSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningDurationSecondsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reasoningDurationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningTokensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reasoningTokens',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningTokensIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reasoningTokens',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningTokensEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reasoningTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningTokensGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reasoningTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningTokensLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reasoningTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      reasoningTokensBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reasoningTokens',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'requestId',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'requestId',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requestId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'requestId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'requestId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'requestId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'requestId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'requestId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'requestId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'requestId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requestId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      requestIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'requestId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      roleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'role',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      roleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'role',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> roleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      roleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      roleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> roleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'role',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      roleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      roleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      roleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition> roleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'role',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sessionId',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sessionId',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      tokenCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tokenCount',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      tokenCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tokenCount',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      tokenCountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokenCount',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      tokenCountGreaterThan(
    int? value, {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      tokenCountLessThan(
    int? value, {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      tokenCountBetween(
    int? lower,
    int? upper, {
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

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'toolCallId',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'toolCallId',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toolCallId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toolCallId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toolCallId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toolCallId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'toolCallId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'toolCallId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'toolCallId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'toolCallId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toolCallId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'toolCallId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'toolCallsJson',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'toolCallsJson',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toolCallsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toolCallsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toolCallsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toolCallsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'toolCallsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'toolCallsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'toolCallsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'toolCallsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toolCallsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterFilterCondition>
      toolCallsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'toolCallsJson',
        value: '',
      ));
    });
  }
}

extension MessageEntityQueryObject
    on QueryBuilder<MessageEntity, MessageEntity, QFilterCondition> {}

extension MessageEntityQueryLinks
    on QueryBuilder<MessageEntity, MessageEntity, QFilterCondition> {}

extension MessageEntityQuerySortBy
    on QueryBuilder<MessageEntity, MessageEntity, QSortBy> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByAssistantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByAssistantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByCompletionTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionTokens', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByCompletionTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionTokens', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByFirstTokenMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstTokenMs', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByFirstTokenMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstTokenMs', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByPromptTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokens', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByPromptTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokens', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByReasoningContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningContent', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByReasoningContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningContent', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByReasoningDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByReasoningDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByReasoningTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningTokens', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByReasoningTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningTokens', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByRequestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByRequestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> sortByToolCallId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolCallId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByToolCallIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolCallId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByToolCallsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolCallsJson', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      sortByToolCallsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolCallsJson', Sort.desc);
    });
  }
}

extension MessageEntityQuerySortThenBy
    on QueryBuilder<MessageEntity, MessageEntity, QSortThenBy> {
  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByAssistantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByAssistantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assistantId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByCompletionTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionTokens', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByCompletionTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completionTokens', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByFirstTokenMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstTokenMs', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByFirstTokenMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstTokenMs', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'model', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByPromptTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokens', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByPromptTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokens', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByReasoningContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningContent', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByReasoningContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningContent', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByReasoningDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByReasoningDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByReasoningTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningTokens', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByReasoningTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasoningTokens', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByRequestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByRequestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenCount', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy> thenByToolCallId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolCallId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByToolCallIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolCallId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByToolCallsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolCallsJson', Sort.asc);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QAfterSortBy>
      thenByToolCallsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toolCallsJson', Sort.desc);
    });
  }
}

extension MessageEntityQueryWhereDistinct
    on QueryBuilder<MessageEntity, MessageEntity, QDistinct> {
  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByAssistantId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assistantId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct>
      distinctByAttachments() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attachments');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct>
      distinctByCompletionTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completionTokens');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMs');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct>
      distinctByFirstTokenMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstTokenMs');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByImages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'images');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUser');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByModel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'model', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct>
      distinctByPromptTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptTokens');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByProvider(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'provider', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct>
      distinctByReasoningContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reasoningContent',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct>
      distinctByReasoningDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reasoningDurationSeconds');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct>
      distinctByReasoningTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reasoningTokens');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByRequestId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requestId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByRole(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'role', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctBySessionId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tokenCount');
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByToolCallId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toolCallId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntity, MessageEntity, QDistinct> distinctByToolCallsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toolCallsJson',
          caseSensitive: caseSensitive);
    });
  }
}

extension MessageEntityQueryProperty
    on QueryBuilder<MessageEntity, MessageEntity, QQueryProperty> {
  QueryBuilder<MessageEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> assistantIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assistantId');
    });
  }

  QueryBuilder<MessageEntity, List<String>, QQueryOperations>
      attachmentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachments');
    });
  }

  QueryBuilder<MessageEntity, int?, QQueryOperations>
      completionTokensProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completionTokens');
    });
  }

  QueryBuilder<MessageEntity, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<MessageEntity, int?, QQueryOperations> durationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMs');
    });
  }

  QueryBuilder<MessageEntity, int?, QQueryOperations> firstTokenMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstTokenMs');
    });
  }

  QueryBuilder<MessageEntity, List<String>, QQueryOperations> imagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'images');
    });
  }

  QueryBuilder<MessageEntity, bool, QQueryOperations> isUserProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUser');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> modelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'model');
    });
  }

  QueryBuilder<MessageEntity, int?, QQueryOperations> promptTokensProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptTokens');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> providerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'provider');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations>
      reasoningContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reasoningContent');
    });
  }

  QueryBuilder<MessageEntity, double?, QQueryOperations>
      reasoningDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reasoningDurationSeconds');
    });
  }

  QueryBuilder<MessageEntity, int?, QQueryOperations>
      reasoningTokensProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reasoningTokens');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> requestIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requestId');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> roleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'role');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<MessageEntity, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<MessageEntity, int?, QQueryOperations> tokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tokenCount');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations> toolCallIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toolCallId');
    });
  }

  QueryBuilder<MessageEntity, String?, QQueryOperations>
      toolCallsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toolCallsJson');
    });
  }
}
