import 'package:drift/drift.dart';

import '../../enum/property_group.dart';
import '../mixin_database.dart';

part 'property_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/property.drift'})
class PropertyDao extends DatabaseAccessor<MixinDatabase>
    with _$PropertyDaoMixin {
  PropertyDao(super.attachedDatabase);

  Future<String?> getProperty(PropertyGroup group, String key) async {
    final result =
        await (select(properties)..where(
          (tbl) => tbl.group.equalsValue(group) & tbl.key.equals(key),
        )).getSingleOrNull();
    return result?.value;
  }

  Future<Map<String, String>> getProperties(PropertyGroup group) async {
    final result =
        await (select(properties)
          ..where((tbl) => tbl.group.equalsValue(group))).get();
    return Map.fromEntries(result.map((e) => MapEntry(e.key, e.value)));
  }

  Future<void> removeProperty(PropertyGroup group, String key) async {
    await (delete(
      properties,
    )..where((tbl) => tbl.group.equalsValue(group) & tbl.key.equals(key))).go();
  }

  Future<void> setProperty(
    PropertyGroup group,
    String key,
    String value,
  ) async {
    await into(properties).insertOnConflictUpdate(
      PropertiesCompanion.insert(group: group, key: key, value: value),
    );
  }

  Future<void> clearProperties(PropertyGroup group) =>
      (delete(properties)..where((tbl) => tbl.group.equalsValue(group))).go();
}
