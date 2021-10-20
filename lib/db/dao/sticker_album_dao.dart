import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'sticker_album_dao.g.dart';

@DriftAccessor(tables: [StickerAlbums])
class StickerAlbumDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerAlbumDaoMixin {
  StickerAlbumDao(MixinDatabase db) : super(db);

  Future<int> insert(StickerAlbum stickerAlbum) =>
      into(db.stickerAlbums).insertOnConflictUpdate(stickerAlbum);

  Future<int> deleteStickerAlbum(StickerAlbum stickerAlbum) =>
      delete(db.stickerAlbums).delete(stickerAlbum);

  Selectable<StickerAlbum> systemAlbums() => db.systemAlbums();
}
