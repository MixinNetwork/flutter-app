import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'stickers_dao.g.dart';

@UseDao(tables: [Sticker])
class StickerDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerDaoMixin {
  StickerDao(MixinDatabase db) : super(db);

  Future<int> insert(Sticker sticker) => into(db.stickers).insert(sticker);

  Future deleteSticker(Sticker sticker) => delete(db.stickers).delete(sticker);
}
