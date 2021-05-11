// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Identitie extends DataClass implements Insertable<Identitie> {
  final int id;
  final String address;
  final int? registrationId;
  final Uint8List publicKey;
  final Uint8List? privateKey;
  final int? nextPrekeyId;
  final int timestamp;
  Identitie(
      {required this.id,
      required this.address,
      this.registrationId,
      required this.publicKey,
      this.privateKey,
      this.nextPrekeyId,
      required this.timestamp});
  factory Identitie.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return Identitie(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      address: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}address'])!,
      registrationId: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}registration_id']),
      publicKey: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}public_key'])!,
      privateKey: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}private_key']),
      nextPrekeyId: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}next_prekey_id']),
      timestamp:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}timestamp'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['address'] = Variable<String>(address);
    if (!nullToAbsent || registrationId != null) {
      map['registration_id'] = Variable<int?>(registrationId);
    }
    map['public_key'] = Variable<Uint8List>(publicKey);
    if (!nullToAbsent || privateKey != null) {
      map['private_key'] = Variable<Uint8List?>(privateKey);
    }
    if (!nullToAbsent || nextPrekeyId != null) {
      map['next_prekey_id'] = Variable<int?>(nextPrekeyId);
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

  factory Identitie.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Identitie(
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
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

  Identitie copyWith(
          {int? id,
          String? address,
          int? registrationId,
          Uint8List? publicKey,
          Uint8List? privateKey,
          int? nextPrekeyId,
          int? timestamp}) =>
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
  })   : address = Value(address),
        publicKey = Value(publicKey),
        timestamp = Value(timestamp);
  static Insertable<Identitie> custom({
    Expression<int>? id,
    Expression<String>? address,
    Expression<int?>? registrationId,
    Expression<Uint8List>? publicKey,
    Expression<Uint8List?>? privateKey,
    Expression<int?>? nextPrekeyId,
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
      map['registration_id'] = Variable<int?>(registrationId.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<Uint8List>(publicKey.value);
    }
    if (privateKey.present) {
      map['private_key'] = Variable<Uint8List?>(privateKey.value);
    }
    if (nextPrekeyId.present) {
      map['next_prekey_id'] = Variable<int?>(nextPrekeyId.value);
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
  final String? _alias;
  Identities(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        declaredAsPrimaryKey: true,
        hasAutoIncrement: true,
        $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  }

  final VerificationMeta _addressMeta = const VerificationMeta('address');
  late final GeneratedTextColumn address = _constructAddress();
  GeneratedTextColumn _constructAddress() {
    return GeneratedTextColumn('address', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _registrationIdMeta =
      const VerificationMeta('registrationId');
  late final GeneratedIntColumn registrationId = _constructRegistrationId();
  GeneratedIntColumn _constructRegistrationId() {
    return GeneratedIntColumn('registration_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _publicKeyMeta = const VerificationMeta('publicKey');
  late final GeneratedBlobColumn publicKey = _constructPublicKey();
  GeneratedBlobColumn _constructPublicKey() {
    return GeneratedBlobColumn('public_key', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _privateKeyMeta = const VerificationMeta('privateKey');
  late final GeneratedBlobColumn privateKey = _constructPrivateKey();
  GeneratedBlobColumn _constructPrivateKey() {
    return GeneratedBlobColumn('private_key', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _nextPrekeyIdMeta =
      const VerificationMeta('nextPrekeyId');
  late final GeneratedIntColumn nextPrekeyId = _constructNextPrekeyId();
  GeneratedIntColumn _constructNextPrekeyId() {
    return GeneratedIntColumn('next_prekey_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  late final GeneratedIntColumn timestamp = _constructTimestamp();
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
  Identitie map(Map<String, dynamic> data, {String? tablePrefix}) {
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
  Prekey({required this.id, required this.prekeyId, required this.record});
  factory Prekey.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return Prekey(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      prekeyId:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}prekey_id'])!,
      record: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}record'])!,
    );
  }
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Prekey(
      id: serializer.fromJson<int>(json['id']),
      prekeyId: serializer.fromJson<int>(json['prekey_id']),
      record: serializer.fromJson<Uint8List>(json['record']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
    required int prekeyId,
    required Uint8List record,
  })   : prekeyId = Value(prekeyId),
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

class Prekeys extends Table with TableInfo<Prekeys, Prekey> {
  final GeneratedDatabase _db;
  final String? _alias;
  Prekeys(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        declaredAsPrimaryKey: true,
        hasAutoIncrement: true,
        $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  }

  final VerificationMeta _prekeyIdMeta = const VerificationMeta('prekeyId');
  late final GeneratedIntColumn prekeyId = _constructPrekeyId();
  GeneratedIntColumn _constructPrekeyId() {
    return GeneratedIntColumn('prekey_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _recordMeta = const VerificationMeta('record');
  late final GeneratedBlobColumn record = _constructRecord();
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
      {required this.id,
      required this.prekeyId,
      required this.record,
      required this.timestamp});
  factory SignedPrekey.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return SignedPrekey(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      prekeyId:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}prekey_id'])!,
      record: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}record'])!,
      timestamp:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}timestamp'])!,
    );
  }
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return SignedPrekey(
      id: serializer.fromJson<int>(json['id']),
      prekeyId: serializer.fromJson<int>(json['prekey_id']),
      record: serializer.fromJson<Uint8List>(json['record']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
    required int prekeyId,
    required Uint8List record,
    required int timestamp,
  })   : prekeyId = Value(prekeyId),
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

class SignedPrekeys extends Table with TableInfo<SignedPrekeys, SignedPrekey> {
  final GeneratedDatabase _db;
  final String? _alias;
  SignedPrekeys(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        declaredAsPrimaryKey: true,
        hasAutoIncrement: true,
        $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  }

  final VerificationMeta _prekeyIdMeta = const VerificationMeta('prekeyId');
  late final GeneratedIntColumn prekeyId = _constructPrekeyId();
  GeneratedIntColumn _constructPrekeyId() {
    return GeneratedIntColumn('prekey_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _recordMeta = const VerificationMeta('record');
  late final GeneratedBlobColumn record = _constructRecord();
  GeneratedBlobColumn _constructRecord() {
    return GeneratedBlobColumn('record', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  late final GeneratedIntColumn timestamp = _constructTimestamp();
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
  final int device;
  final Uint8List record;
  final int timestamp;
  Session(
      {required this.id,
      required this.address,
      required this.device,
      required this.record,
      required this.timestamp});
  factory Session.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return Session(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      address: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}address'])!,
      device:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}device'])!,
      record: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}record'])!,
      timestamp:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}timestamp'])!,
    );
  }
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(address.hashCode,
          $mrjc(device.hashCode, $mrjc(record.hashCode, timestamp.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.address == this.address &&
          other.device == this.device &&
          other.record == this.record &&
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
  })   : address = Value(address),
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

class Sessions extends Table with TableInfo<Sessions, Session> {
  final GeneratedDatabase _db;
  final String? _alias;
  Sessions(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        declaredAsPrimaryKey: true,
        hasAutoIncrement: true,
        $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL');
  }

  final VerificationMeta _addressMeta = const VerificationMeta('address');
  late final GeneratedTextColumn address = _constructAddress();
  GeneratedTextColumn _constructAddress() {
    return GeneratedTextColumn('address', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _deviceMeta = const VerificationMeta('device');
  late final GeneratedIntColumn device = _constructDevice();
  GeneratedIntColumn _constructDevice() {
    return GeneratedIntColumn('device', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _recordMeta = const VerificationMeta('record');
  late final GeneratedBlobColumn record = _constructRecord();
  GeneratedBlobColumn _constructRecord() {
    return GeneratedBlobColumn('record', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  late final GeneratedIntColumn timestamp = _constructTimestamp();
  GeneratedIntColumn _constructTimestamp() {
    return GeneratedIntColumn('timestamp', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [id, address, device, record, timestamp];
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

class SenderKey extends DataClass implements Insertable<SenderKey> {
  final String groupId;
  final String senderId;
  final Uint8List record;
  SenderKey(
      {required this.groupId, required this.senderId, required this.record});
  factory SenderKey.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return SenderKey(
      groupId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}group_id'])!,
      senderId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}sender_id'])!,
      record: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}record'])!,
    );
  }
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return SenderKey(
      groupId: serializer.fromJson<String>(json['group_id']),
      senderId: serializer.fromJson<String>(json['sender_id']),
      record: serializer.fromJson<Uint8List>(json['record']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
    required String groupId,
    required String senderId,
    required Uint8List record,
  })   : groupId = Value(groupId),
        senderId = Value(senderId),
        record = Value(record);
  static Insertable<SenderKey> custom({
    Expression<String>? groupId,
    Expression<String>? senderId,
    Expression<Uint8List>? record,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (senderId != null) 'sender_id': senderId,
      if (record != null) 'record': record,
    });
  }

  SenderKeysCompanion copyWith(
      {Value<String>? groupId,
      Value<String>? senderId,
      Value<Uint8List>? record}) {
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
  final String? _alias;
  SenderKeys(this._db, [this._alias]);
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

  final VerificationMeta _recordMeta = const VerificationMeta('record');
  late final GeneratedBlobColumn record = _constructRecord();
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

class RatchetSenderKey extends DataClass
    implements Insertable<RatchetSenderKey> {
  final String groupId;
  final String senderId;
  final String status;
  final String? messageId;
  final String createdAt;
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
    return RatchetSenderKey(
      groupId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}group_id'])!,
      senderId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}sender_id'])!,
      status:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}status'])!,
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at'])!,
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
          String? messageId,
          String? createdAt}) =>
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
  final Value<String> createdAt;
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
    required String createdAt,
  })   : groupId = Value(groupId),
        senderId = Value(senderId),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<RatchetSenderKey> custom({
    Expression<String>? groupId,
    Expression<String>? senderId,
    Expression<String>? status,
    Expression<String?>? messageId,
    Expression<String>? createdAt,
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
      Value<String>? createdAt}) {
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
      map['created_at'] = Variable<String>(createdAt.value);
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
  late final GeneratedTextColumn createdAt = _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return RatchetSenderKey.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  RatchetSenderKeys createAlias(String alias) {
    return RatchetSenderKeys(_db, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(group_id, sender_id)'];
  @override
  bool get dontWriteConstraints => true;
}

abstract class _$SignalDatabase extends GeneratedDatabase {
  _$SignalDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$SignalDatabase.connect(DatabaseConnection c) : super.connect(c);
  late final Identities identities = Identities(this);
  late final Index indexIdentitiesAddress = Index('index_identities_address',
      'CREATE UNIQUE INDEX IF NOT EXISTS index_identities_address ON identities (address);');
  late final Prekeys prekeys = Prekeys(this);
  late final Index indexPrekeysPrekeyId = Index('index_prekeys_prekey_id',
      'CREATE UNIQUE INDEX IF NOT EXISTS index_prekeys_prekey_id ON prekeys (prekey_id);');
  late final SignedPrekeys signedPrekeys = SignedPrekeys(this);
  late final Index indexSignedPrekeysPrekeyId = Index(
      'index_signed_prekeys_prekey_id',
      'CREATE UNIQUE INDEX IF NOT EXISTS index_signed_prekeys_prekey_id ON signed_prekeys (prekey_id);');
  late final Sessions sessions = Sessions(this);
  late final Index indexSessionsAddressDevice = Index(
      'index_sessions_address_device',
      'CREATE UNIQUE INDEX IF NOT EXISTS index_sessions_address_device ON sessions (address, device);');
  late final SenderKeys senderKeys = SenderKeys(this);
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
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        identities,
        indexIdentitiesAddress,
        prekeys,
        indexPrekeysPrekeyId,
        signedPrekeys,
        indexSignedPrekeysPrekeyId,
        sessions,
        indexSessionsAddressDevice,
        senderKeys,
        ratchetSenderKeys
      ];
}
