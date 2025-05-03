import 'package:drift/drift.dart';

import '../database_event_bus.dart';
import '../event.dart';
import '../mixin_database.dart';

part 'sticker_relationship_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/sticker_relationship.drift'})
class StickerRelationshipDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerRelationshipDaoMixin {
  StickerRelationshipDao(super.db);

  Future<int> insert(StickerRelationship stickerRelationship) => into(
    db.stickerRelationships,
  ).insertOnConflictUpdate(stickerRelationship).then((value) {
    DataBaseEventBus.instance.updateSticker([
      MiniSticker(
        stickerId: stickerRelationship.stickerId,
        albumId: stickerRelationship.albumId,
      ),
    ]);
    return value;
  });

  Future deleteStickerRelationship(StickerRelationship stickerRelationship) =>
      delete(db.stickerRelationships).delete(stickerRelationship).then((value) {
        DataBaseEventBus.instance.updateSticker([
          MiniSticker(
            stickerId: stickerRelationship.stickerId,
            albumId: stickerRelationship.albumId,
          ),
        ]);
        return value;
      });

  Future<void> insertAll(List<StickerRelationship> stickerRelationships) =>
      batch((batch) {
        batch.insertAllOnConflictUpdate(
          db.stickerRelationships,
          stickerRelationships,
        );
      }).then((value) {
        DataBaseEventBus.instance.updateSticker(
          stickerRelationships.map(
            (stickerRelationship) => MiniSticker(
              stickerId: stickerRelationship.stickerId,
              albumId: stickerRelationship.albumId,
            ),
          ),
        );
        return value;
      });
}
