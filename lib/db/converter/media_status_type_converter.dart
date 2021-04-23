import 'package:flutter_app/enum/media_status.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';
import 'package:recase/recase.dart';

class MediaStatusTypeConverter extends TypeConverter<MediaStatus, String> {
  const MediaStatusTypeConverter();

  @override
  MediaStatus? mapToDart(String? fromDb) =>
      EnumToString.fromString(MediaStatus.values, fromDb);

  @override
  String? mapToSql(MediaStatus? value) =>
      EnumToString.convertToString(value)?.constantCase;
}
