// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class SenderKey extends DataClass implements Insertable<SenderKey> {
  final String groupId;
  final String senderId;
  final Uint8List record;
  SenderKey(
      {@required this.groupId, @required this.senderId, @required this.record});
  factory SenderKey.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return SenderKey(
      groupId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}group_id']),
      senderId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}sender_id']),
      record: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}record']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || senderId != null) {
      map['sender_id'] = Variable<String>(senderId);
    }
    if (!nullToAbsent || record != null) {
      map['record'] = Variable<Uint8List>(record);
    }
    return map;
  }

  SenderKeysCompanion toCompanion(bool nullToAbsent) {
    return SenderKeysCompanion(
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      senderId: senderId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderId),
      record:
          record == null && nullToAbsent ? const Value.absent() : Value(record),
    );
  }

  factory SenderKey.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return SenderKey(
      groupId: serializer.fromJson<String>(json['group_id']),
      senderId: serializer.fromJson<String>(json['sender_id']),
      record: serializer.fromJson<Uint8List>(json['record']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'group_id': serializer.toJson<String>(groupId),
      'sender_id': serializer.toJson<String>(senderId),
      'record': serializer.toJson<Uint8List>(record),
    };
  }

  SenderKey copyWith({String groupId, String senderId, Uint8List record}) =>
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
      $mrjf($mrjc(groupId.hashCode, $mrjc(senderId.hashCode, record.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is SenderKey &&
          other.groupId == this.groupId &&
          other.senderId == this.senderId &&
          other.record == this.record);
}

class SenderKeysCompanion extends UpdateCompanion<SenderKey> {
  final Value<String> groupId;
  final Value<String> senderId;
  final Value<Uint8List> record;
  const SenderKeysCompanion({
    this.groupId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.record = const Value.absent(),
  });
  SenderKeysCompanion.insert({
    @required String groupId,
    @required String senderId,
    @required Uint8List record,
  })  : groupId = Value(groupId),
        senderId = Value(senderId),
        record = Value(record);
  static Insertable<SenderKey> custom({
    Expression<String> groupId,
    Expression<String> senderId,
    Expression<Uint8List> record,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (senderId != null) 'sender_id': senderId,
      if (record != null) 'record': record,
    });
  }

  SenderKeysCompanion copyWith(
      {Value<String> groupId,
      Value<String> senderId,
      Value<Uint8List> record}) {
    return SenderKeysCompanion(
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      record: record ?? this.record,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SenderKeysCompanion(')
          ..write('groupId: $groupId, ')
          ..write('senderId: $senderId, ')
          ..write('record: $record')
          ..write(')'))
        .toString();
  }
}

class SenderKeys extends Table with TableInfo<SenderKeys, SenderKey> {
  final GeneratedDatabase _db;
  final String _alias;
  SenderKeys(this._db, [this._alias]);
  final VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  GeneratedTextColumn _groupId;
  GeneratedTextColumn get groupId => _groupId ??= _constructGroupId();
  GeneratedTextColumn _constructGroupId() {
    return GeneratedTextColumn('group_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _senderIdMeta = const VerificationMeta('senderId');
  GeneratedTextColumn _senderId;
  GeneratedTextColumn get senderId => _senderId ??= _constructSenderId();
  GeneratedTextColumn _constructSenderId() {
    return GeneratedTextColumn('sender_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _recordMeta = const VerificationMeta('record');
  GeneratedBlobColumn _record;
  GeneratedBlobColumn get record => _record ??= _constructRecord();
  GeneratedBlobColumn _constructRecord() {
    return GeneratedBlobColumn('record', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [groupId, senderId, record];
  @override
  SenderKeys get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'sender_keys';
  @override
  final String actualTableName = 'sender_keys';
  @override
  VerificationContext validateIntegrity(Insertable<SenderKey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id'], _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id'], _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('record')) {
      context.handle(_recordMeta,
          record.isAcceptableOrUnknown(data['record'], _recordMeta));
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, senderId};
  @override
  SenderKey map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return SenderKey.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  SenderKeys createAlias(String alias) {
    return SenderKeys(_db, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(group_id, sender_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Identitie extends DataClass implements Insertable<Identitie> {
  final int id;
  final String address;
  final int registrationId;
  final Uint8List publicKey;
  final Uint8List privateKey;
  final int nextPrekeyId;
  final int timestamp;
  Identitie(
      {@required this.id,
      @required this.address,
      this.registrationId,
      @required this.publicKey,
      this.privateKey,
      this.nextPrekeyId,
      @required this.timestamp});
  factory Identitie.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return Identitie(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}_id']),
      address:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}address']),
      registrationId: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}registration_id']),
      publicKey: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}public_key']),
      privateKey: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}private_key']),
      nextPrekeyId: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}next_prekey_id']),
      timestamp:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}timestamp']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['_id'] = Variable<int>(id);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || registrationId != null) {
      map['registration_id'] = Variable<int>(registrationId);
    }
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<Uint8List>(publicKey);
    }
    if (!nullToAbsent || privateKey != null) {
      map['private_key'] = Variable<Uint8List>(privateKey);
    }
    if (!nullToAbsent || nextPrekeyId != null) {
      map['next_prekey_id'] = Variable<int>(nextPrekeyId);
    }
    if (!nullToAbsent || timestamp != null) {
      map['timestamp'] = Variable<int>(timestamp);
    }
    return map;
  }

  IdentitiesCompanion toCompanion(bool nullToAbsent) {
    return IdentitiesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      registrationId: registrationId == null && nullToAbsent
          ? const Value.absent()
          : Value(registrationId),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
      privateKey: privateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(privateKey),
      nextPrekeyId: nextPrekeyId == null && nullToAbsent
          ? const Value.absent()
          : Value(nextPrekeyId),
      timestamp: timestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(timestamp),
    );
  }

  factory Identitie.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Identitie(
      id: serializer.fromJson<int>(json['_id']),
      address: serializer.fromJson<String>(json['address']),
      registrationId: serializer.fromJson<int>(json['registration_id']),
      publicKey: serializer.fromJson<Uint8List>(json['public_key']),
      privateKey: serializer.fromJson<Uint8List>(json['private_key']),
      nextPrekeyId: serializer.fromJson<int>(json['next_prekey_id']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      '_id': serializer.toJson<int>(id),
      'address': serializer.toJson<String>(address),
      'registration_id': serializer.toJson<int>(registrationId),
      'public_key': serializer.toJson<Uint8List>(publicKey),
      'private_key': serializer.toJson<Uint8List>(privateKey),
      'next_prekey_id': serializer.toJson<int>(nextPrekeyId),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  Identitie copyWith(
          {int id,
          String address,
          int registrationId,
          Uint8List publicKey,
          Uint8List privateKey,
          int nextPrekeyId,
          int timestamp}) =>
      Identitie(
        id: id ?? this.id,
        address: address ?? this.address,
        registrationId: registrationId ?? this.registrationId,
        publicKey: publicKey ?? this.publicKey,
        privateKey: privateKey ?? this.privateKey,
        nextPrekeyId: nextPrekeyId ?? this.nextPrekeyId,
        timestamp: timestamp ?? this.timestamp,
      );
  @override
  String toString() {
    return (StringBuffer('Identitie(')
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
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(
          address.hashCode,
          $mrjc(
              registrationId.hashCode,
              $mrjc(
                  publicKey.hashCode,
                  $mrjc(privateKey.hashCode,
                      $mrjc(nextPrekeyId.hashCode, timestamp.hashCode)))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Identitie &&
          other.id == this.id &&
          other.address == this.address &&
          other.registrationId == this.registrationId &&
          other.publicKey == this.publicKey &&
          other.privateKey == this.privateKey &&
          other.nextPrekeyId == this.nextPrekeyId &&
          other.timestamp == this.timestamp);
}

class IdentitiesCompanion extends UpdateCompanion<Identitie> {
  final Value<int> id;
  final Value<String> address;
  final Value<int> registrationId;
  final Value<Uint8List> publicKey;
  final Value<Uint8List> privateKey;
  final Value<int> nextPrekeyId;
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
    @required String address,
    this.registrationId = const Value.absent(),
    @required Uint8List publicKey,
    this.privateKey = const Value.absent(),
    this.nextPrekeyId = const Value.absent(),
    @required int timestamp,
  })  : address = Value(address),
        publicKey = Value(publicKey),
        timestamp = Value(timestamp);
  static Insertable<Identitie> custom({
    Expression<int> id,
    Expression<String> address,
    Expression<int> registrationId,
    Expression<Uint8List> publicKey,
    Expression<Uint8List> privateKey,
    Expression<int> nextPrekeyId,
    Expression<int> timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) '_id': id,
      if (address != null) 'address': address,
      if (registrationId != null) 'registration_id': registrationId,
      if (publicKey != null) 'public_key': publicKey,
      if (privateKey != null) 'private_key': privateKey,
      if (nextPrekeyId != null) 'next_prekey_id': nextPrekeyId,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  IdentitiesCompanion copyWith(
      {Value<int> id,
      Value<String> address,
      Value<int> registrationId,
      Value<Uint8List> publicKey,
      Value<Uint8List> privateKey,
      Value<int> nextPrekeyId,
      Value<int> timestamp}) {
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
      map['_id'] = Variable<int>(id.value);
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

class Identities extends Table with TableInfo<Identities, Identitie> {
  final GeneratedDatabase _db;
  final String _alias;
  Identities(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('_id', $tableName, false,
        declaredAsPrimaryKey: true,
        hasAutoIncrement: true,
        $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  }

  final VerificationMeta _addressMeta = const VerificationMeta('address');
  GeneratedTextColumn _address;
  GeneratedTextColumn get address => _address ??= _constructAddress();
  GeneratedTextColumn _constructAddress() {
    return GeneratedTextColumn('address', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _registrationIdMeta =
      const VerificationMeta('registrationId');
  GeneratedIntColumn _registrationId;
  GeneratedIntColumn get registrationId =>
      _registrationId ??= _constructRegistrationId();
  GeneratedIntColumn _constructRegistrationId() {
    return GeneratedIntColumn('registration_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _publicKeyMeta = const VerificationMeta('publicKey');
  GeneratedBlobColumn _publicKey;
  GeneratedBlobColumn get publicKey => _publicKey ??= _constructPublicKey();
  GeneratedBlobColumn _constructPublicKey() {
    return GeneratedBlobColumn('public_key', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _privateKeyMeta = const VerificationMeta('privateKey');
  GeneratedBlobColumn _privateKey;
  GeneratedBlobColumn get privateKey => _privateKey ??= _constructPrivateKey();
  GeneratedBlobColumn _constructPrivateKey() {
    return GeneratedBlobColumn('private_key', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _nextPrekeyIdMeta =
      const VerificationMeta('nextPrekeyId');
  GeneratedIntColumn _nextPrekeyId;
  GeneratedIntColumn get nextPrekeyId =>
      _nextPrekeyId ??= _constructNextPrekeyId();
  GeneratedIntColumn _constructNextPrekeyId() {
    return GeneratedIntColumn('next_prekey_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  GeneratedIntColumn _timestamp;
  GeneratedIntColumn get timestamp => _timestamp ??= _constructTimestamp();
  GeneratedIntColumn _constructTimestamp() {
    return GeneratedIntColumn('timestamp', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

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
  Identities get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'identities';
  @override
  final String actualTableName = 'identities';
  @override
  VerificationContext validateIntegrity(Insertable<Identitie> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('_id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['_id'], _idMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address'], _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('registration_id')) {
      context.handle(
          _registrationIdMeta,
          registrationId.isAcceptableOrUnknown(
              data['registration_id'], _registrationIdMeta));
    }
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key'], _publicKeyMeta));
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('private_key')) {
      context.handle(
          _privateKeyMeta,
          privateKey.isAcceptableOrUnknown(
              data['private_key'], _privateKeyMeta));
    }
    if (data.containsKey('next_prekey_id')) {
      context.handle(
          _nextPrekeyIdMeta,
          nextPrekeyId.isAcceptableOrUnknown(
              data['next_prekey_id'], _nextPrekeyIdMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp'], _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Identitie map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Identitie.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Identities createAlias(String alias) {
    return Identities(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Prekey extends DataClass implements Insertable<Prekey> {
  final int id;
  final int prekeyId;
  final Uint8List record;
  Prekey({@required this.id, @required this.prekeyId, @required this.record});
  factory Prekey.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return Prekey(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}_id']),
      prekeyId:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}prekey_id']),
      record: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}record']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['_id'] = Variable<int>(id);
    }
    if (!nullToAbsent || prekeyId != null) {
      map['prekey_id'] = Variable<int>(prekeyId);
    }
    if (!nullToAbsent || record != null) {
      map['record'] = Variable<Uint8List>(record);
    }
    return map;
  }

  PrekeysCompanion toCompanion(bool nullToAbsent) {
    return PrekeysCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      prekeyId: prekeyId == null && nullToAbsent
          ? const Value.absent()
          : Value(prekeyId),
      record:
          record == null && nullToAbsent ? const Value.absent() : Value(record),
    );
  }

  factory Prekey.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Prekey(
      id: serializer.fromJson<int>(json['_id']),
      prekeyId: serializer.fromJson<int>(json['prekey_id']),
      record: serializer.fromJson<Uint8List>(json['record']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      '_id': serializer.toJson<int>(id),
      'prekey_id': serializer.toJson<int>(prekeyId),
      'record': serializer.toJson<Uint8List>(record),
    };
  }

  Prekey copyWith({int id, int prekeyId, Uint8List record}) => Prekey(
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
      $mrjf($mrjc(id.hashCode, $mrjc(prekeyId.hashCode, record.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Prekey &&
          other.id == this.id &&
          other.prekeyId == this.prekeyId &&
          other.record == this.record);
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
    @required int prekeyId,
    @required Uint8List record,
  })  : prekeyId = Value(prekeyId),
        record = Value(record);
  static Insertable<Prekey> custom({
    Expression<int> id,
    Expression<int> prekeyId,
    Expression<Uint8List> record,
  }) {
    return RawValuesInsertable({
      if (id != null) '_id': id,
      if (prekeyId != null) 'prekey_id': prekeyId,
      if (record != null) 'record': record,
    });
  }

  PrekeysCompanion copyWith(
      {Value<int> id, Value<int> prekeyId, Value<Uint8List> record}) {
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
      map['_id'] = Variable<int>(id.value);
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

class Prekeys extends Table with TableInfo<Prekeys, Prekey> {
  final GeneratedDatabase _db;
  final String _alias;
  Prekeys(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('_id', $tableName, false,
        declaredAsPrimaryKey: true,
        hasAutoIncrement: true,
        $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  }

  final VerificationMeta _prekeyIdMeta = const VerificationMeta('prekeyId');
  GeneratedIntColumn _prekeyId;
  GeneratedIntColumn get prekeyId => _prekeyId ??= _constructPrekeyId();
  GeneratedIntColumn _constructPrekeyId() {
    return GeneratedIntColumn('prekey_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _recordMeta = const VerificationMeta('record');
  GeneratedBlobColumn _record;
  GeneratedBlobColumn get record => _record ??= _constructRecord();
  GeneratedBlobColumn _constructRecord() {
    return GeneratedBlobColumn('record', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [id, prekeyId, record];
  @override
  Prekeys get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'prekeys';
  @override
  final String actualTableName = 'prekeys';
  @override
  VerificationContext validateIntegrity(Insertable<Prekey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('_id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['_id'], _idMeta));
    }
    if (data.containsKey('prekey_id')) {
      context.handle(_prekeyIdMeta,
          prekeyId.isAcceptableOrUnknown(data['prekey_id'], _prekeyIdMeta));
    } else if (isInserting) {
      context.missing(_prekeyIdMeta);
    }
    if (data.containsKey('record')) {
      context.handle(_recordMeta,
          record.isAcceptableOrUnknown(data['record'], _recordMeta));
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prekey map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Prekey.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Prekeys createAlias(String alias) {
    return Prekeys(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SignedPrekey extends DataClass implements Insertable<SignedPrekey> {
  final int id;
  final int prekeyId;
  final Uint8List record;
  final int timestamp;
  SignedPrekey(
      {@required this.id,
      @required this.prekeyId,
      @required this.record,
      @required this.timestamp});
  factory SignedPrekey.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return SignedPrekey(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}_id']),
      prekeyId:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}prekey_id']),
      record: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}record']),
      timestamp:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}timestamp']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['_id'] = Variable<int>(id);
    }
    if (!nullToAbsent || prekeyId != null) {
      map['prekey_id'] = Variable<int>(prekeyId);
    }
    if (!nullToAbsent || record != null) {
      map['record'] = Variable<Uint8List>(record);
    }
    if (!nullToAbsent || timestamp != null) {
      map['timestamp'] = Variable<int>(timestamp);
    }
    return map;
  }

  SignedPrekeysCompanion toCompanion(bool nullToAbsent) {
    return SignedPrekeysCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      prekeyId: prekeyId == null && nullToAbsent
          ? const Value.absent()
          : Value(prekeyId),
      record:
          record == null && nullToAbsent ? const Value.absent() : Value(record),
      timestamp: timestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(timestamp),
    );
  }

  factory SignedPrekey.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return SignedPrekey(
      id: serializer.fromJson<int>(json['_id']),
      prekeyId: serializer.fromJson<int>(json['prekey_id']),
      record: serializer.fromJson<Uint8List>(json['record']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      '_id': serializer.toJson<int>(id),
      'prekey_id': serializer.toJson<int>(prekeyId),
      'record': serializer.toJson<Uint8List>(record),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  SignedPrekey copyWith(
          {int id, int prekeyId, Uint8List record, int timestamp}) =>
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
  int get hashCode => $mrjf($mrjc(id.hashCode,
      $mrjc(prekeyId.hashCode, $mrjc(record.hashCode, timestamp.hashCode))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is SignedPrekey &&
          other.id == this.id &&
          other.prekeyId == this.prekeyId &&
          other.record == this.record &&
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
    @required int prekeyId,
    @required Uint8List record,
    @required int timestamp,
  })  : prekeyId = Value(prekeyId),
        record = Value(record),
        timestamp = Value(timestamp);
  static Insertable<SignedPrekey> custom({
    Expression<int> id,
    Expression<int> prekeyId,
    Expression<Uint8List> record,
    Expression<int> timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) '_id': id,
      if (prekeyId != null) 'prekey_id': prekeyId,
      if (record != null) 'record': record,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SignedPrekeysCompanion copyWith(
      {Value<int> id,
      Value<int> prekeyId,
      Value<Uint8List> record,
      Value<int> timestamp}) {
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
      map['_id'] = Variable<int>(id.value);
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

class SignedPrekeys extends Table with TableInfo<SignedPrekeys, SignedPrekey> {
  final GeneratedDatabase _db;
  final String _alias;
  SignedPrekeys(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('_id', $tableName, false,
        declaredAsPrimaryKey: true,
        hasAutoIncrement: true,
        $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  }

  final VerificationMeta _prekeyIdMeta = const VerificationMeta('prekeyId');
  GeneratedIntColumn _prekeyId;
  GeneratedIntColumn get prekeyId => _prekeyId ??= _constructPrekeyId();
  GeneratedIntColumn _constructPrekeyId() {
    return GeneratedIntColumn('prekey_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _recordMeta = const VerificationMeta('record');
  GeneratedBlobColumn _record;
  GeneratedBlobColumn get record => _record ??= _constructRecord();
  GeneratedBlobColumn _constructRecord() {
    return GeneratedBlobColumn('record', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  GeneratedIntColumn _timestamp;
  GeneratedIntColumn get timestamp => _timestamp ??= _constructTimestamp();
  GeneratedIntColumn _constructTimestamp() {
    return GeneratedIntColumn('timestamp', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [id, prekeyId, record, timestamp];
  @override
  SignedPrekeys get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'signed_prekeys';
  @override
  final String actualTableName = 'signed_prekeys';
  @override
  VerificationContext validateIntegrity(Insertable<SignedPrekey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('_id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['_id'], _idMeta));
    }
    if (data.containsKey('prekey_id')) {
      context.handle(_prekeyIdMeta,
          prekeyId.isAcceptableOrUnknown(data['prekey_id'], _prekeyIdMeta));
    } else if (isInserting) {
      context.missing(_prekeyIdMeta);
    }
    if (data.containsKey('record')) {
      context.handle(_recordMeta,
          record.isAcceptableOrUnknown(data['record'], _recordMeta));
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp'], _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignedPrekey map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return SignedPrekey.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  SignedPrekeys createAlias(String alias) {
    return SignedPrekeys(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String address;
  final Uint8List record;
  final int timestamp;
  Session(
      {@required this.id,
      @required this.address,
      @required this.record,
      @required this.timestamp});
  factory Session.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return Session(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}_id']),
      address:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}address']),
      record: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}record']),
      timestamp:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}timestamp']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['_id'] = Variable<int>(id);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || record != null) {
      map['record'] = Variable<Uint8List>(record);
    }
    if (!nullToAbsent || timestamp != null) {
      map['timestamp'] = Variable<int>(timestamp);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      record:
          record == null && nullToAbsent ? const Value.absent() : Value(record),
      timestamp: timestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(timestamp),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['_id']),
      address: serializer.fromJson<String>(json['address']),
      record: serializer.fromJson<Uint8List>(json['record']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      '_id': serializer.toJson<int>(id),
      'address': serializer.toJson<String>(address),
      'record': serializer.toJson<Uint8List>(record),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  Session copyWith({int id, String address, Uint8List record, int timestamp}) =>
      Session(
        id: id ?? this.id,
        address: address ?? this.address,
        record: record ?? this.record,
        timestamp: timestamp ?? this.timestamp,
      );
  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('address: $address, ')
          ..write('record: $record, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(id.hashCode,
      $mrjc(address.hashCode, $mrjc(record.hashCode, timestamp.hashCode))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.address == this.address &&
          other.record == this.record &&
          other.timestamp == this.timestamp);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> address;
  final Value<Uint8List> record;
  final Value<int> timestamp;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.address = const Value.absent(),
    this.record = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    @required String address,
    @required Uint8List record,
    @required int timestamp,
  })  : address = Value(address),
        record = Value(record),
        timestamp = Value(timestamp);
  static Insertable<Session> custom({
    Expression<int> id,
    Expression<String> address,
    Expression<Uint8List> record,
    Expression<int> timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) '_id': id,
      if (address != null) 'address': address,
      if (record != null) 'record': record,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SessionsCompanion copyWith(
      {Value<int> id,
      Value<String> address,
      Value<Uint8List> record,
      Value<int> timestamp}) {
    return SessionsCompanion(
      id: id ?? this.id,
      address: address ?? this.address,
      record: record ?? this.record,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['_id'] = Variable<int>(id.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
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
          ..write('record: $record, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class Sessions extends Table with TableInfo<Sessions, Session> {
  final GeneratedDatabase _db;
  final String _alias;
  Sessions(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('_id', $tableName, false,
        declaredAsPrimaryKey: true,
        hasAutoIncrement: true,
        $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  }

  final VerificationMeta _addressMeta = const VerificationMeta('address');
  GeneratedTextColumn _address;
  GeneratedTextColumn get address => _address ??= _constructAddress();
  GeneratedTextColumn _constructAddress() {
    return GeneratedTextColumn('address', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _recordMeta = const VerificationMeta('record');
  GeneratedBlobColumn _record;
  GeneratedBlobColumn get record => _record ??= _constructRecord();
  GeneratedBlobColumn _constructRecord() {
    return GeneratedBlobColumn('record', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  GeneratedIntColumn _timestamp;
  GeneratedIntColumn get timestamp => _timestamp ??= _constructTimestamp();
  GeneratedIntColumn _constructTimestamp() {
    return GeneratedIntColumn('timestamp', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [id, address, record, timestamp];
  @override
  Sessions get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'sessions';
  @override
  final String actualTableName = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('_id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['_id'], _idMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address'], _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('record')) {
      context.handle(_recordMeta,
          record.isAcceptableOrUnknown(data['record'], _recordMeta));
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp'], _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Session.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Sessions createAlias(String alias) {
    return Sessions(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

abstract class _$SignalDb extends GeneratedDatabase {
  _$SignalDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$SignalDb.connect(DatabaseConnection c) : super.connect(c);
  SenderKeys _senderKeys;
  SenderKeys get senderKeys => _senderKeys ??= SenderKeys(this);
  Identities _identities;
  Identities get identities => _identities ??= Identities(this);
  Prekeys _prekeys;
  Prekeys get prekeys => _prekeys ??= Prekeys(this);
  SignedPrekeys _signedPrekeys;
  SignedPrekeys get signedPrekeys => _signedPrekeys ??= SignedPrekeys(this);
  Sessions _sessions;
  Sessions get sessions => _sessions ??= Sessions(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [senderKeys, identities, prekeys, signedPrekeys, sessions];
}
