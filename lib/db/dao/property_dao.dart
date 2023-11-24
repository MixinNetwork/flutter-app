import 'package:drift/drift.dart';

import '../../enum/property_group.dart';
import '../../utils/db/db_key_value.dart';
import '../mixin_database.dart';

part 'property_dao.g.dart';

@DriftAccessor(
  include: {'../moor/dao/property.drift'},
)
class PropertyDao extends DatabaseAccessor<MixinDatabase>
    with _$PropertyDaoMixin
    implements KeyValueDao<UserPropertyGroup> {
  PropertyDao(super.attachedDatabase);

  Future<String?> getProperty(UserPropertyGroup group, String key) async {
    final result = await (select(properties)
          ..where((tbl) => tbl.group.equalsValue(group) & tbl.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<Map<String, String>> getProperties(UserPropertyGroup group) async {
    final result = await (select(properties)
          ..where((tbl) => tbl.group.equalsValue(group)))
        .get();
    return Map.fromEntries(result.map((e) => MapEntry(e.key, e.value)));
  }

  Future<void> removeProperty(UserPropertyGroup group, String key) async {
    await (delete(properties)
          ..where((tbl) => tbl.group.equalsValue(group) & tbl.key.equals(key)))
        .go();
  }

  Future<void> setProperty(
    UserPropertyGroup group,
    String key,
    String value,
  ) async {
    await into(properties).insertOnConflictUpdate(
      PropertiesCompanion.insert(
        group: group,
        key: key,
        value: value,
      ),
    );
  }

  Future<void> clearProperties(UserPropertyGroup group) =>
      (delete(properties)..where((tbl) => tbl.group.equalsValue(group))).go();

  @override
  Future<void> clear(UserPropertyGroup group) =>
      (delete(properties)..where((tbl) => tbl.group.equalsValue(group))).go();

  @override
  Future<Map<String, String>> getAll(UserPropertyGroup group) async {
    final result = await (select(properties)
          ..where((tbl) => tbl.group.equalsValue(group)))
        .get();
    return Map.fromEntries(result.map((e) => MapEntry(e.key, e.value)));
  }

  @override
  Future<String?> getByKey(UserPropertyGroup group, String key) async {
    final result = await (select(properties)
          ..where((tbl) => tbl.group.equalsValue(group) & tbl.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  @override
  Future<void> set(UserPropertyGroup group, String key, String? value) async {
    if (value != null) {
      await into(properties).insertOnConflictUpdate(
        PropertiesCompanion.insert(
          group: group,
          key: key,
          value: value,
        ),
      );
    } else {
      await (delete(properties)
            ..where(
                (tbl) => tbl.group.equalsValue(group) & tbl.key.equals(key)))
          .go();
    }
  }

  @override
  Stream<Map<String, String>> watchAll(UserPropertyGroup group) =>
      (select(properties)..where((tbl) => tbl.group.equalsValue(group)))
          .watch()
          .map((event) =>
              Map.fromEntries(event.map((e) => MapEntry(e.key, e.value))));

  @override
  Stream<String?> watchByKey(UserPropertyGroup group, String key) => (select(
          properties)
        ..where((tbl) => tbl.group.equalsValue(group) & tbl.key.equals(key)))
      .watchSingleOrNull()
      .map((event) => event?.value);

  @override
  Stream<void> watchTableHasChanged(UserPropertyGroup group) =>
      db.tableUpdates(TableUpdateQuery.onTable(db.properties));
}
