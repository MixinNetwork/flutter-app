import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../database_event_bus.dart';
import '../event.dart';
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

const _kCategoryPersonal = 'PERSONAL';
const _kCategorySystem = 'SYSTEM';

@DriftAccessor(include: {'../moor/dao/sticker.drift'})
class StickerDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerDaoMixin {
  StickerDao(super.db);

  Future<int> insert(StickersCompanion sticker) =>
      into(db.stickers).insertOnConflictUpdate(sticker).then((value) {
        DataBaseEventBus.instance.updateSticker([
          MiniSticker(
              stickerId: sticker.stickerId.value,
              albumId: sticker.albumId.value)
        ]);
        return value;
      });

  Future<void> insertSticker(Sticker sticker) =>
      into(db.stickers).insert(sticker, mode: InsertMode.insertOrIgnore);

  Future<void> insertAll(Iterable<StickersCompanion> stickers) =>
      batch((batch) => batch.insertAllOnConflictUpdate(db.stickers, stickers))
          .then((value) {
        DataBaseEventBus.instance.updateSticker(stickers.map((sticker) =>
            MiniSticker(
                stickerId: sticker.stickerId.value,
                albumId: sticker.albumId.value)));

        return value;
      });

  Future<void> deletePersonalSticker(String stickerId) async {
    final albumId = await (select(stickerAlbums)
          ..where((tbl) => tbl.category.equals(_kCategoryPersonal)))
        .map((row) => row.albumId)
        .getSingleOrNull();
    if (albumId == null) {
      return;
    }
    await (delete(db.stickerRelationships)
          ..where((tbl) =>
              tbl.stickerId.equals(stickerId) & tbl.albumId.equals(albumId)))
        .go();
    DataBaseEventBus.instance
        .updateSticker([MiniSticker(stickerId: stickerId, albumId: albumId)]);
  }

  SimpleSelectStatement<Stickers, Sticker> sticker(String stickerId) =>
      (select(db.stickers)
        ..where((tbl) => tbl.stickerId.equals(stickerId))
        ..limit(1));

  Selectable<Sticker> stickerByAlbumId(String albumId) => select(db.stickers)
    ..where((tbl) => tbl.albumId.equals(albumId))
    ..orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
    ]);

  Selectable<Sticker> personalStickers() =>
      _stickersByCategory(_kCategoryPersonal);

  Selectable<Sticker> systemStickers() => _stickersByCategory(_kCategorySystem);

  Future<int> updateUsedAt(
          String? albumId, String stickerId, DateTime dateTime) =>
      (update(db.stickers)..where((tbl) => tbl.stickerId.equals(stickerId)))
          .write(
        StickersCompanion(
          lastUseAt: Value(dateTime),
        ),
      )
          .then((value) {
        DataBaseEventBus.instance.updateSticker(
            [MiniSticker(stickerId: stickerId, albumId: albumId)]);
        return value;
      });

  Future<bool> hasSticker(String stickerId) async => db.hasData(
      db.stickers, const [], db.stickers.stickerId.equals(stickerId));

  Future<List<Sticker>> getStickers({
    required int limit,
    required int offset,
  }) =>
      (select(db.stickers)
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.rowId)])
            ..limit(limit, offset: offset))
          .get();
}
