import 'package:drift/drift.dart';

import '../../../enum/property_group.dart';
import '../../../utils/db/db_key_value.dart';
import '../app_database.dart';

part 'app_key_value_dao.g.dart';

@DriftAccessor(
  include: {'../drift/app.drift'},
)
class AppKeyValueDao extends DatabaseAccessor<AppDatabase>
    with _$AppKeyValueDaoMixin
    implements KeyValueDao<AppPropertyGroup> {
  AppKeyValueDao(super.attachedDatabase);

  @override
  Future<void> clear(AppPropertyGroup group) =>
      (delete(properties)..where((tbl) => tbl.group.equalsValue(group))).go();

  @override
  Future<Map<String, String>> getAll(AppPropertyGroup group) async {
    final result = await (select(properties)
          ..where((tbl) => tbl.group.equalsValue(group)))
        .get();
    return Map.fromEntries(result.map((e) => MapEntry(e.key, e.value)));
  }

  @override
  Future<String?> getByKey(AppPropertyGroup group, String key) async {
    final result = await (select(properties)
          ..where((tbl) => tbl.group.equalsValue(group) & tbl.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  @override
  Future<void> set(AppPropertyGroup group, String key, String? value) async {
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
  Stream<Map<String, String>> watchAll(AppPropertyGroup group) =>
      (select(properties)..where((tbl) => tbl.group.equalsValue(group)))
          .watch()
          .map((event) =>
              Map.fromEntries(event.map((e) => MapEntry(e.key, e.value))));

  @override
  Stream<String?> watchByKey(AppPropertyGroup group, String key) => (select(
          properties)
        ..where((tbl) => tbl.group.equalsValue(group) & tbl.key.equals(key)))
      .watchSingleOrNull()
      .map((event) => event?.value);

  @override
  Stream<void> watchTableHasChanged(AppPropertyGroup group) =>
      db.tableUpdates(TableUpdateQuery.onTable(db.properties));
}
