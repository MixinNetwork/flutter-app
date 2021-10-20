import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'sticker_relationship_dao.g.dart';

@DriftAccessor(tables: [StickerRelationships])
class StickerRelationshipDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerRelationshipDaoMixin {
  StickerRelationshipDao(MixinDatabase db) : super(db);

  Future<int> insert(StickerRelationship stickerRelationship) =>
      into(db.stickerRelationships).insertOnConflictUpdate(stickerRelationship);

  Future deleteStickerRelationship(StickerRelationship stickerRelationship) =>
      delete(db.stickerRelationships).delete(stickerRelationship);

  Future<void> insertAll(List<StickerRelationship> stickerRelationships) =>
      batch((batch) {
        batch.insertAllOnConflictUpdate(
            db.stickerRelationships, stickerRelationships);
      });
}
