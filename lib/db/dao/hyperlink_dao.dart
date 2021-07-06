import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'hyperlink_dao.g.dart';

@UseDao(tables: [Hyperlinks])
class HyperlinkDao extends DatabaseAccessor<MixinDatabase>
    with _$HyperlinkDaoMixin {
  HyperlinkDao(MixinDatabase db) : super(db);

  Future<int> insert(Hyperlink hyperlink) =>
      into(db.hyperlinks).insertOnConflictUpdate(hyperlink);

  Future deleteHyperlink(Hyperlink hyperlink) =>
      delete(db.hyperlinks).delete(hyperlink);
}
