import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'sticker_dao.g.dart';

@DriftAccessor(tables: [Sticker])
class StickerDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerDaoMixin {
  StickerDao(MixinDatabase db) : super(db);

  Future<int> insert(Sticker sticker) =>
      into(db.stickers).insertOnConflictUpdate(sticker);

  Future<void> insertAll(List<Sticker> stickers) =>
      batch((batch) => batch.insertAllOnConflictUpdate(db.stickers, stickers));

  Future<int> deleteSticker(Sticker sticker) =>
      delete(db.stickers).delete(sticker);

  Selectable<Sticker> recentUsedStickers() => db.recentUsedStickers();

  SimpleSelectStatement<Stickers, Sticker> sticker(String stickerId) =>
      (select(db.stickers)
        ..where((tbl) => tbl.stickerId.equals(stickerId))
        ..limit(1));

  Selectable<Sticker> stickerByAlbumId(String albumId) => select(db.stickers)
    ..where((tbl) => tbl.albumId.equals(albumId))
    ..orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
    ]);

  Selectable<Sticker> personalStickers() => db.stickersByCategory('PERSONAL');

  Selectable<Sticker> systemStickers() => db.stickersByCategory('SYSTEM');

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
