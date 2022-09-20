import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:recase/recase.dart';

import '../../enum/media_status.dart';

class MediaStatusTypeConverter extends TypeConverter<MediaStatus?, String?> {
  const MediaStatusTypeConverter();

  @override
  MediaStatus? fromSql(String? fromDb) =>
      fromStringToEnum(MediaStatus.values, fromDb);

  @override
  String? toSql(MediaStatus? value) => enumConvertToString(value)?.constantCase;
}
