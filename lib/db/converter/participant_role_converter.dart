import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';

class ParticipantRoleConverter extends TypeConverter<ParticipantRole, String> {
  const ParticipantRoleConverter();

  @override
  ParticipantRole mapToDart(String fromDb) =>
      const ParticipantRoleJsonConverter().fromJson(fromDb);

  @override
  String mapToSql(ParticipantRole value) =>
      const ParticipantRoleJsonConverter().toJson(value);
}
