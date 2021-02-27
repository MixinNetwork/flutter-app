// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixin_database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Job extends DataClass implements Insertable<Job> {
  final String jobId;
  final String action;
  final DateTime createdAt;
  final int? orderId;
  final int priority;
  final String? userId;
  final String? blazeMessage;
  final String? conversationId;
  final String? resendMessageId;
  final int runCount;
  Job(
      {required this.jobId,
      required this.action,
      required this.createdAt,
      this.orderId,
      required this.priority,
      this.userId,
      this.blazeMessage,
      this.conversationId,
      this.resendMessageId,
      required this.runCount});
  factory Job.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Job(
      jobId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}job_id'])!,
      action:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}action'])!,
      createdAt: Jobs.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
      orderId:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}order_id']),
      priority:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}priority'])!,
      userId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}user_id']),
      blazeMessage: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}blaze_message']),
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id']),
      resendMessageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}resend_message_id']),
      runCount:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}run_count'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['job_id'] = Variable<String>(jobId);
    map['action'] = Variable<String>(action);
    {
      final converter = Jobs.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<int?>(orderId);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String?>(userId);
    }
    if (!nullToAbsent || blazeMessage != null) {
      map['blaze_message'] = Variable<String?>(blazeMessage);
    }
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String?>(conversationId);
    }
    if (!nullToAbsent || resendMessageId != null) {
      map['resend_message_id'] = Variable<String?>(resendMessageId);
    }
    map['run_count'] = Variable<int>(runCount);
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      jobId: Value(jobId),
      action: Value(action),
      createdAt: Value(createdAt),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      priority: Value(priority),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      blazeMessage: blazeMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(blazeMessage),
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      resendMessageId: resendMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(resendMessageId),
      runCount: Value(runCount),
    );
  }

  factory Job.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Job(
      jobId: serializer.fromJson<String>(json['job_id']),
      action: serializer.fromJson<String>(json['action']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      orderId: serializer.fromJson<int?>(json['order_id']),
      priority: serializer.fromJson<int>(json['priority']),
      userId: serializer.fromJson<String?>(json['user_id']),
      blazeMessage: serializer.fromJson<String?>(json['blaze_message']),
      conversationId: serializer.fromJson<String?>(json['conversation_id']),
      resendMessageId: serializer.fromJson<String?>(json['resend_message_id']),
      runCount: serializer.fromJson<int>(json['run_count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'job_id': serializer.toJson<String>(jobId),
      'action': serializer.toJson<String>(action),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'order_id': serializer.toJson<int?>(orderId),
      'priority': serializer.toJson<int>(priority),
      'user_id': serializer.toJson<String?>(userId),
      'blaze_message': serializer.toJson<String?>(blazeMessage),
      'conversation_id': serializer.toJson<String?>(conversationId),
      'resend_message_id': serializer.toJson<String?>(resendMessageId),
      'run_count': serializer.toJson<int>(runCount),
    };
  }

  Job copyWith(
          {String? jobId,
          String? action,
          DateTime? createdAt,
          int? orderId,
          int? priority,
          String? userId,
          String? blazeMessage,
          String? conversationId,
          String? resendMessageId,
          int? runCount}) =>
      Job(
        jobId: jobId ?? this.jobId,
        action: action ?? this.action,
        createdAt: createdAt ?? this.createdAt,
        orderId: orderId ?? this.orderId,
        priority: priority ?? this.priority,
        userId: userId ?? this.userId,
        blazeMessage: blazeMessage ?? this.blazeMessage,
        conversationId: conversationId ?? this.conversationId,
        resendMessageId: resendMessageId ?? this.resendMessageId,
        runCount: runCount ?? this.runCount,
      );
  @override
  String toString() {
    return (StringBuffer('Job(')
          ..write('jobId: $jobId, ')
          ..write('action: $action, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderId: $orderId, ')
          ..write('priority: $priority, ')
          ..write('userId: $userId, ')
          ..write('blazeMessage: $blazeMessage, ')
          ..write('conversationId: $conversationId, ')
          ..write('resendMessageId: $resendMessageId, ')
          ..write('runCount: $runCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      jobId.hashCode,
      $mrjc(
          action.hashCode,
          $mrjc(
              createdAt.hashCode,
              $mrjc(
                  orderId.hashCode,
                  $mrjc(
                      priority.hashCode,
                      $mrjc(
                          userId.hashCode,
                          $mrjc(
                              blazeMessage.hashCode,
                              $mrjc(
                                  conversationId.hashCode,
                                  $mrjc(resendMessageId.hashCode,
                                      runCount.hashCode))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Job &&
          other.jobId == this.jobId &&
          other.action == this.action &&
          other.createdAt == this.createdAt &&
          other.orderId == this.orderId &&
          other.priority == this.priority &&
          other.userId == this.userId &&
          other.blazeMessage == this.blazeMessage &&
          other.conversationId == this.conversationId &&
          other.resendMessageId == this.resendMessageId &&
          other.runCount == this.runCount);
}

class JobsCompanion extends UpdateCompanion<Job> {
  final Value<String> jobId;
  final Value<String> action;
  final Value<DateTime> createdAt;
  final Value<int?> orderId;
  final Value<int> priority;
  final Value<String?> userId;
  final Value<String?> blazeMessage;
  final Value<String?> conversationId;
  final Value<String?> resendMessageId;
  final Value<int> runCount;
  const JobsCompanion({
    this.jobId = const Value.absent(),
    this.action = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.orderId = const Value.absent(),
    this.priority = const Value.absent(),
    this.userId = const Value.absent(),
    this.blazeMessage = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.resendMessageId = const Value.absent(),
    this.runCount = const Value.absent(),
  });
  JobsCompanion.insert({
    required String jobId,
    required String action,
    required DateTime createdAt,
    this.orderId = const Value.absent(),
    required int priority,
    this.userId = const Value.absent(),
    this.blazeMessage = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.resendMessageId = const Value.absent(),
    required int runCount,
  })   : jobId = Value(jobId),
        action = Value(action),
        createdAt = Value(createdAt),
        priority = Value(priority),
        runCount = Value(runCount);
  static Insertable<Job> custom({
    Expression<String>? jobId,
    Expression<String>? action,
    Expression<DateTime>? createdAt,
    Expression<int?>? orderId,
    Expression<int>? priority,
    Expression<String?>? userId,
    Expression<String?>? blazeMessage,
    Expression<String?>? conversationId,
    Expression<String?>? resendMessageId,
    Expression<int>? runCount,
  }) {
    return RawValuesInsertable({
      if (jobId != null) 'job_id': jobId,
      if (action != null) 'action': action,
      if (createdAt != null) 'created_at': createdAt,
      if (orderId != null) 'order_id': orderId,
      if (priority != null) 'priority': priority,
      if (userId != null) 'user_id': userId,
      if (blazeMessage != null) 'blaze_message': blazeMessage,
      if (conversationId != null) 'conversation_id': conversationId,
      if (resendMessageId != null) 'resend_message_id': resendMessageId,
      if (runCount != null) 'run_count': runCount,
    });
  }

  JobsCompanion copyWith(
      {Value<String>? jobId,
      Value<String>? action,
      Value<DateTime>? createdAt,
      Value<int?>? orderId,
      Value<int>? priority,
      Value<String?>? userId,
      Value<String?>? blazeMessage,
      Value<String?>? conversationId,
      Value<String?>? resendMessageId,
      Value<int>? runCount}) {
    return JobsCompanion(
      jobId: jobId ?? this.jobId,
      action: action ?? this.action,
      createdAt: createdAt ?? this.createdAt,
      orderId: orderId ?? this.orderId,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      blazeMessage: blazeMessage ?? this.blazeMessage,
      conversationId: conversationId ?? this.conversationId,
      resendMessageId: resendMessageId ?? this.resendMessageId,
      runCount: runCount ?? this.runCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (createdAt.present) {
      final converter = Jobs.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int?>(orderId.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String?>(userId.value);
    }
    if (blazeMessage.present) {
      map['blaze_message'] = Variable<String?>(blazeMessage.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String?>(conversationId.value);
    }
    if (resendMessageId.present) {
      map['resend_message_id'] = Variable<String?>(resendMessageId.value);
    }
    if (runCount.present) {
      map['run_count'] = Variable<int>(runCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('jobId: $jobId, ')
          ..write('action: $action, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderId: $orderId, ')
          ..write('priority: $priority, ')
          ..write('userId: $userId, ')
          ..write('blazeMessage: $blazeMessage, ')
          ..write('conversationId: $conversationId, ')
          ..write('resendMessageId: $resendMessageId, ')
          ..write('runCount: $runCount')
          ..write(')'))
        .toString();
  }
}

class Jobs extends Table with TableInfo<Jobs, Job> {
  final GeneratedDatabase _db;
  final String? _alias;
  Jobs(this._db, [this._alias]);
  final VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  late final GeneratedTextColumn jobId = _constructJobId();
  GeneratedTextColumn _constructJobId() {
    return GeneratedTextColumn('job_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _actionMeta = const VerificationMeta('action');
  late final GeneratedTextColumn action = _constructAction();
  GeneratedTextColumn _constructAction() {
    return GeneratedTextColumn('action', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _orderIdMeta = const VerificationMeta('orderId');
  late final GeneratedIntColumn orderId = _constructOrderId();
  GeneratedIntColumn _constructOrderId() {
    return GeneratedIntColumn('order_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _priorityMeta = const VerificationMeta('priority');
  late final GeneratedIntColumn priority = _constructPriority();
  GeneratedIntColumn _constructPriority() {
    return GeneratedIntColumn('priority', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _blazeMessageMeta =
      const VerificationMeta('blazeMessage');
  late final GeneratedTextColumn blazeMessage = _constructBlazeMessage();
  GeneratedTextColumn _constructBlazeMessage() {
    return GeneratedTextColumn('blaze_message', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedTextColumn conversationId = _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _resendMessageIdMeta =
      const VerificationMeta('resendMessageId');
  late final GeneratedTextColumn resendMessageId = _constructResendMessageId();
  GeneratedTextColumn _constructResendMessageId() {
    return GeneratedTextColumn('resend_message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _runCountMeta = const VerificationMeta('runCount');
  late final GeneratedIntColumn runCount = _constructRunCount();
  GeneratedIntColumn _constructRunCount() {
    return GeneratedIntColumn('run_count', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [
        jobId,
        action,
        createdAt,
        orderId,
        priority,
        userId,
        blazeMessage,
        conversationId,
        resendMessageId,
        runCount
      ];
  @override
  Jobs get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'jobs';
  @override
  final String actualTableName = 'jobs';
  @override
  VerificationContext validateIntegrity(Insertable<Job> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('blaze_message')) {
      context.handle(
          _blazeMessageMeta,
          blazeMessage.isAcceptableOrUnknown(
              data['blaze_message']!, _blazeMessageMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    }
    if (data.containsKey('resend_message_id')) {
      context.handle(
          _resendMessageIdMeta,
          resendMessageId.isAcceptableOrUnknown(
              data['resend_message_id']!, _resendMessageIdMeta));
    }
    if (data.containsKey('run_count')) {
      context.handle(_runCountMeta,
          runCount.isAcceptableOrUnknown(data['run_count']!, _runCountMeta));
    } else if (isInserting) {
      context.missing(_runCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {jobId};
  @override
  Job map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Job.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Jobs createAlias(String alias) {
    return Jobs(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(job_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String conversationId;
  final String? ownerId;
  final ConversationCategory? category;
  final String? name;
  final String? iconUrl;
  final String? announcement;
  final String? codeUrl;
  final String? payType;
  final DateTime createdAt;
  final DateTime? pinTime;
  final String? lastMessageId;
  final DateTime? lastMessageCreatedAt;
  final String? lastReadMessageId;
  final int? unseenMessageCount;
  final ConversationStatus status;
  final String? draft;
  final DateTime? muteUntil;
  Conversation(
      {required this.conversationId,
      this.ownerId,
      this.category,
      this.name,
      this.iconUrl,
      this.announcement,
      this.codeUrl,
      this.payType,
      required this.createdAt,
      this.pinTime,
      this.lastMessageId,
      this.lastMessageCreatedAt,
      this.lastReadMessageId,
      this.unseenMessageCount,
      required this.status,
      this.draft,
      this.muteUntil});
  factory Conversation.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Conversation(
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id'])!,
      ownerId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}owner_id']),
      category: Conversations.$converter0.mapToDart(stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}category'])),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name']),
      iconUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}icon_url']),
      announcement: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}announcement']),
      codeUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}code_url']),
      payType: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}pay_type']),
      createdAt: Conversations.$converter1.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
      pinTime: Conversations.$converter2.mapToDart(
          intType.mapFromDatabaseResponse(data['${effectivePrefix}pin_time'])),
      lastMessageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}last_message_id']),
      lastMessageCreatedAt: Conversations.$converter3.mapToDart(
          intType.mapFromDatabaseResponse(
              data['${effectivePrefix}last_message_created_at'])),
      lastReadMessageId: stringType.mapFromDatabaseResponse(
          data['${effectivePrefix}last_read_message_id']),
      unseenMessageCount: intType.mapFromDatabaseResponse(
          data['${effectivePrefix}unseen_message_count']),
      status: Conversations.$converter4.mapToDart(
          intType.mapFromDatabaseResponse(data['${effectivePrefix}status']))!,
      draft:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}draft']),
      muteUntil: Conversations.$converter5.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}mute_until'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String?>(ownerId);
    }
    if (!nullToAbsent || category != null) {
      final converter = Conversations.$converter0;
      map['category'] = Variable<String?>(converter.mapToSql(category));
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String?>(name);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String?>(iconUrl);
    }
    if (!nullToAbsent || announcement != null) {
      map['announcement'] = Variable<String?>(announcement);
    }
    if (!nullToAbsent || codeUrl != null) {
      map['code_url'] = Variable<String?>(codeUrl);
    }
    if (!nullToAbsent || payType != null) {
      map['pay_type'] = Variable<String?>(payType);
    }
    {
      final converter = Conversations.$converter1;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    if (!nullToAbsent || pinTime != null) {
      final converter = Conversations.$converter2;
      map['pin_time'] = Variable<int?>(converter.mapToSql(pinTime));
    }
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String?>(lastMessageId);
    }
    if (!nullToAbsent || lastMessageCreatedAt != null) {
      final converter = Conversations.$converter3;
      map['last_message_created_at'] =
          Variable<int?>(converter.mapToSql(lastMessageCreatedAt));
    }
    if (!nullToAbsent || lastReadMessageId != null) {
      map['last_read_message_id'] = Variable<String?>(lastReadMessageId);
    }
    if (!nullToAbsent || unseenMessageCount != null) {
      map['unseen_message_count'] = Variable<int?>(unseenMessageCount);
    }
    {
      final converter = Conversations.$converter4;
      map['status'] = Variable<int>(converter.mapToSql(status)!);
    }
    if (!nullToAbsent || draft != null) {
      map['draft'] = Variable<String?>(draft);
    }
    if (!nullToAbsent || muteUntil != null) {
      final converter = Conversations.$converter5;
      map['mute_until'] = Variable<int?>(converter.mapToSql(muteUntil));
    }
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      conversationId: Value(conversationId),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
      announcement: announcement == null && nullToAbsent
          ? const Value.absent()
          : Value(announcement),
      codeUrl: codeUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(codeUrl),
      payType: payType == null && nullToAbsent
          ? const Value.absent()
          : Value(payType),
      createdAt: Value(createdAt),
      pinTime: pinTime == null && nullToAbsent
          ? const Value.absent()
          : Value(pinTime),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      lastMessageCreatedAt: lastMessageCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageCreatedAt),
      lastReadMessageId: lastReadMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadMessageId),
      unseenMessageCount: unseenMessageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(unseenMessageCount),
      status: Value(status),
      draft:
          draft == null && nullToAbsent ? const Value.absent() : Value(draft),
      muteUntil: muteUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(muteUntil),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Conversation(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      ownerId: serializer.fromJson<String?>(json['owner_id']),
      category: serializer.fromJson<ConversationCategory?>(json['category']),
      name: serializer.fromJson<String?>(json['name']),
      iconUrl: serializer.fromJson<String?>(json['icon_url']),
      announcement: serializer.fromJson<String?>(json['announcement']),
      codeUrl: serializer.fromJson<String?>(json['code_url']),
      payType: serializer.fromJson<String?>(json['pay_type']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      pinTime: serializer.fromJson<DateTime?>(json['pin_time']),
      lastMessageId: serializer.fromJson<String?>(json['last_message_id']),
      lastMessageCreatedAt:
          serializer.fromJson<DateTime?>(json['last_message_created_at']),
      lastReadMessageId:
          serializer.fromJson<String?>(json['last_read_message_id']),
      unseenMessageCount:
          serializer.fromJson<int?>(json['unseen_message_count']),
      status: serializer.fromJson<ConversationStatus>(json['status']),
      draft: serializer.fromJson<String?>(json['draft']),
      muteUntil: serializer.fromJson<DateTime?>(json['mute_until']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversation_id': serializer.toJson<String>(conversationId),
      'owner_id': serializer.toJson<String?>(ownerId),
      'category': serializer.toJson<ConversationCategory?>(category),
      'name': serializer.toJson<String?>(name),
      'icon_url': serializer.toJson<String?>(iconUrl),
      'announcement': serializer.toJson<String?>(announcement),
      'code_url': serializer.toJson<String?>(codeUrl),
      'pay_type': serializer.toJson<String?>(payType),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'pin_time': serializer.toJson<DateTime?>(pinTime),
      'last_message_id': serializer.toJson<String?>(lastMessageId),
      'last_message_created_at':
          serializer.toJson<DateTime?>(lastMessageCreatedAt),
      'last_read_message_id': serializer.toJson<String?>(lastReadMessageId),
      'unseen_message_count': serializer.toJson<int?>(unseenMessageCount),
      'status': serializer.toJson<ConversationStatus>(status),
      'draft': serializer.toJson<String?>(draft),
      'mute_until': serializer.toJson<DateTime?>(muteUntil),
    };
  }

  Conversation copyWith(
          {String? conversationId,
          String? ownerId,
          ConversationCategory? category,
          String? name,
          String? iconUrl,
          String? announcement,
          String? codeUrl,
          String? payType,
          DateTime? createdAt,
          DateTime? pinTime,
          String? lastMessageId,
          DateTime? lastMessageCreatedAt,
          String? lastReadMessageId,
          int? unseenMessageCount,
          ConversationStatus? status,
          String? draft,
          DateTime? muteUntil}) =>
      Conversation(
        conversationId: conversationId ?? this.conversationId,
        ownerId: ownerId ?? this.ownerId,
        category: category ?? this.category,
        name: name ?? this.name,
        iconUrl: iconUrl ?? this.iconUrl,
        announcement: announcement ?? this.announcement,
        codeUrl: codeUrl ?? this.codeUrl,
        payType: payType ?? this.payType,
        createdAt: createdAt ?? this.createdAt,
        pinTime: pinTime ?? this.pinTime,
        lastMessageId: lastMessageId ?? this.lastMessageId,
        lastMessageCreatedAt: lastMessageCreatedAt ?? this.lastMessageCreatedAt,
        lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
        unseenMessageCount: unseenMessageCount ?? this.unseenMessageCount,
        status: status ?? this.status,
        draft: draft ?? this.draft,
        muteUntil: muteUntil ?? this.muteUntil,
      );
  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('conversationId: $conversationId, ')
          ..write('ownerId: $ownerId, ')
          ..write('category: $category, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('announcement: $announcement, ')
          ..write('codeUrl: $codeUrl, ')
          ..write('payType: $payType, ')
          ..write('createdAt: $createdAt, ')
          ..write('pinTime: $pinTime, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageCreatedAt: $lastMessageCreatedAt, ')
          ..write('lastReadMessageId: $lastReadMessageId, ')
          ..write('unseenMessageCount: $unseenMessageCount, ')
          ..write('status: $status, ')
          ..write('draft: $draft, ')
          ..write('muteUntil: $muteUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      conversationId.hashCode,
      $mrjc(
          ownerId.hashCode,
          $mrjc(
              category.hashCode,
              $mrjc(
                  name.hashCode,
                  $mrjc(
                      iconUrl.hashCode,
                      $mrjc(
                          announcement.hashCode,
                          $mrjc(
                              codeUrl.hashCode,
                              $mrjc(
                                  payType.hashCode,
                                  $mrjc(
                                      createdAt.hashCode,
                                      $mrjc(
                                          pinTime.hashCode,
                                          $mrjc(
                                              lastMessageId.hashCode,
                                              $mrjc(
                                                  lastMessageCreatedAt.hashCode,
                                                  $mrjc(
                                                      lastReadMessageId
                                                          .hashCode,
                                                      $mrjc(
                                                          unseenMessageCount
                                                              .hashCode,
                                                          $mrjc(
                                                              status.hashCode,
                                                              $mrjc(
                                                                  draft
                                                                      .hashCode,
                                                                  muteUntil
                                                                      .hashCode)))))))))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.conversationId == this.conversationId &&
          other.ownerId == this.ownerId &&
          other.category == this.category &&
          other.name == this.name &&
          other.iconUrl == this.iconUrl &&
          other.announcement == this.announcement &&
          other.codeUrl == this.codeUrl &&
          other.payType == this.payType &&
          other.createdAt == this.createdAt &&
          other.pinTime == this.pinTime &&
          other.lastMessageId == this.lastMessageId &&
          other.lastMessageCreatedAt == this.lastMessageCreatedAt &&
          other.lastReadMessageId == this.lastReadMessageId &&
          other.unseenMessageCount == this.unseenMessageCount &&
          other.status == this.status &&
          other.draft == this.draft &&
          other.muteUntil == this.muteUntil);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> conversationId;
  final Value<String?> ownerId;
  final Value<ConversationCategory?> category;
  final Value<String?> name;
  final Value<String?> iconUrl;
  final Value<String?> announcement;
  final Value<String?> codeUrl;
  final Value<String?> payType;
  final Value<DateTime> createdAt;
  final Value<DateTime?> pinTime;
  final Value<String?> lastMessageId;
  final Value<DateTime?> lastMessageCreatedAt;
  final Value<String?> lastReadMessageId;
  final Value<int?> unseenMessageCount;
  final Value<ConversationStatus> status;
  final Value<String?> draft;
  final Value<DateTime?> muteUntil;
  const ConversationsCompanion({
    this.conversationId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.category = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.announcement = const Value.absent(),
    this.codeUrl = const Value.absent(),
    this.payType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pinTime = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessageCreatedAt = const Value.absent(),
    this.lastReadMessageId = const Value.absent(),
    this.unseenMessageCount = const Value.absent(),
    this.status = const Value.absent(),
    this.draft = const Value.absent(),
    this.muteUntil = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String conversationId,
    this.ownerId = const Value.absent(),
    this.category = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.announcement = const Value.absent(),
    this.codeUrl = const Value.absent(),
    this.payType = const Value.absent(),
    required DateTime createdAt,
    this.pinTime = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessageCreatedAt = const Value.absent(),
    this.lastReadMessageId = const Value.absent(),
    this.unseenMessageCount = const Value.absent(),
    required ConversationStatus status,
    this.draft = const Value.absent(),
    this.muteUntil = const Value.absent(),
  })  : conversationId = Value(conversationId),
        createdAt = Value(createdAt),
        status = Value(status);
  static Insertable<Conversation> custom({
    Expression<String>? conversationId,
    Expression<String?>? ownerId,
    Expression<ConversationCategory?>? category,
    Expression<String?>? name,
    Expression<String?>? iconUrl,
    Expression<String?>? announcement,
    Expression<String?>? codeUrl,
    Expression<String?>? payType,
    Expression<DateTime>? createdAt,
    Expression<DateTime?>? pinTime,
    Expression<String?>? lastMessageId,
    Expression<DateTime?>? lastMessageCreatedAt,
    Expression<String?>? lastReadMessageId,
    Expression<int?>? unseenMessageCount,
    Expression<ConversationStatus>? status,
    Expression<String?>? draft,
    Expression<DateTime?>? muteUntil,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (ownerId != null) 'owner_id': ownerId,
      if (category != null) 'category': category,
      if (name != null) 'name': name,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (announcement != null) 'announcement': announcement,
      if (codeUrl != null) 'code_url': codeUrl,
      if (payType != null) 'pay_type': payType,
      if (createdAt != null) 'created_at': createdAt,
      if (pinTime != null) 'pin_time': pinTime,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (lastMessageCreatedAt != null)
        'last_message_created_at': lastMessageCreatedAt,
      if (lastReadMessageId != null) 'last_read_message_id': lastReadMessageId,
      if (unseenMessageCount != null)
        'unseen_message_count': unseenMessageCount,
      if (status != null) 'status': status,
      if (draft != null) 'draft': draft,
      if (muteUntil != null) 'mute_until': muteUntil,
    });
  }

  ConversationsCompanion copyWith(
      {Value<String>? conversationId,
      Value<String?>? ownerId,
      Value<ConversationCategory?>? category,
      Value<String?>? name,
      Value<String?>? iconUrl,
      Value<String?>? announcement,
      Value<String?>? codeUrl,
      Value<String?>? payType,
      Value<DateTime>? createdAt,
      Value<DateTime?>? pinTime,
      Value<String?>? lastMessageId,
      Value<DateTime?>? lastMessageCreatedAt,
      Value<String?>? lastReadMessageId,
      Value<int?>? unseenMessageCount,
      Value<ConversationStatus>? status,
      Value<String?>? draft,
      Value<DateTime?>? muteUntil}) {
    return ConversationsCompanion(
      conversationId: conversationId ?? this.conversationId,
      ownerId: ownerId ?? this.ownerId,
      category: category ?? this.category,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      announcement: announcement ?? this.announcement,
      codeUrl: codeUrl ?? this.codeUrl,
      payType: payType ?? this.payType,
      createdAt: createdAt ?? this.createdAt,
      pinTime: pinTime ?? this.pinTime,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageCreatedAt: lastMessageCreatedAt ?? this.lastMessageCreatedAt,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      unseenMessageCount: unseenMessageCount ?? this.unseenMessageCount,
      status: status ?? this.status,
      draft: draft ?? this.draft,
      muteUntil: muteUntil ?? this.muteUntil,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String?>(ownerId.value);
    }
    if (category.present) {
      final converter = Conversations.$converter0;
      map['category'] = Variable<String?>(converter.mapToSql(category.value));
    }
    if (name.present) {
      map['name'] = Variable<String?>(name.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String?>(iconUrl.value);
    }
    if (announcement.present) {
      map['announcement'] = Variable<String?>(announcement.value);
    }
    if (codeUrl.present) {
      map['code_url'] = Variable<String?>(codeUrl.value);
    }
    if (payType.present) {
      map['pay_type'] = Variable<String?>(payType.value);
    }
    if (createdAt.present) {
      final converter = Conversations.$converter1;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    if (pinTime.present) {
      final converter = Conversations.$converter2;
      map['pin_time'] = Variable<int?>(converter.mapToSql(pinTime.value));
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String?>(lastMessageId.value);
    }
    if (lastMessageCreatedAt.present) {
      final converter = Conversations.$converter3;
      map['last_message_created_at'] =
          Variable<int?>(converter.mapToSql(lastMessageCreatedAt.value));
    }
    if (lastReadMessageId.present) {
      map['last_read_message_id'] = Variable<String?>(lastReadMessageId.value);
    }
    if (unseenMessageCount.present) {
      map['unseen_message_count'] = Variable<int?>(unseenMessageCount.value);
    }
    if (status.present) {
      final converter = Conversations.$converter4;
      map['status'] = Variable<int>(converter.mapToSql(status.value)!);
    }
    if (draft.present) {
      map['draft'] = Variable<String?>(draft.value);
    }
    if (muteUntil.present) {
      final converter = Conversations.$converter5;
      map['mute_until'] = Variable<int?>(converter.mapToSql(muteUntil.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('ownerId: $ownerId, ')
          ..write('category: $category, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('announcement: $announcement, ')
          ..write('codeUrl: $codeUrl, ')
          ..write('payType: $payType, ')
          ..write('createdAt: $createdAt, ')
          ..write('pinTime: $pinTime, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageCreatedAt: $lastMessageCreatedAt, ')
          ..write('lastReadMessageId: $lastReadMessageId, ')
          ..write('unseenMessageCount: $unseenMessageCount, ')
          ..write('status: $status, ')
          ..write('draft: $draft, ')
          ..write('muteUntil: $muteUntil')
          ..write(')'))
        .toString();
  }
}

class Conversations extends Table with TableInfo<Conversations, Conversation> {
  final GeneratedDatabase _db;
  final String? _alias;
  Conversations(this._db, [this._alias]);
  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedTextColumn conversationId = _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _ownerIdMeta = const VerificationMeta('ownerId');
  late final GeneratedTextColumn ownerId = _constructOwnerId();
  GeneratedTextColumn _constructOwnerId() {
    return GeneratedTextColumn('owner_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  late final GeneratedTextColumn category = _constructCategory();
  GeneratedTextColumn _constructCategory() {
    return GeneratedTextColumn('category', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _iconUrlMeta = const VerificationMeta('iconUrl');
  late final GeneratedTextColumn iconUrl = _constructIconUrl();
  GeneratedTextColumn _constructIconUrl() {
    return GeneratedTextColumn('icon_url', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _announcementMeta =
      const VerificationMeta('announcement');
  late final GeneratedTextColumn announcement = _constructAnnouncement();
  GeneratedTextColumn _constructAnnouncement() {
    return GeneratedTextColumn('announcement', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _codeUrlMeta = const VerificationMeta('codeUrl');
  late final GeneratedTextColumn codeUrl = _constructCodeUrl();
  GeneratedTextColumn _constructCodeUrl() {
    return GeneratedTextColumn('code_url', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _payTypeMeta = const VerificationMeta('payType');
  late final GeneratedTextColumn payType = _constructPayType();
  GeneratedTextColumn _constructPayType() {
    return GeneratedTextColumn('pay_type', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _pinTimeMeta = const VerificationMeta('pinTime');
  late final GeneratedIntColumn pinTime = _constructPinTime();
  GeneratedIntColumn _constructPinTime() {
    return GeneratedIntColumn('pin_time', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _lastMessageIdMeta =
      const VerificationMeta('lastMessageId');
  late final GeneratedTextColumn lastMessageId = _constructLastMessageId();
  GeneratedTextColumn _constructLastMessageId() {
    return GeneratedTextColumn('last_message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _lastMessageCreatedAtMeta =
      const VerificationMeta('lastMessageCreatedAt');
  late final GeneratedIntColumn lastMessageCreatedAt =
      _constructLastMessageCreatedAt();
  GeneratedIntColumn _constructLastMessageCreatedAt() {
    return GeneratedIntColumn('last_message_created_at', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _lastReadMessageIdMeta =
      const VerificationMeta('lastReadMessageId');
  late final GeneratedTextColumn lastReadMessageId =
      _constructLastReadMessageId();
  GeneratedTextColumn _constructLastReadMessageId() {
    return GeneratedTextColumn('last_read_message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _unseenMessageCountMeta =
      const VerificationMeta('unseenMessageCount');
  late final GeneratedIntColumn unseenMessageCount =
      _constructUnseenMessageCount();
  GeneratedIntColumn _constructUnseenMessageCount() {
    return GeneratedIntColumn('unseen_message_count', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedIntColumn status = _constructStatus();
  GeneratedIntColumn _constructStatus() {
    return GeneratedIntColumn('status', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _draftMeta = const VerificationMeta('draft');
  late final GeneratedTextColumn draft = _constructDraft();
  GeneratedTextColumn _constructDraft() {
    return GeneratedTextColumn('draft', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _muteUntilMeta = const VerificationMeta('muteUntil');
  late final GeneratedIntColumn muteUntil = _constructMuteUntil();
  GeneratedIntColumn _constructMuteUntil() {
    return GeneratedIntColumn('mute_until', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [
        conversationId,
        ownerId,
        category,
        name,
        iconUrl,
        announcement,
        codeUrl,
        payType,
        createdAt,
        pinTime,
        lastMessageId,
        lastMessageCreatedAt,
        lastReadMessageId,
        unseenMessageCount,
        status,
        draft,
        muteUntil
      ];
  @override
  Conversations get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'conversations';
  @override
  final String actualTableName = 'conversations';
  @override
  VerificationContext validateIntegrity(Insertable<Conversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    }
    context.handle(_categoryMeta, const VerificationResult.success());
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('icon_url')) {
      context.handle(_iconUrlMeta,
          iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta));
    }
    if (data.containsKey('announcement')) {
      context.handle(
          _announcementMeta,
          announcement.isAcceptableOrUnknown(
              data['announcement']!, _announcementMeta));
    }
    if (data.containsKey('code_url')) {
      context.handle(_codeUrlMeta,
          codeUrl.isAcceptableOrUnknown(data['code_url']!, _codeUrlMeta));
    }
    if (data.containsKey('pay_type')) {
      context.handle(_payTypeMeta,
          payType.isAcceptableOrUnknown(data['pay_type']!, _payTypeMeta));
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    context.handle(_pinTimeMeta, const VerificationResult.success());
    if (data.containsKey('last_message_id')) {
      context.handle(
          _lastMessageIdMeta,
          lastMessageId.isAcceptableOrUnknown(
              data['last_message_id']!, _lastMessageIdMeta));
    }
    context.handle(
        _lastMessageCreatedAtMeta, const VerificationResult.success());
    if (data.containsKey('last_read_message_id')) {
      context.handle(
          _lastReadMessageIdMeta,
          lastReadMessageId.isAcceptableOrUnknown(
              data['last_read_message_id']!, _lastReadMessageIdMeta));
    }
    if (data.containsKey('unseen_message_count')) {
      context.handle(
          _unseenMessageCountMeta,
          unseenMessageCount.isAcceptableOrUnknown(
              data['unseen_message_count']!, _unseenMessageCountMeta));
    }
    context.handle(_statusMeta, const VerificationResult.success());
    if (data.containsKey('draft')) {
      context.handle(
          _draftMeta, draft.isAcceptableOrUnknown(data['draft']!, _draftMeta));
    }
    context.handle(_muteUntilMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Conversation.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Conversations createAlias(String alias) {
    return Conversations(_db, alias);
  }

  static TypeConverter<ConversationCategory, String> $converter0 =
      const ConversationCategoryTypeConverter();
  static TypeConverter<DateTime, int> $converter1 = const MillisDateConverter();
  static TypeConverter<DateTime, int> $converter2 = const MillisDateConverter();
  static TypeConverter<DateTime, int> $converter3 = const MillisDateConverter();
  static TypeConverter<ConversationStatus, int> $converter4 =
      const ConversationStatusTypeConverter();
  static TypeConverter<DateTime, int> $converter5 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(conversation_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class MessageMention extends DataClass implements Insertable<MessageMention> {
  final String messageId;
  final String conversationId;
  final String mentions;
  final int? hasRead;
  MessageMention(
      {required this.messageId,
      required this.conversationId,
      required this.mentions,
      this.hasRead});
  factory MessageMention.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return MessageMention(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id'])!,
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id'])!,
      mentions: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}mentions'])!,
      hasRead:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}has_read']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['mentions'] = Variable<String>(mentions);
    if (!nullToAbsent || hasRead != null) {
      map['has_read'] = Variable<int?>(hasRead);
    }
    return map;
  }

  MessageMentionsCompanion toCompanion(bool nullToAbsent) {
    return MessageMentionsCompanion(
      messageId: Value(messageId),
      conversationId: Value(conversationId),
      mentions: Value(mentions),
      hasRead: hasRead == null && nullToAbsent
          ? const Value.absent()
          : Value(hasRead),
    );
  }

  factory MessageMention.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return MessageMention(
      messageId: serializer.fromJson<String>(json['message_id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      mentions: serializer.fromJson<String>(json['mentions']),
      hasRead: serializer.fromJson<int?>(json['has_read']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'conversation_id': serializer.toJson<String>(conversationId),
      'mentions': serializer.toJson<String>(mentions),
      'has_read': serializer.toJson<int?>(hasRead),
    };
  }

  MessageMention copyWith(
          {String? messageId,
          String? conversationId,
          String? mentions,
          int? hasRead}) =>
      MessageMention(
        messageId: messageId ?? this.messageId,
        conversationId: conversationId ?? this.conversationId,
        mentions: mentions ?? this.mentions,
        hasRead: hasRead ?? this.hasRead,
      );
  @override
  String toString() {
    return (StringBuffer('MessageMention(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('mentions: $mentions, ')
          ..write('hasRead: $hasRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      messageId.hashCode,
      $mrjc(conversationId.hashCode,
          $mrjc(mentions.hashCode, hasRead.hashCode))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is MessageMention &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.mentions == this.mentions &&
          other.hasRead == this.hasRead);
}

class MessageMentionsCompanion extends UpdateCompanion<MessageMention> {
  final Value<String> messageId;
  final Value<String> conversationId;
  final Value<String> mentions;
  final Value<int?> hasRead;
  const MessageMentionsCompanion({
    this.messageId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.mentions = const Value.absent(),
    this.hasRead = const Value.absent(),
  });
  MessageMentionsCompanion.insert({
    required String messageId,
    required String conversationId,
    required String mentions,
    this.hasRead = const Value.absent(),
  })  : messageId = Value(messageId),
        conversationId = Value(conversationId),
        mentions = Value(mentions);
  static Insertable<MessageMention> custom({
    Expression<String>? messageId,
    Expression<String>? conversationId,
    Expression<String>? mentions,
    Expression<int?>? hasRead,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (mentions != null) 'mentions': mentions,
      if (hasRead != null) 'has_read': hasRead,
    });
  }

  MessageMentionsCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? conversationId,
      Value<String>? mentions,
      Value<int?>? hasRead}) {
    return MessageMentionsCompanion(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      mentions: mentions ?? this.mentions,
      hasRead: hasRead ?? this.hasRead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (mentions.present) {
      map['mentions'] = Variable<String>(mentions.value);
    }
    if (hasRead.present) {
      map['has_read'] = Variable<int?>(hasRead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageMentionsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('mentions: $mentions, ')
          ..write('hasRead: $hasRead')
          ..write(')'))
        .toString();
  }
}

class MessageMentions extends Table
    with TableInfo<MessageMentions, MessageMention> {
  final GeneratedDatabase _db;
  final String? _alias;
  MessageMentions(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  late final GeneratedTextColumn messageId = _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedTextColumn conversationId = _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _mentionsMeta = const VerificationMeta('mentions');
  late final GeneratedTextColumn mentions = _constructMentions();
  GeneratedTextColumn _constructMentions() {
    return GeneratedTextColumn('mentions', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _hasReadMeta = const VerificationMeta('hasRead');
  late final GeneratedIntColumn hasRead = _constructHasRead();
  GeneratedIntColumn _constructHasRead() {
    return GeneratedIntColumn('has_read', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [messageId, conversationId, mentions, hasRead];
  @override
  MessageMentions get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'message_mentions';
  @override
  final String actualTableName = 'message_mentions';
  @override
  VerificationContext validateIntegrity(Insertable<MessageMention> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('mentions')) {
      context.handle(_mentionsMeta,
          mentions.isAcceptableOrUnknown(data['mentions']!, _mentionsMeta));
    } else if (isInserting) {
      context.missing(_mentionsMeta);
    }
    if (data.containsKey('has_read')) {
      context.handle(_hasReadMeta,
          hasRead.isAcceptableOrUnknown(data['has_read']!, _hasReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  MessageMention map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return MessageMention.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  MessageMentions createAlias(String alias) {
    return MessageMentions(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Message extends DataClass implements Insertable<Message> {
  final String messageId;
  final String conversationId;
  final String userId;
  final MessageCategory category;
  final String? content;
  final String? mediaUrl;
  final String? mediaMimeType;
  final int? mediaSize;
  final String? mediaDuration;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? mediaHash;
  final String? thumbImage;
  final String? mediaKey;
  final String? mediaDigest;
  final MediaStatus? mediaStatus;
  final MessageStatus status;
  final DateTime createdAt;
  final MessageAction? action;
  final String? participantId;
  final String? snapshotId;
  final String? hyperlink;
  final String? name;
  final String? albumId;
  final String? stickerId;
  final String? sharedUserId;
  final String? mediaWaveform;
  final String? quoteMessageId;
  final String? quoteContent;
  final String? thumbUrl;
  Message(
      {required this.messageId,
      required this.conversationId,
      required this.userId,
      required this.category,
      this.content,
      this.mediaUrl,
      this.mediaMimeType,
      this.mediaSize,
      this.mediaDuration,
      this.mediaWidth,
      this.mediaHeight,
      this.mediaHash,
      this.thumbImage,
      this.mediaKey,
      this.mediaDigest,
      this.mediaStatus,
      required this.status,
      required this.createdAt,
      this.action,
      this.participantId,
      this.snapshotId,
      this.hyperlink,
      this.name,
      this.albumId,
      this.stickerId,
      this.sharedUserId,
      this.mediaWaveform,
      this.quoteMessageId,
      this.quoteContent,
      this.thumbUrl});
  factory Message.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Message(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id'])!,
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id'])!,
      userId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      category: Messages.$converter0.mapToDart(stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}category']))!,
      content:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}content']),
      mediaUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_url']),
      mediaMimeType: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_mime_type']),
      mediaSize:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}media_size']),
      mediaDuration: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_duration']),
      mediaWidth: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_width']),
      mediaHeight: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_height']),
      mediaHash: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_hash']),
      thumbImage: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}thumb_image']),
      mediaKey: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_key']),
      mediaDigest: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_digest']),
      mediaStatus: Messages.$converter1.mapToDart(stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_status'])),
      status: Messages.$converter2.mapToDart(stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}status']))!,
      createdAt: Messages.$converter3.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
      action: Messages.$converter4.mapToDart(
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}action'])),
      participantId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}participant_id']),
      snapshotId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}snapshot_id']),
      hyperlink: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}hyperlink']),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name']),
      albumId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}album_id']),
      stickerId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}sticker_id']),
      sharedUserId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}shared_user_id']),
      mediaWaveform: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_waveform']),
      quoteMessageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}quote_message_id']),
      quoteContent: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}quote_content']),
      thumbUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}thumb_url']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['user_id'] = Variable<String>(userId);
    {
      final converter = Messages.$converter0;
      map['category'] = Variable<String>(converter.mapToSql(category)!);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String?>(content);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String?>(mediaUrl);
    }
    if (!nullToAbsent || mediaMimeType != null) {
      map['media_mime_type'] = Variable<String?>(mediaMimeType);
    }
    if (!nullToAbsent || mediaSize != null) {
      map['media_size'] = Variable<int?>(mediaSize);
    }
    if (!nullToAbsent || mediaDuration != null) {
      map['media_duration'] = Variable<String?>(mediaDuration);
    }
    if (!nullToAbsent || mediaWidth != null) {
      map['media_width'] = Variable<int?>(mediaWidth);
    }
    if (!nullToAbsent || mediaHeight != null) {
      map['media_height'] = Variable<int?>(mediaHeight);
    }
    if (!nullToAbsent || mediaHash != null) {
      map['media_hash'] = Variable<String?>(mediaHash);
    }
    if (!nullToAbsent || thumbImage != null) {
      map['thumb_image'] = Variable<String?>(thumbImage);
    }
    if (!nullToAbsent || mediaKey != null) {
      map['media_key'] = Variable<String?>(mediaKey);
    }
    if (!nullToAbsent || mediaDigest != null) {
      map['media_digest'] = Variable<String?>(mediaDigest);
    }
    if (!nullToAbsent || mediaStatus != null) {
      final converter = Messages.$converter1;
      map['media_status'] = Variable<String?>(converter.mapToSql(mediaStatus));
    }
    {
      final converter = Messages.$converter2;
      map['status'] = Variable<String>(converter.mapToSql(status)!);
    }
    {
      final converter = Messages.$converter3;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    if (!nullToAbsent || action != null) {
      final converter = Messages.$converter4;
      map['action'] = Variable<String?>(converter.mapToSql(action));
    }
    if (!nullToAbsent || participantId != null) {
      map['participant_id'] = Variable<String?>(participantId);
    }
    if (!nullToAbsent || snapshotId != null) {
      map['snapshot_id'] = Variable<String?>(snapshotId);
    }
    if (!nullToAbsent || hyperlink != null) {
      map['hyperlink'] = Variable<String?>(hyperlink);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String?>(name);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String?>(albumId);
    }
    if (!nullToAbsent || stickerId != null) {
      map['sticker_id'] = Variable<String?>(stickerId);
    }
    if (!nullToAbsent || sharedUserId != null) {
      map['shared_user_id'] = Variable<String?>(sharedUserId);
    }
    if (!nullToAbsent || mediaWaveform != null) {
      map['media_waveform'] = Variable<String?>(mediaWaveform);
    }
    if (!nullToAbsent || quoteMessageId != null) {
      map['quote_message_id'] = Variable<String?>(quoteMessageId);
    }
    if (!nullToAbsent || quoteContent != null) {
      map['quote_content'] = Variable<String?>(quoteContent);
    }
    if (!nullToAbsent || thumbUrl != null) {
      map['thumb_url'] = Variable<String?>(thumbUrl);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      messageId: Value(messageId),
      conversationId: Value(conversationId),
      userId: Value(userId),
      category: Value(category),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      mediaMimeType: mediaMimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaMimeType),
      mediaSize: mediaSize == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaSize),
      mediaDuration: mediaDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaDuration),
      mediaWidth: mediaWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaWidth),
      mediaHeight: mediaHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaHeight),
      mediaHash: mediaHash == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaHash),
      thumbImage: thumbImage == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbImage),
      mediaKey: mediaKey == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaKey),
      mediaDigest: mediaDigest == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaDigest),
      mediaStatus: mediaStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaStatus),
      status: Value(status),
      createdAt: Value(createdAt),
      action:
          action == null && nullToAbsent ? const Value.absent() : Value(action),
      participantId: participantId == null && nullToAbsent
          ? const Value.absent()
          : Value(participantId),
      snapshotId: snapshotId == null && nullToAbsent
          ? const Value.absent()
          : Value(snapshotId),
      hyperlink: hyperlink == null && nullToAbsent
          ? const Value.absent()
          : Value(hyperlink),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      stickerId: stickerId == null && nullToAbsent
          ? const Value.absent()
          : Value(stickerId),
      sharedUserId: sharedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedUserId),
      mediaWaveform: mediaWaveform == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaWaveform),
      quoteMessageId: quoteMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(quoteMessageId),
      quoteContent: quoteContent == null && nullToAbsent
          ? const Value.absent()
          : Value(quoteContent),
      thumbUrl: thumbUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbUrl),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Message(
      messageId: serializer.fromJson<String>(json['message_id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      category: serializer.fromJson<MessageCategory>(json['category']),
      content: serializer.fromJson<String?>(json['content']),
      mediaUrl: serializer.fromJson<String?>(json['media_url']),
      mediaMimeType: serializer.fromJson<String?>(json['media_mime_type']),
      mediaSize: serializer.fromJson<int?>(json['media_size']),
      mediaDuration: serializer.fromJson<String?>(json['media_duration']),
      mediaWidth: serializer.fromJson<int?>(json['media_width']),
      mediaHeight: serializer.fromJson<int?>(json['media_height']),
      mediaHash: serializer.fromJson<String?>(json['media_hash']),
      thumbImage: serializer.fromJson<String?>(json['thumb_image']),
      mediaKey: serializer.fromJson<String?>(json['media_key']),
      mediaDigest: serializer.fromJson<String?>(json['media_digest']),
      mediaStatus: serializer.fromJson<MediaStatus?>(json['media_status']),
      status: serializer.fromJson<MessageStatus>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      action: serializer.fromJson<MessageAction?>(json['action']),
      participantId: serializer.fromJson<String?>(json['participant_id']),
      snapshotId: serializer.fromJson<String?>(json['snapshot_id']),
      hyperlink: serializer.fromJson<String?>(json['hyperlink']),
      name: serializer.fromJson<String?>(json['name']),
      albumId: serializer.fromJson<String?>(json['album_id']),
      stickerId: serializer.fromJson<String?>(json['sticker_id']),
      sharedUserId: serializer.fromJson<String?>(json['shared_user_id']),
      mediaWaveform: serializer.fromJson<String?>(json['media_waveform']),
      quoteMessageId: serializer.fromJson<String?>(json['quote_message_id']),
      quoteContent: serializer.fromJson<String?>(json['quote_content']),
      thumbUrl: serializer.fromJson<String?>(json['thumb_url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'conversation_id': serializer.toJson<String>(conversationId),
      'user_id': serializer.toJson<String>(userId),
      'category': serializer.toJson<MessageCategory>(category),
      'content': serializer.toJson<String?>(content),
      'media_url': serializer.toJson<String?>(mediaUrl),
      'media_mime_type': serializer.toJson<String?>(mediaMimeType),
      'media_size': serializer.toJson<int?>(mediaSize),
      'media_duration': serializer.toJson<String?>(mediaDuration),
      'media_width': serializer.toJson<int?>(mediaWidth),
      'media_height': serializer.toJson<int?>(mediaHeight),
      'media_hash': serializer.toJson<String?>(mediaHash),
      'thumb_image': serializer.toJson<String?>(thumbImage),
      'media_key': serializer.toJson<String?>(mediaKey),
      'media_digest': serializer.toJson<String?>(mediaDigest),
      'media_status': serializer.toJson<MediaStatus?>(mediaStatus),
      'status': serializer.toJson<MessageStatus>(status),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'action': serializer.toJson<MessageAction?>(action),
      'participant_id': serializer.toJson<String?>(participantId),
      'snapshot_id': serializer.toJson<String?>(snapshotId),
      'hyperlink': serializer.toJson<String?>(hyperlink),
      'name': serializer.toJson<String?>(name),
      'album_id': serializer.toJson<String?>(albumId),
      'sticker_id': serializer.toJson<String?>(stickerId),
      'shared_user_id': serializer.toJson<String?>(sharedUserId),
      'media_waveform': serializer.toJson<String?>(mediaWaveform),
      'quote_message_id': serializer.toJson<String?>(quoteMessageId),
      'quote_content': serializer.toJson<String?>(quoteContent),
      'thumb_url': serializer.toJson<String?>(thumbUrl),
    };
  }

  Message copyWith(
          {String? messageId,
          String? conversationId,
          String? userId,
          MessageCategory? category,
          String? content,
          String? mediaUrl,
          String? mediaMimeType,
          int? mediaSize,
          String? mediaDuration,
          int? mediaWidth,
          int? mediaHeight,
          String? mediaHash,
          String? thumbImage,
          String? mediaKey,
          String? mediaDigest,
          MediaStatus? mediaStatus,
          MessageStatus? status,
          DateTime? createdAt,
          MessageAction? action,
          String? participantId,
          String? snapshotId,
          String? hyperlink,
          String? name,
          String? albumId,
          String? stickerId,
          String? sharedUserId,
          String? mediaWaveform,
          String? quoteMessageId,
          String? quoteContent,
          String? thumbUrl}) =>
      Message(
        messageId: messageId ?? this.messageId,
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        category: category ?? this.category,
        content: content ?? this.content,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        mediaMimeType: mediaMimeType ?? this.mediaMimeType,
        mediaSize: mediaSize ?? this.mediaSize,
        mediaDuration: mediaDuration ?? this.mediaDuration,
        mediaWidth: mediaWidth ?? this.mediaWidth,
        mediaHeight: mediaHeight ?? this.mediaHeight,
        mediaHash: mediaHash ?? this.mediaHash,
        thumbImage: thumbImage ?? this.thumbImage,
        mediaKey: mediaKey ?? this.mediaKey,
        mediaDigest: mediaDigest ?? this.mediaDigest,
        mediaStatus: mediaStatus ?? this.mediaStatus,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        action: action ?? this.action,
        participantId: participantId ?? this.participantId,
        snapshotId: snapshotId ?? this.snapshotId,
        hyperlink: hyperlink ?? this.hyperlink,
        name: name ?? this.name,
        albumId: albumId ?? this.albumId,
        stickerId: stickerId ?? this.stickerId,
        sharedUserId: sharedUserId ?? this.sharedUserId,
        mediaWaveform: mediaWaveform ?? this.mediaWaveform,
        quoteMessageId: quoteMessageId ?? this.quoteMessageId,
        quoteContent: quoteContent ?? this.quoteContent,
        thumbUrl: thumbUrl ?? this.thumbUrl,
      );
  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('category: $category, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaSize: $mediaSize, ')
          ..write('mediaDuration: $mediaDuration, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaHash: $mediaHash, ')
          ..write('thumbImage: $thumbImage, ')
          ..write('mediaKey: $mediaKey, ')
          ..write('mediaDigest: $mediaDigest, ')
          ..write('mediaStatus: $mediaStatus, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('action: $action, ')
          ..write('participantId: $participantId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('hyperlink: $hyperlink, ')
          ..write('name: $name, ')
          ..write('albumId: $albumId, ')
          ..write('stickerId: $stickerId, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('mediaWaveform: $mediaWaveform, ')
          ..write('quoteMessageId: $quoteMessageId, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('thumbUrl: $thumbUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      messageId.hashCode,
      $mrjc(
          conversationId.hashCode,
          $mrjc(
              userId.hashCode,
              $mrjc(
                  category.hashCode,
                  $mrjc(
                      content.hashCode,
                      $mrjc(
                          mediaUrl.hashCode,
                          $mrjc(
                              mediaMimeType.hashCode,
                              $mrjc(
                                  mediaSize.hashCode,
                                  $mrjc(
                                      mediaDuration.hashCode,
                                      $mrjc(
                                          mediaWidth.hashCode,
                                          $mrjc(
                                              mediaHeight.hashCode,
                                              $mrjc(
                                                  mediaHash.hashCode,
                                                  $mrjc(
                                                      thumbImage.hashCode,
                                                      $mrjc(
                                                          mediaKey.hashCode,
                                                          $mrjc(
                                                              mediaDigest
                                                                  .hashCode,
                                                              $mrjc(
                                                                  mediaStatus
                                                                      .hashCode,
                                                                  $mrjc(
                                                                      status
                                                                          .hashCode,
                                                                      $mrjc(
                                                                          createdAt
                                                                              .hashCode,
                                                                          $mrjc(
                                                                              action.hashCode,
                                                                              $mrjc(participantId.hashCode, $mrjc(snapshotId.hashCode, $mrjc(hyperlink.hashCode, $mrjc(name.hashCode, $mrjc(albumId.hashCode, $mrjc(stickerId.hashCode, $mrjc(sharedUserId.hashCode, $mrjc(mediaWaveform.hashCode, $mrjc(quoteMessageId.hashCode, $mrjc(quoteContent.hashCode, thumbUrl.hashCode))))))))))))))))))))))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Message &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.category == this.category &&
          other.content == this.content &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaMimeType == this.mediaMimeType &&
          other.mediaSize == this.mediaSize &&
          other.mediaDuration == this.mediaDuration &&
          other.mediaWidth == this.mediaWidth &&
          other.mediaHeight == this.mediaHeight &&
          other.mediaHash == this.mediaHash &&
          other.thumbImage == this.thumbImage &&
          other.mediaKey == this.mediaKey &&
          other.mediaDigest == this.mediaDigest &&
          other.mediaStatus == this.mediaStatus &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.action == this.action &&
          other.participantId == this.participantId &&
          other.snapshotId == this.snapshotId &&
          other.hyperlink == this.hyperlink &&
          other.name == this.name &&
          other.albumId == this.albumId &&
          other.stickerId == this.stickerId &&
          other.sharedUserId == this.sharedUserId &&
          other.mediaWaveform == this.mediaWaveform &&
          other.quoteMessageId == this.quoteMessageId &&
          other.quoteContent == this.quoteContent &&
          other.thumbUrl == this.thumbUrl);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> messageId;
  final Value<String> conversationId;
  final Value<String> userId;
  final Value<MessageCategory> category;
  final Value<String?> content;
  final Value<String?> mediaUrl;
  final Value<String?> mediaMimeType;
  final Value<int?> mediaSize;
  final Value<String?> mediaDuration;
  final Value<int?> mediaWidth;
  final Value<int?> mediaHeight;
  final Value<String?> mediaHash;
  final Value<String?> thumbImage;
  final Value<String?> mediaKey;
  final Value<String?> mediaDigest;
  final Value<MediaStatus?> mediaStatus;
  final Value<MessageStatus> status;
  final Value<DateTime> createdAt;
  final Value<MessageAction?> action;
  final Value<String?> participantId;
  final Value<String?> snapshotId;
  final Value<String?> hyperlink;
  final Value<String?> name;
  final Value<String?> albumId;
  final Value<String?> stickerId;
  final Value<String?> sharedUserId;
  final Value<String?> mediaWaveform;
  final Value<String?> quoteMessageId;
  final Value<String?> quoteContent;
  final Value<String?> thumbUrl;
  const MessagesCompanion({
    this.messageId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.category = const Value.absent(),
    this.content = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaMimeType = const Value.absent(),
    this.mediaSize = const Value.absent(),
    this.mediaDuration = const Value.absent(),
    this.mediaWidth = const Value.absent(),
    this.mediaHeight = const Value.absent(),
    this.mediaHash = const Value.absent(),
    this.thumbImage = const Value.absent(),
    this.mediaKey = const Value.absent(),
    this.mediaDigest = const Value.absent(),
    this.mediaStatus = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.action = const Value.absent(),
    this.participantId = const Value.absent(),
    this.snapshotId = const Value.absent(),
    this.hyperlink = const Value.absent(),
    this.name = const Value.absent(),
    this.albumId = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.sharedUserId = const Value.absent(),
    this.mediaWaveform = const Value.absent(),
    this.quoteMessageId = const Value.absent(),
    this.quoteContent = const Value.absent(),
    this.thumbUrl = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String messageId,
    required String conversationId,
    required String userId,
    required MessageCategory category,
    this.content = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaMimeType = const Value.absent(),
    this.mediaSize = const Value.absent(),
    this.mediaDuration = const Value.absent(),
    this.mediaWidth = const Value.absent(),
    this.mediaHeight = const Value.absent(),
    this.mediaHash = const Value.absent(),
    this.thumbImage = const Value.absent(),
    this.mediaKey = const Value.absent(),
    this.mediaDigest = const Value.absent(),
    this.mediaStatus = const Value.absent(),
    required MessageStatus status,
    required DateTime createdAt,
    this.action = const Value.absent(),
    this.participantId = const Value.absent(),
    this.snapshotId = const Value.absent(),
    this.hyperlink = const Value.absent(),
    this.name = const Value.absent(),
    this.albumId = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.sharedUserId = const Value.absent(),
    this.mediaWaveform = const Value.absent(),
    this.quoteMessageId = const Value.absent(),
    this.quoteContent = const Value.absent(),
    this.thumbUrl = const Value.absent(),
  })  : messageId = Value(messageId),
        conversationId = Value(conversationId),
        userId = Value(userId),
        category = Value(category),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<String>? messageId,
    Expression<String>? conversationId,
    Expression<String>? userId,
    Expression<MessageCategory>? category,
    Expression<String?>? content,
    Expression<String?>? mediaUrl,
    Expression<String?>? mediaMimeType,
    Expression<int?>? mediaSize,
    Expression<String?>? mediaDuration,
    Expression<int?>? mediaWidth,
    Expression<int?>? mediaHeight,
    Expression<String?>? mediaHash,
    Expression<String?>? thumbImage,
    Expression<String?>? mediaKey,
    Expression<String?>? mediaDigest,
    Expression<MediaStatus?>? mediaStatus,
    Expression<MessageStatus>? status,
    Expression<DateTime>? createdAt,
    Expression<MessageAction?>? action,
    Expression<String?>? participantId,
    Expression<String?>? snapshotId,
    Expression<String?>? hyperlink,
    Expression<String?>? name,
    Expression<String?>? albumId,
    Expression<String?>? stickerId,
    Expression<String?>? sharedUserId,
    Expression<String?>? mediaWaveform,
    Expression<String?>? quoteMessageId,
    Expression<String?>? quoteContent,
    Expression<String?>? thumbUrl,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
      if (category != null) 'category': category,
      if (content != null) 'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaMimeType != null) 'media_mime_type': mediaMimeType,
      if (mediaSize != null) 'media_size': mediaSize,
      if (mediaDuration != null) 'media_duration': mediaDuration,
      if (mediaWidth != null) 'media_width': mediaWidth,
      if (mediaHeight != null) 'media_height': mediaHeight,
      if (mediaHash != null) 'media_hash': mediaHash,
      if (thumbImage != null) 'thumb_image': thumbImage,
      if (mediaKey != null) 'media_key': mediaKey,
      if (mediaDigest != null) 'media_digest': mediaDigest,
      if (mediaStatus != null) 'media_status': mediaStatus,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (action != null) 'action': action,
      if (participantId != null) 'participant_id': participantId,
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (hyperlink != null) 'hyperlink': hyperlink,
      if (name != null) 'name': name,
      if (albumId != null) 'album_id': albumId,
      if (stickerId != null) 'sticker_id': stickerId,
      if (sharedUserId != null) 'shared_user_id': sharedUserId,
      if (mediaWaveform != null) 'media_waveform': mediaWaveform,
      if (quoteMessageId != null) 'quote_message_id': quoteMessageId,
      if (quoteContent != null) 'quote_content': quoteContent,
      if (thumbUrl != null) 'thumb_url': thumbUrl,
    });
  }

  MessagesCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? conversationId,
      Value<String>? userId,
      Value<MessageCategory>? category,
      Value<String?>? content,
      Value<String?>? mediaUrl,
      Value<String?>? mediaMimeType,
      Value<int?>? mediaSize,
      Value<String?>? mediaDuration,
      Value<int?>? mediaWidth,
      Value<int?>? mediaHeight,
      Value<String?>? mediaHash,
      Value<String?>? thumbImage,
      Value<String?>? mediaKey,
      Value<String?>? mediaDigest,
      Value<MediaStatus?>? mediaStatus,
      Value<MessageStatus>? status,
      Value<DateTime>? createdAt,
      Value<MessageAction?>? action,
      Value<String?>? participantId,
      Value<String?>? snapshotId,
      Value<String?>? hyperlink,
      Value<String?>? name,
      Value<String?>? albumId,
      Value<String?>? stickerId,
      Value<String?>? sharedUserId,
      Value<String?>? mediaWaveform,
      Value<String?>? quoteMessageId,
      Value<String?>? quoteContent,
      Value<String?>? thumbUrl}) {
    return MessagesCompanion(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMimeType: mediaMimeType ?? this.mediaMimeType,
      mediaSize: mediaSize ?? this.mediaSize,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      mediaHash: mediaHash ?? this.mediaHash,
      thumbImage: thumbImage ?? this.thumbImage,
      mediaKey: mediaKey ?? this.mediaKey,
      mediaDigest: mediaDigest ?? this.mediaDigest,
      mediaStatus: mediaStatus ?? this.mediaStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      action: action ?? this.action,
      participantId: participantId ?? this.participantId,
      snapshotId: snapshotId ?? this.snapshotId,
      hyperlink: hyperlink ?? this.hyperlink,
      name: name ?? this.name,
      albumId: albumId ?? this.albumId,
      stickerId: stickerId ?? this.stickerId,
      sharedUserId: sharedUserId ?? this.sharedUserId,
      mediaWaveform: mediaWaveform ?? this.mediaWaveform,
      quoteMessageId: quoteMessageId ?? this.quoteMessageId,
      quoteContent: quoteContent ?? this.quoteContent,
      thumbUrl: thumbUrl ?? this.thumbUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (category.present) {
      final converter = Messages.$converter0;
      map['category'] = Variable<String>(converter.mapToSql(category.value)!);
    }
    if (content.present) {
      map['content'] = Variable<String?>(content.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String?>(mediaUrl.value);
    }
    if (mediaMimeType.present) {
      map['media_mime_type'] = Variable<String?>(mediaMimeType.value);
    }
    if (mediaSize.present) {
      map['media_size'] = Variable<int?>(mediaSize.value);
    }
    if (mediaDuration.present) {
      map['media_duration'] = Variable<String?>(mediaDuration.value);
    }
    if (mediaWidth.present) {
      map['media_width'] = Variable<int?>(mediaWidth.value);
    }
    if (mediaHeight.present) {
      map['media_height'] = Variable<int?>(mediaHeight.value);
    }
    if (mediaHash.present) {
      map['media_hash'] = Variable<String?>(mediaHash.value);
    }
    if (thumbImage.present) {
      map['thumb_image'] = Variable<String?>(thumbImage.value);
    }
    if (mediaKey.present) {
      map['media_key'] = Variable<String?>(mediaKey.value);
    }
    if (mediaDigest.present) {
      map['media_digest'] = Variable<String?>(mediaDigest.value);
    }
    if (mediaStatus.present) {
      final converter = Messages.$converter1;
      map['media_status'] =
          Variable<String?>(converter.mapToSql(mediaStatus.value));
    }
    if (status.present) {
      final converter = Messages.$converter2;
      map['status'] = Variable<String>(converter.mapToSql(status.value)!);
    }
    if (createdAt.present) {
      final converter = Messages.$converter3;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    if (action.present) {
      final converter = Messages.$converter4;
      map['action'] = Variable<String?>(converter.mapToSql(action.value));
    }
    if (participantId.present) {
      map['participant_id'] = Variable<String?>(participantId.value);
    }
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<String?>(snapshotId.value);
    }
    if (hyperlink.present) {
      map['hyperlink'] = Variable<String?>(hyperlink.value);
    }
    if (name.present) {
      map['name'] = Variable<String?>(name.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String?>(albumId.value);
    }
    if (stickerId.present) {
      map['sticker_id'] = Variable<String?>(stickerId.value);
    }
    if (sharedUserId.present) {
      map['shared_user_id'] = Variable<String?>(sharedUserId.value);
    }
    if (mediaWaveform.present) {
      map['media_waveform'] = Variable<String?>(mediaWaveform.value);
    }
    if (quoteMessageId.present) {
      map['quote_message_id'] = Variable<String?>(quoteMessageId.value);
    }
    if (quoteContent.present) {
      map['quote_content'] = Variable<String?>(quoteContent.value);
    }
    if (thumbUrl.present) {
      map['thumb_url'] = Variable<String?>(thumbUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('category: $category, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaSize: $mediaSize, ')
          ..write('mediaDuration: $mediaDuration, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaHash: $mediaHash, ')
          ..write('thumbImage: $thumbImage, ')
          ..write('mediaKey: $mediaKey, ')
          ..write('mediaDigest: $mediaDigest, ')
          ..write('mediaStatus: $mediaStatus, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('action: $action, ')
          ..write('participantId: $participantId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('hyperlink: $hyperlink, ')
          ..write('name: $name, ')
          ..write('albumId: $albumId, ')
          ..write('stickerId: $stickerId, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('mediaWaveform: $mediaWaveform, ')
          ..write('quoteMessageId: $quoteMessageId, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('thumbUrl: $thumbUrl')
          ..write(')'))
        .toString();
  }
}

class Messages extends Table with TableInfo<Messages, Message> {
  final GeneratedDatabase _db;
  final String? _alias;
  Messages(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  late final GeneratedTextColumn messageId = _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedTextColumn conversationId = _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  late final GeneratedTextColumn category = _constructCategory();
  GeneratedTextColumn _constructCategory() {
    return GeneratedTextColumn('category', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _contentMeta = const VerificationMeta('content');
  late final GeneratedTextColumn content = _constructContent();
  GeneratedTextColumn _constructContent() {
    return GeneratedTextColumn('content', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaUrlMeta = const VerificationMeta('mediaUrl');
  late final GeneratedTextColumn mediaUrl = _constructMediaUrl();
  GeneratedTextColumn _constructMediaUrl() {
    return GeneratedTextColumn('media_url', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaMimeTypeMeta =
      const VerificationMeta('mediaMimeType');
  late final GeneratedTextColumn mediaMimeType = _constructMediaMimeType();
  GeneratedTextColumn _constructMediaMimeType() {
    return GeneratedTextColumn('media_mime_type', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaSizeMeta = const VerificationMeta('mediaSize');
  late final GeneratedIntColumn mediaSize = _constructMediaSize();
  GeneratedIntColumn _constructMediaSize() {
    return GeneratedIntColumn('media_size', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaDurationMeta =
      const VerificationMeta('mediaDuration');
  late final GeneratedTextColumn mediaDuration = _constructMediaDuration();
  GeneratedTextColumn _constructMediaDuration() {
    return GeneratedTextColumn('media_duration', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaWidthMeta = const VerificationMeta('mediaWidth');
  late final GeneratedIntColumn mediaWidth = _constructMediaWidth();
  GeneratedIntColumn _constructMediaWidth() {
    return GeneratedIntColumn('media_width', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaHeightMeta =
      const VerificationMeta('mediaHeight');
  late final GeneratedIntColumn mediaHeight = _constructMediaHeight();
  GeneratedIntColumn _constructMediaHeight() {
    return GeneratedIntColumn('media_height', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaHashMeta = const VerificationMeta('mediaHash');
  late final GeneratedTextColumn mediaHash = _constructMediaHash();
  GeneratedTextColumn _constructMediaHash() {
    return GeneratedTextColumn('media_hash', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _thumbImageMeta = const VerificationMeta('thumbImage');
  late final GeneratedTextColumn thumbImage = _constructThumbImage();
  GeneratedTextColumn _constructThumbImage() {
    return GeneratedTextColumn('thumb_image', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaKeyMeta = const VerificationMeta('mediaKey');
  late final GeneratedTextColumn mediaKey = _constructMediaKey();
  GeneratedTextColumn _constructMediaKey() {
    return GeneratedTextColumn('media_key', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaDigestMeta =
      const VerificationMeta('mediaDigest');
  late final GeneratedTextColumn mediaDigest = _constructMediaDigest();
  GeneratedTextColumn _constructMediaDigest() {
    return GeneratedTextColumn('media_digest', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaStatusMeta =
      const VerificationMeta('mediaStatus');
  late final GeneratedTextColumn mediaStatus = _constructMediaStatus();
  GeneratedTextColumn _constructMediaStatus() {
    return GeneratedTextColumn('media_status', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedTextColumn status = _constructStatus();
  GeneratedTextColumn _constructStatus() {
    return GeneratedTextColumn('status', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _actionMeta = const VerificationMeta('action');
  late final GeneratedTextColumn action = _constructAction();
  GeneratedTextColumn _constructAction() {
    return GeneratedTextColumn('action', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _participantIdMeta =
      const VerificationMeta('participantId');
  late final GeneratedTextColumn participantId = _constructParticipantId();
  GeneratedTextColumn _constructParticipantId() {
    return GeneratedTextColumn('participant_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _snapshotIdMeta = const VerificationMeta('snapshotId');
  late final GeneratedTextColumn snapshotId = _constructSnapshotId();
  GeneratedTextColumn _constructSnapshotId() {
    return GeneratedTextColumn('snapshot_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _hyperlinkMeta = const VerificationMeta('hyperlink');
  late final GeneratedTextColumn hyperlink = _constructHyperlink();
  GeneratedTextColumn _constructHyperlink() {
    return GeneratedTextColumn('hyperlink', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _albumIdMeta = const VerificationMeta('albumId');
  late final GeneratedTextColumn albumId = _constructAlbumId();
  GeneratedTextColumn _constructAlbumId() {
    return GeneratedTextColumn('album_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _stickerIdMeta = const VerificationMeta('stickerId');
  late final GeneratedTextColumn stickerId = _constructStickerId();
  GeneratedTextColumn _constructStickerId() {
    return GeneratedTextColumn('sticker_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _sharedUserIdMeta =
      const VerificationMeta('sharedUserId');
  late final GeneratedTextColumn sharedUserId = _constructSharedUserId();
  GeneratedTextColumn _constructSharedUserId() {
    return GeneratedTextColumn('shared_user_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaWaveformMeta =
      const VerificationMeta('mediaWaveform');
  late final GeneratedTextColumn mediaWaveform = _constructMediaWaveform();
  GeneratedTextColumn _constructMediaWaveform() {
    return GeneratedTextColumn('media_waveform', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _quoteMessageIdMeta =
      const VerificationMeta('quoteMessageId');
  late final GeneratedTextColumn quoteMessageId = _constructQuoteMessageId();
  GeneratedTextColumn _constructQuoteMessageId() {
    return GeneratedTextColumn('quote_message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _quoteContentMeta =
      const VerificationMeta('quoteContent');
  late final GeneratedTextColumn quoteContent = _constructQuoteContent();
  GeneratedTextColumn _constructQuoteContent() {
    return GeneratedTextColumn('quote_content', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _thumbUrlMeta = const VerificationMeta('thumbUrl');
  late final GeneratedTextColumn thumbUrl = _constructThumbUrl();
  GeneratedTextColumn _constructThumbUrl() {
    return GeneratedTextColumn('thumb_url', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [
        messageId,
        conversationId,
        userId,
        category,
        content,
        mediaUrl,
        mediaMimeType,
        mediaSize,
        mediaDuration,
        mediaWidth,
        mediaHeight,
        mediaHash,
        thumbImage,
        mediaKey,
        mediaDigest,
        mediaStatus,
        status,
        createdAt,
        action,
        participantId,
        snapshotId,
        hyperlink,
        name,
        albumId,
        stickerId,
        sharedUserId,
        mediaWaveform,
        quoteMessageId,
        quoteContent,
        thumbUrl
      ];
  @override
  Messages get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'messages';
  @override
  final String actualTableName = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    context.handle(_categoryMeta, const VerificationResult.success());
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('media_url')) {
      context.handle(_mediaUrlMeta,
          mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta));
    }
    if (data.containsKey('media_mime_type')) {
      context.handle(
          _mediaMimeTypeMeta,
          mediaMimeType.isAcceptableOrUnknown(
              data['media_mime_type']!, _mediaMimeTypeMeta));
    }
    if (data.containsKey('media_size')) {
      context.handle(_mediaSizeMeta,
          mediaSize.isAcceptableOrUnknown(data['media_size']!, _mediaSizeMeta));
    }
    if (data.containsKey('media_duration')) {
      context.handle(
          _mediaDurationMeta,
          mediaDuration.isAcceptableOrUnknown(
              data['media_duration']!, _mediaDurationMeta));
    }
    if (data.containsKey('media_width')) {
      context.handle(
          _mediaWidthMeta,
          mediaWidth.isAcceptableOrUnknown(
              data['media_width']!, _mediaWidthMeta));
    }
    if (data.containsKey('media_height')) {
      context.handle(
          _mediaHeightMeta,
          mediaHeight.isAcceptableOrUnknown(
              data['media_height']!, _mediaHeightMeta));
    }
    if (data.containsKey('media_hash')) {
      context.handle(_mediaHashMeta,
          mediaHash.isAcceptableOrUnknown(data['media_hash']!, _mediaHashMeta));
    }
    if (data.containsKey('thumb_image')) {
      context.handle(
          _thumbImageMeta,
          thumbImage.isAcceptableOrUnknown(
              data['thumb_image']!, _thumbImageMeta));
    }
    if (data.containsKey('media_key')) {
      context.handle(_mediaKeyMeta,
          mediaKey.isAcceptableOrUnknown(data['media_key']!, _mediaKeyMeta));
    }
    if (data.containsKey('media_digest')) {
      context.handle(
          _mediaDigestMeta,
          mediaDigest.isAcceptableOrUnknown(
              data['media_digest']!, _mediaDigestMeta));
    }
    context.handle(_mediaStatusMeta, const VerificationResult.success());
    context.handle(_statusMeta, const VerificationResult.success());
    context.handle(_createdAtMeta, const VerificationResult.success());
    context.handle(_actionMeta, const VerificationResult.success());
    if (data.containsKey('participant_id')) {
      context.handle(
          _participantIdMeta,
          participantId.isAcceptableOrUnknown(
              data['participant_id']!, _participantIdMeta));
    }
    if (data.containsKey('snapshot_id')) {
      context.handle(
          _snapshotIdMeta,
          snapshotId.isAcceptableOrUnknown(
              data['snapshot_id']!, _snapshotIdMeta));
    }
    if (data.containsKey('hyperlink')) {
      context.handle(_hyperlinkMeta,
          hyperlink.isAcceptableOrUnknown(data['hyperlink']!, _hyperlinkMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    }
    if (data.containsKey('sticker_id')) {
      context.handle(_stickerIdMeta,
          stickerId.isAcceptableOrUnknown(data['sticker_id']!, _stickerIdMeta));
    }
    if (data.containsKey('shared_user_id')) {
      context.handle(
          _sharedUserIdMeta,
          sharedUserId.isAcceptableOrUnknown(
              data['shared_user_id']!, _sharedUserIdMeta));
    }
    if (data.containsKey('media_waveform')) {
      context.handle(
          _mediaWaveformMeta,
          mediaWaveform.isAcceptableOrUnknown(
              data['media_waveform']!, _mediaWaveformMeta));
    }
    if (data.containsKey('quote_message_id')) {
      context.handle(
          _quoteMessageIdMeta,
          quoteMessageId.isAcceptableOrUnknown(
              data['quote_message_id']!, _quoteMessageIdMeta));
    }
    if (data.containsKey('quote_content')) {
      context.handle(
          _quoteContentMeta,
          quoteContent.isAcceptableOrUnknown(
              data['quote_content']!, _quoteContentMeta));
    }
    if (data.containsKey('thumb_url')) {
      context.handle(_thumbUrlMeta,
          thumbUrl.isAcceptableOrUnknown(data['thumb_url']!, _thumbUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Message.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Messages createAlias(String alias) {
    return Messages(_db, alias);
  }

  static TypeConverter<MessageCategory, String> $converter0 =
      const MessageCategoryTypeConverter();
  static TypeConverter<MediaStatus, String> $converter1 =
      const MediaStatusTypeConverter();
  static TypeConverter<MessageStatus, String> $converter2 =
      const MessageStatusTypeConverter();
  static TypeConverter<DateTime, int> $converter3 = const MillisDateConverter();
  static TypeConverter<MessageAction, String> $converter4 =
      const MessageActionConverter();
  @override
  List<String> get customConstraints => const [
        'PRIMARY KEY(message_id)',
        'FOREIGN KEY(conversation_id) REFERENCES conversations(conversation_id) ON UPDATE NO ACTION ON DELETE CASCADE'
      ];
  @override
  bool get dontWriteConstraints => true;
}

class Participant extends DataClass implements Insertable<Participant> {
  final String conversationId;
  final String userId;
  final ParticipantRole? role;
  final DateTime createdAt;
  Participant(
      {required this.conversationId,
      required this.userId,
      this.role,
      required this.createdAt});
  factory Participant.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Participant(
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id'])!,
      userId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      role: Participants.$converter0.mapToDart(
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}role'])),
      createdAt: Participants.$converter1.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || role != null) {
      final converter = Participants.$converter0;
      map['role'] = Variable<String?>(converter.mapToSql(role));
    }
    {
      final converter = Participants.$converter1;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    return map;
  }

  ParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ParticipantsCompanion(
      conversationId: Value(conversationId),
      userId: Value(userId),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      createdAt: Value(createdAt),
    );
  }

  factory Participant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Participant(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      role: serializer.fromJson<ParticipantRole?>(json['role']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversation_id': serializer.toJson<String>(conversationId),
      'user_id': serializer.toJson<String>(userId),
      'role': serializer.toJson<ParticipantRole?>(role),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  Participant copyWith(
          {String? conversationId,
          String? userId,
          ParticipantRole? role,
          DateTime? createdAt}) =>
      Participant(
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Participant(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(conversationId.hashCode,
      $mrjc(userId.hashCode, $mrjc(role.hashCode, createdAt.hashCode))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Participant &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.createdAt == this.createdAt);
}

class ParticipantsCompanion extends UpdateCompanion<Participant> {
  final Value<String> conversationId;
  final Value<String> userId;
  final Value<ParticipantRole?> role;
  final Value<DateTime> createdAt;
  const ParticipantsCompanion({
    this.conversationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ParticipantsCompanion.insert({
    required String conversationId,
    required String userId,
    this.role = const Value.absent(),
    required DateTime createdAt,
  })   : conversationId = Value(conversationId),
        userId = Value(userId),
        createdAt = Value(createdAt);
  static Insertable<Participant> custom({
    Expression<String>? conversationId,
    Expression<String>? userId,
    Expression<ParticipantRole?>? role,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ParticipantsCompanion copyWith(
      {Value<String>? conversationId,
      Value<String>? userId,
      Value<ParticipantRole?>? role,
      Value<DateTime>? createdAt}) {
    return ParticipantsCompanion(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      final converter = Participants.$converter0;
      map['role'] = Variable<String?>(converter.mapToSql(role.value));
    }
    if (createdAt.present) {
      final converter = Participants.$converter1;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParticipantsCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class Participants extends Table with TableInfo<Participants, Participant> {
  final GeneratedDatabase _db;
  final String? _alias;
  Participants(this._db, [this._alias]);
  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedTextColumn conversationId = _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedTextColumn role = _constructRole();
  GeneratedTextColumn _constructRole() {
    return GeneratedTextColumn('role', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [conversationId, userId, role, createdAt];
  @override
  Participants get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'participants';
  @override
  final String actualTableName = 'participants';
  @override
  VerificationContext validateIntegrity(Insertable<Participant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    context.handle(_roleMeta, const VerificationResult.success());
    context.handle(_createdAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, userId};
  @override
  Participant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Participant.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Participants createAlias(String alias) {
    return Participants(_db, alias);
  }

  static TypeConverter<ParticipantRole, String> $converter0 =
      const ParticipantRoleConverter();
  static TypeConverter<DateTime, int> $converter1 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const [
        'PRIMARY KEY(conversation_id,user_id)',
        'FOREIGN KEY(conversation_id) REFERENCES conversations(conversation_id) ON UPDATE NO ACTION ON DELETE CASCADE'
      ];
  @override
  bool get dontWriteConstraints => true;
}

class Snapshot extends DataClass implements Insertable<Snapshot> {
  final String snapshotId;
  final String type;
  final String assetId;
  final String amount;
  final DateTime createdAt;
  final String? opponentId;
  final String? transactionHash;
  final String? sender;
  final String? receiver;
  final String? memo;
  final int? confirmations;
  Snapshot(
      {required this.snapshotId,
      required this.type,
      required this.assetId,
      required this.amount,
      required this.createdAt,
      this.opponentId,
      this.transactionHash,
      this.sender,
      this.receiver,
      this.memo,
      this.confirmations});
  factory Snapshot.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Snapshot(
      snapshotId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}snapshot_id'])!,
      type: stringType.mapFromDatabaseResponse(data['${effectivePrefix}type'])!,
      assetId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_id'])!,
      amount:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}amount'])!,
      createdAt: Snapshots.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
      opponentId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}opponent_id']),
      transactionHash: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}transaction_hash']),
      sender:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}sender']),
      receiver: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}receiver']),
      memo: stringType.mapFromDatabaseResponse(data['${effectivePrefix}memo']),
      confirmations: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}confirmations']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['snapshot_id'] = Variable<String>(snapshotId);
    map['type'] = Variable<String>(type);
    map['asset_id'] = Variable<String>(assetId);
    map['amount'] = Variable<String>(amount);
    {
      final converter = Snapshots.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    if (!nullToAbsent || opponentId != null) {
      map['opponent_id'] = Variable<String?>(opponentId);
    }
    if (!nullToAbsent || transactionHash != null) {
      map['transaction_hash'] = Variable<String?>(transactionHash);
    }
    if (!nullToAbsent || sender != null) {
      map['sender'] = Variable<String?>(sender);
    }
    if (!nullToAbsent || receiver != null) {
      map['receiver'] = Variable<String?>(receiver);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String?>(memo);
    }
    if (!nullToAbsent || confirmations != null) {
      map['confirmations'] = Variable<int?>(confirmations);
    }
    return map;
  }

  SnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotsCompanion(
      snapshotId: Value(snapshotId),
      type: Value(type),
      assetId: Value(assetId),
      amount: Value(amount),
      createdAt: Value(createdAt),
      opponentId: opponentId == null && nullToAbsent
          ? const Value.absent()
          : Value(opponentId),
      transactionHash: transactionHash == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionHash),
      sender:
          sender == null && nullToAbsent ? const Value.absent() : Value(sender),
      receiver: receiver == null && nullToAbsent
          ? const Value.absent()
          : Value(receiver),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      confirmations: confirmations == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmations),
    );
  }

  factory Snapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Snapshot(
      snapshotId: serializer.fromJson<String>(json['snapshot_id']),
      type: serializer.fromJson<String>(json['type']),
      assetId: serializer.fromJson<String>(json['asset_id']),
      amount: serializer.fromJson<String>(json['amount']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      opponentId: serializer.fromJson<String?>(json['opponent_id']),
      transactionHash: serializer.fromJson<String?>(json['transaction_hash']),
      sender: serializer.fromJson<String?>(json['sender']),
      receiver: serializer.fromJson<String?>(json['receiver']),
      memo: serializer.fromJson<String?>(json['memo']),
      confirmations: serializer.fromJson<int?>(json['confirmations']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'snapshot_id': serializer.toJson<String>(snapshotId),
      'type': serializer.toJson<String>(type),
      'asset_id': serializer.toJson<String>(assetId),
      'amount': serializer.toJson<String>(amount),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'opponent_id': serializer.toJson<String?>(opponentId),
      'transaction_hash': serializer.toJson<String?>(transactionHash),
      'sender': serializer.toJson<String?>(sender),
      'receiver': serializer.toJson<String?>(receiver),
      'memo': serializer.toJson<String?>(memo),
      'confirmations': serializer.toJson<int?>(confirmations),
    };
  }

  Snapshot copyWith(
          {String? snapshotId,
          String? type,
          String? assetId,
          String? amount,
          DateTime? createdAt,
          String? opponentId,
          String? transactionHash,
          String? sender,
          String? receiver,
          String? memo,
          int? confirmations}) =>
      Snapshot(
        snapshotId: snapshotId ?? this.snapshotId,
        type: type ?? this.type,
        assetId: assetId ?? this.assetId,
        amount: amount ?? this.amount,
        createdAt: createdAt ?? this.createdAt,
        opponentId: opponentId ?? this.opponentId,
        transactionHash: transactionHash ?? this.transactionHash,
        sender: sender ?? this.sender,
        receiver: receiver ?? this.receiver,
        memo: memo ?? this.memo,
        confirmations: confirmations ?? this.confirmations,
      );
  @override
  String toString() {
    return (StringBuffer('Snapshot(')
          ..write('snapshotId: $snapshotId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('opponentId: $opponentId, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('sender: $sender, ')
          ..write('receiver: $receiver, ')
          ..write('memo: $memo, ')
          ..write('confirmations: $confirmations')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      snapshotId.hashCode,
      $mrjc(
          type.hashCode,
          $mrjc(
              assetId.hashCode,
              $mrjc(
                  amount.hashCode,
                  $mrjc(
                      createdAt.hashCode,
                      $mrjc(
                          opponentId.hashCode,
                          $mrjc(
                              transactionHash.hashCode,
                              $mrjc(
                                  sender.hashCode,
                                  $mrjc(
                                      receiver.hashCode,
                                      $mrjc(memo.hashCode,
                                          confirmations.hashCode)))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Snapshot &&
          other.snapshotId == this.snapshotId &&
          other.type == this.type &&
          other.assetId == this.assetId &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt &&
          other.opponentId == this.opponentId &&
          other.transactionHash == this.transactionHash &&
          other.sender == this.sender &&
          other.receiver == this.receiver &&
          other.memo == this.memo &&
          other.confirmations == this.confirmations);
}

class SnapshotsCompanion extends UpdateCompanion<Snapshot> {
  final Value<String> snapshotId;
  final Value<String> type;
  final Value<String> assetId;
  final Value<String> amount;
  final Value<DateTime> createdAt;
  final Value<String?> opponentId;
  final Value<String?> transactionHash;
  final Value<String?> sender;
  final Value<String?> receiver;
  final Value<String?> memo;
  final Value<int?> confirmations;
  const SnapshotsCompanion({
    this.snapshotId = const Value.absent(),
    this.type = const Value.absent(),
    this.assetId = const Value.absent(),
    this.amount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.opponentId = const Value.absent(),
    this.transactionHash = const Value.absent(),
    this.sender = const Value.absent(),
    this.receiver = const Value.absent(),
    this.memo = const Value.absent(),
    this.confirmations = const Value.absent(),
  });
  SnapshotsCompanion.insert({
    required String snapshotId,
    required String type,
    required String assetId,
    required String amount,
    required DateTime createdAt,
    this.opponentId = const Value.absent(),
    this.transactionHash = const Value.absent(),
    this.sender = const Value.absent(),
    this.receiver = const Value.absent(),
    this.memo = const Value.absent(),
    this.confirmations = const Value.absent(),
  })  : snapshotId = Value(snapshotId),
        type = Value(type),
        assetId = Value(assetId),
        amount = Value(amount),
        createdAt = Value(createdAt);
  static Insertable<Snapshot> custom({
    Expression<String>? snapshotId,
    Expression<String>? type,
    Expression<String>? assetId,
    Expression<String>? amount,
    Expression<DateTime>? createdAt,
    Expression<String?>? opponentId,
    Expression<String?>? transactionHash,
    Expression<String?>? sender,
    Expression<String?>? receiver,
    Expression<String?>? memo,
    Expression<int?>? confirmations,
  }) {
    return RawValuesInsertable({
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (type != null) 'type': type,
      if (assetId != null) 'asset_id': assetId,
      if (amount != null) 'amount': amount,
      if (createdAt != null) 'created_at': createdAt,
      if (opponentId != null) 'opponent_id': opponentId,
      if (transactionHash != null) 'transaction_hash': transactionHash,
      if (sender != null) 'sender': sender,
      if (receiver != null) 'receiver': receiver,
      if (memo != null) 'memo': memo,
      if (confirmations != null) 'confirmations': confirmations,
    });
  }

  SnapshotsCompanion copyWith(
      {Value<String>? snapshotId,
      Value<String>? type,
      Value<String>? assetId,
      Value<String>? amount,
      Value<DateTime>? createdAt,
      Value<String?>? opponentId,
      Value<String?>? transactionHash,
      Value<String?>? sender,
      Value<String?>? receiver,
      Value<String?>? memo,
      Value<int?>? confirmations}) {
    return SnapshotsCompanion(
      snapshotId: snapshotId ?? this.snapshotId,
      type: type ?? this.type,
      assetId: assetId ?? this.assetId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      opponentId: opponentId ?? this.opponentId,
      transactionHash: transactionHash ?? this.transactionHash,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      memo: memo ?? this.memo,
      confirmations: confirmations ?? this.confirmations,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<String>(snapshotId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (createdAt.present) {
      final converter = Snapshots.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    if (opponentId.present) {
      map['opponent_id'] = Variable<String?>(opponentId.value);
    }
    if (transactionHash.present) {
      map['transaction_hash'] = Variable<String?>(transactionHash.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String?>(sender.value);
    }
    if (receiver.present) {
      map['receiver'] = Variable<String?>(receiver.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String?>(memo.value);
    }
    if (confirmations.present) {
      map['confirmations'] = Variable<int?>(confirmations.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotsCompanion(')
          ..write('snapshotId: $snapshotId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('opponentId: $opponentId, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('sender: $sender, ')
          ..write('receiver: $receiver, ')
          ..write('memo: $memo, ')
          ..write('confirmations: $confirmations')
          ..write(')'))
        .toString();
  }
}

class Snapshots extends Table with TableInfo<Snapshots, Snapshot> {
  final GeneratedDatabase _db;
  final String? _alias;
  Snapshots(this._db, [this._alias]);
  final VerificationMeta _snapshotIdMeta = const VerificationMeta('snapshotId');
  late final GeneratedTextColumn snapshotId = _constructSnapshotId();
  GeneratedTextColumn _constructSnapshotId() {
    return GeneratedTextColumn('snapshot_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedTextColumn type = _constructType();
  GeneratedTextColumn _constructType() {
    return GeneratedTextColumn('type', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _assetIdMeta = const VerificationMeta('assetId');
  late final GeneratedTextColumn assetId = _constructAssetId();
  GeneratedTextColumn _constructAssetId() {
    return GeneratedTextColumn('asset_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _amountMeta = const VerificationMeta('amount');
  late final GeneratedTextColumn amount = _constructAmount();
  GeneratedTextColumn _constructAmount() {
    return GeneratedTextColumn('amount', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _opponentIdMeta = const VerificationMeta('opponentId');
  late final GeneratedTextColumn opponentId = _constructOpponentId();
  GeneratedTextColumn _constructOpponentId() {
    return GeneratedTextColumn('opponent_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _transactionHashMeta =
      const VerificationMeta('transactionHash');
  late final GeneratedTextColumn transactionHash = _constructTransactionHash();
  GeneratedTextColumn _constructTransactionHash() {
    return GeneratedTextColumn('transaction_hash', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _senderMeta = const VerificationMeta('sender');
  late final GeneratedTextColumn sender = _constructSender();
  GeneratedTextColumn _constructSender() {
    return GeneratedTextColumn('sender', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _receiverMeta = const VerificationMeta('receiver');
  late final GeneratedTextColumn receiver = _constructReceiver();
  GeneratedTextColumn _constructReceiver() {
    return GeneratedTextColumn('receiver', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedTextColumn memo = _constructMemo();
  GeneratedTextColumn _constructMemo() {
    return GeneratedTextColumn('memo', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _confirmationsMeta =
      const VerificationMeta('confirmations');
  late final GeneratedIntColumn confirmations = _constructConfirmations();
  GeneratedIntColumn _constructConfirmations() {
    return GeneratedIntColumn('confirmations', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [
        snapshotId,
        type,
        assetId,
        amount,
        createdAt,
        opponentId,
        transactionHash,
        sender,
        receiver,
        memo,
        confirmations
      ];
  @override
  Snapshots get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'snapshots';
  @override
  final String actualTableName = 'snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<Snapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('snapshot_id')) {
      context.handle(
          _snapshotIdMeta,
          snapshotId.isAcceptableOrUnknown(
              data['snapshot_id']!, _snapshotIdMeta));
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    if (data.containsKey('opponent_id')) {
      context.handle(
          _opponentIdMeta,
          opponentId.isAcceptableOrUnknown(
              data['opponent_id']!, _opponentIdMeta));
    }
    if (data.containsKey('transaction_hash')) {
      context.handle(
          _transactionHashMeta,
          transactionHash.isAcceptableOrUnknown(
              data['transaction_hash']!, _transactionHashMeta));
    }
    if (data.containsKey('sender')) {
      context.handle(_senderMeta,
          sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    }
    if (data.containsKey('receiver')) {
      context.handle(_receiverMeta,
          receiver.isAcceptableOrUnknown(data['receiver']!, _receiverMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('confirmations')) {
      context.handle(
          _confirmationsMeta,
          confirmations.isAcceptableOrUnknown(
              data['confirmations']!, _confirmationsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {snapshotId};
  @override
  Snapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Snapshot.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Snapshots createAlias(String alias) {
    return Snapshots(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(snapshot_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class User extends DataClass implements Insertable<User> {
  final String userId;
  final String identityNumber;
  final UserRelationship relationship;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final int? isVerified;
  final DateTime? createdAt;
  final DateTime? muteUntil;
  final int? hasPin;
  final String? appId;
  final String? biography;
  final int? isScam;
  User(
      {required this.userId,
      required this.identityNumber,
      required this.relationship,
      this.fullName,
      this.avatarUrl,
      this.phone,
      this.isVerified,
      this.createdAt,
      this.muteUntil,
      this.hasPin,
      this.appId,
      this.biography,
      this.isScam});
  factory User.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return User(
      userId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      identityNumber: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}identity_number'])!,
      relationship: Users.$converter0.mapToDart(stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}relationship']))!,
      fullName: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}full_name']),
      avatarUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}avatar_url']),
      phone:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}phone']),
      isVerified: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}is_verified']),
      createdAt: Users.$converter1.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at'])),
      muteUntil: Users.$converter2.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}mute_until'])),
      hasPin:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}has_pin']),
      appId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}app_id']),
      biography: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}biography']),
      isScam:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}is_scam']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['identity_number'] = Variable<String>(identityNumber);
    {
      final converter = Users.$converter0;
      map['relationship'] = Variable<String>(converter.mapToSql(relationship)!);
    }
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String?>(fullName);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String?>(avatarUrl);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String?>(phone);
    }
    if (!nullToAbsent || isVerified != null) {
      map['is_verified'] = Variable<int?>(isVerified);
    }
    if (!nullToAbsent || createdAt != null) {
      final converter = Users.$converter1;
      map['created_at'] = Variable<int?>(converter.mapToSql(createdAt));
    }
    if (!nullToAbsent || muteUntil != null) {
      final converter = Users.$converter2;
      map['mute_until'] = Variable<int?>(converter.mapToSql(muteUntil));
    }
    if (!nullToAbsent || hasPin != null) {
      map['has_pin'] = Variable<int?>(hasPin);
    }
    if (!nullToAbsent || appId != null) {
      map['app_id'] = Variable<String?>(appId);
    }
    if (!nullToAbsent || biography != null) {
      map['biography'] = Variable<String?>(biography);
    }
    if (!nullToAbsent || isScam != null) {
      map['is_scam'] = Variable<int?>(isScam);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      userId: Value(userId),
      identityNumber: Value(identityNumber),
      relationship: Value(relationship),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      isVerified: isVerified == null && nullToAbsent
          ? const Value.absent()
          : Value(isVerified),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      muteUntil: muteUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(muteUntil),
      hasPin:
          hasPin == null && nullToAbsent ? const Value.absent() : Value(hasPin),
      appId:
          appId == null && nullToAbsent ? const Value.absent() : Value(appId),
      biography: biography == null && nullToAbsent
          ? const Value.absent()
          : Value(biography),
      isScam:
          isScam == null && nullToAbsent ? const Value.absent() : Value(isScam),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return User(
      userId: serializer.fromJson<String>(json['user_id']),
      identityNumber: serializer.fromJson<String>(json['identity_number']),
      relationship: serializer.fromJson<UserRelationship>(json['relationship']),
      fullName: serializer.fromJson<String?>(json['full_name']),
      avatarUrl: serializer.fromJson<String?>(json['avatar_url']),
      phone: serializer.fromJson<String?>(json['phone']),
      isVerified: serializer.fromJson<int?>(json['is_verified']),
      createdAt: serializer.fromJson<DateTime?>(json['created_at']),
      muteUntil: serializer.fromJson<DateTime?>(json['mute_until']),
      hasPin: serializer.fromJson<int?>(json['has_pin']),
      appId: serializer.fromJson<String?>(json['app_id']),
      biography: serializer.fromJson<String?>(json['biography']),
      isScam: serializer.fromJson<int?>(json['is_scam']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'user_id': serializer.toJson<String>(userId),
      'identity_number': serializer.toJson<String>(identityNumber),
      'relationship': serializer.toJson<UserRelationship>(relationship),
      'full_name': serializer.toJson<String?>(fullName),
      'avatar_url': serializer.toJson<String?>(avatarUrl),
      'phone': serializer.toJson<String?>(phone),
      'is_verified': serializer.toJson<int?>(isVerified),
      'created_at': serializer.toJson<DateTime?>(createdAt),
      'mute_until': serializer.toJson<DateTime?>(muteUntil),
      'has_pin': serializer.toJson<int?>(hasPin),
      'app_id': serializer.toJson<String?>(appId),
      'biography': serializer.toJson<String?>(biography),
      'is_scam': serializer.toJson<int?>(isScam),
    };
  }

  User copyWith(
          {String? userId,
          String? identityNumber,
          UserRelationship? relationship,
          String? fullName,
          String? avatarUrl,
          String? phone,
          int? isVerified,
          DateTime? createdAt,
          DateTime? muteUntil,
          int? hasPin,
          String? appId,
          String? biography,
          int? isScam}) =>
      User(
        userId: userId ?? this.userId,
        identityNumber: identityNumber ?? this.identityNumber,
        relationship: relationship ?? this.relationship,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        isVerified: isVerified ?? this.isVerified,
        createdAt: createdAt ?? this.createdAt,
        muteUntil: muteUntil ?? this.muteUntil,
        hasPin: hasPin ?? this.hasPin,
        appId: appId ?? this.appId,
        biography: biography ?? this.biography,
        isScam: isScam ?? this.isScam,
      );
  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('userId: $userId, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('relationship: $relationship, ')
          ..write('fullName: $fullName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('phone: $phone, ')
          ..write('isVerified: $isVerified, ')
          ..write('createdAt: $createdAt, ')
          ..write('muteUntil: $muteUntil, ')
          ..write('hasPin: $hasPin, ')
          ..write('appId: $appId, ')
          ..write('biography: $biography, ')
          ..write('isScam: $isScam')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      userId.hashCode,
      $mrjc(
          identityNumber.hashCode,
          $mrjc(
              relationship.hashCode,
              $mrjc(
                  fullName.hashCode,
                  $mrjc(
                      avatarUrl.hashCode,
                      $mrjc(
                          phone.hashCode,
                          $mrjc(
                              isVerified.hashCode,
                              $mrjc(
                                  createdAt.hashCode,
                                  $mrjc(
                                      muteUntil.hashCode,
                                      $mrjc(
                                          hasPin.hashCode,
                                          $mrjc(
                                              appId.hashCode,
                                              $mrjc(biography.hashCode,
                                                  isScam.hashCode)))))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is User &&
          other.userId == this.userId &&
          other.identityNumber == this.identityNumber &&
          other.relationship == this.relationship &&
          other.fullName == this.fullName &&
          other.avatarUrl == this.avatarUrl &&
          other.phone == this.phone &&
          other.isVerified == this.isVerified &&
          other.createdAt == this.createdAt &&
          other.muteUntil == this.muteUntil &&
          other.hasPin == this.hasPin &&
          other.appId == this.appId &&
          other.biography == this.biography &&
          other.isScam == this.isScam);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> userId;
  final Value<String> identityNumber;
  final Value<UserRelationship> relationship;
  final Value<String?> fullName;
  final Value<String?> avatarUrl;
  final Value<String?> phone;
  final Value<int?> isVerified;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> muteUntil;
  final Value<int?> hasPin;
  final Value<String?> appId;
  final Value<String?> biography;
  final Value<int?> isScam;
  const UsersCompanion({
    this.userId = const Value.absent(),
    this.identityNumber = const Value.absent(),
    this.relationship = const Value.absent(),
    this.fullName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.phone = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.muteUntil = const Value.absent(),
    this.hasPin = const Value.absent(),
    this.appId = const Value.absent(),
    this.biography = const Value.absent(),
    this.isScam = const Value.absent(),
  });
  UsersCompanion.insert({
    required String userId,
    required String identityNumber,
    required UserRelationship relationship,
    this.fullName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.phone = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.muteUntil = const Value.absent(),
    this.hasPin = const Value.absent(),
    this.appId = const Value.absent(),
    this.biography = const Value.absent(),
    this.isScam = const Value.absent(),
  })  : userId = Value(userId),
        identityNumber = Value(identityNumber),
        relationship = Value(relationship);
  static Insertable<User> custom({
    Expression<String>? userId,
    Expression<String>? identityNumber,
    Expression<UserRelationship>? relationship,
    Expression<String?>? fullName,
    Expression<String?>? avatarUrl,
    Expression<String?>? phone,
    Expression<int?>? isVerified,
    Expression<DateTime?>? createdAt,
    Expression<DateTime?>? muteUntil,
    Expression<int?>? hasPin,
    Expression<String?>? appId,
    Expression<String?>? biography,
    Expression<int?>? isScam,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (identityNumber != null) 'identity_number': identityNumber,
      if (relationship != null) 'relationship': relationship,
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phone != null) 'phone': phone,
      if (isVerified != null) 'is_verified': isVerified,
      if (createdAt != null) 'created_at': createdAt,
      if (muteUntil != null) 'mute_until': muteUntil,
      if (hasPin != null) 'has_pin': hasPin,
      if (appId != null) 'app_id': appId,
      if (biography != null) 'biography': biography,
      if (isScam != null) 'is_scam': isScam,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? userId,
      Value<String>? identityNumber,
      Value<UserRelationship>? relationship,
      Value<String?>? fullName,
      Value<String?>? avatarUrl,
      Value<String?>? phone,
      Value<int?>? isVerified,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? muteUntil,
      Value<int?>? hasPin,
      Value<String?>? appId,
      Value<String?>? biography,
      Value<int?>? isScam}) {
    return UsersCompanion(
      userId: userId ?? this.userId,
      identityNumber: identityNumber ?? this.identityNumber,
      relationship: relationship ?? this.relationship,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      muteUntil: muteUntil ?? this.muteUntil,
      hasPin: hasPin ?? this.hasPin,
      appId: appId ?? this.appId,
      biography: biography ?? this.biography,
      isScam: isScam ?? this.isScam,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (identityNumber.present) {
      map['identity_number'] = Variable<String>(identityNumber.value);
    }
    if (relationship.present) {
      final converter = Users.$converter0;
      map['relationship'] =
          Variable<String>(converter.mapToSql(relationship.value)!);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String?>(fullName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String?>(avatarUrl.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String?>(phone.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<int?>(isVerified.value);
    }
    if (createdAt.present) {
      final converter = Users.$converter1;
      map['created_at'] = Variable<int?>(converter.mapToSql(createdAt.value));
    }
    if (muteUntil.present) {
      final converter = Users.$converter2;
      map['mute_until'] = Variable<int?>(converter.mapToSql(muteUntil.value));
    }
    if (hasPin.present) {
      map['has_pin'] = Variable<int?>(hasPin.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String?>(appId.value);
    }
    if (biography.present) {
      map['biography'] = Variable<String?>(biography.value);
    }
    if (isScam.present) {
      map['is_scam'] = Variable<int?>(isScam.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('userId: $userId, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('relationship: $relationship, ')
          ..write('fullName: $fullName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('phone: $phone, ')
          ..write('isVerified: $isVerified, ')
          ..write('createdAt: $createdAt, ')
          ..write('muteUntil: $muteUntil, ')
          ..write('hasPin: $hasPin, ')
          ..write('appId: $appId, ')
          ..write('biography: $biography, ')
          ..write('isScam: $isScam')
          ..write(')'))
        .toString();
  }
}

class Users extends Table with TableInfo<Users, User> {
  final GeneratedDatabase _db;
  final String? _alias;
  Users(this._db, [this._alias]);
  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _identityNumberMeta =
      const VerificationMeta('identityNumber');
  late final GeneratedTextColumn identityNumber = _constructIdentityNumber();
  GeneratedTextColumn _constructIdentityNumber() {
    return GeneratedTextColumn('identity_number', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _relationshipMeta =
      const VerificationMeta('relationship');
  late final GeneratedTextColumn relationship = _constructRelationship();
  GeneratedTextColumn _constructRelationship() {
    return GeneratedTextColumn('relationship', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _fullNameMeta = const VerificationMeta('fullName');
  late final GeneratedTextColumn fullName = _constructFullName();
  GeneratedTextColumn _constructFullName() {
    return GeneratedTextColumn('full_name', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _avatarUrlMeta = const VerificationMeta('avatarUrl');
  late final GeneratedTextColumn avatarUrl = _constructAvatarUrl();
  GeneratedTextColumn _constructAvatarUrl() {
    return GeneratedTextColumn('avatar_url', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _phoneMeta = const VerificationMeta('phone');
  late final GeneratedTextColumn phone = _constructPhone();
  GeneratedTextColumn _constructPhone() {
    return GeneratedTextColumn('phone', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _isVerifiedMeta = const VerificationMeta('isVerified');
  late final GeneratedIntColumn isVerified = _constructIsVerified();
  GeneratedIntColumn _constructIsVerified() {
    return GeneratedIntColumn('is_verified', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _muteUntilMeta = const VerificationMeta('muteUntil');
  late final GeneratedIntColumn muteUntil = _constructMuteUntil();
  GeneratedIntColumn _constructMuteUntil() {
    return GeneratedIntColumn('mute_until', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _hasPinMeta = const VerificationMeta('hasPin');
  late final GeneratedIntColumn hasPin = _constructHasPin();
  GeneratedIntColumn _constructHasPin() {
    return GeneratedIntColumn('has_pin', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _appIdMeta = const VerificationMeta('appId');
  late final GeneratedTextColumn appId = _constructAppId();
  GeneratedTextColumn _constructAppId() {
    return GeneratedTextColumn('app_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _biographyMeta = const VerificationMeta('biography');
  late final GeneratedTextColumn biography = _constructBiography();
  GeneratedTextColumn _constructBiography() {
    return GeneratedTextColumn('biography', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _isScamMeta = const VerificationMeta('isScam');
  late final GeneratedIntColumn isScam = _constructIsScam();
  GeneratedIntColumn _constructIsScam() {
    return GeneratedIntColumn('is_scam', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [
        userId,
        identityNumber,
        relationship,
        fullName,
        avatarUrl,
        phone,
        isVerified,
        createdAt,
        muteUntil,
        hasPin,
        appId,
        biography,
        isScam
      ];
  @override
  Users get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'users';
  @override
  final String actualTableName = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('identity_number')) {
      context.handle(
          _identityNumberMeta,
          identityNumber.isAcceptableOrUnknown(
              data['identity_number']!, _identityNumberMeta));
    } else if (isInserting) {
      context.missing(_identityNumberMeta);
    }
    context.handle(_relationshipMeta, const VerificationResult.success());
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('is_verified')) {
      context.handle(
          _isVerifiedMeta,
          isVerified.isAcceptableOrUnknown(
              data['is_verified']!, _isVerifiedMeta));
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    context.handle(_muteUntilMeta, const VerificationResult.success());
    if (data.containsKey('has_pin')) {
      context.handle(_hasPinMeta,
          hasPin.isAcceptableOrUnknown(data['has_pin']!, _hasPinMeta));
    }
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    }
    if (data.containsKey('biography')) {
      context.handle(_biographyMeta,
          biography.isAcceptableOrUnknown(data['biography']!, _biographyMeta));
    }
    if (data.containsKey('is_scam')) {
      context.handle(_isScamMeta,
          isScam.isAcceptableOrUnknown(data['is_scam']!, _isScamMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return User.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Users createAlias(String alias) {
    return Users(_db, alias);
  }

  static TypeConverter<UserRelationship, String> $converter0 =
      const UserRelationshipConverter();
  static TypeConverter<DateTime, int> $converter1 = const MillisDateConverter();
  static TypeConverter<DateTime, int> $converter2 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(user_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Addresse extends DataClass implements Insertable<Addresse> {
  final String addressId;
  final String type;
  final String assetId;
  final String? publicKey;
  final String? label;
  final DateTime updatedAt;
  final String reserve;
  final String fee;
  final String? accountName;
  final String? accountTag;
  final String? dust;
  Addresse(
      {required this.addressId,
      required this.type,
      required this.assetId,
      this.publicKey,
      this.label,
      required this.updatedAt,
      required this.reserve,
      required this.fee,
      this.accountName,
      this.accountTag,
      this.dust});
  factory Addresse.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Addresse(
      addressId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}address_id'])!,
      type: stringType.mapFromDatabaseResponse(data['${effectivePrefix}type'])!,
      assetId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_id'])!,
      publicKey: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}public_key']),
      label:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}label']),
      updatedAt: Addresses.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}updated_at']))!,
      reserve: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}reserve'])!,
      fee: stringType.mapFromDatabaseResponse(data['${effectivePrefix}fee'])!,
      accountName: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}account_name']),
      accountTag: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}account_tag']),
      dust: stringType.mapFromDatabaseResponse(data['${effectivePrefix}dust']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['address_id'] = Variable<String>(addressId);
    map['type'] = Variable<String>(type);
    map['asset_id'] = Variable<String>(assetId);
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String?>(publicKey);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String?>(label);
    }
    {
      final converter = Addresses.$converter0;
      map['updated_at'] = Variable<int>(converter.mapToSql(updatedAt)!);
    }
    map['reserve'] = Variable<String>(reserve);
    map['fee'] = Variable<String>(fee);
    if (!nullToAbsent || accountName != null) {
      map['account_name'] = Variable<String?>(accountName);
    }
    if (!nullToAbsent || accountTag != null) {
      map['account_tag'] = Variable<String?>(accountTag);
    }
    if (!nullToAbsent || dust != null) {
      map['dust'] = Variable<String?>(dust);
    }
    return map;
  }

  AddressesCompanion toCompanion(bool nullToAbsent) {
    return AddressesCompanion(
      addressId: Value(addressId),
      type: Value(type),
      assetId: Value(assetId),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
      updatedAt: Value(updatedAt),
      reserve: Value(reserve),
      fee: Value(fee),
      accountName: accountName == null && nullToAbsent
          ? const Value.absent()
          : Value(accountName),
      accountTag: accountTag == null && nullToAbsent
          ? const Value.absent()
          : Value(accountTag),
      dust: dust == null && nullToAbsent ? const Value.absent() : Value(dust),
    );
  }

  factory Addresse.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Addresse(
      addressId: serializer.fromJson<String>(json['address_id']),
      type: serializer.fromJson<String>(json['type']),
      assetId: serializer.fromJson<String>(json['asset_id']),
      publicKey: serializer.fromJson<String?>(json['public_key']),
      label: serializer.fromJson<String?>(json['label']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      reserve: serializer.fromJson<String>(json['reserve']),
      fee: serializer.fromJson<String>(json['fee']),
      accountName: serializer.fromJson<String?>(json['account_name']),
      accountTag: serializer.fromJson<String?>(json['account_tag']),
      dust: serializer.fromJson<String?>(json['dust']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'address_id': serializer.toJson<String>(addressId),
      'type': serializer.toJson<String>(type),
      'asset_id': serializer.toJson<String>(assetId),
      'public_key': serializer.toJson<String?>(publicKey),
      'label': serializer.toJson<String?>(label),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'reserve': serializer.toJson<String>(reserve),
      'fee': serializer.toJson<String>(fee),
      'account_name': serializer.toJson<String?>(accountName),
      'account_tag': serializer.toJson<String?>(accountTag),
      'dust': serializer.toJson<String?>(dust),
    };
  }

  Addresse copyWith(
          {String? addressId,
          String? type,
          String? assetId,
          String? publicKey,
          String? label,
          DateTime? updatedAt,
          String? reserve,
          String? fee,
          String? accountName,
          String? accountTag,
          String? dust}) =>
      Addresse(
        addressId: addressId ?? this.addressId,
        type: type ?? this.type,
        assetId: assetId ?? this.assetId,
        publicKey: publicKey ?? this.publicKey,
        label: label ?? this.label,
        updatedAt: updatedAt ?? this.updatedAt,
        reserve: reserve ?? this.reserve,
        fee: fee ?? this.fee,
        accountName: accountName ?? this.accountName,
        accountTag: accountTag ?? this.accountTag,
        dust: dust ?? this.dust,
      );
  @override
  String toString() {
    return (StringBuffer('Addresse(')
          ..write('addressId: $addressId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('publicKey: $publicKey, ')
          ..write('label: $label, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('reserve: $reserve, ')
          ..write('fee: $fee, ')
          ..write('accountName: $accountName, ')
          ..write('accountTag: $accountTag, ')
          ..write('dust: $dust')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      addressId.hashCode,
      $mrjc(
          type.hashCode,
          $mrjc(
              assetId.hashCode,
              $mrjc(
                  publicKey.hashCode,
                  $mrjc(
                      label.hashCode,
                      $mrjc(
                          updatedAt.hashCode,
                          $mrjc(
                              reserve.hashCode,
                              $mrjc(
                                  fee.hashCode,
                                  $mrjc(
                                      accountName.hashCode,
                                      $mrjc(accountTag.hashCode,
                                          dust.hashCode)))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Addresse &&
          other.addressId == this.addressId &&
          other.type == this.type &&
          other.assetId == this.assetId &&
          other.publicKey == this.publicKey &&
          other.label == this.label &&
          other.updatedAt == this.updatedAt &&
          other.reserve == this.reserve &&
          other.fee == this.fee &&
          other.accountName == this.accountName &&
          other.accountTag == this.accountTag &&
          other.dust == this.dust);
}

class AddressesCompanion extends UpdateCompanion<Addresse> {
  final Value<String> addressId;
  final Value<String> type;
  final Value<String> assetId;
  final Value<String?> publicKey;
  final Value<String?> label;
  final Value<DateTime> updatedAt;
  final Value<String> reserve;
  final Value<String> fee;
  final Value<String?> accountName;
  final Value<String?> accountTag;
  final Value<String?> dust;
  const AddressesCompanion({
    this.addressId = const Value.absent(),
    this.type = const Value.absent(),
    this.assetId = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.label = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.reserve = const Value.absent(),
    this.fee = const Value.absent(),
    this.accountName = const Value.absent(),
    this.accountTag = const Value.absent(),
    this.dust = const Value.absent(),
  });
  AddressesCompanion.insert({
    required String addressId,
    required String type,
    required String assetId,
    this.publicKey = const Value.absent(),
    this.label = const Value.absent(),
    required DateTime updatedAt,
    required String reserve,
    required String fee,
    this.accountName = const Value.absent(),
    this.accountTag = const Value.absent(),
    this.dust = const Value.absent(),
  })  : addressId = Value(addressId),
        type = Value(type),
        assetId = Value(assetId),
        updatedAt = Value(updatedAt),
        reserve = Value(reserve),
        fee = Value(fee);
  static Insertable<Addresse> custom({
    Expression<String>? addressId,
    Expression<String>? type,
    Expression<String>? assetId,
    Expression<String?>? publicKey,
    Expression<String?>? label,
    Expression<DateTime>? updatedAt,
    Expression<String>? reserve,
    Expression<String>? fee,
    Expression<String?>? accountName,
    Expression<String?>? accountTag,
    Expression<String?>? dust,
  }) {
    return RawValuesInsertable({
      if (addressId != null) 'address_id': addressId,
      if (type != null) 'type': type,
      if (assetId != null) 'asset_id': assetId,
      if (publicKey != null) 'public_key': publicKey,
      if (label != null) 'label': label,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (reserve != null) 'reserve': reserve,
      if (fee != null) 'fee': fee,
      if (accountName != null) 'account_name': accountName,
      if (accountTag != null) 'account_tag': accountTag,
      if (dust != null) 'dust': dust,
    });
  }

  AddressesCompanion copyWith(
      {Value<String>? addressId,
      Value<String>? type,
      Value<String>? assetId,
      Value<String?>? publicKey,
      Value<String?>? label,
      Value<DateTime>? updatedAt,
      Value<String>? reserve,
      Value<String>? fee,
      Value<String?>? accountName,
      Value<String?>? accountTag,
      Value<String?>? dust}) {
    return AddressesCompanion(
      addressId: addressId ?? this.addressId,
      type: type ?? this.type,
      assetId: assetId ?? this.assetId,
      publicKey: publicKey ?? this.publicKey,
      label: label ?? this.label,
      updatedAt: updatedAt ?? this.updatedAt,
      reserve: reserve ?? this.reserve,
      fee: fee ?? this.fee,
      accountName: accountName ?? this.accountName,
      accountTag: accountTag ?? this.accountTag,
      dust: dust ?? this.dust,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (addressId.present) {
      map['address_id'] = Variable<String>(addressId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String?>(publicKey.value);
    }
    if (label.present) {
      map['label'] = Variable<String?>(label.value);
    }
    if (updatedAt.present) {
      final converter = Addresses.$converter0;
      map['updated_at'] = Variable<int>(converter.mapToSql(updatedAt.value)!);
    }
    if (reserve.present) {
      map['reserve'] = Variable<String>(reserve.value);
    }
    if (fee.present) {
      map['fee'] = Variable<String>(fee.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String?>(accountName.value);
    }
    if (accountTag.present) {
      map['account_tag'] = Variable<String?>(accountTag.value);
    }
    if (dust.present) {
      map['dust'] = Variable<String?>(dust.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AddressesCompanion(')
          ..write('addressId: $addressId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('publicKey: $publicKey, ')
          ..write('label: $label, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('reserve: $reserve, ')
          ..write('fee: $fee, ')
          ..write('accountName: $accountName, ')
          ..write('accountTag: $accountTag, ')
          ..write('dust: $dust')
          ..write(')'))
        .toString();
  }
}

class Addresses extends Table with TableInfo<Addresses, Addresse> {
  final GeneratedDatabase _db;
  final String? _alias;
  Addresses(this._db, [this._alias]);
  final VerificationMeta _addressIdMeta = const VerificationMeta('addressId');
  late final GeneratedTextColumn addressId = _constructAddressId();
  GeneratedTextColumn _constructAddressId() {
    return GeneratedTextColumn('address_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedTextColumn type = _constructType();
  GeneratedTextColumn _constructType() {
    return GeneratedTextColumn('type', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _assetIdMeta = const VerificationMeta('assetId');
  late final GeneratedTextColumn assetId = _constructAssetId();
  GeneratedTextColumn _constructAssetId() {
    return GeneratedTextColumn('asset_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _publicKeyMeta = const VerificationMeta('publicKey');
  late final GeneratedTextColumn publicKey = _constructPublicKey();
  GeneratedTextColumn _constructPublicKey() {
    return GeneratedTextColumn('public_key', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _labelMeta = const VerificationMeta('label');
  late final GeneratedTextColumn label = _constructLabel();
  GeneratedTextColumn _constructLabel() {
    return GeneratedTextColumn('label', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedIntColumn updatedAt = _constructUpdatedAt();
  GeneratedIntColumn _constructUpdatedAt() {
    return GeneratedIntColumn('updated_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _reserveMeta = const VerificationMeta('reserve');
  late final GeneratedTextColumn reserve = _constructReserve();
  GeneratedTextColumn _constructReserve() {
    return GeneratedTextColumn('reserve', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _feeMeta = const VerificationMeta('fee');
  late final GeneratedTextColumn fee = _constructFee();
  GeneratedTextColumn _constructFee() {
    return GeneratedTextColumn('fee', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _accountNameMeta =
      const VerificationMeta('accountName');
  late final GeneratedTextColumn accountName = _constructAccountName();
  GeneratedTextColumn _constructAccountName() {
    return GeneratedTextColumn('account_name', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _accountTagMeta = const VerificationMeta('accountTag');
  late final GeneratedTextColumn accountTag = _constructAccountTag();
  GeneratedTextColumn _constructAccountTag() {
    return GeneratedTextColumn('account_tag', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _dustMeta = const VerificationMeta('dust');
  late final GeneratedTextColumn dust = _constructDust();
  GeneratedTextColumn _constructDust() {
    return GeneratedTextColumn('dust', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [
        addressId,
        type,
        assetId,
        publicKey,
        label,
        updatedAt,
        reserve,
        fee,
        accountName,
        accountTag,
        dust
      ];
  @override
  Addresses get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'addresses';
  @override
  final String actualTableName = 'addresses';
  @override
  VerificationContext validateIntegrity(Insertable<Addresse> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('address_id')) {
      context.handle(_addressIdMeta,
          addressId.isAcceptableOrUnknown(data['address_id']!, _addressIdMeta));
    } else if (isInserting) {
      context.missing(_addressIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    context.handle(_updatedAtMeta, const VerificationResult.success());
    if (data.containsKey('reserve')) {
      context.handle(_reserveMeta,
          reserve.isAcceptableOrUnknown(data['reserve']!, _reserveMeta));
    } else if (isInserting) {
      context.missing(_reserveMeta);
    }
    if (data.containsKey('fee')) {
      context.handle(
          _feeMeta, fee.isAcceptableOrUnknown(data['fee']!, _feeMeta));
    } else if (isInserting) {
      context.missing(_feeMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
          _accountNameMeta,
          accountName.isAcceptableOrUnknown(
              data['account_name']!, _accountNameMeta));
    }
    if (data.containsKey('account_tag')) {
      context.handle(
          _accountTagMeta,
          accountTag.isAcceptableOrUnknown(
              data['account_tag']!, _accountTagMeta));
    }
    if (data.containsKey('dust')) {
      context.handle(
          _dustMeta, dust.isAcceptableOrUnknown(data['dust']!, _dustMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {addressId};
  @override
  Addresse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Addresse.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Addresses createAlias(String alias) {
    return Addresses(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(address_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class App extends DataClass implements Insertable<App> {
  final String appId;
  final String appNumber;
  final String homeUri;
  final String redirectUri;
  final String name;
  final String iconUrl;
  final String? category;
  final String description;
  final String appSecret;
  final String? capabilities;
  final String creatorId;
  final String? resourcePatterns;
  final DateTime? updatedAt;
  App(
      {required this.appId,
      required this.appNumber,
      required this.homeUri,
      required this.redirectUri,
      required this.name,
      required this.iconUrl,
      this.category,
      required this.description,
      required this.appSecret,
      this.capabilities,
      required this.creatorId,
      this.resourcePatterns,
      this.updatedAt});
  factory App.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return App(
      appId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}app_id'])!,
      appNumber: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}app_number'])!,
      homeUri: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}home_uri'])!,
      redirectUri: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}redirect_uri'])!,
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      iconUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}icon_url'])!,
      category: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}category']),
      description: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}description'])!,
      appSecret: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}app_secret'])!,
      capabilities: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}capabilities']),
      creatorId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}creator_id'])!,
      resourcePatterns: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}resource_patterns']),
      updatedAt: Apps.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}updated_at'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['app_id'] = Variable<String>(appId);
    map['app_number'] = Variable<String>(appNumber);
    map['home_uri'] = Variable<String>(homeUri);
    map['redirect_uri'] = Variable<String>(redirectUri);
    map['name'] = Variable<String>(name);
    map['icon_url'] = Variable<String>(iconUrl);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String?>(category);
    }
    map['description'] = Variable<String>(description);
    map['app_secret'] = Variable<String>(appSecret);
    if (!nullToAbsent || capabilities != null) {
      map['capabilities'] = Variable<String?>(capabilities);
    }
    map['creator_id'] = Variable<String>(creatorId);
    if (!nullToAbsent || resourcePatterns != null) {
      map['resource_patterns'] = Variable<String?>(resourcePatterns);
    }
    if (!nullToAbsent || updatedAt != null) {
      final converter = Apps.$converter0;
      map['updated_at'] = Variable<int?>(converter.mapToSql(updatedAt));
    }
    return map;
  }

  AppsCompanion toCompanion(bool nullToAbsent) {
    return AppsCompanion(
      appId: Value(appId),
      appNumber: Value(appNumber),
      homeUri: Value(homeUri),
      redirectUri: Value(redirectUri),
      name: Value(name),
      iconUrl: Value(iconUrl),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      description: Value(description),
      appSecret: Value(appSecret),
      capabilities: capabilities == null && nullToAbsent
          ? const Value.absent()
          : Value(capabilities),
      creatorId: Value(creatorId),
      resourcePatterns: resourcePatterns == null && nullToAbsent
          ? const Value.absent()
          : Value(resourcePatterns),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory App.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return App(
      appId: serializer.fromJson<String>(json['app_id']),
      appNumber: serializer.fromJson<String>(json['app_number']),
      homeUri: serializer.fromJson<String>(json['home_uri']),
      redirectUri: serializer.fromJson<String>(json['redirect_uri']),
      name: serializer.fromJson<String>(json['name']),
      iconUrl: serializer.fromJson<String>(json['icon_url']),
      category: serializer.fromJson<String?>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      appSecret: serializer.fromJson<String>(json['app_secret']),
      capabilities: serializer.fromJson<String?>(json['capabilities']),
      creatorId: serializer.fromJson<String>(json['creator_id']),
      resourcePatterns: serializer.fromJson<String?>(json['resource_patterns']),
      updatedAt: serializer.fromJson<DateTime?>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'app_id': serializer.toJson<String>(appId),
      'app_number': serializer.toJson<String>(appNumber),
      'home_uri': serializer.toJson<String>(homeUri),
      'redirect_uri': serializer.toJson<String>(redirectUri),
      'name': serializer.toJson<String>(name),
      'icon_url': serializer.toJson<String>(iconUrl),
      'category': serializer.toJson<String?>(category),
      'description': serializer.toJson<String>(description),
      'app_secret': serializer.toJson<String>(appSecret),
      'capabilities': serializer.toJson<String?>(capabilities),
      'creator_id': serializer.toJson<String>(creatorId),
      'resource_patterns': serializer.toJson<String?>(resourcePatterns),
      'updated_at': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  App copyWith(
          {String? appId,
          String? appNumber,
          String? homeUri,
          String? redirectUri,
          String? name,
          String? iconUrl,
          String? category,
          String? description,
          String? appSecret,
          String? capabilities,
          String? creatorId,
          String? resourcePatterns,
          DateTime? updatedAt}) =>
      App(
        appId: appId ?? this.appId,
        appNumber: appNumber ?? this.appNumber,
        homeUri: homeUri ?? this.homeUri,
        redirectUri: redirectUri ?? this.redirectUri,
        name: name ?? this.name,
        iconUrl: iconUrl ?? this.iconUrl,
        category: category ?? this.category,
        description: description ?? this.description,
        appSecret: appSecret ?? this.appSecret,
        capabilities: capabilities ?? this.capabilities,
        creatorId: creatorId ?? this.creatorId,
        resourcePatterns: resourcePatterns ?? this.resourcePatterns,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('App(')
          ..write('appId: $appId, ')
          ..write('appNumber: $appNumber, ')
          ..write('homeUri: $homeUri, ')
          ..write('redirectUri: $redirectUri, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('appSecret: $appSecret, ')
          ..write('capabilities: $capabilities, ')
          ..write('creatorId: $creatorId, ')
          ..write('resourcePatterns: $resourcePatterns, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      appId.hashCode,
      $mrjc(
          appNumber.hashCode,
          $mrjc(
              homeUri.hashCode,
              $mrjc(
                  redirectUri.hashCode,
                  $mrjc(
                      name.hashCode,
                      $mrjc(
                          iconUrl.hashCode,
                          $mrjc(
                              category.hashCode,
                              $mrjc(
                                  description.hashCode,
                                  $mrjc(
                                      appSecret.hashCode,
                                      $mrjc(
                                          capabilities.hashCode,
                                          $mrjc(
                                              creatorId.hashCode,
                                              $mrjc(
                                                  resourcePatterns.hashCode,
                                                  updatedAt
                                                      .hashCode)))))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is App &&
          other.appId == this.appId &&
          other.appNumber == this.appNumber &&
          other.homeUri == this.homeUri &&
          other.redirectUri == this.redirectUri &&
          other.name == this.name &&
          other.iconUrl == this.iconUrl &&
          other.category == this.category &&
          other.description == this.description &&
          other.appSecret == this.appSecret &&
          other.capabilities == this.capabilities &&
          other.creatorId == this.creatorId &&
          other.resourcePatterns == this.resourcePatterns &&
          other.updatedAt == this.updatedAt);
}

class AppsCompanion extends UpdateCompanion<App> {
  final Value<String> appId;
  final Value<String> appNumber;
  final Value<String> homeUri;
  final Value<String> redirectUri;
  final Value<String> name;
  final Value<String> iconUrl;
  final Value<String?> category;
  final Value<String> description;
  final Value<String> appSecret;
  final Value<String?> capabilities;
  final Value<String> creatorId;
  final Value<String?> resourcePatterns;
  final Value<DateTime?> updatedAt;
  const AppsCompanion({
    this.appId = const Value.absent(),
    this.appNumber = const Value.absent(),
    this.homeUri = const Value.absent(),
    this.redirectUri = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.appSecret = const Value.absent(),
    this.capabilities = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.resourcePatterns = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppsCompanion.insert({
    required String appId,
    required String appNumber,
    required String homeUri,
    required String redirectUri,
    required String name,
    required String iconUrl,
    this.category = const Value.absent(),
    required String description,
    required String appSecret,
    this.capabilities = const Value.absent(),
    required String creatorId,
    this.resourcePatterns = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : appId = Value(appId),
        appNumber = Value(appNumber),
        homeUri = Value(homeUri),
        redirectUri = Value(redirectUri),
        name = Value(name),
        iconUrl = Value(iconUrl),
        description = Value(description),
        appSecret = Value(appSecret),
        creatorId = Value(creatorId);
  static Insertable<App> custom({
    Expression<String>? appId,
    Expression<String>? appNumber,
    Expression<String>? homeUri,
    Expression<String>? redirectUri,
    Expression<String>? name,
    Expression<String>? iconUrl,
    Expression<String?>? category,
    Expression<String>? description,
    Expression<String>? appSecret,
    Expression<String?>? capabilities,
    Expression<String>? creatorId,
    Expression<String?>? resourcePatterns,
    Expression<DateTime?>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (appId != null) 'app_id': appId,
      if (appNumber != null) 'app_number': appNumber,
      if (homeUri != null) 'home_uri': homeUri,
      if (redirectUri != null) 'redirect_uri': redirectUri,
      if (name != null) 'name': name,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (appSecret != null) 'app_secret': appSecret,
      if (capabilities != null) 'capabilities': capabilities,
      if (creatorId != null) 'creator_id': creatorId,
      if (resourcePatterns != null) 'resource_patterns': resourcePatterns,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppsCompanion copyWith(
      {Value<String>? appId,
      Value<String>? appNumber,
      Value<String>? homeUri,
      Value<String>? redirectUri,
      Value<String>? name,
      Value<String>? iconUrl,
      Value<String?>? category,
      Value<String>? description,
      Value<String>? appSecret,
      Value<String?>? capabilities,
      Value<String>? creatorId,
      Value<String?>? resourcePatterns,
      Value<DateTime?>? updatedAt}) {
    return AppsCompanion(
      appId: appId ?? this.appId,
      appNumber: appNumber ?? this.appNumber,
      homeUri: homeUri ?? this.homeUri,
      redirectUri: redirectUri ?? this.redirectUri,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      category: category ?? this.category,
      description: description ?? this.description,
      appSecret: appSecret ?? this.appSecret,
      capabilities: capabilities ?? this.capabilities,
      creatorId: creatorId ?? this.creatorId,
      resourcePatterns: resourcePatterns ?? this.resourcePatterns,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (appNumber.present) {
      map['app_number'] = Variable<String>(appNumber.value);
    }
    if (homeUri.present) {
      map['home_uri'] = Variable<String>(homeUri.value);
    }
    if (redirectUri.present) {
      map['redirect_uri'] = Variable<String>(redirectUri.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (category.present) {
      map['category'] = Variable<String?>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (appSecret.present) {
      map['app_secret'] = Variable<String>(appSecret.value);
    }
    if (capabilities.present) {
      map['capabilities'] = Variable<String?>(capabilities.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (resourcePatterns.present) {
      map['resource_patterns'] = Variable<String?>(resourcePatterns.value);
    }
    if (updatedAt.present) {
      final converter = Apps.$converter0;
      map['updated_at'] = Variable<int?>(converter.mapToSql(updatedAt.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppsCompanion(')
          ..write('appId: $appId, ')
          ..write('appNumber: $appNumber, ')
          ..write('homeUri: $homeUri, ')
          ..write('redirectUri: $redirectUri, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('appSecret: $appSecret, ')
          ..write('capabilities: $capabilities, ')
          ..write('creatorId: $creatorId, ')
          ..write('resourcePatterns: $resourcePatterns, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class Apps extends Table with TableInfo<Apps, App> {
  final GeneratedDatabase _db;
  final String? _alias;
  Apps(this._db, [this._alias]);
  final VerificationMeta _appIdMeta = const VerificationMeta('appId');
  late final GeneratedTextColumn appId = _constructAppId();
  GeneratedTextColumn _constructAppId() {
    return GeneratedTextColumn('app_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _appNumberMeta = const VerificationMeta('appNumber');
  late final GeneratedTextColumn appNumber = _constructAppNumber();
  GeneratedTextColumn _constructAppNumber() {
    return GeneratedTextColumn('app_number', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _homeUriMeta = const VerificationMeta('homeUri');
  late final GeneratedTextColumn homeUri = _constructHomeUri();
  GeneratedTextColumn _constructHomeUri() {
    return GeneratedTextColumn('home_uri', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _redirectUriMeta =
      const VerificationMeta('redirectUri');
  late final GeneratedTextColumn redirectUri = _constructRedirectUri();
  GeneratedTextColumn _constructRedirectUri() {
    return GeneratedTextColumn('redirect_uri', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _iconUrlMeta = const VerificationMeta('iconUrl');
  late final GeneratedTextColumn iconUrl = _constructIconUrl();
  GeneratedTextColumn _constructIconUrl() {
    return GeneratedTextColumn('icon_url', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  late final GeneratedTextColumn category = _constructCategory();
  GeneratedTextColumn _constructCategory() {
    return GeneratedTextColumn('category', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  late final GeneratedTextColumn description = _constructDescription();
  GeneratedTextColumn _constructDescription() {
    return GeneratedTextColumn('description', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _appSecretMeta = const VerificationMeta('appSecret');
  late final GeneratedTextColumn appSecret = _constructAppSecret();
  GeneratedTextColumn _constructAppSecret() {
    return GeneratedTextColumn('app_secret', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _capabilitiesMeta =
      const VerificationMeta('capabilities');
  late final GeneratedTextColumn capabilities = _constructCapabilities();
  GeneratedTextColumn _constructCapabilities() {
    return GeneratedTextColumn('capabilities', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _creatorIdMeta = const VerificationMeta('creatorId');
  late final GeneratedTextColumn creatorId = _constructCreatorId();
  GeneratedTextColumn _constructCreatorId() {
    return GeneratedTextColumn('creator_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _resourcePatternsMeta =
      const VerificationMeta('resourcePatterns');
  late final GeneratedTextColumn resourcePatterns =
      _constructResourcePatterns();
  GeneratedTextColumn _constructResourcePatterns() {
    return GeneratedTextColumn('resource_patterns', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedIntColumn updatedAt = _constructUpdatedAt();
  GeneratedIntColumn _constructUpdatedAt() {
    return GeneratedIntColumn('updated_at', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [
        appId,
        appNumber,
        homeUri,
        redirectUri,
        name,
        iconUrl,
        category,
        description,
        appSecret,
        capabilities,
        creatorId,
        resourcePatterns,
        updatedAt
      ];
  @override
  Apps get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'apps';
  @override
  final String actualTableName = 'apps';
  @override
  VerificationContext validateIntegrity(Insertable<App> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('app_number')) {
      context.handle(_appNumberMeta,
          appNumber.isAcceptableOrUnknown(data['app_number']!, _appNumberMeta));
    } else if (isInserting) {
      context.missing(_appNumberMeta);
    }
    if (data.containsKey('home_uri')) {
      context.handle(_homeUriMeta,
          homeUri.isAcceptableOrUnknown(data['home_uri']!, _homeUriMeta));
    } else if (isInserting) {
      context.missing(_homeUriMeta);
    }
    if (data.containsKey('redirect_uri')) {
      context.handle(
          _redirectUriMeta,
          redirectUri.isAcceptableOrUnknown(
              data['redirect_uri']!, _redirectUriMeta));
    } else if (isInserting) {
      context.missing(_redirectUriMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(_iconUrlMeta,
          iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta));
    } else if (isInserting) {
      context.missing(_iconUrlMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('app_secret')) {
      context.handle(_appSecretMeta,
          appSecret.isAcceptableOrUnknown(data['app_secret']!, _appSecretMeta));
    } else if (isInserting) {
      context.missing(_appSecretMeta);
    }
    if (data.containsKey('capabilities')) {
      context.handle(
          _capabilitiesMeta,
          capabilities.isAcceptableOrUnknown(
              data['capabilities']!, _capabilitiesMeta));
    }
    if (data.containsKey('creator_id')) {
      context.handle(_creatorIdMeta,
          creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta));
    } else if (isInserting) {
      context.missing(_creatorIdMeta);
    }
    if (data.containsKey('resource_patterns')) {
      context.handle(
          _resourcePatternsMeta,
          resourcePatterns.isAcceptableOrUnknown(
              data['resource_patterns']!, _resourcePatternsMeta));
    }
    context.handle(_updatedAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {appId};
  @override
  App map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return App.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Apps createAlias(String alias) {
    return Apps(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(app_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Asset extends DataClass implements Insertable<Asset> {
  final String assetId;
  final String symbol;
  final String name;
  final String iconUrl;
  final String balance;
  final String destination;
  final String? tag;
  final String priceBtc;
  final String priceUsd;
  final String chainId;
  final String changeUsd;
  final String changeBtc;
  final int confirmations;
  final String? assetKey;
  Asset(
      {required this.assetId,
      required this.symbol,
      required this.name,
      required this.iconUrl,
      required this.balance,
      required this.destination,
      this.tag,
      required this.priceBtc,
      required this.priceUsd,
      required this.chainId,
      required this.changeUsd,
      required this.changeBtc,
      required this.confirmations,
      this.assetKey});
  factory Asset.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Asset(
      assetId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_id'])!,
      symbol:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}symbol'])!,
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      iconUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}icon_url'])!,
      balance: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}balance'])!,
      destination: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}destination'])!,
      tag: stringType.mapFromDatabaseResponse(data['${effectivePrefix}tag']),
      priceBtc: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}price_btc'])!,
      priceUsd: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}price_usd'])!,
      chainId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}chain_id'])!,
      changeUsd: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}change_usd'])!,
      changeBtc: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}change_btc'])!,
      confirmations: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}confirmations'])!,
      assetKey: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_key']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['symbol'] = Variable<String>(symbol);
    map['name'] = Variable<String>(name);
    map['icon_url'] = Variable<String>(iconUrl);
    map['balance'] = Variable<String>(balance);
    map['destination'] = Variable<String>(destination);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String?>(tag);
    }
    map['price_btc'] = Variable<String>(priceBtc);
    map['price_usd'] = Variable<String>(priceUsd);
    map['chain_id'] = Variable<String>(chainId);
    map['change_usd'] = Variable<String>(changeUsd);
    map['change_btc'] = Variable<String>(changeBtc);
    map['confirmations'] = Variable<int>(confirmations);
    if (!nullToAbsent || assetKey != null) {
      map['asset_key'] = Variable<String?>(assetKey);
    }
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      assetId: Value(assetId),
      symbol: Value(symbol),
      name: Value(name),
      iconUrl: Value(iconUrl),
      balance: Value(balance),
      destination: Value(destination),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      priceBtc: Value(priceBtc),
      priceUsd: Value(priceUsd),
      chainId: Value(chainId),
      changeUsd: Value(changeUsd),
      changeBtc: Value(changeBtc),
      confirmations: Value(confirmations),
      assetKey: assetKey == null && nullToAbsent
          ? const Value.absent()
          : Value(assetKey),
    );
  }

  factory Asset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Asset(
      assetId: serializer.fromJson<String>(json['asset_id']),
      symbol: serializer.fromJson<String>(json['symbol']),
      name: serializer.fromJson<String>(json['name']),
      iconUrl: serializer.fromJson<String>(json['icon_url']),
      balance: serializer.fromJson<String>(json['balance']),
      destination: serializer.fromJson<String>(json['destination']),
      tag: serializer.fromJson<String?>(json['tag']),
      priceBtc: serializer.fromJson<String>(json['price_btc']),
      priceUsd: serializer.fromJson<String>(json['price_usd']),
      chainId: serializer.fromJson<String>(json['chain_id']),
      changeUsd: serializer.fromJson<String>(json['change_usd']),
      changeBtc: serializer.fromJson<String>(json['change_btc']),
      confirmations: serializer.fromJson<int>(json['confirmations']),
      assetKey: serializer.fromJson<String?>(json['asset_key']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'asset_id': serializer.toJson<String>(assetId),
      'symbol': serializer.toJson<String>(symbol),
      'name': serializer.toJson<String>(name),
      'icon_url': serializer.toJson<String>(iconUrl),
      'balance': serializer.toJson<String>(balance),
      'destination': serializer.toJson<String>(destination),
      'tag': serializer.toJson<String?>(tag),
      'price_btc': serializer.toJson<String>(priceBtc),
      'price_usd': serializer.toJson<String>(priceUsd),
      'chain_id': serializer.toJson<String>(chainId),
      'change_usd': serializer.toJson<String>(changeUsd),
      'change_btc': serializer.toJson<String>(changeBtc),
      'confirmations': serializer.toJson<int>(confirmations),
      'asset_key': serializer.toJson<String?>(assetKey),
    };
  }

  Asset copyWith(
          {String? assetId,
          String? symbol,
          String? name,
          String? iconUrl,
          String? balance,
          String? destination,
          String? tag,
          String? priceBtc,
          String? priceUsd,
          String? chainId,
          String? changeUsd,
          String? changeBtc,
          int? confirmations,
          String? assetKey}) =>
      Asset(
        assetId: assetId ?? this.assetId,
        symbol: symbol ?? this.symbol,
        name: name ?? this.name,
        iconUrl: iconUrl ?? this.iconUrl,
        balance: balance ?? this.balance,
        destination: destination ?? this.destination,
        tag: tag ?? this.tag,
        priceBtc: priceBtc ?? this.priceBtc,
        priceUsd: priceUsd ?? this.priceUsd,
        chainId: chainId ?? this.chainId,
        changeUsd: changeUsd ?? this.changeUsd,
        changeBtc: changeBtc ?? this.changeBtc,
        confirmations: confirmations ?? this.confirmations,
        assetKey: assetKey ?? this.assetKey,
      );
  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('assetId: $assetId, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('balance: $balance, ')
          ..write('destination: $destination, ')
          ..write('tag: $tag, ')
          ..write('priceBtc: $priceBtc, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('chainId: $chainId, ')
          ..write('changeUsd: $changeUsd, ')
          ..write('changeBtc: $changeBtc, ')
          ..write('confirmations: $confirmations, ')
          ..write('assetKey: $assetKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      assetId.hashCode,
      $mrjc(
          symbol.hashCode,
          $mrjc(
              name.hashCode,
              $mrjc(
                  iconUrl.hashCode,
                  $mrjc(
                      balance.hashCode,
                      $mrjc(
                          destination.hashCode,
                          $mrjc(
                              tag.hashCode,
                              $mrjc(
                                  priceBtc.hashCode,
                                  $mrjc(
                                      priceUsd.hashCode,
                                      $mrjc(
                                          chainId.hashCode,
                                          $mrjc(
                                              changeUsd.hashCode,
                                              $mrjc(
                                                  changeBtc.hashCode,
                                                  $mrjc(
                                                      confirmations.hashCode,
                                                      assetKey
                                                          .hashCode))))))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Asset &&
          other.assetId == this.assetId &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.iconUrl == this.iconUrl &&
          other.balance == this.balance &&
          other.destination == this.destination &&
          other.tag == this.tag &&
          other.priceBtc == this.priceBtc &&
          other.priceUsd == this.priceUsd &&
          other.chainId == this.chainId &&
          other.changeUsd == this.changeUsd &&
          other.changeBtc == this.changeBtc &&
          other.confirmations == this.confirmations &&
          other.assetKey == this.assetKey);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<String> assetId;
  final Value<String> symbol;
  final Value<String> name;
  final Value<String> iconUrl;
  final Value<String> balance;
  final Value<String> destination;
  final Value<String?> tag;
  final Value<String> priceBtc;
  final Value<String> priceUsd;
  final Value<String> chainId;
  final Value<String> changeUsd;
  final Value<String> changeBtc;
  final Value<int> confirmations;
  final Value<String?> assetKey;
  const AssetsCompanion({
    this.assetId = const Value.absent(),
    this.symbol = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.balance = const Value.absent(),
    this.destination = const Value.absent(),
    this.tag = const Value.absent(),
    this.priceBtc = const Value.absent(),
    this.priceUsd = const Value.absent(),
    this.chainId = const Value.absent(),
    this.changeUsd = const Value.absent(),
    this.changeBtc = const Value.absent(),
    this.confirmations = const Value.absent(),
    this.assetKey = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String assetId,
    required String symbol,
    required String name,
    required String iconUrl,
    required String balance,
    required String destination,
    this.tag = const Value.absent(),
    required String priceBtc,
    required String priceUsd,
    required String chainId,
    required String changeUsd,
    required String changeBtc,
    required int confirmations,
    this.assetKey = const Value.absent(),
  })  : assetId = Value(assetId),
        symbol = Value(symbol),
        name = Value(name),
        iconUrl = Value(iconUrl),
        balance = Value(balance),
        destination = Value(destination),
        priceBtc = Value(priceBtc),
        priceUsd = Value(priceUsd),
        chainId = Value(chainId),
        changeUsd = Value(changeUsd),
        changeBtc = Value(changeBtc),
        confirmations = Value(confirmations);
  static Insertable<Asset> custom({
    Expression<String>? assetId,
    Expression<String>? symbol,
    Expression<String>? name,
    Expression<String>? iconUrl,
    Expression<String>? balance,
    Expression<String>? destination,
    Expression<String?>? tag,
    Expression<String>? priceBtc,
    Expression<String>? priceUsd,
    Expression<String>? chainId,
    Expression<String>? changeUsd,
    Expression<String>? changeBtc,
    Expression<int>? confirmations,
    Expression<String?>? assetKey,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (symbol != null) 'symbol': symbol,
      if (name != null) 'name': name,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (balance != null) 'balance': balance,
      if (destination != null) 'destination': destination,
      if (tag != null) 'tag': tag,
      if (priceBtc != null) 'price_btc': priceBtc,
      if (priceUsd != null) 'price_usd': priceUsd,
      if (chainId != null) 'chain_id': chainId,
      if (changeUsd != null) 'change_usd': changeUsd,
      if (changeBtc != null) 'change_btc': changeBtc,
      if (confirmations != null) 'confirmations': confirmations,
      if (assetKey != null) 'asset_key': assetKey,
    });
  }

  AssetsCompanion copyWith(
      {Value<String>? assetId,
      Value<String>? symbol,
      Value<String>? name,
      Value<String>? iconUrl,
      Value<String>? balance,
      Value<String>? destination,
      Value<String?>? tag,
      Value<String>? priceBtc,
      Value<String>? priceUsd,
      Value<String>? chainId,
      Value<String>? changeUsd,
      Value<String>? changeBtc,
      Value<int>? confirmations,
      Value<String?>? assetKey}) {
    return AssetsCompanion(
      assetId: assetId ?? this.assetId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      balance: balance ?? this.balance,
      destination: destination ?? this.destination,
      tag: tag ?? this.tag,
      priceBtc: priceBtc ?? this.priceBtc,
      priceUsd: priceUsd ?? this.priceUsd,
      chainId: chainId ?? this.chainId,
      changeUsd: changeUsd ?? this.changeUsd,
      changeBtc: changeBtc ?? this.changeBtc,
      confirmations: confirmations ?? this.confirmations,
      assetKey: assetKey ?? this.assetKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (balance.present) {
      map['balance'] = Variable<String>(balance.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String?>(tag.value);
    }
    if (priceBtc.present) {
      map['price_btc'] = Variable<String>(priceBtc.value);
    }
    if (priceUsd.present) {
      map['price_usd'] = Variable<String>(priceUsd.value);
    }
    if (chainId.present) {
      map['chain_id'] = Variable<String>(chainId.value);
    }
    if (changeUsd.present) {
      map['change_usd'] = Variable<String>(changeUsd.value);
    }
    if (changeBtc.present) {
      map['change_btc'] = Variable<String>(changeBtc.value);
    }
    if (confirmations.present) {
      map['confirmations'] = Variable<int>(confirmations.value);
    }
    if (assetKey.present) {
      map['asset_key'] = Variable<String?>(assetKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('assetId: $assetId, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('balance: $balance, ')
          ..write('destination: $destination, ')
          ..write('tag: $tag, ')
          ..write('priceBtc: $priceBtc, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('chainId: $chainId, ')
          ..write('changeUsd: $changeUsd, ')
          ..write('changeBtc: $changeBtc, ')
          ..write('confirmations: $confirmations, ')
          ..write('assetKey: $assetKey')
          ..write(')'))
        .toString();
  }
}

class Assets extends Table with TableInfo<Assets, Asset> {
  final GeneratedDatabase _db;
  final String? _alias;
  Assets(this._db, [this._alias]);
  final VerificationMeta _assetIdMeta = const VerificationMeta('assetId');
  late final GeneratedTextColumn assetId = _constructAssetId();
  GeneratedTextColumn _constructAssetId() {
    return GeneratedTextColumn('asset_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  late final GeneratedTextColumn symbol = _constructSymbol();
  GeneratedTextColumn _constructSymbol() {
    return GeneratedTextColumn('symbol', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _iconUrlMeta = const VerificationMeta('iconUrl');
  late final GeneratedTextColumn iconUrl = _constructIconUrl();
  GeneratedTextColumn _constructIconUrl() {
    return GeneratedTextColumn('icon_url', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _balanceMeta = const VerificationMeta('balance');
  late final GeneratedTextColumn balance = _constructBalance();
  GeneratedTextColumn _constructBalance() {
    return GeneratedTextColumn('balance', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _destinationMeta =
      const VerificationMeta('destination');
  late final GeneratedTextColumn destination = _constructDestination();
  GeneratedTextColumn _constructDestination() {
    return GeneratedTextColumn('destination', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _tagMeta = const VerificationMeta('tag');
  late final GeneratedTextColumn tag = _constructTag();
  GeneratedTextColumn _constructTag() {
    return GeneratedTextColumn('tag', $tableName, true, $customConstraints: '');
  }

  final VerificationMeta _priceBtcMeta = const VerificationMeta('priceBtc');
  late final GeneratedTextColumn priceBtc = _constructPriceBtc();
  GeneratedTextColumn _constructPriceBtc() {
    return GeneratedTextColumn('price_btc', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _priceUsdMeta = const VerificationMeta('priceUsd');
  late final GeneratedTextColumn priceUsd = _constructPriceUsd();
  GeneratedTextColumn _constructPriceUsd() {
    return GeneratedTextColumn('price_usd', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _chainIdMeta = const VerificationMeta('chainId');
  late final GeneratedTextColumn chainId = _constructChainId();
  GeneratedTextColumn _constructChainId() {
    return GeneratedTextColumn('chain_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _changeUsdMeta = const VerificationMeta('changeUsd');
  late final GeneratedTextColumn changeUsd = _constructChangeUsd();
  GeneratedTextColumn _constructChangeUsd() {
    return GeneratedTextColumn('change_usd', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _changeBtcMeta = const VerificationMeta('changeBtc');
  late final GeneratedTextColumn changeBtc = _constructChangeBtc();
  GeneratedTextColumn _constructChangeBtc() {
    return GeneratedTextColumn('change_btc', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _confirmationsMeta =
      const VerificationMeta('confirmations');
  late final GeneratedIntColumn confirmations = _constructConfirmations();
  GeneratedIntColumn _constructConfirmations() {
    return GeneratedIntColumn('confirmations', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _assetKeyMeta = const VerificationMeta('assetKey');
  late final GeneratedTextColumn assetKey = _constructAssetKey();
  GeneratedTextColumn _constructAssetKey() {
    return GeneratedTextColumn('asset_key', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [
        assetId,
        symbol,
        name,
        iconUrl,
        balance,
        destination,
        tag,
        priceBtc,
        priceUsd,
        chainId,
        changeUsd,
        changeBtc,
        confirmations,
        assetKey
      ];
  @override
  Assets get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'assets';
  @override
  final String actualTableName = 'assets';
  @override
  VerificationContext validateIntegrity(Insertable<Asset> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(_iconUrlMeta,
          iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta));
    } else if (isInserting) {
      context.missing(_iconUrlMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
          _destinationMeta,
          destination.isAcceptableOrUnknown(
              data['destination']!, _destinationMeta));
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    }
    if (data.containsKey('price_btc')) {
      context.handle(_priceBtcMeta,
          priceBtc.isAcceptableOrUnknown(data['price_btc']!, _priceBtcMeta));
    } else if (isInserting) {
      context.missing(_priceBtcMeta);
    }
    if (data.containsKey('price_usd')) {
      context.handle(_priceUsdMeta,
          priceUsd.isAcceptableOrUnknown(data['price_usd']!, _priceUsdMeta));
    } else if (isInserting) {
      context.missing(_priceUsdMeta);
    }
    if (data.containsKey('chain_id')) {
      context.handle(_chainIdMeta,
          chainId.isAcceptableOrUnknown(data['chain_id']!, _chainIdMeta));
    } else if (isInserting) {
      context.missing(_chainIdMeta);
    }
    if (data.containsKey('change_usd')) {
      context.handle(_changeUsdMeta,
          changeUsd.isAcceptableOrUnknown(data['change_usd']!, _changeUsdMeta));
    } else if (isInserting) {
      context.missing(_changeUsdMeta);
    }
    if (data.containsKey('change_btc')) {
      context.handle(_changeBtcMeta,
          changeBtc.isAcceptableOrUnknown(data['change_btc']!, _changeBtcMeta));
    } else if (isInserting) {
      context.missing(_changeBtcMeta);
    }
    if (data.containsKey('confirmations')) {
      context.handle(
          _confirmationsMeta,
          confirmations.isAcceptableOrUnknown(
              data['confirmations']!, _confirmationsMeta));
    } else if (isInserting) {
      context.missing(_confirmationsMeta);
    }
    if (data.containsKey('asset_key')) {
      context.handle(_assetKeyMeta,
          assetKey.isAcceptableOrUnknown(data['asset_key']!, _assetKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Asset.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Assets createAlias(String alias) {
    return Assets(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(asset_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class CircleConversation extends DataClass
    implements Insertable<CircleConversation> {
  final String conversationId;
  final String circleId;
  final String? userId;
  final DateTime createdAt;
  final DateTime? pinTime;
  CircleConversation(
      {required this.conversationId,
      required this.circleId,
      this.userId,
      required this.createdAt,
      this.pinTime});
  factory CircleConversation.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return CircleConversation(
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id'])!,
      circleId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}circle_id'])!,
      userId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}user_id']),
      createdAt: CircleConversations.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
      pinTime: CircleConversations.$converter1.mapToDart(
          intType.mapFromDatabaseResponse(data['${effectivePrefix}pin_time'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['circle_id'] = Variable<String>(circleId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String?>(userId);
    }
    {
      final converter = CircleConversations.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    if (!nullToAbsent || pinTime != null) {
      final converter = CircleConversations.$converter1;
      map['pin_time'] = Variable<int?>(converter.mapToSql(pinTime));
    }
    return map;
  }

  CircleConversationsCompanion toCompanion(bool nullToAbsent) {
    return CircleConversationsCompanion(
      conversationId: Value(conversationId),
      circleId: Value(circleId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      createdAt: Value(createdAt),
      pinTime: pinTime == null && nullToAbsent
          ? const Value.absent()
          : Value(pinTime),
    );
  }

  factory CircleConversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return CircleConversation(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      circleId: serializer.fromJson<String>(json['circle_id']),
      userId: serializer.fromJson<String?>(json['user_id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      pinTime: serializer.fromJson<DateTime?>(json['pin_time']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversation_id': serializer.toJson<String>(conversationId),
      'circle_id': serializer.toJson<String>(circleId),
      'user_id': serializer.toJson<String?>(userId),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'pin_time': serializer.toJson<DateTime?>(pinTime),
    };
  }

  CircleConversation copyWith(
          {String? conversationId,
          String? circleId,
          String? userId,
          DateTime? createdAt,
          DateTime? pinTime}) =>
      CircleConversation(
        conversationId: conversationId ?? this.conversationId,
        circleId: circleId ?? this.circleId,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
        pinTime: pinTime ?? this.pinTime,
      );
  @override
  String toString() {
    return (StringBuffer('CircleConversation(')
          ..write('conversationId: $conversationId, ')
          ..write('circleId: $circleId, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('pinTime: $pinTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      conversationId.hashCode,
      $mrjc(
          circleId.hashCode,
          $mrjc(
              userId.hashCode, $mrjc(createdAt.hashCode, pinTime.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is CircleConversation &&
          other.conversationId == this.conversationId &&
          other.circleId == this.circleId &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.pinTime == this.pinTime);
}

class CircleConversationsCompanion extends UpdateCompanion<CircleConversation> {
  final Value<String> conversationId;
  final Value<String> circleId;
  final Value<String?> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> pinTime;
  const CircleConversationsCompanion({
    this.conversationId = const Value.absent(),
    this.circleId = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pinTime = const Value.absent(),
  });
  CircleConversationsCompanion.insert({
    required String conversationId,
    required String circleId,
    this.userId = const Value.absent(),
    required DateTime createdAt,
    this.pinTime = const Value.absent(),
  })  : conversationId = Value(conversationId),
        circleId = Value(circleId),
        createdAt = Value(createdAt);
  static Insertable<CircleConversation> custom({
    Expression<String>? conversationId,
    Expression<String>? circleId,
    Expression<String?>? userId,
    Expression<DateTime>? createdAt,
    Expression<DateTime?>? pinTime,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (circleId != null) 'circle_id': circleId,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (pinTime != null) 'pin_time': pinTime,
    });
  }

  CircleConversationsCompanion copyWith(
      {Value<String>? conversationId,
      Value<String>? circleId,
      Value<String?>? userId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? pinTime}) {
    return CircleConversationsCompanion(
      conversationId: conversationId ?? this.conversationId,
      circleId: circleId ?? this.circleId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      pinTime: pinTime ?? this.pinTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (circleId.present) {
      map['circle_id'] = Variable<String>(circleId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String?>(userId.value);
    }
    if (createdAt.present) {
      final converter = CircleConversations.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    if (pinTime.present) {
      final converter = CircleConversations.$converter1;
      map['pin_time'] = Variable<int?>(converter.mapToSql(pinTime.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CircleConversationsCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('circleId: $circleId, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('pinTime: $pinTime')
          ..write(')'))
        .toString();
  }
}

class CircleConversations extends Table
    with TableInfo<CircleConversations, CircleConversation> {
  final GeneratedDatabase _db;
  final String? _alias;
  CircleConversations(this._db, [this._alias]);
  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedTextColumn conversationId = _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _circleIdMeta = const VerificationMeta('circleId');
  late final GeneratedTextColumn circleId = _constructCircleId();
  GeneratedTextColumn _constructCircleId() {
    return GeneratedTextColumn('circle_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _pinTimeMeta = const VerificationMeta('pinTime');
  late final GeneratedIntColumn pinTime = _constructPinTime();
  GeneratedIntColumn _constructPinTime() {
    return GeneratedIntColumn('pin_time', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [conversationId, circleId, userId, createdAt, pinTime];
  @override
  CircleConversations get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'circle_conversations';
  @override
  final String actualTableName = 'circle_conversations';
  @override
  VerificationContext validateIntegrity(Insertable<CircleConversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('circle_id')) {
      context.handle(_circleIdMeta,
          circleId.isAcceptableOrUnknown(data['circle_id']!, _circleIdMeta));
    } else if (isInserting) {
      context.missing(_circleIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    context.handle(_pinTimeMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, circleId};
  @override
  CircleConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return CircleConversation.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  CircleConversations createAlias(String alias) {
    return CircleConversations(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  static TypeConverter<DateTime, int> $converter1 = const MillisDateConverter();
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(conversation_id, circle_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Circle extends DataClass implements Insertable<Circle> {
  final String circleId;
  final String name;
  final DateTime createdAt;
  final DateTime? orderedAt;
  Circle(
      {required this.circleId,
      required this.name,
      required this.createdAt,
      this.orderedAt});
  factory Circle.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Circle(
      circleId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}circle_id'])!,
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      createdAt: Circles.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
      orderedAt: Circles.$converter1.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}ordered_at'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['circle_id'] = Variable<String>(circleId);
    map['name'] = Variable<String>(name);
    {
      final converter = Circles.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    if (!nullToAbsent || orderedAt != null) {
      final converter = Circles.$converter1;
      map['ordered_at'] = Variable<int?>(converter.mapToSql(orderedAt));
    }
    return map;
  }

  CirclesCompanion toCompanion(bool nullToAbsent) {
    return CirclesCompanion(
      circleId: Value(circleId),
      name: Value(name),
      createdAt: Value(createdAt),
      orderedAt: orderedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(orderedAt),
    );
  }

  factory Circle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Circle(
      circleId: serializer.fromJson<String>(json['circle_id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      orderedAt: serializer.fromJson<DateTime?>(json['ordered_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'circle_id': serializer.toJson<String>(circleId),
      'name': serializer.toJson<String>(name),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'ordered_at': serializer.toJson<DateTime?>(orderedAt),
    };
  }

  Circle copyWith(
          {String? circleId,
          String? name,
          DateTime? createdAt,
          DateTime? orderedAt}) =>
      Circle(
        circleId: circleId ?? this.circleId,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        orderedAt: orderedAt ?? this.orderedAt,
      );
  @override
  String toString() {
    return (StringBuffer('Circle(')
          ..write('circleId: $circleId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderedAt: $orderedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(circleId.hashCode,
      $mrjc(name.hashCode, $mrjc(createdAt.hashCode, orderedAt.hashCode))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Circle &&
          other.circleId == this.circleId &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.orderedAt == this.orderedAt);
}

class CirclesCompanion extends UpdateCompanion<Circle> {
  final Value<String> circleId;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime?> orderedAt;
  const CirclesCompanion({
    this.circleId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.orderedAt = const Value.absent(),
  });
  CirclesCompanion.insert({
    required String circleId,
    required String name,
    required DateTime createdAt,
    this.orderedAt = const Value.absent(),
  })  : circleId = Value(circleId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Circle> custom({
    Expression<String>? circleId,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime?>? orderedAt,
  }) {
    return RawValuesInsertable({
      if (circleId != null) 'circle_id': circleId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (orderedAt != null) 'ordered_at': orderedAt,
    });
  }

  CirclesCompanion copyWith(
      {Value<String>? circleId,
      Value<String>? name,
      Value<DateTime>? createdAt,
      Value<DateTime?>? orderedAt}) {
    return CirclesCompanion(
      circleId: circleId ?? this.circleId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      orderedAt: orderedAt ?? this.orderedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (circleId.present) {
      map['circle_id'] = Variable<String>(circleId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      final converter = Circles.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    if (orderedAt.present) {
      final converter = Circles.$converter1;
      map['ordered_at'] = Variable<int?>(converter.mapToSql(orderedAt.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CirclesCompanion(')
          ..write('circleId: $circleId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderedAt: $orderedAt')
          ..write(')'))
        .toString();
  }
}

class Circles extends Table with TableInfo<Circles, Circle> {
  final GeneratedDatabase _db;
  final String? _alias;
  Circles(this._db, [this._alias]);
  final VerificationMeta _circleIdMeta = const VerificationMeta('circleId');
  late final GeneratedTextColumn circleId = _constructCircleId();
  GeneratedTextColumn _constructCircleId() {
    return GeneratedTextColumn('circle_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _orderedAtMeta = const VerificationMeta('orderedAt');
  late final GeneratedIntColumn orderedAt = _constructOrderedAt();
  GeneratedIntColumn _constructOrderedAt() {
    return GeneratedIntColumn('ordered_at', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [circleId, name, createdAt, orderedAt];
  @override
  Circles get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'circles';
  @override
  final String actualTableName = 'circles';
  @override
  VerificationContext validateIntegrity(Insertable<Circle> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('circle_id')) {
      context.handle(_circleIdMeta,
          circleId.isAcceptableOrUnknown(data['circle_id']!, _circleIdMeta));
    } else if (isInserting) {
      context.missing(_circleIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    context.handle(_orderedAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {circleId};
  @override
  Circle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Circle.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Circles createAlias(String alias) {
    return Circles(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  static TypeConverter<DateTime, int> $converter1 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(circle_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class FloodMessage extends DataClass implements Insertable<FloodMessage> {
  final String messageId;
  final String data;
  final DateTime createdAt;
  FloodMessage(
      {required this.messageId, required this.data, required this.createdAt});
  factory FloodMessage.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return FloodMessage(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id'])!,
      data: stringType.mapFromDatabaseResponse(data['${effectivePrefix}data'])!,
      createdAt: FloodMessages.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['data'] = Variable<String>(data);
    {
      final converter = FloodMessages.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    return map;
  }

  FloodMessagesCompanion toCompanion(bool nullToAbsent) {
    return FloodMessagesCompanion(
      messageId: Value(messageId),
      data: Value(data),
      createdAt: Value(createdAt),
    );
  }

  factory FloodMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return FloodMessage(
      messageId: serializer.fromJson<String>(json['message_id']),
      data: serializer.fromJson<String>(json['data']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'data': serializer.toJson<String>(data),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  FloodMessage copyWith(
          {String? messageId, String? data, DateTime? createdAt}) =>
      FloodMessage(
        messageId: messageId ?? this.messageId,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('FloodMessage(')
          ..write('messageId: $messageId, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf(
      $mrjc(messageId.hashCode, $mrjc(data.hashCode, createdAt.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is FloodMessage &&
          other.messageId == this.messageId &&
          other.data == this.data &&
          other.createdAt == this.createdAt);
}

class FloodMessagesCompanion extends UpdateCompanion<FloodMessage> {
  final Value<String> messageId;
  final Value<String> data;
  final Value<DateTime> createdAt;
  const FloodMessagesCompanion({
    this.messageId = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FloodMessagesCompanion.insert({
    required String messageId,
    required String data,
    required DateTime createdAt,
  })   : messageId = Value(messageId),
        data = Value(data),
        createdAt = Value(createdAt);
  static Insertable<FloodMessage> custom({
    Expression<String>? messageId,
    Expression<String>? data,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (data != null) 'data': data,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FloodMessagesCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? data,
      Value<DateTime>? createdAt}) {
    return FloodMessagesCompanion(
      messageId: messageId ?? this.messageId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (createdAt.present) {
      final converter = FloodMessages.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FloodMessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class FloodMessages extends Table with TableInfo<FloodMessages, FloodMessage> {
  final GeneratedDatabase _db;
  final String? _alias;
  FloodMessages(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  late final GeneratedTextColumn messageId = _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _dataMeta = const VerificationMeta('data');
  late final GeneratedTextColumn data = _constructData();
  GeneratedTextColumn _constructData() {
    return GeneratedTextColumn('data', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [messageId, data, createdAt];
  @override
  FloodMessages get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'flood_messages';
  @override
  final String actualTableName = 'flood_messages';
  @override
  VerificationContext validateIntegrity(Insertable<FloodMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  FloodMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return FloodMessage.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  FloodMessages createAlias(String alias) {
    return FloodMessages(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Hyperlink extends DataClass implements Insertable<Hyperlink> {
  final String hyperlink;
  final String siteName;
  final String siteTitle;
  final String? siteDescription;
  final String? siteImage;
  Hyperlink(
      {required this.hyperlink,
      required this.siteName,
      required this.siteTitle,
      this.siteDescription,
      this.siteImage});
  factory Hyperlink.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return Hyperlink(
      hyperlink: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}hyperlink'])!,
      siteName: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}site_name'])!,
      siteTitle: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}site_title'])!,
      siteDescription: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}site_description']),
      siteImage: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}site_image']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hyperlink'] = Variable<String>(hyperlink);
    map['site_name'] = Variable<String>(siteName);
    map['site_title'] = Variable<String>(siteTitle);
    if (!nullToAbsent || siteDescription != null) {
      map['site_description'] = Variable<String?>(siteDescription);
    }
    if (!nullToAbsent || siteImage != null) {
      map['site_image'] = Variable<String?>(siteImage);
    }
    return map;
  }

  HyperlinksCompanion toCompanion(bool nullToAbsent) {
    return HyperlinksCompanion(
      hyperlink: Value(hyperlink),
      siteName: Value(siteName),
      siteTitle: Value(siteTitle),
      siteDescription: siteDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(siteDescription),
      siteImage: siteImage == null && nullToAbsent
          ? const Value.absent()
          : Value(siteImage),
    );
  }

  factory Hyperlink.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Hyperlink(
      hyperlink: serializer.fromJson<String>(json['hyperlink']),
      siteName: serializer.fromJson<String>(json['site_name']),
      siteTitle: serializer.fromJson<String>(json['site_title']),
      siteDescription: serializer.fromJson<String?>(json['site_description']),
      siteImage: serializer.fromJson<String?>(json['site_image']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hyperlink': serializer.toJson<String>(hyperlink),
      'site_name': serializer.toJson<String>(siteName),
      'site_title': serializer.toJson<String>(siteTitle),
      'site_description': serializer.toJson<String?>(siteDescription),
      'site_image': serializer.toJson<String?>(siteImage),
    };
  }

  Hyperlink copyWith(
          {String? hyperlink,
          String? siteName,
          String? siteTitle,
          String? siteDescription,
          String? siteImage}) =>
      Hyperlink(
        hyperlink: hyperlink ?? this.hyperlink,
        siteName: siteName ?? this.siteName,
        siteTitle: siteTitle ?? this.siteTitle,
        siteDescription: siteDescription ?? this.siteDescription,
        siteImage: siteImage ?? this.siteImage,
      );
  @override
  String toString() {
    return (StringBuffer('Hyperlink(')
          ..write('hyperlink: $hyperlink, ')
          ..write('siteName: $siteName, ')
          ..write('siteTitle: $siteTitle, ')
          ..write('siteDescription: $siteDescription, ')
          ..write('siteImage: $siteImage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      hyperlink.hashCode,
      $mrjc(
          siteName.hashCode,
          $mrjc(siteTitle.hashCode,
              $mrjc(siteDescription.hashCode, siteImage.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Hyperlink &&
          other.hyperlink == this.hyperlink &&
          other.siteName == this.siteName &&
          other.siteTitle == this.siteTitle &&
          other.siteDescription == this.siteDescription &&
          other.siteImage == this.siteImage);
}

class HyperlinksCompanion extends UpdateCompanion<Hyperlink> {
  final Value<String> hyperlink;
  final Value<String> siteName;
  final Value<String> siteTitle;
  final Value<String?> siteDescription;
  final Value<String?> siteImage;
  const HyperlinksCompanion({
    this.hyperlink = const Value.absent(),
    this.siteName = const Value.absent(),
    this.siteTitle = const Value.absent(),
    this.siteDescription = const Value.absent(),
    this.siteImage = const Value.absent(),
  });
  HyperlinksCompanion.insert({
    required String hyperlink,
    required String siteName,
    required String siteTitle,
    this.siteDescription = const Value.absent(),
    this.siteImage = const Value.absent(),
  })  : hyperlink = Value(hyperlink),
        siteName = Value(siteName),
        siteTitle = Value(siteTitle);
  static Insertable<Hyperlink> custom({
    Expression<String>? hyperlink,
    Expression<String>? siteName,
    Expression<String>? siteTitle,
    Expression<String?>? siteDescription,
    Expression<String?>? siteImage,
  }) {
    return RawValuesInsertable({
      if (hyperlink != null) 'hyperlink': hyperlink,
      if (siteName != null) 'site_name': siteName,
      if (siteTitle != null) 'site_title': siteTitle,
      if (siteDescription != null) 'site_description': siteDescription,
      if (siteImage != null) 'site_image': siteImage,
    });
  }

  HyperlinksCompanion copyWith(
      {Value<String>? hyperlink,
      Value<String>? siteName,
      Value<String>? siteTitle,
      Value<String?>? siteDescription,
      Value<String?>? siteImage}) {
    return HyperlinksCompanion(
      hyperlink: hyperlink ?? this.hyperlink,
      siteName: siteName ?? this.siteName,
      siteTitle: siteTitle ?? this.siteTitle,
      siteDescription: siteDescription ?? this.siteDescription,
      siteImage: siteImage ?? this.siteImage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hyperlink.present) {
      map['hyperlink'] = Variable<String>(hyperlink.value);
    }
    if (siteName.present) {
      map['site_name'] = Variable<String>(siteName.value);
    }
    if (siteTitle.present) {
      map['site_title'] = Variable<String>(siteTitle.value);
    }
    if (siteDescription.present) {
      map['site_description'] = Variable<String?>(siteDescription.value);
    }
    if (siteImage.present) {
      map['site_image'] = Variable<String?>(siteImage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HyperlinksCompanion(')
          ..write('hyperlink: $hyperlink, ')
          ..write('siteName: $siteName, ')
          ..write('siteTitle: $siteTitle, ')
          ..write('siteDescription: $siteDescription, ')
          ..write('siteImage: $siteImage')
          ..write(')'))
        .toString();
  }
}

class Hyperlinks extends Table with TableInfo<Hyperlinks, Hyperlink> {
  final GeneratedDatabase _db;
  final String? _alias;
  Hyperlinks(this._db, [this._alias]);
  final VerificationMeta _hyperlinkMeta = const VerificationMeta('hyperlink');
  late final GeneratedTextColumn hyperlink = _constructHyperlink();
  GeneratedTextColumn _constructHyperlink() {
    return GeneratedTextColumn('hyperlink', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _siteNameMeta = const VerificationMeta('siteName');
  late final GeneratedTextColumn siteName = _constructSiteName();
  GeneratedTextColumn _constructSiteName() {
    return GeneratedTextColumn('site_name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _siteTitleMeta = const VerificationMeta('siteTitle');
  late final GeneratedTextColumn siteTitle = _constructSiteTitle();
  GeneratedTextColumn _constructSiteTitle() {
    return GeneratedTextColumn('site_title', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _siteDescriptionMeta =
      const VerificationMeta('siteDescription');
  late final GeneratedTextColumn siteDescription = _constructSiteDescription();
  GeneratedTextColumn _constructSiteDescription() {
    return GeneratedTextColumn('site_description', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _siteImageMeta = const VerificationMeta('siteImage');
  late final GeneratedTextColumn siteImage = _constructSiteImage();
  GeneratedTextColumn _constructSiteImage() {
    return GeneratedTextColumn('site_image', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [hyperlink, siteName, siteTitle, siteDescription, siteImage];
  @override
  Hyperlinks get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'hyperlinks';
  @override
  final String actualTableName = 'hyperlinks';
  @override
  VerificationContext validateIntegrity(Insertable<Hyperlink> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hyperlink')) {
      context.handle(_hyperlinkMeta,
          hyperlink.isAcceptableOrUnknown(data['hyperlink']!, _hyperlinkMeta));
    } else if (isInserting) {
      context.missing(_hyperlinkMeta);
    }
    if (data.containsKey('site_name')) {
      context.handle(_siteNameMeta,
          siteName.isAcceptableOrUnknown(data['site_name']!, _siteNameMeta));
    } else if (isInserting) {
      context.missing(_siteNameMeta);
    }
    if (data.containsKey('site_title')) {
      context.handle(_siteTitleMeta,
          siteTitle.isAcceptableOrUnknown(data['site_title']!, _siteTitleMeta));
    } else if (isInserting) {
      context.missing(_siteTitleMeta);
    }
    if (data.containsKey('site_description')) {
      context.handle(
          _siteDescriptionMeta,
          siteDescription.isAcceptableOrUnknown(
              data['site_description']!, _siteDescriptionMeta));
    }
    if (data.containsKey('site_image')) {
      context.handle(_siteImageMeta,
          siteImage.isAcceptableOrUnknown(data['site_image']!, _siteImageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hyperlink};
  @override
  Hyperlink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Hyperlink.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Hyperlinks createAlias(String alias) {
    return Hyperlinks(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(hyperlink)'];
  @override
  bool get dontWriteConstraints => true;
}

class MessagesFt extends DataClass implements Insertable<MessagesFt> {
  final String messageId;
  final String conversationId;
  final String content;
  final String createdAt;
  final String userId;
  final String reservedInt;
  final String reservedText;
  MessagesFt(
      {required this.messageId,
      required this.conversationId,
      required this.content,
      required this.createdAt,
      required this.userId,
      required this.reservedInt,
      required this.reservedText});
  factory MessagesFt.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return MessagesFt(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id'])!,
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id'])!,
      content: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}content'])!,
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at'])!,
      userId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      reservedInt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}reserved_int'])!,
      reservedText: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}reserved_text'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<String>(createdAt);
    map['user_id'] = Variable<String>(userId);
    map['reserved_int'] = Variable<String>(reservedInt);
    map['reserved_text'] = Variable<String>(reservedText);
    return map;
  }

  MessagesFtsCompanion toCompanion(bool nullToAbsent) {
    return MessagesFtsCompanion(
      messageId: Value(messageId),
      conversationId: Value(conversationId),
      content: Value(content),
      createdAt: Value(createdAt),
      userId: Value(userId),
      reservedInt: Value(reservedInt),
      reservedText: Value(reservedText),
    );
  }

  factory MessagesFt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return MessagesFt(
      messageId: serializer.fromJson<String>(json['message_id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      userId: serializer.fromJson<String>(json['user_id']),
      reservedInt: serializer.fromJson<String>(json['reserved_int']),
      reservedText: serializer.fromJson<String>(json['reserved_text']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'conversation_id': serializer.toJson<String>(conversationId),
      'content': serializer.toJson<String>(content),
      'created_at': serializer.toJson<String>(createdAt),
      'user_id': serializer.toJson<String>(userId),
      'reserved_int': serializer.toJson<String>(reservedInt),
      'reserved_text': serializer.toJson<String>(reservedText),
    };
  }

  MessagesFt copyWith(
          {String? messageId,
          String? conversationId,
          String? content,
          String? createdAt,
          String? userId,
          String? reservedInt,
          String? reservedText}) =>
      MessagesFt(
        messageId: messageId ?? this.messageId,
        conversationId: conversationId ?? this.conversationId,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        userId: userId ?? this.userId,
        reservedInt: reservedInt ?? this.reservedInt,
        reservedText: reservedText ?? this.reservedText,
      );
  @override
  String toString() {
    return (StringBuffer('MessagesFt(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('reservedInt: $reservedInt, ')
          ..write('reservedText: $reservedText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      messageId.hashCode,
      $mrjc(
          conversationId.hashCode,
          $mrjc(
              content.hashCode,
              $mrjc(
                  createdAt.hashCode,
                  $mrjc(userId.hashCode,
                      $mrjc(reservedInt.hashCode, reservedText.hashCode)))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is MessagesFt &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.userId == this.userId &&
          other.reservedInt == this.reservedInt &&
          other.reservedText == this.reservedText);
}

class MessagesFtsCompanion extends UpdateCompanion<MessagesFt> {
  final Value<String> messageId;
  final Value<String> conversationId;
  final Value<String> content;
  final Value<String> createdAt;
  final Value<String> userId;
  final Value<String> reservedInt;
  final Value<String> reservedText;
  const MessagesFtsCompanion({
    this.messageId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.reservedInt = const Value.absent(),
    this.reservedText = const Value.absent(),
  });
  MessagesFtsCompanion.insert({
    required String messageId,
    required String conversationId,
    required String content,
    required String createdAt,
    required String userId,
    required String reservedInt,
    required String reservedText,
  })   : messageId = Value(messageId),
        conversationId = Value(conversationId),
        content = Value(content),
        createdAt = Value(createdAt),
        userId = Value(userId),
        reservedInt = Value(reservedInt),
        reservedText = Value(reservedText);
  static Insertable<MessagesFt> custom({
    Expression<String>? messageId,
    Expression<String>? conversationId,
    Expression<String>? content,
    Expression<String>? createdAt,
    Expression<String>? userId,
    Expression<String>? reservedInt,
    Expression<String>? reservedText,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (userId != null) 'user_id': userId,
      if (reservedInt != null) 'reserved_int': reservedInt,
      if (reservedText != null) 'reserved_text': reservedText,
    });
  }

  MessagesFtsCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? conversationId,
      Value<String>? content,
      Value<String>? createdAt,
      Value<String>? userId,
      Value<String>? reservedInt,
      Value<String>? reservedText}) {
    return MessagesFtsCompanion(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      reservedInt: reservedInt ?? this.reservedInt,
      reservedText: reservedText ?? this.reservedText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (reservedInt.present) {
      map['reserved_int'] = Variable<String>(reservedInt.value);
    }
    if (reservedText.present) {
      map['reserved_text'] = Variable<String>(reservedText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesFtsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('reservedInt: $reservedInt, ')
          ..write('reservedText: $reservedText')
          ..write(')'))
        .toString();
  }
}

class MessagesFts extends Table
    with
        TableInfo<MessagesFts, MessagesFt>,
        VirtualTableInfo<MessagesFts, MessagesFt> {
  final GeneratedDatabase _db;
  final String? _alias;
  MessagesFts(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  late final GeneratedTextColumn messageId = _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: '');
  }

  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedTextColumn conversationId = _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: '');
  }

  final VerificationMeta _contentMeta = const VerificationMeta('content');
  late final GeneratedTextColumn content = _constructContent();
  GeneratedTextColumn _constructContent() {
    return GeneratedTextColumn('content', $tableName, false,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedTextColumn createdAt = _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
        $customConstraints: '');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: '');
  }

  final VerificationMeta _reservedIntMeta =
      const VerificationMeta('reservedInt');
  late final GeneratedTextColumn reservedInt = _constructReservedInt();
  GeneratedTextColumn _constructReservedInt() {
    return GeneratedTextColumn('reserved_int', $tableName, false,
        $customConstraints: '');
  }

  final VerificationMeta _reservedTextMeta =
      const VerificationMeta('reservedText');
  late final GeneratedTextColumn reservedText = _constructReservedText();
  GeneratedTextColumn _constructReservedText() {
    return GeneratedTextColumn('reserved_text', $tableName, false,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [
        messageId,
        conversationId,
        content,
        createdAt,
        userId,
        reservedInt,
        reservedText
      ];
  @override
  MessagesFts get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'messages_fts';
  @override
  final String actualTableName = 'messages_fts';
  @override
  VerificationContext validateIntegrity(Insertable<MessagesFt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('reserved_int')) {
      context.handle(
          _reservedIntMeta,
          reservedInt.isAcceptableOrUnknown(
              data['reserved_int']!, _reservedIntMeta));
    } else if (isInserting) {
      context.missing(_reservedIntMeta);
    }
    if (data.containsKey('reserved_text')) {
      context.handle(
          _reservedTextMeta,
          reservedText.isAcceptableOrUnknown(
              data['reserved_text']!, _reservedTextMeta));
    } else if (isInserting) {
      context.missing(_reservedTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  MessagesFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return MessagesFt.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  MessagesFts createAlias(String alias) {
    return MessagesFts(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'FTS5(message_id UNINDEXED, conversation_id UNINDEXED, content, created_at UNINDEXED, user_id UNINDEXED, reserved_int UNINDEXED, reserved_text UNINDEXED, tokenize=\'unicode61\')';
}

class MessagesHistoryData extends DataClass
    implements Insertable<MessagesHistoryData> {
  final String messageId;
  MessagesHistoryData({required this.messageId});
  factory MessagesHistoryData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return MessagesHistoryData(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    return map;
  }

  MessagesHistoryCompanion toCompanion(bool nullToAbsent) {
    return MessagesHistoryCompanion(
      messageId: Value(messageId),
    );
  }

  factory MessagesHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return MessagesHistoryData(
      messageId: serializer.fromJson<String>(json['message_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
    };
  }

  MessagesHistoryData copyWith({String? messageId}) => MessagesHistoryData(
        messageId: messageId ?? this.messageId,
      );
  @override
  String toString() {
    return (StringBuffer('MessagesHistoryData(')
          ..write('messageId: $messageId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf(messageId.hashCode);
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is MessagesHistoryData && other.messageId == this.messageId);
}

class MessagesHistoryCompanion extends UpdateCompanion<MessagesHistoryData> {
  final Value<String> messageId;
  const MessagesHistoryCompanion({
    this.messageId = const Value.absent(),
  });
  MessagesHistoryCompanion.insert({
    required String messageId,
  }) : messageId = Value(messageId);
  static Insertable<MessagesHistoryData> custom({
    Expression<String>? messageId,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
    });
  }

  MessagesHistoryCompanion copyWith({Value<String>? messageId}) {
    return MessagesHistoryCompanion(
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesHistoryCompanion(')
          ..write('messageId: $messageId')
          ..write(')'))
        .toString();
  }
}

class MessagesHistory extends Table
    with TableInfo<MessagesHistory, MessagesHistoryData> {
  final GeneratedDatabase _db;
  final String? _alias;
  MessagesHistory(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  late final GeneratedTextColumn messageId = _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [messageId];
  @override
  MessagesHistory get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'messages_history';
  @override
  final String actualTableName = 'messages_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<MessagesHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  MessagesHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return MessagesHistoryData.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  MessagesHistory createAlias(String alias) {
    return MessagesHistory(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Offset extends DataClass implements Insertable<Offset> {
  final String key;
  final String timestamp;
  Offset({required this.key, required this.timestamp});
  factory Offset.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return Offset(
      key: stringType.mapFromDatabaseResponse(data['${effectivePrefix}key'])!,
      timestamp: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}timestamp'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['timestamp'] = Variable<String>(timestamp);
    return map;
  }

  OffsetsCompanion toCompanion(bool nullToAbsent) {
    return OffsetsCompanion(
      key: Value(key),
      timestamp: Value(timestamp),
    );
  }

  factory Offset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Offset(
      key: serializer.fromJson<String>(json['key']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'timestamp': serializer.toJson<String>(timestamp),
    };
  }

  Offset copyWith({String? key, String? timestamp}) => Offset(
        key: key ?? this.key,
        timestamp: timestamp ?? this.timestamp,
      );
  @override
  String toString() {
    return (StringBuffer('Offset(')
          ..write('key: $key, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(key.hashCode, timestamp.hashCode));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Offset &&
          other.key == this.key &&
          other.timestamp == this.timestamp);
}

class OffsetsCompanion extends UpdateCompanion<Offset> {
  final Value<String> key;
  final Value<String> timestamp;
  const OffsetsCompanion({
    this.key = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  OffsetsCompanion.insert({
    required String key,
    required String timestamp,
  })   : key = Value(key),
        timestamp = Value(timestamp);
  static Insertable<Offset> custom({
    Expression<String>? key,
    Expression<String>? timestamp,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  OffsetsCompanion copyWith({Value<String>? key, Value<String>? timestamp}) {
    return OffsetsCompanion(
      key: key ?? this.key,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OffsetsCompanion(')
          ..write('key: $key, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class Offsets extends Table with TableInfo<Offsets, Offset> {
  final GeneratedDatabase _db;
  final String? _alias;
  Offsets(this._db, [this._alias]);
  final VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedTextColumn key = _constructKey();
  GeneratedTextColumn _constructKey() {
    return GeneratedTextColumn('key', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  late final GeneratedTextColumn timestamp = _constructTimestamp();
  GeneratedTextColumn _constructTimestamp() {
    return GeneratedTextColumn('timestamp', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [key, timestamp];
  @override
  Offsets get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'offsets';
  @override
  final String actualTableName = 'offsets';
  @override
  VerificationContext validateIntegrity(Insertable<Offset> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Offset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Offset.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Offsets createAlias(String alias) {
    return Offsets(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY("key")'];
  @override
  bool get dontWriteConstraints => true;
}

class ParticipantSessionData extends DataClass
    implements Insertable<ParticipantSessionData> {
  final String conversationId;
  final String userId;
  final String sessionId;
  final int? sentToServer;
  final DateTime? createdAt;
  ParticipantSessionData(
      {required this.conversationId,
      required this.userId,
      required this.sessionId,
      this.sentToServer,
      this.createdAt});
  factory ParticipantSessionData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return ParticipantSessionData(
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id'])!,
      userId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      sessionId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}session_id'])!,
      sentToServer: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}sent_to_server']),
      createdAt: ParticipantSession.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['user_id'] = Variable<String>(userId);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || sentToServer != null) {
      map['sent_to_server'] = Variable<int?>(sentToServer);
    }
    if (!nullToAbsent || createdAt != null) {
      final converter = ParticipantSession.$converter0;
      map['created_at'] = Variable<int?>(converter.mapToSql(createdAt));
    }
    return map;
  }

  ParticipantSessionCompanion toCompanion(bool nullToAbsent) {
    return ParticipantSessionCompanion(
      conversationId: Value(conversationId),
      userId: Value(userId),
      sessionId: Value(sessionId),
      sentToServer: sentToServer == null && nullToAbsent
          ? const Value.absent()
          : Value(sentToServer),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory ParticipantSessionData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return ParticipantSessionData(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      sentToServer: serializer.fromJson<int?>(json['sent_to_server']),
      createdAt: serializer.fromJson<DateTime?>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversation_id': serializer.toJson<String>(conversationId),
      'user_id': serializer.toJson<String>(userId),
      'session_id': serializer.toJson<String>(sessionId),
      'sent_to_server': serializer.toJson<int?>(sentToServer),
      'created_at': serializer.toJson<DateTime?>(createdAt),
    };
  }

  ParticipantSessionData copyWith(
          {String? conversationId,
          String? userId,
          String? sessionId,
          int? sentToServer,
          DateTime? createdAt}) =>
      ParticipantSessionData(
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        sessionId: sessionId ?? this.sessionId,
        sentToServer: sentToServer ?? this.sentToServer,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('ParticipantSessionData(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('sentToServer: $sentToServer, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      conversationId.hashCode,
      $mrjc(
          userId.hashCode,
          $mrjc(sessionId.hashCode,
              $mrjc(sentToServer.hashCode, createdAt.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is ParticipantSessionData &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.sentToServer == this.sentToServer &&
          other.createdAt == this.createdAt);
}

class ParticipantSessionCompanion
    extends UpdateCompanion<ParticipantSessionData> {
  final Value<String> conversationId;
  final Value<String> userId;
  final Value<String> sessionId;
  final Value<int?> sentToServer;
  final Value<DateTime?> createdAt;
  const ParticipantSessionCompanion({
    this.conversationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sentToServer = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ParticipantSessionCompanion.insert({
    required String conversationId,
    required String userId,
    required String sessionId,
    this.sentToServer = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : conversationId = Value(conversationId),
        userId = Value(userId),
        sessionId = Value(sessionId);
  static Insertable<ParticipantSessionData> custom({
    Expression<String>? conversationId,
    Expression<String>? userId,
    Expression<String>? sessionId,
    Expression<int?>? sentToServer,
    Expression<DateTime?>? createdAt,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (sentToServer != null) 'sent_to_server': sentToServer,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ParticipantSessionCompanion copyWith(
      {Value<String>? conversationId,
      Value<String>? userId,
      Value<String>? sessionId,
      Value<int?>? sentToServer,
      Value<DateTime?>? createdAt}) {
    return ParticipantSessionCompanion(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      sentToServer: sentToServer ?? this.sentToServer,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sentToServer.present) {
      map['sent_to_server'] = Variable<int?>(sentToServer.value);
    }
    if (createdAt.present) {
      final converter = ParticipantSession.$converter0;
      map['created_at'] = Variable<int?>(converter.mapToSql(createdAt.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParticipantSessionCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('sentToServer: $sentToServer, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class ParticipantSession extends Table
    with TableInfo<ParticipantSession, ParticipantSessionData> {
  final GeneratedDatabase _db;
  final String? _alias;
  ParticipantSession(this._db, [this._alias]);
  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedTextColumn conversationId = _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  late final GeneratedTextColumn sessionId = _constructSessionId();
  GeneratedTextColumn _constructSessionId() {
    return GeneratedTextColumn('session_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _sentToServerMeta =
      const VerificationMeta('sentToServer');
  late final GeneratedIntColumn sentToServer = _constructSentToServer();
  GeneratedIntColumn _constructSentToServer() {
    return GeneratedIntColumn('sent_to_server', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [conversationId, userId, sessionId, sentToServer, createdAt];
  @override
  ParticipantSession get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'participant_session';
  @override
  final String actualTableName = 'participant_session';
  @override
  VerificationContext validateIntegrity(
      Insertable<ParticipantSessionData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('sent_to_server')) {
      context.handle(
          _sentToServerMeta,
          sentToServer.isAcceptableOrUnknown(
              data['sent_to_server']!, _sentToServerMeta));
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, userId, sessionId};
  @override
  ParticipantSessionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return ParticipantSessionData.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  ParticipantSession createAlias(String alias) {
    return ParticipantSession(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(conversation_id, user_id, session_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class RatchetSenderKey extends DataClass
    implements Insertable<RatchetSenderKey> {
  final String groupId;
  final String senderId;
  final String status;
  final String? messageId;
  final DateTime createdAt;
  RatchetSenderKey(
      {required this.groupId,
      required this.senderId,
      required this.status,
      this.messageId,
      required this.createdAt});
  factory RatchetSenderKey.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return RatchetSenderKey(
      groupId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}group_id'])!,
      senderId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}sender_id'])!,
      status:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}status'])!,
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id']),
      createdAt: RatchetSenderKeys.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['sender_id'] = Variable<String>(senderId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String?>(messageId);
    }
    {
      final converter = RatchetSenderKeys.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    return map;
  }

  RatchetSenderKeysCompanion toCompanion(bool nullToAbsent) {
    return RatchetSenderKeysCompanion(
      groupId: Value(groupId),
      senderId: Value(senderId),
      status: Value(status),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      createdAt: Value(createdAt),
    );
  }

  factory RatchetSenderKey.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return RatchetSenderKey(
      groupId: serializer.fromJson<String>(json['group_id']),
      senderId: serializer.fromJson<String>(json['sender_id']),
      status: serializer.fromJson<String>(json['status']),
      messageId: serializer.fromJson<String?>(json['message_id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'group_id': serializer.toJson<String>(groupId),
      'sender_id': serializer.toJson<String>(senderId),
      'status': serializer.toJson<String>(status),
      'message_id': serializer.toJson<String?>(messageId),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  RatchetSenderKey copyWith(
          {String? groupId,
          String? senderId,
          String? status,
          String? messageId,
          DateTime? createdAt}) =>
      RatchetSenderKey(
        groupId: groupId ?? this.groupId,
        senderId: senderId ?? this.senderId,
        status: status ?? this.status,
        messageId: messageId ?? this.messageId,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('RatchetSenderKey(')
          ..write('groupId: $groupId, ')
          ..write('senderId: $senderId, ')
          ..write('status: $status, ')
          ..write('messageId: $messageId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      groupId.hashCode,
      $mrjc(
          senderId.hashCode,
          $mrjc(status.hashCode,
              $mrjc(messageId.hashCode, createdAt.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is RatchetSenderKey &&
          other.groupId == this.groupId &&
          other.senderId == this.senderId &&
          other.status == this.status &&
          other.messageId == this.messageId &&
          other.createdAt == this.createdAt);
}

class RatchetSenderKeysCompanion extends UpdateCompanion<RatchetSenderKey> {
  final Value<String> groupId;
  final Value<String> senderId;
  final Value<String> status;
  final Value<String?> messageId;
  final Value<DateTime> createdAt;
  const RatchetSenderKeysCompanion({
    this.groupId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.status = const Value.absent(),
    this.messageId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RatchetSenderKeysCompanion.insert({
    required String groupId,
    required String senderId,
    required String status,
    this.messageId = const Value.absent(),
    required DateTime createdAt,
  })   : groupId = Value(groupId),
        senderId = Value(senderId),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<RatchetSenderKey> custom({
    Expression<String>? groupId,
    Expression<String>? senderId,
    Expression<String>? status,
    Expression<String?>? messageId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (senderId != null) 'sender_id': senderId,
      if (status != null) 'status': status,
      if (messageId != null) 'message_id': messageId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RatchetSenderKeysCompanion copyWith(
      {Value<String>? groupId,
      Value<String>? senderId,
      Value<String>? status,
      Value<String?>? messageId,
      Value<DateTime>? createdAt}) {
    return RatchetSenderKeysCompanion(
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      status: status ?? this.status,
      messageId: messageId ?? this.messageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String?>(messageId.value);
    }
    if (createdAt.present) {
      final converter = RatchetSenderKeys.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatchetSenderKeysCompanion(')
          ..write('groupId: $groupId, ')
          ..write('senderId: $senderId, ')
          ..write('status: $status, ')
          ..write('messageId: $messageId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class RatchetSenderKeys extends Table
    with TableInfo<RatchetSenderKeys, RatchetSenderKey> {
  final GeneratedDatabase _db;
  final String? _alias;
  RatchetSenderKeys(this._db, [this._alias]);
  final VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  late final GeneratedTextColumn groupId = _constructGroupId();
  GeneratedTextColumn _constructGroupId() {
    return GeneratedTextColumn('group_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _senderIdMeta = const VerificationMeta('senderId');
  late final GeneratedTextColumn senderId = _constructSenderId();
  GeneratedTextColumn _constructSenderId() {
    return GeneratedTextColumn('sender_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedTextColumn status = _constructStatus();
  GeneratedTextColumn _constructStatus() {
    return GeneratedTextColumn('status', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  late final GeneratedTextColumn messageId = _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [groupId, senderId, status, messageId, createdAt];
  @override
  RatchetSenderKeys get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'ratchet_sender_keys';
  @override
  final String actualTableName = 'ratchet_sender_keys';
  @override
  VerificationContext validateIntegrity(Insertable<RatchetSenderKey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, senderId};
  @override
  RatchetSenderKey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return RatchetSenderKey.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  RatchetSenderKeys createAlias(String alias) {
    return RatchetSenderKeys(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(group_id, sender_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class ResendSessionMessage extends DataClass
    implements Insertable<ResendSessionMessage> {
  final String messageId;
  final String userId;
  final String sessionId;
  final int status;
  final DateTime createdAt;
  ResendSessionMessage(
      {required this.messageId,
      required this.userId,
      required this.sessionId,
      required this.status,
      required this.createdAt});
  factory ResendSessionMessage.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return ResendSessionMessage(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id'])!,
      userId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      sessionId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}session_id'])!,
      status:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}status'])!,
      createdAt: ResendSessionMessages.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['user_id'] = Variable<String>(userId);
    map['session_id'] = Variable<String>(sessionId);
    map['status'] = Variable<int>(status);
    {
      final converter = ResendSessionMessages.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    return map;
  }

  ResendSessionMessagesCompanion toCompanion(bool nullToAbsent) {
    return ResendSessionMessagesCompanion(
      messageId: Value(messageId),
      userId: Value(userId),
      sessionId: Value(sessionId),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory ResendSessionMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return ResendSessionMessage(
      messageId: serializer.fromJson<String>(json['message_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      status: serializer.fromJson<int>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'user_id': serializer.toJson<String>(userId),
      'session_id': serializer.toJson<String>(sessionId),
      'status': serializer.toJson<int>(status),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  ResendSessionMessage copyWith(
          {String? messageId,
          String? userId,
          String? sessionId,
          int? status,
          DateTime? createdAt}) =>
      ResendSessionMessage(
        messageId: messageId ?? this.messageId,
        userId: userId ?? this.userId,
        sessionId: sessionId ?? this.sessionId,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('ResendSessionMessage(')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      messageId.hashCode,
      $mrjc(
          userId.hashCode,
          $mrjc(sessionId.hashCode,
              $mrjc(status.hashCode, createdAt.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is ResendSessionMessage &&
          other.messageId == this.messageId &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class ResendSessionMessagesCompanion
    extends UpdateCompanion<ResendSessionMessage> {
  final Value<String> messageId;
  final Value<String> userId;
  final Value<String> sessionId;
  final Value<int> status;
  final Value<DateTime> createdAt;
  const ResendSessionMessagesCompanion({
    this.messageId = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ResendSessionMessagesCompanion.insert({
    required String messageId,
    required String userId,
    required String sessionId,
    required int status,
    required DateTime createdAt,
  })   : messageId = Value(messageId),
        userId = Value(userId),
        sessionId = Value(sessionId),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<ResendSessionMessage> custom({
    Expression<String>? messageId,
    Expression<String>? userId,
    Expression<String>? sessionId,
    Expression<int>? status,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ResendSessionMessagesCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? userId,
      Value<String>? sessionId,
      Value<int>? status,
      Value<DateTime>? createdAt}) {
    return ResendSessionMessagesCompanion(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (createdAt.present) {
      final converter = ResendSessionMessages.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResendSessionMessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class ResendSessionMessages extends Table
    with TableInfo<ResendSessionMessages, ResendSessionMessage> {
  final GeneratedDatabase _db;
  final String? _alias;
  ResendSessionMessages(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  late final GeneratedTextColumn messageId = _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  late final GeneratedTextColumn sessionId = _constructSessionId();
  GeneratedTextColumn _constructSessionId() {
    return GeneratedTextColumn('session_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedIntColumn status = _constructStatus();
  GeneratedIntColumn _constructStatus() {
    return GeneratedIntColumn('status', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [messageId, userId, sessionId, status, createdAt];
  @override
  ResendSessionMessages get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'resend_session_messages';
  @override
  final String actualTableName = 'resend_session_messages';
  @override
  VerificationContext validateIntegrity(
      Insertable<ResendSessionMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, userId, sessionId};
  @override
  ResendSessionMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return ResendSessionMessage.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  ResendSessionMessages createAlias(String alias) {
    return ResendSessionMessages(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(message_id, user_id, session_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class SentSessionSenderKey extends DataClass
    implements Insertable<SentSessionSenderKey> {
  final String conversationId;
  final String userId;
  final String sessionId;
  final int sentToServer;
  final int? senderKeyId;
  final DateTime? createdAt;
  SentSessionSenderKey(
      {required this.conversationId,
      required this.userId,
      required this.sessionId,
      required this.sentToServer,
      this.senderKeyId,
      this.createdAt});
  factory SentSessionSenderKey.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return SentSessionSenderKey(
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id'])!,
      userId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      sessionId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}session_id'])!,
      sentToServer: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}sent_to_server'])!,
      senderKeyId: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}sender_key_id']),
      createdAt: SentSessionSenderKeys.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['user_id'] = Variable<String>(userId);
    map['session_id'] = Variable<String>(sessionId);
    map['sent_to_server'] = Variable<int>(sentToServer);
    if (!nullToAbsent || senderKeyId != null) {
      map['sender_key_id'] = Variable<int?>(senderKeyId);
    }
    if (!nullToAbsent || createdAt != null) {
      final converter = SentSessionSenderKeys.$converter0;
      map['created_at'] = Variable<int?>(converter.mapToSql(createdAt));
    }
    return map;
  }

  SentSessionSenderKeysCompanion toCompanion(bool nullToAbsent) {
    return SentSessionSenderKeysCompanion(
      conversationId: Value(conversationId),
      userId: Value(userId),
      sessionId: Value(sessionId),
      sentToServer: Value(sentToServer),
      senderKeyId: senderKeyId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderKeyId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory SentSessionSenderKey.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return SentSessionSenderKey(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      sentToServer: serializer.fromJson<int>(json['sent_to_server']),
      senderKeyId: serializer.fromJson<int?>(json['sender_key_id']),
      createdAt: serializer.fromJson<DateTime?>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversation_id': serializer.toJson<String>(conversationId),
      'user_id': serializer.toJson<String>(userId),
      'session_id': serializer.toJson<String>(sessionId),
      'sent_to_server': serializer.toJson<int>(sentToServer),
      'sender_key_id': serializer.toJson<int?>(senderKeyId),
      'created_at': serializer.toJson<DateTime?>(createdAt),
    };
  }

  SentSessionSenderKey copyWith(
          {String? conversationId,
          String? userId,
          String? sessionId,
          int? sentToServer,
          int? senderKeyId,
          DateTime? createdAt}) =>
      SentSessionSenderKey(
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        sessionId: sessionId ?? this.sessionId,
        sentToServer: sentToServer ?? this.sentToServer,
        senderKeyId: senderKeyId ?? this.senderKeyId,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('SentSessionSenderKey(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('sentToServer: $sentToServer, ')
          ..write('senderKeyId: $senderKeyId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      conversationId.hashCode,
      $mrjc(
          userId.hashCode,
          $mrjc(
              sessionId.hashCode,
              $mrjc(sentToServer.hashCode,
                  $mrjc(senderKeyId.hashCode, createdAt.hashCode))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is SentSessionSenderKey &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.sentToServer == this.sentToServer &&
          other.senderKeyId == this.senderKeyId &&
          other.createdAt == this.createdAt);
}

class SentSessionSenderKeysCompanion
    extends UpdateCompanion<SentSessionSenderKey> {
  final Value<String> conversationId;
  final Value<String> userId;
  final Value<String> sessionId;
  final Value<int> sentToServer;
  final Value<int?> senderKeyId;
  final Value<DateTime?> createdAt;
  const SentSessionSenderKeysCompanion({
    this.conversationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sentToServer = const Value.absent(),
    this.senderKeyId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SentSessionSenderKeysCompanion.insert({
    required String conversationId,
    required String userId,
    required String sessionId,
    required int sentToServer,
    this.senderKeyId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : conversationId = Value(conversationId),
        userId = Value(userId),
        sessionId = Value(sessionId),
        sentToServer = Value(sentToServer);
  static Insertable<SentSessionSenderKey> custom({
    Expression<String>? conversationId,
    Expression<String>? userId,
    Expression<String>? sessionId,
    Expression<int>? sentToServer,
    Expression<int?>? senderKeyId,
    Expression<DateTime?>? createdAt,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (sentToServer != null) 'sent_to_server': sentToServer,
      if (senderKeyId != null) 'sender_key_id': senderKeyId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SentSessionSenderKeysCompanion copyWith(
      {Value<String>? conversationId,
      Value<String>? userId,
      Value<String>? sessionId,
      Value<int>? sentToServer,
      Value<int?>? senderKeyId,
      Value<DateTime?>? createdAt}) {
    return SentSessionSenderKeysCompanion(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      sentToServer: sentToServer ?? this.sentToServer,
      senderKeyId: senderKeyId ?? this.senderKeyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sentToServer.present) {
      map['sent_to_server'] = Variable<int>(sentToServer.value);
    }
    if (senderKeyId.present) {
      map['sender_key_id'] = Variable<int?>(senderKeyId.value);
    }
    if (createdAt.present) {
      final converter = SentSessionSenderKeys.$converter0;
      map['created_at'] = Variable<int?>(converter.mapToSql(createdAt.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SentSessionSenderKeysCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('sentToServer: $sentToServer, ')
          ..write('senderKeyId: $senderKeyId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class SentSessionSenderKeys extends Table
    with TableInfo<SentSessionSenderKeys, SentSessionSenderKey> {
  final GeneratedDatabase _db;
  final String? _alias;
  SentSessionSenderKeys(this._db, [this._alias]);
  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedTextColumn conversationId = _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  late final GeneratedTextColumn sessionId = _constructSessionId();
  GeneratedTextColumn _constructSessionId() {
    return GeneratedTextColumn('session_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _sentToServerMeta =
      const VerificationMeta('sentToServer');
  late final GeneratedIntColumn sentToServer = _constructSentToServer();
  GeneratedIntColumn _constructSentToServer() {
    return GeneratedIntColumn('sent_to_server', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _senderKeyIdMeta =
      const VerificationMeta('senderKeyId');
  late final GeneratedIntColumn senderKeyId = _constructSenderKeyId();
  GeneratedIntColumn _constructSenderKeyId() {
    return GeneratedIntColumn('sender_key_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [conversationId, userId, sessionId, sentToServer, senderKeyId, createdAt];
  @override
  SentSessionSenderKeys get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'sent_session_sender_keys';
  @override
  final String actualTableName = 'sent_session_sender_keys';
  @override
  VerificationContext validateIntegrity(
      Insertable<SentSessionSenderKey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('sent_to_server')) {
      context.handle(
          _sentToServerMeta,
          sentToServer.isAcceptableOrUnknown(
              data['sent_to_server']!, _sentToServerMeta));
    } else if (isInserting) {
      context.missing(_sentToServerMeta);
    }
    if (data.containsKey('sender_key_id')) {
      context.handle(
          _senderKeyIdMeta,
          senderKeyId.isAcceptableOrUnknown(
              data['sender_key_id']!, _senderKeyIdMeta));
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, userId, sessionId};
  @override
  SentSessionSenderKey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return SentSessionSenderKey.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  SentSessionSenderKeys createAlias(String alias) {
    return SentSessionSenderKeys(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(conversation_id,user_id, session_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class StickerAlbum extends DataClass implements Insertable<StickerAlbum> {
  final String albumId;
  final String name;
  final String iconUrl;
  final DateTime createdAt;
  final DateTime updateAt;
  final String userId;
  final String category;
  final String description;
  StickerAlbum(
      {required this.albumId,
      required this.name,
      required this.iconUrl,
      required this.createdAt,
      required this.updateAt,
      required this.userId,
      required this.category,
      required this.description});
  factory StickerAlbum.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return StickerAlbum(
      albumId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}album_id'])!,
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      iconUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}icon_url'])!,
      createdAt: StickerAlbums.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
      updateAt: StickerAlbums.$converter1.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}update_at']))!,
      userId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      category: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}category'])!,
      description: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}description'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['album_id'] = Variable<String>(albumId);
    map['name'] = Variable<String>(name);
    map['icon_url'] = Variable<String>(iconUrl);
    {
      final converter = StickerAlbums.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    {
      final converter = StickerAlbums.$converter1;
      map['update_at'] = Variable<int>(converter.mapToSql(updateAt)!);
    }
    map['user_id'] = Variable<String>(userId);
    map['category'] = Variable<String>(category);
    map['description'] = Variable<String>(description);
    return map;
  }

  StickerAlbumsCompanion toCompanion(bool nullToAbsent) {
    return StickerAlbumsCompanion(
      albumId: Value(albumId),
      name: Value(name),
      iconUrl: Value(iconUrl),
      createdAt: Value(createdAt),
      updateAt: Value(updateAt),
      userId: Value(userId),
      category: Value(category),
      description: Value(description),
    );
  }

  factory StickerAlbum.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return StickerAlbum(
      albumId: serializer.fromJson<String>(json['album_id']),
      name: serializer.fromJson<String>(json['name']),
      iconUrl: serializer.fromJson<String>(json['icon_url']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updateAt: serializer.fromJson<DateTime>(json['update_at']),
      userId: serializer.fromJson<String>(json['user_id']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'album_id': serializer.toJson<String>(albumId),
      'name': serializer.toJson<String>(name),
      'icon_url': serializer.toJson<String>(iconUrl),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'update_at': serializer.toJson<DateTime>(updateAt),
      'user_id': serializer.toJson<String>(userId),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String>(description),
    };
  }

  StickerAlbum copyWith(
          {String? albumId,
          String? name,
          String? iconUrl,
          DateTime? createdAt,
          DateTime? updateAt,
          String? userId,
          String? category,
          String? description}) =>
      StickerAlbum(
        albumId: albumId ?? this.albumId,
        name: name ?? this.name,
        iconUrl: iconUrl ?? this.iconUrl,
        createdAt: createdAt ?? this.createdAt,
        updateAt: updateAt ?? this.updateAt,
        userId: userId ?? this.userId,
        category: category ?? this.category,
        description: description ?? this.description,
      );
  @override
  String toString() {
    return (StringBuffer('StickerAlbum(')
          ..write('albumId: $albumId, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updateAt: $updateAt, ')
          ..write('userId: $userId, ')
          ..write('category: $category, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      albumId.hashCode,
      $mrjc(
          name.hashCode,
          $mrjc(
              iconUrl.hashCode,
              $mrjc(
                  createdAt.hashCode,
                  $mrjc(
                      updateAt.hashCode,
                      $mrjc(userId.hashCode,
                          $mrjc(category.hashCode, description.hashCode))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is StickerAlbum &&
          other.albumId == this.albumId &&
          other.name == this.name &&
          other.iconUrl == this.iconUrl &&
          other.createdAt == this.createdAt &&
          other.updateAt == this.updateAt &&
          other.userId == this.userId &&
          other.category == this.category &&
          other.description == this.description);
}

class StickerAlbumsCompanion extends UpdateCompanion<StickerAlbum> {
  final Value<String> albumId;
  final Value<String> name;
  final Value<String> iconUrl;
  final Value<DateTime> createdAt;
  final Value<DateTime> updateAt;
  final Value<String> userId;
  final Value<String> category;
  final Value<String> description;
  const StickerAlbumsCompanion({
    this.albumId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updateAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
  });
  StickerAlbumsCompanion.insert({
    required String albumId,
    required String name,
    required String iconUrl,
    required DateTime createdAt,
    required DateTime updateAt,
    required String userId,
    required String category,
    required String description,
  })   : albumId = Value(albumId),
        name = Value(name),
        iconUrl = Value(iconUrl),
        createdAt = Value(createdAt),
        updateAt = Value(updateAt),
        userId = Value(userId),
        category = Value(category),
        description = Value(description);
  static Insertable<StickerAlbum> custom({
    Expression<String>? albumId,
    Expression<String>? name,
    Expression<String>? iconUrl,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updateAt,
    Expression<String>? userId,
    Expression<String>? category,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (albumId != null) 'album_id': albumId,
      if (name != null) 'name': name,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (updateAt != null) 'update_at': updateAt,
      if (userId != null) 'user_id': userId,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
    });
  }

  StickerAlbumsCompanion copyWith(
      {Value<String>? albumId,
      Value<String>? name,
      Value<String>? iconUrl,
      Value<DateTime>? createdAt,
      Value<DateTime>? updateAt,
      Value<String>? userId,
      Value<String>? category,
      Value<String>? description}) {
    return StickerAlbumsCompanion(
      albumId: albumId ?? this.albumId,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
      updateAt: updateAt ?? this.updateAt,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (createdAt.present) {
      final converter = StickerAlbums.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    if (updateAt.present) {
      final converter = StickerAlbums.$converter1;
      map['update_at'] = Variable<int>(converter.mapToSql(updateAt.value)!);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StickerAlbumsCompanion(')
          ..write('albumId: $albumId, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updateAt: $updateAt, ')
          ..write('userId: $userId, ')
          ..write('category: $category, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class StickerAlbums extends Table with TableInfo<StickerAlbums, StickerAlbum> {
  final GeneratedDatabase _db;
  final String? _alias;
  StickerAlbums(this._db, [this._alias]);
  final VerificationMeta _albumIdMeta = const VerificationMeta('albumId');
  late final GeneratedTextColumn albumId = _constructAlbumId();
  GeneratedTextColumn _constructAlbumId() {
    return GeneratedTextColumn('album_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _iconUrlMeta = const VerificationMeta('iconUrl');
  late final GeneratedTextColumn iconUrl = _constructIconUrl();
  GeneratedTextColumn _constructIconUrl() {
    return GeneratedTextColumn('icon_url', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _updateAtMeta = const VerificationMeta('updateAt');
  late final GeneratedIntColumn updateAt = _constructUpdateAt();
  GeneratedIntColumn _constructUpdateAt() {
    return GeneratedIntColumn('update_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  late final GeneratedTextColumn category = _constructCategory();
  GeneratedTextColumn _constructCategory() {
    return GeneratedTextColumn('category', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  late final GeneratedTextColumn description = _constructDescription();
  GeneratedTextColumn _constructDescription() {
    return GeneratedTextColumn('description', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [
        albumId,
        name,
        iconUrl,
        createdAt,
        updateAt,
        userId,
        category,
        description
      ];
  @override
  StickerAlbums get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'sticker_albums';
  @override
  final String actualTableName = 'sticker_albums';
  @override
  VerificationContext validateIntegrity(Insertable<StickerAlbum> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(_iconUrlMeta,
          iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta));
    } else if (isInserting) {
      context.missing(_iconUrlMeta);
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    context.handle(_updateAtMeta, const VerificationResult.success());
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {albumId};
  @override
  StickerAlbum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return StickerAlbum.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  StickerAlbums createAlias(String alias) {
    return StickerAlbums(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  static TypeConverter<DateTime, int> $converter1 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(album_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class StickerRelationship extends DataClass
    implements Insertable<StickerRelationship> {
  final String albumId;
  final String stickerId;
  StickerRelationship({required this.albumId, required this.stickerId});
  factory StickerRelationship.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return StickerRelationship(
      albumId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}album_id'])!,
      stickerId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}sticker_id'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['album_id'] = Variable<String>(albumId);
    map['sticker_id'] = Variable<String>(stickerId);
    return map;
  }

  StickerRelationshipsCompanion toCompanion(bool nullToAbsent) {
    return StickerRelationshipsCompanion(
      albumId: Value(albumId),
      stickerId: Value(stickerId),
    );
  }

  factory StickerRelationship.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return StickerRelationship(
      albumId: serializer.fromJson<String>(json['album_id']),
      stickerId: serializer.fromJson<String>(json['sticker_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'album_id': serializer.toJson<String>(albumId),
      'sticker_id': serializer.toJson<String>(stickerId),
    };
  }

  StickerRelationship copyWith({String? albumId, String? stickerId}) =>
      StickerRelationship(
        albumId: albumId ?? this.albumId,
        stickerId: stickerId ?? this.stickerId,
      );
  @override
  String toString() {
    return (StringBuffer('StickerRelationship(')
          ..write('albumId: $albumId, ')
          ..write('stickerId: $stickerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(albumId.hashCode, stickerId.hashCode));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is StickerRelationship &&
          other.albumId == this.albumId &&
          other.stickerId == this.stickerId);
}

class StickerRelationshipsCompanion
    extends UpdateCompanion<StickerRelationship> {
  final Value<String> albumId;
  final Value<String> stickerId;
  const StickerRelationshipsCompanion({
    this.albumId = const Value.absent(),
    this.stickerId = const Value.absent(),
  });
  StickerRelationshipsCompanion.insert({
    required String albumId,
    required String stickerId,
  })   : albumId = Value(albumId),
        stickerId = Value(stickerId);
  static Insertable<StickerRelationship> custom({
    Expression<String>? albumId,
    Expression<String>? stickerId,
  }) {
    return RawValuesInsertable({
      if (albumId != null) 'album_id': albumId,
      if (stickerId != null) 'sticker_id': stickerId,
    });
  }

  StickerRelationshipsCompanion copyWith(
      {Value<String>? albumId, Value<String>? stickerId}) {
    return StickerRelationshipsCompanion(
      albumId: albumId ?? this.albumId,
      stickerId: stickerId ?? this.stickerId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StickerRelationshipsCompanion(')
          ..write('albumId: $albumId, ')
          ..write('stickerId: $stickerId')
          ..write(')'))
        .toString();
  }
}

class StickerRelationships extends Table
    with TableInfo<StickerRelationships, StickerRelationship> {
  final GeneratedDatabase _db;
  final String? _alias;
  StickerRelationships(this._db, [this._alias]);
  final VerificationMeta _albumIdMeta = const VerificationMeta('albumId');
  late final GeneratedTextColumn albumId = _constructAlbumId();
  GeneratedTextColumn _constructAlbumId() {
    return GeneratedTextColumn('album_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _stickerIdMeta = const VerificationMeta('stickerId');
  late final GeneratedTextColumn stickerId = _constructStickerId();
  GeneratedTextColumn _constructStickerId() {
    return GeneratedTextColumn('sticker_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [albumId, stickerId];
  @override
  StickerRelationships get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'sticker_relationships';
  @override
  final String actualTableName = 'sticker_relationships';
  @override
  VerificationContext validateIntegrity(
      Insertable<StickerRelationship> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('sticker_id')) {
      context.handle(_stickerIdMeta,
          stickerId.isAcceptableOrUnknown(data['sticker_id']!, _stickerIdMeta));
    } else if (isInserting) {
      context.missing(_stickerIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {albumId, stickerId};
  @override
  StickerRelationship map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return StickerRelationship.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  StickerRelationships createAlias(String alias) {
    return StickerRelationships(_db, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(album_id,sticker_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Sticker extends DataClass implements Insertable<Sticker> {
  final String stickerId;
  final String? albumId;
  final String name;
  final String assetUrl;
  final String assetType;
  final int assetWidth;
  final int assetHeight;
  final DateTime createdAt;
  final DateTime? lastUseAt;
  Sticker(
      {required this.stickerId,
      this.albumId,
      required this.name,
      required this.assetUrl,
      required this.assetType,
      required this.assetWidth,
      required this.assetHeight,
      required this.createdAt,
      this.lastUseAt});
  factory Sticker.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Sticker(
      stickerId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}sticker_id'])!,
      albumId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}album_id']),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      assetUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_url'])!,
      assetType: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_type'])!,
      assetWidth: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_width'])!,
      assetHeight: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_height'])!,
      createdAt: Stickers.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']))!,
      lastUseAt: Stickers.$converter1.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}last_use_at'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sticker_id'] = Variable<String>(stickerId);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String?>(albumId);
    }
    map['name'] = Variable<String>(name);
    map['asset_url'] = Variable<String>(assetUrl);
    map['asset_type'] = Variable<String>(assetType);
    map['asset_width'] = Variable<int>(assetWidth);
    map['asset_height'] = Variable<int>(assetHeight);
    {
      final converter = Stickers.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt)!);
    }
    if (!nullToAbsent || lastUseAt != null) {
      final converter = Stickers.$converter1;
      map['last_use_at'] = Variable<int?>(converter.mapToSql(lastUseAt));
    }
    return map;
  }

  StickersCompanion toCompanion(bool nullToAbsent) {
    return StickersCompanion(
      stickerId: Value(stickerId),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      name: Value(name),
      assetUrl: Value(assetUrl),
      assetType: Value(assetType),
      assetWidth: Value(assetWidth),
      assetHeight: Value(assetHeight),
      createdAt: Value(createdAt),
      lastUseAt: lastUseAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUseAt),
    );
  }

  factory Sticker.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Sticker(
      stickerId: serializer.fromJson<String>(json['sticker_id']),
      albumId: serializer.fromJson<String?>(json['album_id']),
      name: serializer.fromJson<String>(json['name']),
      assetUrl: serializer.fromJson<String>(json['asset_url']),
      assetType: serializer.fromJson<String>(json['asset_type']),
      assetWidth: serializer.fromJson<int>(json['asset_width']),
      assetHeight: serializer.fromJson<int>(json['asset_height']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      lastUseAt: serializer.fromJson<DateTime?>(json['last_use_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sticker_id': serializer.toJson<String>(stickerId),
      'album_id': serializer.toJson<String?>(albumId),
      'name': serializer.toJson<String>(name),
      'asset_url': serializer.toJson<String>(assetUrl),
      'asset_type': serializer.toJson<String>(assetType),
      'asset_width': serializer.toJson<int>(assetWidth),
      'asset_height': serializer.toJson<int>(assetHeight),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'last_use_at': serializer.toJson<DateTime?>(lastUseAt),
    };
  }

  Sticker copyWith(
          {String? stickerId,
          String? albumId,
          String? name,
          String? assetUrl,
          String? assetType,
          int? assetWidth,
          int? assetHeight,
          DateTime? createdAt,
          DateTime? lastUseAt}) =>
      Sticker(
        stickerId: stickerId ?? this.stickerId,
        albumId: albumId ?? this.albumId,
        name: name ?? this.name,
        assetUrl: assetUrl ?? this.assetUrl,
        assetType: assetType ?? this.assetType,
        assetWidth: assetWidth ?? this.assetWidth,
        assetHeight: assetHeight ?? this.assetHeight,
        createdAt: createdAt ?? this.createdAt,
        lastUseAt: lastUseAt ?? this.lastUseAt,
      );
  @override
  String toString() {
    return (StringBuffer('Sticker(')
          ..write('stickerId: $stickerId, ')
          ..write('albumId: $albumId, ')
          ..write('name: $name, ')
          ..write('assetUrl: $assetUrl, ')
          ..write('assetType: $assetType, ')
          ..write('assetWidth: $assetWidth, ')
          ..write('assetHeight: $assetHeight, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUseAt: $lastUseAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      stickerId.hashCode,
      $mrjc(
          albumId.hashCode,
          $mrjc(
              name.hashCode,
              $mrjc(
                  assetUrl.hashCode,
                  $mrjc(
                      assetType.hashCode,
                      $mrjc(
                          assetWidth.hashCode,
                          $mrjc(
                              assetHeight.hashCode,
                              $mrjc(createdAt.hashCode,
                                  lastUseAt.hashCode)))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Sticker &&
          other.stickerId == this.stickerId &&
          other.albumId == this.albumId &&
          other.name == this.name &&
          other.assetUrl == this.assetUrl &&
          other.assetType == this.assetType &&
          other.assetWidth == this.assetWidth &&
          other.assetHeight == this.assetHeight &&
          other.createdAt == this.createdAt &&
          other.lastUseAt == this.lastUseAt);
}

class StickersCompanion extends UpdateCompanion<Sticker> {
  final Value<String> stickerId;
  final Value<String?> albumId;
  final Value<String> name;
  final Value<String> assetUrl;
  final Value<String> assetType;
  final Value<int> assetWidth;
  final Value<int> assetHeight;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastUseAt;
  const StickersCompanion({
    this.stickerId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.name = const Value.absent(),
    this.assetUrl = const Value.absent(),
    this.assetType = const Value.absent(),
    this.assetWidth = const Value.absent(),
    this.assetHeight = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUseAt = const Value.absent(),
  });
  StickersCompanion.insert({
    required String stickerId,
    this.albumId = const Value.absent(),
    required String name,
    required String assetUrl,
    required String assetType,
    required int assetWidth,
    required int assetHeight,
    required DateTime createdAt,
    this.lastUseAt = const Value.absent(),
  })  : stickerId = Value(stickerId),
        name = Value(name),
        assetUrl = Value(assetUrl),
        assetType = Value(assetType),
        assetWidth = Value(assetWidth),
        assetHeight = Value(assetHeight),
        createdAt = Value(createdAt);
  static Insertable<Sticker> custom({
    Expression<String>? stickerId,
    Expression<String?>? albumId,
    Expression<String>? name,
    Expression<String>? assetUrl,
    Expression<String>? assetType,
    Expression<int>? assetWidth,
    Expression<int>? assetHeight,
    Expression<DateTime>? createdAt,
    Expression<DateTime?>? lastUseAt,
  }) {
    return RawValuesInsertable({
      if (stickerId != null) 'sticker_id': stickerId,
      if (albumId != null) 'album_id': albumId,
      if (name != null) 'name': name,
      if (assetUrl != null) 'asset_url': assetUrl,
      if (assetType != null) 'asset_type': assetType,
      if (assetWidth != null) 'asset_width': assetWidth,
      if (assetHeight != null) 'asset_height': assetHeight,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUseAt != null) 'last_use_at': lastUseAt,
    });
  }

  StickersCompanion copyWith(
      {Value<String>? stickerId,
      Value<String?>? albumId,
      Value<String>? name,
      Value<String>? assetUrl,
      Value<String>? assetType,
      Value<int>? assetWidth,
      Value<int>? assetHeight,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastUseAt}) {
    return StickersCompanion(
      stickerId: stickerId ?? this.stickerId,
      albumId: albumId ?? this.albumId,
      name: name ?? this.name,
      assetUrl: assetUrl ?? this.assetUrl,
      assetType: assetType ?? this.assetType,
      assetWidth: assetWidth ?? this.assetWidth,
      assetHeight: assetHeight ?? this.assetHeight,
      createdAt: createdAt ?? this.createdAt,
      lastUseAt: lastUseAt ?? this.lastUseAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String?>(albumId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (assetUrl.present) {
      map['asset_url'] = Variable<String>(assetUrl.value);
    }
    if (assetType.present) {
      map['asset_type'] = Variable<String>(assetType.value);
    }
    if (assetWidth.present) {
      map['asset_width'] = Variable<int>(assetWidth.value);
    }
    if (assetHeight.present) {
      map['asset_height'] = Variable<int>(assetHeight.value);
    }
    if (createdAt.present) {
      final converter = Stickers.$converter0;
      map['created_at'] = Variable<int>(converter.mapToSql(createdAt.value)!);
    }
    if (lastUseAt.present) {
      final converter = Stickers.$converter1;
      map['last_use_at'] = Variable<int?>(converter.mapToSql(lastUseAt.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StickersCompanion(')
          ..write('stickerId: $stickerId, ')
          ..write('albumId: $albumId, ')
          ..write('name: $name, ')
          ..write('assetUrl: $assetUrl, ')
          ..write('assetType: $assetType, ')
          ..write('assetWidth: $assetWidth, ')
          ..write('assetHeight: $assetHeight, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUseAt: $lastUseAt')
          ..write(')'))
        .toString();
  }
}

class Stickers extends Table with TableInfo<Stickers, Sticker> {
  final GeneratedDatabase _db;
  final String? _alias;
  Stickers(this._db, [this._alias]);
  final VerificationMeta _stickerIdMeta = const VerificationMeta('stickerId');
  late final GeneratedTextColumn stickerId = _constructStickerId();
  GeneratedTextColumn _constructStickerId() {
    return GeneratedTextColumn('sticker_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _albumIdMeta = const VerificationMeta('albumId');
  late final GeneratedTextColumn albumId = _constructAlbumId();
  GeneratedTextColumn _constructAlbumId() {
    return GeneratedTextColumn('album_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _assetUrlMeta = const VerificationMeta('assetUrl');
  late final GeneratedTextColumn assetUrl = _constructAssetUrl();
  GeneratedTextColumn _constructAssetUrl() {
    return GeneratedTextColumn('asset_url', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _assetTypeMeta = const VerificationMeta('assetType');
  late final GeneratedTextColumn assetType = _constructAssetType();
  GeneratedTextColumn _constructAssetType() {
    return GeneratedTextColumn('asset_type', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _assetWidthMeta = const VerificationMeta('assetWidth');
  late final GeneratedIntColumn assetWidth = _constructAssetWidth();
  GeneratedIntColumn _constructAssetWidth() {
    return GeneratedIntColumn('asset_width', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _assetHeightMeta =
      const VerificationMeta('assetHeight');
  late final GeneratedIntColumn assetHeight = _constructAssetHeight();
  GeneratedIntColumn _constructAssetHeight() {
    return GeneratedIntColumn('asset_height', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedIntColumn createdAt = _constructCreatedAt();
  GeneratedIntColumn _constructCreatedAt() {
    return GeneratedIntColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _lastUseAtMeta = const VerificationMeta('lastUseAt');
  late final GeneratedIntColumn lastUseAt = _constructLastUseAt();
  GeneratedIntColumn _constructLastUseAt() {
    return GeneratedIntColumn('last_use_at', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [
        stickerId,
        albumId,
        name,
        assetUrl,
        assetType,
        assetWidth,
        assetHeight,
        createdAt,
        lastUseAt
      ];
  @override
  Stickers get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'stickers';
  @override
  final String actualTableName = 'stickers';
  @override
  VerificationContext validateIntegrity(Insertable<Sticker> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sticker_id')) {
      context.handle(_stickerIdMeta,
          stickerId.isAcceptableOrUnknown(data['sticker_id']!, _stickerIdMeta));
    } else if (isInserting) {
      context.missing(_stickerIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('asset_url')) {
      context.handle(_assetUrlMeta,
          assetUrl.isAcceptableOrUnknown(data['asset_url']!, _assetUrlMeta));
    } else if (isInserting) {
      context.missing(_assetUrlMeta);
    }
    if (data.containsKey('asset_type')) {
      context.handle(_assetTypeMeta,
          assetType.isAcceptableOrUnknown(data['asset_type']!, _assetTypeMeta));
    } else if (isInserting) {
      context.missing(_assetTypeMeta);
    }
    if (data.containsKey('asset_width')) {
      context.handle(
          _assetWidthMeta,
          assetWidth.isAcceptableOrUnknown(
              data['asset_width']!, _assetWidthMeta));
    } else if (isInserting) {
      context.missing(_assetWidthMeta);
    }
    if (data.containsKey('asset_height')) {
      context.handle(
          _assetHeightMeta,
          assetHeight.isAcceptableOrUnknown(
              data['asset_height']!, _assetHeightMeta));
    } else if (isInserting) {
      context.missing(_assetHeightMeta);
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    context.handle(_lastUseAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stickerId};
  @override
  Sticker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Sticker.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Stickers createAlias(String alias) {
    return Stickers(_db, alias);
  }

  static TypeConverter<DateTime, int> $converter0 = const MillisDateConverter();
  static TypeConverter<DateTime, int> $converter1 = const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(sticker_id)'];
  @override
  bool get dontWriteConstraints => true;
}

abstract class _$MixinDatabase extends GeneratedDatabase {
  _$MixinDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$MixinDatabase.connect(DatabaseConnection c) : super.connect(c);
  late final Jobs jobs = Jobs(this);
  late final Index indexJobsAction = Index('index_jobs_action',
      'CREATE INDEX IF NOT EXISTS index_jobs_action ON jobs ("action");');
  late final Conversations conversations = Conversations(this);
  late final Index indexConversationsCategoryStatusPinTimeCreatedAt = Index(
      'index_conversations_category_status_pin_time_created_at',
      'CREATE INDEX IF NOT EXISTS index_conversations_category_status_pin_time_created_at ON conversations (category, status, pin_time, created_at);');
  late final MessageMentions messageMentions = MessageMentions(this);
  late final Index indexMessageMentionsConversationId = Index(
      'index_message_mentions_conversation_id',
      'CREATE INDEX IF NOT EXISTS index_message_mentions_conversation_id ON message_mentions (conversation_id);');
  late final Messages messages = Messages(this);
  late final Index indexMessagesConversationId = Index(
      'index_messages_conversation_id',
      'CREATE INDEX IF NOT EXISTS index_messages_conversation_id ON messages (conversation_id);');
  late final Index indexMessagesConversationIdCreatedAt = Index(
      'index_messages_conversation_id_created_at',
      'CREATE INDEX IF NOT EXISTS index_messages_conversation_id_created_at ON messages (conversation_id, created_at);');
  late final Index indexMessagesConversationIdStatusUserId = Index(
      'index_messages_conversation_id_status_user_id',
      'CREATE INDEX IF NOT EXISTS index_messages_conversation_id_status_user_id ON messages (conversation_id, status, user_id);');
  late final Index indexMessagesConversationIdUserIdStatusCreatedAt = Index(
      'index_messages_conversation_id_user_id_status_created_at',
      'CREATE INDEX IF NOT EXISTS index_messages_conversation_id_user_id_status_created_at ON messages (conversation_id, user_id, status, created_at);');
  late final Participants participants = Participants(this);
  late final Index indexParticipantsConversationId = Index(
      'index_participants_conversation_id',
      'CREATE INDEX IF NOT EXISTS index_participants_conversation_id ON participants (conversation_id);');
  late final Index indexParticipantsCreatedAt = Index(
      'index_participants_created_at',
      'CREATE INDEX IF NOT EXISTS index_participants_created_at ON participants (created_at);');
  late final Snapshots snapshots = Snapshots(this);
  late final Index indexSnapshotsAssetId = Index('index_snapshots_asset_id',
      'CREATE INDEX IF NOT EXISTS index_snapshots_asset_id ON snapshots (asset_id);');
  late final Users users = Users(this);
  late final Index indexUsersFullName = Index('index_users_full_name',
      'CREATE INDEX IF NOT EXISTS index_users_full_name ON users (full_name);');
  late final Trigger conversationLastMessageUpdate = Trigger(
      'CREATE TRIGGER IF NOT EXISTS conversation_last_message_update AFTER INSERT ON messages BEGIN UPDATE conversations SET last_message_id = new.message_id, last_message_created_at = new.created_at  WHERE conversation_id = new.conversation_id; END;',
      'conversation_last_message_update');
  late final Trigger conversationLastMessageDelete = Trigger(
      'CREATE TRIGGER IF NOT EXISTS conversation_last_message_delete AFTER DELETE ON messages BEGIN UPDATE conversations SET last_message_id = (select message_id from messages where conversation_id = old.conversation_id order by created_at DESC limit 1) WHERE conversation_id = old.conversation_id; END;',
      'conversation_last_message_delete');
  late final Addresses addresses = Addresses(this);
  late final Apps apps = Apps(this);
  late final Assets assets = Assets(this);
  late final CircleConversations circleConversations =
      CircleConversations(this);
  late final Circles circles = Circles(this);
  late final FloodMessages floodMessages = FloodMessages(this);
  late final Hyperlinks hyperlinks = Hyperlinks(this);
  late final MessagesFts messagesFts = MessagesFts(this);
  late final MessagesHistory messagesHistory = MessagesHistory(this);
  late final Offsets offsets = Offsets(this);
  late final ParticipantSession participantSession = ParticipantSession(this);
  late final RatchetSenderKeys ratchetSenderKeys = RatchetSenderKeys(this);
  late final ResendSessionMessages resendSessionMessages =
      ResendSessionMessages(this);
  late final SentSessionSenderKeys sentSessionSenderKeys =
      SentSessionSenderKeys(this);
  late final StickerAlbums stickerAlbums = StickerAlbums(this);
  late final StickerRelationships stickerRelationships =
      StickerRelationships(this);
  late final Stickers stickers = Stickers(this);
  late final AddressesDao addressesDao = AddressesDao(this as MixinDatabase);
  late final AppsDao appsDao = AppsDao(this as MixinDatabase);
  late final AssetsDao assetsDao = AssetsDao(this as MixinDatabase);
  late final CircleConversationDao circleConversationDao =
      CircleConversationDao(this as MixinDatabase);
  late final CirclesDao circlesDao = CirclesDao(this as MixinDatabase);
  late final ConversationsDao conversationsDao =
      ConversationsDao(this as MixinDatabase);
  late final FloodMessagesDao floodMessagesDao =
      FloodMessagesDao(this as MixinDatabase);
  late final HyperlinksDao hyperlinksDao = HyperlinksDao(this as MixinDatabase);
  late final JobsDao jobsDao = JobsDao(this as MixinDatabase);
  late final MessageMentionsDao messageMentionsDao =
      MessageMentionsDao(this as MixinDatabase);
  late final MessagesDao messagesDao = MessagesDao(this as MixinDatabase);
  late final MessagesHistoryDao messagesHistoryDao =
      MessagesHistoryDao(this as MixinDatabase);
  late final OffsetsDao offsetsDao = OffsetsDao(this as MixinDatabase);
  late final ParticipantsDao participantsDao =
      ParticipantsDao(this as MixinDatabase);
  late final ParticipantSessionDao participantSessionDao =
      ParticipantSessionDao(this as MixinDatabase);
  late final ResendSessionMessagesDao resendSessionMessagesDao =
      ResendSessionMessagesDao(this as MixinDatabase);
  late final SentSessionSenderKeysDao sentSessionSenderKeysDao =
      SentSessionSenderKeysDao(this as MixinDatabase);
  late final SnapshotsDao snapshotsDao = SnapshotsDao(this as MixinDatabase);
  late final StickerDao stickerDao = StickerDao(this as MixinDatabase);
  late final StickerAlbumsDao stickerAlbumsDao =
      StickerAlbumsDao(this as MixinDatabase);
  late final StickerRelationshipsDao stickerRelationshipsDao =
      StickerRelationshipsDao(this as MixinDatabase);
  late final UserDao userDao = UserDao(this as MixinDatabase);
  Selectable<User> fuzzySearchGroupUser(String id, String conversationId,
      String username, String identityNumber) {
    return customSelect(
        'SELECT u.* FROM participants p, users u\n        WHERE u.user_id != :id\n        AND p.conversation_id = :conversationId AND p.user_id = u.user_id\n        AND (u.full_name LIKE \'%\' || :username || \'%\'  ESCAPE \'\\\' OR u.identity_number like \'%\' || :identityNumber || \'%\'  ESCAPE \'\\\')\n        ORDER BY u.full_name = :username COLLATE NOCASE OR u.identity_number = :identityNumber COLLATE NOCASE DESC',
        variables: [
          Variable<String>(id),
          Variable<String>(conversationId),
          Variable<String>(username),
          Variable<String>(identityNumber)
        ],
        readsFrom: {
          participants,
          users
        }).map(users.mapFromRow);
  }

  Selectable<User> groupParticipants(String conversationId, String id) {
    return customSelect(
        'SELECT u.* FROM participants p, users u WHERE p.conversation_id = :conversationId AND p.user_id = u.user_id AND u.user_id != :id',
        variables: [Variable<String>(conversationId), Variable<String>(id)],
        readsFrom: {participants, users}).map(users.mapFromRow);
  }

  Selectable<StickerAlbum> systemAlbums() {
    return customSelect(
        'SELECT * FROM sticker_albums WHERE category = \'SYSTEM\' ORDER BY created_at DESC',
        variables: [],
        readsFrom: {stickerAlbums}).map(stickerAlbums.mapFromRow);
  }

  Selectable<StickerAlbum> personalAlbums() {
    return customSelect(
        'SELECT * FROM sticker_albums WHERE category = \'PERSONAL\' ORDER BY created_at ASC LIMIT 1',
        variables: [],
        readsFrom: {stickerAlbums}).map(stickerAlbums.mapFromRow);
  }

  Selectable<Sticker> recentUsedStickers() {
    return customSelect(
        'SELECT * FROM stickers WHERE last_use_at > 0 ORDER BY last_use_at DESC LIMIT 20',
        variables: [],
        readsFrom: {stickers}).map(stickers.mapFromRow);
  }

  Selectable<Sticker> personalStickers() {
    return customSelect(
        'SELECT s.*\nFROM   sticker_albums sa\n       INNER JOIN sticker_relationships sr\n               ON sr.album_id = sa.album_id\n       INNER JOIN stickers s\n               ON sr.sticker_id = s.sticker_id\nWHERE  sa.category = \'PERSONAL\'\nORDER  BY s.created_at',
        variables: [],
        readsFrom: {
          stickerAlbums,
          stickerRelationships,
          stickers
        }).map(stickers.mapFromRow);
  }

  Selectable<User> participantsAvatar(String conversationId) {
    return customSelect(
        'SELECT u.*\nFROM participants p,\n     users u\nWHERE p.conversation_id = :conversationId\n  AND p.user_id = u.user_id\nORDER BY p.created_at\nLIMIT 4',
        variables: [Variable<String>(conversationId)],
        readsFrom: {participants, users}).map(users.mapFromRow);
  }

  Selectable<MessageItem> messagesByConversationId(
      String conversationId, int offset, int limit) {
    return customSelect(
        'SELECT m.message_id AS messageId, m.conversation_id AS conversationId, u.user_id AS userId,\n        u.full_name AS userFullName, u.identity_number AS userIdentityNumber, u.app_id AS appId, m.category AS type,\n        m.content AS content, m.created_at AS createdAt, m.status AS status, m.media_status AS mediaStatus, m.media_waveform AS mediaWaveform,\n        m.name AS mediaName, m.media_mime_type AS mediaMimeType, m.media_size AS mediaSize, m.media_width AS mediaWidth, m.media_height AS mediaHeight,\n        m.thumb_image AS thumbImage, m.thumb_url AS thumbUrl, m.media_url AS mediaUrl, m.media_duration AS mediaDuration, m.quote_message_id as quoteId,\n        m.quote_content as quoteContent, u1.full_name AS participantFullName, m.action AS actionName, u1.user_id AS participantUserId,\n        s.snapshot_id AS snapshotId, s.type AS snapshotType, s.amount AS snapshotAmount, a.symbol AS assetSymbol, s.asset_id AS assetId,\n        a.icon_url AS assetIcon, st.asset_url AS assetUrl, st.asset_width AS assetWidth, st.asset_height AS assetHeight, st.sticker_id AS stickerId,\n        st.name AS assetName, st.asset_type AS assetType, h.site_name AS siteName, h.site_title AS siteTitle, h.site_description AS siteDescription,\n        h.site_image AS siteImage, m.shared_user_id AS sharedUserId, su.full_name AS sharedUserFullName, su.identity_number AS sharedUserIdentityNumber,\n        su.avatar_url AS sharedUserAvatarUrl, su.is_verified AS sharedUserIsVerified, su.app_id AS sharedUserAppId, mm.mentions AS mentions, mm.has_read as mentionRead,\n        c.name AS groupName, u.relationship AS relationship, u1.relationship AS participantRelationship\n        FROM messages m\n        INNER JOIN users u ON m.user_id = u.user_id\n        LEFT JOIN users u1 ON m.participant_id = u1.user_id\n        LEFT JOIN snapshots s ON m.snapshot_id = s.snapshot_id\n        LEFT JOIN assets a ON s.asset_id = a.asset_id\n        LEFT JOIN stickers st ON st.sticker_id = m.sticker_id\n        LEFT JOIN hyperlinks h ON m.hyperlink = h.hyperlink\n        LEFT JOIN users su ON m.shared_user_id = su.user_id\n        LEFT JOIN conversations c ON m.conversation_id = c.conversation_id\n        LEFT JOIN message_mentions mm ON m.message_id = mm.message_id\n        WHERE m.conversation_id = :conversationId\n        ORDER BY m.created_at DESC\n        LIMIT :offset, :limit',
        variables: [
          Variable<String>(conversationId),
          Variable<int>(offset),
          Variable<int>(limit)
        ],
        readsFrom: {
          messages,
          users,
          snapshots,
          assets,
          stickers,
          hyperlinks,
          messageMentions,
          conversations
        }).map((QueryRow row) {
      return MessageItem(
        messageId: row.readString('messageId'),
        conversationId: row.readString('conversationId'),
        userId: row.readString('userId'),
        userFullName: row.readString('userFullName'),
        userIdentityNumber: row.readString('userIdentityNumber'),
        appId: row.readString('appId'),
        type: Messages.$converter0.mapToDart(row.readString('type'))!,
        content: row.readString('content'),
        createdAt: Messages.$converter3.mapToDart(row.readInt('createdAt'))!,
        status: Messages.$converter2.mapToDart(row.readString('status'))!,
        mediaStatus:
            Messages.$converter1.mapToDart(row.readString('mediaStatus')),
        mediaWaveform: row.readString('mediaWaveform'),
        mediaName: row.readString('mediaName'),
        mediaMimeType: row.readString('mediaMimeType'),
        mediaSize: row.readInt('mediaSize'),
        mediaWidth: row.readInt('mediaWidth'),
        mediaHeight: row.readInt('mediaHeight'),
        thumbImage: row.readString('thumbImage'),
        thumbUrl: row.readString('thumbUrl'),
        mediaUrl: row.readString('mediaUrl'),
        mediaDuration: row.readString('mediaDuration'),
        quoteId: row.readString('quoteId'),
        quoteContent: row.readString('quoteContent'),
        participantFullName: row.readString('participantFullName'),
        actionName:
            Messages.$converter4.mapToDart(row.readString('actionName')),
        participantUserId: row.readString('participantUserId'),
        snapshotId: row.readString('snapshotId'),
        snapshotType: row.readString('snapshotType'),
        snapshotAmount: row.readString('snapshotAmount'),
        assetSymbol: row.readString('assetSymbol'),
        assetId: row.readString('assetId'),
        assetIcon: row.readString('assetIcon'),
        assetUrl: row.readString('assetUrl'),
        assetWidth: row.readInt('assetWidth'),
        assetHeight: row.readInt('assetHeight'),
        stickerId: row.readString('stickerId'),
        assetName: row.readString('assetName'),
        assetType: row.readString('assetType'),
        siteName: row.readString('siteName'),
        siteTitle: row.readString('siteTitle'),
        siteDescription: row.readString('siteDescription'),
        siteImage: row.readString('siteImage'),
        sharedUserId: row.readString('sharedUserId'),
        sharedUserFullName: row.readString('sharedUserFullName'),
        sharedUserIdentityNumber: row.readString('sharedUserIdentityNumber'),
        sharedUserAvatarUrl: row.readString('sharedUserAvatarUrl'),
        sharedUserIsVerified: row.readInt('sharedUserIsVerified'),
        sharedUserAppId: row.readString('sharedUserAppId'),
        mentions: row.readString('mentions'),
        mentionRead: row.readInt('mentionRead'),
        groupName: row.readString('groupName'),
        relationship:
            Users.$converter0.mapToDart(row.readString('relationship'))!,
        participantRelationship: Users.$converter0
            .mapToDart(row.readString('participantRelationship'))!,
      );
    });
  }

  Selectable<MessageItem> messagesByMessageIds(List<String> messageIds) {
    var $arrayStartIndex = 1;
    final expandedmessageIds = $expandVar($arrayStartIndex, messageIds.length);
    $arrayStartIndex += messageIds.length;
    return customSelect(
        'SELECT m.message_id AS messageId, m.conversation_id AS conversationId, u.user_id AS userId,\n        u.full_name AS userFullName, u.identity_number AS userIdentityNumber, u.app_id AS appId, m.category AS type,\n        m.content AS content, m.created_at AS createdAt, m.status AS status, m.media_status AS mediaStatus, m.media_waveform AS mediaWaveform,\n        m.name AS mediaName, m.media_mime_type AS mediaMimeType, m.media_size AS mediaSize, m.media_width AS mediaWidth, m.media_height AS mediaHeight,\n        m.thumb_image AS thumbImage, m.thumb_url AS thumbUrl, m.media_url AS mediaUrl, m.media_duration AS mediaDuration, m.quote_message_id as quoteId,\n        m.quote_content as quoteContent, u1.full_name AS participantFullName, m.action AS actionName, u1.user_id AS participantUserId,\n        s.snapshot_id AS snapshotId, s.type AS snapshotType, s.amount AS snapshotAmount, a.symbol AS assetSymbol, s.asset_id AS assetId,\n        a.icon_url AS assetIcon, st.asset_url AS assetUrl, st.asset_width AS assetWidth, st.asset_height AS assetHeight, st.sticker_id AS stickerId,\n        st.name AS assetName, st.asset_type AS assetType, h.site_name AS siteName, h.site_title AS siteTitle, h.site_description AS siteDescription,\n        h.site_image AS siteImage, m.shared_user_id AS sharedUserId, su.full_name AS sharedUserFullName, su.identity_number AS sharedUserIdentityNumber,\n        su.avatar_url AS sharedUserAvatarUrl, su.is_verified AS sharedUserIsVerified, su.app_id AS sharedUserAppId, mm.mentions AS mentions, mm.has_read as mentionRead,\n        c.name AS groupName, u.relationship AS relationship, u1.relationship AS participantRelationship\n        FROM messages m\n        INNER JOIN users u ON m.user_id = u.user_id\n        LEFT JOIN users u1 ON m.participant_id = u1.user_id\n        LEFT JOIN snapshots s ON m.snapshot_id = s.snapshot_id\n        LEFT JOIN assets a ON s.asset_id = a.asset_id\n        LEFT JOIN stickers st ON st.sticker_id = m.sticker_id\n        LEFT JOIN hyperlinks h ON m.hyperlink = h.hyperlink\n        LEFT JOIN users su ON m.shared_user_id = su.user_id\n        LEFT JOIN conversations c ON m.conversation_id = c.conversation_id\n        LEFT JOIN message_mentions mm ON m.message_id = mm.message_id\n        WHERE m.message_id in ($expandedmessageIds)\n        ORDER BY m.created_at DESC',
        variables: [
          for (var $ in messageIds) Variable<String>($)
        ],
        readsFrom: {
          messages,
          users,
          snapshots,
          assets,
          stickers,
          hyperlinks,
          messageMentions,
          conversations
        }).map((QueryRow row) {
      return MessageItem(
        messageId: row.readString('messageId'),
        conversationId: row.readString('conversationId'),
        userId: row.readString('userId'),
        userFullName: row.readString('userFullName'),
        userIdentityNumber: row.readString('userIdentityNumber'),
        appId: row.readString('appId'),
        type: Messages.$converter0.mapToDart(row.readString('type'))!,
        content: row.readString('content'),
        createdAt: Messages.$converter3.mapToDart(row.readInt('createdAt'))!,
        status: Messages.$converter2.mapToDart(row.readString('status'))!,
        mediaStatus:
            Messages.$converter1.mapToDart(row.readString('mediaStatus')),
        mediaWaveform: row.readString('mediaWaveform'),
        mediaName: row.readString('mediaName'),
        mediaMimeType: row.readString('mediaMimeType'),
        mediaSize: row.readInt('mediaSize'),
        mediaWidth: row.readInt('mediaWidth'),
        mediaHeight: row.readInt('mediaHeight'),
        thumbImage: row.readString('thumbImage'),
        thumbUrl: row.readString('thumbUrl'),
        mediaUrl: row.readString('mediaUrl'),
        mediaDuration: row.readString('mediaDuration'),
        quoteId: row.readString('quoteId'),
        quoteContent: row.readString('quoteContent'),
        participantFullName: row.readString('participantFullName'),
        actionName:
            Messages.$converter4.mapToDart(row.readString('actionName')),
        participantUserId: row.readString('participantUserId'),
        snapshotId: row.readString('snapshotId'),
        snapshotType: row.readString('snapshotType'),
        snapshotAmount: row.readString('snapshotAmount'),
        assetSymbol: row.readString('assetSymbol'),
        assetId: row.readString('assetId'),
        assetIcon: row.readString('assetIcon'),
        assetUrl: row.readString('assetUrl'),
        assetWidth: row.readInt('assetWidth'),
        assetHeight: row.readInt('assetHeight'),
        stickerId: row.readString('stickerId'),
        assetName: row.readString('assetName'),
        assetType: row.readString('assetType'),
        siteName: row.readString('siteName'),
        siteTitle: row.readString('siteTitle'),
        siteDescription: row.readString('siteDescription'),
        siteImage: row.readString('siteImage'),
        sharedUserId: row.readString('sharedUserId'),
        sharedUserFullName: row.readString('sharedUserFullName'),
        sharedUserIdentityNumber: row.readString('sharedUserIdentityNumber'),
        sharedUserAvatarUrl: row.readString('sharedUserAvatarUrl'),
        sharedUserIsVerified: row.readInt('sharedUserIsVerified'),
        sharedUserAppId: row.readString('sharedUserAppId'),
        mentions: row.readString('mentions'),
        mentionRead: row.readInt('mentionRead'),
        groupName: row.readString('groupName'),
        relationship:
            Users.$converter0.mapToDart(row.readString('relationship'))!,
        participantRelationship: Users.$converter0
            .mapToDart(row.readString('participantRelationship'))!,
      );
    });
  }

  Selectable<int> messageRowIdByConversationId(String conversationId) {
    return customSelect(
        'SELECT rowid FROM messages WHERE conversation_id = :conversationId ORDER BY created_at DESC',
        variables: [Variable<String>(conversationId)],
        readsFrom: {messages}).map((QueryRow row) => row.readInt('rowid'));
  }

  Selectable<SendingMessage> sendingMessage(String message_id) {
    return customSelect(
        'SELECT m.message_id, m.conversation_id, m.user_id, m.category, m.content, m.media_url, m.media_mime_type,\n      m.media_size, m.media_duration, m.media_width, m.media_height, m.media_hash, m.thumb_image, m.media_key,\n      m.media_digest, m.media_status, m.status, m.created_at, m.action, m.participant_id, m.snapshot_id, m.hyperlink,\n      m.name, m.album_id, m.sticker_id, m.shared_user_id, m.media_waveform, m.quote_message_id, m.quote_content,\n      rm.status as resend_status, rm.user_id as resend_user_id, rm.session_id as resend_session_id\n      FROM messages m LEFT JOIN resend_session_messages rm on m.message_id = rm.message_id\n      WHERE m.message_id = :message_id AND (m.status = \'SENDING\' OR rm.status = 1) AND m.content IS NOT NULL',
        variables: [Variable<String>(message_id)],
        readsFrom: {messages, resendSessionMessages}).map((QueryRow row) {
      return SendingMessage(
        messageId: row.readString('message_id'),
        conversationId: row.readString('conversation_id'),
        userId: row.readString('user_id'),
        category: Messages.$converter0.mapToDart(row.readString('category'))!,
        content: row.readString('content'),
        mediaUrl: row.readString('media_url'),
        mediaMimeType: row.readString('media_mime_type'),
        mediaSize: row.readInt('media_size'),
        mediaDuration: row.readString('media_duration'),
        mediaWidth: row.readInt('media_width'),
        mediaHeight: row.readInt('media_height'),
        mediaHash: row.readString('media_hash'),
        thumbImage: row.readString('thumb_image'),
        mediaKey: row.readString('media_key'),
        mediaDigest: row.readString('media_digest'),
        mediaStatus:
            Messages.$converter1.mapToDart(row.readString('media_status')),
        status: Messages.$converter2.mapToDart(row.readString('status'))!,
        createdAt: Messages.$converter3.mapToDart(row.readInt('created_at'))!,
        action: Messages.$converter4.mapToDart(row.readString('action')),
        participantId: row.readString('participant_id'),
        snapshotId: row.readString('snapshot_id'),
        hyperlink: row.readString('hyperlink'),
        name: row.readString('name'),
        albumId: row.readString('album_id'),
        stickerId: row.readString('sticker_id'),
        sharedUserId: row.readString('shared_user_id'),
        mediaWaveform: row.readString('media_waveform'),
        quoteMessageId: row.readString('quote_message_id'),
        quoteContent: row.readString('quote_content'),
        resendStatus: row.readInt('resend_status'),
        resendUserId: row.readString('resend_user_id'),
        resendSessionId: row.readString('resend_session_id'),
      );
    });
  }

  Selectable<QuoteMessageItem> findMessageItemById(
      String conversationId, String messageId) {
    return customSelect(
        'SELECT m.message_id AS messageId, m.conversation_id AS conversationId, u.user_id AS userId,\n      u.full_name AS userFullName, u.identity_number AS userIdentityNumber, u.app_id AS appId, m.category AS type,\n      m.content AS content, m.created_at AS createdAt, m.status AS status, m.media_status AS mediaStatus, m.media_waveform AS mediaWaveform,\n      m.name AS mediaName, m.media_mime_type AS mediaMimeType, m.media_size AS mediaSize, m.media_width AS mediaWidth, m.media_height AS mediaHeight,\n      m.thumb_image AS thumbImage, m.thumb_url AS thumbUrl, m.media_url AS mediaUrl, m.media_duration AS mediaDuration,\n      m.quote_message_id as quoteId, m.quote_content as quoteContent,\n      st.asset_url AS assetUrl, st.asset_width AS assetWidth, st.asset_height AS assetHeight, st.sticker_id AS stickerId,\n      st.name AS assetName, st.asset_type AS assetType, m.shared_user_id AS sharedUserId, su.full_name AS sharedUserFullName, su.identity_number AS sharedUserIdentityNumber,\n      su.avatar_url AS sharedUserAvatarUrl, su.is_verified AS sharedUserIsVerified, su.app_id AS sharedUserAppId, mm.mentions AS mentions\n      FROM messages m\n      INNER JOIN users u ON m.user_id = u.user_id\n      LEFT JOIN stickers st ON st.sticker_id = m.sticker_id\n      LEFT JOIN users su ON m.shared_user_id = su.user_id\n      LEFT JOIN message_mentions mm ON m.message_id = mm.message_id\n      WHERE m.conversation_id = :conversationId AND m.message_id = :messageId AND m.status != \'FAILED\'',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(messageId)
        ],
        readsFrom: {
          messages,
          users,
          stickers,
          messageMentions
        }).map((QueryRow row) {
      return QuoteMessageItem(
        messageId: row.readString('messageId'),
        conversationId: row.readString('conversationId'),
        userId: row.readString('userId'),
        userFullName: row.readString('userFullName'),
        userIdentityNumber: row.readString('userIdentityNumber'),
        appId: row.readString('appId'),
        type: Messages.$converter0.mapToDart(row.readString('type'))!,
        content: row.readString('content'),
        createdAt: Messages.$converter3.mapToDart(row.readInt('createdAt'))!,
        status: Messages.$converter2.mapToDart(row.readString('status'))!,
        mediaStatus:
            Messages.$converter1.mapToDart(row.readString('mediaStatus')),
        mediaWaveform: row.readString('mediaWaveform'),
        mediaName: row.readString('mediaName'),
        mediaMimeType: row.readString('mediaMimeType'),
        mediaSize: row.readInt('mediaSize'),
        mediaWidth: row.readInt('mediaWidth'),
        mediaHeight: row.readInt('mediaHeight'),
        thumbImage: row.readString('thumbImage'),
        thumbUrl: row.readString('thumbUrl'),
        mediaUrl: row.readString('mediaUrl'),
        mediaDuration: row.readString('mediaDuration'),
        quoteId: row.readString('quoteId'),
        quoteContent: row.readString('quoteContent'),
        assetUrl: row.readString('assetUrl'),
        assetWidth: row.readInt('assetWidth'),
        assetHeight: row.readInt('assetHeight'),
        stickerId: row.readString('stickerId'),
        assetName: row.readString('assetName'),
        assetType: row.readString('assetType'),
        sharedUserId: row.readString('sharedUserId'),
        sharedUserFullName: row.readString('sharedUserFullName'),
        sharedUserIdentityNumber: row.readString('sharedUserIdentityNumber'),
        sharedUserAvatarUrl: row.readString('sharedUserAvatarUrl'),
        sharedUserIsVerified: row.readInt('sharedUserIsVerified'),
        sharedUserAppId: row.readString('sharedUserAppId'),
        mentions: row.readString('mentions'),
      );
    });
  }

  Selectable<SearchMessageItem> fuzzySearchMessage(String query, int limit) {
    return customSelect(
        'SELECT m.conversation_id AS conversationId, c.icon_url AS conversationAvatarUrl,\n    c.name AS conversationName, c.category AS conversationCategory, count(m.message_id) as messageCount,\n    u.user_id AS userId, u.avatar_url AS userAvatarUrl, u.full_name AS userFullName\n    FROM messages m, (SELECT message_id FROM messages_fts WHERE messages_fts MATCH :query) fts\n    INNER JOIN users u ON c.owner_id = u.user_id\n    INNER JOIN conversations c ON c.conversation_id = m.conversation_id\n    WHERE m.message_id = messages_fts.message_id\n    GROUP BY m.conversation_id\n    ORDER BY max(m.created_at) DESC\n    LIMIT :limit',
        variables: [
          Variable<String>(query),
          Variable<int>(limit)
        ],
        readsFrom: {
          messages,
          conversations,
          users,
          messagesFts
        }).map((QueryRow row) {
      return SearchMessageItem(
        conversationId: row.readString('conversationId'),
        conversationAvatarUrl: row.readString('conversationAvatarUrl'),
        conversationName: row.readString('conversationName'),
        conversationCategory: Conversations.$converter0
            .mapToDart(row.readString('conversationCategory')),
        messageCount: row.readInt('messageCount'),
        userId: row.readString('userId'),
        userAvatarUrl: row.readString('userAvatarUrl'),
        userFullName: row.readString('userFullName'),
      );
    });
  }

  Selectable<SearchMessageDetailItem> fuzzySearchMessageByConversationId(
      String query, String conversationId) {
    return customSelect(
        'SELECT m.message_id messageId, u.user_id AS userId, u.avatar_url AS userAvatarUrl, u.full_name AS userFullName,\n    m.category AS type, m.content AS content, m.created_at AS createdAt, m.name AS mediaName\n    FROM messages m, (SELECT message_id FROM messages_fts WHERE messages_fts MATCH :query AND conversation_id = :conversationId) fts\n    INNER JOIN users u ON m.user_id = u.user_id\n    WHERE m.message_id = fts.message_id\n    ORDER BY m.created_at DESC',
        variables: [Variable<String>(query), Variable<String>(conversationId)],
        readsFrom: {messages, users, messagesFts}).map((QueryRow row) {
      return SearchMessageDetailItem(
        messageId: row.readString('messageId'),
        userId: row.readString('userId'),
        userAvatarUrl: row.readString('userAvatarUrl'),
        userFullName: row.readString('userFullName'),
        type: Messages.$converter0.mapToDart(row.readString('type'))!,
        content: row.readString('content'),
        createdAt: Messages.$converter3.mapToDart(row.readInt('createdAt'))!,
        mediaName: row.readString('mediaName'),
      );
    });
  }

  Selectable<int> contactConversationCount() {
    return customSelect(
        'SELECT Count(1)\nFROM   conversations c\n       INNER JOIN users ou\n               ON ou.user_id = c.owner_id\n       LEFT JOIN messages m\n              ON c.last_message_id = m.message_id\nWHERE  c.category = \'CONTACT\'\n       AND ou.relationship = \'FRIEND\'\n       AND ou.app_id IS NULL\nORDER  BY c.pin_time DESC, c.last_message_created_at DESC',
        variables: [],
        readsFrom: {
          conversations,
          users,
          messages
        }).map((QueryRow row) => row.readInt('Count(1)'));
  }

  Selectable<ConversationItem> contactConversations(int limit, int offset) {
    return customSelect(
        'SELECT c.conversation_id AS conversationId, c.icon_url AS groupIconUrl, c.category AS category,\n            c.name AS groupName, c.status AS status, c.last_read_message_id AS lastReadMessageId,\n            c.unseen_message_count AS unseenMessageCount, c.owner_id AS ownerId, c.pin_time AS pinTime, c.mute_until AS muteUntil,\n            ou.avatar_url AS avatarUrl, ou.full_name AS name, ou.is_verified AS ownerVerified,\n            ou.identity_number AS ownerIdentityNumber, ou.mute_until AS ownerMuteUntil, ou.app_id AS appId,\n            m.content AS content, m.category AS contentType, c.created_at AS createdAt, m.created_at AS lastMessageCreatedAt, m.media_url AS mediaUrl,\n            m.user_id AS senderId, m.action AS actionName, m.status AS messageStatus,\n            mu.full_name AS senderFullName, s.type AS SnapshotType,\n            pu.full_name AS participantFullName, pu.user_id AS participantUserId,\n            (SELECT count(*) FROM message_mentions me WHERE me.conversation_id = c.conversation_id AND me.has_read = 0) as mentionCount,\n            mm.mentions AS mentions,\n            ou.relationship AS relationship\n            FROM conversations c\n            INNER JOIN users ou ON ou.user_id = c.owner_id\n            LEFT JOIN messages m ON c.last_message_id = m.message_id\n            LEFT JOIN message_mentions mm ON mm.message_id = m.message_id\n            LEFT JOIN users mu ON mu.user_id = m.user_id\n            LEFT JOIN snapshots s ON s.snapshot_id = m.snapshot_id\n            LEFT JOIN users pu ON pu.user_id = m.participant_id\n            WHERE c.category = \'CONTACT\' AND ou.relationship = \'FRIEND\' AND ou.app_id IS NULL\n            ORDER BY c.pin_time DESC, c.last_message_created_at DESC\n            LIMIT :limit OFFSET :offset',
        variables: [
          Variable<int>(limit),
          Variable<int>(offset)
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          snapshots,
          messageMentions
        }).map((QueryRow row) {
      return ConversationItem(
        conversationId: row.readString('conversationId'),
        groupIconUrl: row.readString('groupIconUrl'),
        category:
            Conversations.$converter0.mapToDart(row.readString('category')),
        groupName: row.readString('groupName'),
        status: Conversations.$converter4.mapToDart(row.readInt('status'))!,
        lastReadMessageId: row.readString('lastReadMessageId'),
        unseenMessageCount: row.readInt('unseenMessageCount'),
        ownerId: row.readString('ownerId'),
        pinTime: Conversations.$converter2.mapToDart(row.readInt('pinTime')),
        muteUntil:
            Conversations.$converter5.mapToDart(row.readInt('muteUntil')),
        avatarUrl: row.readString('avatarUrl'),
        name: row.readString('name'),
        ownerVerified: row.readInt('ownerVerified'),
        ownerIdentityNumber: row.readString('ownerIdentityNumber'),
        ownerMuteUntil:
            Users.$converter2.mapToDart(row.readInt('ownerMuteUntil')),
        appId: row.readString('appId'),
        content: row.readString('content'),
        contentType:
            Messages.$converter0.mapToDart(row.readString('contentType')),
        createdAt:
            Conversations.$converter1.mapToDart(row.readInt('createdAt'))!,
        lastMessageCreatedAt:
            Messages.$converter3.mapToDart(row.readInt('lastMessageCreatedAt')),
        mediaUrl: row.readString('mediaUrl'),
        senderId: row.readString('senderId'),
        actionName:
            Messages.$converter4.mapToDart(row.readString('actionName')),
        messageStatus:
            Messages.$converter2.mapToDart(row.readString('messageStatus')),
        senderFullName: row.readString('senderFullName'),
        snapshotType: row.readString('SnapshotType'),
        participantFullName: row.readString('participantFullName'),
        participantUserId: row.readString('participantUserId'),
        mentionCount: row.readInt('mentionCount'),
        mentions: row.readString('mentions'),
        relationship:
            Users.$converter0.mapToDart(row.readString('relationship'))!,
      );
    });
  }

  Selectable<int> strangerConversationCount() {
    return customSelect(
        'SELECT Count(*)\nFROM   conversations c\n       INNER JOIN users ou\n               ON ou.user_id = c.owner_id\n       LEFT JOIN messages m\n              ON c.last_message_id = m.message_id\nWHERE  c.category = \'CONTACT\'\n       AND ou.relationship = \'STRANGER\'\nORDER  BY c.pin_time DESC,\n          CASE\n            WHEN m.created_at IS NULL THEN c.created_at\n            ELSE m.created_at\n          END DESC',
        variables: [],
        readsFrom: {
          conversations,
          users,
          messages
        }).map((QueryRow row) => row.readInt('Count(*)'));
  }

  Selectable<ConversationItem> strangerConversations(int limit, int offset) {
    return customSelect(
        'SELECT c.conversation_id AS conversationId, c.icon_url AS groupIconUrl, c.category AS category,\n            c.name AS groupName, c.status AS status, c.last_read_message_id AS lastReadMessageId,\n            c.unseen_message_count AS unseenMessageCount, c.owner_id AS ownerId, c.pin_time AS pinTime, c.mute_until AS muteUntil,\n            ou.avatar_url AS avatarUrl, ou.full_name AS name, ou.is_verified AS ownerVerified,\n            ou.identity_number AS ownerIdentityNumber, ou.mute_until AS ownerMuteUntil, ou.app_id AS appId,\n            m.content AS content, m.category AS contentType, c.created_at AS createdAt, m.created_at AS lastMessageCreatedAt, m.media_url AS mediaUrl,\n            m.user_id AS senderId, m.action AS actionName, m.status AS messageStatus,\n            mu.full_name AS senderFullName, s.type AS SnapshotType,\n            pu.full_name AS participantFullName, pu.user_id AS participantUserId,\n            (SELECT count(*) FROM message_mentions me WHERE me.conversation_id = c.conversation_id AND me.has_read = 0) as mentionCount,\n            mm.mentions AS mentions,\n            ou.relationship AS relationship\n            FROM conversations c\n            INNER JOIN users ou ON ou.user_id = c.owner_id\n            LEFT JOIN messages m ON c.last_message_id = m.message_id\n            LEFT JOIN message_mentions mm ON mm.message_id = m.message_id\n            LEFT JOIN users mu ON mu.user_id = m.user_id\n            LEFT JOIN snapshots s ON s.snapshot_id = m.snapshot_id\n            LEFT JOIN users pu ON pu.user_id = m.participant_id\n            WHERE c.category = \'CONTACT\' AND ou.relationship = \'STRANGER\'\n            ORDER BY c.pin_time DESC,\n              CASE\n                WHEN m.created_at is NULL THEN c.created_at\n                ELSE m.created_at\n              END\n            DESC\n            LIMIT :limit OFFSET :offset',
        variables: [
          Variable<int>(limit),
          Variable<int>(offset)
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          snapshots,
          messageMentions
        }).map((QueryRow row) {
      return ConversationItem(
        conversationId: row.readString('conversationId'),
        groupIconUrl: row.readString('groupIconUrl'),
        category:
            Conversations.$converter0.mapToDart(row.readString('category')),
        groupName: row.readString('groupName'),
        status: Conversations.$converter4.mapToDart(row.readInt('status'))!,
        lastReadMessageId: row.readString('lastReadMessageId'),
        unseenMessageCount: row.readInt('unseenMessageCount'),
        ownerId: row.readString('ownerId'),
        pinTime: Conversations.$converter2.mapToDart(row.readInt('pinTime')),
        muteUntil:
            Conversations.$converter5.mapToDart(row.readInt('muteUntil')),
        avatarUrl: row.readString('avatarUrl'),
        name: row.readString('name'),
        ownerVerified: row.readInt('ownerVerified'),
        ownerIdentityNumber: row.readString('ownerIdentityNumber'),
        ownerMuteUntil:
            Users.$converter2.mapToDart(row.readInt('ownerMuteUntil')),
        appId: row.readString('appId'),
        content: row.readString('content'),
        contentType:
            Messages.$converter0.mapToDart(row.readString('contentType')),
        createdAt:
            Conversations.$converter1.mapToDart(row.readInt('createdAt'))!,
        lastMessageCreatedAt:
            Messages.$converter3.mapToDart(row.readInt('lastMessageCreatedAt')),
        mediaUrl: row.readString('mediaUrl'),
        senderId: row.readString('senderId'),
        actionName:
            Messages.$converter4.mapToDart(row.readString('actionName')),
        messageStatus:
            Messages.$converter2.mapToDart(row.readString('messageStatus')),
        senderFullName: row.readString('senderFullName'),
        snapshotType: row.readString('SnapshotType'),
        participantFullName: row.readString('participantFullName'),
        participantUserId: row.readString('participantUserId'),
        mentionCount: row.readInt('mentionCount'),
        mentions: row.readString('mentions'),
        relationship:
            Users.$converter0.mapToDart(row.readString('relationship'))!,
      );
    });
  }

  Selectable<int> groupConversationCount() {
    return customSelect(
        'SELECT Count(*)\nFROM   conversations c\n       LEFT JOIN messages m\n              ON c.last_message_id = m.message_id\nWHERE  c.category = \'GROUP\'\nORDER  BY c.pin_time DESC,\n          CASE\n            WHEN m.created_at IS NULL THEN c.created_at\n            ELSE m.created_at\n          END DESC',
        variables: [],
        readsFrom: {
          conversations,
          messages
        }).map((QueryRow row) => row.readInt('Count(*)'));
  }

  Selectable<ConversationItem> groupConversations(int limit, int offset) {
    return customSelect(
        'SELECT c.conversation_id AS conversationId, c.icon_url AS groupIconUrl, c.category AS category,\n            c.name AS groupName, c.status AS status, c.last_read_message_id AS lastReadMessageId,\n            c.unseen_message_count AS unseenMessageCount, c.owner_id AS ownerId, c.pin_time AS pinTime, c.mute_until AS muteUntil,\n            ou.avatar_url AS avatarUrl, ou.full_name AS name, ou.is_verified AS ownerVerified,\n            ou.identity_number AS ownerIdentityNumber, ou.mute_until AS ownerMuteUntil, ou.app_id AS appId,\n            m.content AS content, m.category AS contentType, c.created_at AS createdAt, m.created_at AS lastMessageCreatedAt, m.media_url AS mediaUrl,\n            m.user_id AS senderId, m.action AS actionName, m.status AS messageStatus,\n            mu.full_name AS senderFullName, s.type AS SnapshotType,\n            pu.full_name AS participantFullName, pu.user_id AS participantUserId,\n            (SELECT count(*) FROM message_mentions me WHERE me.conversation_id = c.conversation_id AND me.has_read = 0) as mentionCount,\n            mm.mentions AS mentions,\n            ou.relationship AS relationship\n            FROM conversations c\n            INNER JOIN users ou ON ou.user_id = c.owner_id\n            LEFT JOIN messages m ON c.last_message_id = m.message_id\n            LEFT JOIN message_mentions mm ON mm.message_id = m.message_id\n            LEFT JOIN users mu ON mu.user_id = m.user_id\n            LEFT JOIN snapshots s ON s.snapshot_id = m.snapshot_id\n            LEFT JOIN users pu ON pu.user_id = m.participant_id\n            WHERE c.category = \'GROUP\'\n            ORDER BY c.pin_time DESC,\n              CASE\n                WHEN m.created_at is NULL THEN c.created_at\n                ELSE m.created_at\n              END\n            DESC\n            LIMIT :limit OFFSET :offset',
        variables: [
          Variable<int>(limit),
          Variable<int>(offset)
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          snapshots,
          messageMentions
        }).map((QueryRow row) {
      return ConversationItem(
        conversationId: row.readString('conversationId'),
        groupIconUrl: row.readString('groupIconUrl'),
        category:
            Conversations.$converter0.mapToDart(row.readString('category')),
        groupName: row.readString('groupName'),
        status: Conversations.$converter4.mapToDart(row.readInt('status'))!,
        lastReadMessageId: row.readString('lastReadMessageId'),
        unseenMessageCount: row.readInt('unseenMessageCount'),
        ownerId: row.readString('ownerId'),
        pinTime: Conversations.$converter2.mapToDart(row.readInt('pinTime')),
        muteUntil:
            Conversations.$converter5.mapToDart(row.readInt('muteUntil')),
        avatarUrl: row.readString('avatarUrl'),
        name: row.readString('name'),
        ownerVerified: row.readInt('ownerVerified'),
        ownerIdentityNumber: row.readString('ownerIdentityNumber'),
        ownerMuteUntil:
            Users.$converter2.mapToDart(row.readInt('ownerMuteUntil')),
        appId: row.readString('appId'),
        content: row.readString('content'),
        contentType:
            Messages.$converter0.mapToDart(row.readString('contentType')),
        createdAt:
            Conversations.$converter1.mapToDart(row.readInt('createdAt'))!,
        lastMessageCreatedAt:
            Messages.$converter3.mapToDart(row.readInt('lastMessageCreatedAt')),
        mediaUrl: row.readString('mediaUrl'),
        senderId: row.readString('senderId'),
        actionName:
            Messages.$converter4.mapToDart(row.readString('actionName')),
        messageStatus:
            Messages.$converter2.mapToDart(row.readString('messageStatus')),
        senderFullName: row.readString('senderFullName'),
        snapshotType: row.readString('SnapshotType'),
        participantFullName: row.readString('participantFullName'),
        participantUserId: row.readString('participantUserId'),
        mentionCount: row.readInt('mentionCount'),
        mentions: row.readString('mentions'),
        relationship:
            Users.$converter0.mapToDart(row.readString('relationship'))!,
      );
    });
  }

  Selectable<int> botConversationCount() {
    return customSelect(
        'SELECT Count(*)\nFROM   conversations c\n       INNER JOIN users ou\n               ON ou.user_id = c.owner_id\n       LEFT JOIN messages m\n              ON c.last_message_id = m.message_id\nWHERE  c.category = \'CONTACT\'\n       AND ou.app_id IS NOT NULL\nORDER  BY c.pin_time DESC,\n          CASE\n            WHEN m.created_at IS NULL THEN c.created_at\n            ELSE m.created_at\n          END DESC',
        variables: [],
        readsFrom: {
          conversations,
          users,
          messages
        }).map((QueryRow row) => row.readInt('Count(*)'));
  }

  Selectable<ConversationItem> botConversations(int limit, int offset) {
    return customSelect(
        'SELECT c.conversation_id AS conversationId, c.icon_url AS groupIconUrl, c.category AS category,\n            c.name AS groupName, c.status AS status, c.last_read_message_id AS lastReadMessageId,\n            c.unseen_message_count AS unseenMessageCount, c.owner_id AS ownerId, c.pin_time AS pinTime, c.mute_until AS muteUntil,\n            ou.avatar_url AS avatarUrl, ou.full_name AS name, ou.is_verified AS ownerVerified,\n            ou.identity_number AS ownerIdentityNumber, ou.mute_until AS ownerMuteUntil, ou.app_id AS appId,\n            m.content AS content, m.category AS contentType, c.created_at AS createdAt, m.created_at AS lastMessageCreatedAt, m.media_url AS mediaUrl,\n            m.user_id AS senderId, m.action AS actionName, m.status AS messageStatus,\n            mu.full_name AS senderFullName, s.type AS SnapshotType,\n            pu.full_name AS participantFullName, pu.user_id AS participantUserId,\n            (SELECT count(*) FROM message_mentions me WHERE me.conversation_id = c.conversation_id AND me.has_read = 0) as mentionCount,\n            mm.mentions AS mentions,\n            ou.relationship AS relationship\n            FROM conversations c\n            INNER JOIN users ou ON ou.user_id = c.owner_id\n            LEFT JOIN messages m ON c.last_message_id = m.message_id\n            LEFT JOIN message_mentions mm ON mm.message_id = m.message_id\n            LEFT JOIN users mu ON mu.user_id = m.user_id\n            LEFT JOIN snapshots s ON s.snapshot_id = m.snapshot_id\n            LEFT JOIN users pu ON pu.user_id = m.participant_id\n            WHERE c.category = \'CONTACT\' AND ou.app_id IS NOT NULL\n            ORDER BY c.pin_time DESC,\n              CASE\n                WHEN m.created_at is NULL THEN c.created_at\n                ELSE m.created_at\n              END\n            DESC\n            LIMIT :limit OFFSET :offset',
        variables: [
          Variable<int>(limit),
          Variable<int>(offset)
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          snapshots,
          messageMentions
        }).map((QueryRow row) {
      return ConversationItem(
        conversationId: row.readString('conversationId'),
        groupIconUrl: row.readString('groupIconUrl'),
        category:
            Conversations.$converter0.mapToDart(row.readString('category')),
        groupName: row.readString('groupName'),
        status: Conversations.$converter4.mapToDart(row.readInt('status'))!,
        lastReadMessageId: row.readString('lastReadMessageId'),
        unseenMessageCount: row.readInt('unseenMessageCount'),
        ownerId: row.readString('ownerId'),
        pinTime: Conversations.$converter2.mapToDart(row.readInt('pinTime')),
        muteUntil:
            Conversations.$converter5.mapToDart(row.readInt('muteUntil')),
        avatarUrl: row.readString('avatarUrl'),
        name: row.readString('name'),
        ownerVerified: row.readInt('ownerVerified'),
        ownerIdentityNumber: row.readString('ownerIdentityNumber'),
        ownerMuteUntil:
            Users.$converter2.mapToDart(row.readInt('ownerMuteUntil')),
        appId: row.readString('appId'),
        content: row.readString('content'),
        contentType:
            Messages.$converter0.mapToDart(row.readString('contentType')),
        createdAt:
            Conversations.$converter1.mapToDart(row.readInt('createdAt'))!,
        lastMessageCreatedAt:
            Messages.$converter3.mapToDart(row.readInt('lastMessageCreatedAt')),
        mediaUrl: row.readString('mediaUrl'),
        senderId: row.readString('senderId'),
        actionName:
            Messages.$converter4.mapToDart(row.readString('actionName')),
        messageStatus:
            Messages.$converter2.mapToDart(row.readString('messageStatus')),
        senderFullName: row.readString('senderFullName'),
        snapshotType: row.readString('SnapshotType'),
        participantFullName: row.readString('participantFullName'),
        participantUserId: row.readString('participantUserId'),
        mentionCount: row.readInt('mentionCount'),
        mentions: row.readString('mentions'),
        relationship:
            Users.$converter0.mapToDart(row.readString('relationship'))!,
      );
    });
  }

  Selectable<ConversationItem> conversationItem(String id) {
    return customSelect(
        'SELECT c.conversation_id AS conversationId, c.icon_url AS groupIconUrl, c.category AS category,\n            c.name AS groupName, c.status AS status, c.last_read_message_id AS lastReadMessageId,\n            c.unseen_message_count AS unseenMessageCount, c.owner_id AS ownerId, c.pin_time AS pinTime, c.mute_until AS muteUntil,\n            ou.avatar_url AS avatarUrl, ou.full_name AS name, ou.is_verified AS ownerVerified,\n            ou.identity_number AS ownerIdentityNumber, ou.mute_until AS ownerMuteUntil, ou.app_id AS appId,\n            m.content AS content, m.category AS contentType, c.created_at AS createdAt, m.created_at AS lastMessageCreatedAt, m.media_url AS mediaUrl,\n            m.user_id AS senderId, m.action AS actionName, m.status AS messageStatus,\n            mu.full_name AS senderFullName, s.type AS SnapshotType,\n            pu.full_name AS participantFullName, pu.user_id AS participantUserId,\n            (SELECT count(*) FROM message_mentions me WHERE me.conversation_id = c.conversation_id AND me.has_read = 0) as mentionCount,\n            mm.mentions AS mentions,\n            ou.relationship AS relationship\n            FROM conversations c\n            INNER JOIN users ou ON ou.user_id = c.owner_id\n            LEFT JOIN messages m ON c.last_message_id = m.message_id\n            LEFT JOIN message_mentions mm ON mm.message_id = m.message_id\n            LEFT JOIN users mu ON mu.user_id = m.user_id\n            LEFT JOIN snapshots s ON s.snapshot_id = m.snapshot_id\n            LEFT JOIN users pu ON pu.user_id = m.participant_id\n            WHERE c.conversation_id = :id\n                        ORDER BY c.pin_time DESC,\n              CASE\n                WHEN m.created_at is NULL THEN c.created_at\n                ELSE m.created_at\n              END\n            DESC',
        variables: [
          Variable<String>(id)
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          snapshots,
          messageMentions
        }).map((QueryRow row) {
      return ConversationItem(
        conversationId: row.readString('conversationId'),
        groupIconUrl: row.readString('groupIconUrl'),
        category:
            Conversations.$converter0.mapToDart(row.readString('category')),
        groupName: row.readString('groupName'),
        status: Conversations.$converter4.mapToDart(row.readInt('status'))!,
        lastReadMessageId: row.readString('lastReadMessageId'),
        unseenMessageCount: row.readInt('unseenMessageCount'),
        ownerId: row.readString('ownerId'),
        pinTime: Conversations.$converter2.mapToDart(row.readInt('pinTime')),
        muteUntil:
            Conversations.$converter5.mapToDart(row.readInt('muteUntil')),
        avatarUrl: row.readString('avatarUrl'),
        name: row.readString('name'),
        ownerVerified: row.readInt('ownerVerified'),
        ownerIdentityNumber: row.readString('ownerIdentityNumber'),
        ownerMuteUntil:
            Users.$converter2.mapToDart(row.readInt('ownerMuteUntil')),
        appId: row.readString('appId'),
        content: row.readString('content'),
        contentType:
            Messages.$converter0.mapToDart(row.readString('contentType')),
        createdAt:
            Conversations.$converter1.mapToDart(row.readInt('createdAt'))!,
        lastMessageCreatedAt:
            Messages.$converter3.mapToDart(row.readInt('lastMessageCreatedAt')),
        mediaUrl: row.readString('mediaUrl'),
        senderId: row.readString('senderId'),
        actionName:
            Messages.$converter4.mapToDart(row.readString('actionName')),
        messageStatus:
            Messages.$converter2.mapToDart(row.readString('messageStatus')),
        senderFullName: row.readString('senderFullName'),
        snapshotType: row.readString('SnapshotType'),
        participantFullName: row.readString('participantFullName'),
        participantUserId: row.readString('participantUserId'),
        mentionCount: row.readInt('mentionCount'),
        mentions: row.readString('mentions'),
        relationship:
            Users.$converter0.mapToDart(row.readString('relationship'))!,
      );
    });
  }

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        jobs,
        indexJobsAction,
        conversations,
        indexConversationsCategoryStatusPinTimeCreatedAt,
        messageMentions,
        indexMessageMentionsConversationId,
        messages,
        indexMessagesConversationId,
        indexMessagesConversationIdCreatedAt,
        indexMessagesConversationIdStatusUserId,
        indexMessagesConversationIdUserIdStatusCreatedAt,
        participants,
        indexParticipantsConversationId,
        indexParticipantsCreatedAt,
        snapshots,
        indexSnapshotsAssetId,
        users,
        indexUsersFullName,
        conversationLastMessageUpdate,
        conversationLastMessageDelete,
        addresses,
        apps,
        assets,
        circleConversations,
        circles,
        floodMessages,
        hyperlinks,
        messagesFts,
        messagesHistory,
        offsets,
        participantSession,
        ratchetSenderKeys,
        resendSessionMessages,
        sentSessionSenderKeys,
        stickerAlbums,
        stickerRelationships,
        stickers
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('conversations',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('messages', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('conversations',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('participants', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('messages',
                limitUpdateKind: UpdateKind.insert),
            result: [
              TableUpdate('conversations', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('messages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('conversations', kind: UpdateKind.update),
            ],
          ),
        ],
      );
}

class MessageItem {
  final String messageId;
  final String conversationId;
  final String userId;
  final String? userFullName;
  final String userIdentityNumber;
  final String? appId;
  final MessageCategory type;
  final String? content;
  final DateTime createdAt;
  final MessageStatus status;
  final MediaStatus? mediaStatus;
  final String? mediaWaveform;
  final String? mediaName;
  final String? mediaMimeType;
  final int? mediaSize;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? thumbImage;
  final String? thumbUrl;
  final String? mediaUrl;
  final String? mediaDuration;
  final String? quoteId;
  final String? quoteContent;
  final String? participantFullName;
  final MessageAction? actionName;
  final String participantUserId;
  final String? snapshotId;
  final String? snapshotType;
  final String? snapshotAmount;
  final String? assetSymbol;
  final String? assetId;
  final String? assetIcon;
  final String? assetUrl;
  final int? assetWidth;
  final int? assetHeight;
  final String? stickerId;
  final String? assetName;
  final String? assetType;
  final String? siteName;
  final String? siteTitle;
  final String? siteDescription;
  final String? siteImage;
  final String? sharedUserId;
  final String? sharedUserFullName;
  final String sharedUserIdentityNumber;
  final String? sharedUserAvatarUrl;
  final int? sharedUserIsVerified;
  final String? sharedUserAppId;
  final String? mentions;
  final int? mentionRead;
  final String? groupName;
  final UserRelationship relationship;
  final UserRelationship participantRelationship;
  MessageItem({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    this.userFullName,
    required this.userIdentityNumber,
    this.appId,
    required this.type,
    this.content,
    required this.createdAt,
    required this.status,
    this.mediaStatus,
    this.mediaWaveform,
    this.mediaName,
    this.mediaMimeType,
    this.mediaSize,
    this.mediaWidth,
    this.mediaHeight,
    this.thumbImage,
    this.thumbUrl,
    this.mediaUrl,
    this.mediaDuration,
    this.quoteId,
    this.quoteContent,
    this.participantFullName,
    this.actionName,
    required this.participantUserId,
    this.snapshotId,
    this.snapshotType,
    this.snapshotAmount,
    this.assetSymbol,
    this.assetId,
    this.assetIcon,
    this.assetUrl,
    this.assetWidth,
    this.assetHeight,
    this.stickerId,
    this.assetName,
    this.assetType,
    this.siteName,
    this.siteTitle,
    this.siteDescription,
    this.siteImage,
    this.sharedUserId,
    this.sharedUserFullName,
    required this.sharedUserIdentityNumber,
    this.sharedUserAvatarUrl,
    this.sharedUserIsVerified,
    this.sharedUserAppId,
    this.mentions,
    this.mentionRead,
    this.groupName,
    required this.relationship,
    required this.participantRelationship,
  });
  @override
  int get hashCode => $mrjf($mrjc(
      messageId.hashCode,
      $mrjc(
          conversationId.hashCode,
          $mrjc(
              userId.hashCode,
              $mrjc(
                  userFullName.hashCode,
                  $mrjc(
                      userIdentityNumber.hashCode,
                      $mrjc(
                          appId.hashCode,
                          $mrjc(
                              type.hashCode,
                              $mrjc(
                                  content.hashCode,
                                  $mrjc(
                                      createdAt.hashCode,
                                      $mrjc(
                                          status.hashCode,
                                          $mrjc(
                                              mediaStatus.hashCode,
                                              $mrjc(
                                                  mediaWaveform.hashCode,
                                                  $mrjc(
                                                      mediaName.hashCode,
                                                      $mrjc(
                                                          mediaMimeType
                                                              .hashCode,
                                                          $mrjc(
                                                              mediaSize
                                                                  .hashCode,
                                                              $mrjc(
                                                                  mediaWidth
                                                                      .hashCode,
                                                                  $mrjc(
                                                                      mediaHeight
                                                                          .hashCode,
                                                                      $mrjc(
                                                                          thumbImage
                                                                              .hashCode,
                                                                          $mrjc(
                                                                              thumbUrl.hashCode,
                                                                              $mrjc(mediaUrl.hashCode, $mrjc(mediaDuration.hashCode, $mrjc(quoteId.hashCode, $mrjc(quoteContent.hashCode, $mrjc(participantFullName.hashCode, $mrjc(actionName.hashCode, $mrjc(participantUserId.hashCode, $mrjc(snapshotId.hashCode, $mrjc(snapshotType.hashCode, $mrjc(snapshotAmount.hashCode, $mrjc(assetSymbol.hashCode, $mrjc(assetId.hashCode, $mrjc(assetIcon.hashCode, $mrjc(assetUrl.hashCode, $mrjc(assetWidth.hashCode, $mrjc(assetHeight.hashCode, $mrjc(stickerId.hashCode, $mrjc(assetName.hashCode, $mrjc(assetType.hashCode, $mrjc(siteName.hashCode, $mrjc(siteTitle.hashCode, $mrjc(siteDescription.hashCode, $mrjc(siteImage.hashCode, $mrjc(sharedUserId.hashCode, $mrjc(sharedUserFullName.hashCode, $mrjc(sharedUserIdentityNumber.hashCode, $mrjc(sharedUserAvatarUrl.hashCode, $mrjc(sharedUserIsVerified.hashCode, $mrjc(sharedUserAppId.hashCode, $mrjc(mentions.hashCode, $mrjc(mentionRead.hashCode, $mrjc(groupName.hashCode, $mrjc(relationship.hashCode, participantRelationship.hashCode)))))))))))))))))))))))))))))))))))))))))))))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is MessageItem &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.userFullName == this.userFullName &&
          other.userIdentityNumber == this.userIdentityNumber &&
          other.appId == this.appId &&
          other.type == this.type &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.mediaStatus == this.mediaStatus &&
          other.mediaWaveform == this.mediaWaveform &&
          other.mediaName == this.mediaName &&
          other.mediaMimeType == this.mediaMimeType &&
          other.mediaSize == this.mediaSize &&
          other.mediaWidth == this.mediaWidth &&
          other.mediaHeight == this.mediaHeight &&
          other.thumbImage == this.thumbImage &&
          other.thumbUrl == this.thumbUrl &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaDuration == this.mediaDuration &&
          other.quoteId == this.quoteId &&
          other.quoteContent == this.quoteContent &&
          other.participantFullName == this.participantFullName &&
          other.actionName == this.actionName &&
          other.participantUserId == this.participantUserId &&
          other.snapshotId == this.snapshotId &&
          other.snapshotType == this.snapshotType &&
          other.snapshotAmount == this.snapshotAmount &&
          other.assetSymbol == this.assetSymbol &&
          other.assetId == this.assetId &&
          other.assetIcon == this.assetIcon &&
          other.assetUrl == this.assetUrl &&
          other.assetWidth == this.assetWidth &&
          other.assetHeight == this.assetHeight &&
          other.stickerId == this.stickerId &&
          other.assetName == this.assetName &&
          other.assetType == this.assetType &&
          other.siteName == this.siteName &&
          other.siteTitle == this.siteTitle &&
          other.siteDescription == this.siteDescription &&
          other.siteImage == this.siteImage &&
          other.sharedUserId == this.sharedUserId &&
          other.sharedUserFullName == this.sharedUserFullName &&
          other.sharedUserIdentityNumber == this.sharedUserIdentityNumber &&
          other.sharedUserAvatarUrl == this.sharedUserAvatarUrl &&
          other.sharedUserIsVerified == this.sharedUserIsVerified &&
          other.sharedUserAppId == this.sharedUserAppId &&
          other.mentions == this.mentions &&
          other.mentionRead == this.mentionRead &&
          other.groupName == this.groupName &&
          other.relationship == this.relationship &&
          other.participantRelationship == this.participantRelationship);
  @override
  String toString() {
    return (StringBuffer('MessageItem(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('userFullName: $userFullName, ')
          ..write('userIdentityNumber: $userIdentityNumber, ')
          ..write('appId: $appId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('mediaStatus: $mediaStatus, ')
          ..write('mediaWaveform: $mediaWaveform, ')
          ..write('mediaName: $mediaName, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaSize: $mediaSize, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('thumbImage: $thumbImage, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaDuration: $mediaDuration, ')
          ..write('quoteId: $quoteId, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('participantFullName: $participantFullName, ')
          ..write('actionName: $actionName, ')
          ..write('participantUserId: $participantUserId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('snapshotType: $snapshotType, ')
          ..write('snapshotAmount: $snapshotAmount, ')
          ..write('assetSymbol: $assetSymbol, ')
          ..write('assetId: $assetId, ')
          ..write('assetIcon: $assetIcon, ')
          ..write('assetUrl: $assetUrl, ')
          ..write('assetWidth: $assetWidth, ')
          ..write('assetHeight: $assetHeight, ')
          ..write('stickerId: $stickerId, ')
          ..write('assetName: $assetName, ')
          ..write('assetType: $assetType, ')
          ..write('siteName: $siteName, ')
          ..write('siteTitle: $siteTitle, ')
          ..write('siteDescription: $siteDescription, ')
          ..write('siteImage: $siteImage, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('sharedUserFullName: $sharedUserFullName, ')
          ..write('sharedUserIdentityNumber: $sharedUserIdentityNumber, ')
          ..write('sharedUserAvatarUrl: $sharedUserAvatarUrl, ')
          ..write('sharedUserIsVerified: $sharedUserIsVerified, ')
          ..write('sharedUserAppId: $sharedUserAppId, ')
          ..write('mentions: $mentions, ')
          ..write('mentionRead: $mentionRead, ')
          ..write('groupName: $groupName, ')
          ..write('relationship: $relationship, ')
          ..write('participantRelationship: $participantRelationship')
          ..write(')'))
        .toString();
  }
}

class SendingMessage {
  final String messageId;
  final String conversationId;
  final String userId;
  final MessageCategory category;
  final String? content;
  final String? mediaUrl;
  final String? mediaMimeType;
  final int? mediaSize;
  final String? mediaDuration;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? mediaHash;
  final String? thumbImage;
  final String? mediaKey;
  final String? mediaDigest;
  final MediaStatus? mediaStatus;
  final MessageStatus status;
  final DateTime createdAt;
  final MessageAction? action;
  final String? participantId;
  final String? snapshotId;
  final String? hyperlink;
  final String? name;
  final String? albumId;
  final String? stickerId;
  final String? sharedUserId;
  final String? mediaWaveform;
  final String? quoteMessageId;
  final String? quoteContent;
  final int? resendStatus;
  final String? resendUserId;
  final String? resendSessionId;
  SendingMessage({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.category,
    this.content,
    this.mediaUrl,
    this.mediaMimeType,
    this.mediaSize,
    this.mediaDuration,
    this.mediaWidth,
    this.mediaHeight,
    this.mediaHash,
    this.thumbImage,
    this.mediaKey,
    this.mediaDigest,
    this.mediaStatus,
    required this.status,
    required this.createdAt,
    this.action,
    this.participantId,
    this.snapshotId,
    this.hyperlink,
    this.name,
    this.albumId,
    this.stickerId,
    this.sharedUserId,
    this.mediaWaveform,
    this.quoteMessageId,
    this.quoteContent,
    this.resendStatus,
    this.resendUserId,
    this.resendSessionId,
  });
  @override
  int get hashCode => $mrjf($mrjc(
      messageId.hashCode,
      $mrjc(
          conversationId.hashCode,
          $mrjc(
              userId.hashCode,
              $mrjc(
                  category.hashCode,
                  $mrjc(
                      content.hashCode,
                      $mrjc(
                          mediaUrl.hashCode,
                          $mrjc(
                              mediaMimeType.hashCode,
                              $mrjc(
                                  mediaSize.hashCode,
                                  $mrjc(
                                      mediaDuration.hashCode,
                                      $mrjc(
                                          mediaWidth.hashCode,
                                          $mrjc(
                                              mediaHeight.hashCode,
                                              $mrjc(
                                                  mediaHash.hashCode,
                                                  $mrjc(
                                                      thumbImage.hashCode,
                                                      $mrjc(
                                                          mediaKey.hashCode,
                                                          $mrjc(
                                                              mediaDigest
                                                                  .hashCode,
                                                              $mrjc(
                                                                  mediaStatus
                                                                      .hashCode,
                                                                  $mrjc(
                                                                      status
                                                                          .hashCode,
                                                                      $mrjc(
                                                                          createdAt
                                                                              .hashCode,
                                                                          $mrjc(
                                                                              action.hashCode,
                                                                              $mrjc(participantId.hashCode, $mrjc(snapshotId.hashCode, $mrjc(hyperlink.hashCode, $mrjc(name.hashCode, $mrjc(albumId.hashCode, $mrjc(stickerId.hashCode, $mrjc(sharedUserId.hashCode, $mrjc(mediaWaveform.hashCode, $mrjc(quoteMessageId.hashCode, $mrjc(quoteContent.hashCode, $mrjc(resendStatus.hashCode, $mrjc(resendUserId.hashCode, resendSessionId.hashCode))))))))))))))))))))))))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is SendingMessage &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.category == this.category &&
          other.content == this.content &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaMimeType == this.mediaMimeType &&
          other.mediaSize == this.mediaSize &&
          other.mediaDuration == this.mediaDuration &&
          other.mediaWidth == this.mediaWidth &&
          other.mediaHeight == this.mediaHeight &&
          other.mediaHash == this.mediaHash &&
          other.thumbImage == this.thumbImage &&
          other.mediaKey == this.mediaKey &&
          other.mediaDigest == this.mediaDigest &&
          other.mediaStatus == this.mediaStatus &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.action == this.action &&
          other.participantId == this.participantId &&
          other.snapshotId == this.snapshotId &&
          other.hyperlink == this.hyperlink &&
          other.name == this.name &&
          other.albumId == this.albumId &&
          other.stickerId == this.stickerId &&
          other.sharedUserId == this.sharedUserId &&
          other.mediaWaveform == this.mediaWaveform &&
          other.quoteMessageId == this.quoteMessageId &&
          other.quoteContent == this.quoteContent &&
          other.resendStatus == this.resendStatus &&
          other.resendUserId == this.resendUserId &&
          other.resendSessionId == this.resendSessionId);
  @override
  String toString() {
    return (StringBuffer('SendingMessage(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('category: $category, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaSize: $mediaSize, ')
          ..write('mediaDuration: $mediaDuration, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaHash: $mediaHash, ')
          ..write('thumbImage: $thumbImage, ')
          ..write('mediaKey: $mediaKey, ')
          ..write('mediaDigest: $mediaDigest, ')
          ..write('mediaStatus: $mediaStatus, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('action: $action, ')
          ..write('participantId: $participantId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('hyperlink: $hyperlink, ')
          ..write('name: $name, ')
          ..write('albumId: $albumId, ')
          ..write('stickerId: $stickerId, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('mediaWaveform: $mediaWaveform, ')
          ..write('quoteMessageId: $quoteMessageId, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('resendStatus: $resendStatus, ')
          ..write('resendUserId: $resendUserId, ')
          ..write('resendSessionId: $resendSessionId')
          ..write(')'))
        .toString();
  }
}

class QuoteMessageItem {
  final String messageId;
  final String conversationId;
  final String userId;
  final String? userFullName;
  final String userIdentityNumber;
  final String? appId;
  final MessageCategory type;
  final String? content;
  final DateTime createdAt;
  final MessageStatus status;
  final MediaStatus? mediaStatus;
  final String? mediaWaveform;
  final String? mediaName;
  final String? mediaMimeType;
  final int? mediaSize;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? thumbImage;
  final String? thumbUrl;
  final String? mediaUrl;
  final String? mediaDuration;
  final String? quoteId;
  final String? quoteContent;
  final String? assetUrl;
  final int? assetWidth;
  final int? assetHeight;
  final String? stickerId;
  final String? assetName;
  final String? assetType;
  final String? sharedUserId;
  final String? sharedUserFullName;
  final String sharedUserIdentityNumber;
  final String? sharedUserAvatarUrl;
  final int? sharedUserIsVerified;
  final String? sharedUserAppId;
  final String? mentions;
  QuoteMessageItem({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    this.userFullName,
    required this.userIdentityNumber,
    this.appId,
    required this.type,
    this.content,
    required this.createdAt,
    required this.status,
    this.mediaStatus,
    this.mediaWaveform,
    this.mediaName,
    this.mediaMimeType,
    this.mediaSize,
    this.mediaWidth,
    this.mediaHeight,
    this.thumbImage,
    this.thumbUrl,
    this.mediaUrl,
    this.mediaDuration,
    this.quoteId,
    this.quoteContent,
    this.assetUrl,
    this.assetWidth,
    this.assetHeight,
    this.stickerId,
    this.assetName,
    this.assetType,
    this.sharedUserId,
    this.sharedUserFullName,
    required this.sharedUserIdentityNumber,
    this.sharedUserAvatarUrl,
    this.sharedUserIsVerified,
    this.sharedUserAppId,
    this.mentions,
  });
  @override
  int get hashCode => $mrjf($mrjc(
      messageId.hashCode,
      $mrjc(
          conversationId.hashCode,
          $mrjc(
              userId.hashCode,
              $mrjc(
                  userFullName.hashCode,
                  $mrjc(
                      userIdentityNumber.hashCode,
                      $mrjc(
                          appId.hashCode,
                          $mrjc(
                              type.hashCode,
                              $mrjc(
                                  content.hashCode,
                                  $mrjc(
                                      createdAt.hashCode,
                                      $mrjc(
                                          status.hashCode,
                                          $mrjc(
                                              mediaStatus.hashCode,
                                              $mrjc(
                                                  mediaWaveform.hashCode,
                                                  $mrjc(
                                                      mediaName.hashCode,
                                                      $mrjc(
                                                          mediaMimeType
                                                              .hashCode,
                                                          $mrjc(
                                                              mediaSize
                                                                  .hashCode,
                                                              $mrjc(
                                                                  mediaWidth
                                                                      .hashCode,
                                                                  $mrjc(
                                                                      mediaHeight
                                                                          .hashCode,
                                                                      $mrjc(
                                                                          thumbImage
                                                                              .hashCode,
                                                                          $mrjc(
                                                                              thumbUrl.hashCode,
                                                                              $mrjc(mediaUrl.hashCode, $mrjc(mediaDuration.hashCode, $mrjc(quoteId.hashCode, $mrjc(quoteContent.hashCode, $mrjc(assetUrl.hashCode, $mrjc(assetWidth.hashCode, $mrjc(assetHeight.hashCode, $mrjc(stickerId.hashCode, $mrjc(assetName.hashCode, $mrjc(assetType.hashCode, $mrjc(sharedUserId.hashCode, $mrjc(sharedUserFullName.hashCode, $mrjc(sharedUserIdentityNumber.hashCode, $mrjc(sharedUserAvatarUrl.hashCode, $mrjc(sharedUserIsVerified.hashCode, $mrjc(sharedUserAppId.hashCode, mentions.hashCode))))))))))))))))))))))))))))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is QuoteMessageItem &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.userFullName == this.userFullName &&
          other.userIdentityNumber == this.userIdentityNumber &&
          other.appId == this.appId &&
          other.type == this.type &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.mediaStatus == this.mediaStatus &&
          other.mediaWaveform == this.mediaWaveform &&
          other.mediaName == this.mediaName &&
          other.mediaMimeType == this.mediaMimeType &&
          other.mediaSize == this.mediaSize &&
          other.mediaWidth == this.mediaWidth &&
          other.mediaHeight == this.mediaHeight &&
          other.thumbImage == this.thumbImage &&
          other.thumbUrl == this.thumbUrl &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaDuration == this.mediaDuration &&
          other.quoteId == this.quoteId &&
          other.quoteContent == this.quoteContent &&
          other.assetUrl == this.assetUrl &&
          other.assetWidth == this.assetWidth &&
          other.assetHeight == this.assetHeight &&
          other.stickerId == this.stickerId &&
          other.assetName == this.assetName &&
          other.assetType == this.assetType &&
          other.sharedUserId == this.sharedUserId &&
          other.sharedUserFullName == this.sharedUserFullName &&
          other.sharedUserIdentityNumber == this.sharedUserIdentityNumber &&
          other.sharedUserAvatarUrl == this.sharedUserAvatarUrl &&
          other.sharedUserIsVerified == this.sharedUserIsVerified &&
          other.sharedUserAppId == this.sharedUserAppId &&
          other.mentions == this.mentions);
  @override
  String toString() {
    return (StringBuffer('QuoteMessageItem(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('userFullName: $userFullName, ')
          ..write('userIdentityNumber: $userIdentityNumber, ')
          ..write('appId: $appId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('mediaStatus: $mediaStatus, ')
          ..write('mediaWaveform: $mediaWaveform, ')
          ..write('mediaName: $mediaName, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaSize: $mediaSize, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('thumbImage: $thumbImage, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaDuration: $mediaDuration, ')
          ..write('quoteId: $quoteId, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('assetUrl: $assetUrl, ')
          ..write('assetWidth: $assetWidth, ')
          ..write('assetHeight: $assetHeight, ')
          ..write('stickerId: $stickerId, ')
          ..write('assetName: $assetName, ')
          ..write('assetType: $assetType, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('sharedUserFullName: $sharedUserFullName, ')
          ..write('sharedUserIdentityNumber: $sharedUserIdentityNumber, ')
          ..write('sharedUserAvatarUrl: $sharedUserAvatarUrl, ')
          ..write('sharedUserIsVerified: $sharedUserIsVerified, ')
          ..write('sharedUserAppId: $sharedUserAppId, ')
          ..write('mentions: $mentions')
          ..write(')'))
        .toString();
  }
}

class SearchMessageItem {
  final String conversationId;
  final String? conversationAvatarUrl;
  final String? conversationName;
  final ConversationCategory? conversationCategory;
  final int messageCount;
  final String userId;
  final String? userAvatarUrl;
  final String? userFullName;
  SearchMessageItem({
    required this.conversationId,
    this.conversationAvatarUrl,
    this.conversationName,
    this.conversationCategory,
    required this.messageCount,
    required this.userId,
    this.userAvatarUrl,
    this.userFullName,
  });
  @override
  int get hashCode => $mrjf($mrjc(
      conversationId.hashCode,
      $mrjc(
          conversationAvatarUrl.hashCode,
          $mrjc(
              conversationName.hashCode,
              $mrjc(
                  conversationCategory.hashCode,
                  $mrjc(
                      messageCount.hashCode,
                      $mrjc(
                          userId.hashCode,
                          $mrjc(userAvatarUrl.hashCode,
                              userFullName.hashCode))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is SearchMessageItem &&
          other.conversationId == this.conversationId &&
          other.conversationAvatarUrl == this.conversationAvatarUrl &&
          other.conversationName == this.conversationName &&
          other.conversationCategory == this.conversationCategory &&
          other.messageCount == this.messageCount &&
          other.userId == this.userId &&
          other.userAvatarUrl == this.userAvatarUrl &&
          other.userFullName == this.userFullName);
  @override
  String toString() {
    return (StringBuffer('SearchMessageItem(')
          ..write('conversationId: $conversationId, ')
          ..write('conversationAvatarUrl: $conversationAvatarUrl, ')
          ..write('conversationName: $conversationName, ')
          ..write('conversationCategory: $conversationCategory, ')
          ..write('messageCount: $messageCount, ')
          ..write('userId: $userId, ')
          ..write('userAvatarUrl: $userAvatarUrl, ')
          ..write('userFullName: $userFullName')
          ..write(')'))
        .toString();
  }
}

class SearchMessageDetailItem {
  final String messageId;
  final String userId;
  final String? userAvatarUrl;
  final String? userFullName;
  final MessageCategory type;
  final String? content;
  final DateTime createdAt;
  final String? mediaName;
  SearchMessageDetailItem({
    required this.messageId,
    required this.userId,
    this.userAvatarUrl,
    this.userFullName,
    required this.type,
    this.content,
    required this.createdAt,
    this.mediaName,
  });
  @override
  int get hashCode => $mrjf($mrjc(
      messageId.hashCode,
      $mrjc(
          userId.hashCode,
          $mrjc(
              userAvatarUrl.hashCode,
              $mrjc(
                  userFullName.hashCode,
                  $mrjc(
                      type.hashCode,
                      $mrjc(content.hashCode,
                          $mrjc(createdAt.hashCode, mediaName.hashCode))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is SearchMessageDetailItem &&
          other.messageId == this.messageId &&
          other.userId == this.userId &&
          other.userAvatarUrl == this.userAvatarUrl &&
          other.userFullName == this.userFullName &&
          other.type == this.type &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.mediaName == this.mediaName);
  @override
  String toString() {
    return (StringBuffer('SearchMessageDetailItem(')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('userAvatarUrl: $userAvatarUrl, ')
          ..write('userFullName: $userFullName, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('mediaName: $mediaName')
          ..write(')'))
        .toString();
  }
}

class ConversationItem {
  final String conversationId;
  final String? groupIconUrl;
  final ConversationCategory? category;
  final String? groupName;
  final ConversationStatus status;
  final String? lastReadMessageId;
  final int? unseenMessageCount;
  final String? ownerId;
  final DateTime? pinTime;
  final DateTime? muteUntil;
  final String? avatarUrl;
  final String? name;
  final int? ownerVerified;
  final String ownerIdentityNumber;
  final DateTime? ownerMuteUntil;
  final String? appId;
  final String? content;
  final MessageCategory? contentType;
  final DateTime createdAt;
  final DateTime? lastMessageCreatedAt;
  final String? mediaUrl;
  final String? senderId;
  final MessageAction? actionName;
  final MessageStatus? messageStatus;
  final String? senderFullName;
  final String? snapshotType;
  final String? participantFullName;
  final String participantUserId;
  final int mentionCount;
  final String? mentions;
  final UserRelationship relationship;
  ConversationItem({
    required this.conversationId,
    this.groupIconUrl,
    this.category,
    this.groupName,
    required this.status,
    this.lastReadMessageId,
    this.unseenMessageCount,
    this.ownerId,
    this.pinTime,
    this.muteUntil,
    this.avatarUrl,
    this.name,
    this.ownerVerified,
    required this.ownerIdentityNumber,
    this.ownerMuteUntil,
    this.appId,
    this.content,
    this.contentType,
    required this.createdAt,
    this.lastMessageCreatedAt,
    this.mediaUrl,
    this.senderId,
    this.actionName,
    this.messageStatus,
    this.senderFullName,
    this.snapshotType,
    this.participantFullName,
    required this.participantUserId,
    required this.mentionCount,
    this.mentions,
    required this.relationship,
  });
  @override
  int get hashCode => $mrjf($mrjc(
      conversationId.hashCode,
      $mrjc(
          groupIconUrl.hashCode,
          $mrjc(
              category.hashCode,
              $mrjc(
                  groupName.hashCode,
                  $mrjc(
                      status.hashCode,
                      $mrjc(
                          lastReadMessageId.hashCode,
                          $mrjc(
                              unseenMessageCount.hashCode,
                              $mrjc(
                                  ownerId.hashCode,
                                  $mrjc(
                                      pinTime.hashCode,
                                      $mrjc(
                                          muteUntil.hashCode,
                                          $mrjc(
                                              avatarUrl.hashCode,
                                              $mrjc(
                                                  name.hashCode,
                                                  $mrjc(
                                                      ownerVerified.hashCode,
                                                      $mrjc(
                                                          ownerIdentityNumber
                                                              .hashCode,
                                                          $mrjc(
                                                              ownerMuteUntil
                                                                  .hashCode,
                                                              $mrjc(
                                                                  appId
                                                                      .hashCode,
                                                                  $mrjc(
                                                                      content
                                                                          .hashCode,
                                                                      $mrjc(
                                                                          contentType
                                                                              .hashCode,
                                                                          $mrjc(
                                                                              createdAt.hashCode,
                                                                              $mrjc(lastMessageCreatedAt.hashCode, $mrjc(mediaUrl.hashCode, $mrjc(senderId.hashCode, $mrjc(actionName.hashCode, $mrjc(messageStatus.hashCode, $mrjc(senderFullName.hashCode, $mrjc(snapshotType.hashCode, $mrjc(participantFullName.hashCode, $mrjc(participantUserId.hashCode, $mrjc(mentionCount.hashCode, $mrjc(mentions.hashCode, relationship.hashCode)))))))))))))))))))))))))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is ConversationItem &&
          other.conversationId == this.conversationId &&
          other.groupIconUrl == this.groupIconUrl &&
          other.category == this.category &&
          other.groupName == this.groupName &&
          other.status == this.status &&
          other.lastReadMessageId == this.lastReadMessageId &&
          other.unseenMessageCount == this.unseenMessageCount &&
          other.ownerId == this.ownerId &&
          other.pinTime == this.pinTime &&
          other.muteUntil == this.muteUntil &&
          other.avatarUrl == this.avatarUrl &&
          other.name == this.name &&
          other.ownerVerified == this.ownerVerified &&
          other.ownerIdentityNumber == this.ownerIdentityNumber &&
          other.ownerMuteUntil == this.ownerMuteUntil &&
          other.appId == this.appId &&
          other.content == this.content &&
          other.contentType == this.contentType &&
          other.createdAt == this.createdAt &&
          other.lastMessageCreatedAt == this.lastMessageCreatedAt &&
          other.mediaUrl == this.mediaUrl &&
          other.senderId == this.senderId &&
          other.actionName == this.actionName &&
          other.messageStatus == this.messageStatus &&
          other.senderFullName == this.senderFullName &&
          other.snapshotType == this.snapshotType &&
          other.participantFullName == this.participantFullName &&
          other.participantUserId == this.participantUserId &&
          other.mentionCount == this.mentionCount &&
          other.mentions == this.mentions &&
          other.relationship == this.relationship);
  @override
  String toString() {
    return (StringBuffer('ConversationItem(')
          ..write('conversationId: $conversationId, ')
          ..write('groupIconUrl: $groupIconUrl, ')
          ..write('category: $category, ')
          ..write('groupName: $groupName, ')
          ..write('status: $status, ')
          ..write('lastReadMessageId: $lastReadMessageId, ')
          ..write('unseenMessageCount: $unseenMessageCount, ')
          ..write('ownerId: $ownerId, ')
          ..write('pinTime: $pinTime, ')
          ..write('muteUntil: $muteUntil, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('name: $name, ')
          ..write('ownerVerified: $ownerVerified, ')
          ..write('ownerIdentityNumber: $ownerIdentityNumber, ')
          ..write('ownerMuteUntil: $ownerMuteUntil, ')
          ..write('appId: $appId, ')
          ..write('content: $content, ')
          ..write('contentType: $contentType, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMessageCreatedAt: $lastMessageCreatedAt, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('senderId: $senderId, ')
          ..write('actionName: $actionName, ')
          ..write('messageStatus: $messageStatus, ')
          ..write('senderFullName: $senderFullName, ')
          ..write('snapshotType: $snapshotType, ')
          ..write('participantFullName: $participantFullName, ')
          ..write('participantUserId: $participantUserId, ')
          ..write('mentionCount: $mentionCount, ')
          ..write('mentions: $mentions, ')
          ..write('relationship: $relationship')
          ..write(')'))
        .toString();
  }
}
