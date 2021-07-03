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

  Future<Sticker?> getStickerByUnique(String stickerId) async =>
      customSelect('SELECT * FROM stickers WHERE sticker_id = :stickerId;',
              readsFrom: {
            db.stickers
          },
              variables: [
            Variable.withString(stickerId),
          ])
          .map((QueryRow row) => Sticker(
              stickerId: row.read<String>('sticker_id'),
              name: row.read<String>('name'),
              assetUrl: row.read<String>('asset_url'),
              assetType: row.read<String>('asset_type'),
              assetWidth: row.read<int>('asset_width'),
              assetHeight: row.read<int>('asset_height'),
              createdAt: row.read<DateTime>('last_use_at')))
          .getSingleOrNull();

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

  Future<Sticker> getStickerByAlbumIdAndName(String stickerId, String name) =>
      customSelect(
              'SELECT s.* FROM sticker_relationships sr, stickers s WHERE sr.sticker_id = s.sticker_id AND sr.album_id = :id AND s.name = :name;',
              readsFrom: {
            db.stickerRelationships,
            db.stickers
          },
              variables: [
            Variable.withString(stickerId),
            Variable.withString(name)
          ])
          .map((QueryRow row) => Sticker(
              stickerId: row.read<String>('sticker_id'),
              name: row.read<String>('name'),
              assetUrl: row.read<String>('asset_url'),
              assetType: row.read<String>('asset_type'),
              assetWidth: row.read<int>('asset_width'),
              assetHeight: row.read<int>('asset_height'),
              createdAt: row.read<DateTime>('last_use_at')))
          .getSingle();
}
