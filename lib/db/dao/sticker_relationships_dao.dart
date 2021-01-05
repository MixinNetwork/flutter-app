import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'sticker_relationships_dao.g.dart';

@UseDao(tables: [StickerRelationships])
class StickerRelationshipsDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  StickerRelationshipsDao(MixinDatabase db) : super(db);
}
