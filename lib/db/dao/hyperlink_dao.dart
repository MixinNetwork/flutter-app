import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'hyperlink_dao.g.dart';

@DriftAccessor()
class HyperlinkDao extends DatabaseAccessor<MixinDatabase>
    with _$HyperlinkDaoMixin {
  HyperlinkDao(super.db);

  Future<int> insert(Hyperlink hyperlink) =>
      into(db.hyperlinks).insertOnConflictUpdate(hyperlink);

  Future deleteHyperlink(Hyperlink hyperlink) =>
      delete(db.hyperlinks).delete(hyperlink);
}
