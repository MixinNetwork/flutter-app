// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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
  late final GeneratedColumnWithTypeConverter<AppPropertyGroup, String> group =
      GeneratedColumn<String>('group', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: true,
              $customConstraints: 'NOT NULL')
          .withConverter<AppPropertyGroup>(Properties.$convertergroup);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [key, group, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'properties';
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

  static TypeConverter<AppPropertyGroup, String> $convertergroup =
      const AppPropertyGroupConverter();
  @override
  List<String> get customConstraints => const ['PRIMARY KEY("key", "group")'];
  @override
  bool get dontWriteConstraints => true;
}

class Propertie extends DataClass implements Insertable<Propertie> {
  final String key;
  final AppPropertyGroup group;
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
      group: serializer.fromJson<AppPropertyGroup>(json['group']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'group': serializer.toJson<AppPropertyGroup>(group),
      'value': serializer.toJson<String>(value),
    };
  }

  Propertie copyWith({String? key, AppPropertyGroup? group, String? value}) =>
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
  final Value<AppPropertyGroup> group;
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
    required AppPropertyGroup group,
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
      Value<AppPropertyGroup>? group,
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final Properties properties = Properties(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [properties];
}
