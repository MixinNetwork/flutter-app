import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/utils/enum_to_string.dart';
import 'package:moor/moor.dart';

class MediaStatusTypeConverter extends TypeConverter<MediaStatus, String> {
  const MediaStatusTypeConverter();

  @override
  MediaStatus? mapToDart(String? fromDb) =>
      EnumToString.fromString(MediaStatus.values, fromDb);

  @override
  String? mapToSql(MediaStatus? value) => EnumToString.convertToString(value);
}
