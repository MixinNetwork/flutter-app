// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_database.dart';

// ignore_for_file: type=lint
class AiChatMessages extends Table
    with TableInfo<AiChatMessages, AiChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AiChatMessages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _errorTextMeta = const VerificationMeta(
    'errorText',
  );
  late final GeneratedColumn<String> errorText = GeneratedColumn<String>(
    'error_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(AiChatMessages.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(AiChatMessages.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    threadId,
    conversationId,
    role,
    providerId,
    content,
    status,
    model,
    errorText,
    metadata,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiChatMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('error_text')) {
      context.handle(
        _errorTextMeta,
        errorText.isAcceptableOrUnknown(data['error_text']!, _errorTextMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiChatMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      errorText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_text'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: AiChatMessages.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: AiChatMessages.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  AiChatMessages createAlias(String alias) {
    return AiChatMessages(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(id)'];
  @override
  bool get dontWriteConstraints => true;
}

class AiChatMessage extends DataClass implements Insertable<AiChatMessage> {
  final String id;
  final String threadId;
  final String conversationId;
  final String role;
  final String providerId;
  final String content;
  final String status;
  final String? model;
  final String? errorText;
  final String? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AiChatMessage({
    required this.id,
    required this.threadId,
    required this.conversationId,
    required this.role,
    required this.providerId,
    required this.content,
    required this.status,
    this.model,
    this.errorText,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['thread_id'] = Variable<String>(threadId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['role'] = Variable<String>(role);
    map['provider_id'] = Variable<String>(providerId);
    map['content'] = Variable<String>(content);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || errorText != null) {
      map['error_text'] = Variable<String>(errorText);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    {
      map['created_at'] = Variable<int>(
        AiChatMessages.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        AiChatMessages.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  AiChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return AiChatMessagesCompanion(
      id: Value(id),
      threadId: Value(threadId),
      conversationId: Value(conversationId),
      role: Value(role),
      providerId: Value(providerId),
      content: Value(content),
      status: Value(status),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      errorText: errorText == null && nullToAbsent
          ? const Value.absent()
          : Value(errorText),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AiChatMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiChatMessage(
      id: serializer.fromJson<String>(json['id']),
      threadId: serializer.fromJson<String>(json['thread_id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      role: serializer.fromJson<String>(json['role']),
      providerId: serializer.fromJson<String>(json['provider_id']),
      content: serializer.fromJson<String>(json['content']),
      status: serializer.fromJson<String>(json['status']),
      model: serializer.fromJson<String?>(json['model']),
      errorText: serializer.fromJson<String?>(json['error_text']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'thread_id': serializer.toJson<String>(threadId),
      'conversation_id': serializer.toJson<String>(conversationId),
      'role': serializer.toJson<String>(role),
      'provider_id': serializer.toJson<String>(providerId),
      'content': serializer.toJson<String>(content),
      'status': serializer.toJson<String>(status),
      'model': serializer.toJson<String?>(model),
      'error_text': serializer.toJson<String?>(errorText),
      'metadata': serializer.toJson<String?>(metadata),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AiChatMessage copyWith({
    String? id,
    String? threadId,
    String? conversationId,
    String? role,
    String? providerId,
    String? content,
    String? status,
    Value<String?> model = const Value.absent(),
    Value<String?> errorText = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AiChatMessage(
    id: id ?? this.id,
    threadId: threadId ?? this.threadId,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    providerId: providerId ?? this.providerId,
    content: content ?? this.content,
    status: status ?? this.status,
    model: model.present ? model.value : this.model,
    errorText: errorText.present ? errorText.value : this.errorText,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AiChatMessage copyWithCompanion(AiChatMessagesCompanion data) {
    return AiChatMessage(
      id: data.id.present ? data.id.value : this.id,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      content: data.content.present ? data.content.value : this.content,
      status: data.status.present ? data.status.value : this.status,
      model: data.model.present ? data.model.value : this.model,
      errorText: data.errorText.present ? data.errorText.value : this.errorText,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiChatMessage(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('providerId: $providerId, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('model: $model, ')
          ..write('errorText: $errorText, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    threadId,
    conversationId,
    role,
    providerId,
    content,
    status,
    model,
    errorText,
    metadata,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiChatMessage &&
          other.id == this.id &&
          other.threadId == this.threadId &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.providerId == this.providerId &&
          other.content == this.content &&
          other.status == this.status &&
          other.model == this.model &&
          other.errorText == this.errorText &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AiChatMessagesCompanion extends UpdateCompanion<AiChatMessage> {
  final Value<String> id;
  final Value<String> threadId;
  final Value<String> conversationId;
  final Value<String> role;
  final Value<String> providerId;
  final Value<String> content;
  final Value<String> status;
  final Value<String?> model;
  final Value<String?> errorText;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AiChatMessagesCompanion({
    this.id = const Value.absent(),
    this.threadId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.providerId = const Value.absent(),
    this.content = const Value.absent(),
    this.status = const Value.absent(),
    this.model = const Value.absent(),
    this.errorText = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiChatMessagesCompanion.insert({
    required String id,
    this.threadId = const Value.absent(),
    required String conversationId,
    required String role,
    required String providerId,
    required String content,
    required String status,
    this.model = const Value.absent(),
    this.errorText = const Value.absent(),
    this.metadata = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       role = Value(role),
       providerId = Value(providerId),
       content = Value(content),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AiChatMessage> custom({
    Expression<String>? id,
    Expression<String>? threadId,
    Expression<String>? conversationId,
    Expression<String>? role,
    Expression<String>? providerId,
    Expression<String>? content,
    Expression<String>? status,
    Expression<String>? model,
    Expression<String>? errorText,
    Expression<String>? metadata,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (threadId != null) 'thread_id': threadId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (providerId != null) 'provider_id': providerId,
      if (content != null) 'content': content,
      if (status != null) 'status': status,
      if (model != null) 'model': model,
      if (errorText != null) 'error_text': errorText,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? threadId,
    Value<String>? conversationId,
    Value<String>? role,
    Value<String>? providerId,
    Value<String>? content,
    Value<String>? status,
    Value<String?>? model,
    Value<String?>? errorText,
    Value<String?>? metadata,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AiChatMessagesCompanion(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      providerId: providerId ?? this.providerId,
      content: content ?? this.content,
      status: status ?? this.status,
      model: model ?? this.model,
      errorText: errorText ?? this.errorText,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (errorText.present) {
      map['error_text'] = Variable<String>(errorText.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        AiChatMessages.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        AiChatMessages.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('providerId: $providerId, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('model: $model, ')
          ..write('errorText: $errorText, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AiChatThreads extends Table with TableInfo<AiChatThreads, AiChatThread> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AiChatThreads(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _messageCountMeta = const VerificationMeta(
    'messageCount',
  );
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
    'message_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'active\'',
    defaultValue: const CustomExpression('\'active\''),
  );
  late final GeneratedColumnWithTypeConverter<DateTime?, int> pinnedAt =
      GeneratedColumn<int>(
        'pinned_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: '',
      ).withConverter<DateTime?>(AiChatThreads.$converterpinnedAtn);
  late final GeneratedColumnWithTypeConverter<DateTime?, int> archivedAt =
      GeneratedColumn<int>(
        'archived_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: '',
      ).withConverter<DateTime?>(AiChatThreads.$converterarchivedAtn);
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastMessageAt =
      GeneratedColumn<int>(
        'last_message_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: '',
      ).withConverter<DateTime?>(AiChatThreads.$converterlastMessageAtn);
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(AiChatThreads.$convertercreatedAt);
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<DateTime>(AiChatThreads.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    title,
    summary,
    lastMessagePreview,
    messageCount,
    status,
    pinnedAt,
    archivedAt,
    lastMessageAt,
    metadata,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_chat_threads';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiChatThread> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    }
    if (data.containsKey('message_count')) {
      context.handle(
        _messageCountMeta,
        messageCount.isAcceptableOrUnknown(
          data['message_count']!,
          _messageCountMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiChatThread map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiChatThread(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      ),
      messageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      pinnedAt: AiChatThreads.$converterpinnedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pinned_at'],
        ),
      ),
      archivedAt: AiChatThreads.$converterarchivedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}archived_at'],
        ),
      ),
      lastMessageAt: AiChatThreads.$converterlastMessageAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_message_at'],
        ),
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: AiChatThreads.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: AiChatThreads.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  AiChatThreads createAlias(String alias) {
    return AiChatThreads(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterpinnedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $converterpinnedAtn =
      NullAwareTypeConverter.wrap($converterpinnedAt);
  static TypeConverter<DateTime, int> $converterarchivedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $converterarchivedAtn =
      NullAwareTypeConverter.wrap($converterarchivedAt);
  static TypeConverter<DateTime, int> $converterlastMessageAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $converterlastMessageAtn =
      NullAwareTypeConverter.wrap($converterlastMessageAt);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(id)'];
  @override
  bool get dontWriteConstraints => true;
}

class AiChatThread extends DataClass implements Insertable<AiChatThread> {
  final String id;
  final String conversationId;
  final String? title;
  final String? summary;
  final String? lastMessagePreview;
  final int messageCount;
  final String status;
  final DateTime? pinnedAt;
  final DateTime? archivedAt;
  final DateTime? lastMessageAt;
  final String? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AiChatThread({
    required this.id,
    required this.conversationId,
    this.title,
    this.summary,
    this.lastMessagePreview,
    required this.messageCount,
    required this.status,
    this.pinnedAt,
    this.archivedAt,
    this.lastMessageAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || lastMessagePreview != null) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview);
    }
    map['message_count'] = Variable<int>(messageCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<int>(
        AiChatThreads.$converterpinnedAtn.toSql(pinnedAt),
      );
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(
        AiChatThreads.$converterarchivedAtn.toSql(archivedAt),
      );
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<int>(
        AiChatThreads.$converterlastMessageAtn.toSql(lastMessageAt),
      );
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    {
      map['created_at'] = Variable<int>(
        AiChatThreads.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        AiChatThreads.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  AiChatThreadsCompanion toCompanion(bool nullToAbsent) {
    return AiChatThreadsCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      lastMessagePreview: lastMessagePreview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessagePreview),
      messageCount: Value(messageCount),
      status: Value(status),
      pinnedAt: pinnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AiChatThread.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiChatThread(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      title: serializer.fromJson<String?>(json['title']),
      summary: serializer.fromJson<String?>(json['summary']),
      lastMessagePreview: serializer.fromJson<String?>(
        json['last_message_preview'],
      ),
      messageCount: serializer.fromJson<int>(json['message_count']),
      status: serializer.fromJson<String>(json['status']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinned_at']),
      archivedAt: serializer.fromJson<DateTime?>(json['archived_at']),
      lastMessageAt: serializer.fromJson<DateTime?>(json['last_message_at']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversation_id': serializer.toJson<String>(conversationId),
      'title': serializer.toJson<String?>(title),
      'summary': serializer.toJson<String?>(summary),
      'last_message_preview': serializer.toJson<String?>(lastMessagePreview),
      'message_count': serializer.toJson<int>(messageCount),
      'status': serializer.toJson<String>(status),
      'pinned_at': serializer.toJson<DateTime?>(pinnedAt),
      'archived_at': serializer.toJson<DateTime?>(archivedAt),
      'last_message_at': serializer.toJson<DateTime?>(lastMessageAt),
      'metadata': serializer.toJson<String?>(metadata),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AiChatThread copyWith({
    String? id,
    String? conversationId,
    Value<String?> title = const Value.absent(),
    Value<String?> summary = const Value.absent(),
    Value<String?> lastMessagePreview = const Value.absent(),
    int? messageCount,
    String? status,
    Value<DateTime?> pinnedAt = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<DateTime?> lastMessageAt = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AiChatThread(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    title: title.present ? title.value : this.title,
    summary: summary.present ? summary.value : this.summary,
    lastMessagePreview: lastMessagePreview.present
        ? lastMessagePreview.value
        : this.lastMessagePreview,
    messageCount: messageCount ?? this.messageCount,
    status: status ?? this.status,
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AiChatThread copyWithCompanion(AiChatThreadsCompanion data) {
    return AiChatThread(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      status: data.status.present ? data.status.value : this.status,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiChatThread(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('messageCount: $messageCount, ')
          ..write('status: $status, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    title,
    summary,
    lastMessagePreview,
    messageCount,
    status,
    pinnedAt,
    archivedAt,
    lastMessageAt,
    metadata,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiChatThread &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.messageCount == this.messageCount &&
          other.status == this.status &&
          other.pinnedAt == this.pinnedAt &&
          other.archivedAt == this.archivedAt &&
          other.lastMessageAt == this.lastMessageAt &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AiChatThreadsCompanion extends UpdateCompanion<AiChatThread> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String?> title;
  final Value<String?> summary;
  final Value<String?> lastMessagePreview;
  final Value<int> messageCount;
  final Value<String> status;
  final Value<DateTime?> pinnedAt;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> lastMessageAt;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AiChatThreadsCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.status = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiChatThreadsCompanion.insert({
    required String id,
    required String conversationId,
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.status = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.metadata = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AiChatThread> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? lastMessagePreview,
    Expression<int>? messageCount,
    Expression<String>? status,
    Expression<int>? pinnedAt,
    Expression<int>? archivedAt,
    Expression<int>? lastMessageAt,
    Expression<String>? metadata,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (messageCount != null) 'message_count': messageCount,
      if (status != null) 'status': status,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiChatThreadsCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String?>? title,
    Value<String?>? summary,
    Value<String?>? lastMessagePreview,
    Value<int>? messageCount,
    Value<String>? status,
    Value<DateTime?>? pinnedAt,
    Value<DateTime?>? archivedAt,
    Value<DateTime?>? lastMessageAt,
    Value<String?>? metadata,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AiChatThreadsCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      messageCount: messageCount ?? this.messageCount,
      status: status ?? this.status,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<int>(
        AiChatThreads.$converterpinnedAtn.toSql(pinnedAt.value),
      );
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(
        AiChatThreads.$converterarchivedAtn.toSql(archivedAt.value),
      );
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<int>(
        AiChatThreads.$converterlastMessageAtn.toSql(lastMessageAt.value),
      );
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        AiChatThreads.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        AiChatThreads.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiChatThreadsCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('messageCount: $messageCount, ')
          ..write('status: $status, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AiDatabase extends GeneratedDatabase {
  _$AiDatabase(QueryExecutor e) : super(e);
  $AiDatabaseManager get managers => $AiDatabaseManager(this);
  late final AiChatMessages aiChatMessages = AiChatMessages(this);
  late final AiChatThreads aiChatThreads = AiChatThreads(this);
  late final Index indexAiChatMessagesConversationIdCreatedAt = Index(
    'index_ai_chat_messages_conversation_id_created_at',
    'CREATE INDEX IF NOT EXISTS index_ai_chat_messages_conversation_id_created_at ON ai_chat_messages (conversation_id, created_at DESC)',
  );
  late final Index indexAiChatMessagesThreadIdCreatedAt = Index(
    'index_ai_chat_messages_thread_id_created_at',
    'CREATE INDEX IF NOT EXISTS index_ai_chat_messages_thread_id_created_at ON ai_chat_messages (thread_id, created_at DESC)',
  );
  late final Index indexAiChatThreadsConversationIdUpdatedAt = Index(
    'index_ai_chat_threads_conversation_id_updated_at',
    'CREATE INDEX IF NOT EXISTS index_ai_chat_threads_conversation_id_updated_at ON ai_chat_threads (conversation_id, status, updated_at DESC)',
  );
  late final Index indexAiChatThreadsConversationIdLastMessageAt = Index(
    'index_ai_chat_threads_conversation_id_last_message_at',
    'CREATE INDEX IF NOT EXISTS index_ai_chat_threads_conversation_id_last_message_at ON ai_chat_threads (conversation_id, status, last_message_at DESC)',
  );
  late final AiChatMessageDao aiChatMessageDao = AiChatMessageDao(
    this as AiDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    aiChatMessages,
    aiChatThreads,
    indexAiChatMessagesConversationIdCreatedAt,
    indexAiChatMessagesThreadIdCreatedAt,
    indexAiChatThreadsConversationIdUpdatedAt,
    indexAiChatThreadsConversationIdLastMessageAt,
  ];
}

typedef $AiChatMessagesCreateCompanionBuilder =
    AiChatMessagesCompanion Function({
      required String id,
      Value<String> threadId,
      required String conversationId,
      required String role,
      required String providerId,
      required String content,
      required String status,
      Value<String?> model,
      Value<String?> errorText,
      Value<String?> metadata,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $AiChatMessagesUpdateCompanionBuilder =
    AiChatMessagesCompanion Function({
      Value<String> id,
      Value<String> threadId,
      Value<String> conversationId,
      Value<String> role,
      Value<String> providerId,
      Value<String> content,
      Value<String> status,
      Value<String?> model,
      Value<String?> errorText,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $AiChatMessagesFilterComposer
    extends Composer<_$AiDatabase, AiChatMessages> {
  $AiChatMessagesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorText => $composableBuilder(
    column: $table.errorText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $AiChatMessagesOrderingComposer
    extends Composer<_$AiDatabase, AiChatMessages> {
  $AiChatMessagesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorText => $composableBuilder(
    column: $table.errorText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AiChatMessagesAnnotationComposer
    extends Composer<_$AiDatabase, AiChatMessages> {
  $AiChatMessagesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get errorText =>
      $composableBuilder(column: $table.errorText, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $AiChatMessagesTableManager
    extends
        RootTableManager<
          _$AiDatabase,
          AiChatMessages,
          AiChatMessage,
          $AiChatMessagesFilterComposer,
          $AiChatMessagesOrderingComposer,
          $AiChatMessagesAnnotationComposer,
          $AiChatMessagesCreateCompanionBuilder,
          $AiChatMessagesUpdateCompanionBuilder,
          (
            AiChatMessage,
            BaseReferences<_$AiDatabase, AiChatMessages, AiChatMessage>,
          ),
          AiChatMessage,
          PrefetchHooks Function()
        > {
  $AiChatMessagesTableManager(_$AiDatabase db, AiChatMessages table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AiChatMessagesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AiChatMessagesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AiChatMessagesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> threadId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> errorText = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiChatMessagesCompanion(
                id: id,
                threadId: threadId,
                conversationId: conversationId,
                role: role,
                providerId: providerId,
                content: content,
                status: status,
                model: model,
                errorText: errorText,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> threadId = const Value.absent(),
                required String conversationId,
                required String role,
                required String providerId,
                required String content,
                required String status,
                Value<String?> model = const Value.absent(),
                Value<String?> errorText = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AiChatMessagesCompanion.insert(
                id: id,
                threadId: threadId,
                conversationId: conversationId,
                role: role,
                providerId: providerId,
                content: content,
                status: status,
                model: model,
                errorText: errorText,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AiChatMessagesProcessedTableManager =
    ProcessedTableManager<
      _$AiDatabase,
      AiChatMessages,
      AiChatMessage,
      $AiChatMessagesFilterComposer,
      $AiChatMessagesOrderingComposer,
      $AiChatMessagesAnnotationComposer,
      $AiChatMessagesCreateCompanionBuilder,
      $AiChatMessagesUpdateCompanionBuilder,
      (
        AiChatMessage,
        BaseReferences<_$AiDatabase, AiChatMessages, AiChatMessage>,
      ),
      AiChatMessage,
      PrefetchHooks Function()
    >;
typedef $AiChatThreadsCreateCompanionBuilder =
    AiChatThreadsCompanion Function({
      required String id,
      required String conversationId,
      Value<String?> title,
      Value<String?> summary,
      Value<String?> lastMessagePreview,
      Value<int> messageCount,
      Value<String> status,
      Value<DateTime?> pinnedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> lastMessageAt,
      Value<String?> metadata,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $AiChatThreadsUpdateCompanionBuilder =
    AiChatThreadsCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String?> title,
      Value<String?> summary,
      Value<String?> lastMessagePreview,
      Value<int> messageCount,
      Value<String> status,
      Value<DateTime?> pinnedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> lastMessageAt,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $AiChatThreadsFilterComposer
    extends Composer<_$AiDatabase, AiChatThreads> {
  $AiChatThreadsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get pinnedAt =>
      $composableBuilder(
        column: $table.pinnedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get archivedAt =>
      $composableBuilder(
        column: $table.archivedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastMessageAt =>
      $composableBuilder(
        column: $table.lastMessageAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $AiChatThreadsOrderingComposer
    extends Composer<_$AiDatabase, AiChatThreads> {
  $AiChatThreadsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AiChatThreadsAnnotationComposer
    extends Composer<_$AiDatabase, AiChatThreads> {
  $AiChatThreadsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get pinnedAt =>
      $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get archivedAt =>
      $composableBuilder(
        column: $table.archivedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastMessageAt =>
      $composableBuilder(
        column: $table.lastMessageAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $AiChatThreadsTableManager
    extends
        RootTableManager<
          _$AiDatabase,
          AiChatThreads,
          AiChatThread,
          $AiChatThreadsFilterComposer,
          $AiChatThreadsOrderingComposer,
          $AiChatThreadsAnnotationComposer,
          $AiChatThreadsCreateCompanionBuilder,
          $AiChatThreadsUpdateCompanionBuilder,
          (
            AiChatThread,
            BaseReferences<_$AiDatabase, AiChatThreads, AiChatThread>,
          ),
          AiChatThread,
          PrefetchHooks Function()
        > {
  $AiChatThreadsTableManager(_$AiDatabase db, AiChatThreads table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AiChatThreadsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AiChatThreadsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AiChatThreadsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiChatThreadsCompanion(
                id: id,
                conversationId: conversationId,
                title: title,
                summary: summary,
                lastMessagePreview: lastMessagePreview,
                messageCount: messageCount,
                status: status,
                pinnedAt: pinnedAt,
                archivedAt: archivedAt,
                lastMessageAt: lastMessageAt,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                Value<String?> title = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> pinnedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AiChatThreadsCompanion.insert(
                id: id,
                conversationId: conversationId,
                title: title,
                summary: summary,
                lastMessagePreview: lastMessagePreview,
                messageCount: messageCount,
                status: status,
                pinnedAt: pinnedAt,
                archivedAt: archivedAt,
                lastMessageAt: lastMessageAt,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AiChatThreadsProcessedTableManager =
    ProcessedTableManager<
      _$AiDatabase,
      AiChatThreads,
      AiChatThread,
      $AiChatThreadsFilterComposer,
      $AiChatThreadsOrderingComposer,
      $AiChatThreadsAnnotationComposer,
      $AiChatThreadsCreateCompanionBuilder,
      $AiChatThreadsUpdateCompanionBuilder,
      (AiChatThread, BaseReferences<_$AiDatabase, AiChatThreads, AiChatThread>),
      AiChatThread,
      PrefetchHooks Function()
    >;

class $AiDatabaseManager {
  final _$AiDatabase _db;
  $AiDatabaseManager(this._db);
  $AiChatMessagesTableManager get aiChatMessages =>
      $AiChatMessagesTableManager(_db, _db.aiChatMessages);
  $AiChatThreadsTableManager get aiChatThreads =>
      $AiChatThreadsTableManager(_db, _db.aiChatThreads);
}
