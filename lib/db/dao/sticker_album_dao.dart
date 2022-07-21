import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';

part 'sticker_album_dao.g.dart';

extension StickerAlbumsCompanionExtension on sdk.StickerAlbum {
  StickerAlbumsCompanion get asStickerAlbumsCompanion =>
      StickerAlbumsCompanion.insert(
        albumId: albumId,
        name: name,
        iconUrl: iconUrl,
        updateAt: updateAt,
        userId: userId,
        category: category,
        description: description,
        createdAt: createdAt,
        banner: Value(banner),
        isVerified: Value(isVerified),
      );
}

@DriftAccessor(tables: [StickerAlbums])
class StickerAlbumDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerAlbumDaoMixin {
  StickerAlbumDao(super.db);

  Future<int> insert(StickerAlbumsCompanion stickerAlbum) =>
      into(db.stickerAlbums).insertOnConflictUpdate(stickerAlbum);

  Future<int> deleteStickerAlbum(StickerAlbum stickerAlbum) =>
      delete(db.stickerAlbums).delete(stickerAlbum);

  SimpleSelectStatement<StickerAlbums, StickerAlbum> systemAlbums() =>
      select(db.stickerAlbums)
        ..where((tbl) => tbl.category.equals('SYSTEM'))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

  SimpleSelectStatement<StickerAlbums, StickerAlbum> personalAlbum() =>
      select(db.stickerAlbums)
        ..where((tbl) => tbl.category.equals('PERSONAL'))
        ..limit(1);

  SimpleSelectStatement<StickerAlbums, StickerAlbum> systemAddedAlbums() =>
      select(db.stickerAlbums)
        ..where((tbl) => tbl.category.equals('SYSTEM') & tbl.added.equals(true))
        ..orderBy([
          (tbl) => OrderingTerm.asc(tbl.orderedAt),
          (tbl) => OrderingTerm.desc(tbl.createdAt),
        ]);

  SimpleSelectStatement<StickerAlbums, StickerAlbum> album(String albumId) =>
      select(db.stickerAlbums)
        ..where((tbl) => tbl.albumId.equals(albumId))
        ..limit(1);

  Future<int> updateAdded(String albumId, bool added) =>
      (update(db.stickerAlbums)..where((tbl) => tbl.albumId.equals(albumId)))
          .write(
        StickerAlbumsCompanion(
          added: Value(added),
          orderedAt: !added ? const Value(0) : const Value.absent(),
        ),
      );

  Future<void> updateOrders(List<StickerAlbum> value) {
    final newList = value.asMap().entries.map((e) {
      final index = e.key;
      final album = e.value;
      return album.copyWith(orderedAt: index);
    });
    return batch(
        (batch) => batch.insertAllOnConflictUpdate(db.stickerAlbums, newList));
  }

  Selectable<DateTime?> latestCreatedAt() => (selectOnly(db.stickerAlbums)
        ..addColumns([db.stickerAlbums.createdAt])
        ..orderBy([OrderingTerm.desc(db.stickerAlbums.createdAt)])
        ..limit(1))
      .map((row) => db.stickerAlbums.createdAt.converter
          .mapToDart(row.read(db.stickerAlbums.createdAt)));

  Selectable<int?> maxOrder() {
    final max = db.stickerAlbums.orderedAt.max();
    return (selectOnly(db.stickerAlbums)..addColumns([max]))
        .map((row) => row.read(max));
  }
}
