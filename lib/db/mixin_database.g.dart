// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixin_database.dart';

// ignore_for_file: type=lint
class Users extends Table with TableInfo<Users, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Users(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _identityNumberMeta =
      const VerificationMeta('identityNumber');
  late final GeneratedColumn<String> identityNumber = GeneratedColumn<String>(
      'identity_number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _relationshipMeta =
      const VerificationMeta('relationship');
  late final GeneratedColumnWithTypeConverter<UserRelationship?, String>
      relationship = GeneratedColumn<String>('relationship', aliasedName, true,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<UserRelationship?>(Users.$converterrelationship);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _isVerifiedMeta =
      const VerificationMeta('isVerified');
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
      'is_verified', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(Users.$convertercreatedAtn);
  static const VerificationMeta _muteUntilMeta =
      const VerificationMeta('muteUntil');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> muteUntil =
      GeneratedColumn<int>('mute_until', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(Users.$convertermuteUntiln);
  static const VerificationMeta _hasPinMeta = const VerificationMeta('hasPin');
  late final GeneratedColumn<int> hasPin = GeneratedColumn<int>(
      'has_pin', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _biographyMeta =
      const VerificationMeta('biography');
  late final GeneratedColumn<String> biography = GeneratedColumn<String>(
      'biography', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _isScamMeta = const VerificationMeta('isScam');
  late final GeneratedColumn<int> isScam = GeneratedColumn<int>(
      'is_scam', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _codeUrlMeta =
      const VerificationMeta('codeUrl');
  late final GeneratedColumn<String> codeUrl = GeneratedColumn<String>(
      'code_url', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _codeIdMeta = const VerificationMeta('codeId');
  late final GeneratedColumn<String> codeId = GeneratedColumn<String>(
      'code_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
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
        isScam,
        codeUrl,
        codeId
      ];
  @override
  String get aliasedName => _alias ?? 'users';
  @override
  String get actualTableName => 'users';
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
    if (data.containsKey('code_url')) {
      context.handle(_codeUrlMeta,
          codeUrl.isAcceptableOrUnknown(data['code_url']!, _codeUrlMeta));
    }
    if (data.containsKey('code_id')) {
      context.handle(_codeIdMeta,
          codeId.isAcceptableOrUnknown(data['code_id']!, _codeIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      identityNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}identity_number'])!,
      relationship: Users.$converterrelationship.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relationship'])),
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name']),
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      isVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_verified']),
      createdAt: Users.$convertercreatedAtn.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])),
      muteUntil: Users.$convertermuteUntiln.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mute_until'])),
      hasPin: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}has_pin']),
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id']),
      biography: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}biography']),
      isScam: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_scam']),
      codeUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code_url']),
      codeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code_id']),
    );
  }

  @override
  Users createAlias(String alias) {
    return Users(attachedDatabase, alias);
  }

  static TypeConverter<UserRelationship?, String?> $converterrelationship =
      const UserRelationshipConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $convertercreatedAtn =
      NullAwareTypeConverter.wrap($convertercreatedAt);
  static TypeConverter<DateTime, int> $convertermuteUntil =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $convertermuteUntiln =
      NullAwareTypeConverter.wrap($convertermuteUntil);
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(user_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class User extends DataClass implements Insertable<User> {
  final String userId;
  final String identityNumber;
  final UserRelationship? relationship;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final bool? isVerified;
  final DateTime? createdAt;
  final DateTime? muteUntil;
  final int? hasPin;
  final String? appId;
  final String? biography;
  final int? isScam;
  final String? codeUrl;
  final String? codeId;
  const User(
      {required this.userId,
      required this.identityNumber,
      this.relationship,
      this.fullName,
      this.avatarUrl,
      this.phone,
      this.isVerified,
      this.createdAt,
      this.muteUntil,
      this.hasPin,
      this.appId,
      this.biography,
      this.isScam,
      this.codeUrl,
      this.codeId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['identity_number'] = Variable<String>(identityNumber);
    if (!nullToAbsent || relationship != null) {
      final converter = Users.$converterrelationship;
      map['relationship'] = Variable<String>(converter.toSql(relationship));
    }
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || isVerified != null) {
      map['is_verified'] = Variable<bool>(isVerified);
    }
    if (!nullToAbsent || createdAt != null) {
      final converter = Users.$convertercreatedAtn;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || muteUntil != null) {
      final converter = Users.$convertermuteUntiln;
      map['mute_until'] = Variable<int>(converter.toSql(muteUntil));
    }
    if (!nullToAbsent || hasPin != null) {
      map['has_pin'] = Variable<int>(hasPin);
    }
    if (!nullToAbsent || appId != null) {
      map['app_id'] = Variable<String>(appId);
    }
    if (!nullToAbsent || biography != null) {
      map['biography'] = Variable<String>(biography);
    }
    if (!nullToAbsent || isScam != null) {
      map['is_scam'] = Variable<int>(isScam);
    }
    if (!nullToAbsent || codeUrl != null) {
      map['code_url'] = Variable<String>(codeUrl);
    }
    if (!nullToAbsent || codeId != null) {
      map['code_id'] = Variable<String>(codeId);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      userId: Value(userId),
      identityNumber: Value(identityNumber),
      relationship: relationship == null && nullToAbsent
          ? const Value.absent()
          : Value(relationship),
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
      codeUrl: codeUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(codeUrl),
      codeId:
          codeId == null && nullToAbsent ? const Value.absent() : Value(codeId),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      userId: serializer.fromJson<String>(json['user_id']),
      identityNumber: serializer.fromJson<String>(json['identity_number']),
      relationship:
          serializer.fromJson<UserRelationship?>(json['relationship']),
      fullName: serializer.fromJson<String?>(json['full_name']),
      avatarUrl: serializer.fromJson<String?>(json['avatar_url']),
      phone: serializer.fromJson<String?>(json['phone']),
      isVerified: serializer.fromJson<bool?>(json['is_verified']),
      createdAt: serializer.fromJson<DateTime?>(json['created_at']),
      muteUntil: serializer.fromJson<DateTime?>(json['mute_until']),
      hasPin: serializer.fromJson<int?>(json['has_pin']),
      appId: serializer.fromJson<String?>(json['app_id']),
      biography: serializer.fromJson<String?>(json['biography']),
      isScam: serializer.fromJson<int?>(json['is_scam']),
      codeUrl: serializer.fromJson<String?>(json['code_url']),
      codeId: serializer.fromJson<String?>(json['code_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'user_id': serializer.toJson<String>(userId),
      'identity_number': serializer.toJson<String>(identityNumber),
      'relationship': serializer.toJson<UserRelationship?>(relationship),
      'full_name': serializer.toJson<String?>(fullName),
      'avatar_url': serializer.toJson<String?>(avatarUrl),
      'phone': serializer.toJson<String?>(phone),
      'is_verified': serializer.toJson<bool?>(isVerified),
      'created_at': serializer.toJson<DateTime?>(createdAt),
      'mute_until': serializer.toJson<DateTime?>(muteUntil),
      'has_pin': serializer.toJson<int?>(hasPin),
      'app_id': serializer.toJson<String?>(appId),
      'biography': serializer.toJson<String?>(biography),
      'is_scam': serializer.toJson<int?>(isScam),
      'code_url': serializer.toJson<String?>(codeUrl),
      'code_id': serializer.toJson<String?>(codeId),
    };
  }

  User copyWith(
          {String? userId,
          String? identityNumber,
          Value<UserRelationship?> relationship = const Value.absent(),
          Value<String?> fullName = const Value.absent(),
          Value<String?> avatarUrl = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<bool?> isVerified = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> muteUntil = const Value.absent(),
          Value<int?> hasPin = const Value.absent(),
          Value<String?> appId = const Value.absent(),
          Value<String?> biography = const Value.absent(),
          Value<int?> isScam = const Value.absent(),
          Value<String?> codeUrl = const Value.absent(),
          Value<String?> codeId = const Value.absent()}) =>
      User(
        userId: userId ?? this.userId,
        identityNumber: identityNumber ?? this.identityNumber,
        relationship:
            relationship.present ? relationship.value : this.relationship,
        fullName: fullName.present ? fullName.value : this.fullName,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
        phone: phone.present ? phone.value : this.phone,
        isVerified: isVerified.present ? isVerified.value : this.isVerified,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        muteUntil: muteUntil.present ? muteUntil.value : this.muteUntil,
        hasPin: hasPin.present ? hasPin.value : this.hasPin,
        appId: appId.present ? appId.value : this.appId,
        biography: biography.present ? biography.value : this.biography,
        isScam: isScam.present ? isScam.value : this.isScam,
        codeUrl: codeUrl.present ? codeUrl.value : this.codeUrl,
        codeId: codeId.present ? codeId.value : this.codeId,
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
          ..write('isScam: $isScam, ')
          ..write('codeUrl: $codeUrl, ')
          ..write('codeId: $codeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
      isScam,
      codeUrl,
      codeId);
  @override
  bool operator ==(Object other) =>
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
          other.isScam == this.isScam &&
          other.codeUrl == this.codeUrl &&
          other.codeId == this.codeId);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> userId;
  final Value<String> identityNumber;
  final Value<UserRelationship?> relationship;
  final Value<String?> fullName;
  final Value<String?> avatarUrl;
  final Value<String?> phone;
  final Value<bool?> isVerified;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> muteUntil;
  final Value<int?> hasPin;
  final Value<String?> appId;
  final Value<String?> biography;
  final Value<int?> isScam;
  final Value<String?> codeUrl;
  final Value<String?> codeId;
  final Value<int> rowid;
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
    this.codeUrl = const Value.absent(),
    this.codeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String userId,
    required String identityNumber,
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
    this.codeUrl = const Value.absent(),
    this.codeId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        identityNumber = Value(identityNumber);
  static Insertable<User> custom({
    Expression<String>? userId,
    Expression<String>? identityNumber,
    Expression<String>? relationship,
    Expression<String>? fullName,
    Expression<String>? avatarUrl,
    Expression<String>? phone,
    Expression<bool>? isVerified,
    Expression<int>? createdAt,
    Expression<int>? muteUntil,
    Expression<int>? hasPin,
    Expression<String>? appId,
    Expression<String>? biography,
    Expression<int>? isScam,
    Expression<String>? codeUrl,
    Expression<String>? codeId,
    Expression<int>? rowid,
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
      if (codeUrl != null) 'code_url': codeUrl,
      if (codeId != null) 'code_id': codeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? userId,
      Value<String>? identityNumber,
      Value<UserRelationship?>? relationship,
      Value<String?>? fullName,
      Value<String?>? avatarUrl,
      Value<String?>? phone,
      Value<bool?>? isVerified,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? muteUntil,
      Value<int?>? hasPin,
      Value<String?>? appId,
      Value<String?>? biography,
      Value<int?>? isScam,
      Value<String?>? codeUrl,
      Value<String?>? codeId,
      Value<int>? rowid}) {
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
      codeUrl: codeUrl ?? this.codeUrl,
      codeId: codeId ?? this.codeId,
      rowid: rowid ?? this.rowid,
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
      final converter = Users.$converterrelationship;
      map['relationship'] =
          Variable<String>(converter.toSql(relationship.value));
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (createdAt.present) {
      final converter = Users.$convertercreatedAtn;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (muteUntil.present) {
      final converter = Users.$convertermuteUntiln;
      map['mute_until'] = Variable<int>(converter.toSql(muteUntil.value));
    }
    if (hasPin.present) {
      map['has_pin'] = Variable<int>(hasPin.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (biography.present) {
      map['biography'] = Variable<String>(biography.value);
    }
    if (isScam.present) {
      map['is_scam'] = Variable<int>(isScam.value);
    }
    if (codeUrl.present) {
      map['code_url'] = Variable<String>(codeUrl.value);
    }
    if (codeId.present) {
      map['code_id'] = Variable<String>(codeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('isScam: $isScam, ')
          ..write('codeUrl: $codeUrl, ')
          ..write('codeId: $codeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Conversations extends Table with TableInfo<Conversations, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Conversations(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  late final GeneratedColumnWithTypeConverter<ConversationCategory?, String>
      category = GeneratedColumn<String>('category', aliasedName, true,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<ConversationCategory?>(
              Conversations.$convertercategory);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _iconUrlMeta =
      const VerificationMeta('iconUrl');
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
      'icon_url', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _announcementMeta =
      const VerificationMeta('announcement');
  late final GeneratedColumn<String> announcement = GeneratedColumn<String>(
      'announcement', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _codeUrlMeta =
      const VerificationMeta('codeUrl');
  late final GeneratedColumn<String> codeUrl = GeneratedColumn<String>(
      'code_url', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _payTypeMeta =
      const VerificationMeta('payType');
  late final GeneratedColumn<String> payType = GeneratedColumn<String>(
      'pay_type', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(Conversations.$convertercreatedAt);
  static const VerificationMeta _pinTimeMeta =
      const VerificationMeta('pinTime');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> pinTime =
      GeneratedColumn<int>('pin_time', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(Conversations.$converterpinTimen);
  static const VerificationMeta _lastMessageIdMeta =
      const VerificationMeta('lastMessageId');
  late final GeneratedColumn<String> lastMessageId = GeneratedColumn<String>(
      'last_message_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _lastMessageCreatedAtMeta =
      const VerificationMeta('lastMessageCreatedAt');
  late final GeneratedColumnWithTypeConverter<DateTime?, int>
      lastMessageCreatedAt = GeneratedColumn<int>(
              'last_message_created_at', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(
              Conversations.$converterlastMessageCreatedAtn);
  static const VerificationMeta _lastReadMessageIdMeta =
      const VerificationMeta('lastReadMessageId');
  late final GeneratedColumn<String> lastReadMessageId =
      GeneratedColumn<String>('last_read_message_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: '');
  static const VerificationMeta _unseenMessageCountMeta =
      const VerificationMeta('unseenMessageCount');
  late final GeneratedColumn<int> unseenMessageCount = GeneratedColumn<int>(
      'unseen_message_count', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumnWithTypeConverter<ConversationStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<ConversationStatus>(Conversations.$converterstatus);
  static const VerificationMeta _draftMeta = const VerificationMeta('draft');
  late final GeneratedColumn<String> draft = GeneratedColumn<String>(
      'draft', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _muteUntilMeta =
      const VerificationMeta('muteUntil');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> muteUntil =
      GeneratedColumn<int>('mute_until', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(Conversations.$convertermuteUntiln);
  static const VerificationMeta _expireInMeta =
      const VerificationMeta('expireIn');
  late final GeneratedColumn<int> expireIn = GeneratedColumn<int>(
      'expire_in', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
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
        muteUntil,
        expireIn
      ];
  @override
  String get aliasedName => _alias ?? 'conversations';
  @override
  String get actualTableName => 'conversations';
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
    if (data.containsKey('expire_in')) {
      context.handle(_expireInMeta,
          expireIn.isAcceptableOrUnknown(data['expire_in']!, _expireInMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id']),
      category: Conversations.$convertercategory.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      iconUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_url']),
      announcement: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}announcement']),
      codeUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code_url']),
      payType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pay_type']),
      createdAt: Conversations.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      pinTime: Conversations.$converterpinTimen.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pin_time'])),
      lastMessageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_message_id']),
      lastMessageCreatedAt: Conversations.$converterlastMessageCreatedAtn
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.int,
              data['${effectivePrefix}last_message_created_at'])),
      lastReadMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_read_message_id']),
      unseenMessageCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}unseen_message_count']),
      status: Conversations.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      draft: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}draft']),
      muteUntil: Conversations.$convertermuteUntiln.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mute_until'])),
      expireIn: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expire_in']),
    );
  }

  @override
  Conversations createAlias(String alias) {
    return Conversations(attachedDatabase, alias);
  }

  static TypeConverter<ConversationCategory?, String?> $convertercategory =
      const ConversationCategoryTypeConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime, int> $converterpinTime =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $converterpinTimen =
      NullAwareTypeConverter.wrap($converterpinTime);
  static TypeConverter<DateTime, int> $converterlastMessageCreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $converterlastMessageCreatedAtn =
      NullAwareTypeConverter.wrap($converterlastMessageCreatedAt);
  static TypeConverter<ConversationStatus, int> $converterstatus =
      const ConversationStatusTypeConverter();
  static TypeConverter<DateTime, int> $convertermuteUntil =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $convertermuteUntiln =
      NullAwareTypeConverter.wrap($convertermuteUntil);
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(conversation_id)'];
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
  final int? expireIn;
  const Conversation(
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
      this.muteUntil,
      this.expireIn});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || category != null) {
      final converter = Conversations.$convertercategory;
      map['category'] = Variable<String>(converter.toSql(category));
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    if (!nullToAbsent || announcement != null) {
      map['announcement'] = Variable<String>(announcement);
    }
    if (!nullToAbsent || codeUrl != null) {
      map['code_url'] = Variable<String>(codeUrl);
    }
    if (!nullToAbsent || payType != null) {
      map['pay_type'] = Variable<String>(payType);
    }
    {
      final converter = Conversations.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || pinTime != null) {
      final converter = Conversations.$converterpinTimen;
      map['pin_time'] = Variable<int>(converter.toSql(pinTime));
    }
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String>(lastMessageId);
    }
    if (!nullToAbsent || lastMessageCreatedAt != null) {
      final converter = Conversations.$converterlastMessageCreatedAtn;
      map['last_message_created_at'] =
          Variable<int>(converter.toSql(lastMessageCreatedAt));
    }
    if (!nullToAbsent || lastReadMessageId != null) {
      map['last_read_message_id'] = Variable<String>(lastReadMessageId);
    }
    if (!nullToAbsent || unseenMessageCount != null) {
      map['unseen_message_count'] = Variable<int>(unseenMessageCount);
    }
    {
      final converter = Conversations.$converterstatus;
      map['status'] = Variable<int>(converter.toSql(status));
    }
    if (!nullToAbsent || draft != null) {
      map['draft'] = Variable<String>(draft);
    }
    if (!nullToAbsent || muteUntil != null) {
      final converter = Conversations.$convertermuteUntiln;
      map['mute_until'] = Variable<int>(converter.toSql(muteUntil));
    }
    if (!nullToAbsent || expireIn != null) {
      map['expire_in'] = Variable<int>(expireIn);
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
      expireIn: expireIn == null && nullToAbsent
          ? const Value.absent()
          : Value(expireIn),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
      expireIn: serializer.fromJson<int?>(json['expire_in']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
      'expire_in': serializer.toJson<int?>(expireIn),
    };
  }

  Conversation copyWith(
          {String? conversationId,
          Value<String?> ownerId = const Value.absent(),
          Value<ConversationCategory?> category = const Value.absent(),
          Value<String?> name = const Value.absent(),
          Value<String?> iconUrl = const Value.absent(),
          Value<String?> announcement = const Value.absent(),
          Value<String?> codeUrl = const Value.absent(),
          Value<String?> payType = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> pinTime = const Value.absent(),
          Value<String?> lastMessageId = const Value.absent(),
          Value<DateTime?> lastMessageCreatedAt = const Value.absent(),
          Value<String?> lastReadMessageId = const Value.absent(),
          Value<int?> unseenMessageCount = const Value.absent(),
          ConversationStatus? status,
          Value<String?> draft = const Value.absent(),
          Value<DateTime?> muteUntil = const Value.absent(),
          Value<int?> expireIn = const Value.absent()}) =>
      Conversation(
        conversationId: conversationId ?? this.conversationId,
        ownerId: ownerId.present ? ownerId.value : this.ownerId,
        category: category.present ? category.value : this.category,
        name: name.present ? name.value : this.name,
        iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
        announcement:
            announcement.present ? announcement.value : this.announcement,
        codeUrl: codeUrl.present ? codeUrl.value : this.codeUrl,
        payType: payType.present ? payType.value : this.payType,
        createdAt: createdAt ?? this.createdAt,
        pinTime: pinTime.present ? pinTime.value : this.pinTime,
        lastMessageId:
            lastMessageId.present ? lastMessageId.value : this.lastMessageId,
        lastMessageCreatedAt: lastMessageCreatedAt.present
            ? lastMessageCreatedAt.value
            : this.lastMessageCreatedAt,
        lastReadMessageId: lastReadMessageId.present
            ? lastReadMessageId.value
            : this.lastReadMessageId,
        unseenMessageCount: unseenMessageCount.present
            ? unseenMessageCount.value
            : this.unseenMessageCount,
        status: status ?? this.status,
        draft: draft.present ? draft.value : this.draft,
        muteUntil: muteUntil.present ? muteUntil.value : this.muteUntil,
        expireIn: expireIn.present ? expireIn.value : this.expireIn,
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
          ..write('muteUntil: $muteUntil, ')
          ..write('expireIn: $expireIn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
      muteUntil,
      expireIn);
  @override
  bool operator ==(Object other) =>
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
          other.muteUntil == this.muteUntil &&
          other.expireIn == this.expireIn);
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
  final Value<int?> expireIn;
  final Value<int> rowid;
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
    this.expireIn = const Value.absent(),
    this.rowid = const Value.absent(),
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
    this.expireIn = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : conversationId = Value(conversationId),
        createdAt = Value(createdAt),
        status = Value(status);
  static Insertable<Conversation> custom({
    Expression<String>? conversationId,
    Expression<String>? ownerId,
    Expression<String>? category,
    Expression<String>? name,
    Expression<String>? iconUrl,
    Expression<String>? announcement,
    Expression<String>? codeUrl,
    Expression<String>? payType,
    Expression<int>? createdAt,
    Expression<int>? pinTime,
    Expression<String>? lastMessageId,
    Expression<int>? lastMessageCreatedAt,
    Expression<String>? lastReadMessageId,
    Expression<int>? unseenMessageCount,
    Expression<int>? status,
    Expression<String>? draft,
    Expression<int>? muteUntil,
    Expression<int>? expireIn,
    Expression<int>? rowid,
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
      if (expireIn != null) 'expire_in': expireIn,
      if (rowid != null) 'rowid': rowid,
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
      Value<DateTime?>? muteUntil,
      Value<int?>? expireIn,
      Value<int>? rowid}) {
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
      expireIn: expireIn ?? this.expireIn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (category.present) {
      final converter = Conversations.$convertercategory;
      map['category'] = Variable<String>(converter.toSql(category.value));
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (announcement.present) {
      map['announcement'] = Variable<String>(announcement.value);
    }
    if (codeUrl.present) {
      map['code_url'] = Variable<String>(codeUrl.value);
    }
    if (payType.present) {
      map['pay_type'] = Variable<String>(payType.value);
    }
    if (createdAt.present) {
      final converter = Conversations.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (pinTime.present) {
      final converter = Conversations.$converterpinTimen;
      map['pin_time'] = Variable<int>(converter.toSql(pinTime.value));
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (lastMessageCreatedAt.present) {
      final converter = Conversations.$converterlastMessageCreatedAtn;
      map['last_message_created_at'] =
          Variable<int>(converter.toSql(lastMessageCreatedAt.value));
    }
    if (lastReadMessageId.present) {
      map['last_read_message_id'] = Variable<String>(lastReadMessageId.value);
    }
    if (unseenMessageCount.present) {
      map['unseen_message_count'] = Variable<int>(unseenMessageCount.value);
    }
    if (status.present) {
      final converter = Conversations.$converterstatus;
      map['status'] = Variable<int>(converter.toSql(status.value));
    }
    if (draft.present) {
      map['draft'] = Variable<String>(draft.value);
    }
    if (muteUntil.present) {
      final converter = Conversations.$convertermuteUntiln;
      map['mute_until'] = Variable<int>(converter.toSql(muteUntil.value));
    }
    if (expireIn.present) {
      map['expire_in'] = Variable<int>(expireIn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('muteUntil: $muteUntil, ')
          ..write('expireIn: $expireIn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Messages extends Table with TableInfo<Messages, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Messages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaUrlMeta =
      const VerificationMeta('mediaUrl');
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
      'media_url', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaMimeTypeMeta =
      const VerificationMeta('mediaMimeType');
  late final GeneratedColumn<String> mediaMimeType = GeneratedColumn<String>(
      'media_mime_type', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaSizeMeta =
      const VerificationMeta('mediaSize');
  late final GeneratedColumn<int> mediaSize = GeneratedColumn<int>(
      'media_size', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaDurationMeta =
      const VerificationMeta('mediaDuration');
  late final GeneratedColumn<String> mediaDuration = GeneratedColumn<String>(
      'media_duration', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaWidthMeta =
      const VerificationMeta('mediaWidth');
  late final GeneratedColumn<int> mediaWidth = GeneratedColumn<int>(
      'media_width', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaHeightMeta =
      const VerificationMeta('mediaHeight');
  late final GeneratedColumn<int> mediaHeight = GeneratedColumn<int>(
      'media_height', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaHashMeta =
      const VerificationMeta('mediaHash');
  late final GeneratedColumn<String> mediaHash = GeneratedColumn<String>(
      'media_hash', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _thumbImageMeta =
      const VerificationMeta('thumbImage');
  late final GeneratedColumn<String> thumbImage = GeneratedColumn<String>(
      'thumb_image', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaKeyMeta =
      const VerificationMeta('mediaKey');
  late final GeneratedColumn<String> mediaKey = GeneratedColumn<String>(
      'media_key', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaDigestMeta =
      const VerificationMeta('mediaDigest');
  late final GeneratedColumn<String> mediaDigest = GeneratedColumn<String>(
      'media_digest', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaStatusMeta =
      const VerificationMeta('mediaStatus');
  late final GeneratedColumnWithTypeConverter<MediaStatus?, String>
      mediaStatus = GeneratedColumn<String>('media_status', aliasedName, true,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<MediaStatus?>(Messages.$convertermediaStatus);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumnWithTypeConverter<MessageStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<MessageStatus>(Messages.$converterstatus);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(Messages.$convertercreatedAt);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _participantIdMeta =
      const VerificationMeta('participantId');
  late final GeneratedColumn<String> participantId = GeneratedColumn<String>(
      'participant_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _snapshotIdMeta =
      const VerificationMeta('snapshotId');
  late final GeneratedColumn<String> snapshotId = GeneratedColumn<String>(
      'snapshot_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _hyperlinkMeta =
      const VerificationMeta('hyperlink');
  late final GeneratedColumn<String> hyperlink = GeneratedColumn<String>(
      'hyperlink', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _stickerIdMeta =
      const VerificationMeta('stickerId');
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
      'sticker_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _sharedUserIdMeta =
      const VerificationMeta('sharedUserId');
  late final GeneratedColumn<String> sharedUserId = GeneratedColumn<String>(
      'shared_user_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaWaveformMeta =
      const VerificationMeta('mediaWaveform');
  late final GeneratedColumn<String> mediaWaveform = GeneratedColumn<String>(
      'media_waveform', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _quoteMessageIdMeta =
      const VerificationMeta('quoteMessageId');
  late final GeneratedColumn<String> quoteMessageId = GeneratedColumn<String>(
      'quote_message_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _quoteContentMeta =
      const VerificationMeta('quoteContent');
  late final GeneratedColumn<String> quoteContent = GeneratedColumn<String>(
      'quote_content', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _thumbUrlMeta =
      const VerificationMeta('thumbUrl');
  late final GeneratedColumn<String> thumbUrl = GeneratedColumn<String>(
      'thumb_url', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
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
        thumbUrl,
        caption
      ];
  @override
  String get aliasedName => _alias ?? 'messages';
  @override
  String get actualTableName => 'messages';
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
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
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
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    }
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
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      mediaUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_url']),
      mediaMimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_mime_type']),
      mediaSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_size']),
      mediaDuration: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_duration']),
      mediaWidth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_width']),
      mediaHeight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_height']),
      mediaHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_hash']),
      thumbImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumb_image']),
      mediaKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_key']),
      mediaDigest: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_digest']),
      mediaStatus: Messages.$convertermediaStatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_status'])),
      status: Messages.$converterstatus.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      createdAt: Messages.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action']),
      participantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}participant_id']),
      snapshotId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot_id']),
      hyperlink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hyperlink']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id']),
      stickerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sticker_id']),
      sharedUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shared_user_id']),
      mediaWaveform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_waveform']),
      quoteMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}quote_message_id']),
      quoteContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quote_content']),
      thumbUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumb_url']),
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption']),
    );
  }

  @override
  Messages createAlias(String alias) {
    return Messages(attachedDatabase, alias);
  }

  static TypeConverter<MediaStatus?, String?> $convertermediaStatus =
      const MediaStatusTypeConverter();
  static TypeConverter<MessageStatus, String> $converterstatus =
      const MessageStatusTypeConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const [
        'PRIMARY KEY(message_id)',
        'FOREIGN KEY(conversation_id)REFERENCES conversations(conversation_id)ON UPDATE NO ACTION ON DELETE CASCADE'
      ];
  @override
  bool get dontWriteConstraints => true;
}

class Message extends DataClass implements Insertable<Message> {
  final String messageId;
  final String conversationId;
  final String userId;
  final String category;
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
  final String? action;
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
  final String? caption;
  const Message(
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
      this.thumbUrl,
      this.caption});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['user_id'] = Variable<String>(userId);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || mediaMimeType != null) {
      map['media_mime_type'] = Variable<String>(mediaMimeType);
    }
    if (!nullToAbsent || mediaSize != null) {
      map['media_size'] = Variable<int>(mediaSize);
    }
    if (!nullToAbsent || mediaDuration != null) {
      map['media_duration'] = Variable<String>(mediaDuration);
    }
    if (!nullToAbsent || mediaWidth != null) {
      map['media_width'] = Variable<int>(mediaWidth);
    }
    if (!nullToAbsent || mediaHeight != null) {
      map['media_height'] = Variable<int>(mediaHeight);
    }
    if (!nullToAbsent || mediaHash != null) {
      map['media_hash'] = Variable<String>(mediaHash);
    }
    if (!nullToAbsent || thumbImage != null) {
      map['thumb_image'] = Variable<String>(thumbImage);
    }
    if (!nullToAbsent || mediaKey != null) {
      map['media_key'] = Variable<String>(mediaKey);
    }
    if (!nullToAbsent || mediaDigest != null) {
      map['media_digest'] = Variable<String>(mediaDigest);
    }
    if (!nullToAbsent || mediaStatus != null) {
      final converter = Messages.$convertermediaStatus;
      map['media_status'] = Variable<String>(converter.toSql(mediaStatus));
    }
    {
      final converter = Messages.$converterstatus;
      map['status'] = Variable<String>(converter.toSql(status));
    }
    {
      final converter = Messages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || action != null) {
      map['action'] = Variable<String>(action);
    }
    if (!nullToAbsent || participantId != null) {
      map['participant_id'] = Variable<String>(participantId);
    }
    if (!nullToAbsent || snapshotId != null) {
      map['snapshot_id'] = Variable<String>(snapshotId);
    }
    if (!nullToAbsent || hyperlink != null) {
      map['hyperlink'] = Variable<String>(hyperlink);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || stickerId != null) {
      map['sticker_id'] = Variable<String>(stickerId);
    }
    if (!nullToAbsent || sharedUserId != null) {
      map['shared_user_id'] = Variable<String>(sharedUserId);
    }
    if (!nullToAbsent || mediaWaveform != null) {
      map['media_waveform'] = Variable<String>(mediaWaveform);
    }
    if (!nullToAbsent || quoteMessageId != null) {
      map['quote_message_id'] = Variable<String>(quoteMessageId);
    }
    if (!nullToAbsent || quoteContent != null) {
      map['quote_content'] = Variable<String>(quoteContent);
    }
    if (!nullToAbsent || thumbUrl != null) {
      map['thumb_url'] = Variable<String>(thumbUrl);
    }
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
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
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      messageId: serializer.fromJson<String>(json['message_id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      category: serializer.fromJson<String>(json['category']),
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
      action: serializer.fromJson<String?>(json['action']),
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
      caption: serializer.fromJson<String?>(json['caption']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'conversation_id': serializer.toJson<String>(conversationId),
      'user_id': serializer.toJson<String>(userId),
      'category': serializer.toJson<String>(category),
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
      'action': serializer.toJson<String?>(action),
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
      'caption': serializer.toJson<String?>(caption),
    };
  }

  Message copyWith(
          {String? messageId,
          String? conversationId,
          String? userId,
          String? category,
          Value<String?> content = const Value.absent(),
          Value<String?> mediaUrl = const Value.absent(),
          Value<String?> mediaMimeType = const Value.absent(),
          Value<int?> mediaSize = const Value.absent(),
          Value<String?> mediaDuration = const Value.absent(),
          Value<int?> mediaWidth = const Value.absent(),
          Value<int?> mediaHeight = const Value.absent(),
          Value<String?> mediaHash = const Value.absent(),
          Value<String?> thumbImage = const Value.absent(),
          Value<String?> mediaKey = const Value.absent(),
          Value<String?> mediaDigest = const Value.absent(),
          Value<MediaStatus?> mediaStatus = const Value.absent(),
          MessageStatus? status,
          DateTime? createdAt,
          Value<String?> action = const Value.absent(),
          Value<String?> participantId = const Value.absent(),
          Value<String?> snapshotId = const Value.absent(),
          Value<String?> hyperlink = const Value.absent(),
          Value<String?> name = const Value.absent(),
          Value<String?> albumId = const Value.absent(),
          Value<String?> stickerId = const Value.absent(),
          Value<String?> sharedUserId = const Value.absent(),
          Value<String?> mediaWaveform = const Value.absent(),
          Value<String?> quoteMessageId = const Value.absent(),
          Value<String?> quoteContent = const Value.absent(),
          Value<String?> thumbUrl = const Value.absent(),
          Value<String?> caption = const Value.absent()}) =>
      Message(
        messageId: messageId ?? this.messageId,
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        category: category ?? this.category,
        content: content.present ? content.value : this.content,
        mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
        mediaMimeType:
            mediaMimeType.present ? mediaMimeType.value : this.mediaMimeType,
        mediaSize: mediaSize.present ? mediaSize.value : this.mediaSize,
        mediaDuration:
            mediaDuration.present ? mediaDuration.value : this.mediaDuration,
        mediaWidth: mediaWidth.present ? mediaWidth.value : this.mediaWidth,
        mediaHeight: mediaHeight.present ? mediaHeight.value : this.mediaHeight,
        mediaHash: mediaHash.present ? mediaHash.value : this.mediaHash,
        thumbImage: thumbImage.present ? thumbImage.value : this.thumbImage,
        mediaKey: mediaKey.present ? mediaKey.value : this.mediaKey,
        mediaDigest: mediaDigest.present ? mediaDigest.value : this.mediaDigest,
        mediaStatus: mediaStatus.present ? mediaStatus.value : this.mediaStatus,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        action: action.present ? action.value : this.action,
        participantId:
            participantId.present ? participantId.value : this.participantId,
        snapshotId: snapshotId.present ? snapshotId.value : this.snapshotId,
        hyperlink: hyperlink.present ? hyperlink.value : this.hyperlink,
        name: name.present ? name.value : this.name,
        albumId: albumId.present ? albumId.value : this.albumId,
        stickerId: stickerId.present ? stickerId.value : this.stickerId,
        sharedUserId:
            sharedUserId.present ? sharedUserId.value : this.sharedUserId,
        mediaWaveform:
            mediaWaveform.present ? mediaWaveform.value : this.mediaWaveform,
        quoteMessageId:
            quoteMessageId.present ? quoteMessageId.value : this.quoteMessageId,
        quoteContent:
            quoteContent.present ? quoteContent.value : this.quoteContent,
        thumbUrl: thumbUrl.present ? thumbUrl.value : this.thumbUrl,
        caption: caption.present ? caption.value : this.caption,
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
          ..write('thumbUrl: $thumbUrl, ')
          ..write('caption: $caption')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
        thumbUrl,
        caption
      ]);
  @override
  bool operator ==(Object other) =>
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
          other.thumbUrl == this.thumbUrl &&
          other.caption == this.caption);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> messageId;
  final Value<String> conversationId;
  final Value<String> userId;
  final Value<String> category;
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
  final Value<String?> action;
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
  final Value<String?> caption;
  final Value<int> rowid;
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
    this.caption = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String messageId,
    required String conversationId,
    required String userId,
    required String category,
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
    this.caption = const Value.absent(),
    this.rowid = const Value.absent(),
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
    Expression<String>? category,
    Expression<String>? content,
    Expression<String>? mediaUrl,
    Expression<String>? mediaMimeType,
    Expression<int>? mediaSize,
    Expression<String>? mediaDuration,
    Expression<int>? mediaWidth,
    Expression<int>? mediaHeight,
    Expression<String>? mediaHash,
    Expression<String>? thumbImage,
    Expression<String>? mediaKey,
    Expression<String>? mediaDigest,
    Expression<String>? mediaStatus,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<String>? action,
    Expression<String>? participantId,
    Expression<String>? snapshotId,
    Expression<String>? hyperlink,
    Expression<String>? name,
    Expression<String>? albumId,
    Expression<String>? stickerId,
    Expression<String>? sharedUserId,
    Expression<String>? mediaWaveform,
    Expression<String>? quoteMessageId,
    Expression<String>? quoteContent,
    Expression<String>? thumbUrl,
    Expression<String>? caption,
    Expression<int>? rowid,
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
      if (caption != null) 'caption': caption,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? conversationId,
      Value<String>? userId,
      Value<String>? category,
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
      Value<String?>? action,
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
      Value<String?>? thumbUrl,
      Value<String?>? caption,
      Value<int>? rowid}) {
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
      caption: caption ?? this.caption,
      rowid: rowid ?? this.rowid,
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
      map['category'] = Variable<String>(category.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (mediaMimeType.present) {
      map['media_mime_type'] = Variable<String>(mediaMimeType.value);
    }
    if (mediaSize.present) {
      map['media_size'] = Variable<int>(mediaSize.value);
    }
    if (mediaDuration.present) {
      map['media_duration'] = Variable<String>(mediaDuration.value);
    }
    if (mediaWidth.present) {
      map['media_width'] = Variable<int>(mediaWidth.value);
    }
    if (mediaHeight.present) {
      map['media_height'] = Variable<int>(mediaHeight.value);
    }
    if (mediaHash.present) {
      map['media_hash'] = Variable<String>(mediaHash.value);
    }
    if (thumbImage.present) {
      map['thumb_image'] = Variable<String>(thumbImage.value);
    }
    if (mediaKey.present) {
      map['media_key'] = Variable<String>(mediaKey.value);
    }
    if (mediaDigest.present) {
      map['media_digest'] = Variable<String>(mediaDigest.value);
    }
    if (mediaStatus.present) {
      final converter = Messages.$convertermediaStatus;
      map['media_status'] =
          Variable<String>(converter.toSql(mediaStatus.value));
    }
    if (status.present) {
      final converter = Messages.$converterstatus;
      map['status'] = Variable<String>(converter.toSql(status.value));
    }
    if (createdAt.present) {
      final converter = Messages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (participantId.present) {
      map['participant_id'] = Variable<String>(participantId.value);
    }
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<String>(snapshotId.value);
    }
    if (hyperlink.present) {
      map['hyperlink'] = Variable<String>(hyperlink.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (sharedUserId.present) {
      map['shared_user_id'] = Variable<String>(sharedUserId.value);
    }
    if (mediaWaveform.present) {
      map['media_waveform'] = Variable<String>(mediaWaveform.value);
    }
    if (quoteMessageId.present) {
      map['quote_message_id'] = Variable<String>(quoteMessageId.value);
    }
    if (quoteContent.present) {
      map['quote_content'] = Variable<String>(quoteContent.value);
    }
    if (thumbUrl.present) {
      map['thumb_url'] = Variable<String>(thumbUrl.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('thumbUrl: $thumbUrl, ')
          ..write('caption: $caption, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Participants extends Table with TableInfo<Participants, Participant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Participants(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedColumnWithTypeConverter<ParticipantRole?, String> role =
      GeneratedColumn<String>('role', aliasedName, true,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<ParticipantRole?>(Participants.$converterrole);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(Participants.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns =>
      [conversationId, userId, role, createdAt];
  @override
  String get aliasedName => _alias ?? 'participants';
  @override
  String get actualTableName => 'participants';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Participant(
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      role: Participants.$converterrole.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])),
      createdAt: Participants.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
    );
  }

  @override
  Participants createAlias(String alias) {
    return Participants(attachedDatabase, alias);
  }

  static TypeConverter<ParticipantRole?, String?> $converterrole =
      const ParticipantRoleConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const [
        'PRIMARY KEY(conversation_id, user_id)',
        'FOREIGN KEY(conversation_id)REFERENCES conversations(conversation_id)ON UPDATE NO ACTION ON DELETE CASCADE'
      ];
  @override
  bool get dontWriteConstraints => true;
}

class Participant extends DataClass implements Insertable<Participant> {
  final String conversationId;
  final String userId;
  final ParticipantRole? role;
  final DateTime createdAt;
  const Participant(
      {required this.conversationId,
      required this.userId,
      this.role,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || role != null) {
      final converter = Participants.$converterrole;
      map['role'] = Variable<String>(converter.toSql(role));
    }
    {
      final converter = Participants.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Participant(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      role: serializer.fromJson<ParticipantRole?>(json['role']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
          Value<ParticipantRole?> role = const Value.absent(),
          DateTime? createdAt}) =>
      Participant(
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        role: role.present ? role.value : this.role,
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
  int get hashCode => Object.hash(conversationId, userId, role, createdAt);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
  const ParticipantsCompanion({
    this.conversationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParticipantsCompanion.insert({
    required String conversationId,
    required String userId,
    this.role = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : conversationId = Value(conversationId),
        userId = Value(userId),
        createdAt = Value(createdAt);
  static Insertable<Participant> custom({
    Expression<String>? conversationId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParticipantsCompanion copyWith(
      {Value<String>? conversationId,
      Value<String>? userId,
      Value<ParticipantRole?>? role,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ParticipantsCompanion(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
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
      final converter = Participants.$converterrole;
      map['role'] = Variable<String>(converter.toSql(role.value));
    }
    if (createdAt.present) {
      final converter = Participants.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParticipantsCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CircleConversations extends Table
    with TableInfo<CircleConversations, CircleConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CircleConversations(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _circleIdMeta =
      const VerificationMeta('circleId');
  late final GeneratedColumn<String> circleId = GeneratedColumn<String>(
      'circle_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(CircleConversations.$convertercreatedAt);
  static const VerificationMeta _pinTimeMeta =
      const VerificationMeta('pinTime');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> pinTime =
      GeneratedColumn<int>('pin_time', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(CircleConversations.$converterpinTimen);
  @override
  List<GeneratedColumn> get $columns =>
      [conversationId, circleId, userId, createdAt, pinTime];
  @override
  String get aliasedName => _alias ?? 'circle_conversations';
  @override
  String get actualTableName => 'circle_conversations';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CircleConversation(
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      circleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}circle_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      createdAt: CircleConversations.$convertercreatedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      pinTime: CircleConversations.$converterpinTimen.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pin_time'])),
    );
  }

  @override
  CircleConversations createAlias(String alias) {
    return CircleConversations(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime, int> $converterpinTime =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $converterpinTimen =
      NullAwareTypeConverter.wrap($converterpinTime);
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(conversation_id, circle_id)'];
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
  const CircleConversation(
      {required this.conversationId,
      required this.circleId,
      this.userId,
      required this.createdAt,
      this.pinTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['circle_id'] = Variable<String>(circleId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    {
      final converter = CircleConversations.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || pinTime != null) {
      final converter = CircleConversations.$converterpinTimen;
      map['pin_time'] = Variable<int>(converter.toSql(pinTime));
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
          Value<String?> userId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> pinTime = const Value.absent()}) =>
      CircleConversation(
        conversationId: conversationId ?? this.conversationId,
        circleId: circleId ?? this.circleId,
        userId: userId.present ? userId.value : this.userId,
        createdAt: createdAt ?? this.createdAt,
        pinTime: pinTime.present ? pinTime.value : this.pinTime,
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
  int get hashCode =>
      Object.hash(conversationId, circleId, userId, createdAt, pinTime);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
  const CircleConversationsCompanion({
    this.conversationId = const Value.absent(),
    this.circleId = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pinTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CircleConversationsCompanion.insert({
    required String conversationId,
    required String circleId,
    this.userId = const Value.absent(),
    required DateTime createdAt,
    this.pinTime = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : conversationId = Value(conversationId),
        circleId = Value(circleId),
        createdAt = Value(createdAt);
  static Insertable<CircleConversation> custom({
    Expression<String>? conversationId,
    Expression<String>? circleId,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<int>? pinTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (circleId != null) 'circle_id': circleId,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (pinTime != null) 'pin_time': pinTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CircleConversationsCompanion copyWith(
      {Value<String>? conversationId,
      Value<String>? circleId,
      Value<String?>? userId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? pinTime,
      Value<int>? rowid}) {
    return CircleConversationsCompanion(
      conversationId: conversationId ?? this.conversationId,
      circleId: circleId ?? this.circleId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      pinTime: pinTime ?? this.pinTime,
      rowid: rowid ?? this.rowid,
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
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      final converter = CircleConversations.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (pinTime.present) {
      final converter = CircleConversations.$converterpinTimen;
      map['pin_time'] = Variable<int>(converter.toSql(pinTime.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('pinTime: $pinTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ParticipantSession extends Table
    with TableInfo<ParticipantSession, ParticipantSessionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ParticipantSession(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _sentToServerMeta =
      const VerificationMeta('sentToServer');
  late final GeneratedColumn<int> sentToServer = GeneratedColumn<int>(
      'sent_to_server', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(ParticipantSession.$convertercreatedAtn);
  static const VerificationMeta _publicKeyMeta =
      const VerificationMeta('publicKey');
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
      'public_key', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [conversationId, userId, sessionId, sentToServer, createdAt, publicKey];
  @override
  String get aliasedName => _alias ?? 'participant_session';
  @override
  String get actualTableName => 'participant_session';
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
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, userId, sessionId};
  @override
  ParticipantSessionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParticipantSessionData(
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      sentToServer: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sent_to_server']),
      createdAt: ParticipantSession.$convertercreatedAtn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}created_at'])),
      publicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}public_key']),
    );
  }

  @override
  ParticipantSession createAlias(String alias) {
    return ParticipantSession(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $convertercreatedAtn =
      NullAwareTypeConverter.wrap($convertercreatedAt);
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(conversation_id, user_id, session_id)'];
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
  final String? publicKey;
  const ParticipantSessionData(
      {required this.conversationId,
      required this.userId,
      required this.sessionId,
      this.sentToServer,
      this.createdAt,
      this.publicKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['user_id'] = Variable<String>(userId);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || sentToServer != null) {
      map['sent_to_server'] = Variable<int>(sentToServer);
    }
    if (!nullToAbsent || createdAt != null) {
      final converter = ParticipantSession.$convertercreatedAtn;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String>(publicKey);
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
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
    );
  }

  factory ParticipantSessionData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParticipantSessionData(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      sentToServer: serializer.fromJson<int?>(json['sent_to_server']),
      createdAt: serializer.fromJson<DateTime?>(json['created_at']),
      publicKey: serializer.fromJson<String?>(json['public_key']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversation_id': serializer.toJson<String>(conversationId),
      'user_id': serializer.toJson<String>(userId),
      'session_id': serializer.toJson<String>(sessionId),
      'sent_to_server': serializer.toJson<int?>(sentToServer),
      'created_at': serializer.toJson<DateTime?>(createdAt),
      'public_key': serializer.toJson<String?>(publicKey),
    };
  }

  ParticipantSessionData copyWith(
          {String? conversationId,
          String? userId,
          String? sessionId,
          Value<int?> sentToServer = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          Value<String?> publicKey = const Value.absent()}) =>
      ParticipantSessionData(
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        sessionId: sessionId ?? this.sessionId,
        sentToServer:
            sentToServer.present ? sentToServer.value : this.sentToServer,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        publicKey: publicKey.present ? publicKey.value : this.publicKey,
      );
  @override
  String toString() {
    return (StringBuffer('ParticipantSessionData(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('sentToServer: $sentToServer, ')
          ..write('createdAt: $createdAt, ')
          ..write('publicKey: $publicKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      conversationId, userId, sessionId, sentToServer, createdAt, publicKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParticipantSessionData &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.sentToServer == this.sentToServer &&
          other.createdAt == this.createdAt &&
          other.publicKey == this.publicKey);
}

class ParticipantSessionCompanion
    extends UpdateCompanion<ParticipantSessionData> {
  final Value<String> conversationId;
  final Value<String> userId;
  final Value<String> sessionId;
  final Value<int?> sentToServer;
  final Value<DateTime?> createdAt;
  final Value<String?> publicKey;
  final Value<int> rowid;
  const ParticipantSessionCompanion({
    this.conversationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sentToServer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParticipantSessionCompanion.insert({
    required String conversationId,
    required String userId,
    required String sessionId,
    this.sentToServer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : conversationId = Value(conversationId),
        userId = Value(userId),
        sessionId = Value(sessionId);
  static Insertable<ParticipantSessionData> custom({
    Expression<String>? conversationId,
    Expression<String>? userId,
    Expression<String>? sessionId,
    Expression<int>? sentToServer,
    Expression<int>? createdAt,
    Expression<String>? publicKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (sentToServer != null) 'sent_to_server': sentToServer,
      if (createdAt != null) 'created_at': createdAt,
      if (publicKey != null) 'public_key': publicKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParticipantSessionCompanion copyWith(
      {Value<String>? conversationId,
      Value<String>? userId,
      Value<String>? sessionId,
      Value<int?>? sentToServer,
      Value<DateTime?>? createdAt,
      Value<String?>? publicKey,
      Value<int>? rowid}) {
    return ParticipantSessionCompanion(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      sentToServer: sentToServer ?? this.sentToServer,
      createdAt: createdAt ?? this.createdAt,
      publicKey: publicKey ?? this.publicKey,
      rowid: rowid ?? this.rowid,
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
    if (createdAt.present) {
      final converter = ParticipantSession.$convertercreatedAtn;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('publicKey: $publicKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Snapshots extends Table with TableInfo<Snapshots, Snapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Snapshots(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _snapshotIdMeta =
      const VerificationMeta('snapshotId');
  late final GeneratedColumn<String> snapshotId = GeneratedColumn<String>(
      'snapshot_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _traceIdMeta =
      const VerificationMeta('traceId');
  late final GeneratedColumn<String> traceId = GeneratedColumn<String>(
      'trace_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
      'amount', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(Snapshots.$convertercreatedAt);
  static const VerificationMeta _opponentIdMeta =
      const VerificationMeta('opponentId');
  late final GeneratedColumn<String> opponentId = GeneratedColumn<String>(
      'opponent_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _transactionHashMeta =
      const VerificationMeta('transactionHash');
  late final GeneratedColumn<String> transactionHash = GeneratedColumn<String>(
      'transaction_hash', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
      'sender', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _receiverMeta =
      const VerificationMeta('receiver');
  late final GeneratedColumn<String> receiver = GeneratedColumn<String>(
      'receiver', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _confirmationsMeta =
      const VerificationMeta('confirmations');
  late final GeneratedColumn<int> confirmations = GeneratedColumn<int>(
      'confirmations', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _snapshotHashMeta =
      const VerificationMeta('snapshotHash');
  late final GeneratedColumn<String> snapshotHash = GeneratedColumn<String>(
      'snapshot_hash', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _openingBalanceMeta =
      const VerificationMeta('openingBalance');
  late final GeneratedColumn<String> openingBalance = GeneratedColumn<String>(
      'opening_balance', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _closingBalanceMeta =
      const VerificationMeta('closingBalance');
  late final GeneratedColumn<String> closingBalance = GeneratedColumn<String>(
      'closing_balance', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [
        snapshotId,
        traceId,
        type,
        assetId,
        amount,
        createdAt,
        opponentId,
        transactionHash,
        sender,
        receiver,
        memo,
        confirmations,
        snapshotHash,
        openingBalance,
        closingBalance
      ];
  @override
  String get aliasedName => _alias ?? 'snapshots';
  @override
  String get actualTableName => 'snapshots';
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
    if (data.containsKey('trace_id')) {
      context.handle(_traceIdMeta,
          traceId.isAcceptableOrUnknown(data['trace_id']!, _traceIdMeta));
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
    if (data.containsKey('snapshot_hash')) {
      context.handle(
          _snapshotHashMeta,
          snapshotHash.isAcceptableOrUnknown(
              data['snapshot_hash']!, _snapshotHashMeta));
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
          _openingBalanceMeta,
          openingBalance.isAcceptableOrUnknown(
              data['opening_balance']!, _openingBalanceMeta));
    }
    if (data.containsKey('closing_balance')) {
      context.handle(
          _closingBalanceMeta,
          closingBalance.isAcceptableOrUnknown(
              data['closing_balance']!, _closingBalanceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {snapshotId};
  @override
  Snapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Snapshot(
      snapshotId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot_id'])!,
      traceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trace_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}amount'])!,
      createdAt: Snapshots.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      opponentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opponent_id']),
      transactionHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transaction_hash']),
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender']),
      receiver: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receiver']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      confirmations: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}confirmations']),
      snapshotHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot_hash']),
      openingBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opening_balance']),
      closingBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}closing_balance']),
    );
  }

  @override
  Snapshots createAlias(String alias) {
    return Snapshots(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(snapshot_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Snapshot extends DataClass implements Insertable<Snapshot> {
  final String snapshotId;
  final String? traceId;
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
  final String? snapshotHash;
  final String? openingBalance;
  final String? closingBalance;
  const Snapshot(
      {required this.snapshotId,
      this.traceId,
      required this.type,
      required this.assetId,
      required this.amount,
      required this.createdAt,
      this.opponentId,
      this.transactionHash,
      this.sender,
      this.receiver,
      this.memo,
      this.confirmations,
      this.snapshotHash,
      this.openingBalance,
      this.closingBalance});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['snapshot_id'] = Variable<String>(snapshotId);
    if (!nullToAbsent || traceId != null) {
      map['trace_id'] = Variable<String>(traceId);
    }
    map['type'] = Variable<String>(type);
    map['asset_id'] = Variable<String>(assetId);
    map['amount'] = Variable<String>(amount);
    {
      final converter = Snapshots.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || opponentId != null) {
      map['opponent_id'] = Variable<String>(opponentId);
    }
    if (!nullToAbsent || transactionHash != null) {
      map['transaction_hash'] = Variable<String>(transactionHash);
    }
    if (!nullToAbsent || sender != null) {
      map['sender'] = Variable<String>(sender);
    }
    if (!nullToAbsent || receiver != null) {
      map['receiver'] = Variable<String>(receiver);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || confirmations != null) {
      map['confirmations'] = Variable<int>(confirmations);
    }
    if (!nullToAbsent || snapshotHash != null) {
      map['snapshot_hash'] = Variable<String>(snapshotHash);
    }
    if (!nullToAbsent || openingBalance != null) {
      map['opening_balance'] = Variable<String>(openingBalance);
    }
    if (!nullToAbsent || closingBalance != null) {
      map['closing_balance'] = Variable<String>(closingBalance);
    }
    return map;
  }

  SnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotsCompanion(
      snapshotId: Value(snapshotId),
      traceId: traceId == null && nullToAbsent
          ? const Value.absent()
          : Value(traceId),
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
      snapshotHash: snapshotHash == null && nullToAbsent
          ? const Value.absent()
          : Value(snapshotHash),
      openingBalance: openingBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(openingBalance),
      closingBalance: closingBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(closingBalance),
    );
  }

  factory Snapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Snapshot(
      snapshotId: serializer.fromJson<String>(json['snapshot_id']),
      traceId: serializer.fromJson<String?>(json['trace_id']),
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
      snapshotHash: serializer.fromJson<String?>(json['snapshot_hash']),
      openingBalance: serializer.fromJson<String?>(json['opening_balance']),
      closingBalance: serializer.fromJson<String?>(json['closing_balance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'snapshot_id': serializer.toJson<String>(snapshotId),
      'trace_id': serializer.toJson<String?>(traceId),
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
      'snapshot_hash': serializer.toJson<String?>(snapshotHash),
      'opening_balance': serializer.toJson<String?>(openingBalance),
      'closing_balance': serializer.toJson<String?>(closingBalance),
    };
  }

  Snapshot copyWith(
          {String? snapshotId,
          Value<String?> traceId = const Value.absent(),
          String? type,
          String? assetId,
          String? amount,
          DateTime? createdAt,
          Value<String?> opponentId = const Value.absent(),
          Value<String?> transactionHash = const Value.absent(),
          Value<String?> sender = const Value.absent(),
          Value<String?> receiver = const Value.absent(),
          Value<String?> memo = const Value.absent(),
          Value<int?> confirmations = const Value.absent(),
          Value<String?> snapshotHash = const Value.absent(),
          Value<String?> openingBalance = const Value.absent(),
          Value<String?> closingBalance = const Value.absent()}) =>
      Snapshot(
        snapshotId: snapshotId ?? this.snapshotId,
        traceId: traceId.present ? traceId.value : this.traceId,
        type: type ?? this.type,
        assetId: assetId ?? this.assetId,
        amount: amount ?? this.amount,
        createdAt: createdAt ?? this.createdAt,
        opponentId: opponentId.present ? opponentId.value : this.opponentId,
        transactionHash: transactionHash.present
            ? transactionHash.value
            : this.transactionHash,
        sender: sender.present ? sender.value : this.sender,
        receiver: receiver.present ? receiver.value : this.receiver,
        memo: memo.present ? memo.value : this.memo,
        confirmations:
            confirmations.present ? confirmations.value : this.confirmations,
        snapshotHash:
            snapshotHash.present ? snapshotHash.value : this.snapshotHash,
        openingBalance:
            openingBalance.present ? openingBalance.value : this.openingBalance,
        closingBalance:
            closingBalance.present ? closingBalance.value : this.closingBalance,
      );
  @override
  String toString() {
    return (StringBuffer('Snapshot(')
          ..write('snapshotId: $snapshotId, ')
          ..write('traceId: $traceId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('opponentId: $opponentId, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('sender: $sender, ')
          ..write('receiver: $receiver, ')
          ..write('memo: $memo, ')
          ..write('confirmations: $confirmations, ')
          ..write('snapshotHash: $snapshotHash, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('closingBalance: $closingBalance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      snapshotId,
      traceId,
      type,
      assetId,
      amount,
      createdAt,
      opponentId,
      transactionHash,
      sender,
      receiver,
      memo,
      confirmations,
      snapshotHash,
      openingBalance,
      closingBalance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Snapshot &&
          other.snapshotId == this.snapshotId &&
          other.traceId == this.traceId &&
          other.type == this.type &&
          other.assetId == this.assetId &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt &&
          other.opponentId == this.opponentId &&
          other.transactionHash == this.transactionHash &&
          other.sender == this.sender &&
          other.receiver == this.receiver &&
          other.memo == this.memo &&
          other.confirmations == this.confirmations &&
          other.snapshotHash == this.snapshotHash &&
          other.openingBalance == this.openingBalance &&
          other.closingBalance == this.closingBalance);
}

class SnapshotsCompanion extends UpdateCompanion<Snapshot> {
  final Value<String> snapshotId;
  final Value<String?> traceId;
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
  final Value<String?> snapshotHash;
  final Value<String?> openingBalance;
  final Value<String?> closingBalance;
  final Value<int> rowid;
  const SnapshotsCompanion({
    this.snapshotId = const Value.absent(),
    this.traceId = const Value.absent(),
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
    this.snapshotHash = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.closingBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotsCompanion.insert({
    required String snapshotId,
    this.traceId = const Value.absent(),
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
    this.snapshotHash = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.closingBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : snapshotId = Value(snapshotId),
        type = Value(type),
        assetId = Value(assetId),
        amount = Value(amount),
        createdAt = Value(createdAt);
  static Insertable<Snapshot> custom({
    Expression<String>? snapshotId,
    Expression<String>? traceId,
    Expression<String>? type,
    Expression<String>? assetId,
    Expression<String>? amount,
    Expression<int>? createdAt,
    Expression<String>? opponentId,
    Expression<String>? transactionHash,
    Expression<String>? sender,
    Expression<String>? receiver,
    Expression<String>? memo,
    Expression<int>? confirmations,
    Expression<String>? snapshotHash,
    Expression<String>? openingBalance,
    Expression<String>? closingBalance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (traceId != null) 'trace_id': traceId,
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
      if (snapshotHash != null) 'snapshot_hash': snapshotHash,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (closingBalance != null) 'closing_balance': closingBalance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotsCompanion copyWith(
      {Value<String>? snapshotId,
      Value<String?>? traceId,
      Value<String>? type,
      Value<String>? assetId,
      Value<String>? amount,
      Value<DateTime>? createdAt,
      Value<String?>? opponentId,
      Value<String?>? transactionHash,
      Value<String?>? sender,
      Value<String?>? receiver,
      Value<String?>? memo,
      Value<int?>? confirmations,
      Value<String?>? snapshotHash,
      Value<String?>? openingBalance,
      Value<String?>? closingBalance,
      Value<int>? rowid}) {
    return SnapshotsCompanion(
      snapshotId: snapshotId ?? this.snapshotId,
      traceId: traceId ?? this.traceId,
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
      snapshotHash: snapshotHash ?? this.snapshotHash,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<String>(snapshotId.value);
    }
    if (traceId.present) {
      map['trace_id'] = Variable<String>(traceId.value);
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
      final converter = Snapshots.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (opponentId.present) {
      map['opponent_id'] = Variable<String>(opponentId.value);
    }
    if (transactionHash.present) {
      map['transaction_hash'] = Variable<String>(transactionHash.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (receiver.present) {
      map['receiver'] = Variable<String>(receiver.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (confirmations.present) {
      map['confirmations'] = Variable<int>(confirmations.value);
    }
    if (snapshotHash.present) {
      map['snapshot_hash'] = Variable<String>(snapshotHash.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<String>(openingBalance.value);
    }
    if (closingBalance.present) {
      map['closing_balance'] = Variable<String>(closingBalance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotsCompanion(')
          ..write('snapshotId: $snapshotId, ')
          ..write('traceId: $traceId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('opponentId: $opponentId, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('sender: $sender, ')
          ..write('receiver: $receiver, ')
          ..write('memo: $memo, ')
          ..write('confirmations: $confirmations, ')
          ..write('snapshotHash: $snapshotHash, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('closingBalance: $closingBalance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Assets extends Table with TableInfo<Assets, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Assets(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
      'symbol', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _iconUrlMeta =
      const VerificationMeta('iconUrl');
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
      'icon_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  late final GeneratedColumn<String> balance = GeneratedColumn<String>(
      'balance', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _destinationMeta =
      const VerificationMeta('destination');
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
      'destination', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _priceBtcMeta =
      const VerificationMeta('priceBtc');
  late final GeneratedColumn<String> priceBtc = GeneratedColumn<String>(
      'price_btc', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _priceUsdMeta =
      const VerificationMeta('priceUsd');
  late final GeneratedColumn<String> priceUsd = GeneratedColumn<String>(
      'price_usd', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _chainIdMeta =
      const VerificationMeta('chainId');
  late final GeneratedColumn<String> chainId = GeneratedColumn<String>(
      'chain_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _changeUsdMeta =
      const VerificationMeta('changeUsd');
  late final GeneratedColumn<String> changeUsd = GeneratedColumn<String>(
      'change_usd', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _changeBtcMeta =
      const VerificationMeta('changeBtc');
  late final GeneratedColumn<String> changeBtc = GeneratedColumn<String>(
      'change_btc', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _confirmationsMeta =
      const VerificationMeta('confirmations');
  late final GeneratedColumn<int> confirmations = GeneratedColumn<int>(
      'confirmations', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _assetKeyMeta =
      const VerificationMeta('assetKey');
  late final GeneratedColumn<String> assetKey = GeneratedColumn<String>(
      'asset_key', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _reserveMeta =
      const VerificationMeta('reserve');
  late final GeneratedColumn<String> reserve = GeneratedColumn<String>(
      'reserve', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
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
        assetKey,
        reserve
      ];
  @override
  String get aliasedName => _alias ?? 'assets';
  @override
  String get actualTableName => 'assets';
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
    if (data.containsKey('reserve')) {
      context.handle(_reserveMeta,
          reserve.isAcceptableOrUnknown(data['reserve']!, _reserveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      symbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_url'])!,
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}balance'])!,
      destination: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}destination'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag']),
      priceBtc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}price_btc'])!,
      priceUsd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}price_usd'])!,
      chainId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chain_id'])!,
      changeUsd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}change_usd'])!,
      changeBtc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}change_btc'])!,
      confirmations: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}confirmations'])!,
      assetKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_key']),
      reserve: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reserve']),
    );
  }

  @override
  Assets createAlias(String alias) {
    return Assets(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(asset_id)'];
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
  final String? reserve;
  const Asset(
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
      this.assetKey,
      this.reserve});
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
      map['tag'] = Variable<String>(tag);
    }
    map['price_btc'] = Variable<String>(priceBtc);
    map['price_usd'] = Variable<String>(priceUsd);
    map['chain_id'] = Variable<String>(chainId);
    map['change_usd'] = Variable<String>(changeUsd);
    map['change_btc'] = Variable<String>(changeBtc);
    map['confirmations'] = Variable<int>(confirmations);
    if (!nullToAbsent || assetKey != null) {
      map['asset_key'] = Variable<String>(assetKey);
    }
    if (!nullToAbsent || reserve != null) {
      map['reserve'] = Variable<String>(reserve);
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
      reserve: reserve == null && nullToAbsent
          ? const Value.absent()
          : Value(reserve),
    );
  }

  factory Asset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
      reserve: serializer.fromJson<String?>(json['reserve']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
      'reserve': serializer.toJson<String?>(reserve),
    };
  }

  Asset copyWith(
          {String? assetId,
          String? symbol,
          String? name,
          String? iconUrl,
          String? balance,
          String? destination,
          Value<String?> tag = const Value.absent(),
          String? priceBtc,
          String? priceUsd,
          String? chainId,
          String? changeUsd,
          String? changeBtc,
          int? confirmations,
          Value<String?> assetKey = const Value.absent(),
          Value<String?> reserve = const Value.absent()}) =>
      Asset(
        assetId: assetId ?? this.assetId,
        symbol: symbol ?? this.symbol,
        name: name ?? this.name,
        iconUrl: iconUrl ?? this.iconUrl,
        balance: balance ?? this.balance,
        destination: destination ?? this.destination,
        tag: tag.present ? tag.value : this.tag,
        priceBtc: priceBtc ?? this.priceBtc,
        priceUsd: priceUsd ?? this.priceUsd,
        chainId: chainId ?? this.chainId,
        changeUsd: changeUsd ?? this.changeUsd,
        changeBtc: changeBtc ?? this.changeBtc,
        confirmations: confirmations ?? this.confirmations,
        assetKey: assetKey.present ? assetKey.value : this.assetKey,
        reserve: reserve.present ? reserve.value : this.reserve,
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
          ..write('assetKey: $assetKey, ')
          ..write('reserve: $reserve')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
      assetKey,
      reserve);
  @override
  bool operator ==(Object other) =>
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
          other.assetKey == this.assetKey &&
          other.reserve == this.reserve);
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
  final Value<String?> reserve;
  final Value<int> rowid;
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
    this.reserve = const Value.absent(),
    this.rowid = const Value.absent(),
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
    this.reserve = const Value.absent(),
    this.rowid = const Value.absent(),
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
    Expression<String>? tag,
    Expression<String>? priceBtc,
    Expression<String>? priceUsd,
    Expression<String>? chainId,
    Expression<String>? changeUsd,
    Expression<String>? changeBtc,
    Expression<int>? confirmations,
    Expression<String>? assetKey,
    Expression<String>? reserve,
    Expression<int>? rowid,
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
      if (reserve != null) 'reserve': reserve,
      if (rowid != null) 'rowid': rowid,
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
      Value<String?>? assetKey,
      Value<String?>? reserve,
      Value<int>? rowid}) {
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
      reserve: reserve ?? this.reserve,
      rowid: rowid ?? this.rowid,
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
      map['tag'] = Variable<String>(tag.value);
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
      map['asset_key'] = Variable<String>(assetKey.value);
    }
    if (reserve.present) {
      map['reserve'] = Variable<String>(reserve.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('assetKey: $assetKey, ')
          ..write('reserve: $reserve, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Chains extends Table with TableInfo<Chains, Chain> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Chains(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chainIdMeta =
      const VerificationMeta('chainId');
  late final GeneratedColumn<String> chainId = GeneratedColumn<String>(
      'chain_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
      'symbol', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _iconUrlMeta =
      const VerificationMeta('iconUrl');
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
      'icon_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _thresholdMeta =
      const VerificationMeta('threshold');
  late final GeneratedColumn<int> threshold = GeneratedColumn<int>(
      'threshold', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns =>
      [chainId, name, symbol, iconUrl, threshold];
  @override
  String get aliasedName => _alias ?? 'chains';
  @override
  String get actualTableName => 'chains';
  @override
  VerificationContext validateIntegrity(Insertable<Chain> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chain_id')) {
      context.handle(_chainIdMeta,
          chainId.isAcceptableOrUnknown(data['chain_id']!, _chainIdMeta));
    } else if (isInserting) {
      context.missing(_chainIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(_iconUrlMeta,
          iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta));
    } else if (isInserting) {
      context.missing(_iconUrlMeta);
    }
    if (data.containsKey('threshold')) {
      context.handle(_thresholdMeta,
          threshold.isAcceptableOrUnknown(data['threshold']!, _thresholdMeta));
    } else if (isInserting) {
      context.missing(_thresholdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chainId};
  @override
  Chain map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chain(
      chainId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chain_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      symbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      iconUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_url'])!,
      threshold: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}threshold'])!,
    );
  }

  @override
  Chains createAlias(String alias) {
    return Chains(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(chain_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Chain extends DataClass implements Insertable<Chain> {
  final String chainId;
  final String name;
  final String symbol;
  final String iconUrl;
  final int threshold;
  const Chain(
      {required this.chainId,
      required this.name,
      required this.symbol,
      required this.iconUrl,
      required this.threshold});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chain_id'] = Variable<String>(chainId);
    map['name'] = Variable<String>(name);
    map['symbol'] = Variable<String>(symbol);
    map['icon_url'] = Variable<String>(iconUrl);
    map['threshold'] = Variable<int>(threshold);
    return map;
  }

  ChainsCompanion toCompanion(bool nullToAbsent) {
    return ChainsCompanion(
      chainId: Value(chainId),
      name: Value(name),
      symbol: Value(symbol),
      iconUrl: Value(iconUrl),
      threshold: Value(threshold),
    );
  }

  factory Chain.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chain(
      chainId: serializer.fromJson<String>(json['chain_id']),
      name: serializer.fromJson<String>(json['name']),
      symbol: serializer.fromJson<String>(json['symbol']),
      iconUrl: serializer.fromJson<String>(json['icon_url']),
      threshold: serializer.fromJson<int>(json['threshold']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chain_id': serializer.toJson<String>(chainId),
      'name': serializer.toJson<String>(name),
      'symbol': serializer.toJson<String>(symbol),
      'icon_url': serializer.toJson<String>(iconUrl),
      'threshold': serializer.toJson<int>(threshold),
    };
  }

  Chain copyWith(
          {String? chainId,
          String? name,
          String? symbol,
          String? iconUrl,
          int? threshold}) =>
      Chain(
        chainId: chainId ?? this.chainId,
        name: name ?? this.name,
        symbol: symbol ?? this.symbol,
        iconUrl: iconUrl ?? this.iconUrl,
        threshold: threshold ?? this.threshold,
      );
  @override
  String toString() {
    return (StringBuffer('Chain(')
          ..write('chainId: $chainId, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('threshold: $threshold')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chainId, name, symbol, iconUrl, threshold);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chain &&
          other.chainId == this.chainId &&
          other.name == this.name &&
          other.symbol == this.symbol &&
          other.iconUrl == this.iconUrl &&
          other.threshold == this.threshold);
}

class ChainsCompanion extends UpdateCompanion<Chain> {
  final Value<String> chainId;
  final Value<String> name;
  final Value<String> symbol;
  final Value<String> iconUrl;
  final Value<int> threshold;
  final Value<int> rowid;
  const ChainsCompanion({
    this.chainId = const Value.absent(),
    this.name = const Value.absent(),
    this.symbol = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.threshold = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChainsCompanion.insert({
    required String chainId,
    required String name,
    required String symbol,
    required String iconUrl,
    required int threshold,
    this.rowid = const Value.absent(),
  })  : chainId = Value(chainId),
        name = Value(name),
        symbol = Value(symbol),
        iconUrl = Value(iconUrl),
        threshold = Value(threshold);
  static Insertable<Chain> custom({
    Expression<String>? chainId,
    Expression<String>? name,
    Expression<String>? symbol,
    Expression<String>? iconUrl,
    Expression<int>? threshold,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chainId != null) 'chain_id': chainId,
      if (name != null) 'name': name,
      if (symbol != null) 'symbol': symbol,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (threshold != null) 'threshold': threshold,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChainsCompanion copyWith(
      {Value<String>? chainId,
      Value<String>? name,
      Value<String>? symbol,
      Value<String>? iconUrl,
      Value<int>? threshold,
      Value<int>? rowid}) {
    return ChainsCompanion(
      chainId: chainId ?? this.chainId,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      iconUrl: iconUrl ?? this.iconUrl,
      threshold: threshold ?? this.threshold,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chainId.present) {
      map['chain_id'] = Variable<String>(chainId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (threshold.present) {
      map['threshold'] = Variable<int>(threshold.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChainsCompanion(')
          ..write('chainId: $chainId, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('threshold: $threshold, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Stickers extends Table with TableInfo<Stickers, Sticker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Stickers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stickerIdMeta =
      const VerificationMeta('stickerId');
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
      'sticker_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _assetUrlMeta =
      const VerificationMeta('assetUrl');
  late final GeneratedColumn<String> assetUrl = GeneratedColumn<String>(
      'asset_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _assetTypeMeta =
      const VerificationMeta('assetType');
  late final GeneratedColumn<String> assetType = GeneratedColumn<String>(
      'asset_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _assetWidthMeta =
      const VerificationMeta('assetWidth');
  late final GeneratedColumn<int> assetWidth = GeneratedColumn<int>(
      'asset_width', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _assetHeightMeta =
      const VerificationMeta('assetHeight');
  late final GeneratedColumn<int> assetHeight = GeneratedColumn<int>(
      'asset_height', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(Stickers.$convertercreatedAt);
  static const VerificationMeta _lastUseAtMeta =
      const VerificationMeta('lastUseAt');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastUseAt =
      GeneratedColumn<int>('last_use_at', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(Stickers.$converterlastUseAtn);
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
  String get aliasedName => _alias ?? 'stickers';
  @override
  String get actualTableName => 'stickers';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sticker(
      stickerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sticker_id'])!,
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      assetUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_url'])!,
      assetType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_type'])!,
      assetWidth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_width'])!,
      assetHeight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_height'])!,
      createdAt: Stickers.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      lastUseAt: Stickers.$converterlastUseAtn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_use_at'])),
    );
  }

  @override
  Stickers createAlias(String alias) {
    return Stickers(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime, int> $converterlastUseAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $converterlastUseAtn =
      NullAwareTypeConverter.wrap($converterlastUseAt);
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(sticker_id)'];
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
  const Sticker(
      {required this.stickerId,
      this.albumId,
      required this.name,
      required this.assetUrl,
      required this.assetType,
      required this.assetWidth,
      required this.assetHeight,
      required this.createdAt,
      this.lastUseAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sticker_id'] = Variable<String>(stickerId);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    map['name'] = Variable<String>(name);
    map['asset_url'] = Variable<String>(assetUrl);
    map['asset_type'] = Variable<String>(assetType);
    map['asset_width'] = Variable<int>(assetWidth);
    map['asset_height'] = Variable<int>(assetHeight);
    {
      final converter = Stickers.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || lastUseAt != null) {
      final converter = Stickers.$converterlastUseAtn;
      map['last_use_at'] = Variable<int>(converter.toSql(lastUseAt));
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
          Value<String?> albumId = const Value.absent(),
          String? name,
          String? assetUrl,
          String? assetType,
          int? assetWidth,
          int? assetHeight,
          DateTime? createdAt,
          Value<DateTime?> lastUseAt = const Value.absent()}) =>
      Sticker(
        stickerId: stickerId ?? this.stickerId,
        albumId: albumId.present ? albumId.value : this.albumId,
        name: name ?? this.name,
        assetUrl: assetUrl ?? this.assetUrl,
        assetType: assetType ?? this.assetType,
        assetWidth: assetWidth ?? this.assetWidth,
        assetHeight: assetHeight ?? this.assetHeight,
        createdAt: createdAt ?? this.createdAt,
        lastUseAt: lastUseAt.present ? lastUseAt.value : this.lastUseAt,
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
  int get hashCode => Object.hash(stickerId, albumId, name, assetUrl, assetType,
      assetWidth, assetHeight, createdAt, lastUseAt);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
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
    this.rowid = const Value.absent(),
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
    this.rowid = const Value.absent(),
  })  : stickerId = Value(stickerId),
        name = Value(name),
        assetUrl = Value(assetUrl),
        assetType = Value(assetType),
        assetWidth = Value(assetWidth),
        assetHeight = Value(assetHeight),
        createdAt = Value(createdAt);
  static Insertable<Sticker> custom({
    Expression<String>? stickerId,
    Expression<String>? albumId,
    Expression<String>? name,
    Expression<String>? assetUrl,
    Expression<String>? assetType,
    Expression<int>? assetWidth,
    Expression<int>? assetHeight,
    Expression<int>? createdAt,
    Expression<int>? lastUseAt,
    Expression<int>? rowid,
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
      if (rowid != null) 'rowid': rowid,
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
      Value<DateTime?>? lastUseAt,
      Value<int>? rowid}) {
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
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
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
      final converter = Stickers.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (lastUseAt.present) {
      final converter = Stickers.$converterlastUseAtn;
      map['last_use_at'] = Variable<int>(converter.toSql(lastUseAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('lastUseAt: $lastUseAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Hyperlinks extends Table with TableInfo<Hyperlinks, Hyperlink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Hyperlinks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hyperlinkMeta =
      const VerificationMeta('hyperlink');
  late final GeneratedColumn<String> hyperlink = GeneratedColumn<String>(
      'hyperlink', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _siteNameMeta =
      const VerificationMeta('siteName');
  late final GeneratedColumn<String> siteName = GeneratedColumn<String>(
      'site_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _siteTitleMeta =
      const VerificationMeta('siteTitle');
  late final GeneratedColumn<String> siteTitle = GeneratedColumn<String>(
      'site_title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _siteDescriptionMeta =
      const VerificationMeta('siteDescription');
  late final GeneratedColumn<String> siteDescription = GeneratedColumn<String>(
      'site_description', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _siteImageMeta =
      const VerificationMeta('siteImage');
  late final GeneratedColumn<String> siteImage = GeneratedColumn<String>(
      'site_image', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [hyperlink, siteName, siteTitle, siteDescription, siteImage];
  @override
  String get aliasedName => _alias ?? 'hyperlinks';
  @override
  String get actualTableName => 'hyperlinks';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Hyperlink(
      hyperlink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hyperlink'])!,
      siteName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}site_name'])!,
      siteTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}site_title'])!,
      siteDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}site_description']),
      siteImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}site_image']),
    );
  }

  @override
  Hyperlinks createAlias(String alias) {
    return Hyperlinks(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(hyperlink)'];
  @override
  bool get dontWriteConstraints => true;
}

class Hyperlink extends DataClass implements Insertable<Hyperlink> {
  final String hyperlink;
  final String siteName;
  final String siteTitle;
  final String? siteDescription;
  final String? siteImage;
  const Hyperlink(
      {required this.hyperlink,
      required this.siteName,
      required this.siteTitle,
      this.siteDescription,
      this.siteImage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hyperlink'] = Variable<String>(hyperlink);
    map['site_name'] = Variable<String>(siteName);
    map['site_title'] = Variable<String>(siteTitle);
    if (!nullToAbsent || siteDescription != null) {
      map['site_description'] = Variable<String>(siteDescription);
    }
    if (!nullToAbsent || siteImage != null) {
      map['site_image'] = Variable<String>(siteImage);
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
          Value<String?> siteDescription = const Value.absent(),
          Value<String?> siteImage = const Value.absent()}) =>
      Hyperlink(
        hyperlink: hyperlink ?? this.hyperlink,
        siteName: siteName ?? this.siteName,
        siteTitle: siteTitle ?? this.siteTitle,
        siteDescription: siteDescription.present
            ? siteDescription.value
            : this.siteDescription,
        siteImage: siteImage.present ? siteImage.value : this.siteImage,
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
  int get hashCode =>
      Object.hash(hyperlink, siteName, siteTitle, siteDescription, siteImage);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
  const HyperlinksCompanion({
    this.hyperlink = const Value.absent(),
    this.siteName = const Value.absent(),
    this.siteTitle = const Value.absent(),
    this.siteDescription = const Value.absent(),
    this.siteImage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HyperlinksCompanion.insert({
    required String hyperlink,
    required String siteName,
    required String siteTitle,
    this.siteDescription = const Value.absent(),
    this.siteImage = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : hyperlink = Value(hyperlink),
        siteName = Value(siteName),
        siteTitle = Value(siteTitle);
  static Insertable<Hyperlink> custom({
    Expression<String>? hyperlink,
    Expression<String>? siteName,
    Expression<String>? siteTitle,
    Expression<String>? siteDescription,
    Expression<String>? siteImage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hyperlink != null) 'hyperlink': hyperlink,
      if (siteName != null) 'site_name': siteName,
      if (siteTitle != null) 'site_title': siteTitle,
      if (siteDescription != null) 'site_description': siteDescription,
      if (siteImage != null) 'site_image': siteImage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HyperlinksCompanion copyWith(
      {Value<String>? hyperlink,
      Value<String>? siteName,
      Value<String>? siteTitle,
      Value<String?>? siteDescription,
      Value<String?>? siteImage,
      Value<int>? rowid}) {
    return HyperlinksCompanion(
      hyperlink: hyperlink ?? this.hyperlink,
      siteName: siteName ?? this.siteName,
      siteTitle: siteTitle ?? this.siteTitle,
      siteDescription: siteDescription ?? this.siteDescription,
      siteImage: siteImage ?? this.siteImage,
      rowid: rowid ?? this.rowid,
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
      map['site_description'] = Variable<String>(siteDescription.value);
    }
    if (siteImage.present) {
      map['site_image'] = Variable<String>(siteImage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('siteImage: $siteImage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MessageMentions extends Table
    with TableInfo<MessageMentions, MessageMention> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MessageMentions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _hasReadMeta =
      const VerificationMeta('hasRead');
  late final GeneratedColumn<bool> hasRead = GeneratedColumn<bool>(
      'has_read', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [messageId, conversationId, hasRead];
  @override
  String get aliasedName => _alias ?? 'message_mentions';
  @override
  String get actualTableName => 'message_mentions';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageMention(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      hasRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_read']),
    );
  }

  @override
  MessageMentions createAlias(String alias) {
    return MessageMentions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class MessageMention extends DataClass implements Insertable<MessageMention> {
  final String messageId;
  final String conversationId;
  final bool? hasRead;
  const MessageMention(
      {required this.messageId, required this.conversationId, this.hasRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || hasRead != null) {
      map['has_read'] = Variable<bool>(hasRead);
    }
    return map;
  }

  MessageMentionsCompanion toCompanion(bool nullToAbsent) {
    return MessageMentionsCompanion(
      messageId: Value(messageId),
      conversationId: Value(conversationId),
      hasRead: hasRead == null && nullToAbsent
          ? const Value.absent()
          : Value(hasRead),
    );
  }

  factory MessageMention.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageMention(
      messageId: serializer.fromJson<String>(json['message_id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      hasRead: serializer.fromJson<bool?>(json['has_read']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'conversation_id': serializer.toJson<String>(conversationId),
      'has_read': serializer.toJson<bool?>(hasRead),
    };
  }

  MessageMention copyWith(
          {String? messageId,
          String? conversationId,
          Value<bool?> hasRead = const Value.absent()}) =>
      MessageMention(
        messageId: messageId ?? this.messageId,
        conversationId: conversationId ?? this.conversationId,
        hasRead: hasRead.present ? hasRead.value : this.hasRead,
      );
  @override
  String toString() {
    return (StringBuffer('MessageMention(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('hasRead: $hasRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, conversationId, hasRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageMention &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.hasRead == this.hasRead);
}

class MessageMentionsCompanion extends UpdateCompanion<MessageMention> {
  final Value<String> messageId;
  final Value<String> conversationId;
  final Value<bool?> hasRead;
  final Value<int> rowid;
  const MessageMentionsCompanion({
    this.messageId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.hasRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageMentionsCompanion.insert({
    required String messageId,
    required String conversationId,
    this.hasRead = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        conversationId = Value(conversationId);
  static Insertable<MessageMention> custom({
    Expression<String>? messageId,
    Expression<String>? conversationId,
    Expression<bool>? hasRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (hasRead != null) 'has_read': hasRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageMentionsCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? conversationId,
      Value<bool?>? hasRead,
      Value<int>? rowid}) {
    return MessageMentionsCompanion(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      hasRead: hasRead ?? this.hasRead,
      rowid: rowid ?? this.rowid,
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
    if (hasRead.present) {
      map['has_read'] = Variable<bool>(hasRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageMentionsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('hasRead: $hasRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PinMessages extends Table with TableInfo<PinMessages, PinMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PinMessages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(PinMessages.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [messageId, conversationId, createdAt];
  @override
  String get aliasedName => _alias ?? 'pin_messages';
  @override
  String get actualTableName => 'pin_messages';
  @override
  VerificationContext validateIntegrity(Insertable<PinMessage> instance,
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
    context.handle(_createdAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  PinMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PinMessage(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      createdAt: PinMessages.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
    );
  }

  @override
  PinMessages createAlias(String alias) {
    return PinMessages(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class PinMessage extends DataClass implements Insertable<PinMessage> {
  final String messageId;
  final String conversationId;
  final DateTime createdAt;
  const PinMessage(
      {required this.messageId,
      required this.conversationId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['conversation_id'] = Variable<String>(conversationId);
    {
      final converter = PinMessages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    return map;
  }

  PinMessagesCompanion toCompanion(bool nullToAbsent) {
    return PinMessagesCompanion(
      messageId: Value(messageId),
      conversationId: Value(conversationId),
      createdAt: Value(createdAt),
    );
  }

  factory PinMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PinMessage(
      messageId: serializer.fromJson<String>(json['message_id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'conversation_id': serializer.toJson<String>(conversationId),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  PinMessage copyWith(
          {String? messageId, String? conversationId, DateTime? createdAt}) =>
      PinMessage(
        messageId: messageId ?? this.messageId,
        conversationId: conversationId ?? this.conversationId,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('PinMessage(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, conversationId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PinMessage &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.createdAt == this.createdAt);
}

class PinMessagesCompanion extends UpdateCompanion<PinMessage> {
  final Value<String> messageId;
  final Value<String> conversationId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PinMessagesCompanion({
    this.messageId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PinMessagesCompanion.insert({
    required String messageId,
    required String conversationId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        conversationId = Value(conversationId),
        createdAt = Value(createdAt);
  static Insertable<PinMessage> custom({
    Expression<String>? messageId,
    Expression<String>? conversationId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PinMessagesCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? conversationId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PinMessagesCompanion(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
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
    if (createdAt.present) {
      final converter = PinMessages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PinMessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExpiredMessages extends Table
    with TableInfo<ExpiredMessages, ExpiredMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExpiredMessages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _expireInMeta =
      const VerificationMeta('expireIn');
  late final GeneratedColumn<int> expireIn = GeneratedColumn<int>(
      'expire_in', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _expireAtMeta =
      const VerificationMeta('expireAt');
  late final GeneratedColumn<int> expireAt = GeneratedColumn<int>(
      'expire_at', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [messageId, expireIn, expireAt];
  @override
  String get aliasedName => _alias ?? 'expired_messages';
  @override
  String get actualTableName => 'expired_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ExpiredMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('expire_in')) {
      context.handle(_expireInMeta,
          expireIn.isAcceptableOrUnknown(data['expire_in']!, _expireInMeta));
    } else if (isInserting) {
      context.missing(_expireInMeta);
    }
    if (data.containsKey('expire_at')) {
      context.handle(_expireAtMeta,
          expireAt.isAcceptableOrUnknown(data['expire_at']!, _expireAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  ExpiredMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpiredMessage(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      expireIn: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expire_in'])!,
      expireAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expire_at']),
    );
  }

  @override
  ExpiredMessages createAlias(String alias) {
    return ExpiredMessages(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class ExpiredMessage extends DataClass implements Insertable<ExpiredMessage> {
  final String messageId;
  final int expireIn;
  final int? expireAt;
  const ExpiredMessage(
      {required this.messageId, required this.expireIn, this.expireAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['expire_in'] = Variable<int>(expireIn);
    if (!nullToAbsent || expireAt != null) {
      map['expire_at'] = Variable<int>(expireAt);
    }
    return map;
  }

  ExpiredMessagesCompanion toCompanion(bool nullToAbsent) {
    return ExpiredMessagesCompanion(
      messageId: Value(messageId),
      expireIn: Value(expireIn),
      expireAt: expireAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expireAt),
    );
  }

  factory ExpiredMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpiredMessage(
      messageId: serializer.fromJson<String>(json['message_id']),
      expireIn: serializer.fromJson<int>(json['expire_in']),
      expireAt: serializer.fromJson<int?>(json['expire_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'expire_in': serializer.toJson<int>(expireIn),
      'expire_at': serializer.toJson<int?>(expireAt),
    };
  }

  ExpiredMessage copyWith(
          {String? messageId,
          int? expireIn,
          Value<int?> expireAt = const Value.absent()}) =>
      ExpiredMessage(
        messageId: messageId ?? this.messageId,
        expireIn: expireIn ?? this.expireIn,
        expireAt: expireAt.present ? expireAt.value : this.expireAt,
      );
  @override
  String toString() {
    return (StringBuffer('ExpiredMessage(')
          ..write('messageId: $messageId, ')
          ..write('expireIn: $expireIn, ')
          ..write('expireAt: $expireAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, expireIn, expireAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpiredMessage &&
          other.messageId == this.messageId &&
          other.expireIn == this.expireIn &&
          other.expireAt == this.expireAt);
}

class ExpiredMessagesCompanion extends UpdateCompanion<ExpiredMessage> {
  final Value<String> messageId;
  final Value<int> expireIn;
  final Value<int?> expireAt;
  final Value<int> rowid;
  const ExpiredMessagesCompanion({
    this.messageId = const Value.absent(),
    this.expireIn = const Value.absent(),
    this.expireAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpiredMessagesCompanion.insert({
    required String messageId,
    required int expireIn,
    this.expireAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        expireIn = Value(expireIn);
  static Insertable<ExpiredMessage> custom({
    Expression<String>? messageId,
    Expression<int>? expireIn,
    Expression<int>? expireAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (expireIn != null) 'expire_in': expireIn,
      if (expireAt != null) 'expire_at': expireAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpiredMessagesCompanion copyWith(
      {Value<String>? messageId,
      Value<int>? expireIn,
      Value<int?>? expireAt,
      Value<int>? rowid}) {
    return ExpiredMessagesCompanion(
      messageId: messageId ?? this.messageId,
      expireIn: expireIn ?? this.expireIn,
      expireAt: expireAt ?? this.expireAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (expireIn.present) {
      map['expire_in'] = Variable<int>(expireIn.value);
    }
    if (expireAt.present) {
      map['expire_at'] = Variable<int>(expireAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpiredMessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('expireIn: $expireIn, ')
          ..write('expireAt: $expireAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ResendSessionMessages extends Table
    with TableInfo<ResendSessionMessages, ResendSessionMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ResendSessionMessages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(ResendSessionMessages.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns =>
      [messageId, userId, sessionId, status, createdAt];
  @override
  String get aliasedName => _alias ?? 'resend_session_messages';
  @override
  String get actualTableName => 'resend_session_messages';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResendSessionMessage(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      createdAt: ResendSessionMessages.$convertercreatedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
    );
  }

  @override
  ResendSessionMessages createAlias(String alias) {
    return ResendSessionMessages(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(message_id, user_id, session_id)'];
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
  const ResendSessionMessage(
      {required this.messageId,
      required this.userId,
      required this.sessionId,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['user_id'] = Variable<String>(userId);
    map['session_id'] = Variable<String>(sessionId);
    map['status'] = Variable<int>(status);
    {
      final converter = ResendSessionMessages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
  int get hashCode =>
      Object.hash(messageId, userId, sessionId, status, createdAt);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
  const ResendSessionMessagesCompanion({
    this.messageId = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResendSessionMessagesCompanion.insert({
    required String messageId,
    required String userId,
    required String sessionId,
    required int status,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        userId = Value(userId),
        sessionId = Value(sessionId),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<ResendSessionMessage> custom({
    Expression<String>? messageId,
    Expression<String>? userId,
    Expression<String>? sessionId,
    Expression<int>? status,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResendSessionMessagesCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? userId,
      Value<String>? sessionId,
      Value<int>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ResendSessionMessagesCompanion(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
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
      final converter = ResendSessionMessages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Addresses extends Table with TableInfo<Addresses, Addresse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Addresses(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _addressIdMeta =
      const VerificationMeta('addressId');
  late final GeneratedColumn<String> addressId = GeneratedColumn<String>(
      'address_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _destinationMeta =
      const VerificationMeta('destination');
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
      'destination', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(Addresses.$converterupdatedAt);
  static const VerificationMeta _reserveMeta =
      const VerificationMeta('reserve');
  late final GeneratedColumn<String> reserve = GeneratedColumn<String>(
      'reserve', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _feeMeta = const VerificationMeta('fee');
  late final GeneratedColumn<String> fee = GeneratedColumn<String>(
      'fee', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _dustMeta = const VerificationMeta('dust');
  late final GeneratedColumn<String> dust = GeneratedColumn<String>(
      'dust', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [
        addressId,
        type,
        assetId,
        destination,
        label,
        updatedAt,
        reserve,
        fee,
        tag,
        dust
      ];
  @override
  String get aliasedName => _alias ?? 'addresses';
  @override
  String get actualTableName => 'addresses';
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
    if (data.containsKey('destination')) {
      context.handle(
          _destinationMeta,
          destination.isAcceptableOrUnknown(
              data['destination']!, _destinationMeta));
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
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
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Addresse(
      addressId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      destination: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}destination'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      updatedAt: Addresses.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      reserve: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reserve'])!,
      fee: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fee'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag']),
      dust: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dust']),
    );
  }

  @override
  Addresses createAlias(String alias) {
    return Addresses(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterupdatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(address_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Addresse extends DataClass implements Insertable<Addresse> {
  final String addressId;
  final String type;
  final String assetId;
  final String destination;
  final String label;
  final DateTime updatedAt;
  final String reserve;
  final String fee;
  final String? tag;
  final String? dust;
  const Addresse(
      {required this.addressId,
      required this.type,
      required this.assetId,
      required this.destination,
      required this.label,
      required this.updatedAt,
      required this.reserve,
      required this.fee,
      this.tag,
      this.dust});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['address_id'] = Variable<String>(addressId);
    map['type'] = Variable<String>(type);
    map['asset_id'] = Variable<String>(assetId);
    map['destination'] = Variable<String>(destination);
    map['label'] = Variable<String>(label);
    {
      final converter = Addresses.$converterupdatedAt;
      map['updated_at'] = Variable<int>(converter.toSql(updatedAt));
    }
    map['reserve'] = Variable<String>(reserve);
    map['fee'] = Variable<String>(fee);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || dust != null) {
      map['dust'] = Variable<String>(dust);
    }
    return map;
  }

  AddressesCompanion toCompanion(bool nullToAbsent) {
    return AddressesCompanion(
      addressId: Value(addressId),
      type: Value(type),
      assetId: Value(assetId),
      destination: Value(destination),
      label: Value(label),
      updatedAt: Value(updatedAt),
      reserve: Value(reserve),
      fee: Value(fee),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      dust: dust == null && nullToAbsent ? const Value.absent() : Value(dust),
    );
  }

  factory Addresse.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Addresse(
      addressId: serializer.fromJson<String>(json['address_id']),
      type: serializer.fromJson<String>(json['type']),
      assetId: serializer.fromJson<String>(json['asset_id']),
      destination: serializer.fromJson<String>(json['destination']),
      label: serializer.fromJson<String>(json['label']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      reserve: serializer.fromJson<String>(json['reserve']),
      fee: serializer.fromJson<String>(json['fee']),
      tag: serializer.fromJson<String?>(json['tag']),
      dust: serializer.fromJson<String?>(json['dust']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'address_id': serializer.toJson<String>(addressId),
      'type': serializer.toJson<String>(type),
      'asset_id': serializer.toJson<String>(assetId),
      'destination': serializer.toJson<String>(destination),
      'label': serializer.toJson<String>(label),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'reserve': serializer.toJson<String>(reserve),
      'fee': serializer.toJson<String>(fee),
      'tag': serializer.toJson<String?>(tag),
      'dust': serializer.toJson<String?>(dust),
    };
  }

  Addresse copyWith(
          {String? addressId,
          String? type,
          String? assetId,
          String? destination,
          String? label,
          DateTime? updatedAt,
          String? reserve,
          String? fee,
          Value<String?> tag = const Value.absent(),
          Value<String?> dust = const Value.absent()}) =>
      Addresse(
        addressId: addressId ?? this.addressId,
        type: type ?? this.type,
        assetId: assetId ?? this.assetId,
        destination: destination ?? this.destination,
        label: label ?? this.label,
        updatedAt: updatedAt ?? this.updatedAt,
        reserve: reserve ?? this.reserve,
        fee: fee ?? this.fee,
        tag: tag.present ? tag.value : this.tag,
        dust: dust.present ? dust.value : this.dust,
      );
  @override
  String toString() {
    return (StringBuffer('Addresse(')
          ..write('addressId: $addressId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('destination: $destination, ')
          ..write('label: $label, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('reserve: $reserve, ')
          ..write('fee: $fee, ')
          ..write('tag: $tag, ')
          ..write('dust: $dust')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(addressId, type, assetId, destination, label,
      updatedAt, reserve, fee, tag, dust);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Addresse &&
          other.addressId == this.addressId &&
          other.type == this.type &&
          other.assetId == this.assetId &&
          other.destination == this.destination &&
          other.label == this.label &&
          other.updatedAt == this.updatedAt &&
          other.reserve == this.reserve &&
          other.fee == this.fee &&
          other.tag == this.tag &&
          other.dust == this.dust);
}

class AddressesCompanion extends UpdateCompanion<Addresse> {
  final Value<String> addressId;
  final Value<String> type;
  final Value<String> assetId;
  final Value<String> destination;
  final Value<String> label;
  final Value<DateTime> updatedAt;
  final Value<String> reserve;
  final Value<String> fee;
  final Value<String?> tag;
  final Value<String?> dust;
  final Value<int> rowid;
  const AddressesCompanion({
    this.addressId = const Value.absent(),
    this.type = const Value.absent(),
    this.assetId = const Value.absent(),
    this.destination = const Value.absent(),
    this.label = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.reserve = const Value.absent(),
    this.fee = const Value.absent(),
    this.tag = const Value.absent(),
    this.dust = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AddressesCompanion.insert({
    required String addressId,
    required String type,
    required String assetId,
    required String destination,
    required String label,
    required DateTime updatedAt,
    required String reserve,
    required String fee,
    this.tag = const Value.absent(),
    this.dust = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : addressId = Value(addressId),
        type = Value(type),
        assetId = Value(assetId),
        destination = Value(destination),
        label = Value(label),
        updatedAt = Value(updatedAt),
        reserve = Value(reserve),
        fee = Value(fee);
  static Insertable<Addresse> custom({
    Expression<String>? addressId,
    Expression<String>? type,
    Expression<String>? assetId,
    Expression<String>? destination,
    Expression<String>? label,
    Expression<int>? updatedAt,
    Expression<String>? reserve,
    Expression<String>? fee,
    Expression<String>? tag,
    Expression<String>? dust,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (addressId != null) 'address_id': addressId,
      if (type != null) 'type': type,
      if (assetId != null) 'asset_id': assetId,
      if (destination != null) 'destination': destination,
      if (label != null) 'label': label,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (reserve != null) 'reserve': reserve,
      if (fee != null) 'fee': fee,
      if (tag != null) 'tag': tag,
      if (dust != null) 'dust': dust,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AddressesCompanion copyWith(
      {Value<String>? addressId,
      Value<String>? type,
      Value<String>? assetId,
      Value<String>? destination,
      Value<String>? label,
      Value<DateTime>? updatedAt,
      Value<String>? reserve,
      Value<String>? fee,
      Value<String?>? tag,
      Value<String?>? dust,
      Value<int>? rowid}) {
    return AddressesCompanion(
      addressId: addressId ?? this.addressId,
      type: type ?? this.type,
      assetId: assetId ?? this.assetId,
      destination: destination ?? this.destination,
      label: label ?? this.label,
      updatedAt: updatedAt ?? this.updatedAt,
      reserve: reserve ?? this.reserve,
      fee: fee ?? this.fee,
      tag: tag ?? this.tag,
      dust: dust ?? this.dust,
      rowid: rowid ?? this.rowid,
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
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (updatedAt.present) {
      final converter = Addresses.$converterupdatedAt;
      map['updated_at'] = Variable<int>(converter.toSql(updatedAt.value));
    }
    if (reserve.present) {
      map['reserve'] = Variable<String>(reserve.value);
    }
    if (fee.present) {
      map['fee'] = Variable<String>(fee.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (dust.present) {
      map['dust'] = Variable<String>(dust.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AddressesCompanion(')
          ..write('addressId: $addressId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('destination: $destination, ')
          ..write('label: $label, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('reserve: $reserve, ')
          ..write('fee: $fee, ')
          ..write('tag: $tag, ')
          ..write('dust: $dust, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Apps extends Table with TableInfo<Apps, App> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Apps(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _appNumberMeta =
      const VerificationMeta('appNumber');
  late final GeneratedColumn<String> appNumber = GeneratedColumn<String>(
      'app_number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _homeUriMeta =
      const VerificationMeta('homeUri');
  late final GeneratedColumn<String> homeUri = GeneratedColumn<String>(
      'home_uri', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _redirectUriMeta =
      const VerificationMeta('redirectUri');
  late final GeneratedColumn<String> redirectUri = GeneratedColumn<String>(
      'redirect_uri', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _iconUrlMeta =
      const VerificationMeta('iconUrl');
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
      'icon_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _appSecretMeta =
      const VerificationMeta('appSecret');
  late final GeneratedColumn<String> appSecret = GeneratedColumn<String>(
      'app_secret', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _capabilitiesMeta =
      const VerificationMeta('capabilities');
  late final GeneratedColumn<String> capabilities = GeneratedColumn<String>(
      'capabilities', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _creatorIdMeta =
      const VerificationMeta('creatorId');
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
      'creator_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _resourcePatternsMeta =
      const VerificationMeta('resourcePatterns');
  late final GeneratedColumn<String> resourcePatterns = GeneratedColumn<String>(
      'resource_patterns', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(Apps.$converterupdatedAtn);
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
  String get aliasedName => _alias ?? 'apps';
  @override
  String get actualTableName => 'apps';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return App(
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id'])!,
      appNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_number'])!,
      homeUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}home_uri'])!,
      redirectUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}redirect_uri'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_url'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      appSecret: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_secret'])!,
      capabilities: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}capabilities']),
      creatorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}creator_id'])!,
      resourcePatterns: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}resource_patterns']),
      updatedAt: Apps.$converterupdatedAtn.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])),
    );
  }

  @override
  Apps createAlias(String alias) {
    return Apps(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterupdatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $converterupdatedAtn =
      NullAwareTypeConverter.wrap($converterupdatedAt);
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(app_id)'];
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
  const App(
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
      map['category'] = Variable<String>(category);
    }
    map['description'] = Variable<String>(description);
    map['app_secret'] = Variable<String>(appSecret);
    if (!nullToAbsent || capabilities != null) {
      map['capabilities'] = Variable<String>(capabilities);
    }
    map['creator_id'] = Variable<String>(creatorId);
    if (!nullToAbsent || resourcePatterns != null) {
      map['resource_patterns'] = Variable<String>(resourcePatterns);
    }
    if (!nullToAbsent || updatedAt != null) {
      final converter = Apps.$converterupdatedAtn;
      map['updated_at'] = Variable<int>(converter.toSql(updatedAt));
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
          Value<String?> category = const Value.absent(),
          String? description,
          String? appSecret,
          Value<String?> capabilities = const Value.absent(),
          String? creatorId,
          Value<String?> resourcePatterns = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      App(
        appId: appId ?? this.appId,
        appNumber: appNumber ?? this.appNumber,
        homeUri: homeUri ?? this.homeUri,
        redirectUri: redirectUri ?? this.redirectUri,
        name: name ?? this.name,
        iconUrl: iconUrl ?? this.iconUrl,
        category: category.present ? category.value : this.category,
        description: description ?? this.description,
        appSecret: appSecret ?? this.appSecret,
        capabilities:
            capabilities.present ? capabilities.value : this.capabilities,
        creatorId: creatorId ?? this.creatorId,
        resourcePatterns: resourcePatterns.present
            ? resourcePatterns.value
            : this.resourcePatterns,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
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
  int get hashCode => Object.hash(
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
      updatedAt);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
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
    this.rowid = const Value.absent(),
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
    this.rowid = const Value.absent(),
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
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? appSecret,
    Expression<String>? capabilities,
    Expression<String>? creatorId,
    Expression<String>? resourcePatterns,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
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
      if (rowid != null) 'rowid': rowid,
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
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
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
      rowid: rowid ?? this.rowid,
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
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (appSecret.present) {
      map['app_secret'] = Variable<String>(appSecret.value);
    }
    if (capabilities.present) {
      map['capabilities'] = Variable<String>(capabilities.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (resourcePatterns.present) {
      map['resource_patterns'] = Variable<String>(resourcePatterns.value);
    }
    if (updatedAt.present) {
      final converter = Apps.$converterupdatedAtn;
      map['updated_at'] = Variable<int>(converter.toSql(updatedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Circles extends Table with TableInfo<Circles, Circle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Circles(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _circleIdMeta =
      const VerificationMeta('circleId');
  late final GeneratedColumn<String> circleId = GeneratedColumn<String>(
      'circle_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(Circles.$convertercreatedAt);
  static const VerificationMeta _orderedAtMeta =
      const VerificationMeta('orderedAt');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> orderedAt =
      GeneratedColumn<int>('ordered_at', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(Circles.$converterorderedAtn);
  @override
  List<GeneratedColumn> get $columns => [circleId, name, createdAt, orderedAt];
  @override
  String get aliasedName => _alias ?? 'circles';
  @override
  String get actualTableName => 'circles';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Circle(
      circleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}circle_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: Circles.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      orderedAt: Circles.$converterorderedAtn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordered_at'])),
    );
  }

  @override
  Circles createAlias(String alias) {
    return Circles(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime, int> $converterorderedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $converterorderedAtn =
      NullAwareTypeConverter.wrap($converterorderedAt);
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(circle_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Circle extends DataClass implements Insertable<Circle> {
  final String circleId;
  final String name;
  final DateTime createdAt;
  final DateTime? orderedAt;
  const Circle(
      {required this.circleId,
      required this.name,
      required this.createdAt,
      this.orderedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['circle_id'] = Variable<String>(circleId);
    map['name'] = Variable<String>(name);
    {
      final converter = Circles.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || orderedAt != null) {
      final converter = Circles.$converterorderedAtn;
      map['ordered_at'] = Variable<int>(converter.toSql(orderedAt));
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Circle(
      circleId: serializer.fromJson<String>(json['circle_id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      orderedAt: serializer.fromJson<DateTime?>(json['ordered_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
          Value<DateTime?> orderedAt = const Value.absent()}) =>
      Circle(
        circleId: circleId ?? this.circleId,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        orderedAt: orderedAt.present ? orderedAt.value : this.orderedAt,
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
  int get hashCode => Object.hash(circleId, name, createdAt, orderedAt);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
  const CirclesCompanion({
    this.circleId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.orderedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CirclesCompanion.insert({
    required String circleId,
    required String name,
    required DateTime createdAt,
    this.orderedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : circleId = Value(circleId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Circle> custom({
    Expression<String>? circleId,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<int>? orderedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (circleId != null) 'circle_id': circleId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (orderedAt != null) 'ordered_at': orderedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CirclesCompanion copyWith(
      {Value<String>? circleId,
      Value<String>? name,
      Value<DateTime>? createdAt,
      Value<DateTime?>? orderedAt,
      Value<int>? rowid}) {
    return CirclesCompanion(
      circleId: circleId ?? this.circleId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      orderedAt: orderedAt ?? this.orderedAt,
      rowid: rowid ?? this.rowid,
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
      final converter = Circles.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (orderedAt.present) {
      final converter = Circles.$converterorderedAtn;
      map['ordered_at'] = Variable<int>(converter.toSql(orderedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CirclesCompanion(')
          ..write('circleId: $circleId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderedAt: $orderedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class FloodMessages extends Table with TableInfo<FloodMessages, FloodMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FloodMessages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(FloodMessages.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [messageId, data, createdAt];
  @override
  String get aliasedName => _alias ?? 'flood_messages';
  @override
  String get actualTableName => 'flood_messages';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FloodMessage(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      createdAt: FloodMessages.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
    );
  }

  @override
  FloodMessages createAlias(String alias) {
    return FloodMessages(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class FloodMessage extends DataClass implements Insertable<FloodMessage> {
  final String messageId;
  final String data;
  final DateTime createdAt;
  const FloodMessage(
      {required this.messageId, required this.data, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['data'] = Variable<String>(data);
    {
      final converter = FloodMessages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FloodMessage(
      messageId: serializer.fromJson<String>(json['message_id']),
      data: serializer.fromJson<String>(json['data']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
  int get hashCode => Object.hash(messageId, data, createdAt);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
  const FloodMessagesCompanion({
    this.messageId = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FloodMessagesCompanion.insert({
    required String messageId,
    required String data,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        data = Value(data),
        createdAt = Value(createdAt);
  static Insertable<FloodMessage> custom({
    Expression<String>? messageId,
    Expression<String>? data,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (data != null) 'data': data,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FloodMessagesCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? data,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return FloodMessagesCompanion(
      messageId: messageId ?? this.messageId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
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
      final converter = FloodMessages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FloodMessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Jobs extends Table with TableInfo<Jobs, Job> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Jobs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(Jobs.$convertercreatedAt);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
      'order_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _blazeMessageMeta =
      const VerificationMeta('blazeMessage');
  late final GeneratedColumn<String> blazeMessage = GeneratedColumn<String>(
      'blaze_message', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _resendMessageIdMeta =
      const VerificationMeta('resendMessageId');
  late final GeneratedColumn<String> resendMessageId = GeneratedColumn<String>(
      'resend_message_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _runCountMeta =
      const VerificationMeta('runCount');
  late final GeneratedColumn<int> runCount = GeneratedColumn<int>(
      'run_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
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
  String get aliasedName => _alias ?? 'jobs';
  @override
  String get actualTableName => 'jobs';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Job(
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      createdAt: Jobs.$convertercreatedAt.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_id']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      blazeMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blaze_message']),
      conversationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conversation_id']),
      resendMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}resend_message_id']),
      runCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}run_count'])!,
    );
  }

  @override
  Jobs createAlias(String alias) {
    return Jobs(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(job_id)'];
  @override
  bool get dontWriteConstraints => true;
}

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
  const Job(
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['job_id'] = Variable<String>(jobId);
    map['action'] = Variable<String>(action);
    {
      final converter = Jobs.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<int>(orderId);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || blazeMessage != null) {
      map['blaze_message'] = Variable<String>(blazeMessage);
    }
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    if (!nullToAbsent || resendMessageId != null) {
      map['resend_message_id'] = Variable<String>(resendMessageId);
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
          Value<int?> orderId = const Value.absent(),
          int? priority,
          Value<String?> userId = const Value.absent(),
          Value<String?> blazeMessage = const Value.absent(),
          Value<String?> conversationId = const Value.absent(),
          Value<String?> resendMessageId = const Value.absent(),
          int? runCount}) =>
      Job(
        jobId: jobId ?? this.jobId,
        action: action ?? this.action,
        createdAt: createdAt ?? this.createdAt,
        orderId: orderId.present ? orderId.value : this.orderId,
        priority: priority ?? this.priority,
        userId: userId.present ? userId.value : this.userId,
        blazeMessage:
            blazeMessage.present ? blazeMessage.value : this.blazeMessage,
        conversationId:
            conversationId.present ? conversationId.value : this.conversationId,
        resendMessageId: resendMessageId.present
            ? resendMessageId.value
            : this.resendMessageId,
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
  int get hashCode => Object.hash(jobId, action, createdAt, orderId, priority,
      userId, blazeMessage, conversationId, resendMessageId, runCount);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
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
    this.rowid = const Value.absent(),
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
    this.rowid = const Value.absent(),
  })  : jobId = Value(jobId),
        action = Value(action),
        createdAt = Value(createdAt),
        priority = Value(priority),
        runCount = Value(runCount);
  static Insertable<Job> custom({
    Expression<String>? jobId,
    Expression<String>? action,
    Expression<int>? createdAt,
    Expression<int>? orderId,
    Expression<int>? priority,
    Expression<String>? userId,
    Expression<String>? blazeMessage,
    Expression<String>? conversationId,
    Expression<String>? resendMessageId,
    Expression<int>? runCount,
    Expression<int>? rowid,
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
      if (rowid != null) 'rowid': rowid,
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
      Value<int>? runCount,
      Value<int>? rowid}) {
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
      rowid: rowid ?? this.rowid,
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
      final converter = Jobs.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (blazeMessage.present) {
      map['blaze_message'] = Variable<String>(blazeMessage.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (resendMessageId.present) {
      map['resend_message_id'] = Variable<String>(resendMessageId.value);
    }
    if (runCount.present) {
      map['run_count'] = Variable<int>(runCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('runCount: $runCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MessagesHistory extends Table
    with TableInfo<MessagesHistory, MessagesHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MessagesHistory(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [messageId];
  @override
  String get aliasedName => _alias ?? 'messages_history';
  @override
  String get actualTableName => 'messages_history';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagesHistoryData(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
    );
  }

  @override
  MessagesHistory createAlias(String alias) {
    return MessagesHistory(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class MessagesHistoryData extends DataClass
    implements Insertable<MessagesHistoryData> {
  final String messageId;
  const MessagesHistoryData({required this.messageId});
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesHistoryData(
      messageId: serializer.fromJson<String>(json['message_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
  int get hashCode => messageId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagesHistoryData && other.messageId == this.messageId);
}

class MessagesHistoryCompanion extends UpdateCompanion<MessagesHistoryData> {
  final Value<String> messageId;
  final Value<int> rowid;
  const MessagesHistoryCompanion({
    this.messageId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesHistoryCompanion.insert({
    required String messageId,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId);
  static Insertable<MessagesHistoryData> custom({
    Expression<String>? messageId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesHistoryCompanion copyWith(
      {Value<String>? messageId, Value<int>? rowid}) {
    return MessagesHistoryCompanion(
      messageId: messageId ?? this.messageId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesHistoryCompanion(')
          ..write('messageId: $messageId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Offsets extends Table with TableInfo<Offsets, Offset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Offsets(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [key, timestamp];
  @override
  String get aliasedName => _alias ?? 'offsets';
  @override
  String get actualTableName => 'offsets';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Offset(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  Offsets createAlias(String alias) {
    return Offsets(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY("key")'];
  @override
  bool get dontWriteConstraints => true;
}

class Offset extends DataClass implements Insertable<Offset> {
  final String key;
  final String timestamp;
  const Offset({required this.key, required this.timestamp});
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Offset(
      key: serializer.fromJson<String>(json['key']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
  int get hashCode => Object.hash(key, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Offset &&
          other.key == this.key &&
          other.timestamp == this.timestamp);
}

class OffsetsCompanion extends UpdateCompanion<Offset> {
  final Value<String> key;
  final Value<String> timestamp;
  final Value<int> rowid;
  const OffsetsCompanion({
    this.key = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OffsetsCompanion.insert({
    required String key,
    required String timestamp,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        timestamp = Value(timestamp);
  static Insertable<Offset> custom({
    Expression<String>? key,
    Expression<String>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OffsetsCompanion copyWith(
      {Value<String>? key, Value<String>? timestamp, Value<int>? rowid}) {
    return OffsetsCompanion(
      key: key ?? this.key,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OffsetsCompanion(')
          ..write('key: $key, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SentSessionSenderKeys extends Table
    with TableInfo<SentSessionSenderKeys, SentSessionSenderKey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SentSessionSenderKeys(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _sentToServerMeta =
      const VerificationMeta('sentToServer');
  late final GeneratedColumn<int> sentToServer = GeneratedColumn<int>(
      'sent_to_server', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _senderKeyIdMeta =
      const VerificationMeta('senderKeyId');
  late final GeneratedColumn<int> senderKeyId = GeneratedColumn<int>(
      'sender_key_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(SentSessionSenderKeys.$convertercreatedAtn);
  @override
  List<GeneratedColumn> get $columns =>
      [conversationId, userId, sessionId, sentToServer, senderKeyId, createdAt];
  @override
  String get aliasedName => _alias ?? 'sent_session_sender_keys';
  @override
  String get actualTableName => 'sent_session_sender_keys';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SentSessionSenderKey(
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      sentToServer: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sent_to_server'])!,
      senderKeyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sender_key_id']),
      createdAt: SentSessionSenderKeys.$convertercreatedAtn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}created_at'])),
    );
  }

  @override
  SentSessionSenderKeys createAlias(String alias) {
    return SentSessionSenderKeys(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $convertercreatedAtn =
      NullAwareTypeConverter.wrap($convertercreatedAt);
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(conversation_id, user_id, session_id)'];
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
  const SentSessionSenderKey(
      {required this.conversationId,
      required this.userId,
      required this.sessionId,
      required this.sentToServer,
      this.senderKeyId,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['user_id'] = Variable<String>(userId);
    map['session_id'] = Variable<String>(sessionId);
    map['sent_to_server'] = Variable<int>(sentToServer);
    if (!nullToAbsent || senderKeyId != null) {
      map['sender_key_id'] = Variable<int>(senderKeyId);
    }
    if (!nullToAbsent || createdAt != null) {
      final converter = SentSessionSenderKeys.$convertercreatedAtn;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
          Value<int?> senderKeyId = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      SentSessionSenderKey(
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        sessionId: sessionId ?? this.sessionId,
        sentToServer: sentToServer ?? this.sentToServer,
        senderKeyId: senderKeyId.present ? senderKeyId.value : this.senderKeyId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
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
  int get hashCode => Object.hash(
      conversationId, userId, sessionId, sentToServer, senderKeyId, createdAt);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
  const SentSessionSenderKeysCompanion({
    this.conversationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sentToServer = const Value.absent(),
    this.senderKeyId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SentSessionSenderKeysCompanion.insert({
    required String conversationId,
    required String userId,
    required String sessionId,
    required int sentToServer,
    this.senderKeyId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : conversationId = Value(conversationId),
        userId = Value(userId),
        sessionId = Value(sessionId),
        sentToServer = Value(sentToServer);
  static Insertable<SentSessionSenderKey> custom({
    Expression<String>? conversationId,
    Expression<String>? userId,
    Expression<String>? sessionId,
    Expression<int>? sentToServer,
    Expression<int>? senderKeyId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (sentToServer != null) 'sent_to_server': sentToServer,
      if (senderKeyId != null) 'sender_key_id': senderKeyId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SentSessionSenderKeysCompanion copyWith(
      {Value<String>? conversationId,
      Value<String>? userId,
      Value<String>? sessionId,
      Value<int>? sentToServer,
      Value<int?>? senderKeyId,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return SentSessionSenderKeysCompanion(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      sentToServer: sentToServer ?? this.sentToServer,
      senderKeyId: senderKeyId ?? this.senderKeyId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
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
      map['sender_key_id'] = Variable<int>(senderKeyId.value);
    }
    if (createdAt.present) {
      final converter = SentSessionSenderKeys.$convertercreatedAtn;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class StickerAlbums extends Table with TableInfo<StickerAlbums, StickerAlbum> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StickerAlbums(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _iconUrlMeta =
      const VerificationMeta('iconUrl');
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
      'icon_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(StickerAlbums.$convertercreatedAt);
  static const VerificationMeta _updateAtMeta =
      const VerificationMeta('updateAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> updateAt =
      GeneratedColumn<int>('update_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(StickerAlbums.$converterupdateAt);
  static const VerificationMeta _orderedAtMeta =
      const VerificationMeta('orderedAt');
  late final GeneratedColumn<int> orderedAt = GeneratedColumn<int>(
      'ordered_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _bannerMeta = const VerificationMeta('banner');
  late final GeneratedColumn<String> banner = GeneratedColumn<String>(
      'banner', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _addedMeta = const VerificationMeta('added');
  late final GeneratedColumn<bool> added = GeneratedColumn<bool>(
      'added', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT FALSE',
      defaultValue: const CustomExpression('FALSE'));
  static const VerificationMeta _isVerifiedMeta =
      const VerificationMeta('isVerified');
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
      'is_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT FALSE',
      defaultValue: const CustomExpression('FALSE'));
  @override
  List<GeneratedColumn> get $columns => [
        albumId,
        name,
        iconUrl,
        createdAt,
        updateAt,
        orderedAt,
        userId,
        category,
        description,
        banner,
        added,
        isVerified
      ];
  @override
  String get aliasedName => _alias ?? 'sticker_albums';
  @override
  String get actualTableName => 'sticker_albums';
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
    if (data.containsKey('ordered_at')) {
      context.handle(_orderedAtMeta,
          orderedAt.isAcceptableOrUnknown(data['ordered_at']!, _orderedAtMeta));
    }
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
    if (data.containsKey('banner')) {
      context.handle(_bannerMeta,
          banner.isAcceptableOrUnknown(data['banner']!, _bannerMeta));
    }
    if (data.containsKey('added')) {
      context.handle(
          _addedMeta, added.isAcceptableOrUnknown(data['added']!, _addedMeta));
    }
    if (data.containsKey('is_verified')) {
      context.handle(
          _isVerifiedMeta,
          isVerified.isAcceptableOrUnknown(
              data['is_verified']!, _isVerifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {albumId};
  @override
  StickerAlbum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StickerAlbum(
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_url'])!,
      createdAt: StickerAlbums.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updateAt: StickerAlbums.$converterupdateAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}update_at'])!),
      orderedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordered_at'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      banner: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}banner']),
      added: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}added']),
      isVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_verified'])!,
    );
  }

  @override
  StickerAlbums createAlias(String alias) {
    return StickerAlbums(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime, int> $converterupdateAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(album_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class StickerAlbum extends DataClass implements Insertable<StickerAlbum> {
  final String albumId;
  final String name;
  final String iconUrl;
  final DateTime createdAt;
  final DateTime updateAt;
  final int orderedAt;
  final String userId;
  final String category;
  final String description;
  final String? banner;
  final bool? added;
  final bool isVerified;
  const StickerAlbum(
      {required this.albumId,
      required this.name,
      required this.iconUrl,
      required this.createdAt,
      required this.updateAt,
      required this.orderedAt,
      required this.userId,
      required this.category,
      required this.description,
      this.banner,
      this.added,
      required this.isVerified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['album_id'] = Variable<String>(albumId);
    map['name'] = Variable<String>(name);
    map['icon_url'] = Variable<String>(iconUrl);
    {
      final converter = StickerAlbums.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    {
      final converter = StickerAlbums.$converterupdateAt;
      map['update_at'] = Variable<int>(converter.toSql(updateAt));
    }
    map['ordered_at'] = Variable<int>(orderedAt);
    map['user_id'] = Variable<String>(userId);
    map['category'] = Variable<String>(category);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || banner != null) {
      map['banner'] = Variable<String>(banner);
    }
    if (!nullToAbsent || added != null) {
      map['added'] = Variable<bool>(added);
    }
    map['is_verified'] = Variable<bool>(isVerified);
    return map;
  }

  StickerAlbumsCompanion toCompanion(bool nullToAbsent) {
    return StickerAlbumsCompanion(
      albumId: Value(albumId),
      name: Value(name),
      iconUrl: Value(iconUrl),
      createdAt: Value(createdAt),
      updateAt: Value(updateAt),
      orderedAt: Value(orderedAt),
      userId: Value(userId),
      category: Value(category),
      description: Value(description),
      banner:
          banner == null && nullToAbsent ? const Value.absent() : Value(banner),
      added:
          added == null && nullToAbsent ? const Value.absent() : Value(added),
      isVerified: Value(isVerified),
    );
  }

  factory StickerAlbum.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StickerAlbum(
      albumId: serializer.fromJson<String>(json['album_id']),
      name: serializer.fromJson<String>(json['name']),
      iconUrl: serializer.fromJson<String>(json['icon_url']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updateAt: serializer.fromJson<DateTime>(json['update_at']),
      orderedAt: serializer.fromJson<int>(json['ordered_at']),
      userId: serializer.fromJson<String>(json['user_id']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      banner: serializer.fromJson<String?>(json['banner']),
      added: serializer.fromJson<bool?>(json['added']),
      isVerified: serializer.fromJson<bool>(json['is_verified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'album_id': serializer.toJson<String>(albumId),
      'name': serializer.toJson<String>(name),
      'icon_url': serializer.toJson<String>(iconUrl),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'update_at': serializer.toJson<DateTime>(updateAt),
      'ordered_at': serializer.toJson<int>(orderedAt),
      'user_id': serializer.toJson<String>(userId),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String>(description),
      'banner': serializer.toJson<String?>(banner),
      'added': serializer.toJson<bool?>(added),
      'is_verified': serializer.toJson<bool>(isVerified),
    };
  }

  StickerAlbum copyWith(
          {String? albumId,
          String? name,
          String? iconUrl,
          DateTime? createdAt,
          DateTime? updateAt,
          int? orderedAt,
          String? userId,
          String? category,
          String? description,
          Value<String?> banner = const Value.absent(),
          Value<bool?> added = const Value.absent(),
          bool? isVerified}) =>
      StickerAlbum(
        albumId: albumId ?? this.albumId,
        name: name ?? this.name,
        iconUrl: iconUrl ?? this.iconUrl,
        createdAt: createdAt ?? this.createdAt,
        updateAt: updateAt ?? this.updateAt,
        orderedAt: orderedAt ?? this.orderedAt,
        userId: userId ?? this.userId,
        category: category ?? this.category,
        description: description ?? this.description,
        banner: banner.present ? banner.value : this.banner,
        added: added.present ? added.value : this.added,
        isVerified: isVerified ?? this.isVerified,
      );
  @override
  String toString() {
    return (StringBuffer('StickerAlbum(')
          ..write('albumId: $albumId, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updateAt: $updateAt, ')
          ..write('orderedAt: $orderedAt, ')
          ..write('userId: $userId, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('banner: $banner, ')
          ..write('added: $added, ')
          ..write('isVerified: $isVerified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(albumId, name, iconUrl, createdAt, updateAt,
      orderedAt, userId, category, description, banner, added, isVerified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StickerAlbum &&
          other.albumId == this.albumId &&
          other.name == this.name &&
          other.iconUrl == this.iconUrl &&
          other.createdAt == this.createdAt &&
          other.updateAt == this.updateAt &&
          other.orderedAt == this.orderedAt &&
          other.userId == this.userId &&
          other.category == this.category &&
          other.description == this.description &&
          other.banner == this.banner &&
          other.added == this.added &&
          other.isVerified == this.isVerified);
}

class StickerAlbumsCompanion extends UpdateCompanion<StickerAlbum> {
  final Value<String> albumId;
  final Value<String> name;
  final Value<String> iconUrl;
  final Value<DateTime> createdAt;
  final Value<DateTime> updateAt;
  final Value<int> orderedAt;
  final Value<String> userId;
  final Value<String> category;
  final Value<String> description;
  final Value<String?> banner;
  final Value<bool?> added;
  final Value<bool> isVerified;
  final Value<int> rowid;
  const StickerAlbumsCompanion({
    this.albumId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updateAt = const Value.absent(),
    this.orderedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.banner = const Value.absent(),
    this.added = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StickerAlbumsCompanion.insert({
    required String albumId,
    required String name,
    required String iconUrl,
    required DateTime createdAt,
    required DateTime updateAt,
    this.orderedAt = const Value.absent(),
    required String userId,
    required String category,
    required String description,
    this.banner = const Value.absent(),
    this.added = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : albumId = Value(albumId),
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
    Expression<int>? createdAt,
    Expression<int>? updateAt,
    Expression<int>? orderedAt,
    Expression<String>? userId,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? banner,
    Expression<bool>? added,
    Expression<bool>? isVerified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (albumId != null) 'album_id': albumId,
      if (name != null) 'name': name,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (updateAt != null) 'update_at': updateAt,
      if (orderedAt != null) 'ordered_at': orderedAt,
      if (userId != null) 'user_id': userId,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (banner != null) 'banner': banner,
      if (added != null) 'added': added,
      if (isVerified != null) 'is_verified': isVerified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StickerAlbumsCompanion copyWith(
      {Value<String>? albumId,
      Value<String>? name,
      Value<String>? iconUrl,
      Value<DateTime>? createdAt,
      Value<DateTime>? updateAt,
      Value<int>? orderedAt,
      Value<String>? userId,
      Value<String>? category,
      Value<String>? description,
      Value<String?>? banner,
      Value<bool?>? added,
      Value<bool>? isVerified,
      Value<int>? rowid}) {
    return StickerAlbumsCompanion(
      albumId: albumId ?? this.albumId,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
      updateAt: updateAt ?? this.updateAt,
      orderedAt: orderedAt ?? this.orderedAt,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      description: description ?? this.description,
      banner: banner ?? this.banner,
      added: added ?? this.added,
      isVerified: isVerified ?? this.isVerified,
      rowid: rowid ?? this.rowid,
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
      final converter = StickerAlbums.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (updateAt.present) {
      final converter = StickerAlbums.$converterupdateAt;
      map['update_at'] = Variable<int>(converter.toSql(updateAt.value));
    }
    if (orderedAt.present) {
      map['ordered_at'] = Variable<int>(orderedAt.value);
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
    if (banner.present) {
      map['banner'] = Variable<String>(banner.value);
    }
    if (added.present) {
      map['added'] = Variable<bool>(added.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
          ..write('orderedAt: $orderedAt, ')
          ..write('userId: $userId, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('banner: $banner, ')
          ..write('added: $added, ')
          ..write('isVerified: $isVerified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class StickerRelationships extends Table
    with TableInfo<StickerRelationships, StickerRelationship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StickerRelationships(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _stickerIdMeta =
      const VerificationMeta('stickerId');
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
      'sticker_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [albumId, stickerId];
  @override
  String get aliasedName => _alias ?? 'sticker_relationships';
  @override
  String get actualTableName => 'sticker_relationships';
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StickerRelationship(
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id'])!,
      stickerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sticker_id'])!,
    );
  }

  @override
  StickerRelationships createAlias(String alias) {
    return StickerRelationships(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(album_id, sticker_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class StickerRelationship extends DataClass
    implements Insertable<StickerRelationship> {
  final String albumId;
  final String stickerId;
  const StickerRelationship({required this.albumId, required this.stickerId});
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
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StickerRelationship(
      albumId: serializer.fromJson<String>(json['album_id']),
      stickerId: serializer.fromJson<String>(json['sticker_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
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
  int get hashCode => Object.hash(albumId, stickerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StickerRelationship &&
          other.albumId == this.albumId &&
          other.stickerId == this.stickerId);
}

class StickerRelationshipsCompanion
    extends UpdateCompanion<StickerRelationship> {
  final Value<String> albumId;
  final Value<String> stickerId;
  final Value<int> rowid;
  const StickerRelationshipsCompanion({
    this.albumId = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StickerRelationshipsCompanion.insert({
    required String albumId,
    required String stickerId,
    this.rowid = const Value.absent(),
  })  : albumId = Value(albumId),
        stickerId = Value(stickerId);
  static Insertable<StickerRelationship> custom({
    Expression<String>? albumId,
    Expression<String>? stickerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (albumId != null) 'album_id': albumId,
      if (stickerId != null) 'sticker_id': stickerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StickerRelationshipsCompanion copyWith(
      {Value<String>? albumId, Value<String>? stickerId, Value<int>? rowid}) {
    return StickerRelationshipsCompanion(
      albumId: albumId ?? this.albumId,
      stickerId: stickerId ?? this.stickerId,
      rowid: rowid ?? this.rowid,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StickerRelationshipsCompanion(')
          ..write('albumId: $albumId, ')
          ..write('stickerId: $stickerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TranscriptMessages extends Table
    with TableInfo<TranscriptMessages, TranscriptMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TranscriptMessages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transcriptIdMeta =
      const VerificationMeta('transcriptId');
  late final GeneratedColumn<String> transcriptId = GeneratedColumn<String>(
      'transcript_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _userFullNameMeta =
      const VerificationMeta('userFullName');
  late final GeneratedColumn<String> userFullName = GeneratedColumn<String>(
      'user_full_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(TranscriptMessages.$convertercreatedAt);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaUrlMeta =
      const VerificationMeta('mediaUrl');
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
      'media_url', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaNameMeta =
      const VerificationMeta('mediaName');
  late final GeneratedColumn<String> mediaName = GeneratedColumn<String>(
      'media_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaSizeMeta =
      const VerificationMeta('mediaSize');
  late final GeneratedColumn<int> mediaSize = GeneratedColumn<int>(
      'media_size', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaWidthMeta =
      const VerificationMeta('mediaWidth');
  late final GeneratedColumn<int> mediaWidth = GeneratedColumn<int>(
      'media_width', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaHeightMeta =
      const VerificationMeta('mediaHeight');
  late final GeneratedColumn<int> mediaHeight = GeneratedColumn<int>(
      'media_height', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaMimeTypeMeta =
      const VerificationMeta('mediaMimeType');
  late final GeneratedColumn<String> mediaMimeType = GeneratedColumn<String>(
      'media_mime_type', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaDurationMeta =
      const VerificationMeta('mediaDuration');
  late final GeneratedColumn<String> mediaDuration = GeneratedColumn<String>(
      'media_duration', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaStatusMeta =
      const VerificationMeta('mediaStatus');
  late final GeneratedColumnWithTypeConverter<MediaStatus?, String>
      mediaStatus = GeneratedColumn<String>('media_status', aliasedName, true,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<MediaStatus?>(
              TranscriptMessages.$convertermediaStatus);
  static const VerificationMeta _mediaWaveformMeta =
      const VerificationMeta('mediaWaveform');
  late final GeneratedColumn<String> mediaWaveform = GeneratedColumn<String>(
      'media_waveform', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _thumbImageMeta =
      const VerificationMeta('thumbImage');
  late final GeneratedColumn<String> thumbImage = GeneratedColumn<String>(
      'thumb_image', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _thumbUrlMeta =
      const VerificationMeta('thumbUrl');
  late final GeneratedColumn<String> thumbUrl = GeneratedColumn<String>(
      'thumb_url', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaKeyMeta =
      const VerificationMeta('mediaKey');
  late final GeneratedColumn<String> mediaKey = GeneratedColumn<String>(
      'media_key', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaDigestMeta =
      const VerificationMeta('mediaDigest');
  late final GeneratedColumn<String> mediaDigest = GeneratedColumn<String>(
      'media_digest', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mediaCreatedAtMeta =
      const VerificationMeta('mediaCreatedAt');
  late final GeneratedColumnWithTypeConverter<DateTime?, int> mediaCreatedAt =
      GeneratedColumn<int>('media_created_at', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<DateTime?>(
              TranscriptMessages.$convertermediaCreatedAtn);
  static const VerificationMeta _stickerIdMeta =
      const VerificationMeta('stickerId');
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
      'sticker_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _sharedUserIdMeta =
      const VerificationMeta('sharedUserId');
  late final GeneratedColumn<String> sharedUserId = GeneratedColumn<String>(
      'shared_user_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _mentionsMeta =
      const VerificationMeta('mentions');
  late final GeneratedColumn<String> mentions = GeneratedColumn<String>(
      'mentions', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _quoteIdMeta =
      const VerificationMeta('quoteId');
  late final GeneratedColumn<String> quoteId = GeneratedColumn<String>(
      'quote_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _quoteContentMeta =
      const VerificationMeta('quoteContent');
  late final GeneratedColumn<String> quoteContent = GeneratedColumn<String>(
      'quote_content', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [
        transcriptId,
        messageId,
        userId,
        userFullName,
        category,
        createdAt,
        content,
        mediaUrl,
        mediaName,
        mediaSize,
        mediaWidth,
        mediaHeight,
        mediaMimeType,
        mediaDuration,
        mediaStatus,
        mediaWaveform,
        thumbImage,
        thumbUrl,
        mediaKey,
        mediaDigest,
        mediaCreatedAt,
        stickerId,
        sharedUserId,
        mentions,
        quoteId,
        quoteContent,
        caption
      ];
  @override
  String get aliasedName => _alias ?? 'transcript_messages';
  @override
  String get actualTableName => 'transcript_messages';
  @override
  VerificationContext validateIntegrity(Insertable<TranscriptMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transcript_id')) {
      context.handle(
          _transcriptIdMeta,
          transcriptId.isAcceptableOrUnknown(
              data['transcript_id']!, _transcriptIdMeta));
    } else if (isInserting) {
      context.missing(_transcriptIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('user_full_name')) {
      context.handle(
          _userFullNameMeta,
          userFullName.isAcceptableOrUnknown(
              data['user_full_name']!, _userFullNameMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('media_url')) {
      context.handle(_mediaUrlMeta,
          mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta));
    }
    if (data.containsKey('media_name')) {
      context.handle(_mediaNameMeta,
          mediaName.isAcceptableOrUnknown(data['media_name']!, _mediaNameMeta));
    }
    if (data.containsKey('media_size')) {
      context.handle(_mediaSizeMeta,
          mediaSize.isAcceptableOrUnknown(data['media_size']!, _mediaSizeMeta));
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
    if (data.containsKey('media_mime_type')) {
      context.handle(
          _mediaMimeTypeMeta,
          mediaMimeType.isAcceptableOrUnknown(
              data['media_mime_type']!, _mediaMimeTypeMeta));
    }
    if (data.containsKey('media_duration')) {
      context.handle(
          _mediaDurationMeta,
          mediaDuration.isAcceptableOrUnknown(
              data['media_duration']!, _mediaDurationMeta));
    }
    context.handle(_mediaStatusMeta, const VerificationResult.success());
    if (data.containsKey('media_waveform')) {
      context.handle(
          _mediaWaveformMeta,
          mediaWaveform.isAcceptableOrUnknown(
              data['media_waveform']!, _mediaWaveformMeta));
    }
    if (data.containsKey('thumb_image')) {
      context.handle(
          _thumbImageMeta,
          thumbImage.isAcceptableOrUnknown(
              data['thumb_image']!, _thumbImageMeta));
    }
    if (data.containsKey('thumb_url')) {
      context.handle(_thumbUrlMeta,
          thumbUrl.isAcceptableOrUnknown(data['thumb_url']!, _thumbUrlMeta));
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
    context.handle(_mediaCreatedAtMeta, const VerificationResult.success());
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
    if (data.containsKey('mentions')) {
      context.handle(_mentionsMeta,
          mentions.isAcceptableOrUnknown(data['mentions']!, _mentionsMeta));
    }
    if (data.containsKey('quote_id')) {
      context.handle(_quoteIdMeta,
          quoteId.isAcceptableOrUnknown(data['quote_id']!, _quoteIdMeta));
    }
    if (data.containsKey('quote_content')) {
      context.handle(
          _quoteContentMeta,
          quoteContent.isAcceptableOrUnknown(
              data['quote_content']!, _quoteContentMeta));
    }
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transcriptId, messageId};
  @override
  TranscriptMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranscriptMessage(
      transcriptId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcript_id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      userFullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_full_name']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      createdAt: TranscriptMessages.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      mediaUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_url']),
      mediaName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_name']),
      mediaSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_size']),
      mediaWidth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_width']),
      mediaHeight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_height']),
      mediaMimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_mime_type']),
      mediaDuration: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_duration']),
      mediaStatus: TranscriptMessages.$convertermediaStatus.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}media_status'])),
      mediaWaveform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_waveform']),
      thumbImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumb_image']),
      thumbUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumb_url']),
      mediaKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_key']),
      mediaDigest: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_digest']),
      mediaCreatedAt: TranscriptMessages.$convertermediaCreatedAtn.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}media_created_at'])),
      stickerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sticker_id']),
      sharedUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shared_user_id']),
      mentions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mentions']),
      quoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quote_id']),
      quoteContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quote_content']),
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption']),
    );
  }

  @override
  TranscriptMessages createAlias(String alias) {
    return TranscriptMessages(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  static TypeConverter<MediaStatus?, String?> $convertermediaStatus =
      const MediaStatusTypeConverter();
  static TypeConverter<DateTime, int> $convertermediaCreatedAt =
      const MillisDateConverter();
  static TypeConverter<DateTime?, int?> $convertermediaCreatedAtn =
      NullAwareTypeConverter.wrap($convertermediaCreatedAt);
  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(transcript_id, message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class TranscriptMessage extends DataClass
    implements Insertable<TranscriptMessage> {
  final String transcriptId;
  final String messageId;
  final String? userId;
  final String? userFullName;
  final String category;
  final DateTime createdAt;
  final String? content;
  final String? mediaUrl;
  final String? mediaName;
  final int? mediaSize;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? mediaMimeType;
  final String? mediaDuration;
  final MediaStatus? mediaStatus;
  final String? mediaWaveform;
  final String? thumbImage;
  final String? thumbUrl;
  final String? mediaKey;
  final String? mediaDigest;
  final DateTime? mediaCreatedAt;
  final String? stickerId;
  final String? sharedUserId;
  final String? mentions;
  final String? quoteId;
  final String? quoteContent;
  final String? caption;
  const TranscriptMessage(
      {required this.transcriptId,
      required this.messageId,
      this.userId,
      this.userFullName,
      required this.category,
      required this.createdAt,
      this.content,
      this.mediaUrl,
      this.mediaName,
      this.mediaSize,
      this.mediaWidth,
      this.mediaHeight,
      this.mediaMimeType,
      this.mediaDuration,
      this.mediaStatus,
      this.mediaWaveform,
      this.thumbImage,
      this.thumbUrl,
      this.mediaKey,
      this.mediaDigest,
      this.mediaCreatedAt,
      this.stickerId,
      this.sharedUserId,
      this.mentions,
      this.quoteId,
      this.quoteContent,
      this.caption});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transcript_id'] = Variable<String>(transcriptId);
    map['message_id'] = Variable<String>(messageId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || userFullName != null) {
      map['user_full_name'] = Variable<String>(userFullName);
    }
    map['category'] = Variable<String>(category);
    {
      final converter = TranscriptMessages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || mediaName != null) {
      map['media_name'] = Variable<String>(mediaName);
    }
    if (!nullToAbsent || mediaSize != null) {
      map['media_size'] = Variable<int>(mediaSize);
    }
    if (!nullToAbsent || mediaWidth != null) {
      map['media_width'] = Variable<int>(mediaWidth);
    }
    if (!nullToAbsent || mediaHeight != null) {
      map['media_height'] = Variable<int>(mediaHeight);
    }
    if (!nullToAbsent || mediaMimeType != null) {
      map['media_mime_type'] = Variable<String>(mediaMimeType);
    }
    if (!nullToAbsent || mediaDuration != null) {
      map['media_duration'] = Variable<String>(mediaDuration);
    }
    if (!nullToAbsent || mediaStatus != null) {
      final converter = TranscriptMessages.$convertermediaStatus;
      map['media_status'] = Variable<String>(converter.toSql(mediaStatus));
    }
    if (!nullToAbsent || mediaWaveform != null) {
      map['media_waveform'] = Variable<String>(mediaWaveform);
    }
    if (!nullToAbsent || thumbImage != null) {
      map['thumb_image'] = Variable<String>(thumbImage);
    }
    if (!nullToAbsent || thumbUrl != null) {
      map['thumb_url'] = Variable<String>(thumbUrl);
    }
    if (!nullToAbsent || mediaKey != null) {
      map['media_key'] = Variable<String>(mediaKey);
    }
    if (!nullToAbsent || mediaDigest != null) {
      map['media_digest'] = Variable<String>(mediaDigest);
    }
    if (!nullToAbsent || mediaCreatedAt != null) {
      final converter = TranscriptMessages.$convertermediaCreatedAtn;
      map['media_created_at'] = Variable<int>(converter.toSql(mediaCreatedAt));
    }
    if (!nullToAbsent || stickerId != null) {
      map['sticker_id'] = Variable<String>(stickerId);
    }
    if (!nullToAbsent || sharedUserId != null) {
      map['shared_user_id'] = Variable<String>(sharedUserId);
    }
    if (!nullToAbsent || mentions != null) {
      map['mentions'] = Variable<String>(mentions);
    }
    if (!nullToAbsent || quoteId != null) {
      map['quote_id'] = Variable<String>(quoteId);
    }
    if (!nullToAbsent || quoteContent != null) {
      map['quote_content'] = Variable<String>(quoteContent);
    }
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    return map;
  }

  TranscriptMessagesCompanion toCompanion(bool nullToAbsent) {
    return TranscriptMessagesCompanion(
      transcriptId: Value(transcriptId),
      messageId: Value(messageId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      userFullName: userFullName == null && nullToAbsent
          ? const Value.absent()
          : Value(userFullName),
      category: Value(category),
      createdAt: Value(createdAt),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      mediaName: mediaName == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaName),
      mediaSize: mediaSize == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaSize),
      mediaWidth: mediaWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaWidth),
      mediaHeight: mediaHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaHeight),
      mediaMimeType: mediaMimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaMimeType),
      mediaDuration: mediaDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaDuration),
      mediaStatus: mediaStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaStatus),
      mediaWaveform: mediaWaveform == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaWaveform),
      thumbImage: thumbImage == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbImage),
      thumbUrl: thumbUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbUrl),
      mediaKey: mediaKey == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaKey),
      mediaDigest: mediaDigest == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaDigest),
      mediaCreatedAt: mediaCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaCreatedAt),
      stickerId: stickerId == null && nullToAbsent
          ? const Value.absent()
          : Value(stickerId),
      sharedUserId: sharedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedUserId),
      mentions: mentions == null && nullToAbsent
          ? const Value.absent()
          : Value(mentions),
      quoteId: quoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(quoteId),
      quoteContent: quoteContent == null && nullToAbsent
          ? const Value.absent()
          : Value(quoteContent),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
    );
  }

  factory TranscriptMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranscriptMessage(
      transcriptId: serializer.fromJson<String>(json['transcript_id']),
      messageId: serializer.fromJson<String>(json['message_id']),
      userId: serializer.fromJson<String?>(json['user_id']),
      userFullName: serializer.fromJson<String?>(json['user_full_name']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      content: serializer.fromJson<String?>(json['content']),
      mediaUrl: serializer.fromJson<String?>(json['media_url']),
      mediaName: serializer.fromJson<String?>(json['media_name']),
      mediaSize: serializer.fromJson<int?>(json['media_size']),
      mediaWidth: serializer.fromJson<int?>(json['media_width']),
      mediaHeight: serializer.fromJson<int?>(json['media_height']),
      mediaMimeType: serializer.fromJson<String?>(json['media_mime_type']),
      mediaDuration: serializer.fromJson<String?>(json['media_duration']),
      mediaStatus: serializer.fromJson<MediaStatus?>(json['media_status']),
      mediaWaveform: serializer.fromJson<String?>(json['media_waveform']),
      thumbImage: serializer.fromJson<String?>(json['thumb_image']),
      thumbUrl: serializer.fromJson<String?>(json['thumb_url']),
      mediaKey: serializer.fromJson<String?>(json['media_key']),
      mediaDigest: serializer.fromJson<String?>(json['media_digest']),
      mediaCreatedAt: serializer.fromJson<DateTime?>(json['media_created_at']),
      stickerId: serializer.fromJson<String?>(json['sticker_id']),
      sharedUserId: serializer.fromJson<String?>(json['shared_user_id']),
      mentions: serializer.fromJson<String?>(json['mentions']),
      quoteId: serializer.fromJson<String?>(json['quote_id']),
      quoteContent: serializer.fromJson<String?>(json['quote_content']),
      caption: serializer.fromJson<String?>(json['caption']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transcript_id': serializer.toJson<String>(transcriptId),
      'message_id': serializer.toJson<String>(messageId),
      'user_id': serializer.toJson<String?>(userId),
      'user_full_name': serializer.toJson<String?>(userFullName),
      'category': serializer.toJson<String>(category),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'content': serializer.toJson<String?>(content),
      'media_url': serializer.toJson<String?>(mediaUrl),
      'media_name': serializer.toJson<String?>(mediaName),
      'media_size': serializer.toJson<int?>(mediaSize),
      'media_width': serializer.toJson<int?>(mediaWidth),
      'media_height': serializer.toJson<int?>(mediaHeight),
      'media_mime_type': serializer.toJson<String?>(mediaMimeType),
      'media_duration': serializer.toJson<String?>(mediaDuration),
      'media_status': serializer.toJson<MediaStatus?>(mediaStatus),
      'media_waveform': serializer.toJson<String?>(mediaWaveform),
      'thumb_image': serializer.toJson<String?>(thumbImage),
      'thumb_url': serializer.toJson<String?>(thumbUrl),
      'media_key': serializer.toJson<String?>(mediaKey),
      'media_digest': serializer.toJson<String?>(mediaDigest),
      'media_created_at': serializer.toJson<DateTime?>(mediaCreatedAt),
      'sticker_id': serializer.toJson<String?>(stickerId),
      'shared_user_id': serializer.toJson<String?>(sharedUserId),
      'mentions': serializer.toJson<String?>(mentions),
      'quote_id': serializer.toJson<String?>(quoteId),
      'quote_content': serializer.toJson<String?>(quoteContent),
      'caption': serializer.toJson<String?>(caption),
    };
  }

  TranscriptMessage copyWith(
          {String? transcriptId,
          String? messageId,
          Value<String?> userId = const Value.absent(),
          Value<String?> userFullName = const Value.absent(),
          String? category,
          DateTime? createdAt,
          Value<String?> content = const Value.absent(),
          Value<String?> mediaUrl = const Value.absent(),
          Value<String?> mediaName = const Value.absent(),
          Value<int?> mediaSize = const Value.absent(),
          Value<int?> mediaWidth = const Value.absent(),
          Value<int?> mediaHeight = const Value.absent(),
          Value<String?> mediaMimeType = const Value.absent(),
          Value<String?> mediaDuration = const Value.absent(),
          Value<MediaStatus?> mediaStatus = const Value.absent(),
          Value<String?> mediaWaveform = const Value.absent(),
          Value<String?> thumbImage = const Value.absent(),
          Value<String?> thumbUrl = const Value.absent(),
          Value<String?> mediaKey = const Value.absent(),
          Value<String?> mediaDigest = const Value.absent(),
          Value<DateTime?> mediaCreatedAt = const Value.absent(),
          Value<String?> stickerId = const Value.absent(),
          Value<String?> sharedUserId = const Value.absent(),
          Value<String?> mentions = const Value.absent(),
          Value<String?> quoteId = const Value.absent(),
          Value<String?> quoteContent = const Value.absent(),
          Value<String?> caption = const Value.absent()}) =>
      TranscriptMessage(
        transcriptId: transcriptId ?? this.transcriptId,
        messageId: messageId ?? this.messageId,
        userId: userId.present ? userId.value : this.userId,
        userFullName:
            userFullName.present ? userFullName.value : this.userFullName,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
        content: content.present ? content.value : this.content,
        mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
        mediaName: mediaName.present ? mediaName.value : this.mediaName,
        mediaSize: mediaSize.present ? mediaSize.value : this.mediaSize,
        mediaWidth: mediaWidth.present ? mediaWidth.value : this.mediaWidth,
        mediaHeight: mediaHeight.present ? mediaHeight.value : this.mediaHeight,
        mediaMimeType:
            mediaMimeType.present ? mediaMimeType.value : this.mediaMimeType,
        mediaDuration:
            mediaDuration.present ? mediaDuration.value : this.mediaDuration,
        mediaStatus: mediaStatus.present ? mediaStatus.value : this.mediaStatus,
        mediaWaveform:
            mediaWaveform.present ? mediaWaveform.value : this.mediaWaveform,
        thumbImage: thumbImage.present ? thumbImage.value : this.thumbImage,
        thumbUrl: thumbUrl.present ? thumbUrl.value : this.thumbUrl,
        mediaKey: mediaKey.present ? mediaKey.value : this.mediaKey,
        mediaDigest: mediaDigest.present ? mediaDigest.value : this.mediaDigest,
        mediaCreatedAt:
            mediaCreatedAt.present ? mediaCreatedAt.value : this.mediaCreatedAt,
        stickerId: stickerId.present ? stickerId.value : this.stickerId,
        sharedUserId:
            sharedUserId.present ? sharedUserId.value : this.sharedUserId,
        mentions: mentions.present ? mentions.value : this.mentions,
        quoteId: quoteId.present ? quoteId.value : this.quoteId,
        quoteContent:
            quoteContent.present ? quoteContent.value : this.quoteContent,
        caption: caption.present ? caption.value : this.caption,
      );
  @override
  String toString() {
    return (StringBuffer('TranscriptMessage(')
          ..write('transcriptId: $transcriptId, ')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('userFullName: $userFullName, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaName: $mediaName, ')
          ..write('mediaSize: $mediaSize, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaDuration: $mediaDuration, ')
          ..write('mediaStatus: $mediaStatus, ')
          ..write('mediaWaveform: $mediaWaveform, ')
          ..write('thumbImage: $thumbImage, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('mediaKey: $mediaKey, ')
          ..write('mediaDigest: $mediaDigest, ')
          ..write('mediaCreatedAt: $mediaCreatedAt, ')
          ..write('stickerId: $stickerId, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('mentions: $mentions, ')
          ..write('quoteId: $quoteId, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('caption: $caption')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        transcriptId,
        messageId,
        userId,
        userFullName,
        category,
        createdAt,
        content,
        mediaUrl,
        mediaName,
        mediaSize,
        mediaWidth,
        mediaHeight,
        mediaMimeType,
        mediaDuration,
        mediaStatus,
        mediaWaveform,
        thumbImage,
        thumbUrl,
        mediaKey,
        mediaDigest,
        mediaCreatedAt,
        stickerId,
        sharedUserId,
        mentions,
        quoteId,
        quoteContent,
        caption
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptMessage &&
          other.transcriptId == this.transcriptId &&
          other.messageId == this.messageId &&
          other.userId == this.userId &&
          other.userFullName == this.userFullName &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.content == this.content &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaName == this.mediaName &&
          other.mediaSize == this.mediaSize &&
          other.mediaWidth == this.mediaWidth &&
          other.mediaHeight == this.mediaHeight &&
          other.mediaMimeType == this.mediaMimeType &&
          other.mediaDuration == this.mediaDuration &&
          other.mediaStatus == this.mediaStatus &&
          other.mediaWaveform == this.mediaWaveform &&
          other.thumbImage == this.thumbImage &&
          other.thumbUrl == this.thumbUrl &&
          other.mediaKey == this.mediaKey &&
          other.mediaDigest == this.mediaDigest &&
          other.mediaCreatedAt == this.mediaCreatedAt &&
          other.stickerId == this.stickerId &&
          other.sharedUserId == this.sharedUserId &&
          other.mentions == this.mentions &&
          other.quoteId == this.quoteId &&
          other.quoteContent == this.quoteContent &&
          other.caption == this.caption);
}

class TranscriptMessagesCompanion extends UpdateCompanion<TranscriptMessage> {
  final Value<String> transcriptId;
  final Value<String> messageId;
  final Value<String?> userId;
  final Value<String?> userFullName;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<String?> content;
  final Value<String?> mediaUrl;
  final Value<String?> mediaName;
  final Value<int?> mediaSize;
  final Value<int?> mediaWidth;
  final Value<int?> mediaHeight;
  final Value<String?> mediaMimeType;
  final Value<String?> mediaDuration;
  final Value<MediaStatus?> mediaStatus;
  final Value<String?> mediaWaveform;
  final Value<String?> thumbImage;
  final Value<String?> thumbUrl;
  final Value<String?> mediaKey;
  final Value<String?> mediaDigest;
  final Value<DateTime?> mediaCreatedAt;
  final Value<String?> stickerId;
  final Value<String?> sharedUserId;
  final Value<String?> mentions;
  final Value<String?> quoteId;
  final Value<String?> quoteContent;
  final Value<String?> caption;
  final Value<int> rowid;
  const TranscriptMessagesCompanion({
    this.transcriptId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.userId = const Value.absent(),
    this.userFullName = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.content = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaName = const Value.absent(),
    this.mediaSize = const Value.absent(),
    this.mediaWidth = const Value.absent(),
    this.mediaHeight = const Value.absent(),
    this.mediaMimeType = const Value.absent(),
    this.mediaDuration = const Value.absent(),
    this.mediaStatus = const Value.absent(),
    this.mediaWaveform = const Value.absent(),
    this.thumbImage = const Value.absent(),
    this.thumbUrl = const Value.absent(),
    this.mediaKey = const Value.absent(),
    this.mediaDigest = const Value.absent(),
    this.mediaCreatedAt = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.sharedUserId = const Value.absent(),
    this.mentions = const Value.absent(),
    this.quoteId = const Value.absent(),
    this.quoteContent = const Value.absent(),
    this.caption = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranscriptMessagesCompanion.insert({
    required String transcriptId,
    required String messageId,
    this.userId = const Value.absent(),
    this.userFullName = const Value.absent(),
    required String category,
    required DateTime createdAt,
    this.content = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaName = const Value.absent(),
    this.mediaSize = const Value.absent(),
    this.mediaWidth = const Value.absent(),
    this.mediaHeight = const Value.absent(),
    this.mediaMimeType = const Value.absent(),
    this.mediaDuration = const Value.absent(),
    this.mediaStatus = const Value.absent(),
    this.mediaWaveform = const Value.absent(),
    this.thumbImage = const Value.absent(),
    this.thumbUrl = const Value.absent(),
    this.mediaKey = const Value.absent(),
    this.mediaDigest = const Value.absent(),
    this.mediaCreatedAt = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.sharedUserId = const Value.absent(),
    this.mentions = const Value.absent(),
    this.quoteId = const Value.absent(),
    this.quoteContent = const Value.absent(),
    this.caption = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : transcriptId = Value(transcriptId),
        messageId = Value(messageId),
        category = Value(category),
        createdAt = Value(createdAt);
  static Insertable<TranscriptMessage> custom({
    Expression<String>? transcriptId,
    Expression<String>? messageId,
    Expression<String>? userId,
    Expression<String>? userFullName,
    Expression<String>? category,
    Expression<int>? createdAt,
    Expression<String>? content,
    Expression<String>? mediaUrl,
    Expression<String>? mediaName,
    Expression<int>? mediaSize,
    Expression<int>? mediaWidth,
    Expression<int>? mediaHeight,
    Expression<String>? mediaMimeType,
    Expression<String>? mediaDuration,
    Expression<String>? mediaStatus,
    Expression<String>? mediaWaveform,
    Expression<String>? thumbImage,
    Expression<String>? thumbUrl,
    Expression<String>? mediaKey,
    Expression<String>? mediaDigest,
    Expression<int>? mediaCreatedAt,
    Expression<String>? stickerId,
    Expression<String>? sharedUserId,
    Expression<String>? mentions,
    Expression<String>? quoteId,
    Expression<String>? quoteContent,
    Expression<String>? caption,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transcriptId != null) 'transcript_id': transcriptId,
      if (messageId != null) 'message_id': messageId,
      if (userId != null) 'user_id': userId,
      if (userFullName != null) 'user_full_name': userFullName,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (content != null) 'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaName != null) 'media_name': mediaName,
      if (mediaSize != null) 'media_size': mediaSize,
      if (mediaWidth != null) 'media_width': mediaWidth,
      if (mediaHeight != null) 'media_height': mediaHeight,
      if (mediaMimeType != null) 'media_mime_type': mediaMimeType,
      if (mediaDuration != null) 'media_duration': mediaDuration,
      if (mediaStatus != null) 'media_status': mediaStatus,
      if (mediaWaveform != null) 'media_waveform': mediaWaveform,
      if (thumbImage != null) 'thumb_image': thumbImage,
      if (thumbUrl != null) 'thumb_url': thumbUrl,
      if (mediaKey != null) 'media_key': mediaKey,
      if (mediaDigest != null) 'media_digest': mediaDigest,
      if (mediaCreatedAt != null) 'media_created_at': mediaCreatedAt,
      if (stickerId != null) 'sticker_id': stickerId,
      if (sharedUserId != null) 'shared_user_id': sharedUserId,
      if (mentions != null) 'mentions': mentions,
      if (quoteId != null) 'quote_id': quoteId,
      if (quoteContent != null) 'quote_content': quoteContent,
      if (caption != null) 'caption': caption,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranscriptMessagesCompanion copyWith(
      {Value<String>? transcriptId,
      Value<String>? messageId,
      Value<String?>? userId,
      Value<String?>? userFullName,
      Value<String>? category,
      Value<DateTime>? createdAt,
      Value<String?>? content,
      Value<String?>? mediaUrl,
      Value<String?>? mediaName,
      Value<int?>? mediaSize,
      Value<int?>? mediaWidth,
      Value<int?>? mediaHeight,
      Value<String?>? mediaMimeType,
      Value<String?>? mediaDuration,
      Value<MediaStatus?>? mediaStatus,
      Value<String?>? mediaWaveform,
      Value<String?>? thumbImage,
      Value<String?>? thumbUrl,
      Value<String?>? mediaKey,
      Value<String?>? mediaDigest,
      Value<DateTime?>? mediaCreatedAt,
      Value<String?>? stickerId,
      Value<String?>? sharedUserId,
      Value<String?>? mentions,
      Value<String?>? quoteId,
      Value<String?>? quoteContent,
      Value<String?>? caption,
      Value<int>? rowid}) {
    return TranscriptMessagesCompanion(
      transcriptId: transcriptId ?? this.transcriptId,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaName: mediaName ?? this.mediaName,
      mediaSize: mediaSize ?? this.mediaSize,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      mediaMimeType: mediaMimeType ?? this.mediaMimeType,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      mediaStatus: mediaStatus ?? this.mediaStatus,
      mediaWaveform: mediaWaveform ?? this.mediaWaveform,
      thumbImage: thumbImage ?? this.thumbImage,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      mediaKey: mediaKey ?? this.mediaKey,
      mediaDigest: mediaDigest ?? this.mediaDigest,
      mediaCreatedAt: mediaCreatedAt ?? this.mediaCreatedAt,
      stickerId: stickerId ?? this.stickerId,
      sharedUserId: sharedUserId ?? this.sharedUserId,
      mentions: mentions ?? this.mentions,
      quoteId: quoteId ?? this.quoteId,
      quoteContent: quoteContent ?? this.quoteContent,
      caption: caption ?? this.caption,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transcriptId.present) {
      map['transcript_id'] = Variable<String>(transcriptId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userFullName.present) {
      map['user_full_name'] = Variable<String>(userFullName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      final converter = TranscriptMessages.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (mediaName.present) {
      map['media_name'] = Variable<String>(mediaName.value);
    }
    if (mediaSize.present) {
      map['media_size'] = Variable<int>(mediaSize.value);
    }
    if (mediaWidth.present) {
      map['media_width'] = Variable<int>(mediaWidth.value);
    }
    if (mediaHeight.present) {
      map['media_height'] = Variable<int>(mediaHeight.value);
    }
    if (mediaMimeType.present) {
      map['media_mime_type'] = Variable<String>(mediaMimeType.value);
    }
    if (mediaDuration.present) {
      map['media_duration'] = Variable<String>(mediaDuration.value);
    }
    if (mediaStatus.present) {
      final converter = TranscriptMessages.$convertermediaStatus;
      map['media_status'] =
          Variable<String>(converter.toSql(mediaStatus.value));
    }
    if (mediaWaveform.present) {
      map['media_waveform'] = Variable<String>(mediaWaveform.value);
    }
    if (thumbImage.present) {
      map['thumb_image'] = Variable<String>(thumbImage.value);
    }
    if (thumbUrl.present) {
      map['thumb_url'] = Variable<String>(thumbUrl.value);
    }
    if (mediaKey.present) {
      map['media_key'] = Variable<String>(mediaKey.value);
    }
    if (mediaDigest.present) {
      map['media_digest'] = Variable<String>(mediaDigest.value);
    }
    if (mediaCreatedAt.present) {
      final converter = TranscriptMessages.$convertermediaCreatedAtn;
      map['media_created_at'] =
          Variable<int>(converter.toSql(mediaCreatedAt.value));
    }
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (sharedUserId.present) {
      map['shared_user_id'] = Variable<String>(sharedUserId.value);
    }
    if (mentions.present) {
      map['mentions'] = Variable<String>(mentions.value);
    }
    if (quoteId.present) {
      map['quote_id'] = Variable<String>(quoteId.value);
    }
    if (quoteContent.present) {
      map['quote_content'] = Variable<String>(quoteContent.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptMessagesCompanion(')
          ..write('transcriptId: $transcriptId, ')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('userFullName: $userFullName, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaName: $mediaName, ')
          ..write('mediaSize: $mediaSize, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaDuration: $mediaDuration, ')
          ..write('mediaStatus: $mediaStatus, ')
          ..write('mediaWaveform: $mediaWaveform, ')
          ..write('thumbImage: $thumbImage, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('mediaKey: $mediaKey, ')
          ..write('mediaDigest: $mediaDigest, ')
          ..write('mediaCreatedAt: $mediaCreatedAt, ')
          ..write('stickerId: $stickerId, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('mentions: $mentions, ')
          ..write('quoteId: $quoteId, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('caption: $caption, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Fiats extends Table with TableInfo<Fiats, Fiat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Fiats(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
      'rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [code, rate];
  @override
  String get aliasedName => _alias ?? 'fiats';
  @override
  String get actualTableName => 'fiats';
  @override
  VerificationContext validateIntegrity(Insertable<Fiat> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
          _rateMeta, rate.isAcceptableOrUnknown(data['rate']!, _rateMeta));
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  Fiat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fiat(
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      rate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate'])!,
    );
  }

  @override
  Fiats createAlias(String alias) {
    return Fiats(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(code)'];
  @override
  bool get dontWriteConstraints => true;
}

class Fiat extends DataClass implements Insertable<Fiat> {
  final String code;
  final double rate;
  const Fiat({required this.code, required this.rate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['rate'] = Variable<double>(rate);
    return map;
  }

  FiatsCompanion toCompanion(bool nullToAbsent) {
    return FiatsCompanion(
      code: Value(code),
      rate: Value(rate),
    );
  }

  factory Fiat.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fiat(
      code: serializer.fromJson<String>(json['code']),
      rate: serializer.fromJson<double>(json['rate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'rate': serializer.toJson<double>(rate),
    };
  }

  Fiat copyWith({String? code, double? rate}) => Fiat(
        code: code ?? this.code,
        rate: rate ?? this.rate,
      );
  @override
  String toString() {
    return (StringBuffer('Fiat(')
          ..write('code: $code, ')
          ..write('rate: $rate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, rate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fiat && other.code == this.code && other.rate == this.rate);
}

class FiatsCompanion extends UpdateCompanion<Fiat> {
  final Value<String> code;
  final Value<double> rate;
  final Value<int> rowid;
  const FiatsCompanion({
    this.code = const Value.absent(),
    this.rate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FiatsCompanion.insert({
    required String code,
    required double rate,
    this.rowid = const Value.absent(),
  })  : code = Value(code),
        rate = Value(rate);
  static Insertable<Fiat> custom({
    Expression<String>? code,
    Expression<double>? rate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (rate != null) 'rate': rate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FiatsCompanion copyWith(
      {Value<String>? code, Value<double>? rate, Value<int>? rowid}) {
    return FiatsCompanion(
      code: code ?? this.code,
      rate: rate ?? this.rate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiatsCompanion(')
          ..write('code: $code, ')
          ..write('rate: $rate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class FavoriteApps extends Table with TableInfo<FavoriteApps, FavoriteApp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FavoriteApps(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<DateTime>(FavoriteApps.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [appId, userId, createdAt];
  @override
  String get aliasedName => _alias ?? 'favorite_apps';
  @override
  String get actualTableName => 'favorite_apps';
  @override
  VerificationContext validateIntegrity(Insertable<FavoriteApp> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    context.handle(_createdAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {appId, userId};
  @override
  FavoriteApp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteApp(
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      createdAt: FavoriteApps.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
    );
  }

  @override
  FavoriteApps createAlias(String alias) {
    return FavoriteApps(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisDateConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(app_id, user_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class FavoriteApp extends DataClass implements Insertable<FavoriteApp> {
  final String appId;
  final String userId;
  final DateTime createdAt;
  const FavoriteApp(
      {required this.appId, required this.userId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['app_id'] = Variable<String>(appId);
    map['user_id'] = Variable<String>(userId);
    {
      final converter = FavoriteApps.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt));
    }
    return map;
  }

  FavoriteAppsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteAppsCompanion(
      appId: Value(appId),
      userId: Value(userId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteApp.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteApp(
      appId: serializer.fromJson<String>(json['app_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'app_id': serializer.toJson<String>(appId),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteApp copyWith({String? appId, String? userId, DateTime? createdAt}) =>
      FavoriteApp(
        appId: appId ?? this.appId,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('FavoriteApp(')
          ..write('appId: $appId, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(appId, userId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteApp &&
          other.appId == this.appId &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt);
}

class FavoriteAppsCompanion extends UpdateCompanion<FavoriteApp> {
  final Value<String> appId;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FavoriteAppsCompanion({
    this.appId = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteAppsCompanion.insert({
    required String appId,
    required String userId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : appId = Value(appId),
        userId = Value(userId),
        createdAt = Value(createdAt);
  static Insertable<FavoriteApp> custom({
    Expression<String>? appId,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (appId != null) 'app_id': appId,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteAppsCompanion copyWith(
      {Value<String>? appId,
      Value<String>? userId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return FavoriteAppsCompanion(
      appId: appId ?? this.appId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      final converter = FavoriteApps.$convertercreatedAt;
      map['created_at'] = Variable<int>(converter.toSql(createdAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteAppsCompanion(')
          ..write('appId: $appId, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Properties extends Table with TableInfo<Properties, Propertie> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Properties(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _groupMeta = const VerificationMeta('group');
  late final GeneratedColumnWithTypeConverter<PropertyGroup, String> group =
      GeneratedColumn<String>('group', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<PropertyGroup>(Properties.$convertergroup);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [key, group, value];
  @override
  String get aliasedName => _alias ?? 'properties';
  @override
  String get actualTableName => 'properties';
  @override
  VerificationContext validateIntegrity(Insertable<Propertie> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    context.handle(_groupMeta, const VerificationResult.success());
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key, group};
  @override
  Propertie map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Propertie(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      group: Properties.$convertergroup.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group'])!),
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  Properties createAlias(String alias) {
    return Properties(attachedDatabase, alias);
  }

  static TypeConverter<PropertyGroup, String> $convertergroup =
      const PropertyGroupConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY("key", "group")'];
  @override
  bool get dontWriteConstraints => true;
}

class Propertie extends DataClass implements Insertable<Propertie> {
  final String key;
  final PropertyGroup group;
  final String value;
  const Propertie(
      {required this.key, required this.group, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    {
      final converter = Properties.$convertergroup;
      map['group'] = Variable<String>(converter.toSql(group));
    }
    map['value'] = Variable<String>(value);
    return map;
  }

  PropertiesCompanion toCompanion(bool nullToAbsent) {
    return PropertiesCompanion(
      key: Value(key),
      group: Value(group),
      value: Value(value),
    );
  }

  factory Propertie.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Propertie(
      key: serializer.fromJson<String>(json['key']),
      group: serializer.fromJson<PropertyGroup>(json['group']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'group': serializer.toJson<PropertyGroup>(group),
      'value': serializer.toJson<String>(value),
    };
  }

  Propertie copyWith({String? key, PropertyGroup? group, String? value}) =>
      Propertie(
        key: key ?? this.key,
        group: group ?? this.group,
        value: value ?? this.value,
      );
  @override
  String toString() {
    return (StringBuffer('Propertie(')
          ..write('key: $key, ')
          ..write('group: $group, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, group, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Propertie &&
          other.key == this.key &&
          other.group == this.group &&
          other.value == this.value);
}

class PropertiesCompanion extends UpdateCompanion<Propertie> {
  final Value<String> key;
  final Value<PropertyGroup> group;
  final Value<String> value;
  final Value<int> rowid;
  const PropertiesCompanion({
    this.key = const Value.absent(),
    this.group = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PropertiesCompanion.insert({
    required String key,
    required PropertyGroup group,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        group = Value(group),
        value = Value(value);
  static Insertable<Propertie> custom({
    Expression<String>? key,
    Expression<String>? group,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (group != null) 'group': group,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PropertiesCompanion copyWith(
      {Value<String>? key,
      Value<PropertyGroup>? group,
      Value<String>? value,
      Value<int>? rowid}) {
    return PropertiesCompanion(
      key: key ?? this.key,
      group: group ?? this.group,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (group.present) {
      final converter = Properties.$convertergroup;
      map['group'] = Variable<String>(converter.toSql(group.value));
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PropertiesCompanion(')
          ..write('key: $key, ')
          ..write('group: $group, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MixinDatabase extends GeneratedDatabase {
  _$MixinDatabase(QueryExecutor e) : super(e);
  late final Users users = Users(this);
  late final Conversations conversations = Conversations(this);
  late final Messages messages = Messages(this);
  late final Participants participants = Participants(this);
  late final CircleConversations circleConversations =
      CircleConversations(this);
  late final ParticipantSession participantSession = ParticipantSession(this);
  late final Snapshots snapshots = Snapshots(this);
  late final Assets assets = Assets(this);
  late final Chains chains = Chains(this);
  late final Stickers stickers = Stickers(this);
  late final Hyperlinks hyperlinks = Hyperlinks(this);
  late final MessageMentions messageMentions = MessageMentions(this);
  late final PinMessages pinMessages = PinMessages(this);
  late final ExpiredMessages expiredMessages = ExpiredMessages(this);
  late final ResendSessionMessages resendSessionMessages =
      ResendSessionMessages(this);
  late final Addresses addresses = Addresses(this);
  late final Apps apps = Apps(this);
  late final Circles circles = Circles(this);
  late final FloodMessages floodMessages = FloodMessages(this);
  late final Jobs jobs = Jobs(this);
  late final MessagesHistory messagesHistory = MessagesHistory(this);
  late final Offsets offsets = Offsets(this);
  late final SentSessionSenderKeys sentSessionSenderKeys =
      SentSessionSenderKeys(this);
  late final StickerAlbums stickerAlbums = StickerAlbums(this);
  late final StickerRelationships stickerRelationships =
      StickerRelationships(this);
  late final TranscriptMessages transcriptMessages = TranscriptMessages(this);
  late final Fiats fiats = Fiats(this);
  late final FavoriteApps favoriteApps = FavoriteApps(this);
  late final Properties properties = Properties(this);
  late final Index indexConversationsCategoryStatus = Index(
      'index_conversations_category_status',
      'CREATE INDEX IF NOT EXISTS index_conversations_category_status ON conversations (category, status)');
  late final Index indexConversationsMuteUntil = Index(
      'index_conversations_mute_until',
      'CREATE INDEX IF NOT EXISTS index_conversations_mute_until ON conversations (mute_until)');
  late final Index indexFloodMessagesCreatedAt = Index(
      'index_flood_messages_created_at',
      'CREATE INDEX IF NOT EXISTS index_flood_messages_created_at ON flood_messages (created_at)');
  late final Index indexJobsAction = Index('index_jobs_action',
      'CREATE INDEX IF NOT EXISTS index_jobs_action ON jobs ("action")');
  late final Index indexMessageMentionsConversationIdHasRead = Index(
      'index_message_mentions_conversation_id_has_read',
      'CREATE INDEX IF NOT EXISTS index_message_mentions_conversation_id_has_read ON message_mentions (conversation_id, has_read)');
  late final Index indexParticipantsConversationIdCreatedAt = Index(
      'index_participants_conversation_id_created_at',
      'CREATE INDEX IF NOT EXISTS index_participants_conversation_id_created_at ON participants (conversation_id, created_at)');
  late final Index indexStickerAlbumsCategoryCreatedAt = Index(
      'index_sticker_albums_category_created_at',
      'CREATE INDEX IF NOT EXISTS index_sticker_albums_category_created_at ON sticker_albums (category, created_at DESC)');
  late final Index indexPinMessagesConversationId = Index(
      'index_pin_messages_conversation_id',
      'CREATE INDEX IF NOT EXISTS index_pin_messages_conversation_id ON pin_messages (conversation_id)');
  late final Index indexUsersIdentityNumber = Index(
      'index_users_identity_number',
      'CREATE INDEX IF NOT EXISTS index_users_identity_number ON users (identity_number)');
  late final Index indexMessagesConversationIdCreatedAt = Index(
      'index_messages_conversation_id_created_at',
      'CREATE INDEX IF NOT EXISTS index_messages_conversation_id_created_at ON messages (conversation_id, created_at DESC)');
  late final Index indexMessagesConversationIdCategoryCreatedAt = Index(
      'index_messages_conversation_id_category_created_at',
      'CREATE INDEX IF NOT EXISTS index_messages_conversation_id_category_created_at ON messages (conversation_id, category, created_at DESC)');
  late final Index indexMessageConversationIdStatusUserId = Index(
      'index_message_conversation_id_status_user_id',
      'CREATE INDEX IF NOT EXISTS index_message_conversation_id_status_user_id ON messages (conversation_id, status, user_id)');
  late final Index indexMessagesConversationIdQuoteMessageId = Index(
      'index_messages_conversation_id_quote_message_id',
      'CREATE INDEX IF NOT EXISTS index_messages_conversation_id_quote_message_id ON messages (conversation_id, quote_message_id)');
  late final AddressDao addressDao = AddressDao(this as MixinDatabase);
  late final AppDao appDao = AppDao(this as MixinDatabase);
  late final AssetDao assetDao = AssetDao(this as MixinDatabase);
  late final CircleConversationDao circleConversationDao =
      CircleConversationDao(this as MixinDatabase);
  late final CircleDao circleDao = CircleDao(this as MixinDatabase);
  late final ConversationDao conversationDao =
      ConversationDao(this as MixinDatabase);
  late final FloodMessageDao floodMessageDao =
      FloodMessageDao(this as MixinDatabase);
  late final HyperlinkDao hyperlinkDao = HyperlinkDao(this as MixinDatabase);
  late final JobDao jobDao = JobDao(this as MixinDatabase);
  late final MessageMentionDao messageMentionDao =
      MessageMentionDao(this as MixinDatabase);
  late final MessageDao messageDao = MessageDao(this as MixinDatabase);
  late final MessageHistoryDao messageHistoryDao =
      MessageHistoryDao(this as MixinDatabase);
  late final OffsetDao offsetDao = OffsetDao(this as MixinDatabase);
  late final ParticipantDao participantDao =
      ParticipantDao(this as MixinDatabase);
  late final ParticipantSessionDao participantSessionDao =
      ParticipantSessionDao(this as MixinDatabase);
  late final ResendSessionMessageDao resendSessionMessageDao =
      ResendSessionMessageDao(this as MixinDatabase);
  late final SentSessionSenderKeyDao sentSessionSenderKeyDao =
      SentSessionSenderKeyDao(this as MixinDatabase);
  late final SnapshotDao snapshotDao = SnapshotDao(this as MixinDatabase);
  late final StickerDao stickerDao = StickerDao(this as MixinDatabase);
  late final StickerAlbumDao stickerAlbumDao =
      StickerAlbumDao(this as MixinDatabase);
  late final StickerRelationshipDao stickerRelationshipDao =
      StickerRelationshipDao(this as MixinDatabase);
  late final UserDao userDao = UserDao(this as MixinDatabase);
  late final PinMessageDao pinMessageDao = PinMessageDao(this as MixinDatabase);
  late final FiatDao fiatDao = FiatDao(this as MixinDatabase);
  late final FavoriteAppDao favoriteAppDao =
      FavoriteAppDao(this as MixinDatabase);
  late final ExpiredMessageDao expiredMessageDao =
      ExpiredMessageDao(this as MixinDatabase);
  late final ChainDao chainDao = ChainDao(this as MixinDatabase);
  late final PropertyDao propertyDao = PropertyDao(this as MixinDatabase);
  late final TranscriptMessageDao transcriptMessageDao =
      TranscriptMessageDao(this as MixinDatabase);
  Selectable<User> fuzzySearchBotGroupUser(String conversationId,
      DateTime createdAt, String id, String username, String identityNumber) {
    return customSelect(
        'SELECT u.* FROM users AS u WHERE(u.user_id IN (SELECT m.user_id FROM messages AS m WHERE conversation_id = ?1 AND m.created_at > ?2) OR u.user_id IN (SELECT f.user_id FROM users AS f WHERE relationship = \'FRIEND\'))AND u.user_id != ?3 AND u.identity_number != 0 AND(u.full_name LIKE \'%\' || ?4 || \'%\' ESCAPE \'\\\' OR u.identity_number LIKE \'%\' || ?5 || \'%\' ESCAPE \'\\\')ORDER BY CASE u.relationship WHEN \'FRIEND\' THEN 1 ELSE 2 END, u.relationship OR u.full_name = ?4 COLLATE NOCASE OR u.identity_number = ?5 COLLATE NOCASE DESC',
        variables: [
          Variable<String>(conversationId),
          Variable<int>(Messages.$convertercreatedAt.toSql(createdAt)),
          Variable<String>(id),
          Variable<String>(username),
          Variable<String>(identityNumber)
        ],
        readsFrom: {
          users,
          messages,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<User> fuzzySearchGroupUser(String id, String conversationId,
      String username, String identityNumber) {
    return customSelect(
        'SELECT u.* FROM participants AS p,users AS u WHERE u.user_id != ?1 AND p.conversation_id = ?2 AND p.user_id = u.user_id AND(u.full_name LIKE \'%\' || ?3 || \'%\' ESCAPE \'\\\' OR u.identity_number LIKE \'%\' || ?4 || \'%\' ESCAPE \'\\\')ORDER BY u.full_name = ?3 COLLATE NOCASE OR u.identity_number = ?4 COLLATE NOCASE DESC',
        variables: [
          Variable<String>(id),
          Variable<String>(conversationId),
          Variable<String>(username),
          Variable<String>(identityNumber)
        ],
        readsFrom: {
          participants,
          users,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<User> groupParticipants(String conversationId) {
    return customSelect(
        'SELECT u.* FROM participants AS p,users AS u WHERE p.conversation_id = ?1 AND p.user_id = u.user_id',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          participants,
          users,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<User> notInFriends(List<String> filterIds) {
    var $arrayStartIndex = 1;
    final expandedfilterIds = $expandVar($arrayStartIndex, filterIds.length);
    $arrayStartIndex += filterIds.length;
    return customSelect(
        'SELECT * FROM users WHERE relationship = \'FRIEND\' AND user_id NOT IN ($expandedfilterIds) ORDER BY full_name, user_id ASC',
        variables: [
          for (var $ in filterIds) Variable<String>($)
        ],
        readsFrom: {
          users,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<User> usersByIn(List<String> userIds) {
    var $arrayStartIndex = 1;
    final expandeduserIds = $expandVar($arrayStartIndex, userIds.length);
    $arrayStartIndex += userIds.length;
    return customSelect(
        'SELECT * FROM users WHERE user_id IN ($expandeduserIds)',
        variables: [
          for (var $ in userIds) Variable<String>($)
        ],
        readsFrom: {
          users,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<String> userIdsByIn(List<String> userIds) {
    var $arrayStartIndex = 1;
    final expandeduserIds = $expandVar($arrayStartIndex, userIds.length);
    $arrayStartIndex += userIds.length;
    return customSelect(
        'SELECT user_id FROM users WHERE user_id IN ($expandeduserIds)',
        variables: [
          for (var $ in userIds) Variable<String>($)
        ],
        readsFrom: {
          users,
        }).map((QueryRow row) => row.read<String>('user_id'));
  }

  Selectable<User> fuzzySearchUser(
      FuzzySearchUser$firstFilter firstFilter,
      String id,
      String username,
      String identityNumber,
      FuzzySearchUser$lastFilter lastFilter) {
    var $arrayStartIndex = 4;
    final generatedfirstFilter = $write(
        firstFilter(this.users, this.conversations),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedfirstFilter.amountOfVariables;
    final generatedlastFilter = $write(
        lastFilter(this.users, this.conversations),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlastFilter.amountOfVariables;
    return customSelect(
        'SELECT users.* FROM users LEFT JOIN conversations ON conversations.owner_id = user_id WHERE ${generatedfirstFilter.sql} AND user_id != ?1 AND relationship = \'FRIEND\' AND(full_name LIKE \'%\' || ?2 || \'%\' ESCAPE \'\\\' OR identity_number LIKE \' %\' || ?3 || \' %\' ESCAPE \'\\\')AND ${generatedlastFilter.sql} GROUP BY user_id ORDER BY full_name = ?2 COLLATE nocase OR identity_number = ?3 COLLATE nocase DESC',
        variables: [
          Variable<String>(id),
          Variable<String>(username),
          Variable<String>(identityNumber),
          ...generatedfirstFilter.introducedVariables,
          ...generatedlastFilter.introducedVariables
        ],
        readsFrom: {
          users,
          conversations,
          ...generatedfirstFilter.watchedTables,
          ...generatedlastFilter.watchedTables,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<User> fuzzySearchUserInCircle(
      FuzzySearchUserInCircle$filter filter,
      String id,
      String username,
      String identityNumber,
      String? circleId) {
    var $arrayStartIndex = 5;
    final generatedfilter = $write(
        filter(this.users, this.conversations,
            alias(this.circleConversations, 'circleConversation')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedfilter.amountOfVariables;
    return customSelect(
        'SELECT users.* FROM users LEFT JOIN conversations ON conversations.owner_id = users.user_id LEFT JOIN circle_conversations AS circleConversation ON circleConversation.user_id = users.user_id WHERE ${generatedfilter.sql} AND users.user_id != ?1 AND relationship = \'FRIEND\' AND(full_name LIKE \'%\' || ?2 || \'%\' ESCAPE \'\\\' OR identity_number LIKE \' %\' || ?3 || \' %\' ESCAPE \'\\\')AND circleConversation.circle_id = ?4 GROUP BY users.user_id ORDER BY full_name = ?2 COLLATE nocase OR identity_number = ?3 COLLATE nocase DESC',
        variables: [
          Variable<String>(id),
          Variable<String>(username),
          Variable<String>(identityNumber),
          Variable<String>(circleId),
          ...generatedfilter.introducedVariables
        ],
        readsFrom: {
          users,
          conversations,
          circleConversations,
          ...generatedfilter.watchedTables,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<String?> biographyByIdentityNumber(String userId) {
    return customSelect('SELECT biography FROM users WHERE user_id = ?1',
        variables: [
          Variable<String>(userId)
        ],
        readsFrom: {
          users,
        }).map((QueryRow row) => row.readNullable<String>('biography'));
  }

  Selectable<MentionUser> userByIdentityNumbers(List<String> numbers) {
    var $arrayStartIndex = 1;
    final expandednumbers = $expandVar($arrayStartIndex, numbers.length);
    $arrayStartIndex += numbers.length;
    return customSelect(
        'SELECT user_id, identity_number, full_name FROM users WHERE identity_number IN ($expandednumbers)',
        variables: [
          for (var $ in numbers) Variable<String>($)
        ],
        readsFrom: {
          users,
        }).map((QueryRow row) {
      return MentionUser(
        userId: row.read<String>('user_id'),
        identityNumber: row.read<String>('identity_number'),
        fullName: row.readNullable<String>('full_name'),
      );
    });
  }

  Selectable<int> countUsers() {
    return customSelect('SELECT COUNT(*) AS _c0 FROM users',
        variables: [],
        readsFrom: {
          users,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<User> participantsAvatar(String conversationId) {
    return customSelect(
        'SELECT user.* FROM participants AS participant INNER JOIN users AS user ON participant.user_id = user.user_id WHERE participant.conversation_id = ?1 ORDER BY participant.created_at ASC LIMIT 4',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          participants,
          users,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<ParticipantSessionKey> participantSessionKeyWithoutSelf(
      String conversationId, String userId) {
    return customSelect(
        'SELECT conversation_id, user_id, session_id, public_key FROM participant_session WHERE conversation_id = ?1 AND user_id != ?2 LIMIT 1',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(userId)
        ],
        readsFrom: {
          participantSession,
        }).map((QueryRow row) {
      return ParticipantSessionKey(
        conversationId: row.read<String>('conversation_id'),
        userId: row.read<String>('user_id'),
        sessionId: row.read<String>('session_id'),
        publicKey: row.readNullable<String>('public_key'),
      );
    });
  }

  Selectable<ParticipantSessionKey> otherParticipantSessionKey(
      String conversationId, String userId, String sessionId) {
    return customSelect(
        'SELECT conversation_id, user_id, session_id, public_key FROM participant_session WHERE conversation_id = ?1 AND user_id == ?2 AND session_id != ?3 ORDER BY created_at DESC LIMIT 1',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(userId),
          Variable<String>(sessionId)
        ],
        readsFrom: {
          participantSession,
        }).map((QueryRow row) {
      return ParticipantSessionKey(
        conversationId: row.read<String>('conversation_id'),
        userId: row.read<String>('user_id'),
        sessionId: row.read<String>('session_id'),
        publicKey: row.readNullable<String>('public_key'),
      );
    });
  }

  Selectable<ParticipantSessionData> notSendSessionParticipants(
      String conversationId, String sessionId) {
    return customSelect(
        'SELECT p.* FROM participant_session AS p LEFT JOIN users AS u ON p.user_id = u.user_id WHERE p.conversation_id = ?1 AND p.session_id != ?2 AND u.app_id IS NULL AND p.sent_to_server IS NULL',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(sessionId)
        ],
        readsFrom: {
          participantSession,
          users,
        }).asyncMap(participantSession.mapFromRow);
  }

  Selectable<ParticipantSessionData> participantSessionKeyBySessionId(
      String conversationId, String sessionId) {
    return customSelect(
        'SELECT * FROM participant_session WHERE conversation_id = ?1 AND session_id == ?2',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(sessionId)
        ],
        readsFrom: {
          participantSession,
        }).asyncMap(participantSession.mapFromRow);
  }

  Selectable<ParticipantUser> groupParticipantsByConversationId(
      String conversationId) {
    return customSelect(
        'SELECT p.conversation_id AS conversationId, p.role AS role, p.created_at AS createdAt, u.user_id AS userId, u.identity_number AS identityNumber, u.relationship AS relationship, u.biography AS biography, u.full_name AS fullName, u.avatar_url AS avatarUrl, u.phone AS phone, u.is_verified AS isVerified, u.created_at AS userCreatedAt, u.mute_until AS muteUntil, u.has_pin AS hasPin, u.app_id AS appId, u.is_scam AS isScam FROM participants AS p,users AS u WHERE p.conversation_id = ?1 AND p.user_id = u.user_id ORDER BY p.created_at DESC',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          participants,
          users,
        }).map((QueryRow row) {
      return ParticipantUser(
        conversationId: row.read<String>('conversationId'),
        role: Participants.$converterrole
            .fromSql(row.readNullable<String>('role')),
        createdAt: Participants.$convertercreatedAt
            .fromSql(row.read<int>('createdAt')),
        userId: row.read<String>('userId'),
        identityNumber: row.read<String>('identityNumber'),
        relationship: Users.$converterrelationship
            .fromSql(row.readNullable<String>('relationship')),
        biography: row.readNullable<String>('biography'),
        fullName: row.readNullable<String>('fullName'),
        avatarUrl: row.readNullable<String>('avatarUrl'),
        phone: row.readNullable<String>('phone'),
        isVerified: row.readNullable<bool>('isVerified'),
        userCreatedAt: NullAwareTypeConverter.wrapFromSql(
            Users.$convertercreatedAt, row.readNullable<int>('userCreatedAt')),
        muteUntil: NullAwareTypeConverter.wrapFromSql(
            Users.$convertermuteUntil, row.readNullable<int>('muteUntil')),
        hasPin: row.readNullable<int>('hasPin'),
        appId: row.readNullable<String>('appId'),
        isScam: row.readNullable<int>('isScam'),
      );
    });
  }

  Selectable<String> userIdByIdentityNumber(
      String conversationId, String identityNumber) {
    return customSelect(
        'SELECT u.user_id FROM users AS u INNER JOIN participants AS p ON p.user_id = u.user_id WHERE p.conversation_id = ?1 AND u.identity_number = ?2',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(identityNumber)
        ],
        readsFrom: {
          users,
          participants,
        }).map((QueryRow row) => row.read<String>('user_id'));
  }

  Selectable<int> countParticipants() {
    return customSelect('SELECT COUNT(1) AS _c0 FROM participants',
        variables: [],
        readsFrom: {
          participants,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<int> conversationParticipantsCount(String conversationId) {
    return customSelect(
        'SELECT COUNT(1) AS _c0 FROM participants WHERE conversation_id = ?1',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          participants,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<MessageItem> baseMessageItems(BaseMessageItems$where where,
      BaseMessageItems$order order, BaseMessageItems$limit limit) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(
            alias(this.messages, 'message'),
            alias(this.users, 'sender'),
            alias(this.users, 'participant'),
            alias(this.snapshots, 'snapshot'),
            alias(this.assets, 'asset'),
            alias(this.chains, 'chain'),
            alias(this.stickers, 'sticker'),
            alias(this.hyperlinks, 'hyperlink'),
            alias(this.users, 'sharedUser'),
            alias(this.conversations, 'conversation'),
            alias(this.messageMentions, 'messageMention'),
            alias(this.pinMessages, 'pinMessage'),
            alias(this.expiredMessages, 'em')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedorder = $write(
        order?.call(
                alias(this.messages, 'message'),
                alias(this.users, 'sender'),
                alias(this.users, 'participant'),
                alias(this.snapshots, 'snapshot'),
                alias(this.assets, 'asset'),
                alias(this.chains, 'chain'),
                alias(this.stickers, 'sticker'),
                alias(this.hyperlinks, 'hyperlink'),
                alias(this.users, 'sharedUser'),
                alias(this.conversations, 'conversation'),
                alias(this.messageMentions, 'messageMention'),
                alias(this.pinMessages, 'pinMessage'),
                alias(this.expiredMessages, 'em')) ??
            const OrderBy.nothing(),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedorder.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.messages, 'message'),
            alias(this.users, 'sender'),
            alias(this.users, 'participant'),
            alias(this.snapshots, 'snapshot'),
            alias(this.assets, 'asset'),
            alias(this.chains, 'chain'),
            alias(this.stickers, 'sticker'),
            alias(this.hyperlinks, 'hyperlink'),
            alias(this.users, 'sharedUser'),
            alias(this.conversations, 'conversation'),
            alias(this.messageMentions, 'messageMention'),
            alias(this.pinMessages, 'pinMessage'),
            alias(this.expiredMessages, 'em')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT message.message_id AS messageId, message.conversation_id AS conversationId, message.category AS type, message.content AS content, message.created_at AS createdAt, message.status AS status, message.media_status AS mediaStatus, message.media_waveform AS mediaWaveform, message.name AS mediaName, message.media_mime_type AS mediaMimeType, message.media_size AS mediaSize, message.media_width AS mediaWidth, message.media_height AS mediaHeight, message.thumb_image AS thumbImage, message.thumb_url AS thumbUrl, message.media_url AS mediaUrl, message.media_duration AS mediaDuration, message.quote_message_id AS quoteId, message.quote_content AS quoteContent, message."action" AS actionName, message.shared_user_id AS sharedUserId, message.sticker_id AS stickerId, sender.user_id AS userId, sender.full_name AS userFullName, sender.identity_number AS userIdentityNumber, sender.app_id AS appId, sender.relationship AS relationship, sender.avatar_url AS avatarUrl, sharedUser.full_name AS sharedUserFullName, sharedUser.identity_number AS sharedUserIdentityNumber, sharedUser.avatar_url AS sharedUserAvatarUrl, sharedUser.is_verified AS sharedUserIsVerified, sharedUser.app_id AS sharedUserAppId, conversation.owner_id AS conversationOwnerId, conversation.category AS conversionCategory, conversation.name AS groupName, sticker.asset_url AS assetUrl, sticker.asset_width AS assetWidth, sticker.asset_height AS assetHeight, sticker.name AS assetName, sticker.asset_type AS assetType, participant.full_name AS participantFullName, participant.user_id AS participantUserId, snapshot.snapshot_id AS snapshotId, snapshot.type AS snapshotType, snapshot.amount AS snapshotAmount, snapshot.asset_id AS assetId, asset.symbol AS assetSymbol, asset.icon_url AS assetIcon, chain.icon_url AS chainIcon, hyperlink.site_name AS siteName, hyperlink.site_title AS siteTitle, hyperlink.site_description AS siteDescription, hyperlink.site_image AS siteImage, messageMention.has_read AS mentionRead, em.expire_in AS expireIn, CASE WHEN pinMessage.message_id IS NOT NULL THEN TRUE ELSE FALSE END AS pinned FROM messages AS message INNER JOIN users AS sender ON message.user_id = sender.user_id LEFT JOIN users AS participant ON message.participant_id = participant.user_id LEFT JOIN snapshots AS snapshot ON message.snapshot_id = snapshot.snapshot_id LEFT JOIN assets AS asset ON snapshot.asset_id = asset.asset_id LEFT JOIN chains AS chain ON asset.chain_id = chain.chain_id LEFT JOIN stickers AS sticker ON sticker.sticker_id = message.sticker_id LEFT JOIN hyperlinks AS hyperlink ON message.hyperlink = hyperlink.hyperlink LEFT JOIN users AS sharedUser ON message.shared_user_id = sharedUser.user_id LEFT JOIN conversations AS conversation ON message.conversation_id = conversation.conversation_id LEFT JOIN message_mentions AS messageMention ON message.message_id = messageMention.message_id LEFT JOIN pin_messages AS pinMessage ON message.message_id = pinMessage.message_id LEFT JOIN expired_messages AS em ON message.message_id = em.message_id WHERE ${generatedwhere.sql} ${generatedorder.sql} ${generatedlimit.sql}',
        variables: [
          ...generatedwhere.introducedVariables,
          ...generatedorder.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          messages,
          users,
          conversations,
          stickers,
          snapshots,
          assets,
          chains,
          hyperlinks,
          messageMentions,
          expiredMessages,
          pinMessages,
          ...generatedwhere.watchedTables,
          ...generatedorder.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) {
      return MessageItem(
        messageId: row.read<String>('messageId'),
        conversationId: row.read<String>('conversationId'),
        type: row.read<String>('type'),
        content: row.readNullable<String>('content'),
        createdAt:
            Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
        status: Messages.$converterstatus.fromSql(row.read<String>('status')),
        mediaStatus: Messages.$convertermediaStatus
            .fromSql(row.readNullable<String>('mediaStatus')),
        mediaWaveform: row.readNullable<String>('mediaWaveform'),
        mediaName: row.readNullable<String>('mediaName'),
        mediaMimeType: row.readNullable<String>('mediaMimeType'),
        mediaSize: row.readNullable<int>('mediaSize'),
        mediaWidth: row.readNullable<int>('mediaWidth'),
        mediaHeight: row.readNullable<int>('mediaHeight'),
        thumbImage: row.readNullable<String>('thumbImage'),
        thumbUrl: row.readNullable<String>('thumbUrl'),
        mediaUrl: row.readNullable<String>('mediaUrl'),
        mediaDuration: row.readNullable<String>('mediaDuration'),
        quoteId: row.readNullable<String>('quoteId'),
        quoteContent: row.readNullable<String>('quoteContent'),
        actionName: row.readNullable<String>('actionName'),
        sharedUserId: row.readNullable<String>('sharedUserId'),
        stickerId: row.readNullable<String>('stickerId'),
        userId: row.read<String>('userId'),
        userFullName: row.readNullable<String>('userFullName'),
        userIdentityNumber: row.read<String>('userIdentityNumber'),
        appId: row.readNullable<String>('appId'),
        relationship: Users.$converterrelationship
            .fromSql(row.readNullable<String>('relationship')),
        avatarUrl: row.readNullable<String>('avatarUrl'),
        sharedUserFullName: row.readNullable<String>('sharedUserFullName'),
        sharedUserIdentityNumber:
            row.readNullable<String>('sharedUserIdentityNumber'),
        sharedUserAvatarUrl: row.readNullable<String>('sharedUserAvatarUrl'),
        sharedUserIsVerified: row.readNullable<bool>('sharedUserIsVerified'),
        sharedUserAppId: row.readNullable<String>('sharedUserAppId'),
        conversationOwnerId: row.readNullable<String>('conversationOwnerId'),
        conversionCategory: Conversations.$convertercategory
            .fromSql(row.readNullable<String>('conversionCategory')),
        groupName: row.readNullable<String>('groupName'),
        assetUrl: row.readNullable<String>('assetUrl'),
        assetWidth: row.readNullable<int>('assetWidth'),
        assetHeight: row.readNullable<int>('assetHeight'),
        assetName: row.readNullable<String>('assetName'),
        assetType: row.readNullable<String>('assetType'),
        participantFullName: row.readNullable<String>('participantFullName'),
        participantUserId: row.readNullable<String>('participantUserId'),
        snapshotId: row.readNullable<String>('snapshotId'),
        snapshotType: row.readNullable<String>('snapshotType'),
        snapshotAmount: row.readNullable<String>('snapshotAmount'),
        assetId: row.readNullable<String>('assetId'),
        assetSymbol: row.readNullable<String>('assetSymbol'),
        assetIcon: row.readNullable<String>('assetIcon'),
        chainIcon: row.readNullable<String>('chainIcon'),
        siteName: row.readNullable<String>('siteName'),
        siteTitle: row.readNullable<String>('siteTitle'),
        siteDescription: row.readNullable<String>('siteDescription'),
        siteImage: row.readNullable<String>('siteImage'),
        mentionRead: row.readNullable<bool>('mentionRead'),
        expireIn: row.readNullable<int>('expireIn'),
        pinned: row.read<bool>('pinned'),
      );
    });
  }

  Selectable<QuoteMessageItem> baseQuoteMessageItem(
      BaseQuoteMessageItem$where where,
      BaseQuoteMessageItem$order order,
      BaseQuoteMessageItem$limit limit) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(
            alias(this.messages, 'message'),
            alias(this.users, 'sender'),
            alias(this.stickers, 'sticker'),
            alias(this.users, 'shareUser'),
            alias(this.messageMentions, 'messageMention')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedorder = $write(
        order?.call(
                alias(this.messages, 'message'),
                alias(this.users, 'sender'),
                alias(this.stickers, 'sticker'),
                alias(this.users, 'shareUser'),
                alias(this.messageMentions, 'messageMention')) ??
            const OrderBy.nothing(),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedorder.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.messages, 'message'),
            alias(this.users, 'sender'),
            alias(this.stickers, 'sticker'),
            alias(this.users, 'shareUser'),
            alias(this.messageMentions, 'messageMention')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT message.message_id AS messageId, message.conversation_id AS conversationId, sender.user_id AS userId, sender.full_name AS userFullName, sender.identity_number AS userIdentityNumber, sender.app_id AS appId, message.category AS type, message.content AS content, message.created_at AS createdAt, message.status AS status, message.media_status AS mediaStatus, message.media_waveform AS mediaWaveform, message.name AS mediaName, message.media_mime_type AS mediaMimeType, message.media_size AS mediaSize, message.media_width AS mediaWidth, message.media_height AS mediaHeight, message.thumb_image AS thumbImage, message.thumb_url AS thumbUrl, message.media_url AS mediaUrl, message.media_duration AS mediaDuration, message.sticker_id AS stickerId, sticker.asset_url AS assetUrl, sticker.asset_width AS assetWidth, sticker.asset_height AS assetHeight, sticker.name AS assetName, sticker.asset_type AS assetType, message.shared_user_id AS sharedUserId, shareUser.full_name AS sharedUserFullName, shareUser.identity_number AS sharedUserIdentityNumber, shareUser.avatar_url AS sharedUserAvatarUrl, shareUser.is_verified AS sharedUserIsVerified, shareUser.app_id AS sharedUserAppId FROM messages AS message INNER JOIN users AS sender ON message.user_id = sender.user_id LEFT JOIN stickers AS sticker ON sticker.sticker_id = message.sticker_id LEFT JOIN users AS shareUser ON message.shared_user_id = shareUser.user_id LEFT JOIN message_mentions AS messageMention ON message.message_id = messageMention.message_id WHERE ${generatedwhere.sql} ${generatedorder.sql} ${generatedlimit.sql}',
        variables: [
          ...generatedwhere.introducedVariables,
          ...generatedorder.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          messages,
          users,
          stickers,
          messageMentions,
          ...generatedwhere.watchedTables,
          ...generatedorder.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) {
      return QuoteMessageItem(
        messageId: row.read<String>('messageId'),
        conversationId: row.read<String>('conversationId'),
        userId: row.read<String>('userId'),
        userFullName: row.readNullable<String>('userFullName'),
        userIdentityNumber: row.read<String>('userIdentityNumber'),
        appId: row.readNullable<String>('appId'),
        type: row.read<String>('type'),
        content: row.readNullable<String>('content'),
        createdAt:
            Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
        status: Messages.$converterstatus.fromSql(row.read<String>('status')),
        mediaStatus: Messages.$convertermediaStatus
            .fromSql(row.readNullable<String>('mediaStatus')),
        mediaWaveform: row.readNullable<String>('mediaWaveform'),
        mediaName: row.readNullable<String>('mediaName'),
        mediaMimeType: row.readNullable<String>('mediaMimeType'),
        mediaSize: row.readNullable<int>('mediaSize'),
        mediaWidth: row.readNullable<int>('mediaWidth'),
        mediaHeight: row.readNullable<int>('mediaHeight'),
        thumbImage: row.readNullable<String>('thumbImage'),
        thumbUrl: row.readNullable<String>('thumbUrl'),
        mediaUrl: row.readNullable<String>('mediaUrl'),
        mediaDuration: row.readNullable<String>('mediaDuration'),
        stickerId: row.readNullable<String>('stickerId'),
        assetUrl: row.readNullable<String>('assetUrl'),
        assetWidth: row.readNullable<int>('assetWidth'),
        assetHeight: row.readNullable<int>('assetHeight'),
        assetName: row.readNullable<String>('assetName'),
        assetType: row.readNullable<String>('assetType'),
        sharedUserId: row.readNullable<String>('sharedUserId'),
        sharedUserFullName: row.readNullable<String>('sharedUserFullName'),
        sharedUserIdentityNumber:
            row.readNullable<String>('sharedUserIdentityNumber'),
        sharedUserAvatarUrl: row.readNullable<String>('sharedUserAvatarUrl'),
        sharedUserIsVerified: row.readNullable<bool>('sharedUserIsVerified'),
        sharedUserAppId: row.readNullable<String>('sharedUserAppId'),
      );
    });
  }

  Selectable<MessageStatus> findMessageStatusById(String messageId) {
    return customSelect(
        'SELECT status FROM messages WHERE message_id = ?1 LIMIT 1',
        variables: [
          Variable<String>(messageId)
        ],
        readsFrom: {
          messages,
        }).map((QueryRow row) =>
        Messages.$converterstatus.fromSql(row.read<String>('status')));
  }

  Selectable<SendingMessage> sendingMessage(String messageId) {
    return customSelect(
        'SELECT m.message_id, m.conversation_id, m.user_id, m.category, m.content, m.media_url, m.media_mime_type, m.media_size, m.media_duration, m.media_width, m.media_height, m.media_hash, m.thumb_image, m.media_key, m.media_digest, m.media_status, m.status, m.created_at, m."action", m.participant_id, m.snapshot_id, m.hyperlink, m.name, m.album_id, m.sticker_id, m.shared_user_id, m.media_waveform, m.quote_message_id, m.quote_content, rm.status AS resend_status, rm.user_id AS resend_user_id, rm.session_id AS resend_session_id FROM messages AS m LEFT JOIN resend_session_messages AS rm ON m.message_id = rm.message_id WHERE m.message_id = ?1 AND(m.status = \'SENDING\' OR rm.status = 1)AND m.content IS NOT NULL LIMIT 1',
        variables: [
          Variable<String>(messageId)
        ],
        readsFrom: {
          messages,
          resendSessionMessages,
        }).map((QueryRow row) {
      return SendingMessage(
        messageId: row.read<String>('message_id'),
        conversationId: row.read<String>('conversation_id'),
        userId: row.read<String>('user_id'),
        category: row.read<String>('category'),
        content: row.readNullable<String>('content'),
        mediaUrl: row.readNullable<String>('media_url'),
        mediaMimeType: row.readNullable<String>('media_mime_type'),
        mediaSize: row.readNullable<int>('media_size'),
        mediaDuration: row.readNullable<String>('media_duration'),
        mediaWidth: row.readNullable<int>('media_width'),
        mediaHeight: row.readNullable<int>('media_height'),
        mediaHash: row.readNullable<String>('media_hash'),
        thumbImage: row.readNullable<String>('thumb_image'),
        mediaKey: row.readNullable<String>('media_key'),
        mediaDigest: row.readNullable<String>('media_digest'),
        mediaStatus: Messages.$convertermediaStatus
            .fromSql(row.readNullable<String>('media_status')),
        status: Messages.$converterstatus.fromSql(row.read<String>('status')),
        createdAt:
            Messages.$convertercreatedAt.fromSql(row.read<int>('created_at')),
        action: row.readNullable<String>('action'),
        participantId: row.readNullable<String>('participant_id'),
        snapshotId: row.readNullable<String>('snapshot_id'),
        hyperlink: row.readNullable<String>('hyperlink'),
        name: row.readNullable<String>('name'),
        albumId: row.readNullable<String>('album_id'),
        stickerId: row.readNullable<String>('sticker_id'),
        sharedUserId: row.readNullable<String>('shared_user_id'),
        mediaWaveform: row.readNullable<String>('media_waveform'),
        quoteMessageId: row.readNullable<String>('quote_message_id'),
        quoteContent: row.readNullable<String>('quote_content'),
        resendStatus: row.readNullable<int>('resend_status'),
        resendUserId: row.readNullable<String>('resend_user_id'),
        resendSessionId: row.readNullable<String>('resend_session_id'),
      );
    });
  }

  Selectable<NotificationMessage> notificationMessage(List<String> messageId) {
    var $arrayStartIndex = 1;
    final expandedmessageId = $expandVar($arrayStartIndex, messageId.length);
    $arrayStartIndex += messageId.length;
    return customSelect(
        'SELECT m.message_id AS messageId, m.conversation_id AS conversationId, sender.user_id AS senderId, sender.full_name AS senderFullName, m.category AS type, m.content AS content, m.quote_content AS quoteContent, m.status AS status, c.name AS groupName, c.mute_until AS muteUntil, conversationOwner.mute_until AS ownerMuteUntil, conversationOwner.user_id AS ownerUserId, conversationOwner.full_name AS ownerFullName, m.created_at AS createdAt, c.category AS category, m."action" AS actionName, conversationOwner.relationship AS relationship, pu.full_name AS participantFullName, pu.user_id AS participantUserId FROM messages AS m INNER JOIN users AS sender ON m.user_id = sender.user_id LEFT JOIN conversations AS c ON m.conversation_id = c.conversation_id LEFT JOIN users AS conversationOwner ON c.owner_id = conversationOwner.user_id LEFT JOIN message_mentions AS mm ON m.message_id = mm.message_id LEFT JOIN users AS pu ON pu.user_id = m.participant_id WHERE m.message_id IN ($expandedmessageId) ORDER BY m.created_at DESC',
        variables: [
          for (var $ in messageId) Variable<String>($)
        ],
        readsFrom: {
          messages,
          users,
          conversations,
          messageMentions,
        }).map((QueryRow row) {
      return NotificationMessage(
        messageId: row.read<String>('messageId'),
        conversationId: row.read<String>('conversationId'),
        senderId: row.read<String>('senderId'),
        senderFullName: row.readNullable<String>('senderFullName'),
        type: row.read<String>('type'),
        content: row.readNullable<String>('content'),
        quoteContent: row.readNullable<String>('quoteContent'),
        status: Messages.$converterstatus.fromSql(row.read<String>('status')),
        groupName: row.readNullable<String>('groupName'),
        muteUntil: NullAwareTypeConverter.wrapFromSql(
            Conversations.$convertermuteUntil,
            row.readNullable<int>('muteUntil')),
        ownerMuteUntil: NullAwareTypeConverter.wrapFromSql(
            Users.$convertermuteUntil, row.readNullable<int>('ownerMuteUntil')),
        ownerUserId: row.readNullable<String>('ownerUserId'),
        ownerFullName: row.readNullable<String>('ownerFullName'),
        createdAt:
            Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
        category: Conversations.$convertercategory
            .fromSql(row.readNullable<String>('category')),
        actionName: row.readNullable<String>('actionName'),
        relationship: Users.$converterrelationship
            .fromSql(row.readNullable<String>('relationship')),
        participantFullName: row.readNullable<String>('participantFullName'),
        participantUserId: row.readNullable<String>('participantUserId'),
      );
    });
  }

  Future<int> updateUnseenMessageCountAndLastMessageId(String conversationId,
      String userId, String? lastMessageId, DateTime? lastMessageCreatedAt) {
    return customUpdate(
      'UPDATE conversations SET unseen_message_count = (SELECT count(1) FROM messages WHERE conversation_id = ?1 AND status IN (\'SENT\', \'DELIVERED\') AND user_id != ?2), last_message_id = ?3, last_message_created_at = ?4 WHERE conversation_id = ?1',
      variables: [
        Variable<String>(conversationId),
        Variable<String>(userId),
        Variable<String>(lastMessageId),
        Variable<int>(NullAwareTypeConverter.wrapToSql(
            Conversations.$converterlastMessageCreatedAt, lastMessageCreatedAt))
      ],
      updates: {conversations},
      updateKind: UpdateKind.update,
    );
  }

  Selectable<SearchMessageDetailItem> getSearchMessageByIds(
      List<String> messageIds) {
    var $arrayStartIndex = 1;
    final expandedmessageIds = $expandVar($arrayStartIndex, messageIds.length);
    $arrayStartIndex += messageIds.length;
    return customSelect(
        'SELECT m.message_id AS messageId, u.user_id AS senderId, u.avatar_url AS senderAvatarUrl, u.full_name AS senderFullName, m.status AS status, m.category AS type, m.content AS content, m.created_at AS createdAt, m.name AS mediaName, u.app_id AS appId, u.is_verified AS verified, c.owner_id AS ownerId, c.icon_url AS groupIconUrl, c.category AS category, c.name AS groupName, c.conversation_id AS conversationId, owner.full_name AS ownerFullName, owner.avatar_url AS ownerAvatarUrl FROM messages AS m INNER JOIN conversations AS c ON c.conversation_id = m.conversation_id INNER JOIN users AS u ON m.user_id = u.user_id INNER JOIN users AS owner ON c.owner_id = owner.user_id WHERE m.message_id IN ($expandedmessageIds) ORDER BY m.created_at DESC, m."rowid" DESC',
        variables: [
          for (var $ in messageIds) Variable<String>($)
        ],
        readsFrom: {
          messages,
          users,
          conversations,
        }).map((QueryRow row) {
      return SearchMessageDetailItem(
        messageId: row.read<String>('messageId'),
        senderId: row.read<String>('senderId'),
        senderAvatarUrl: row.readNullable<String>('senderAvatarUrl'),
        senderFullName: row.readNullable<String>('senderFullName'),
        status: Messages.$converterstatus.fromSql(row.read<String>('status')),
        type: row.read<String>('type'),
        content: row.readNullable<String>('content'),
        createdAt:
            Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
        mediaName: row.readNullable<String>('mediaName'),
        appId: row.readNullable<String>('appId'),
        verified: row.readNullable<bool>('verified'),
        ownerId: row.readNullable<String>('ownerId'),
        groupIconUrl: row.readNullable<String>('groupIconUrl'),
        category: Conversations.$convertercategory
            .fromSql(row.readNullable<String>('category')),
        groupName: row.readNullable<String>('groupName'),
        conversationId: row.read<String>('conversationId'),
        ownerFullName: row.readNullable<String>('ownerFullName'),
        ownerAvatarUrl: row.readNullable<String>('ownerAvatarUrl'),
      );
    });
  }

  Selectable<MiniMessageItem> miniMessageByIds(List<String> messageIds) {
    var $arrayStartIndex = 1;
    final expandedmessageIds = $expandVar($arrayStartIndex, messageIds.length);
    $arrayStartIndex += messageIds.length;
    return customSelect(
        'SELECT conversation_id AS conversationId, message_id AS messageId FROM messages WHERE message_id IN ($expandedmessageIds)',
        variables: [
          for (var $ in messageIds) Variable<String>($)
        ],
        readsFrom: {
          messages,
        }).map((QueryRow row) {
      return MiniMessageItem(
        conversationId: row.read<String>('conversationId'),
        messageId: row.read<String>('messageId'),
      );
    });
  }

  Selectable<SearchMessageDetailItem> searchMessage(
      SearchMessage$where where, SearchMessage$limit limit) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(alias(this.messages, 'm'), alias(this.conversations, 'c'),
            alias(this.users, 'u'), alias(this.users, 'owner')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedlimit = $write(
        limit(alias(this.messages, 'm'), alias(this.conversations, 'c'),
            alias(this.users, 'u'), alias(this.users, 'owner')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT m.message_id AS messageId, u.user_id AS senderId, u.avatar_url AS senderAvatarUrl, u.full_name AS senderFullName, m.status AS status, m.category AS type, m.content AS content, m.created_at AS createdAt, m.name AS mediaName, u.app_id AS appId, u.is_verified AS verified, c.owner_id AS ownerId, c.icon_url AS groupIconUrl, c.category AS category, c.name AS groupName, c.conversation_id AS conversationId, owner.full_name AS ownerFullName, owner.avatar_url AS ownerAvatarUrl FROM messages AS m INNER JOIN conversations AS c ON c.conversation_id = m.conversation_id INNER JOIN users AS u ON m.user_id = u.user_id INNER JOIN users AS owner ON c.owner_id = owner.user_id WHERE ${generatedwhere.sql} ORDER BY m.created_at DESC, m."rowid" DESC ${generatedlimit.sql}',
        variables: [
          ...generatedwhere.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          messages,
          users,
          conversations,
          ...generatedwhere.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) {
      return SearchMessageDetailItem(
        messageId: row.read<String>('messageId'),
        senderId: row.read<String>('senderId'),
        senderAvatarUrl: row.readNullable<String>('senderAvatarUrl'),
        senderFullName: row.readNullable<String>('senderFullName'),
        status: Messages.$converterstatus.fromSql(row.read<String>('status')),
        type: row.read<String>('type'),
        content: row.readNullable<String>('content'),
        createdAt:
            Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
        mediaName: row.readNullable<String>('mediaName'),
        appId: row.readNullable<String>('appId'),
        verified: row.readNullable<bool>('verified'),
        ownerId: row.readNullable<String>('ownerId'),
        groupIconUrl: row.readNullable<String>('groupIconUrl'),
        category: Conversations.$convertercategory
            .fromSql(row.readNullable<String>('category')),
        groupName: row.readNullable<String>('groupName'),
        conversationId: row.read<String>('conversationId'),
        ownerFullName: row.readNullable<String>('ownerFullName'),
        ownerAvatarUrl: row.readNullable<String>('ownerAvatarUrl'),
      );
    });
  }

  Selectable<int> countMessages() {
    return customSelect('SELECT count(1) AS _c0 FROM messages',
        variables: [],
        readsFrom: {
          messages,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<int> countMediaMessages() {
    return customSelect(
        'SELECT count(1) AS _c0 FROM messages WHERE category IN (\'SIGNAL_IMAGE\', \'SIGNAL_VIDEO\', \'SIGNAL_DATA\', \'SIGNAL_AUDIO\', \'PLAIN_IMAGE\', \'PLAIN_VIDEO\', \'PLAIN_DATA\', \'PLAIN_AUDIO\', \'ENCRYPTED_IMAGE\', \'ENCRYPTED_VIDEO\', \'ENCRYPTED_DATA\', \'ENCRYPTED_AUDIO\')',
        variables: [],
        readsFrom: {
          messages,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<QuoteMinimal> findBigQuoteMessage(int rowId, int limit) {
    return customSelect(
        'SELECT "rowid", conversation_id, quote_message_id FROM messages WHERE "rowid" > ?1 AND quote_message_id IS NOT NULL AND quote_message_id != \'\' AND length(quote_content) > 10240 GROUP BY quote_message_id ORDER BY "rowid" ASC LIMIT ?2',
        variables: [
          Variable<int>(rowId),
          Variable<int>(limit)
        ],
        readsFrom: {
          messages,
        }).map((QueryRow row) {
      return QuoteMinimal(
        rowid: row.read<int>('rowid'),
        conversationId: row.read<String>('conversation_id'),
        quoteMessageId: row.readNullable<String>('quote_message_id'),
      );
    });
  }

  Selectable<MessageItem> basePinMessageItems(String conversationId,
      BasePinMessageItems$order order, BasePinMessageItems$limit limit) {
    var $arrayStartIndex = 2;
    final generatedorder = $write(
        order?.call(
                alias(this.pinMessages, 'pinMessage'),
                alias(this.messages, 'message'),
                alias(this.users, 'sender'),
                alias(this.users, 'participant'),
                alias(this.snapshots, 'snapshot'),
                alias(this.assets, 'asset'),
                alias(this.chains, 'chain'),
                alias(this.stickers, 'sticker'),
                alias(this.hyperlinks, 'hyperlink'),
                alias(this.users, 'sharedUser'),
                alias(this.conversations, 'conversation'),
                alias(this.messageMentions, 'messageMention'),
                alias(this.expiredMessages, 'em')) ??
            const OrderBy.nothing(),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedorder.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.pinMessages, 'pinMessage'),
            alias(this.messages, 'message'),
            alias(this.users, 'sender'),
            alias(this.users, 'participant'),
            alias(this.snapshots, 'snapshot'),
            alias(this.assets, 'asset'),
            alias(this.chains, 'chain'),
            alias(this.stickers, 'sticker'),
            alias(this.hyperlinks, 'hyperlink'),
            alias(this.users, 'sharedUser'),
            alias(this.conversations, 'conversation'),
            alias(this.messageMentions, 'messageMention'),
            alias(this.expiredMessages, 'em')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT message.message_id AS messageId, message.conversation_id AS conversationId, message.category AS type, message.content AS content, message.created_at AS createdAt, message.status AS status, message.media_status AS mediaStatus, message.media_waveform AS mediaWaveform, message.name AS mediaName, message.media_mime_type AS mediaMimeType, message.media_size AS mediaSize, message.media_width AS mediaWidth, message.media_height AS mediaHeight, message.thumb_image AS thumbImage, message.thumb_url AS thumbUrl, message.media_url AS mediaUrl, message.media_duration AS mediaDuration, message.quote_message_id AS quoteId, message.quote_content AS quoteContent, message."action" AS actionName, message.shared_user_id AS sharedUserId, sender.user_id AS userId, sender.full_name AS userFullName, sender.identity_number AS userIdentityNumber, sender.app_id AS appId, sender.relationship AS relationship, sender.avatar_url AS avatarUrl, sharedUser.full_name AS sharedUserFullName, sharedUser.identity_number AS sharedUserIdentityNumber, sharedUser.avatar_url AS sharedUserAvatarUrl, sharedUser.is_verified AS sharedUserIsVerified, sharedUser.app_id AS sharedUserAppId, conversation.owner_id AS conversationOwnerId, conversation.category AS conversionCategory, conversation.name AS groupName, sticker.asset_url AS assetUrl, sticker.asset_width AS assetWidth, sticker.asset_height AS assetHeight, sticker.sticker_id AS stickerId, sticker.name AS assetName, sticker.asset_type AS assetType, participant.full_name AS participantFullName, participant.user_id AS participantUserId, snapshot.snapshot_id AS snapshotId, snapshot.type AS snapshotType, snapshot.amount AS snapshotAmount, snapshot.asset_id AS assetId, asset.symbol AS assetSymbol, asset.icon_url AS assetIcon, chain.icon_url AS chainIcon, hyperlink.site_name AS siteName, hyperlink.site_title AS siteTitle, hyperlink.site_description AS siteDescription, hyperlink.site_image AS siteImage, messageMention.has_read AS mentionRead, em.expire_in AS expireIn, CASE WHEN pinMessage.message_id IS NOT NULL THEN TRUE ELSE FALSE END AS pinned FROM pin_messages AS pinMessage INNER JOIN messages AS message ON message.message_id = pinMessage.message_id INNER JOIN users AS sender ON message.user_id = sender.user_id LEFT JOIN users AS participant ON message.participant_id = participant.user_id LEFT JOIN snapshots AS snapshot ON message.snapshot_id = snapshot.snapshot_id LEFT JOIN assets AS asset ON snapshot.asset_id = asset.asset_id LEFT JOIN chains AS chain ON asset.chain_id = chain.chain_id LEFT JOIN stickers AS sticker ON sticker.sticker_id = message.sticker_id LEFT JOIN hyperlinks AS hyperlink ON message.hyperlink = hyperlink.hyperlink LEFT JOIN users AS sharedUser ON message.shared_user_id = sharedUser.user_id LEFT JOIN conversations AS conversation ON message.conversation_id = conversation.conversation_id LEFT JOIN message_mentions AS messageMention ON message.message_id = messageMention.message_id LEFT JOIN expired_messages AS em ON message.message_id = em.message_id WHERE pinMessage.conversation_id = ?1 ${generatedorder.sql} ${generatedlimit.sql}',
        variables: [
          Variable<String>(conversationId),
          ...generatedorder.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          messages,
          users,
          conversations,
          stickers,
          snapshots,
          assets,
          chains,
          hyperlinks,
          messageMentions,
          expiredMessages,
          pinMessages,
          ...generatedorder.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) {
      return MessageItem(
        messageId: row.read<String>('messageId'),
        conversationId: row.read<String>('conversationId'),
        type: row.read<String>('type'),
        content: row.readNullable<String>('content'),
        createdAt:
            Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
        status: Messages.$converterstatus.fromSql(row.read<String>('status')),
        mediaStatus: Messages.$convertermediaStatus
            .fromSql(row.readNullable<String>('mediaStatus')),
        mediaWaveform: row.readNullable<String>('mediaWaveform'),
        mediaName: row.readNullable<String>('mediaName'),
        mediaMimeType: row.readNullable<String>('mediaMimeType'),
        mediaSize: row.readNullable<int>('mediaSize'),
        mediaWidth: row.readNullable<int>('mediaWidth'),
        mediaHeight: row.readNullable<int>('mediaHeight'),
        thumbImage: row.readNullable<String>('thumbImage'),
        thumbUrl: row.readNullable<String>('thumbUrl'),
        mediaUrl: row.readNullable<String>('mediaUrl'),
        mediaDuration: row.readNullable<String>('mediaDuration'),
        quoteId: row.readNullable<String>('quoteId'),
        quoteContent: row.readNullable<String>('quoteContent'),
        actionName: row.readNullable<String>('actionName'),
        sharedUserId: row.readNullable<String>('sharedUserId'),
        stickerId: row.readNullable<String>('stickerId'),
        userId: row.read<String>('userId'),
        userFullName: row.readNullable<String>('userFullName'),
        userIdentityNumber: row.read<String>('userIdentityNumber'),
        appId: row.readNullable<String>('appId'),
        relationship: Users.$converterrelationship
            .fromSql(row.readNullable<String>('relationship')),
        avatarUrl: row.readNullable<String>('avatarUrl'),
        sharedUserFullName: row.readNullable<String>('sharedUserFullName'),
        sharedUserIdentityNumber:
            row.readNullable<String>('sharedUserIdentityNumber'),
        sharedUserAvatarUrl: row.readNullable<String>('sharedUserAvatarUrl'),
        sharedUserIsVerified: row.readNullable<bool>('sharedUserIsVerified'),
        sharedUserAppId: row.readNullable<String>('sharedUserAppId'),
        conversationOwnerId: row.readNullable<String>('conversationOwnerId'),
        conversionCategory: Conversations.$convertercategory
            .fromSql(row.readNullable<String>('conversionCategory')),
        groupName: row.readNullable<String>('groupName'),
        assetUrl: row.readNullable<String>('assetUrl'),
        assetWidth: row.readNullable<int>('assetWidth'),
        assetHeight: row.readNullable<int>('assetHeight'),
        assetName: row.readNullable<String>('assetName'),
        assetType: row.readNullable<String>('assetType'),
        participantFullName: row.readNullable<String>('participantFullName'),
        participantUserId: row.readNullable<String>('participantUserId'),
        snapshotId: row.readNullable<String>('snapshotId'),
        snapshotType: row.readNullable<String>('snapshotType'),
        snapshotAmount: row.readNullable<String>('snapshotAmount'),
        assetId: row.readNullable<String>('assetId'),
        assetSymbol: row.readNullable<String>('assetSymbol'),
        assetIcon: row.readNullable<String>('assetIcon'),
        chainIcon: row.readNullable<String>('chainIcon'),
        siteName: row.readNullable<String>('siteName'),
        siteTitle: row.readNullable<String>('siteTitle'),
        siteDescription: row.readNullable<String>('siteDescription'),
        siteImage: row.readNullable<String>('siteImage'),
        mentionRead: row.readNullable<bool>('mentionRead'),
        expireIn: row.readNullable<int>('expireIn'),
        pinned: row.read<bool>('pinned'),
      );
    });
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        conversations,
        messages,
        participants,
        circleConversations,
        participantSession,
        snapshots,
        assets,
        chains,
        stickers,
        hyperlinks,
        messageMentions,
        pinMessages,
        expiredMessages,
        resendSessionMessages,
        addresses,
        apps,
        circles,
        floodMessages,
        jobs,
        messagesHistory,
        offsets,
        sentSessionSenderKeys,
        stickerAlbums,
        stickerRelationships,
        transcriptMessages,
        fiats,
        favoriteApps,
        properties,
        indexConversationsCategoryStatus,
        indexConversationsMuteUntil,
        indexFloodMessagesCreatedAt,
        indexJobsAction,
        indexMessageMentionsConversationIdHasRead,
        indexParticipantsConversationIdCreatedAt,
        indexStickerAlbumsCategoryCreatedAt,
        indexPinMessagesConversationId,
        indexUsersIdentityNumber,
        indexMessagesConversationIdCreatedAt,
        indexMessagesConversationIdCategoryCreatedAt,
        indexMessageConversationIdStatusUserId,
        indexMessagesConversationIdQuoteMessageId
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
        ],
      );
}

typedef FuzzySearchUser$firstFilter = Expression<bool> Function(
    Users users, Conversations conversations);
typedef FuzzySearchUser$lastFilter = Expression<bool> Function(
    Users users, Conversations conversations);
typedef FuzzySearchUserInCircle$filter = Expression<bool> Function(Users users,
    Conversations conversations, CircleConversations circleConversation);

class MentionUser {
  final String userId;
  final String identityNumber;
  final String? fullName;
  MentionUser({
    required this.userId,
    required this.identityNumber,
    this.fullName,
  });
  @override
  int get hashCode => Object.hash(userId, identityNumber, fullName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MentionUser &&
          other.userId == this.userId &&
          other.identityNumber == this.identityNumber &&
          other.fullName == this.fullName);
  @override
  String toString() {
    return (StringBuffer('MentionUser(')
          ..write('userId: $userId, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('fullName: $fullName')
          ..write(')'))
        .toString();
  }
}

class ParticipantSessionKey {
  final String conversationId;
  final String userId;
  final String sessionId;
  final String? publicKey;
  ParticipantSessionKey({
    required this.conversationId,
    required this.userId,
    required this.sessionId,
    this.publicKey,
  });
  @override
  int get hashCode => Object.hash(conversationId, userId, sessionId, publicKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParticipantSessionKey &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.publicKey == this.publicKey);
  @override
  String toString() {
    return (StringBuffer('ParticipantSessionKey(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('publicKey: $publicKey')
          ..write(')'))
        .toString();
  }
}

class ParticipantUser {
  final String conversationId;
  final ParticipantRole? role;
  final DateTime createdAt;
  final String userId;
  final String identityNumber;
  final UserRelationship? relationship;
  final String? biography;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final bool? isVerified;
  final DateTime? userCreatedAt;
  final DateTime? muteUntil;
  final int? hasPin;
  final String? appId;
  final int? isScam;
  ParticipantUser({
    required this.conversationId,
    this.role,
    required this.createdAt,
    required this.userId,
    required this.identityNumber,
    this.relationship,
    this.biography,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.isVerified,
    this.userCreatedAt,
    this.muteUntil,
    this.hasPin,
    this.appId,
    this.isScam,
  });
  @override
  int get hashCode => Object.hash(
      conversationId,
      role,
      createdAt,
      userId,
      identityNumber,
      relationship,
      biography,
      fullName,
      avatarUrl,
      phone,
      isVerified,
      userCreatedAt,
      muteUntil,
      hasPin,
      appId,
      isScam);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParticipantUser &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.createdAt == this.createdAt &&
          other.userId == this.userId &&
          other.identityNumber == this.identityNumber &&
          other.relationship == this.relationship &&
          other.biography == this.biography &&
          other.fullName == this.fullName &&
          other.avatarUrl == this.avatarUrl &&
          other.phone == this.phone &&
          other.isVerified == this.isVerified &&
          other.userCreatedAt == this.userCreatedAt &&
          other.muteUntil == this.muteUntil &&
          other.hasPin == this.hasPin &&
          other.appId == this.appId &&
          other.isScam == this.isScam);
  @override
  String toString() {
    return (StringBuffer('ParticipantUser(')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('relationship: $relationship, ')
          ..write('biography: $biography, ')
          ..write('fullName: $fullName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('phone: $phone, ')
          ..write('isVerified: $isVerified, ')
          ..write('userCreatedAt: $userCreatedAt, ')
          ..write('muteUntil: $muteUntil, ')
          ..write('hasPin: $hasPin, ')
          ..write('appId: $appId, ')
          ..write('isScam: $isScam')
          ..write(')'))
        .toString();
  }
}

class MessageItem {
  final String messageId;
  final String conversationId;
  final String type;
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
  final String? actionName;
  final String? sharedUserId;
  final String? stickerId;
  final String userId;
  final String? userFullName;
  final String userIdentityNumber;
  final String? appId;
  final UserRelationship? relationship;
  final String? avatarUrl;
  final String? sharedUserFullName;
  final String? sharedUserIdentityNumber;
  final String? sharedUserAvatarUrl;
  final bool? sharedUserIsVerified;
  final String? sharedUserAppId;
  final String? conversationOwnerId;
  final ConversationCategory? conversionCategory;
  final String? groupName;
  final String? assetUrl;
  final int? assetWidth;
  final int? assetHeight;
  final String? assetName;
  final String? assetType;
  final String? participantFullName;
  final String? participantUserId;
  final String? snapshotId;
  final String? snapshotType;
  final String? snapshotAmount;
  final String? assetId;
  final String? assetSymbol;
  final String? assetIcon;
  final String? chainIcon;
  final String? siteName;
  final String? siteTitle;
  final String? siteDescription;
  final String? siteImage;
  final bool? mentionRead;
  final int? expireIn;
  final bool pinned;
  MessageItem({
    required this.messageId,
    required this.conversationId,
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
    this.actionName,
    this.sharedUserId,
    this.stickerId,
    required this.userId,
    this.userFullName,
    required this.userIdentityNumber,
    this.appId,
    this.relationship,
    this.avatarUrl,
    this.sharedUserFullName,
    this.sharedUserIdentityNumber,
    this.sharedUserAvatarUrl,
    this.sharedUserIsVerified,
    this.sharedUserAppId,
    this.conversationOwnerId,
    this.conversionCategory,
    this.groupName,
    this.assetUrl,
    this.assetWidth,
    this.assetHeight,
    this.assetName,
    this.assetType,
    this.participantFullName,
    this.participantUserId,
    this.snapshotId,
    this.snapshotType,
    this.snapshotAmount,
    this.assetId,
    this.assetSymbol,
    this.assetIcon,
    this.chainIcon,
    this.siteName,
    this.siteTitle,
    this.siteDescription,
    this.siteImage,
    this.mentionRead,
    this.expireIn,
    required this.pinned,
  });
  @override
  int get hashCode => Object.hashAll([
        messageId,
        conversationId,
        type,
        content,
        createdAt,
        status,
        mediaStatus,
        mediaWaveform,
        mediaName,
        mediaMimeType,
        mediaSize,
        mediaWidth,
        mediaHeight,
        thumbImage,
        thumbUrl,
        mediaUrl,
        mediaDuration,
        quoteId,
        quoteContent,
        actionName,
        sharedUserId,
        stickerId,
        userId,
        userFullName,
        userIdentityNumber,
        appId,
        relationship,
        avatarUrl,
        sharedUserFullName,
        sharedUserIdentityNumber,
        sharedUserAvatarUrl,
        sharedUserIsVerified,
        sharedUserAppId,
        conversationOwnerId,
        conversionCategory,
        groupName,
        assetUrl,
        assetWidth,
        assetHeight,
        assetName,
        assetType,
        participantFullName,
        participantUserId,
        snapshotId,
        snapshotType,
        snapshotAmount,
        assetId,
        assetSymbol,
        assetIcon,
        chainIcon,
        siteName,
        siteTitle,
        siteDescription,
        siteImage,
        mentionRead,
        expireIn,
        pinned
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageItem &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
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
          other.actionName == this.actionName &&
          other.sharedUserId == this.sharedUserId &&
          other.stickerId == this.stickerId &&
          other.userId == this.userId &&
          other.userFullName == this.userFullName &&
          other.userIdentityNumber == this.userIdentityNumber &&
          other.appId == this.appId &&
          other.relationship == this.relationship &&
          other.avatarUrl == this.avatarUrl &&
          other.sharedUserFullName == this.sharedUserFullName &&
          other.sharedUserIdentityNumber == this.sharedUserIdentityNumber &&
          other.sharedUserAvatarUrl == this.sharedUserAvatarUrl &&
          other.sharedUserIsVerified == this.sharedUserIsVerified &&
          other.sharedUserAppId == this.sharedUserAppId &&
          other.conversationOwnerId == this.conversationOwnerId &&
          other.conversionCategory == this.conversionCategory &&
          other.groupName == this.groupName &&
          other.assetUrl == this.assetUrl &&
          other.assetWidth == this.assetWidth &&
          other.assetHeight == this.assetHeight &&
          other.assetName == this.assetName &&
          other.assetType == this.assetType &&
          other.participantFullName == this.participantFullName &&
          other.participantUserId == this.participantUserId &&
          other.snapshotId == this.snapshotId &&
          other.snapshotType == this.snapshotType &&
          other.snapshotAmount == this.snapshotAmount &&
          other.assetId == this.assetId &&
          other.assetSymbol == this.assetSymbol &&
          other.assetIcon == this.assetIcon &&
          other.chainIcon == this.chainIcon &&
          other.siteName == this.siteName &&
          other.siteTitle == this.siteTitle &&
          other.siteDescription == this.siteDescription &&
          other.siteImage == this.siteImage &&
          other.mentionRead == this.mentionRead &&
          other.expireIn == this.expireIn &&
          other.pinned == this.pinned);
  @override
  String toString() {
    return (StringBuffer('MessageItem(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
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
          ..write('actionName: $actionName, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('stickerId: $stickerId, ')
          ..write('userId: $userId, ')
          ..write('userFullName: $userFullName, ')
          ..write('userIdentityNumber: $userIdentityNumber, ')
          ..write('appId: $appId, ')
          ..write('relationship: $relationship, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('sharedUserFullName: $sharedUserFullName, ')
          ..write('sharedUserIdentityNumber: $sharedUserIdentityNumber, ')
          ..write('sharedUserAvatarUrl: $sharedUserAvatarUrl, ')
          ..write('sharedUserIsVerified: $sharedUserIsVerified, ')
          ..write('sharedUserAppId: $sharedUserAppId, ')
          ..write('conversationOwnerId: $conversationOwnerId, ')
          ..write('conversionCategory: $conversionCategory, ')
          ..write('groupName: $groupName, ')
          ..write('assetUrl: $assetUrl, ')
          ..write('assetWidth: $assetWidth, ')
          ..write('assetHeight: $assetHeight, ')
          ..write('assetName: $assetName, ')
          ..write('assetType: $assetType, ')
          ..write('participantFullName: $participantFullName, ')
          ..write('participantUserId: $participantUserId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('snapshotType: $snapshotType, ')
          ..write('snapshotAmount: $snapshotAmount, ')
          ..write('assetId: $assetId, ')
          ..write('assetSymbol: $assetSymbol, ')
          ..write('assetIcon: $assetIcon, ')
          ..write('chainIcon: $chainIcon, ')
          ..write('siteName: $siteName, ')
          ..write('siteTitle: $siteTitle, ')
          ..write('siteDescription: $siteDescription, ')
          ..write('siteImage: $siteImage, ')
          ..write('mentionRead: $mentionRead, ')
          ..write('expireIn: $expireIn, ')
          ..write('pinned: $pinned')
          ..write(')'))
        .toString();
  }
}

typedef BaseMessageItems$where = Expression<bool> Function(
    Messages message,
    Users sender,
    Users participant,
    Snapshots snapshot,
    Assets asset,
    Chains chain,
    Stickers sticker,
    Hyperlinks hyperlink,
    Users sharedUser,
    Conversations conversation,
    MessageMentions messageMention,
    PinMessages pinMessage,
    ExpiredMessages em);
typedef BaseMessageItems$order = OrderBy Function(
    Messages message,
    Users sender,
    Users participant,
    Snapshots snapshot,
    Assets asset,
    Chains chain,
    Stickers sticker,
    Hyperlinks hyperlink,
    Users sharedUser,
    Conversations conversation,
    MessageMentions messageMention,
    PinMessages pinMessage,
    ExpiredMessages em);
typedef BaseMessageItems$limit = Limit Function(
    Messages message,
    Users sender,
    Users participant,
    Snapshots snapshot,
    Assets asset,
    Chains chain,
    Stickers sticker,
    Hyperlinks hyperlink,
    Users sharedUser,
    Conversations conversation,
    MessageMentions messageMention,
    PinMessages pinMessage,
    ExpiredMessages em);

class QuoteMessageItem {
  final String messageId;
  final String conversationId;
  final String userId;
  final String? userFullName;
  final String userIdentityNumber;
  final String? appId;
  final String type;
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
  final String? stickerId;
  final String? assetUrl;
  final int? assetWidth;
  final int? assetHeight;
  final String? assetName;
  final String? assetType;
  final String? sharedUserId;
  final String? sharedUserFullName;
  final String? sharedUserIdentityNumber;
  final String? sharedUserAvatarUrl;
  final bool? sharedUserIsVerified;
  final String? sharedUserAppId;
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
    this.stickerId,
    this.assetUrl,
    this.assetWidth,
    this.assetHeight,
    this.assetName,
    this.assetType,
    this.sharedUserId,
    this.sharedUserFullName,
    this.sharedUserIdentityNumber,
    this.sharedUserAvatarUrl,
    this.sharedUserIsVerified,
    this.sharedUserAppId,
  });
  @override
  int get hashCode => Object.hashAll([
        messageId,
        conversationId,
        userId,
        userFullName,
        userIdentityNumber,
        appId,
        type,
        content,
        createdAt,
        status,
        mediaStatus,
        mediaWaveform,
        mediaName,
        mediaMimeType,
        mediaSize,
        mediaWidth,
        mediaHeight,
        thumbImage,
        thumbUrl,
        mediaUrl,
        mediaDuration,
        stickerId,
        assetUrl,
        assetWidth,
        assetHeight,
        assetName,
        assetType,
        sharedUserId,
        sharedUserFullName,
        sharedUserIdentityNumber,
        sharedUserAvatarUrl,
        sharedUserIsVerified,
        sharedUserAppId
      ]);
  @override
  bool operator ==(Object other) =>
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
          other.stickerId == this.stickerId &&
          other.assetUrl == this.assetUrl &&
          other.assetWidth == this.assetWidth &&
          other.assetHeight == this.assetHeight &&
          other.assetName == this.assetName &&
          other.assetType == this.assetType &&
          other.sharedUserId == this.sharedUserId &&
          other.sharedUserFullName == this.sharedUserFullName &&
          other.sharedUserIdentityNumber == this.sharedUserIdentityNumber &&
          other.sharedUserAvatarUrl == this.sharedUserAvatarUrl &&
          other.sharedUserIsVerified == this.sharedUserIsVerified &&
          other.sharedUserAppId == this.sharedUserAppId);
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
          ..write('stickerId: $stickerId, ')
          ..write('assetUrl: $assetUrl, ')
          ..write('assetWidth: $assetWidth, ')
          ..write('assetHeight: $assetHeight, ')
          ..write('assetName: $assetName, ')
          ..write('assetType: $assetType, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('sharedUserFullName: $sharedUserFullName, ')
          ..write('sharedUserIdentityNumber: $sharedUserIdentityNumber, ')
          ..write('sharedUserAvatarUrl: $sharedUserAvatarUrl, ')
          ..write('sharedUserIsVerified: $sharedUserIsVerified, ')
          ..write('sharedUserAppId: $sharedUserAppId')
          ..write(')'))
        .toString();
  }
}

typedef BaseQuoteMessageItem$where = Expression<bool> Function(
    Messages message,
    Users sender,
    Stickers sticker,
    Users shareUser,
    MessageMentions messageMention);
typedef BaseQuoteMessageItem$order = OrderBy Function(
    Messages message,
    Users sender,
    Stickers sticker,
    Users shareUser,
    MessageMentions messageMention);
typedef BaseQuoteMessageItem$limit = Limit Function(
    Messages message,
    Users sender,
    Stickers sticker,
    Users shareUser,
    MessageMentions messageMention);

class SendingMessage {
  final String messageId;
  final String conversationId;
  final String userId;
  final String category;
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
  final String? action;
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
  int get hashCode => Object.hashAll([
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
        resendStatus,
        resendUserId,
        resendSessionId
      ]);
  @override
  bool operator ==(Object other) =>
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

class NotificationMessage {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String? senderFullName;
  final String type;
  final String? content;
  final String? quoteContent;
  final MessageStatus status;
  final String? groupName;
  final DateTime? muteUntil;
  final DateTime? ownerMuteUntil;
  final String? ownerUserId;
  final String? ownerFullName;
  final DateTime createdAt;
  final ConversationCategory? category;
  final String? actionName;
  final UserRelationship? relationship;
  final String? participantFullName;
  final String? participantUserId;
  NotificationMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    this.senderFullName,
    required this.type,
    this.content,
    this.quoteContent,
    required this.status,
    this.groupName,
    this.muteUntil,
    this.ownerMuteUntil,
    this.ownerUserId,
    this.ownerFullName,
    required this.createdAt,
    this.category,
    this.actionName,
    this.relationship,
    this.participantFullName,
    this.participantUserId,
  });
  @override
  int get hashCode => Object.hash(
      messageId,
      conversationId,
      senderId,
      senderFullName,
      type,
      content,
      quoteContent,
      status,
      groupName,
      muteUntil,
      ownerMuteUntil,
      ownerUserId,
      ownerFullName,
      createdAt,
      category,
      actionName,
      relationship,
      participantFullName,
      participantUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationMessage &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.senderFullName == this.senderFullName &&
          other.type == this.type &&
          other.content == this.content &&
          other.quoteContent == this.quoteContent &&
          other.status == this.status &&
          other.groupName == this.groupName &&
          other.muteUntil == this.muteUntil &&
          other.ownerMuteUntil == this.ownerMuteUntil &&
          other.ownerUserId == this.ownerUserId &&
          other.ownerFullName == this.ownerFullName &&
          other.createdAt == this.createdAt &&
          other.category == this.category &&
          other.actionName == this.actionName &&
          other.relationship == this.relationship &&
          other.participantFullName == this.participantFullName &&
          other.participantUserId == this.participantUserId);
  @override
  String toString() {
    return (StringBuffer('NotificationMessage(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('senderFullName: $senderFullName, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('status: $status, ')
          ..write('groupName: $groupName, ')
          ..write('muteUntil: $muteUntil, ')
          ..write('ownerMuteUntil: $ownerMuteUntil, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('ownerFullName: $ownerFullName, ')
          ..write('createdAt: $createdAt, ')
          ..write('category: $category, ')
          ..write('actionName: $actionName, ')
          ..write('relationship: $relationship, ')
          ..write('participantFullName: $participantFullName, ')
          ..write('participantUserId: $participantUserId')
          ..write(')'))
        .toString();
  }
}

class SearchMessageDetailItem {
  final String messageId;
  final String senderId;
  final String? senderAvatarUrl;
  final String? senderFullName;
  final MessageStatus status;
  final String type;
  final String? content;
  final DateTime createdAt;
  final String? mediaName;
  final String? appId;
  final bool? verified;
  final String? ownerId;
  final String? groupIconUrl;
  final ConversationCategory? category;
  final String? groupName;
  final String conversationId;
  final String? ownerFullName;
  final String? ownerAvatarUrl;
  SearchMessageDetailItem({
    required this.messageId,
    required this.senderId,
    this.senderAvatarUrl,
    this.senderFullName,
    required this.status,
    required this.type,
    this.content,
    required this.createdAt,
    this.mediaName,
    this.appId,
    this.verified,
    this.ownerId,
    this.groupIconUrl,
    this.category,
    this.groupName,
    required this.conversationId,
    this.ownerFullName,
    this.ownerAvatarUrl,
  });
  @override
  int get hashCode => Object.hash(
      messageId,
      senderId,
      senderAvatarUrl,
      senderFullName,
      status,
      type,
      content,
      createdAt,
      mediaName,
      appId,
      verified,
      ownerId,
      groupIconUrl,
      category,
      groupName,
      conversationId,
      ownerFullName,
      ownerAvatarUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchMessageDetailItem &&
          other.messageId == this.messageId &&
          other.senderId == this.senderId &&
          other.senderAvatarUrl == this.senderAvatarUrl &&
          other.senderFullName == this.senderFullName &&
          other.status == this.status &&
          other.type == this.type &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.mediaName == this.mediaName &&
          other.appId == this.appId &&
          other.verified == this.verified &&
          other.ownerId == this.ownerId &&
          other.groupIconUrl == this.groupIconUrl &&
          other.category == this.category &&
          other.groupName == this.groupName &&
          other.conversationId == this.conversationId &&
          other.ownerFullName == this.ownerFullName &&
          other.ownerAvatarUrl == this.ownerAvatarUrl);
  @override
  String toString() {
    return (StringBuffer('SearchMessageDetailItem(')
          ..write('messageId: $messageId, ')
          ..write('senderId: $senderId, ')
          ..write('senderAvatarUrl: $senderAvatarUrl, ')
          ..write('senderFullName: $senderFullName, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('mediaName: $mediaName, ')
          ..write('appId: $appId, ')
          ..write('verified: $verified, ')
          ..write('ownerId: $ownerId, ')
          ..write('groupIconUrl: $groupIconUrl, ')
          ..write('category: $category, ')
          ..write('groupName: $groupName, ')
          ..write('conversationId: $conversationId, ')
          ..write('ownerFullName: $ownerFullName, ')
          ..write('ownerAvatarUrl: $ownerAvatarUrl')
          ..write(')'))
        .toString();
  }
}

class MiniMessageItem {
  final String conversationId;
  final String messageId;
  MiniMessageItem({
    required this.conversationId,
    required this.messageId,
  });
  @override
  int get hashCode => Object.hash(conversationId, messageId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MiniMessageItem &&
          other.conversationId == this.conversationId &&
          other.messageId == this.messageId);
  @override
  String toString() {
    return (StringBuffer('MiniMessageItem(')
          ..write('conversationId: $conversationId, ')
          ..write('messageId: $messageId')
          ..write(')'))
        .toString();
  }
}

typedef SearchMessage$where = Expression<bool> Function(
    Messages m, Conversations c, Users u, Users owner);
typedef SearchMessage$limit = Limit Function(
    Messages m, Conversations c, Users u, Users owner);

class QuoteMinimal {
  final int rowid;
  final String conversationId;
  final String? quoteMessageId;
  QuoteMinimal({
    required this.rowid,
    required this.conversationId,
    this.quoteMessageId,
  });
  @override
  int get hashCode => Object.hash(rowid, conversationId, quoteMessageId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteMinimal &&
          other.rowid == this.rowid &&
          other.conversationId == this.conversationId &&
          other.quoteMessageId == this.quoteMessageId);
  @override
  String toString() {
    return (StringBuffer('QuoteMinimal(')
          ..write('rowid: $rowid, ')
          ..write('conversationId: $conversationId, ')
          ..write('quoteMessageId: $quoteMessageId')
          ..write(')'))
        .toString();
  }
}

typedef BasePinMessageItems$order = OrderBy Function(
    PinMessages pinMessage,
    Messages message,
    Users sender,
    Users participant,
    Snapshots snapshot,
    Assets asset,
    Chains chain,
    Stickers sticker,
    Hyperlinks hyperlink,
    Users sharedUser,
    Conversations conversation,
    MessageMentions messageMention,
    ExpiredMessages em);
typedef BasePinMessageItems$limit = Limit Function(
    PinMessages pinMessage,
    Messages message,
    Users sender,
    Users participant,
    Snapshots snapshot,
    Assets asset,
    Chains chain,
    Stickers sticker,
    Hyperlinks hyperlink,
    Users sharedUser,
    Conversations conversation,
    MessageMentions messageMention,
    ExpiredMessages em);
