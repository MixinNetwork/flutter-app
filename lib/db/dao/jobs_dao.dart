import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'jobs_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class JobsDao extends DatabaseAccessor<MixinDatabase> with _$JobsDaoMixin {
  JobsDao(MixinDatabase db) : super(db);

  Future<int> insert(Job job) => into(db.jobs).insert(job);

  Future deleteJob(Job job) => delete(db.jobs).delete(job);
}
