// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixin_database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Addresse extends DataClass implements Insertable<Addresse> {
  final String addressId;
  final String type;
  final String assetId;
  final String publicKey;
  final String label;
  final String updatedAt;
  final String reserve;
  final String fee;
  final String accountName;
  final String accountTag;
  final String dust;
  Addresse(
      {@required this.addressId,
      @required this.type,
      @required this.assetId,
      this.publicKey,
      this.label,
      @required this.updatedAt,
      @required this.reserve,
      @required this.fee,
      this.accountName,
      this.accountTag,
      this.dust});
  factory Addresse.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return Addresse(
      addressId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}address_id']),
      type: stringType.mapFromDatabaseResponse(data['${effectivePrefix}type']),
      assetId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_id']),
      publicKey: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}public_key']),
      label:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}label']),
      updatedAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}updated_at']),
      reserve:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}reserve']),
      fee: stringType.mapFromDatabaseResponse(data['${effectivePrefix}fee']),
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
    if (!nullToAbsent || addressId != null) {
      map['address_id'] = Variable<String>(addressId);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<String>(assetId);
    }
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String>(publicKey);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || reserve != null) {
      map['reserve'] = Variable<String>(reserve);
    }
    if (!nullToAbsent || fee != null) {
      map['fee'] = Variable<String>(fee);
    }
    if (!nullToAbsent || accountName != null) {
      map['account_name'] = Variable<String>(accountName);
    }
    if (!nullToAbsent || accountTag != null) {
      map['account_tag'] = Variable<String>(accountTag);
    }
    if (!nullToAbsent || dust != null) {
      map['dust'] = Variable<String>(dust);
    }
    return map;
  }

  AddressesCompanion toCompanion(bool nullToAbsent) {
    return AddressesCompanion(
      addressId: addressId == null && nullToAbsent
          ? const Value.absent()
          : Value(addressId),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      reserve: reserve == null && nullToAbsent
          ? const Value.absent()
          : Value(reserve),
      fee: fee == null && nullToAbsent ? const Value.absent() : Value(fee),
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
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Addresse(
      addressId: serializer.fromJson<String>(json['address_id']),
      type: serializer.fromJson<String>(json['type']),
      assetId: serializer.fromJson<String>(json['asset_id']),
      publicKey: serializer.fromJson<String>(json['public_key']),
      label: serializer.fromJson<String>(json['label']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
      reserve: serializer.fromJson<String>(json['reserve']),
      fee: serializer.fromJson<String>(json['fee']),
      accountName: serializer.fromJson<String>(json['account_name']),
      accountTag: serializer.fromJson<String>(json['account_tag']),
      dust: serializer.fromJson<String>(json['dust']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'address_id': serializer.toJson<String>(addressId),
      'type': serializer.toJson<String>(type),
      'asset_id': serializer.toJson<String>(assetId),
      'public_key': serializer.toJson<String>(publicKey),
      'label': serializer.toJson<String>(label),
      'updated_at': serializer.toJson<String>(updatedAt),
      'reserve': serializer.toJson<String>(reserve),
      'fee': serializer.toJson<String>(fee),
      'account_name': serializer.toJson<String>(accountName),
      'account_tag': serializer.toJson<String>(accountTag),
      'dust': serializer.toJson<String>(dust),
    };
  }

  Addresse copyWith(
          {String addressId,
          String type,
          String assetId,
          String publicKey,
          String label,
          String updatedAt,
          String reserve,
          String fee,
          String accountName,
          String accountTag,
          String dust}) =>
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
  final Value<String> publicKey;
  final Value<String> label;
  final Value<String> updatedAt;
  final Value<String> reserve;
  final Value<String> fee;
  final Value<String> accountName;
  final Value<String> accountTag;
  final Value<String> dust;
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
    @required String addressId,
    @required String type,
    @required String assetId,
    this.publicKey = const Value.absent(),
    this.label = const Value.absent(),
    @required String updatedAt,
    @required String reserve,
    @required String fee,
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
    Expression<String> addressId,
    Expression<String> type,
    Expression<String> assetId,
    Expression<String> publicKey,
    Expression<String> label,
    Expression<String> updatedAt,
    Expression<String> reserve,
    Expression<String> fee,
    Expression<String> accountName,
    Expression<String> accountTag,
    Expression<String> dust,
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
      {Value<String> addressId,
      Value<String> type,
      Value<String> assetId,
      Value<String> publicKey,
      Value<String> label,
      Value<String> updatedAt,
      Value<String> reserve,
      Value<String> fee,
      Value<String> accountName,
      Value<String> accountTag,
      Value<String> dust}) {
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
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (reserve.present) {
      map['reserve'] = Variable<String>(reserve.value);
    }
    if (fee.present) {
      map['fee'] = Variable<String>(fee.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (accountTag.present) {
      map['account_tag'] = Variable<String>(accountTag.value);
    }
    if (dust.present) {
      map['dust'] = Variable<String>(dust.value);
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
  final String _alias;
  Addresses(this._db, [this._alias]);
  final VerificationMeta _addressIdMeta = const VerificationMeta('addressId');
  GeneratedTextColumn _addressId;
  GeneratedTextColumn get addressId => _addressId ??= _constructAddressId();
  GeneratedTextColumn _constructAddressId() {
    return GeneratedTextColumn('address_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _typeMeta = const VerificationMeta('type');
  GeneratedTextColumn _type;
  GeneratedTextColumn get type => _type ??= _constructType();
  GeneratedTextColumn _constructType() {
    return GeneratedTextColumn('type', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _assetIdMeta = const VerificationMeta('assetId');
  GeneratedTextColumn _assetId;
  GeneratedTextColumn get assetId => _assetId ??= _constructAssetId();
  GeneratedTextColumn _constructAssetId() {
    return GeneratedTextColumn('asset_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _publicKeyMeta = const VerificationMeta('publicKey');
  GeneratedTextColumn _publicKey;
  GeneratedTextColumn get publicKey => _publicKey ??= _constructPublicKey();
  GeneratedTextColumn _constructPublicKey() {
    return GeneratedTextColumn('public_key', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _labelMeta = const VerificationMeta('label');
  GeneratedTextColumn _label;
  GeneratedTextColumn get label => _label ??= _constructLabel();
  GeneratedTextColumn _constructLabel() {
    return GeneratedTextColumn('label', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  GeneratedTextColumn _updatedAt;
  GeneratedTextColumn get updatedAt => _updatedAt ??= _constructUpdatedAt();
  GeneratedTextColumn _constructUpdatedAt() {
    return GeneratedTextColumn('updated_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _reserveMeta = const VerificationMeta('reserve');
  GeneratedTextColumn _reserve;
  GeneratedTextColumn get reserve => _reserve ??= _constructReserve();
  GeneratedTextColumn _constructReserve() {
    return GeneratedTextColumn('reserve', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _feeMeta = const VerificationMeta('fee');
  GeneratedTextColumn _fee;
  GeneratedTextColumn get fee => _fee ??= _constructFee();
  GeneratedTextColumn _constructFee() {
    return GeneratedTextColumn('fee', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _accountNameMeta =
      const VerificationMeta('accountName');
  GeneratedTextColumn _accountName;
  GeneratedTextColumn get accountName =>
      _accountName ??= _constructAccountName();
  GeneratedTextColumn _constructAccountName() {
    return GeneratedTextColumn('account_name', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _accountTagMeta = const VerificationMeta('accountTag');
  GeneratedTextColumn _accountTag;
  GeneratedTextColumn get accountTag => _accountTag ??= _constructAccountTag();
  GeneratedTextColumn _constructAccountTag() {
    return GeneratedTextColumn('account_tag', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _dustMeta = const VerificationMeta('dust');
  GeneratedTextColumn _dust;
  GeneratedTextColumn get dust => _dust ??= _constructDust();
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
          addressId.isAcceptableOrUnknown(data['address_id'], _addressIdMeta));
    } else if (isInserting) {
      context.missing(_addressIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type'], _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id'], _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key'], _publicKeyMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label'], _labelMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at'], _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('reserve')) {
      context.handle(_reserveMeta,
          reserve.isAcceptableOrUnknown(data['reserve'], _reserveMeta));
    } else if (isInserting) {
      context.missing(_reserveMeta);
    }
    if (data.containsKey('fee')) {
      context.handle(
          _feeMeta, fee.isAcceptableOrUnknown(data['fee'], _feeMeta));
    } else if (isInserting) {
      context.missing(_feeMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
          _accountNameMeta,
          accountName.isAcceptableOrUnknown(
              data['account_name'], _accountNameMeta));
    }
    if (data.containsKey('account_tag')) {
      context.handle(
          _accountTagMeta,
          accountTag.isAcceptableOrUnknown(
              data['account_tag'], _accountTagMeta));
    }
    if (data.containsKey('dust')) {
      context.handle(
          _dustMeta, dust.isAcceptableOrUnknown(data['dust'], _dustMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {addressId};
  @override
  Addresse map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Addresse.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Addresses createAlias(String alias) {
    return Addresses(_db, alias);
  }

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
  final String description;
  final String capabilites;
  final String creatorId;
  App(
      {@required this.appId,
      @required this.appNumber,
      @required this.homeUri,
      @required this.redirectUri,
      @required this.name,
      @required this.iconUrl,
      @required this.description,
      this.capabilites,
      @required this.creatorId});
  factory App.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return App(
      appId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}app_id']),
      appNumber: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}app_number']),
      homeUri: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}home_uri']),
      redirectUri: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}redirect_uri']),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name']),
      iconUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}icon_url']),
      description: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}description']),
      capabilites: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}capabilites']),
      creatorId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}creator_id']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || appId != null) {
      map['app_id'] = Variable<String>(appId);
    }
    if (!nullToAbsent || appNumber != null) {
      map['app_number'] = Variable<String>(appNumber);
    }
    if (!nullToAbsent || homeUri != null) {
      map['home_uri'] = Variable<String>(homeUri);
    }
    if (!nullToAbsent || redirectUri != null) {
      map['redirect_uri'] = Variable<String>(redirectUri);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || capabilites != null) {
      map['capabilites'] = Variable<String>(capabilites);
    }
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
    return map;
  }

  AppsCompanion toCompanion(bool nullToAbsent) {
    return AppsCompanion(
      appId:
          appId == null && nullToAbsent ? const Value.absent() : Value(appId),
      appNumber: appNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(appNumber),
      homeUri: homeUri == null && nullToAbsent
          ? const Value.absent()
          : Value(homeUri),
      redirectUri: redirectUri == null && nullToAbsent
          ? const Value.absent()
          : Value(redirectUri),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      capabilites: capabilites == null && nullToAbsent
          ? const Value.absent()
          : Value(capabilites),
      creatorId: creatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorId),
    );
  }

  factory App.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return App(
      appId: serializer.fromJson<String>(json['app_id']),
      appNumber: serializer.fromJson<String>(json['app_number']),
      homeUri: serializer.fromJson<String>(json['home_uri']),
      redirectUri: serializer.fromJson<String>(json['redirect_uri']),
      name: serializer.fromJson<String>(json['name']),
      iconUrl: serializer.fromJson<String>(json['icon_url']),
      description: serializer.fromJson<String>(json['description']),
      capabilites: serializer.fromJson<String>(json['capabilites']),
      creatorId: serializer.fromJson<String>(json['creator_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'app_id': serializer.toJson<String>(appId),
      'app_number': serializer.toJson<String>(appNumber),
      'home_uri': serializer.toJson<String>(homeUri),
      'redirect_uri': serializer.toJson<String>(redirectUri),
      'name': serializer.toJson<String>(name),
      'icon_url': serializer.toJson<String>(iconUrl),
      'description': serializer.toJson<String>(description),
      'capabilites': serializer.toJson<String>(capabilites),
      'creator_id': serializer.toJson<String>(creatorId),
    };
  }

  App copyWith(
          {String appId,
          String appNumber,
          String homeUri,
          String redirectUri,
          String name,
          String iconUrl,
          String description,
          String capabilites,
          String creatorId}) =>
      App(
        appId: appId ?? this.appId,
        appNumber: appNumber ?? this.appNumber,
        homeUri: homeUri ?? this.homeUri,
        redirectUri: redirectUri ?? this.redirectUri,
        name: name ?? this.name,
        iconUrl: iconUrl ?? this.iconUrl,
        description: description ?? this.description,
        capabilites: capabilites ?? this.capabilites,
        creatorId: creatorId ?? this.creatorId,
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
          ..write('description: $description, ')
          ..write('capabilites: $capabilites, ')
          ..write('creatorId: $creatorId')
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
                              description.hashCode,
                              $mrjc(capabilites.hashCode,
                                  creatorId.hashCode)))))))));
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
          other.description == this.description &&
          other.capabilites == this.capabilites &&
          other.creatorId == this.creatorId);
}

class AppsCompanion extends UpdateCompanion<App> {
  final Value<String> appId;
  final Value<String> appNumber;
  final Value<String> homeUri;
  final Value<String> redirectUri;
  final Value<String> name;
  final Value<String> iconUrl;
  final Value<String> description;
  final Value<String> capabilites;
  final Value<String> creatorId;
  const AppsCompanion({
    this.appId = const Value.absent(),
    this.appNumber = const Value.absent(),
    this.homeUri = const Value.absent(),
    this.redirectUri = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.capabilites = const Value.absent(),
    this.creatorId = const Value.absent(),
  });
  AppsCompanion.insert({
    @required String appId,
    @required String appNumber,
    @required String homeUri,
    @required String redirectUri,
    @required String name,
    @required String iconUrl,
    @required String description,
    this.capabilites = const Value.absent(),
    @required String creatorId,
  })  : appId = Value(appId),
        appNumber = Value(appNumber),
        homeUri = Value(homeUri),
        redirectUri = Value(redirectUri),
        name = Value(name),
        iconUrl = Value(iconUrl),
        description = Value(description),
        creatorId = Value(creatorId);
  static Insertable<App> custom({
    Expression<String> appId,
    Expression<String> appNumber,
    Expression<String> homeUri,
    Expression<String> redirectUri,
    Expression<String> name,
    Expression<String> iconUrl,
    Expression<String> description,
    Expression<String> capabilites,
    Expression<String> creatorId,
  }) {
    return RawValuesInsertable({
      if (appId != null) 'app_id': appId,
      if (appNumber != null) 'app_number': appNumber,
      if (homeUri != null) 'home_uri': homeUri,
      if (redirectUri != null) 'redirect_uri': redirectUri,
      if (name != null) 'name': name,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (description != null) 'description': description,
      if (capabilites != null) 'capabilites': capabilites,
      if (creatorId != null) 'creator_id': creatorId,
    });
  }

  AppsCompanion copyWith(
      {Value<String> appId,
      Value<String> appNumber,
      Value<String> homeUri,
      Value<String> redirectUri,
      Value<String> name,
      Value<String> iconUrl,
      Value<String> description,
      Value<String> capabilites,
      Value<String> creatorId}) {
    return AppsCompanion(
      appId: appId ?? this.appId,
      appNumber: appNumber ?? this.appNumber,
      homeUri: homeUri ?? this.homeUri,
      redirectUri: redirectUri ?? this.redirectUri,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      description: description ?? this.description,
      capabilites: capabilites ?? this.capabilites,
      creatorId: creatorId ?? this.creatorId,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (capabilites.present) {
      map['capabilites'] = Variable<String>(capabilites.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
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
          ..write('description: $description, ')
          ..write('capabilites: $capabilites, ')
          ..write('creatorId: $creatorId')
          ..write(')'))
        .toString();
  }
}

class Apps extends Table with TableInfo<Apps, App> {
  final GeneratedDatabase _db;
  final String _alias;
  Apps(this._db, [this._alias]);
  final VerificationMeta _appIdMeta = const VerificationMeta('appId');
  GeneratedTextColumn _appId;
  GeneratedTextColumn get appId => _appId ??= _constructAppId();
  GeneratedTextColumn _constructAppId() {
    return GeneratedTextColumn('app_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _appNumberMeta = const VerificationMeta('appNumber');
  GeneratedTextColumn _appNumber;
  GeneratedTextColumn get appNumber => _appNumber ??= _constructAppNumber();
  GeneratedTextColumn _constructAppNumber() {
    return GeneratedTextColumn('app_number', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _homeUriMeta = const VerificationMeta('homeUri');
  GeneratedTextColumn _homeUri;
  GeneratedTextColumn get homeUri => _homeUri ??= _constructHomeUri();
  GeneratedTextColumn _constructHomeUri() {
    return GeneratedTextColumn('home_uri', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _redirectUriMeta =
      const VerificationMeta('redirectUri');
  GeneratedTextColumn _redirectUri;
  GeneratedTextColumn get redirectUri =>
      _redirectUri ??= _constructRedirectUri();
  GeneratedTextColumn _constructRedirectUri() {
    return GeneratedTextColumn('redirect_uri', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  GeneratedTextColumn _name;
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _iconUrlMeta = const VerificationMeta('iconUrl');
  GeneratedTextColumn _iconUrl;
  GeneratedTextColumn get iconUrl => _iconUrl ??= _constructIconUrl();
  GeneratedTextColumn _constructIconUrl() {
    return GeneratedTextColumn('icon_url', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  GeneratedTextColumn _description;
  GeneratedTextColumn get description =>
      _description ??= _constructDescription();
  GeneratedTextColumn _constructDescription() {
    return GeneratedTextColumn('description', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _capabilitesMeta =
      const VerificationMeta('capabilites');
  GeneratedTextColumn _capabilites;
  GeneratedTextColumn get capabilites =>
      _capabilites ??= _constructCapabilites();
  GeneratedTextColumn _constructCapabilites() {
    return GeneratedTextColumn('capabilites', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _creatorIdMeta = const VerificationMeta('creatorId');
  GeneratedTextColumn _creatorId;
  GeneratedTextColumn get creatorId => _creatorId ??= _constructCreatorId();
  GeneratedTextColumn _constructCreatorId() {
    return GeneratedTextColumn('creator_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [
        appId,
        appNumber,
        homeUri,
        redirectUri,
        name,
        iconUrl,
        description,
        capabilites,
        creatorId
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
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id'], _appIdMeta));
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('app_number')) {
      context.handle(_appNumberMeta,
          appNumber.isAcceptableOrUnknown(data['app_number'], _appNumberMeta));
    } else if (isInserting) {
      context.missing(_appNumberMeta);
    }
    if (data.containsKey('home_uri')) {
      context.handle(_homeUriMeta,
          homeUri.isAcceptableOrUnknown(data['home_uri'], _homeUriMeta));
    } else if (isInserting) {
      context.missing(_homeUriMeta);
    }
    if (data.containsKey('redirect_uri')) {
      context.handle(
          _redirectUriMeta,
          redirectUri.isAcceptableOrUnknown(
              data['redirect_uri'], _redirectUriMeta));
    } else if (isInserting) {
      context.missing(_redirectUriMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name'], _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(_iconUrlMeta,
          iconUrl.isAcceptableOrUnknown(data['icon_url'], _iconUrlMeta));
    } else if (isInserting) {
      context.missing(_iconUrlMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description'], _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('capabilites')) {
      context.handle(
          _capabilitesMeta,
          capabilites.isAcceptableOrUnknown(
              data['capabilites'], _capabilitesMeta));
    }
    if (data.containsKey('creator_id')) {
      context.handle(_creatorIdMeta,
          creatorId.isAcceptableOrUnknown(data['creator_id'], _creatorIdMeta));
    } else if (isInserting) {
      context.missing(_creatorIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {appId};
  @override
  App map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return App.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Apps createAlias(String alias) {
    return Apps(_db, alias);
  }

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
  final String tag;
  final String priceBtc;
  final String priceUsd;
  final String chainId;
  final String changeUsd;
  final String changeBtc;
  final int confirmations;
  final String assetKey;
  Asset(
      {@required this.assetId,
      @required this.symbol,
      @required this.name,
      @required this.iconUrl,
      @required this.balance,
      @required this.destination,
      this.tag,
      @required this.priceBtc,
      @required this.priceUsd,
      @required this.chainId,
      @required this.changeUsd,
      @required this.changeBtc,
      @required this.confirmations,
      this.assetKey});
  factory Asset.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Asset(
      assetId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_id']),
      symbol:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}symbol']),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name']),
      iconUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}icon_url']),
      balance:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}balance']),
      destination: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}destination']),
      tag: stringType.mapFromDatabaseResponse(data['${effectivePrefix}tag']),
      priceBtc: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}price_btc']),
      priceUsd: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}price_usd']),
      chainId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}chain_id']),
      changeUsd: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}change_usd']),
      changeBtc: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}change_btc']),
      confirmations: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}confirmations']),
      assetKey: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}asset_key']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<String>(assetId);
    }
    if (!nullToAbsent || symbol != null) {
      map['symbol'] = Variable<String>(symbol);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    if (!nullToAbsent || balance != null) {
      map['balance'] = Variable<String>(balance);
    }
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || priceBtc != null) {
      map['price_btc'] = Variable<String>(priceBtc);
    }
    if (!nullToAbsent || priceUsd != null) {
      map['price_usd'] = Variable<String>(priceUsd);
    }
    if (!nullToAbsent || chainId != null) {
      map['chain_id'] = Variable<String>(chainId);
    }
    if (!nullToAbsent || changeUsd != null) {
      map['change_usd'] = Variable<String>(changeUsd);
    }
    if (!nullToAbsent || changeBtc != null) {
      map['change_btc'] = Variable<String>(changeBtc);
    }
    if (!nullToAbsent || confirmations != null) {
      map['confirmations'] = Variable<int>(confirmations);
    }
    if (!nullToAbsent || assetKey != null) {
      map['asset_key'] = Variable<String>(assetKey);
    }
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      symbol:
          symbol == null && nullToAbsent ? const Value.absent() : Value(symbol),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
      balance: balance == null && nullToAbsent
          ? const Value.absent()
          : Value(balance),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      priceBtc: priceBtc == null && nullToAbsent
          ? const Value.absent()
          : Value(priceBtc),
      priceUsd: priceUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUsd),
      chainId: chainId == null && nullToAbsent
          ? const Value.absent()
          : Value(chainId),
      changeUsd: changeUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(changeUsd),
      changeBtc: changeBtc == null && nullToAbsent
          ? const Value.absent()
          : Value(changeBtc),
      confirmations: confirmations == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmations),
      assetKey: assetKey == null && nullToAbsent
          ? const Value.absent()
          : Value(assetKey),
    );
  }

  factory Asset.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Asset(
      assetId: serializer.fromJson<String>(json['asset_id']),
      symbol: serializer.fromJson<String>(json['symbol']),
      name: serializer.fromJson<String>(json['name']),
      iconUrl: serializer.fromJson<String>(json['icon_url']),
      balance: serializer.fromJson<String>(json['balance']),
      destination: serializer.fromJson<String>(json['destination']),
      tag: serializer.fromJson<String>(json['tag']),
      priceBtc: serializer.fromJson<String>(json['price_btc']),
      priceUsd: serializer.fromJson<String>(json['price_usd']),
      chainId: serializer.fromJson<String>(json['chain_id']),
      changeUsd: serializer.fromJson<String>(json['change_usd']),
      changeBtc: serializer.fromJson<String>(json['change_btc']),
      confirmations: serializer.fromJson<int>(json['confirmations']),
      assetKey: serializer.fromJson<String>(json['asset_key']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'asset_id': serializer.toJson<String>(assetId),
      'symbol': serializer.toJson<String>(symbol),
      'name': serializer.toJson<String>(name),
      'icon_url': serializer.toJson<String>(iconUrl),
      'balance': serializer.toJson<String>(balance),
      'destination': serializer.toJson<String>(destination),
      'tag': serializer.toJson<String>(tag),
      'price_btc': serializer.toJson<String>(priceBtc),
      'price_usd': serializer.toJson<String>(priceUsd),
      'chain_id': serializer.toJson<String>(chainId),
      'change_usd': serializer.toJson<String>(changeUsd),
      'change_btc': serializer.toJson<String>(changeBtc),
      'confirmations': serializer.toJson<int>(confirmations),
      'asset_key': serializer.toJson<String>(assetKey),
    };
  }

  Asset copyWith(
          {String assetId,
          String symbol,
          String name,
          String iconUrl,
          String balance,
          String destination,
          String tag,
          String priceBtc,
          String priceUsd,
          String chainId,
          String changeUsd,
          String changeBtc,
          int confirmations,
          String assetKey}) =>
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
  final Value<String> tag;
  final Value<String> priceBtc;
  final Value<String> priceUsd;
  final Value<String> chainId;
  final Value<String> changeUsd;
  final Value<String> changeBtc;
  final Value<int> confirmations;
  final Value<String> assetKey;
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
    @required String assetId,
    @required String symbol,
    @required String name,
    @required String iconUrl,
    @required String balance,
    @required String destination,
    this.tag = const Value.absent(),
    @required String priceBtc,
    @required String priceUsd,
    @required String chainId,
    @required String changeUsd,
    @required String changeBtc,
    @required int confirmations,
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
    Expression<String> assetId,
    Expression<String> symbol,
    Expression<String> name,
    Expression<String> iconUrl,
    Expression<String> balance,
    Expression<String> destination,
    Expression<String> tag,
    Expression<String> priceBtc,
    Expression<String> priceUsd,
    Expression<String> chainId,
    Expression<String> changeUsd,
    Expression<String> changeBtc,
    Expression<int> confirmations,
    Expression<String> assetKey,
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
      {Value<String> assetId,
      Value<String> symbol,
      Value<String> name,
      Value<String> iconUrl,
      Value<String> balance,
      Value<String> destination,
      Value<String> tag,
      Value<String> priceBtc,
      Value<String> priceUsd,
      Value<String> chainId,
      Value<String> changeUsd,
      Value<String> changeBtc,
      Value<int> confirmations,
      Value<String> assetKey}) {
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
  final String _alias;
  Assets(this._db, [this._alias]);
  final VerificationMeta _assetIdMeta = const VerificationMeta('assetId');
  GeneratedTextColumn _assetId;
  GeneratedTextColumn get assetId => _assetId ??= _constructAssetId();
  GeneratedTextColumn _constructAssetId() {
    return GeneratedTextColumn('asset_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  GeneratedTextColumn _symbol;
  GeneratedTextColumn get symbol => _symbol ??= _constructSymbol();
  GeneratedTextColumn _constructSymbol() {
    return GeneratedTextColumn('symbol', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  GeneratedTextColumn _name;
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _iconUrlMeta = const VerificationMeta('iconUrl');
  GeneratedTextColumn _iconUrl;
  GeneratedTextColumn get iconUrl => _iconUrl ??= _constructIconUrl();
  GeneratedTextColumn _constructIconUrl() {
    return GeneratedTextColumn('icon_url', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _balanceMeta = const VerificationMeta('balance');
  GeneratedTextColumn _balance;
  GeneratedTextColumn get balance => _balance ??= _constructBalance();
  GeneratedTextColumn _constructBalance() {
    return GeneratedTextColumn('balance', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _destinationMeta =
      const VerificationMeta('destination');
  GeneratedTextColumn _destination;
  GeneratedTextColumn get destination =>
      _destination ??= _constructDestination();
  GeneratedTextColumn _constructDestination() {
    return GeneratedTextColumn('destination', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _tagMeta = const VerificationMeta('tag');
  GeneratedTextColumn _tag;
  GeneratedTextColumn get tag => _tag ??= _constructTag();
  GeneratedTextColumn _constructTag() {
    return GeneratedTextColumn('tag', $tableName, true, $customConstraints: '');
  }

  final VerificationMeta _priceBtcMeta = const VerificationMeta('priceBtc');
  GeneratedTextColumn _priceBtc;
  GeneratedTextColumn get priceBtc => _priceBtc ??= _constructPriceBtc();
  GeneratedTextColumn _constructPriceBtc() {
    return GeneratedTextColumn('price_btc', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _priceUsdMeta = const VerificationMeta('priceUsd');
  GeneratedTextColumn _priceUsd;
  GeneratedTextColumn get priceUsd => _priceUsd ??= _constructPriceUsd();
  GeneratedTextColumn _constructPriceUsd() {
    return GeneratedTextColumn('price_usd', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _chainIdMeta = const VerificationMeta('chainId');
  GeneratedTextColumn _chainId;
  GeneratedTextColumn get chainId => _chainId ??= _constructChainId();
  GeneratedTextColumn _constructChainId() {
    return GeneratedTextColumn('chain_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _changeUsdMeta = const VerificationMeta('changeUsd');
  GeneratedTextColumn _changeUsd;
  GeneratedTextColumn get changeUsd => _changeUsd ??= _constructChangeUsd();
  GeneratedTextColumn _constructChangeUsd() {
    return GeneratedTextColumn('change_usd', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _changeBtcMeta = const VerificationMeta('changeBtc');
  GeneratedTextColumn _changeBtc;
  GeneratedTextColumn get changeBtc => _changeBtc ??= _constructChangeBtc();
  GeneratedTextColumn _constructChangeBtc() {
    return GeneratedTextColumn('change_btc', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _confirmationsMeta =
      const VerificationMeta('confirmations');
  GeneratedIntColumn _confirmations;
  GeneratedIntColumn get confirmations =>
      _confirmations ??= _constructConfirmations();
  GeneratedIntColumn _constructConfirmations() {
    return GeneratedIntColumn('confirmations', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _assetKeyMeta = const VerificationMeta('assetKey');
  GeneratedTextColumn _assetKey;
  GeneratedTextColumn get assetKey => _assetKey ??= _constructAssetKey();
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
          assetId.isAcceptableOrUnknown(data['asset_id'], _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol'], _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name'], _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(_iconUrlMeta,
          iconUrl.isAcceptableOrUnknown(data['icon_url'], _iconUrlMeta));
    } else if (isInserting) {
      context.missing(_iconUrlMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance'], _balanceMeta));
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
          _destinationMeta,
          destination.isAcceptableOrUnknown(
              data['destination'], _destinationMeta));
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag'], _tagMeta));
    }
    if (data.containsKey('price_btc')) {
      context.handle(_priceBtcMeta,
          priceBtc.isAcceptableOrUnknown(data['price_btc'], _priceBtcMeta));
    } else if (isInserting) {
      context.missing(_priceBtcMeta);
    }
    if (data.containsKey('price_usd')) {
      context.handle(_priceUsdMeta,
          priceUsd.isAcceptableOrUnknown(data['price_usd'], _priceUsdMeta));
    } else if (isInserting) {
      context.missing(_priceUsdMeta);
    }
    if (data.containsKey('chain_id')) {
      context.handle(_chainIdMeta,
          chainId.isAcceptableOrUnknown(data['chain_id'], _chainIdMeta));
    } else if (isInserting) {
      context.missing(_chainIdMeta);
    }
    if (data.containsKey('change_usd')) {
      context.handle(_changeUsdMeta,
          changeUsd.isAcceptableOrUnknown(data['change_usd'], _changeUsdMeta));
    } else if (isInserting) {
      context.missing(_changeUsdMeta);
    }
    if (data.containsKey('change_btc')) {
      context.handle(_changeBtcMeta,
          changeBtc.isAcceptableOrUnknown(data['change_btc'], _changeBtcMeta));
    } else if (isInserting) {
      context.missing(_changeBtcMeta);
    }
    if (data.containsKey('confirmations')) {
      context.handle(
          _confirmationsMeta,
          confirmations.isAcceptableOrUnknown(
              data['confirmations'], _confirmationsMeta));
    } else if (isInserting) {
      context.missing(_confirmationsMeta);
    }
    if (data.containsKey('asset_key')) {
      context.handle(_assetKeyMeta,
          assetKey.isAcceptableOrUnknown(data['asset_key'], _assetKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  Asset map(Map<String, dynamic> data, {String tablePrefix}) {
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
  final String userId;
  final String createdAt;
  final String pinTime;
  CircleConversation(
      {@required this.conversationId,
      @required this.circleId,
      this.userId,
      @required this.createdAt,
      this.pinTime});
  factory CircleConversation.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return CircleConversation(
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id']),
      circleId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}circle_id']),
      userId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}user_id']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
      pinTime: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}pin_time']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    if (!nullToAbsent || circleId != null) {
      map['circle_id'] = Variable<String>(circleId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || pinTime != null) {
      map['pin_time'] = Variable<String>(pinTime);
    }
    return map;
  }

  CircleConversationsCompanion toCompanion(bool nullToAbsent) {
    return CircleConversationsCompanion(
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      circleId: circleId == null && nullToAbsent
          ? const Value.absent()
          : Value(circleId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      pinTime: pinTime == null && nullToAbsent
          ? const Value.absent()
          : Value(pinTime),
    );
  }

  factory CircleConversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return CircleConversation(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      circleId: serializer.fromJson<String>(json['circle_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      pinTime: serializer.fromJson<String>(json['pin_time']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversation_id': serializer.toJson<String>(conversationId),
      'circle_id': serializer.toJson<String>(circleId),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(createdAt),
      'pin_time': serializer.toJson<String>(pinTime),
    };
  }

  CircleConversation copyWith(
          {String conversationId,
          String circleId,
          String userId,
          String createdAt,
          String pinTime}) =>
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
  final Value<String> userId;
  final Value<String> createdAt;
  final Value<String> pinTime;
  const CircleConversationsCompanion({
    this.conversationId = const Value.absent(),
    this.circleId = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pinTime = const Value.absent(),
  });
  CircleConversationsCompanion.insert({
    @required String conversationId,
    @required String circleId,
    this.userId = const Value.absent(),
    @required String createdAt,
    this.pinTime = const Value.absent(),
  })  : conversationId = Value(conversationId),
        circleId = Value(circleId),
        createdAt = Value(createdAt);
  static Insertable<CircleConversation> custom({
    Expression<String> conversationId,
    Expression<String> circleId,
    Expression<String> userId,
    Expression<String> createdAt,
    Expression<String> pinTime,
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
      {Value<String> conversationId,
      Value<String> circleId,
      Value<String> userId,
      Value<String> createdAt,
      Value<String> pinTime}) {
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
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (pinTime.present) {
      map['pin_time'] = Variable<String>(pinTime.value);
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
  final String _alias;
  CircleConversations(this._db, [this._alias]);
  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  GeneratedTextColumn _conversationId;
  GeneratedTextColumn get conversationId =>
      _conversationId ??= _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _circleIdMeta = const VerificationMeta('circleId');
  GeneratedTextColumn _circleId;
  GeneratedTextColumn get circleId => _circleId ??= _constructCircleId();
  GeneratedTextColumn _constructCircleId() {
    return GeneratedTextColumn('circle_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  GeneratedTextColumn _userId;
  GeneratedTextColumn get userId => _userId ??= _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _pinTimeMeta = const VerificationMeta('pinTime');
  GeneratedTextColumn _pinTime;
  GeneratedTextColumn get pinTime => _pinTime ??= _constructPinTime();
  GeneratedTextColumn _constructPinTime() {
    return GeneratedTextColumn('pin_time', $tableName, true,
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
              data['conversation_id'], _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('circle_id')) {
      context.handle(_circleIdMeta,
          circleId.isAcceptableOrUnknown(data['circle_id'], _circleIdMeta));
    } else if (isInserting) {
      context.missing(_circleIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id'], _userIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('pin_time')) {
      context.handle(_pinTimeMeta,
          pinTime.isAcceptableOrUnknown(data['pin_time'], _pinTimeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, circleId};
  @override
  CircleConversation map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return CircleConversation.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  CircleConversations createAlias(String alias) {
    return CircleConversations(_db, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(conversation_id, circle_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Circle extends DataClass implements Insertable<Circle> {
  final String circleId;
  final String name;
  final String createdAt;
  final String orderedAt;
  Circle(
      {@required this.circleId,
      @required this.name,
      @required this.createdAt,
      this.orderedAt});
  factory Circle.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return Circle(
      circleId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}circle_id']),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
      orderedAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}ordered_at']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || circleId != null) {
      map['circle_id'] = Variable<String>(circleId);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || orderedAt != null) {
      map['ordered_at'] = Variable<String>(orderedAt);
    }
    return map;
  }

  CirclesCompanion toCompanion(bool nullToAbsent) {
    return CirclesCompanion(
      circleId: circleId == null && nullToAbsent
          ? const Value.absent()
          : Value(circleId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      orderedAt: orderedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(orderedAt),
    );
  }

  factory Circle.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Circle(
      circleId: serializer.fromJson<String>(json['circle_id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      orderedAt: serializer.fromJson<String>(json['ordered_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'circle_id': serializer.toJson<String>(circleId),
      'name': serializer.toJson<String>(name),
      'created_at': serializer.toJson<String>(createdAt),
      'ordered_at': serializer.toJson<String>(orderedAt),
    };
  }

  Circle copyWith(
          {String circleId, String name, String createdAt, String orderedAt}) =>
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
  final Value<String> createdAt;
  final Value<String> orderedAt;
  const CirclesCompanion({
    this.circleId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.orderedAt = const Value.absent(),
  });
  CirclesCompanion.insert({
    @required String circleId,
    @required String name,
    @required String createdAt,
    this.orderedAt = const Value.absent(),
  })  : circleId = Value(circleId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Circle> custom({
    Expression<String> circleId,
    Expression<String> name,
    Expression<String> createdAt,
    Expression<String> orderedAt,
  }) {
    return RawValuesInsertable({
      if (circleId != null) 'circle_id': circleId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (orderedAt != null) 'ordered_at': orderedAt,
    });
  }

  CirclesCompanion copyWith(
      {Value<String> circleId,
      Value<String> name,
      Value<String> createdAt,
      Value<String> orderedAt}) {
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
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (orderedAt.present) {
      map['ordered_at'] = Variable<String>(orderedAt.value);
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
  final String _alias;
  Circles(this._db, [this._alias]);
  final VerificationMeta _circleIdMeta = const VerificationMeta('circleId');
  GeneratedTextColumn _circleId;
  GeneratedTextColumn get circleId => _circleId ??= _constructCircleId();
  GeneratedTextColumn _constructCircleId() {
    return GeneratedTextColumn('circle_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  GeneratedTextColumn _name;
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _orderedAtMeta = const VerificationMeta('orderedAt');
  GeneratedTextColumn _orderedAt;
  GeneratedTextColumn get orderedAt => _orderedAt ??= _constructOrderedAt();
  GeneratedTextColumn _constructOrderedAt() {
    return GeneratedTextColumn('ordered_at', $tableName, true,
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
          circleId.isAcceptableOrUnknown(data['circle_id'], _circleIdMeta));
    } else if (isInserting) {
      context.missing(_circleIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name'], _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('ordered_at')) {
      context.handle(_orderedAtMeta,
          orderedAt.isAcceptableOrUnknown(data['ordered_at'], _orderedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {circleId};
  @override
  Circle map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Circle.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Circles createAlias(String alias) {
    return Circles(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(circle_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String conversationId;
  final String ownerId;
  final String category;
  final String name;
  final String iconUrl;
  final String announcement;
  final String codeUrl;
  final String payType;
  final String createdAt;
  final String pinTime;
  final String lastMessageId;
  final String lastReadMessageId;
  final int unseenMessageCount;
  final int status;
  final String draft;
  final String muteUntil;
  Conversation(
      {@required this.conversationId,
      this.ownerId,
      this.category,
      this.name,
      this.iconUrl,
      this.announcement,
      this.codeUrl,
      this.payType,
      @required this.createdAt,
      this.pinTime,
      this.lastMessageId,
      this.lastReadMessageId,
      this.unseenMessageCount,
      @required this.status,
      this.draft,
      this.muteUntil});
  factory Conversation.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Conversation(
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id']),
      ownerId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}owner_id']),
      category: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}category']),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name']),
      iconUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}icon_url']),
      announcement: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}announcement']),
      codeUrl: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}code_url']),
      payType: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}pay_type']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
      pinTime: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}pin_time']),
      lastMessageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}last_message_id']),
      lastReadMessageId: stringType.mapFromDatabaseResponse(
          data['${effectivePrefix}last_read_message_id']),
      unseenMessageCount: intType.mapFromDatabaseResponse(
          data['${effectivePrefix}unseen_message_count']),
      status: intType.mapFromDatabaseResponse(data['${effectivePrefix}status']),
      draft:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}draft']),
      muteUntil: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}mute_until']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
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
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || pinTime != null) {
      map['pin_time'] = Variable<String>(pinTime);
    }
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String>(lastMessageId);
    }
    if (!nullToAbsent || lastReadMessageId != null) {
      map['last_read_message_id'] = Variable<String>(lastReadMessageId);
    }
    if (!nullToAbsent || unseenMessageCount != null) {
      map['unseen_message_count'] = Variable<int>(unseenMessageCount);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<int>(status);
    }
    if (!nullToAbsent || draft != null) {
      map['draft'] = Variable<String>(draft);
    }
    if (!nullToAbsent || muteUntil != null) {
      map['mute_until'] = Variable<String>(muteUntil);
    }
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
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
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      pinTime: pinTime == null && nullToAbsent
          ? const Value.absent()
          : Value(pinTime),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      lastReadMessageId: lastReadMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadMessageId),
      unseenMessageCount: unseenMessageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(unseenMessageCount),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
      draft:
          draft == null && nullToAbsent ? const Value.absent() : Value(draft),
      muteUntil: muteUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(muteUntil),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Conversation(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      ownerId: serializer.fromJson<String>(json['owner_id']),
      category: serializer.fromJson<String>(json['category']),
      name: serializer.fromJson<String>(json['name']),
      iconUrl: serializer.fromJson<String>(json['icon_url']),
      announcement: serializer.fromJson<String>(json['announcement']),
      codeUrl: serializer.fromJson<String>(json['code_url']),
      payType: serializer.fromJson<String>(json['pay_type']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      pinTime: serializer.fromJson<String>(json['pin_time']),
      lastMessageId: serializer.fromJson<String>(json['last_message_id']),
      lastReadMessageId:
          serializer.fromJson<String>(json['last_read_message_id']),
      unseenMessageCount:
          serializer.fromJson<int>(json['unseen_message_count']),
      status: serializer.fromJson<int>(json['status']),
      draft: serializer.fromJson<String>(json['draft']),
      muteUntil: serializer.fromJson<String>(json['mute_until']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversation_id': serializer.toJson<String>(conversationId),
      'owner_id': serializer.toJson<String>(ownerId),
      'category': serializer.toJson<String>(category),
      'name': serializer.toJson<String>(name),
      'icon_url': serializer.toJson<String>(iconUrl),
      'announcement': serializer.toJson<String>(announcement),
      'code_url': serializer.toJson<String>(codeUrl),
      'pay_type': serializer.toJson<String>(payType),
      'created_at': serializer.toJson<String>(createdAt),
      'pin_time': serializer.toJson<String>(pinTime),
      'last_message_id': serializer.toJson<String>(lastMessageId),
      'last_read_message_id': serializer.toJson<String>(lastReadMessageId),
      'unseen_message_count': serializer.toJson<int>(unseenMessageCount),
      'status': serializer.toJson<int>(status),
      'draft': serializer.toJson<String>(draft),
      'mute_until': serializer.toJson<String>(muteUntil),
    };
  }

  Conversation copyWith(
          {String conversationId,
          String ownerId,
          String category,
          String name,
          String iconUrl,
          String announcement,
          String codeUrl,
          String payType,
          String createdAt,
          String pinTime,
          String lastMessageId,
          String lastReadMessageId,
          int unseenMessageCount,
          int status,
          String draft,
          String muteUntil}) =>
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
                                                  lastReadMessageId.hashCode,
                                                  $mrjc(
                                                      unseenMessageCount
                                                          .hashCode,
                                                      $mrjc(
                                                          status.hashCode,
                                                          $mrjc(
                                                              draft.hashCode,
                                                              muteUntil
                                                                  .hashCode))))))))))))))));
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
          other.lastReadMessageId == this.lastReadMessageId &&
          other.unseenMessageCount == this.unseenMessageCount &&
          other.status == this.status &&
          other.draft == this.draft &&
          other.muteUntil == this.muteUntil);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> conversationId;
  final Value<String> ownerId;
  final Value<String> category;
  final Value<String> name;
  final Value<String> iconUrl;
  final Value<String> announcement;
  final Value<String> codeUrl;
  final Value<String> payType;
  final Value<String> createdAt;
  final Value<String> pinTime;
  final Value<String> lastMessageId;
  final Value<String> lastReadMessageId;
  final Value<int> unseenMessageCount;
  final Value<int> status;
  final Value<String> draft;
  final Value<String> muteUntil;
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
    this.lastReadMessageId = const Value.absent(),
    this.unseenMessageCount = const Value.absent(),
    this.status = const Value.absent(),
    this.draft = const Value.absent(),
    this.muteUntil = const Value.absent(),
  });
  ConversationsCompanion.insert({
    @required String conversationId,
    this.ownerId = const Value.absent(),
    this.category = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.announcement = const Value.absent(),
    this.codeUrl = const Value.absent(),
    this.payType = const Value.absent(),
    @required String createdAt,
    this.pinTime = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastReadMessageId = const Value.absent(),
    this.unseenMessageCount = const Value.absent(),
    @required int status,
    this.draft = const Value.absent(),
    this.muteUntil = const Value.absent(),
  })  : conversationId = Value(conversationId),
        createdAt = Value(createdAt),
        status = Value(status);
  static Insertable<Conversation> custom({
    Expression<String> conversationId,
    Expression<String> ownerId,
    Expression<String> category,
    Expression<String> name,
    Expression<String> iconUrl,
    Expression<String> announcement,
    Expression<String> codeUrl,
    Expression<String> payType,
    Expression<String> createdAt,
    Expression<String> pinTime,
    Expression<String> lastMessageId,
    Expression<String> lastReadMessageId,
    Expression<int> unseenMessageCount,
    Expression<int> status,
    Expression<String> draft,
    Expression<String> muteUntil,
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
      if (lastReadMessageId != null) 'last_read_message_id': lastReadMessageId,
      if (unseenMessageCount != null)
        'unseen_message_count': unseenMessageCount,
      if (status != null) 'status': status,
      if (draft != null) 'draft': draft,
      if (muteUntil != null) 'mute_until': muteUntil,
    });
  }

  ConversationsCompanion copyWith(
      {Value<String> conversationId,
      Value<String> ownerId,
      Value<String> category,
      Value<String> name,
      Value<String> iconUrl,
      Value<String> announcement,
      Value<String> codeUrl,
      Value<String> payType,
      Value<String> createdAt,
      Value<String> pinTime,
      Value<String> lastMessageId,
      Value<String> lastReadMessageId,
      Value<int> unseenMessageCount,
      Value<int> status,
      Value<String> draft,
      Value<String> muteUntil}) {
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
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (pinTime.present) {
      map['pin_time'] = Variable<String>(pinTime.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (lastReadMessageId.present) {
      map['last_read_message_id'] = Variable<String>(lastReadMessageId.value);
    }
    if (unseenMessageCount.present) {
      map['unseen_message_count'] = Variable<int>(unseenMessageCount.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (draft.present) {
      map['draft'] = Variable<String>(draft.value);
    }
    if (muteUntil.present) {
      map['mute_until'] = Variable<String>(muteUntil.value);
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
  final String _alias;
  Conversations(this._db, [this._alias]);
  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  GeneratedTextColumn _conversationId;
  GeneratedTextColumn get conversationId =>
      _conversationId ??= _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _ownerIdMeta = const VerificationMeta('ownerId');
  GeneratedTextColumn _ownerId;
  GeneratedTextColumn get ownerId => _ownerId ??= _constructOwnerId();
  GeneratedTextColumn _constructOwnerId() {
    return GeneratedTextColumn('owner_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  GeneratedTextColumn _category;
  GeneratedTextColumn get category => _category ??= _constructCategory();
  GeneratedTextColumn _constructCategory() {
    return GeneratedTextColumn('category', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  GeneratedTextColumn _name;
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _iconUrlMeta = const VerificationMeta('iconUrl');
  GeneratedTextColumn _iconUrl;
  GeneratedTextColumn get iconUrl => _iconUrl ??= _constructIconUrl();
  GeneratedTextColumn _constructIconUrl() {
    return GeneratedTextColumn('icon_url', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _announcementMeta =
      const VerificationMeta('announcement');
  GeneratedTextColumn _announcement;
  GeneratedTextColumn get announcement =>
      _announcement ??= _constructAnnouncement();
  GeneratedTextColumn _constructAnnouncement() {
    return GeneratedTextColumn('announcement', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _codeUrlMeta = const VerificationMeta('codeUrl');
  GeneratedTextColumn _codeUrl;
  GeneratedTextColumn get codeUrl => _codeUrl ??= _constructCodeUrl();
  GeneratedTextColumn _constructCodeUrl() {
    return GeneratedTextColumn('code_url', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _payTypeMeta = const VerificationMeta('payType');
  GeneratedTextColumn _payType;
  GeneratedTextColumn get payType => _payType ??= _constructPayType();
  GeneratedTextColumn _constructPayType() {
    return GeneratedTextColumn('pay_type', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _pinTimeMeta = const VerificationMeta('pinTime');
  GeneratedTextColumn _pinTime;
  GeneratedTextColumn get pinTime => _pinTime ??= _constructPinTime();
  GeneratedTextColumn _constructPinTime() {
    return GeneratedTextColumn('pin_time', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _lastMessageIdMeta =
      const VerificationMeta('lastMessageId');
  GeneratedTextColumn _lastMessageId;
  GeneratedTextColumn get lastMessageId =>
      _lastMessageId ??= _constructLastMessageId();
  GeneratedTextColumn _constructLastMessageId() {
    return GeneratedTextColumn('last_message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _lastReadMessageIdMeta =
      const VerificationMeta('lastReadMessageId');
  GeneratedTextColumn _lastReadMessageId;
  GeneratedTextColumn get lastReadMessageId =>
      _lastReadMessageId ??= _constructLastReadMessageId();
  GeneratedTextColumn _constructLastReadMessageId() {
    return GeneratedTextColumn('last_read_message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _unseenMessageCountMeta =
      const VerificationMeta('unseenMessageCount');
  GeneratedIntColumn _unseenMessageCount;
  GeneratedIntColumn get unseenMessageCount =>
      _unseenMessageCount ??= _constructUnseenMessageCount();
  GeneratedIntColumn _constructUnseenMessageCount() {
    return GeneratedIntColumn('unseen_message_count', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _statusMeta = const VerificationMeta('status');
  GeneratedIntColumn _status;
  GeneratedIntColumn get status => _status ??= _constructStatus();
  GeneratedIntColumn _constructStatus() {
    return GeneratedIntColumn('status', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _draftMeta = const VerificationMeta('draft');
  GeneratedTextColumn _draft;
  GeneratedTextColumn get draft => _draft ??= _constructDraft();
  GeneratedTextColumn _constructDraft() {
    return GeneratedTextColumn('draft', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _muteUntilMeta = const VerificationMeta('muteUntil');
  GeneratedTextColumn _muteUntil;
  GeneratedTextColumn get muteUntil => _muteUntil ??= _constructMuteUntil();
  GeneratedTextColumn _constructMuteUntil() {
    return GeneratedTextColumn('mute_until', $tableName, true,
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
              data['conversation_id'], _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id'], _ownerIdMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category'], _categoryMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name'], _nameMeta));
    }
    if (data.containsKey('icon_url')) {
      context.handle(_iconUrlMeta,
          iconUrl.isAcceptableOrUnknown(data['icon_url'], _iconUrlMeta));
    }
    if (data.containsKey('announcement')) {
      context.handle(
          _announcementMeta,
          announcement.isAcceptableOrUnknown(
              data['announcement'], _announcementMeta));
    }
    if (data.containsKey('code_url')) {
      context.handle(_codeUrlMeta,
          codeUrl.isAcceptableOrUnknown(data['code_url'], _codeUrlMeta));
    }
    if (data.containsKey('pay_type')) {
      context.handle(_payTypeMeta,
          payType.isAcceptableOrUnknown(data['pay_type'], _payTypeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('pin_time')) {
      context.handle(_pinTimeMeta,
          pinTime.isAcceptableOrUnknown(data['pin_time'], _pinTimeMeta));
    }
    if (data.containsKey('last_message_id')) {
      context.handle(
          _lastMessageIdMeta,
          lastMessageId.isAcceptableOrUnknown(
              data['last_message_id'], _lastMessageIdMeta));
    }
    if (data.containsKey('last_read_message_id')) {
      context.handle(
          _lastReadMessageIdMeta,
          lastReadMessageId.isAcceptableOrUnknown(
              data['last_read_message_id'], _lastReadMessageIdMeta));
    }
    if (data.containsKey('unseen_message_count')) {
      context.handle(
          _unseenMessageCountMeta,
          unseenMessageCount.isAcceptableOrUnknown(
              data['unseen_message_count'], _unseenMessageCountMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status'], _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('draft')) {
      context.handle(
          _draftMeta, draft.isAcceptableOrUnknown(data['draft'], _draftMeta));
    }
    if (data.containsKey('mute_until')) {
      context.handle(_muteUntilMeta,
          muteUntil.isAcceptableOrUnknown(data['mute_until'], _muteUntilMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId};
  @override
  Conversation map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Conversation.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Conversations createAlias(String alias) {
    return Conversations(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(conversation_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class FloodMessage extends DataClass implements Insertable<FloodMessage> {
  final String messageId;
  final String data;
  final String createdAt;
  FloodMessage(
      {@required this.messageId,
      @required this.data,
      @required this.createdAt});
  factory FloodMessage.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return FloodMessage(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id']),
      data: stringType.mapFromDatabaseResponse(data['${effectivePrefix}data']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(data);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  FloodMessagesCompanion toCompanion(bool nullToAbsent) {
    return FloodMessagesCompanion(
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory FloodMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return FloodMessage(
      messageId: serializer.fromJson<String>(json['message_id']),
      data: serializer.fromJson<String>(json['data']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'data': serializer.toJson<String>(data),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  FloodMessage copyWith({String messageId, String data, String createdAt}) =>
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
  final Value<String> createdAt;
  const FloodMessagesCompanion({
    this.messageId = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FloodMessagesCompanion.insert({
    @required String messageId,
    @required String data,
    @required String createdAt,
  })  : messageId = Value(messageId),
        data = Value(data),
        createdAt = Value(createdAt);
  static Insertable<FloodMessage> custom({
    Expression<String> messageId,
    Expression<String> data,
    Expression<String> createdAt,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (data != null) 'data': data,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FloodMessagesCompanion copyWith(
      {Value<String> messageId, Value<String> data, Value<String> createdAt}) {
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
      map['created_at'] = Variable<String>(createdAt.value);
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
  final String _alias;
  FloodMessages(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  GeneratedTextColumn _messageId;
  GeneratedTextColumn get messageId => _messageId ??= _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _dataMeta = const VerificationMeta('data');
  GeneratedTextColumn _data;
  GeneratedTextColumn get data => _data ??= _constructData();
  GeneratedTextColumn _constructData() {
    return GeneratedTextColumn('data', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
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
          messageId.isAcceptableOrUnknown(data['message_id'], _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data'], _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  FloodMessage map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return FloodMessage.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  FloodMessages createAlias(String alias) {
    return FloodMessages(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(message_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Hyperlink extends DataClass implements Insertable<Hyperlink> {
  final String hyperlink;
  final String siteName;
  final String siteTitle;
  final String siteDescription;
  final String siteImage;
  Hyperlink(
      {@required this.hyperlink,
      @required this.siteName,
      @required this.siteTitle,
      this.siteDescription,
      this.siteImage});
  factory Hyperlink.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return Hyperlink(
      hyperlink: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}hyperlink']),
      siteName: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}site_name']),
      siteTitle: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}site_title']),
      siteDescription: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}site_description']),
      siteImage: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}site_image']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || hyperlink != null) {
      map['hyperlink'] = Variable<String>(hyperlink);
    }
    if (!nullToAbsent || siteName != null) {
      map['site_name'] = Variable<String>(siteName);
    }
    if (!nullToAbsent || siteTitle != null) {
      map['site_title'] = Variable<String>(siteTitle);
    }
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
      hyperlink: hyperlink == null && nullToAbsent
          ? const Value.absent()
          : Value(hyperlink),
      siteName: siteName == null && nullToAbsent
          ? const Value.absent()
          : Value(siteName),
      siteTitle: siteTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(siteTitle),
      siteDescription: siteDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(siteDescription),
      siteImage: siteImage == null && nullToAbsent
          ? const Value.absent()
          : Value(siteImage),
    );
  }

  factory Hyperlink.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Hyperlink(
      hyperlink: serializer.fromJson<String>(json['hyperlink']),
      siteName: serializer.fromJson<String>(json['site_name']),
      siteTitle: serializer.fromJson<String>(json['site_title']),
      siteDescription: serializer.fromJson<String>(json['site_description']),
      siteImage: serializer.fromJson<String>(json['site_image']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hyperlink': serializer.toJson<String>(hyperlink),
      'site_name': serializer.toJson<String>(siteName),
      'site_title': serializer.toJson<String>(siteTitle),
      'site_description': serializer.toJson<String>(siteDescription),
      'site_image': serializer.toJson<String>(siteImage),
    };
  }

  Hyperlink copyWith(
          {String hyperlink,
          String siteName,
          String siteTitle,
          String siteDescription,
          String siteImage}) =>
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
  final Value<String> siteDescription;
  final Value<String> siteImage;
  const HyperlinksCompanion({
    this.hyperlink = const Value.absent(),
    this.siteName = const Value.absent(),
    this.siteTitle = const Value.absent(),
    this.siteDescription = const Value.absent(),
    this.siteImage = const Value.absent(),
  });
  HyperlinksCompanion.insert({
    @required String hyperlink,
    @required String siteName,
    @required String siteTitle,
    this.siteDescription = const Value.absent(),
    this.siteImage = const Value.absent(),
  })  : hyperlink = Value(hyperlink),
        siteName = Value(siteName),
        siteTitle = Value(siteTitle);
  static Insertable<Hyperlink> custom({
    Expression<String> hyperlink,
    Expression<String> siteName,
    Expression<String> siteTitle,
    Expression<String> siteDescription,
    Expression<String> siteImage,
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
      {Value<String> hyperlink,
      Value<String> siteName,
      Value<String> siteTitle,
      Value<String> siteDescription,
      Value<String> siteImage}) {
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
      map['site_description'] = Variable<String>(siteDescription.value);
    }
    if (siteImage.present) {
      map['site_image'] = Variable<String>(siteImage.value);
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
  final String _alias;
  Hyperlinks(this._db, [this._alias]);
  final VerificationMeta _hyperlinkMeta = const VerificationMeta('hyperlink');
  GeneratedTextColumn _hyperlink;
  GeneratedTextColumn get hyperlink => _hyperlink ??= _constructHyperlink();
  GeneratedTextColumn _constructHyperlink() {
    return GeneratedTextColumn('hyperlink', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _siteNameMeta = const VerificationMeta('siteName');
  GeneratedTextColumn _siteName;
  GeneratedTextColumn get siteName => _siteName ??= _constructSiteName();
  GeneratedTextColumn _constructSiteName() {
    return GeneratedTextColumn('site_name', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _siteTitleMeta = const VerificationMeta('siteTitle');
  GeneratedTextColumn _siteTitle;
  GeneratedTextColumn get siteTitle => _siteTitle ??= _constructSiteTitle();
  GeneratedTextColumn _constructSiteTitle() {
    return GeneratedTextColumn('site_title', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _siteDescriptionMeta =
      const VerificationMeta('siteDescription');
  GeneratedTextColumn _siteDescription;
  GeneratedTextColumn get siteDescription =>
      _siteDescription ??= _constructSiteDescription();
  GeneratedTextColumn _constructSiteDescription() {
    return GeneratedTextColumn('site_description', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _siteImageMeta = const VerificationMeta('siteImage');
  GeneratedTextColumn _siteImage;
  GeneratedTextColumn get siteImage => _siteImage ??= _constructSiteImage();
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
          hyperlink.isAcceptableOrUnknown(data['hyperlink'], _hyperlinkMeta));
    } else if (isInserting) {
      context.missing(_hyperlinkMeta);
    }
    if (data.containsKey('site_name')) {
      context.handle(_siteNameMeta,
          siteName.isAcceptableOrUnknown(data['site_name'], _siteNameMeta));
    } else if (isInserting) {
      context.missing(_siteNameMeta);
    }
    if (data.containsKey('site_title')) {
      context.handle(_siteTitleMeta,
          siteTitle.isAcceptableOrUnknown(data['site_title'], _siteTitleMeta));
    } else if (isInserting) {
      context.missing(_siteTitleMeta);
    }
    if (data.containsKey('site_description')) {
      context.handle(
          _siteDescriptionMeta,
          siteDescription.isAcceptableOrUnknown(
              data['site_description'], _siteDescriptionMeta));
    }
    if (data.containsKey('site_image')) {
      context.handle(_siteImageMeta,
          siteImage.isAcceptableOrUnknown(data['site_image'], _siteImageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hyperlink};
  @override
  Hyperlink map(Map<String, dynamic> data, {String tablePrefix}) {
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

class Job extends DataClass implements Insertable<Job> {
  final String jobId;
  final String createdAt;
  final int orderId;
  final int priority;
  final String userId;
  final String blazeMessage;
  final String conversationId;
  final String resendMessageId;
  final int runCount;
  Job(
      {@required this.jobId,
      @required this.createdAt,
      this.orderId,
      @required this.priority,
      this.userId,
      this.blazeMessage,
      this.conversationId,
      this.resendMessageId,
      @required this.runCount});
  factory Job.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Job(
      jobId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}job_id']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
      orderId:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}order_id']),
      priority:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}priority']),
      userId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}user_id']),
      blazeMessage: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}blaze_message']),
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id']),
      resendMessageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}resend_message_id']),
      runCount:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}run_count']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<int>(orderId);
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<int>(priority);
    }
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
    if (!nullToAbsent || runCount != null) {
      map['run_count'] = Variable<int>(runCount);
    }
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
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
      runCount: runCount == null && nullToAbsent
          ? const Value.absent()
          : Value(runCount),
    );
  }

  factory Job.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Job(
      jobId: serializer.fromJson<String>(json['job_id']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      orderId: serializer.fromJson<int>(json['order_id']),
      priority: serializer.fromJson<int>(json['priority']),
      userId: serializer.fromJson<String>(json['user_id']),
      blazeMessage: serializer.fromJson<String>(json['blaze_message']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      resendMessageId: serializer.fromJson<String>(json['resend_message_id']),
      runCount: serializer.fromJson<int>(json['run_count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'job_id': serializer.toJson<String>(jobId),
      'created_at': serializer.toJson<String>(createdAt),
      'order_id': serializer.toJson<int>(orderId),
      'priority': serializer.toJson<int>(priority),
      'user_id': serializer.toJson<String>(userId),
      'blaze_message': serializer.toJson<String>(blazeMessage),
      'conversation_id': serializer.toJson<String>(conversationId),
      'resend_message_id': serializer.toJson<String>(resendMessageId),
      'run_count': serializer.toJson<int>(runCount),
    };
  }

  Job copyWith(
          {String jobId,
          String createdAt,
          int orderId,
          int priority,
          String userId,
          String blazeMessage,
          String conversationId,
          String resendMessageId,
          int runCount}) =>
      Job(
        jobId: jobId ?? this.jobId,
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
                                  runCount.hashCode)))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Job &&
          other.jobId == this.jobId &&
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
  final Value<String> createdAt;
  final Value<int> orderId;
  final Value<int> priority;
  final Value<String> userId;
  final Value<String> blazeMessage;
  final Value<String> conversationId;
  final Value<String> resendMessageId;
  final Value<int> runCount;
  const JobsCompanion({
    this.jobId = const Value.absent(),
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
    @required String jobId,
    @required String createdAt,
    this.orderId = const Value.absent(),
    @required int priority,
    this.userId = const Value.absent(),
    this.blazeMessage = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.resendMessageId = const Value.absent(),
    @required int runCount,
  })  : jobId = Value(jobId),
        createdAt = Value(createdAt),
        priority = Value(priority),
        runCount = Value(runCount);
  static Insertable<Job> custom({
    Expression<String> jobId,
    Expression<String> createdAt,
    Expression<int> orderId,
    Expression<int> priority,
    Expression<String> userId,
    Expression<String> blazeMessage,
    Expression<String> conversationId,
    Expression<String> resendMessageId,
    Expression<int> runCount,
  }) {
    return RawValuesInsertable({
      if (jobId != null) 'job_id': jobId,
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
      {Value<String> jobId,
      Value<String> createdAt,
      Value<int> orderId,
      Value<int> priority,
      Value<String> userId,
      Value<String> blazeMessage,
      Value<String> conversationId,
      Value<String> resendMessageId,
      Value<int> runCount}) {
    return JobsCompanion(
      jobId: jobId ?? this.jobId,
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
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('jobId: $jobId, ')
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
  final String _alias;
  Jobs(this._db, [this._alias]);
  final VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  GeneratedTextColumn _jobId;
  GeneratedTextColumn get jobId => _jobId ??= _constructJobId();
  GeneratedTextColumn _constructJobId() {
    return GeneratedTextColumn('job_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _orderIdMeta = const VerificationMeta('orderId');
  GeneratedIntColumn _orderId;
  GeneratedIntColumn get orderId => _orderId ??= _constructOrderId();
  GeneratedIntColumn _constructOrderId() {
    return GeneratedIntColumn('order_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _priorityMeta = const VerificationMeta('priority');
  GeneratedIntColumn _priority;
  GeneratedIntColumn get priority => _priority ??= _constructPriority();
  GeneratedIntColumn _constructPriority() {
    return GeneratedIntColumn('priority', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  GeneratedTextColumn _userId;
  GeneratedTextColumn get userId => _userId ??= _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _blazeMessageMeta =
      const VerificationMeta('blazeMessage');
  GeneratedTextColumn _blazeMessage;
  GeneratedTextColumn get blazeMessage =>
      _blazeMessage ??= _constructBlazeMessage();
  GeneratedTextColumn _constructBlazeMessage() {
    return GeneratedTextColumn('blaze_message', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  GeneratedTextColumn _conversationId;
  GeneratedTextColumn get conversationId =>
      _conversationId ??= _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _resendMessageIdMeta =
      const VerificationMeta('resendMessageId');
  GeneratedTextColumn _resendMessageId;
  GeneratedTextColumn get resendMessageId =>
      _resendMessageId ??= _constructResendMessageId();
  GeneratedTextColumn _constructResendMessageId() {
    return GeneratedTextColumn('resend_message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _runCountMeta = const VerificationMeta('runCount');
  GeneratedIntColumn _runCount;
  GeneratedIntColumn get runCount => _runCount ??= _constructRunCount();
  GeneratedIntColumn _constructRunCount() {
    return GeneratedIntColumn('run_count', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  @override
  List<GeneratedColumn> get $columns => [
        jobId,
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
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id'], _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id'], _orderIdMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority'], _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id'], _userIdMeta));
    }
    if (data.containsKey('blaze_message')) {
      context.handle(
          _blazeMessageMeta,
          blazeMessage.isAcceptableOrUnknown(
              data['blaze_message'], _blazeMessageMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id'], _conversationIdMeta));
    }
    if (data.containsKey('resend_message_id')) {
      context.handle(
          _resendMessageIdMeta,
          resendMessageId.isAcceptableOrUnknown(
              data['resend_message_id'], _resendMessageIdMeta));
    }
    if (data.containsKey('run_count')) {
      context.handle(_runCountMeta,
          runCount.isAcceptableOrUnknown(data['run_count'], _runCountMeta));
    } else if (isInserting) {
      context.missing(_runCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {jobId};
  @override
  Job map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Job.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Jobs createAlias(String alias) {
    return Jobs(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(job_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class MessageMention extends DataClass implements Insertable<MessageMention> {
  final String messageId;
  final String conversationId;
  final String mentions;
  final int hasRead;
  MessageMention(
      {@required this.messageId,
      @required this.conversationId,
      @required this.mentions,
      this.hasRead});
  factory MessageMention.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return MessageMention(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id']),
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id']),
      mentions: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}mentions']),
      hasRead:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}has_read']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    if (!nullToAbsent || mentions != null) {
      map['mentions'] = Variable<String>(mentions);
    }
    if (!nullToAbsent || hasRead != null) {
      map['has_read'] = Variable<int>(hasRead);
    }
    return map;
  }

  MessageMentionsCompanion toCompanion(bool nullToAbsent) {
    return MessageMentionsCompanion(
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      mentions: mentions == null && nullToAbsent
          ? const Value.absent()
          : Value(mentions),
      hasRead: hasRead == null && nullToAbsent
          ? const Value.absent()
          : Value(hasRead),
    );
  }

  factory MessageMention.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return MessageMention(
      messageId: serializer.fromJson<String>(json['message_id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      mentions: serializer.fromJson<String>(json['mentions']),
      hasRead: serializer.fromJson<int>(json['has_read']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'conversation_id': serializer.toJson<String>(conversationId),
      'mentions': serializer.toJson<String>(mentions),
      'has_read': serializer.toJson<int>(hasRead),
    };
  }

  MessageMention copyWith(
          {String messageId,
          String conversationId,
          String mentions,
          int hasRead}) =>
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
  final Value<int> hasRead;
  const MessageMentionsCompanion({
    this.messageId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.mentions = const Value.absent(),
    this.hasRead = const Value.absent(),
  });
  MessageMentionsCompanion.insert({
    @required String messageId,
    @required String conversationId,
    @required String mentions,
    this.hasRead = const Value.absent(),
  })  : messageId = Value(messageId),
        conversationId = Value(conversationId),
        mentions = Value(mentions);
  static Insertable<MessageMention> custom({
    Expression<String> messageId,
    Expression<String> conversationId,
    Expression<String> mentions,
    Expression<int> hasRead,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (mentions != null) 'mentions': mentions,
      if (hasRead != null) 'has_read': hasRead,
    });
  }

  MessageMentionsCompanion copyWith(
      {Value<String> messageId,
      Value<String> conversationId,
      Value<String> mentions,
      Value<int> hasRead}) {
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
      map['has_read'] = Variable<int>(hasRead.value);
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
  final String _alias;
  MessageMentions(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  GeneratedTextColumn _messageId;
  GeneratedTextColumn get messageId => _messageId ??= _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  GeneratedTextColumn _conversationId;
  GeneratedTextColumn get conversationId =>
      _conversationId ??= _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _mentionsMeta = const VerificationMeta('mentions');
  GeneratedTextColumn _mentions;
  GeneratedTextColumn get mentions => _mentions ??= _constructMentions();
  GeneratedTextColumn _constructMentions() {
    return GeneratedTextColumn('mentions', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _hasReadMeta = const VerificationMeta('hasRead');
  GeneratedIntColumn _hasRead;
  GeneratedIntColumn get hasRead => _hasRead ??= _constructHasRead();
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
          messageId.isAcceptableOrUnknown(data['message_id'], _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id'], _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('mentions')) {
      context.handle(_mentionsMeta,
          mentions.isAcceptableOrUnknown(data['mentions'], _mentionsMeta));
    } else if (isInserting) {
      context.missing(_mentionsMeta);
    }
    if (data.containsKey('has_read')) {
      context.handle(_hasReadMeta,
          hasRead.isAcceptableOrUnknown(data['has_read'], _hasReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  MessageMention map(Map<String, dynamic> data, {String tablePrefix}) {
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
  final String category;
  final String content;
  final String mediaUrl;
  final String mediaMimeType;
  final int mediaSize;
  final String mediaDuration;
  final int mediaWidth;
  final int mediaHeight;
  final String mediaHash;
  final String thumbImage;
  final String mediaKey;
  final String mediaDigest;
  final String mediaStatus;
  final String status;
  final String createdAt;
  final String participantId;
  final String snapshotId;
  final String hyperlink;
  final String name;
  final String albumId;
  final String stickerId;
  final String sharedUserId;
  final String mediaWaveform;
  final String quoteMessageId;
  final String quoteContent;
  final String thumbUrl;
  Message(
      {@required this.messageId,
      @required this.conversationId,
      @required this.userId,
      @required this.category,
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
      @required this.status,
      @required this.createdAt,
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
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Message(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id']),
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id']),
      userId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}user_id']),
      category: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}category']),
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
      mediaStatus: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}media_status']),
      status:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}status']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
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
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
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
      map['media_status'] = Variable<String>(mediaStatus);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
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
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
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
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
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
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Message(
      messageId: serializer.fromJson<String>(json['message_id']),
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      category: serializer.fromJson<String>(json['category']),
      content: serializer.fromJson<String>(json['content']),
      mediaUrl: serializer.fromJson<String>(json['media_url']),
      mediaMimeType: serializer.fromJson<String>(json['media_mime_type']),
      mediaSize: serializer.fromJson<int>(json['media_size']),
      mediaDuration: serializer.fromJson<String>(json['media_duration']),
      mediaWidth: serializer.fromJson<int>(json['media_width']),
      mediaHeight: serializer.fromJson<int>(json['media_height']),
      mediaHash: serializer.fromJson<String>(json['media_hash']),
      thumbImage: serializer.fromJson<String>(json['thumb_image']),
      mediaKey: serializer.fromJson<String>(json['media_key']),
      mediaDigest: serializer.fromJson<String>(json['media_digest']),
      mediaStatus: serializer.fromJson<String>(json['media_status']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      participantId: serializer.fromJson<String>(json['participant_id']),
      snapshotId: serializer.fromJson<String>(json['snapshot_id']),
      hyperlink: serializer.fromJson<String>(json['hyperlink']),
      name: serializer.fromJson<String>(json['name']),
      albumId: serializer.fromJson<String>(json['album_id']),
      stickerId: serializer.fromJson<String>(json['sticker_id']),
      sharedUserId: serializer.fromJson<String>(json['shared_user_id']),
      mediaWaveform: serializer.fromJson<String>(json['media_waveform']),
      quoteMessageId: serializer.fromJson<String>(json['quote_message_id']),
      quoteContent: serializer.fromJson<String>(json['quote_content']),
      thumbUrl: serializer.fromJson<String>(json['thumb_url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'conversation_id': serializer.toJson<String>(conversationId),
      'user_id': serializer.toJson<String>(userId),
      'category': serializer.toJson<String>(category),
      'content': serializer.toJson<String>(content),
      'media_url': serializer.toJson<String>(mediaUrl),
      'media_mime_type': serializer.toJson<String>(mediaMimeType),
      'media_size': serializer.toJson<int>(mediaSize),
      'media_duration': serializer.toJson<String>(mediaDuration),
      'media_width': serializer.toJson<int>(mediaWidth),
      'media_height': serializer.toJson<int>(mediaHeight),
      'media_hash': serializer.toJson<String>(mediaHash),
      'thumb_image': serializer.toJson<String>(thumbImage),
      'media_key': serializer.toJson<String>(mediaKey),
      'media_digest': serializer.toJson<String>(mediaDigest),
      'media_status': serializer.toJson<String>(mediaStatus),
      'status': serializer.toJson<String>(status),
      'created_at': serializer.toJson<String>(createdAt),
      'participant_id': serializer.toJson<String>(participantId),
      'snapshot_id': serializer.toJson<String>(snapshotId),
      'hyperlink': serializer.toJson<String>(hyperlink),
      'name': serializer.toJson<String>(name),
      'album_id': serializer.toJson<String>(albumId),
      'sticker_id': serializer.toJson<String>(stickerId),
      'shared_user_id': serializer.toJson<String>(sharedUserId),
      'media_waveform': serializer.toJson<String>(mediaWaveform),
      'quote_message_id': serializer.toJson<String>(quoteMessageId),
      'quote_content': serializer.toJson<String>(quoteContent),
      'thumb_url': serializer.toJson<String>(thumbUrl),
    };
  }

  Message copyWith(
          {String messageId,
          String conversationId,
          String userId,
          String category,
          String content,
          String mediaUrl,
          String mediaMimeType,
          int mediaSize,
          String mediaDuration,
          int mediaWidth,
          int mediaHeight,
          String mediaHash,
          String thumbImage,
          String mediaKey,
          String mediaDigest,
          String mediaStatus,
          String status,
          String createdAt,
          String participantId,
          String snapshotId,
          String hyperlink,
          String name,
          String albumId,
          String stickerId,
          String sharedUserId,
          String mediaWaveform,
          String quoteMessageId,
          String quoteContent,
          String thumbUrl}) =>
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
                                                                              participantId.hashCode,
                                                                              $mrjc(snapshotId.hashCode, $mrjc(hyperlink.hashCode, $mrjc(name.hashCode, $mrjc(albumId.hashCode, $mrjc(stickerId.hashCode, $mrjc(sharedUserId.hashCode, $mrjc(mediaWaveform.hashCode, $mrjc(quoteMessageId.hashCode, $mrjc(quoteContent.hashCode, thumbUrl.hashCode)))))))))))))))))))))))))))));
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
  final Value<String> category;
  final Value<String> content;
  final Value<String> mediaUrl;
  final Value<String> mediaMimeType;
  final Value<int> mediaSize;
  final Value<String> mediaDuration;
  final Value<int> mediaWidth;
  final Value<int> mediaHeight;
  final Value<String> mediaHash;
  final Value<String> thumbImage;
  final Value<String> mediaKey;
  final Value<String> mediaDigest;
  final Value<String> mediaStatus;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<String> participantId;
  final Value<String> snapshotId;
  final Value<String> hyperlink;
  final Value<String> name;
  final Value<String> albumId;
  final Value<String> stickerId;
  final Value<String> sharedUserId;
  final Value<String> mediaWaveform;
  final Value<String> quoteMessageId;
  final Value<String> quoteContent;
  final Value<String> thumbUrl;
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
    @required String messageId,
    @required String conversationId,
    @required String userId,
    @required String category,
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
    @required String status,
    @required String createdAt,
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
    Expression<String> messageId,
    Expression<String> conversationId,
    Expression<String> userId,
    Expression<String> category,
    Expression<String> content,
    Expression<String> mediaUrl,
    Expression<String> mediaMimeType,
    Expression<int> mediaSize,
    Expression<String> mediaDuration,
    Expression<int> mediaWidth,
    Expression<int> mediaHeight,
    Expression<String> mediaHash,
    Expression<String> thumbImage,
    Expression<String> mediaKey,
    Expression<String> mediaDigest,
    Expression<String> mediaStatus,
    Expression<String> status,
    Expression<String> createdAt,
    Expression<String> participantId,
    Expression<String> snapshotId,
    Expression<String> hyperlink,
    Expression<String> name,
    Expression<String> albumId,
    Expression<String> stickerId,
    Expression<String> sharedUserId,
    Expression<String> mediaWaveform,
    Expression<String> quoteMessageId,
    Expression<String> quoteContent,
    Expression<String> thumbUrl,
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
      {Value<String> messageId,
      Value<String> conversationId,
      Value<String> userId,
      Value<String> category,
      Value<String> content,
      Value<String> mediaUrl,
      Value<String> mediaMimeType,
      Value<int> mediaSize,
      Value<String> mediaDuration,
      Value<int> mediaWidth,
      Value<int> mediaHeight,
      Value<String> mediaHash,
      Value<String> thumbImage,
      Value<String> mediaKey,
      Value<String> mediaDigest,
      Value<String> mediaStatus,
      Value<String> status,
      Value<String> createdAt,
      Value<String> participantId,
      Value<String> snapshotId,
      Value<String> hyperlink,
      Value<String> name,
      Value<String> albumId,
      Value<String> stickerId,
      Value<String> sharedUserId,
      Value<String> mediaWaveform,
      Value<String> quoteMessageId,
      Value<String> quoteContent,
      Value<String> thumbUrl}) {
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
      map['media_status'] = Variable<String>(mediaStatus.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
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
  final String _alias;
  Messages(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  GeneratedTextColumn _messageId;
  GeneratedTextColumn get messageId => _messageId ??= _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  GeneratedTextColumn _conversationId;
  GeneratedTextColumn get conversationId =>
      _conversationId ??= _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  GeneratedTextColumn _userId;
  GeneratedTextColumn get userId => _userId ??= _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  GeneratedTextColumn _category;
  GeneratedTextColumn get category => _category ??= _constructCategory();
  GeneratedTextColumn _constructCategory() {
    return GeneratedTextColumn('category', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _contentMeta = const VerificationMeta('content');
  GeneratedTextColumn _content;
  GeneratedTextColumn get content => _content ??= _constructContent();
  GeneratedTextColumn _constructContent() {
    return GeneratedTextColumn('content', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaUrlMeta = const VerificationMeta('mediaUrl');
  GeneratedTextColumn _mediaUrl;
  GeneratedTextColumn get mediaUrl => _mediaUrl ??= _constructMediaUrl();
  GeneratedTextColumn _constructMediaUrl() {
    return GeneratedTextColumn('media_url', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaMimeTypeMeta =
      const VerificationMeta('mediaMimeType');
  GeneratedTextColumn _mediaMimeType;
  GeneratedTextColumn get mediaMimeType =>
      _mediaMimeType ??= _constructMediaMimeType();
  GeneratedTextColumn _constructMediaMimeType() {
    return GeneratedTextColumn('media_mime_type', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaSizeMeta = const VerificationMeta('mediaSize');
  GeneratedIntColumn _mediaSize;
  GeneratedIntColumn get mediaSize => _mediaSize ??= _constructMediaSize();
  GeneratedIntColumn _constructMediaSize() {
    return GeneratedIntColumn('media_size', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaDurationMeta =
      const VerificationMeta('mediaDuration');
  GeneratedTextColumn _mediaDuration;
  GeneratedTextColumn get mediaDuration =>
      _mediaDuration ??= _constructMediaDuration();
  GeneratedTextColumn _constructMediaDuration() {
    return GeneratedTextColumn('media_duration', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaWidthMeta = const VerificationMeta('mediaWidth');
  GeneratedIntColumn _mediaWidth;
  GeneratedIntColumn get mediaWidth => _mediaWidth ??= _constructMediaWidth();
  GeneratedIntColumn _constructMediaWidth() {
    return GeneratedIntColumn('media_width', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaHeightMeta =
      const VerificationMeta('mediaHeight');
  GeneratedIntColumn _mediaHeight;
  GeneratedIntColumn get mediaHeight =>
      _mediaHeight ??= _constructMediaHeight();
  GeneratedIntColumn _constructMediaHeight() {
    return GeneratedIntColumn('media_height', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaHashMeta = const VerificationMeta('mediaHash');
  GeneratedTextColumn _mediaHash;
  GeneratedTextColumn get mediaHash => _mediaHash ??= _constructMediaHash();
  GeneratedTextColumn _constructMediaHash() {
    return GeneratedTextColumn('media_hash', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _thumbImageMeta = const VerificationMeta('thumbImage');
  GeneratedTextColumn _thumbImage;
  GeneratedTextColumn get thumbImage => _thumbImage ??= _constructThumbImage();
  GeneratedTextColumn _constructThumbImage() {
    return GeneratedTextColumn('thumb_image', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaKeyMeta = const VerificationMeta('mediaKey');
  GeneratedTextColumn _mediaKey;
  GeneratedTextColumn get mediaKey => _mediaKey ??= _constructMediaKey();
  GeneratedTextColumn _constructMediaKey() {
    return GeneratedTextColumn('media_key', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaDigestMeta =
      const VerificationMeta('mediaDigest');
  GeneratedTextColumn _mediaDigest;
  GeneratedTextColumn get mediaDigest =>
      _mediaDigest ??= _constructMediaDigest();
  GeneratedTextColumn _constructMediaDigest() {
    return GeneratedTextColumn('media_digest', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaStatusMeta =
      const VerificationMeta('mediaStatus');
  GeneratedTextColumn _mediaStatus;
  GeneratedTextColumn get mediaStatus =>
      _mediaStatus ??= _constructMediaStatus();
  GeneratedTextColumn _constructMediaStatus() {
    return GeneratedTextColumn('media_status', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _statusMeta = const VerificationMeta('status');
  GeneratedTextColumn _status;
  GeneratedTextColumn get status => _status ??= _constructStatus();
  GeneratedTextColumn _constructStatus() {
    return GeneratedTextColumn('status', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _participantIdMeta =
      const VerificationMeta('participantId');
  GeneratedTextColumn _participantId;
  GeneratedTextColumn get participantId =>
      _participantId ??= _constructParticipantId();
  GeneratedTextColumn _constructParticipantId() {
    return GeneratedTextColumn('participant_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _snapshotIdMeta = const VerificationMeta('snapshotId');
  GeneratedTextColumn _snapshotId;
  GeneratedTextColumn get snapshotId => _snapshotId ??= _constructSnapshotId();
  GeneratedTextColumn _constructSnapshotId() {
    return GeneratedTextColumn('snapshot_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _hyperlinkMeta = const VerificationMeta('hyperlink');
  GeneratedTextColumn _hyperlink;
  GeneratedTextColumn get hyperlink => _hyperlink ??= _constructHyperlink();
  GeneratedTextColumn _constructHyperlink() {
    return GeneratedTextColumn('hyperlink', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  GeneratedTextColumn _name;
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _albumIdMeta = const VerificationMeta('albumId');
  GeneratedTextColumn _albumId;
  GeneratedTextColumn get albumId => _albumId ??= _constructAlbumId();
  GeneratedTextColumn _constructAlbumId() {
    return GeneratedTextColumn('album_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _stickerIdMeta = const VerificationMeta('stickerId');
  GeneratedTextColumn _stickerId;
  GeneratedTextColumn get stickerId => _stickerId ??= _constructStickerId();
  GeneratedTextColumn _constructStickerId() {
    return GeneratedTextColumn('sticker_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _sharedUserIdMeta =
      const VerificationMeta('sharedUserId');
  GeneratedTextColumn _sharedUserId;
  GeneratedTextColumn get sharedUserId =>
      _sharedUserId ??= _constructSharedUserId();
  GeneratedTextColumn _constructSharedUserId() {
    return GeneratedTextColumn('shared_user_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _mediaWaveformMeta =
      const VerificationMeta('mediaWaveform');
  GeneratedTextColumn _mediaWaveform;
  GeneratedTextColumn get mediaWaveform =>
      _mediaWaveform ??= _constructMediaWaveform();
  GeneratedTextColumn _constructMediaWaveform() {
    return GeneratedTextColumn('media_waveform', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _quoteMessageIdMeta =
      const VerificationMeta('quoteMessageId');
  GeneratedTextColumn _quoteMessageId;
  GeneratedTextColumn get quoteMessageId =>
      _quoteMessageId ??= _constructQuoteMessageId();
  GeneratedTextColumn _constructQuoteMessageId() {
    return GeneratedTextColumn('quote_message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _quoteContentMeta =
      const VerificationMeta('quoteContent');
  GeneratedTextColumn _quoteContent;
  GeneratedTextColumn get quoteContent =>
      _quoteContent ??= _constructQuoteContent();
  GeneratedTextColumn _constructQuoteContent() {
    return GeneratedTextColumn('quote_content', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _thumbUrlMeta = const VerificationMeta('thumbUrl');
  GeneratedTextColumn _thumbUrl;
  GeneratedTextColumn get thumbUrl => _thumbUrl ??= _constructThumbUrl();
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
          messageId.isAcceptableOrUnknown(data['message_id'], _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id'], _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id'], _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category'], _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content'], _contentMeta));
    }
    if (data.containsKey('media_url')) {
      context.handle(_mediaUrlMeta,
          mediaUrl.isAcceptableOrUnknown(data['media_url'], _mediaUrlMeta));
    }
    if (data.containsKey('media_mime_type')) {
      context.handle(
          _mediaMimeTypeMeta,
          mediaMimeType.isAcceptableOrUnknown(
              data['media_mime_type'], _mediaMimeTypeMeta));
    }
    if (data.containsKey('media_size')) {
      context.handle(_mediaSizeMeta,
          mediaSize.isAcceptableOrUnknown(data['media_size'], _mediaSizeMeta));
    }
    if (data.containsKey('media_duration')) {
      context.handle(
          _mediaDurationMeta,
          mediaDuration.isAcceptableOrUnknown(
              data['media_duration'], _mediaDurationMeta));
    }
    if (data.containsKey('media_width')) {
      context.handle(
          _mediaWidthMeta,
          mediaWidth.isAcceptableOrUnknown(
              data['media_width'], _mediaWidthMeta));
    }
    if (data.containsKey('media_height')) {
      context.handle(
          _mediaHeightMeta,
          mediaHeight.isAcceptableOrUnknown(
              data['media_height'], _mediaHeightMeta));
    }
    if (data.containsKey('media_hash')) {
      context.handle(_mediaHashMeta,
          mediaHash.isAcceptableOrUnknown(data['media_hash'], _mediaHashMeta));
    }
    if (data.containsKey('thumb_image')) {
      context.handle(
          _thumbImageMeta,
          thumbImage.isAcceptableOrUnknown(
              data['thumb_image'], _thumbImageMeta));
    }
    if (data.containsKey('media_key')) {
      context.handle(_mediaKeyMeta,
          mediaKey.isAcceptableOrUnknown(data['media_key'], _mediaKeyMeta));
    }
    if (data.containsKey('media_digest')) {
      context.handle(
          _mediaDigestMeta,
          mediaDigest.isAcceptableOrUnknown(
              data['media_digest'], _mediaDigestMeta));
    }
    if (data.containsKey('media_status')) {
      context.handle(
          _mediaStatusMeta,
          mediaStatus.isAcceptableOrUnknown(
              data['media_status'], _mediaStatusMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status'], _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('participant_id')) {
      context.handle(
          _participantIdMeta,
          participantId.isAcceptableOrUnknown(
              data['participant_id'], _participantIdMeta));
    }
    if (data.containsKey('snapshot_id')) {
      context.handle(
          _snapshotIdMeta,
          snapshotId.isAcceptableOrUnknown(
              data['snapshot_id'], _snapshotIdMeta));
    }
    if (data.containsKey('hyperlink')) {
      context.handle(_hyperlinkMeta,
          hyperlink.isAcceptableOrUnknown(data['hyperlink'], _hyperlinkMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name'], _nameMeta));
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id'], _albumIdMeta));
    }
    if (data.containsKey('sticker_id')) {
      context.handle(_stickerIdMeta,
          stickerId.isAcceptableOrUnknown(data['sticker_id'], _stickerIdMeta));
    }
    if (data.containsKey('shared_user_id')) {
      context.handle(
          _sharedUserIdMeta,
          sharedUserId.isAcceptableOrUnknown(
              data['shared_user_id'], _sharedUserIdMeta));
    }
    if (data.containsKey('media_waveform')) {
      context.handle(
          _mediaWaveformMeta,
          mediaWaveform.isAcceptableOrUnknown(
              data['media_waveform'], _mediaWaveformMeta));
    }
    if (data.containsKey('quote_message_id')) {
      context.handle(
          _quoteMessageIdMeta,
          quoteMessageId.isAcceptableOrUnknown(
              data['quote_message_id'], _quoteMessageIdMeta));
    }
    if (data.containsKey('quote_content')) {
      context.handle(
          _quoteContentMeta,
          quoteContent.isAcceptableOrUnknown(
              data['quote_content'], _quoteContentMeta));
    }
    if (data.containsKey('thumb_url')) {
      context.handle(_thumbUrlMeta,
          thumbUrl.isAcceptableOrUnknown(data['thumb_url'], _thumbUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  Message map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Message.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Messages createAlias(String alias) {
    return Messages(_db, alias);
  }

  @override
  List<String> get customConstraints => const [
        'PRIMARY KEY(message_id)',
        'FOREIGN KEY(conversation_id) REFERENCES conversations(conversation_id) ON UPDATE NO ACTION ON DELETE CASCADE'
      ];
  @override
  bool get dontWriteConstraints => true;
}

class MessagesHistoryData extends DataClass
    implements Insertable<MessagesHistoryData> {
  final String messageId;
  MessagesHistoryData({@required this.messageId});
  factory MessagesHistoryData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return MessagesHistoryData(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    return map;
  }

  MessagesHistoryCompanion toCompanion(bool nullToAbsent) {
    return MessagesHistoryCompanion(
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
    );
  }

  factory MessagesHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return MessagesHistoryData(
      messageId: serializer.fromJson<String>(json['message_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
    };
  }

  MessagesHistoryData copyWith({String messageId}) => MessagesHistoryData(
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
    @required String messageId,
  }) : messageId = Value(messageId);
  static Insertable<MessagesHistoryData> custom({
    Expression<String> messageId,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
    });
  }

  MessagesHistoryCompanion copyWith({Value<String> messageId}) {
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
  final String _alias;
  MessagesHistory(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  GeneratedTextColumn _messageId;
  GeneratedTextColumn get messageId => _messageId ??= _constructMessageId();
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
          messageId.isAcceptableOrUnknown(data['message_id'], _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  MessagesHistoryData map(Map<String, dynamic> data, {String tablePrefix}) {
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
  final String timestamp;
  final String userId;
  final String sessionId;
  final int sentToServer;
  final String createdAt;
  Offset(
      {@required this.timestamp,
      @required this.userId,
      @required this.sessionId,
      this.sentToServer,
      this.createdAt});
  factory Offset.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Offset(
      timestamp: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}timestamp']),
      userId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}user_id']),
      sessionId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}session_id']),
      sentToServer: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}sent_to_server']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || timestamp != null) {
      map['timestamp'] = Variable<String>(timestamp);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || sentToServer != null) {
      map['sent_to_server'] = Variable<int>(sentToServer);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  OffsetsCompanion toCompanion(bool nullToAbsent) {
    return OffsetsCompanion(
      timestamp: timestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(timestamp),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      sentToServer: sentToServer == null && nullToAbsent
          ? const Value.absent()
          : Value(sentToServer),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Offset.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Offset(
      timestamp: serializer.fromJson<String>(json['timestamp']),
      userId: serializer.fromJson<String>(json['user_id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      sentToServer: serializer.fromJson<int>(json['sent_to_server']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'timestamp': serializer.toJson<String>(timestamp),
      'user_id': serializer.toJson<String>(userId),
      'session_id': serializer.toJson<String>(sessionId),
      'sent_to_server': serializer.toJson<int>(sentToServer),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  Offset copyWith(
          {String timestamp,
          String userId,
          String sessionId,
          int sentToServer,
          String createdAt}) =>
      Offset(
        timestamp: timestamp ?? this.timestamp,
        userId: userId ?? this.userId,
        sessionId: sessionId ?? this.sessionId,
        sentToServer: sentToServer ?? this.sentToServer,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Offset(')
          ..write('timestamp: $timestamp, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('sentToServer: $sentToServer, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      timestamp.hashCode,
      $mrjc(
          userId.hashCode,
          $mrjc(sessionId.hashCode,
              $mrjc(sentToServer.hashCode, createdAt.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Offset &&
          other.timestamp == this.timestamp &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.sentToServer == this.sentToServer &&
          other.createdAt == this.createdAt);
}

class OffsetsCompanion extends UpdateCompanion<Offset> {
  final Value<String> timestamp;
  final Value<String> userId;
  final Value<String> sessionId;
  final Value<int> sentToServer;
  final Value<String> createdAt;
  const OffsetsCompanion({
    this.timestamp = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sentToServer = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OffsetsCompanion.insert({
    @required String timestamp,
    @required String userId,
    @required String sessionId,
    this.sentToServer = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : timestamp = Value(timestamp),
        userId = Value(userId),
        sessionId = Value(sessionId);
  static Insertable<Offset> custom({
    Expression<String> timestamp,
    Expression<String> userId,
    Expression<String> sessionId,
    Expression<int> sentToServer,
    Expression<String> createdAt,
  }) {
    return RawValuesInsertable({
      if (timestamp != null) 'timestamp': timestamp,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (sentToServer != null) 'sent_to_server': sentToServer,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OffsetsCompanion copyWith(
      {Value<String> timestamp,
      Value<String> userId,
      Value<String> sessionId,
      Value<int> sentToServer,
      Value<String> createdAt}) {
    return OffsetsCompanion(
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      sentToServer: sentToServer ?? this.sentToServer,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
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
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OffsetsCompanion(')
          ..write('timestamp: $timestamp, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('sentToServer: $sentToServer, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class Offsets extends Table with TableInfo<Offsets, Offset> {
  final GeneratedDatabase _db;
  final String _alias;
  Offsets(this._db, [this._alias]);
  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  GeneratedTextColumn _timestamp;
  GeneratedTextColumn get timestamp => _timestamp ??= _constructTimestamp();
  GeneratedTextColumn _constructTimestamp() {
    return GeneratedTextColumn('timestamp', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  GeneratedTextColumn _userId;
  GeneratedTextColumn get userId => _userId ??= _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  GeneratedTextColumn _sessionId;
  GeneratedTextColumn get sessionId => _sessionId ??= _constructSessionId();
  GeneratedTextColumn _constructSessionId() {
    return GeneratedTextColumn('session_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _sentToServerMeta =
      const VerificationMeta('sentToServer');
  GeneratedIntColumn _sentToServer;
  GeneratedIntColumn get sentToServer =>
      _sentToServer ??= _constructSentToServer();
  GeneratedIntColumn _constructSentToServer() {
    return GeneratedIntColumn('sent_to_server', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns =>
      [timestamp, userId, sessionId, sentToServer, createdAt];
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
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp'], _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id'], _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id'], _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('sent_to_server')) {
      context.handle(
          _sentToServerMeta,
          sentToServer.isAcceptableOrUnknown(
              data['sent_to_server'], _sentToServerMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, sessionId};
  @override
  Offset map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Offset.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Offsets createAlias(String alias) {
    return Offsets(_db, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(conversation_id, user_id, session_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Participant extends DataClass implements Insertable<Participant> {
  final String conversationId;
  final String userId;
  final String role;
  final String createdAt;
  Participant(
      {@required this.conversationId,
      @required this.userId,
      @required this.role,
      @required this.createdAt});
  factory Participant.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return Participant(
      conversationId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}conversation_id']),
      userId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}user_id']),
      role: stringType.mapFromDatabaseResponse(data['${effectivePrefix}role']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  ParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ParticipantsCompanion(
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Participant.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Participant(
      conversationId: serializer.fromJson<String>(json['conversation_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      role: serializer.fromJson<String>(json['role']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversation_id': serializer.toJson<String>(conversationId),
      'user_id': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  Participant copyWith(
          {String conversationId,
          String userId,
          String role,
          String createdAt}) =>
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
  final Value<String> role;
  final Value<String> createdAt;
  const ParticipantsCompanion({
    this.conversationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ParticipantsCompanion.insert({
    @required String conversationId,
    @required String userId,
    @required String role,
    @required String createdAt,
  })  : conversationId = Value(conversationId),
        userId = Value(userId),
        role = Value(role),
        createdAt = Value(createdAt);
  static Insertable<Participant> custom({
    Expression<String> conversationId,
    Expression<String> userId,
    Expression<String> role,
    Expression<String> createdAt,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ParticipantsCompanion copyWith(
      {Value<String> conversationId,
      Value<String> userId,
      Value<String> role,
      Value<String> createdAt}) {
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
      map['role'] = Variable<String>(role.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
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
  final String _alias;
  Participants(this._db, [this._alias]);
  final VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  GeneratedTextColumn _conversationId;
  GeneratedTextColumn get conversationId =>
      _conversationId ??= _constructConversationId();
  GeneratedTextColumn _constructConversationId() {
    return GeneratedTextColumn('conversation_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  GeneratedTextColumn _userId;
  GeneratedTextColumn get userId => _userId ??= _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _roleMeta = const VerificationMeta('role');
  GeneratedTextColumn _role;
  GeneratedTextColumn get role => _role ??= _constructRole();
  GeneratedTextColumn _constructRole() {
    return GeneratedTextColumn('role', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
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
              data['conversation_id'], _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id'], _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role'], _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, userId};
  @override
  Participant map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Participant.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Participants createAlias(String alias) {
    return Participants(_db, alias);
  }

  @override
  List<String> get customConstraints => const [
        'PRIMARY KEY(conversation_id,user_id)',
        'FOREIGN KEY(conversation_id) REFERENCES conversations(conversation_id) ON UPDATE NO ACTION ON DELETE CASCADE'
      ];
  @override
  bool get dontWriteConstraints => true;
}

class RatchetSenderKey extends DataClass
    implements Insertable<RatchetSenderKey> {
  final String groupId;
  final String senderId;
  final String status;
  final String messageId;
  final String createdAt;
  RatchetSenderKey(
      {@required this.groupId,
      @required this.senderId,
      @required this.status,
      this.messageId,
      @required this.createdAt});
  factory RatchetSenderKey.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return RatchetSenderKey(
      groupId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}group_id']),
      senderId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}sender_id']),
      status:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}status']),
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
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
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  RatchetSenderKeysCompanion toCompanion(bool nullToAbsent) {
    return RatchetSenderKeysCompanion(
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      senderId: senderId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderId),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory RatchetSenderKey.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return RatchetSenderKey(
      groupId: serializer.fromJson<String>(json['group_id']),
      senderId: serializer.fromJson<String>(json['sender_id']),
      status: serializer.fromJson<String>(json['status']),
      messageId: serializer.fromJson<String>(json['message_id']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'group_id': serializer.toJson<String>(groupId),
      'sender_id': serializer.toJson<String>(senderId),
      'status': serializer.toJson<String>(status),
      'message_id': serializer.toJson<String>(messageId),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  RatchetSenderKey copyWith(
          {String groupId,
          String senderId,
          String status,
          String messageId,
          String createdAt}) =>
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
  final Value<String> messageId;
  final Value<String> createdAt;
  const RatchetSenderKeysCompanion({
    this.groupId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.status = const Value.absent(),
    this.messageId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RatchetSenderKeysCompanion.insert({
    @required String groupId,
    @required String senderId,
    @required String status,
    this.messageId = const Value.absent(),
    @required String createdAt,
  })  : groupId = Value(groupId),
        senderId = Value(senderId),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<RatchetSenderKey> custom({
    Expression<String> groupId,
    Expression<String> senderId,
    Expression<String> status,
    Expression<String> messageId,
    Expression<String> createdAt,
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
      {Value<String> groupId,
      Value<String> senderId,
      Value<String> status,
      Value<String> messageId,
      Value<String> createdAt}) {
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
      map['message_id'] = Variable<String>(messageId.value);
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
  final String _alias;
  RatchetSenderKeys(this._db, [this._alias]);
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

  final VerificationMeta _statusMeta = const VerificationMeta('status');
  GeneratedTextColumn _status;
  GeneratedTextColumn get status => _status ??= _constructStatus();
  GeneratedTextColumn _constructStatus() {
    return GeneratedTextColumn('status', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  GeneratedTextColumn _messageId;
  GeneratedTextColumn get messageId => _messageId ??= _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
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
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status'], _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id'], _messageIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, senderId};
  @override
  RatchetSenderKey map(Map<String, dynamic> data, {String tablePrefix}) {
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

class ResendSessionMessage extends DataClass
    implements Insertable<ResendSessionMessage> {
  final String messageId;
  final String userId;
  final String sessionId;
  final int status;
  final String createdAt;
  ResendSessionMessage(
      {@required this.messageId,
      @required this.userId,
      @required this.sessionId,
      @required this.status,
      @required this.createdAt});
  factory ResendSessionMessage.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return ResendSessionMessage(
      messageId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}message_id']),
      userId:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}user_id']),
      sessionId: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}session_id']),
      status: intType.mapFromDatabaseResponse(data['${effectivePrefix}status']),
      createdAt: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<int>(status);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  ResendSessionMessagesCompanion toCompanion(bool nullToAbsent) {
    return ResendSessionMessagesCompanion(
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory ResendSessionMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return ResendSessionMessage(
      messageId: serializer.fromJson<String>(json['message_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      status: serializer.fromJson<int>(json['status']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'message_id': serializer.toJson<String>(messageId),
      'user_id': serializer.toJson<String>(userId),
      'session_id': serializer.toJson<String>(sessionId),
      'status': serializer.toJson<int>(status),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  ResendSessionMessage copyWith(
          {String messageId,
          String userId,
          String sessionId,
          int status,
          String createdAt}) =>
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
  final Value<String> createdAt;
  const ResendSessionMessagesCompanion({
    this.messageId = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ResendSessionMessagesCompanion.insert({
    @required String messageId,
    @required String userId,
    @required String sessionId,
    @required int status,
    @required String createdAt,
  })  : messageId = Value(messageId),
        userId = Value(userId),
        sessionId = Value(sessionId),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<ResendSessionMessage> custom({
    Expression<String> messageId,
    Expression<String> userId,
    Expression<String> sessionId,
    Expression<int> status,
    Expression<String> createdAt,
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
      {Value<String> messageId,
      Value<String> userId,
      Value<String> sessionId,
      Value<int> status,
      Value<String> createdAt}) {
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
      map['created_at'] = Variable<String>(createdAt.value);
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
  final String _alias;
  ResendSessionMessages(this._db, [this._alias]);
  final VerificationMeta _messageIdMeta = const VerificationMeta('messageId');
  GeneratedTextColumn _messageId;
  GeneratedTextColumn get messageId => _messageId ??= _constructMessageId();
  GeneratedTextColumn _constructMessageId() {
    return GeneratedTextColumn('message_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  GeneratedTextColumn _userId;
  GeneratedTextColumn get userId => _userId ??= _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  GeneratedTextColumn _sessionId;
  GeneratedTextColumn get sessionId => _sessionId ??= _constructSessionId();
  GeneratedTextColumn _constructSessionId() {
    return GeneratedTextColumn('session_id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _statusMeta = const VerificationMeta('status');
  GeneratedIntColumn _status;
  GeneratedIntColumn get status => _status ??= _constructStatus();
  GeneratedIntColumn _constructStatus() {
    return GeneratedIntColumn('status', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedTextColumn _createdAt;
  GeneratedTextColumn get createdAt => _createdAt ??= _constructCreatedAt();
  GeneratedTextColumn _constructCreatedAt() {
    return GeneratedTextColumn('created_at', $tableName, false,
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
          messageId.isAcceptableOrUnknown(data['message_id'], _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id'], _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id'], _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status'], _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, userId, sessionId};
  @override
  ResendSessionMessage map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return ResendSessionMessage.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  ResendSessionMessages createAlias(String alias) {
    return ResendSessionMessages(_db, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(message_id, user_id, session_id)'];
  @override
  bool get dontWriteConstraints => true;
}

abstract class _$MixinDatabase extends GeneratedDatabase {
  _$MixinDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  Addresses _addresses;
  Addresses get addresses => _addresses ??= Addresses(this);
  Apps _apps;
  Apps get apps => _apps ??= Apps(this);
  Assets _assets;
  Assets get assets => _assets ??= Assets(this);
  CircleConversations _circleConversations;
  CircleConversations get circleConversations =>
      _circleConversations ??= CircleConversations(this);
  Circles _circles;
  Circles get circles => _circles ??= Circles(this);
  Conversations _conversations;
  Conversations get conversations => _conversations ??= Conversations(this);
  FloodMessages _floodMessages;
  FloodMessages get floodMessages => _floodMessages ??= FloodMessages(this);
  Hyperlinks _hyperlinks;
  Hyperlinks get hyperlinks => _hyperlinks ??= Hyperlinks(this);
  Jobs _jobs;
  Jobs get jobs => _jobs ??= Jobs(this);
  MessageMentions _messageMentions;
  MessageMentions get messageMentions =>
      _messageMentions ??= MessageMentions(this);
  Messages _messages;
  Messages get messages => _messages ??= Messages(this);
  MessagesHistory _messagesHistory;
  MessagesHistory get messagesHistory =>
      _messagesHistory ??= MessagesHistory(this);
  Offsets _offsets;
  Offsets get offsets => _offsets ??= Offsets(this);
  Participants _participants;
  Participants get participants => _participants ??= Participants(this);
  RatchetSenderKeys _ratchetSenderKeys;
  RatchetSenderKeys get ratchetSenderKeys =>
      _ratchetSenderKeys ??= RatchetSenderKeys(this);
  ResendSessionMessages _resendSessionMessages;
  ResendSessionMessages get resendSessionMessages =>
      _resendSessionMessages ??= ResendSessionMessages(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        addresses,
        apps,
        assets,
        circleConversations,
        circles,
        conversations,
        floodMessages,
        hyperlinks,
        jobs,
        messageMentions,
        messages,
        messagesHistory,
        offsets,
        participants,
        ratchetSenderKeys,
        resendSessionMessages
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
