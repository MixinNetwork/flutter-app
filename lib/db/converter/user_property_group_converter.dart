import 'package:drift/drift.dart';

import '../../enum/property_group.dart';

class UserPropertyGroupConverter
    extends TypeConverter<UserPropertyGroup, String> {
  const UserPropertyGroupConverter();

  @override
  UserPropertyGroup fromSql(String fromDb) =>
      UserPropertyGroup.values.byName(fromDb);

  @override
  String toSql(UserPropertyGroup value) => value.name;
}
