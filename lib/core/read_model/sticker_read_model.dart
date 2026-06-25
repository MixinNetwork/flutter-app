import 'package:rxdart/rxdart.dart';

import '../../db/dao/sticker_album_dao.dart';
import '../../db/dao/sticker_dao.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';

const kStickerReadModelThrottleDuration = Duration(seconds: 3);

class StickerReadModel {
  StickerReadModel({
    required StickerDao stickerDao,
    required StickerAlbumDao stickerAlbumDao,
    DataBaseEventBus? eventBus,
  }) : _stickerDao = stickerDao,
       _stickerAlbumDao = stickerAlbumDao,
       _eventBus = eventBus ?? DataBaseEventBus.instance;

  final StickerDao _stickerDao;
  final StickerAlbumDao _stickerAlbumDao;
  final DataBaseEventBus _eventBus;

  Stream<List<StickerAlbum>> systemAddedAlbums() => _watchStickerChanges(
    fetch: () => _stickerAlbumDao.systemAddedAlbums().get(),
  );

  Stream<List<Sticker>> recentUsedStickers() => _watchStickerChanges(
    fetch: () => _stickerDao.recentUsedStickers().get(),
  );

  Stream<List<Sticker>> personalStickers() => _watchStickerChanges(
    fetch: () => _stickerDao.personalStickers().get(),
  );

  Stream<List<Sticker>> albumStickers(String albumId) => _watchStickerChanges(
    albumIds: [albumId],
    fetch: () => _stickerDao.stickerByAlbumId(albumId).get(),
  );

  Stream<List<T>> _watchStickerChanges<T>({
    required Future<List<T>> Function() fetch,
    Iterable<String> albumIds = const [],
  }) {
    final events = albumIds.isEmpty
        ? _eventBus.updateStickerStream
        : _eventBus.watchUpdateStickerStream(albumIds: albumIds);
    return events
        .map<void>((_) {})
        .throttleTime(kStickerReadModelThrottleDuration)
        .startWith(null)
        .asyncMap((_) => fetch());
  }
}
