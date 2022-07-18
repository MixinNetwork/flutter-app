import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';

part 'sticker_dao.g.dart';

extension StickerConverter on sdk.Sticker {
  StickersCompanion get asStickersCompanion => StickersCompanion(
        stickerId: Value(stickerId),
        albumId: Value(albumId),
        name: Value(name),
        assetUrl: Value(assetUrl),
        assetType: Value(assetType),
        assetWidth: Value(assetWidth),
        assetHeight: Value(assetHeight),
        createdAt: Value(createdAt),
      );
}

@DriftAccessor(tables: [Sticker])
class StickerDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerDaoMixin {
  StickerDao(super.db);

  Future<int> insert(StickersCompanion sticker) =>
      into(db.stickers).insertOnConflictUpdate(sticker);

  Future<void> insertAll(Iterable<StickersCompanion> stickers) =>
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
