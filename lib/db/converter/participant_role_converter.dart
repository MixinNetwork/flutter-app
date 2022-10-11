import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class ParticipantRoleConverter
    extends TypeConverter<ParticipantRole?, String?> {
  const ParticipantRoleConverter();

  @override
  ParticipantRole? fromSql(String? fromDb) =>
      const ParticipantRoleJsonConverter().fromJson(fromDb);

  @override
  String? toSql(ParticipantRole? value) =>
      const ParticipantRoleJsonConverter().toJson(value);
}
