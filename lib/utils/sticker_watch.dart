import '../db/database.dart';
import '../db/database_event_bus.dart';
import '../db/mixin_database.dart';
import 'extension/extension.dart';

Stream<Sticker?> watchStickerById(
  Database database,
  String stickerId, {
  Duration duration = kDefaultThrottleDuration,
}) {
  if (stickerId.isEmpty) return const Stream<Sticker?>.empty();

  return database.stickerDao
      .sticker(stickerId)
      .watchSingleOrNullWithStream(
        eventStreams: [
          DataBaseEventBus.instance.watchUpdateStickerStream(
            stickerIds: [stickerId],
          ),
        ],
        duration: duration,
      );
}
