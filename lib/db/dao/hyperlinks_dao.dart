import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'hyperlinks_dao.g.dart';

@UseDao(tables: [Hyperlinks])
class HyperlinksDao extends DatabaseAccessor<MixinDatabase>
    with _$HyperlinksDaoMixin {
  HyperlinksDao(MixinDatabase db) : super(db);

  Future<int> insert(Hyperlink hyperlink) =>
      into(db.hyperlinks).insertOnConflictUpdate(hyperlink);

  Future deleteHyperlink(Hyperlink hyperlink) =>
      delete(db.hyperlinks).delete(hyperlink);
}
