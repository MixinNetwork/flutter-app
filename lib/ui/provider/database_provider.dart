import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/database.dart';
import '../../db/fts_database.dart';
import '../../db/mixin_database.dart';
import '../../utils/rivepod.dart';
import '../../utils/synchronized.dart';
import 'account/multi_auth_provider.dart';
import 'slide_category_provider.dart';

final databaseProvider =
    StateNotifierProvider.autoDispose<DatabaseOpener, AsyncValue<Database>>(
  (ref) {
    final identityNumber =
        ref.watch(authAccountProvider.select((value) => value?.identityNumber));

    if (identityNumber == null) return DatabaseOpener();

    return DatabaseOpener.open(identityNumber);
  },
);

extension _DatabaseExt on MixinDatabase {
  Future<void> doInitVerify() =>
      conversationDao.conversationCountByCategory(SlideCategoryType.chats);
}

class DatabaseOpener extends DistinctStateNotifier<AsyncValue<Database>> {
  DatabaseOpener() : super(const AsyncValue.loading());

  DatabaseOpener.open(this.identityNumber) : super(const AsyncValue.loading()) {
    open();
  }

  late final String identityNumber;

  final Lock _lock = Lock();

  Future<void> open() => _lock.synchronized(() async {
        d('connect to database: $identityNumber');
        if (state.hasValue) {
          e('database already opened');
          return;
        }
        try {
          final mixinDatabase =
              await connectToDatabase(identityNumber, fromMainIsolate: true);
          final db = Database(
            mixinDatabase,
            await FtsDatabase.connect(identityNumber, fromMainIsolate: true),
          );
          // Do a database query, to ensure database has properly initialized.
          await mixinDatabase.doInitVerify();
          state = AsyncValue.data(db);
        } catch (error, stacktrace) {
          e('failed to open database: $error, $stacktrace');
          state = AsyncValue.error(error, stacktrace);
        }
      });

  @override
  Future<void> dispose() async {
    await close();
    super.dispose();
  }

  Future<void> close() async {
    await state.valueOrNull?.dispose();
    state = const AsyncValue.loading();
  }
}
