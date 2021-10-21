import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class UserRelationshipConverter
    extends TypeConverter<UserRelationship, String> {
  const UserRelationshipConverter();

  @override
  UserRelationship? mapToDart(String? fromDb) =>
      const UserRelationshipJsonConverter().fromJson(fromDb);

  @override
  String? mapToSql(UserRelationship? value) =>
      const UserRelationshipJsonConverter().toJson(value);
}
