import 'package:drift/drift.dart';

import '../../enum/property_group.dart';

class PropertyGroupConverter extends TypeConverter<PropertyGroup, String> {
  const PropertyGroupConverter();

  @override
  PropertyGroup fromSql(String fromDb) => PropertyGroup.values.byName(fromDb);

  @override
  String toSql(PropertyGroup value) => value.name;
}
