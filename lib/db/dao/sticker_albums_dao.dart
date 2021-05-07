import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'sticker_albums_dao.g.dart';

@UseDao(tables: [StickerAlbums])
class StickerAlbumsDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerAlbumsDaoMixin {
  StickerAlbumsDao(MixinDatabase db) : super(db);

  Future<int> insert(StickerAlbum stickerAlbum) =>
      into(db.stickerAlbums).insertOnConflictUpdate(stickerAlbum);

  Future<int> deleteStickerAlbum(StickerAlbum stickerAlbum) =>
      delete(db.stickerAlbums).delete(stickerAlbum);

  Selectable<StickerAlbum> systemAlbums() => db.systemAlbums();
}
