import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'offsets_dao.g.dart';

@UseDao(tables: [Offsets])
class OffsetsDao extends DatabaseAccessor<MixinDatabase>
    with _$OffsetsDaoMixin {
  OffsetsDao(MixinDatabase db) : super(db);

  Future<int> insert(Offset offset) =>
      into(db.offsets).insertOnConflictUpdate(offset);

  Future deleteOffset(Offset offset) => delete(db.offsets).delete(offset);
}
