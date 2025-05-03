import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

enum MediaStatus { pending, done, canceled, expired, read }

class MediaStatusJsonConverter extends EnumJsonConverter<MediaStatus> {
  const MediaStatusJsonConverter();

  @override
  List<MediaStatus> enumValues() => MediaStatus.values;
}
