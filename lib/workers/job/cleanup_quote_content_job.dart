import 'package:mixin_logger/mixin_logger.dart';

import '../../constants/constants.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import 'base_migration_job.dart';

const _kQueryMax = 100;

class CleanupQuoteContentJob extends BaseMigrationJob {
  CleanupQuoteContentJob({required super.database})
      : super(action: kCleanupQuoteContent);

  @override
  Future<void> migration(Job job) async {
    var rowId = -1;
    while (true) {
      final messages =
          await database.messageDao.bigQuoteMessage(rowId, _kQueryMax).get();
      for (final message in messages) {
        final quoteMessageId = message.quoteMessageId;
        if (quoteMessageId == null) {
          e('CleanupQuoteContentJob: quoteMessageId is null, message: ${message.rowid}');
          continue;
        }
        final quote = await database.messageDao.findMessageItemById(
          message.conversationId,
          quoteMessageId,
        );
        await database.messageDao.updateQuoteContentByQuoteId(
          message.conversationId,
          quoteMessageId,
          quote?.toJson(),
        );
      }
      if (messages.length < _kQueryMax) {
        break;
      }
      rowId = messages.last.rowid;
    }
  }
}
