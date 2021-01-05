import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'jobs_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class JobsDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  JobsDao(MixinDatabase db) : super(db);
}
