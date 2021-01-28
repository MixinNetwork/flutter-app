import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'sticker_albums_dao.g.dart';

@UseDao(tables: [StickerAlbums])
class StickerAlbumsDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerAlbumsDaoMixin {
  StickerAlbumsDao(MixinDatabase db) : super(db);

  Future<int> insert(StickerAlbum stickerAlbum) =>
      into(db.stickerAlbums).insertOnConflictUpdate(stickerAlbum);

  Future deleteStickerAlbum(StickerAlbum stickerAlbum) =>
      delete(db.stickerAlbums).delete(stickerAlbum);
}
