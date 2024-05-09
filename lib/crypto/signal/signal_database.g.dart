// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_database.dart';

// ignore_for_file: type=lint
class SenderKeys extends Table with TableInfo<SenderKeys, SenderKey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SenderKeys(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _recordMeta = const VerificationMeta('record');
  late final GeneratedColumn<Uint8List> record = GeneratedColumn<Uint8List>(
      'record', aliasedName, false,
      type: DriftSqlType.blob,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [groupId, senderId, record];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sender_keys';
  @override
  VerificationContext validateIntegrity(Insertable<SenderKey> instance,
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
    if (data.containsKey('record')) {
      context.handle(_recordMeta,
          record.isAcceptableOrUnknown(data['record']!, _recordMeta));
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, senderId};
  @override
  SenderKey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SenderKey(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      record: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}record'])!,
    );
  }

  @override
  SenderKeys createAlias(String alias) {
    return SenderKeys(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(group_id, sender_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class SenderKey extends DataClass implements Insertable<SenderKey> {
  final String groupId;
  final String senderId;
  final Uint8List record;
  const SenderKey(
      {required this.groupId, required this.senderId, required this.record});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['sender_id'] = Variable<String>(senderId);
    map['record'] = Variable<Uint8List>(record);
    return map;
  }

  SenderKeysCompanion toCompanion(bool nullToAbsent) {
    return SenderKeysCompanion(
      groupId: Value(groupId),
      senderId: Value(senderId),
      record: Value(record),
    );
  }

  factory SenderKey.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SenderKey(
      groupId: serializer.fromJson<String>(json['group_id']),
      senderId: serializer.fromJson<String>(json['sender_id']),
      record: serializer.fromJson<Uint8List>(json['record']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'group_id': serializer.toJson<String>(groupId),
      'sender_id': serializer.toJson<String>(senderId),
      'record': serializer.toJson<Uint8List>(record),
    };
  }

  SenderKey copyWith({String? groupId, String? senderId, Uint8List? record}) =>
      SenderKey(
        groupId: groupId ?? this.groupId,
        senderId: senderId ?? this.senderId,
        record: record ?? this.record,
      );
  @override
  String toString() {
    return (StringBuffer('SenderKey(')
          ..write('groupId: $groupId, ')
          ..write('senderId: $senderId, ')
          ..write('record: $record')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(groupId, senderId, $driftBlobEquality.hash(record));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SenderKey &&
          other.groupId == this.groupId &&
          other.senderId == this.senderId &&
          $driftBlobEquality.equals(other.record, this.record));
}

class SenderKeysCompanion extends UpdateCompanion<SenderKey> {
  final Value<String> groupId;
  final Value<String> senderId;
  final Value<Uint8List> record;
  final Value<int> rowid;
  const SenderKeysCompanion({
    this.groupId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.record = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SenderKeysCompanion.insert({
    required String groupId,
    required String senderId,
    required Uint8List record,
    this.rowid = const Value.absent(),
  })  : groupId = Value(groupId),
        senderId = Value(senderId),
        record = Value(record);
  static Insertable<SenderKey> custom({
    Expression<String>? groupId,
    Expression<String>? senderId,
    Expression<Uint8List>? record,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (senderId != null) 'sender_id': senderId,
      if (record != null) 'record': record,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SenderKeysCompanion copyWith(
      {Value<String>? groupId,
      Value<String>? senderId,
      Value<Uint8List>? record,
      Value<int>? rowid}) {
    return SenderKeysCompanion(
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      record: record ?? this.record,
      rowid: rowid ?? this.rowid,
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
    if (record.present) {
      map['record'] = Variable<Uint8List>(record.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SenderKeysCompanion(')
          ..write('groupId: $groupId, ')
          ..write('senderId: $senderId, ')
          ..write('record: $record, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Identities extends Table with TableInfo<Identities, Identity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Identities(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _registrationIdMeta =
      const VerificationMeta('registrationId');
  late final GeneratedColumn<int> registrationId = GeneratedColumn<int>(
      'registration_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _publicKeyMeta =
      const VerificationMeta('publicKey');
  late final GeneratedColumn<Uint8List> publicKey = GeneratedColumn<Uint8List>(
      'public_key', aliasedName, false,
      type: DriftSqlType.blob,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _privateKeyMeta =
      const VerificationMeta('privateKey');
  late final GeneratedColumn<Uint8List> privateKey = GeneratedColumn<Uint8List>(
      'private_key', aliasedName, true,
      type: DriftSqlType.blob,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _nextPrekeyIdMeta =
      const VerificationMeta('nextPrekeyId');
  late final GeneratedColumn<int> nextPrekeyId = GeneratedColumn<int>(
      'next_prekey_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [
        id,
        address,
        registrationId,
        publicKey,
        privateKey,
        nextPrekeyId,
        timestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'identities';
  @override
  VerificationContext validateIntegrity(Insertable<Identity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('registration_id')) {
      context.handle(
          _registrationIdMeta,
          registrationId.isAcceptableOrUnknown(
              data['registration_id']!, _registrationIdMeta));
    }
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta));
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('private_key')) {
      context.handle(
          _privateKeyMeta,
          privateKey.isAcceptableOrUnknown(
              data['private_key']!, _privateKeyMeta));
    }
    if (data.containsKey('next_prekey_id')) {
      context.handle(
          _nextPrekeyIdMeta,
          nextPrekeyId.isAcceptableOrUnknown(
              data['next_prekey_id']!, _nextPrekeyIdMeta));
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Identity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Identity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      registrationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}registration_id']),
      publicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}public_key'])!,
      privateKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}private_key']),
      nextPrekeyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_prekey_id']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  Identities createAlias(String alias) {
    return Identities(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Identity extends DataClass implements Insertable<Identity> {
  final int id;
  final String address;
  final int? registrationId;
  final Uint8List publicKey;
  final Uint8List? privateKey;
  final int? nextPrekeyId;
  final int timestamp;
  const Identity(
      {required this.id,
      required this.address,
      this.registrationId,
      required this.publicKey,
      this.privateKey,
      this.nextPrekeyId,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['address'] = Variable<String>(address);
    if (!nullToAbsent || registrationId != null) {
      map['registration_id'] = Variable<int>(registrationId);
    }
    map['public_key'] = Variable<Uint8List>(publicKey);
    if (!nullToAbsent || privateKey != null) {
      map['private_key'] = Variable<Uint8List>(privateKey);
    }
    if (!nullToAbsent || nextPrekeyId != null) {
      map['next_prekey_id'] = Variable<int>(nextPrekeyId);
    }
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  IdentitiesCompanion toCompanion(bool nullToAbsent) {
    return IdentitiesCompanion(
      id: Value(id),
      address: Value(address),
      registrationId: registrationId == null && nullToAbsent
          ? const Value.absent()
          : Value(registrationId),
      publicKey: Value(publicKey),
      privateKey: privateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(privateKey),
      nextPrekeyId: nextPrekeyId == null && nullToAbsent
          ? const Value.absent()
          : Value(nextPrekeyId),
      timestamp: Value(timestamp),
    );
  }

  factory Identity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Identity(
      id: serializer.fromJson<int>(json['id']),
      address: serializer.fromJson<String>(json['address']),
      registrationId: serializer.fromJson<int?>(json['registration_id']),
      publicKey: serializer.fromJson<Uint8List>(json['public_key']),
      privateKey: serializer.fromJson<Uint8List?>(json['private_key']),
      nextPrekeyId: serializer.fromJson<int?>(json['next_prekey_id']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'address': serializer.toJson<String>(address),
      'registration_id': serializer.toJson<int?>(registrationId),
      'public_key': serializer.toJson<Uint8List>(publicKey),
      'private_key': serializer.toJson<Uint8List?>(privateKey),
      'next_prekey_id': serializer.toJson<int?>(nextPrekeyId),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  Identity copyWith(
          {int? id,
          String? address,
          Value<int?> registrationId = const Value.absent(),
          Uint8List? publicKey,
          Value<Uint8List?> privateKey = const Value.absent(),
          Value<int?> nextPrekeyId = const Value.absent(),
          int? timestamp}) =>
      Identity(
        id: id ?? this.id,
        address: address ?? this.address,
        registrationId:
            registrationId.present ? registrationId.value : this.registrationId,
        publicKey: publicKey ?? this.publicKey,
        privateKey: privateKey.present ? privateKey.value : this.privateKey,
        nextPrekeyId:
            nextPrekeyId.present ? nextPrekeyId.value : this.nextPrekeyId,
        timestamp: timestamp ?? this.timestamp,
      );
  @override
  String toString() {
    return (StringBuffer('Identity(')
          ..write('id: $id, ')
          ..write('address: $address, ')
          ..write('registrationId: $registrationId, ')
          ..write('publicKey: $publicKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('nextPrekeyId: $nextPrekeyId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      address,
      registrationId,
      $driftBlobEquality.hash(publicKey),
      $driftBlobEquality.hash(privateKey),
      nextPrekeyId,
      timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Identity &&
          other.id == this.id &&
          other.address == this.address &&
          other.registrationId == this.registrationId &&
          $driftBlobEquality.equals(other.publicKey, this.publicKey) &&
          $driftBlobEquality.equals(other.privateKey, this.privateKey) &&
          other.nextPrekeyId == this.nextPrekeyId &&
          other.timestamp == this.timestamp);
}

class IdentitiesCompanion extends UpdateCompanion<Identity> {
  final Value<int> id;
  final Value<String> address;
  final Value<int?> registrationId;
  final Value<Uint8List> publicKey;
  final Value<Uint8List?> privateKey;
  final Value<int?> nextPrekeyId;
  final Value<int> timestamp;
  const IdentitiesCompanion({
    this.id = const Value.absent(),
    this.address = const Value.absent(),
    this.registrationId = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.privateKey = const Value.absent(),
    this.nextPrekeyId = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  IdentitiesCompanion.insert({
    this.id = const Value.absent(),
    required String address,
    this.registrationId = const Value.absent(),
    required Uint8List publicKey,
    this.privateKey = const Value.absent(),
    this.nextPrekeyId = const Value.absent(),
    required int timestamp,
  })  : address = Value(address),
        publicKey = Value(publicKey),
        timestamp = Value(timestamp);
  static Insertable<Identity> custom({
    Expression<int>? id,
    Expression<String>? address,
    Expression<int>? registrationId,
    Expression<Uint8List>? publicKey,
    Expression<Uint8List>? privateKey,
    Expression<int>? nextPrekeyId,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (address != null) 'address': address,
      if (registrationId != null) 'registration_id': registrationId,
      if (publicKey != null) 'public_key': publicKey,
      if (privateKey != null) 'private_key': privateKey,
      if (nextPrekeyId != null) 'next_prekey_id': nextPrekeyId,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  IdentitiesCompanion copyWith(
      {Value<int>? id,
      Value<String>? address,
      Value<int?>? registrationId,
      Value<Uint8List>? publicKey,
      Value<Uint8List?>? privateKey,
      Value<int?>? nextPrekeyId,
      Value<int>? timestamp}) {
    return IdentitiesCompanion(
      id: id ?? this.id,
      address: address ?? this.address,
      registrationId: registrationId ?? this.registrationId,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      nextPrekeyId: nextPrekeyId ?? this.nextPrekeyId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (registrationId.present) {
      map['registration_id'] = Variable<int>(registrationId.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<Uint8List>(publicKey.value);
    }
    if (privateKey.present) {
      map['private_key'] = Variable<Uint8List>(privateKey.value);
    }
    if (nextPrekeyId.present) {
      map['next_prekey_id'] = Variable<int>(nextPrekeyId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdentitiesCompanion(')
          ..write('id: $id, ')
          ..write('address: $address, ')
          ..write('registrationId: $registrationId, ')
          ..write('publicKey: $publicKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('nextPrekeyId: $nextPrekeyId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class Prekeys extends Table with TableInfo<Prekeys, Prekey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Prekeys(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  static const VerificationMeta _prekeyIdMeta =
      const VerificationMeta('prekeyId');
  late final GeneratedColumn<int> prekeyId = GeneratedColumn<int>(
      'prekey_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _recordMeta = const VerificationMeta('record');
  late final GeneratedColumn<Uint8List> record = GeneratedColumn<Uint8List>(
      'record', aliasedName, false,
      type: DriftSqlType.blob,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [id, prekeyId, record];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prekeys';
  @override
  VerificationContext validateIntegrity(Insertable<Prekey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prekey_id')) {
      context.handle(_prekeyIdMeta,
          prekeyId.isAcceptableOrUnknown(data['prekey_id']!, _prekeyIdMeta));
    } else if (isInserting) {
      context.missing(_prekeyIdMeta);
    }
    if (data.containsKey('record')) {
      context.handle(_recordMeta,
          record.isAcceptableOrUnknown(data['record']!, _recordMeta));
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prekey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prekey(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      prekeyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}prekey_id'])!,
      record: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}record'])!,
    );
  }

  @override
  Prekeys createAlias(String alias) {
    return Prekeys(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Prekey extends DataClass implements Insertable<Prekey> {
  final int id;
  final int prekeyId;
  final Uint8List record;
  const Prekey(
      {required this.id, required this.prekeyId, required this.record});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prekey_id'] = Variable<int>(prekeyId);
    map['record'] = Variable<Uint8List>(record);
    return map;
  }

  PrekeysCompanion toCompanion(bool nullToAbsent) {
    return PrekeysCompanion(
      id: Value(id),
      prekeyId: Value(prekeyId),
      record: Value(record),
    );
  }

  factory Prekey.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prekey(
      id: serializer.fromJson<int>(json['id']),
      prekeyId: serializer.fromJson<int>(json['prekey_id']),
      record: serializer.fromJson<Uint8List>(json['record']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'prekey_id': serializer.toJson<int>(prekeyId),
      'record': serializer.toJson<Uint8List>(record),
    };
  }

  Prekey copyWith({int? id, int? prekeyId, Uint8List? record}) => Prekey(
        id: id ?? this.id,
        prekeyId: prekeyId ?? this.prekeyId,
        record: record ?? this.record,
      );
  @override
  String toString() {
    return (StringBuffer('Prekey(')
          ..write('id: $id, ')
          ..write('prekeyId: $prekeyId, ')
          ..write('record: $record')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, prekeyId, $driftBlobEquality.hash(record));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prekey &&
          other.id == this.id &&
          other.prekeyId == this.prekeyId &&
          $driftBlobEquality.equals(other.record, this.record));
}

class PrekeysCompanion extends UpdateCompanion<Prekey> {
  final Value<int> id;
  final Value<int> prekeyId;
  final Value<Uint8List> record;
  const PrekeysCompanion({
    this.id = const Value.absent(),
    this.prekeyId = const Value.absent(),
    this.record = const Value.absent(),
  });
  PrekeysCompanion.insert({
    this.id = const Value.absent(),
    required int prekeyId,
    required Uint8List record,
  })  : prekeyId = Value(prekeyId),
        record = Value(record);
  static Insertable<Prekey> custom({
    Expression<int>? id,
    Expression<int>? prekeyId,
    Expression<Uint8List>? record,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prekeyId != null) 'prekey_id': prekeyId,
      if (record != null) 'record': record,
    });
  }

  PrekeysCompanion copyWith(
      {Value<int>? id, Value<int>? prekeyId, Value<Uint8List>? record}) {
    return PrekeysCompanion(
      id: id ?? this.id,
      prekeyId: prekeyId ?? this.prekeyId,
      record: record ?? this.record,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (prekeyId.present) {
      map['prekey_id'] = Variable<int>(prekeyId.value);
    }
    if (record.present) {
      map['record'] = Variable<Uint8List>(record.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrekeysCompanion(')
          ..write('id: $id, ')
          ..write('prekeyId: $prekeyId, ')
          ..write('record: $record')
          ..write(')'))
        .toString();
  }
}

class SignedPrekeys extends Table with TableInfo<SignedPrekeys, SignedPrekey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SignedPrekeys(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  static const VerificationMeta _prekeyIdMeta =
      const VerificationMeta('prekeyId');
  late final GeneratedColumn<int> prekeyId = GeneratedColumn<int>(
      'prekey_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _recordMeta = const VerificationMeta('record');
  late final GeneratedColumn<Uint8List> record = GeneratedColumn<Uint8List>(
      'record', aliasedName, false,
      type: DriftSqlType.blob,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [id, prekeyId, record, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signed_prekeys';
  @override
  VerificationContext validateIntegrity(Insertable<SignedPrekey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prekey_id')) {
      context.handle(_prekeyIdMeta,
          prekeyId.isAcceptableOrUnknown(data['prekey_id']!, _prekeyIdMeta));
    } else if (isInserting) {
      context.missing(_prekeyIdMeta);
    }
    if (data.containsKey('record')) {
      context.handle(_recordMeta,
          record.isAcceptableOrUnknown(data['record']!, _recordMeta));
    } else if (isInserting) {
      context.missing(_recordMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignedPrekey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignedPrekey(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      prekeyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}prekey_id'])!,
      record: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}record'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  SignedPrekeys createAlias(String alias) {
    return SignedPrekeys(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SignedPrekey extends DataClass implements Insertable<SignedPrekey> {
  final int id;
  final int prekeyId;
  final Uint8List record;
  final int timestamp;
  const SignedPrekey(
      {required this.id,
      required this.prekeyId,
      required this.record,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prekey_id'] = Variable<int>(prekeyId);
    map['record'] = Variable<Uint8List>(record);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  SignedPrekeysCompanion toCompanion(bool nullToAbsent) {
    return SignedPrekeysCompanion(
      id: Value(id),
      prekeyId: Value(prekeyId),
      record: Value(record),
      timestamp: Value(timestamp),
    );
  }

  factory SignedPrekey.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignedPrekey(
      id: serializer.fromJson<int>(json['id']),
      prekeyId: serializer.fromJson<int>(json['prekey_id']),
      record: serializer.fromJson<Uint8List>(json['record']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'prekey_id': serializer.toJson<int>(prekeyId),
      'record': serializer.toJson<Uint8List>(record),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  SignedPrekey copyWith(
          {int? id, int? prekeyId, Uint8List? record, int? timestamp}) =>
      SignedPrekey(
        id: id ?? this.id,
        prekeyId: prekeyId ?? this.prekeyId,
        record: record ?? this.record,
        timestamp: timestamp ?? this.timestamp,
      );
  @override
  String toString() {
    return (StringBuffer('SignedPrekey(')
          ..write('id: $id, ')
          ..write('prekeyId: $prekeyId, ')
          ..write('record: $record, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, prekeyId, $driftBlobEquality.hash(record), timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignedPrekey &&
          other.id == this.id &&
          other.prekeyId == this.prekeyId &&
          $driftBlobEquality.equals(other.record, this.record) &&
          other.timestamp == this.timestamp);
}

class SignedPrekeysCompanion extends UpdateCompanion<SignedPrekey> {
  final Value<int> id;
  final Value<int> prekeyId;
  final Value<Uint8List> record;
  final Value<int> timestamp;
  const SignedPrekeysCompanion({
    this.id = const Value.absent(),
    this.prekeyId = const Value.absent(),
    this.record = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  SignedPrekeysCompanion.insert({
    this.id = const Value.absent(),
    required int prekeyId,
    required Uint8List record,
    required int timestamp,
  })  : prekeyId = Value(prekeyId),
        record = Value(record),
        timestamp = Value(timestamp);
  static Insertable<SignedPrekey> custom({
    Expression<int>? id,
    Expression<int>? prekeyId,
    Expression<Uint8List>? record,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prekeyId != null) 'prekey_id': prekeyId,
      if (record != null) 'record': record,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SignedPrekeysCompanion copyWith(
      {Value<int>? id,
      Value<int>? prekeyId,
      Value<Uint8List>? record,
      Value<int>? timestamp}) {
    return SignedPrekeysCompanion(
      id: id ?? this.id,
      prekeyId: prekeyId ?? this.prekeyId,
      record: record ?? this.record,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (prekeyId.present) {
      map['prekey_id'] = Variable<int>(prekeyId.value);
    }
    if (record.present) {
      map['record'] = Variable<Uint8List>(record.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignedPrekeysCompanion(')
          ..write('id: $id, ')
          ..write('prekeyId: $prekeyId, ')
          ..write('record: $record, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class Sessions extends Table with TableInfo<Sessions, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Sessions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  late final GeneratedColumn<int> device = GeneratedColumn<int>(
      'device', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _recordMeta = const VerificationMeta('record');
  late final GeneratedColumn<Uint8List> record = GeneratedColumn<Uint8List>(
      'record', aliasedName, false,
      type: DriftSqlType.blob,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns =>
      [id, address, device, record, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('device')) {
      context.handle(_deviceMeta,
          device.isAcceptableOrUnknown(data['device']!, _deviceMeta));
    } else if (isInserting) {
      context.missing(_deviceMeta);
    }
    if (data.containsKey('record')) {
      context.handle(_recordMeta,
          record.isAcceptableOrUnknown(data['record']!, _recordMeta));
    } else if (isInserting) {
      context.missing(_recordMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      device: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device'])!,
      record: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}record'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  Sessions createAlias(String alias) {
    return Sessions(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String address;
  final int device;
  final Uint8List record;
  final int timestamp;
  const Session(
      {required this.id,
      required this.address,
      required this.device,
      required this.record,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['address'] = Variable<String>(address);
    map['device'] = Variable<int>(device);
    map['record'] = Variable<Uint8List>(record);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      address: Value(address),
      device: Value(device),
      record: Value(record),
      timestamp: Value(timestamp),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      address: serializer.fromJson<String>(json['address']),
      device: serializer.fromJson<int>(json['device']),
      record: serializer.fromJson<Uint8List>(json['record']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'address': serializer.toJson<String>(address),
      'device': serializer.toJson<int>(device),
      'record': serializer.toJson<Uint8List>(record),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  Session copyWith(
          {int? id,
          String? address,
          int? device,
          Uint8List? record,
          int? timestamp}) =>
      Session(
        id: id ?? this.id,
        address: address ?? this.address,
        device: device ?? this.device,
        record: record ?? this.record,
        timestamp: timestamp ?? this.timestamp,
      );
  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('address: $address, ')
          ..write('device: $device, ')
          ..write('record: $record, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, address, device, $driftBlobEquality.hash(record), timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.address == this.address &&
          other.device == this.device &&
          $driftBlobEquality.equals(other.record, this.record) &&
          other.timestamp == this.timestamp);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> address;
  final Value<int> device;
  final Value<Uint8List> record;
  final Value<int> timestamp;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.address = const Value.absent(),
    this.device = const Value.absent(),
    this.record = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String address,
    required int device,
    required Uint8List record,
    required int timestamp,
  })  : address = Value(address),
        device = Value(device),
        record = Value(record),
        timestamp = Value(timestamp);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? address,
    Expression<int>? device,
    Expression<Uint8List>? record,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (address != null) 'address': address,
      if (device != null) 'device': device,
      if (record != null) 'record': record,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SessionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? address,
      Value<int>? device,
      Value<Uint8List>? record,
      Value<int>? timestamp}) {
    return SessionsCompanion(
      id: id ?? this.id,
      address: address ?? this.address,
      device: device ?? this.device,
      record: record ?? this.record,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (device.present) {
      map['device'] = Variable<int>(device.value);
    }
    if (record.present) {
      map['record'] = Variable<Uint8List>(record.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('address: $address, ')
          ..write('device: $device, ')
          ..write('record: $record, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class RatchetSenderKeys extends Table
    with TableInfo<RatchetSenderKeys, RatchetSenderKey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RatchetSenderKeys(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns =>
      [groupId, senderId, status, messageId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ratchet_sender_keys';
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
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, senderId};
  @override
  RatchetSenderKey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatchetSenderKey(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  RatchetSenderKeys createAlias(String alias) {
    return RatchetSenderKeys(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(group_id, sender_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class RatchetSenderKey extends DataClass
    implements Insertable<RatchetSenderKey> {
  final String groupId;
  final String senderId;
  final String status;
  final String? messageId;
  final String createdAt;
  const RatchetSenderKey(
      {required this.groupId,
      required this.senderId,
      required this.status,
      this.messageId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['sender_id'] = Variable<String>(senderId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    map['created_at'] = Variable<String>(createdAt);
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatchetSenderKey(
      groupId: serializer.fromJson<String>(json['group_id']),
      senderId: serializer.fromJson<String>(json['sender_id']),
      status: serializer.fromJson<String>(json['status']),
      messageId: serializer.fromJson<String?>(json['message_id']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'group_id': serializer.toJson<String>(groupId),
      'sender_id': serializer.toJson<String>(senderId),
      'status': serializer.toJson<String>(status),
      'message_id': serializer.toJson<String?>(messageId),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  RatchetSenderKey copyWith(
          {String? groupId,
          String? senderId,
          String? status,
          Value<String?> messageId = const Value.absent(),
          String? createdAt}) =>
      RatchetSenderKey(
        groupId: groupId ?? this.groupId,
        senderId: senderId ?? this.senderId,
        status: status ?? this.status,
        messageId: messageId.present ? messageId.value : this.messageId,
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
  int get hashCode =>
      Object.hash(groupId, senderId, status, messageId, createdAt);
  @override
  bool operator ==(Object other) =>
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
  final Value<String> createdAt;
  final Value<int> rowid;
  const RatchetSenderKeysCompanion({
    this.groupId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.status = const Value.absent(),
    this.messageId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatchetSenderKeysCompanion.insert({
    required String groupId,
    required String senderId,
    required String status,
    this.messageId = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : groupId = Value(groupId),
        senderId = Value(senderId),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<RatchetSenderKey> custom({
    Expression<String>? groupId,
    Expression<String>? senderId,
    Expression<String>? status,
    Expression<String>? messageId,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (senderId != null) 'sender_id': senderId,
      if (status != null) 'status': status,
      if (messageId != null) 'message_id': messageId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatchetSenderKeysCompanion copyWith(
      {Value<String>? groupId,
      Value<String>? senderId,
      Value<String>? status,
      Value<String?>? messageId,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return RatchetSenderKeysCompanion(
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      status: status ?? this.status,
      messageId: messageId ?? this.messageId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
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
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SignalDatabase extends GeneratedDatabase {
  _$SignalDatabase(QueryExecutor e) : super(e);
  _$SignalDatabaseManager get managers => _$SignalDatabaseManager(this);
  late final SenderKeys senderKeys = SenderKeys(this);
  late final Identities identities = Identities(this);
  late final Index indexIdentitiesAddress = Index('index_identities_address',
      'CREATE UNIQUE INDEX IF NOT EXISTS index_identities_address ON identities (address)');
  late final Prekeys prekeys = Prekeys(this);
  late final Index indexPrekeysPrekeyId = Index('index_prekeys_prekey_id',
      'CREATE UNIQUE INDEX IF NOT EXISTS index_prekeys_prekey_id ON prekeys (prekey_id)');
  late final SignedPrekeys signedPrekeys = SignedPrekeys(this);
  late final Index indexSignedPrekeysPrekeyId = Index(
      'index_signed_prekeys_prekey_id',
      'CREATE UNIQUE INDEX IF NOT EXISTS index_signed_prekeys_prekey_id ON signed_prekeys (prekey_id)');
  late final Sessions sessions = Sessions(this);
  late final Index indexSessionsAddressDevice = Index(
      'index_sessions_address_device',
      'CREATE UNIQUE INDEX IF NOT EXISTS index_sessions_address_device ON sessions (address, device)');
  late final RatchetSenderKeys ratchetSenderKeys = RatchetSenderKeys(this);
  late final IdentityDao identityDao = IdentityDao(this as SignalDatabase);
  late final PreKeyDao preKeyDao = PreKeyDao(this as SignalDatabase);
  late final SenderKeyDao senderKeyDao = SenderKeyDao(this as SignalDatabase);
  late final SessionDao sessionDao = SessionDao(this as SignalDatabase);
  late final SignedPreKeyDao signedPreKeyDao =
      SignedPreKeyDao(this as SignalDatabase);
  late final RatchetSenderKeyDao ratchetSenderKeyDao =
      RatchetSenderKeyDao(this as SignalDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        senderKeys,
        identities,
        indexIdentitiesAddress,
        prekeys,
        indexPrekeysPrekeyId,
        signedPrekeys,
        indexSignedPrekeysPrekeyId,
        sessions,
        indexSessionsAddressDevice,
        ratchetSenderKeys
      ];
}

typedef $SenderKeysInsertCompanionBuilder = SenderKeysCompanion Function({
  required String groupId,
  required String senderId,
  required Uint8List record,
  Value<int> rowid,
});
typedef $SenderKeysUpdateCompanionBuilder = SenderKeysCompanion Function({
  Value<String> groupId,
  Value<String> senderId,
  Value<Uint8List> record,
  Value<int> rowid,
});

class $SenderKeysTableManager extends RootTableManager<
    _$SignalDatabase,
    SenderKeys,
    SenderKey,
    $SenderKeysFilterComposer,
    $SenderKeysOrderingComposer,
    $SenderKeysProcessedTableManager,
    $SenderKeysInsertCompanionBuilder,
    $SenderKeysUpdateCompanionBuilder> {
  $SenderKeysTableManager(_$SignalDatabase db, SenderKeys table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $SenderKeysFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $SenderKeysOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $SenderKeysProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> groupId = const Value.absent(),
            Value<String> senderId = const Value.absent(),
            Value<Uint8List> record = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SenderKeysCompanion(
            groupId: groupId,
            senderId: senderId,
            record: record,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String groupId,
            required String senderId,
            required Uint8List record,
            Value<int> rowid = const Value.absent(),
          }) =>
              SenderKeysCompanion.insert(
            groupId: groupId,
            senderId: senderId,
            record: record,
            rowid: rowid,
          ),
        ));
}

class $SenderKeysProcessedTableManager extends ProcessedTableManager<
    _$SignalDatabase,
    SenderKeys,
    SenderKey,
    $SenderKeysFilterComposer,
    $SenderKeysOrderingComposer,
    $SenderKeysProcessedTableManager,
    $SenderKeysInsertCompanionBuilder,
    $SenderKeysUpdateCompanionBuilder> {
  $SenderKeysProcessedTableManager(super.$state);
}

class $SenderKeysFilterComposer
    extends FilterComposer<_$SignalDatabase, SenderKeys> {
  $SenderKeysFilterComposer(super.$state);
  ColumnFilters<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get senderId => $state.composableBuilder(
      column: $state.table.senderId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get record => $state.composableBuilder(
      column: $state.table.record,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $SenderKeysOrderingComposer
    extends OrderingComposer<_$SignalDatabase, SenderKeys> {
  $SenderKeysOrderingComposer(super.$state);
  ColumnOrderings<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get senderId => $state.composableBuilder(
      column: $state.table.senderId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get record => $state.composableBuilder(
      column: $state.table.record,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $IdentitiesInsertCompanionBuilder = IdentitiesCompanion Function({
  Value<int> id,
  required String address,
  Value<int?> registrationId,
  required Uint8List publicKey,
  Value<Uint8List?> privateKey,
  Value<int?> nextPrekeyId,
  required int timestamp,
});
typedef $IdentitiesUpdateCompanionBuilder = IdentitiesCompanion Function({
  Value<int> id,
  Value<String> address,
  Value<int?> registrationId,
  Value<Uint8List> publicKey,
  Value<Uint8List?> privateKey,
  Value<int?> nextPrekeyId,
  Value<int> timestamp,
});

class $IdentitiesTableManager extends RootTableManager<
    _$SignalDatabase,
    Identities,
    Identity,
    $IdentitiesFilterComposer,
    $IdentitiesOrderingComposer,
    $IdentitiesProcessedTableManager,
    $IdentitiesInsertCompanionBuilder,
    $IdentitiesUpdateCompanionBuilder> {
  $IdentitiesTableManager(_$SignalDatabase db, Identities table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $IdentitiesFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $IdentitiesOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $IdentitiesProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<int?> registrationId = const Value.absent(),
            Value<Uint8List> publicKey = const Value.absent(),
            Value<Uint8List?> privateKey = const Value.absent(),
            Value<int?> nextPrekeyId = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
          }) =>
              IdentitiesCompanion(
            id: id,
            address: address,
            registrationId: registrationId,
            publicKey: publicKey,
            privateKey: privateKey,
            nextPrekeyId: nextPrekeyId,
            timestamp: timestamp,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required String address,
            Value<int?> registrationId = const Value.absent(),
            required Uint8List publicKey,
            Value<Uint8List?> privateKey = const Value.absent(),
            Value<int?> nextPrekeyId = const Value.absent(),
            required int timestamp,
          }) =>
              IdentitiesCompanion.insert(
            id: id,
            address: address,
            registrationId: registrationId,
            publicKey: publicKey,
            privateKey: privateKey,
            nextPrekeyId: nextPrekeyId,
            timestamp: timestamp,
          ),
        ));
}

class $IdentitiesProcessedTableManager extends ProcessedTableManager<
    _$SignalDatabase,
    Identities,
    Identity,
    $IdentitiesFilterComposer,
    $IdentitiesOrderingComposer,
    $IdentitiesProcessedTableManager,
    $IdentitiesInsertCompanionBuilder,
    $IdentitiesUpdateCompanionBuilder> {
  $IdentitiesProcessedTableManager(super.$state);
}

class $IdentitiesFilterComposer
    extends FilterComposer<_$SignalDatabase, Identities> {
  $IdentitiesFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get registrationId => $state.composableBuilder(
      column: $state.table.registrationId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get publicKey => $state.composableBuilder(
      column: $state.table.publicKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get privateKey => $state.composableBuilder(
      column: $state.table.privateKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get nextPrekeyId => $state.composableBuilder(
      column: $state.table.nextPrekeyId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $IdentitiesOrderingComposer
    extends OrderingComposer<_$SignalDatabase, Identities> {
  $IdentitiesOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get registrationId => $state.composableBuilder(
      column: $state.table.registrationId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get publicKey => $state.composableBuilder(
      column: $state.table.publicKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get privateKey => $state.composableBuilder(
      column: $state.table.privateKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get nextPrekeyId => $state.composableBuilder(
      column: $state.table.nextPrekeyId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $PrekeysInsertCompanionBuilder = PrekeysCompanion Function({
  Value<int> id,
  required int prekeyId,
  required Uint8List record,
});
typedef $PrekeysUpdateCompanionBuilder = PrekeysCompanion Function({
  Value<int> id,
  Value<int> prekeyId,
  Value<Uint8List> record,
});

class $PrekeysTableManager extends RootTableManager<
    _$SignalDatabase,
    Prekeys,
    Prekey,
    $PrekeysFilterComposer,
    $PrekeysOrderingComposer,
    $PrekeysProcessedTableManager,
    $PrekeysInsertCompanionBuilder,
    $PrekeysUpdateCompanionBuilder> {
  $PrekeysTableManager(_$SignalDatabase db, Prekeys table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $PrekeysFilterComposer(ComposerState(db, table)),
          orderingComposer: $PrekeysOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $PrekeysProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<int> prekeyId = const Value.absent(),
            Value<Uint8List> record = const Value.absent(),
          }) =>
              PrekeysCompanion(
            id: id,
            prekeyId: prekeyId,
            record: record,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required int prekeyId,
            required Uint8List record,
          }) =>
              PrekeysCompanion.insert(
            id: id,
            prekeyId: prekeyId,
            record: record,
          ),
        ));
}

class $PrekeysProcessedTableManager extends ProcessedTableManager<
    _$SignalDatabase,
    Prekeys,
    Prekey,
    $PrekeysFilterComposer,
    $PrekeysOrderingComposer,
    $PrekeysProcessedTableManager,
    $PrekeysInsertCompanionBuilder,
    $PrekeysUpdateCompanionBuilder> {
  $PrekeysProcessedTableManager(super.$state);
}

class $PrekeysFilterComposer extends FilterComposer<_$SignalDatabase, Prekeys> {
  $PrekeysFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get prekeyId => $state.composableBuilder(
      column: $state.table.prekeyId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get record => $state.composableBuilder(
      column: $state.table.record,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $PrekeysOrderingComposer
    extends OrderingComposer<_$SignalDatabase, Prekeys> {
  $PrekeysOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get prekeyId => $state.composableBuilder(
      column: $state.table.prekeyId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get record => $state.composableBuilder(
      column: $state.table.record,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $SignedPrekeysInsertCompanionBuilder = SignedPrekeysCompanion Function({
  Value<int> id,
  required int prekeyId,
  required Uint8List record,
  required int timestamp,
});
typedef $SignedPrekeysUpdateCompanionBuilder = SignedPrekeysCompanion Function({
  Value<int> id,
  Value<int> prekeyId,
  Value<Uint8List> record,
  Value<int> timestamp,
});

class $SignedPrekeysTableManager extends RootTableManager<
    _$SignalDatabase,
    SignedPrekeys,
    SignedPrekey,
    $SignedPrekeysFilterComposer,
    $SignedPrekeysOrderingComposer,
    $SignedPrekeysProcessedTableManager,
    $SignedPrekeysInsertCompanionBuilder,
    $SignedPrekeysUpdateCompanionBuilder> {
  $SignedPrekeysTableManager(_$SignalDatabase db, SignedPrekeys table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $SignedPrekeysFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $SignedPrekeysOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $SignedPrekeysProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<int> prekeyId = const Value.absent(),
            Value<Uint8List> record = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
          }) =>
              SignedPrekeysCompanion(
            id: id,
            prekeyId: prekeyId,
            record: record,
            timestamp: timestamp,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required int prekeyId,
            required Uint8List record,
            required int timestamp,
          }) =>
              SignedPrekeysCompanion.insert(
            id: id,
            prekeyId: prekeyId,
            record: record,
            timestamp: timestamp,
          ),
        ));
}

class $SignedPrekeysProcessedTableManager extends ProcessedTableManager<
    _$SignalDatabase,
    SignedPrekeys,
    SignedPrekey,
    $SignedPrekeysFilterComposer,
    $SignedPrekeysOrderingComposer,
    $SignedPrekeysProcessedTableManager,
    $SignedPrekeysInsertCompanionBuilder,
    $SignedPrekeysUpdateCompanionBuilder> {
  $SignedPrekeysProcessedTableManager(super.$state);
}

class $SignedPrekeysFilterComposer
    extends FilterComposer<_$SignalDatabase, SignedPrekeys> {
  $SignedPrekeysFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get prekeyId => $state.composableBuilder(
      column: $state.table.prekeyId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get record => $state.composableBuilder(
      column: $state.table.record,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $SignedPrekeysOrderingComposer
    extends OrderingComposer<_$SignalDatabase, SignedPrekeys> {
  $SignedPrekeysOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get prekeyId => $state.composableBuilder(
      column: $state.table.prekeyId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get record => $state.composableBuilder(
      column: $state.table.record,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $SessionsInsertCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required String address,
  required int device,
  required Uint8List record,
  required int timestamp,
});
typedef $SessionsUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<String> address,
  Value<int> device,
  Value<Uint8List> record,
  Value<int> timestamp,
});

class $SessionsTableManager extends RootTableManager<
    _$SignalDatabase,
    Sessions,
    Session,
    $SessionsFilterComposer,
    $SessionsOrderingComposer,
    $SessionsProcessedTableManager,
    $SessionsInsertCompanionBuilder,
    $SessionsUpdateCompanionBuilder> {
  $SessionsTableManager(_$SignalDatabase db, Sessions table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $SessionsFilterComposer(ComposerState(db, table)),
          orderingComposer: $SessionsOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $SessionsProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<int> device = const Value.absent(),
            Value<Uint8List> record = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            address: address,
            device: device,
            record: record,
            timestamp: timestamp,
          ),
          getInsertCompanionBuilder: ({
            Value<int> id = const Value.absent(),
            required String address,
            required int device,
            required Uint8List record,
            required int timestamp,
          }) =>
              SessionsCompanion.insert(
            id: id,
            address: address,
            device: device,
            record: record,
            timestamp: timestamp,
          ),
        ));
}

class $SessionsProcessedTableManager extends ProcessedTableManager<
    _$SignalDatabase,
    Sessions,
    Session,
    $SessionsFilterComposer,
    $SessionsOrderingComposer,
    $SessionsProcessedTableManager,
    $SessionsInsertCompanionBuilder,
    $SessionsUpdateCompanionBuilder> {
  $SessionsProcessedTableManager(super.$state);
}

class $SessionsFilterComposer
    extends FilterComposer<_$SignalDatabase, Sessions> {
  $SessionsFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get device => $state.composableBuilder(
      column: $state.table.device,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get record => $state.composableBuilder(
      column: $state.table.record,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $SessionsOrderingComposer
    extends OrderingComposer<_$SignalDatabase, Sessions> {
  $SessionsOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get device => $state.composableBuilder(
      column: $state.table.device,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get record => $state.composableBuilder(
      column: $state.table.record,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $RatchetSenderKeysInsertCompanionBuilder = RatchetSenderKeysCompanion
    Function({
  required String groupId,
  required String senderId,
  required String status,
  Value<String?> messageId,
  required String createdAt,
  Value<int> rowid,
});
typedef $RatchetSenderKeysUpdateCompanionBuilder = RatchetSenderKeysCompanion
    Function({
  Value<String> groupId,
  Value<String> senderId,
  Value<String> status,
  Value<String?> messageId,
  Value<String> createdAt,
  Value<int> rowid,
});

class $RatchetSenderKeysTableManager extends RootTableManager<
    _$SignalDatabase,
    RatchetSenderKeys,
    RatchetSenderKey,
    $RatchetSenderKeysFilterComposer,
    $RatchetSenderKeysOrderingComposer,
    $RatchetSenderKeysProcessedTableManager,
    $RatchetSenderKeysInsertCompanionBuilder,
    $RatchetSenderKeysUpdateCompanionBuilder> {
  $RatchetSenderKeysTableManager(_$SignalDatabase db, RatchetSenderKeys table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $RatchetSenderKeysFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $RatchetSenderKeysOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $RatchetSenderKeysProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> groupId = const Value.absent(),
            Value<String> senderId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RatchetSenderKeysCompanion(
            groupId: groupId,
            senderId: senderId,
            status: status,
            messageId: messageId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String groupId,
            required String senderId,
            required String status,
            Value<String?> messageId = const Value.absent(),
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RatchetSenderKeysCompanion.insert(
            groupId: groupId,
            senderId: senderId,
            status: status,
            messageId: messageId,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $RatchetSenderKeysProcessedTableManager extends ProcessedTableManager<
    _$SignalDatabase,
    RatchetSenderKeys,
    RatchetSenderKey,
    $RatchetSenderKeysFilterComposer,
    $RatchetSenderKeysOrderingComposer,
    $RatchetSenderKeysProcessedTableManager,
    $RatchetSenderKeysInsertCompanionBuilder,
    $RatchetSenderKeysUpdateCompanionBuilder> {
  $RatchetSenderKeysProcessedTableManager(super.$state);
}

class $RatchetSenderKeysFilterComposer
    extends FilterComposer<_$SignalDatabase, RatchetSenderKeys> {
  $RatchetSenderKeysFilterComposer(super.$state);
  ColumnFilters<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get senderId => $state.composableBuilder(
      column: $state.table.senderId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get messageId => $state.composableBuilder(
      column: $state.table.messageId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $RatchetSenderKeysOrderingComposer
    extends OrderingComposer<_$SignalDatabase, RatchetSenderKeys> {
  $RatchetSenderKeysOrderingComposer(super.$state);
  ColumnOrderings<String> get groupId => $state.composableBuilder(
      column: $state.table.groupId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get senderId => $state.composableBuilder(
      column: $state.table.senderId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get messageId => $state.composableBuilder(
      column: $state.table.messageId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class _$SignalDatabaseManager {
  final _$SignalDatabase _db;
  _$SignalDatabaseManager(this._db);
  $SenderKeysTableManager get senderKeys =>
      $SenderKeysTableManager(_db, _db.senderKeys);
  $IdentitiesTableManager get identities =>
      $IdentitiesTableManager(_db, _db.identities);
  $PrekeysTableManager get prekeys => $PrekeysTableManager(_db, _db.prekeys);
  $SignedPrekeysTableManager get signedPrekeys =>
      $SignedPrekeysTableManager(_db, _db.signedPrekeys);
  $SessionsTableManager get sessions =>
      $SessionsTableManager(_db, _db.sessions);
  $RatchetSenderKeysTableManager get ratchetSenderKeys =>
      $RatchetSenderKeysTableManager(_db, _db.ratchetSenderKeys);
}
