import 'package:flutter_app/utils/enum_to_string.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:recase/recase.dart';
import 'package:moor/moor.dart';

class UserRelationshipConverter
    extends TypeConverter<UserRelationship, String> {
  const UserRelationshipConverter();

  @override
  UserRelationship mapToDart(String fromDb) => EnumToString.fromString(
        UserRelationship.values,
        fromDb?.camelCase,
      );

  @override
  String mapToSql(UserRelationship value) =>
      EnumToString.convertToString(value)?.constantCase;
}
