import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'offsets_dao.g.dart';

@UseDao(tables: [Offsets])
class OffsetsDao extends DatabaseAccessor<MixinDatabase>
    with _$OffsetsDaoMixin {
  OffsetsDao(MixinDatabase db) : super(db);
}
