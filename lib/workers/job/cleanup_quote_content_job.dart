import '../../constants/constants.dart';
import '../../db/mixin_database.dart';
import 'base_migration_job.dart';

class CleanupQuoteContentJob extends BaseMigrationJob {
  CleanupQuoteContentJob({required super.database})
      : super(action: kCleanupQuoteContent);

  @override
  Future<void> migration(Job job) async {
    throw Exception('not implemented');
  }
}
