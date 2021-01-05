import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'hyperlinks_dao.g.dart';

@UseDao(tables: [Hyperlinks])
class HyperlinksDao extends DatabaseAccessor<MixinDatabase>
    with _$HyperlinksDaoMixin {
  HyperlinksDao(MixinDatabase db) : super(db);

  Future<int> insert(Hyperlink hyperlink) =>
      into(db.hyperlinks).insert(hyperlink);

  Future deleteHyperlink(Hyperlink hyperlink) =>
      delete(db.hyperlinks).delete(hyperlink);
}
