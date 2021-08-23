import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'sticker_dao.g.dart';

@UseDao(tables: [Sticker])
class StickerDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerDaoMixin {
  StickerDao(MixinDatabase db) : super(db);

  Future<int> insert(Sticker sticker) =>
      into(db.stickers).insertOnConflictUpdate(sticker);

  Future<int> deleteSticker(Sticker sticker) =>
      delete(db.stickers).delete(sticker);

  Selectable<Sticker> recentUsedStickers() => db.recentUsedStickers();

  SimpleSelectStatement<Stickers, Sticker> getStickerByUnique(
          String stickerId) =>
      (select(db.stickers)
        ..where((tbl) => tbl.stickerId.equals(stickerId))
        ..limit(1));

  Selectable<Sticker> stickerByAlbumId(String albumId) => select(db.stickers)
    ..where((tbl) => tbl.albumId.equals(albumId))
    ..orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
    ]);

  Selectable<Sticker> personalStickers() => db.personalStickers();

  Future<int> updateUsedAt(String stickerId, DateTime dateTime) =>
      (update(db.stickers)..where((tbl) => tbl.stickerId.equals(stickerId)))
          .write(
        StickersCompanion(
          lastUseAt: Value(dateTime),
        ),
      );

  Future<bool> hasSticker(String stickerId) async => db.hasData(
      db.stickers, const [], db.stickers.stickerId.equals(stickerId));
}
