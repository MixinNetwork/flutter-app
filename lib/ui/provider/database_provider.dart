import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../crypto/crypto_key_value.dart';
import '../../db/app/app_database.dart';
import '../../db/database.dart';
import '../../db/fts_database.dart';
import '../../db/mixin_database.dart';
import '../../utils/rivepod.dart';
import '../../utils/synchronized.dart';
import 'account/multi_auth_provider.dart';
import 'hive_key_value_provider.dart';
import 'slide_category_provider.dart';

final appDatabaseProvider =
    Provider<AppDatabase>((ref) => throw UnimplementedError());

final databaseProvider =
    StateNotifierProvider.autoDispose<DatabaseOpener, AsyncValue<Database>>(
  (ref) {
    final identityNumber =
        ref.watch(authAccountProvider.select((value) => value?.identityNumber));

    if (identityNumber == null) return DatabaseOpener(ref);

    return DatabaseOpener.open(identityNumber, ref);
  },
);

extension _DatabaseExt on MixinDatabase {
  Future<void> doInitVerify() =>
      conversationDao.conversationCountByCategory(SlideCategoryType.chats);
}

class DatabaseOpener extends DistinctStateNotifier<AsyncValue<Database>> {
  DatabaseOpener(this.ref) : super(const AsyncValue.loading());

  DatabaseOpener.open(this.identityNumber, this.ref)
      : super(const AsyncValue.loading()) {
    open();
  }

  String? identityNumber;

  final Ref ref;

  final Lock _lock = Lock();

  Future<void> open() => _lock.synchronized(() async {
        final identityNumber = this.identityNumber!;
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
          try {
            await _onDatabaseOpenSucceed(db, identityNumber);
          } catch (error, stacktrace) {
            e('_onDatabaseOpenSucceed has error: $error, $stacktrace');
          }
          state = AsyncValue.data(db);
        } catch (error, stacktrace) {
          e('failed to open database: $error, $stacktrace');
          state = AsyncValue.error(error, stacktrace);
        }
      });

  Future<void> _onDatabaseOpenSucceed(
      Database database, String identityNumber) async {
    // migrate old crypto key value to new crypto key value
    try {
      final hive = ref.read(hiveProvider(identityNumber));
      final oldCryptoKeyValue = CryptoKeyValue();
      await oldCryptoKeyValue.migrateToNewCryptoKeyValue(
        hive,
        identityNumber,
        database.cryptoKeyValue,
      );
    } catch (error, stacktrace) {
      e('migrateToNewCryptoKeyValue has error: $error, $stacktrace');
    }
  }

  @override
  Future<void> dispose() async {
    await close();
    super.dispose();
  }

  Future<void> close() async {
    if (identityNumber != null) {
      i('close database: $identityNumber');
    }
    await state.valueOrNull?.dispose();
    state = const AsyncValue.loading();
  }
}
