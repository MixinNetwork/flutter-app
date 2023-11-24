import 'package:drift/drift.dart';

import '../../../enum/property_group.dart';

class AppPropertyGroupConverter
    extends TypeConverter<AppPropertyGroup, String> {
  const AppPropertyGroupConverter();

  @override
  AppPropertyGroup fromSql(String fromDb) =>
      AppPropertyGroup.values.byName(fromDb);

  @override
  String toSql(AppPropertyGroup value) => value.name;
}
