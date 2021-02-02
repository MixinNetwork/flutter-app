import 'package:flutter_app/utils/enum_to_string.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:recase/recase.dart';
import 'package:moor/moor.dart';

class ParticipantRoleConverter extends TypeConverter<ParticipantRole, String> {
  const ParticipantRoleConverter();

  @override
  ParticipantRole mapToDart(String fromDb) => EnumToString.fromString(
        ParticipantRole.values,
        fromDb?.camelCase,
      );

  @override
  String mapToSql(ParticipantRole value) =>
      EnumToString.convertToString(value)?.constantCase;
}
