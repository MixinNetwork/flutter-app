import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/database.dart';
import '../../db/fts_database.dart';
import '../../db/mixin_database.dart';
import '../../utils/synchronized.dart';
import '../home/bloc/slide_category_cubit.dart';
import 'multi_auth_provider.dart';

final databaseProvider =
    StateNotifierProvider.autoDispose<DatabaseOpener, AsyncValue<Database>>(
  (ref) {
    final identityNumber =
        ref.watch(authAccountProvider.select((value) => value?.identityNumber));
    return DatabaseOpener(identityNumber);
  },
);

extension _DatabaseExt on MixinDatabase {
  Future<void> doInitVerify() =>
      conversationDao.conversationCountByCategory(SlideCategoryType.chats);
}

class DatabaseOpener extends StateNotifier<AsyncValue<Database>> {
  DatabaseOpener(this.identityNumber) : super(const AsyncValue.loading()) {
    if (identityNumber != null) open();
  }

  final String? identityNumber;

  Database? _database;

  final Lock _lock = Lock();

  Future<void> open() => _lock.synchronized(() async {
        i('connect to database: $identityNumber');
        if (_database != null) {
          e('database already opened');
          return;
        }
        try {
          final mixinDatabase =
              await connectToDatabase(identityNumber!, fromMainIsolate: true);
          final db = Database(
            mixinDatabase,
            await FtsDatabase.connect(identityNumber!, fromMainIsolate: true),
          );
          _database = db;
          // Do a database query, to ensure database has properly initialized.
          await mixinDatabase.doInitVerify();
          state = AsyncValue.data(db);
        } catch (error, stacktrace) {
          e('failed to open database: $error, $stacktrace');
          state = AsyncValue.error(error, stacktrace);
        }
      });

  Future<void> close() async {
    if (_database != null) {
      await _database?.dispose();
      _database = null;
    }
    state = const AsyncValue.loading();
  }
}
