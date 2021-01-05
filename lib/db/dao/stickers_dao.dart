import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'stickers_dao.g.dart';

@UseDao(tables: [Sticker])
class StickerDao extends DatabaseAccessor<MixinDatabase>
    with _$StickerDaoMixin {
  StickerDao(MixinDatabase db) : super(db);
}
