import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/database.dart';
import '../../db/fts_database.dart';
import '../../db/mixin_database.dart';
import '../../utils/synchronized.dart';
import 'multi_auth_provider.dart';
import 'slide_category_provider.dart';

final databaseProvider =
    NotifierProvider.autoDispose<DatabaseOpener, AsyncValue<Database>>(
      DatabaseOpener.new,
    );

extension _DatabaseExt on MixinDatabase {
  Future<void> doInitVerify() =>
      conversationDao.conversationCountByCategory(SlideCategoryType.chats);
}

class DatabaseOpener extends Notifier<AsyncValue<Database>> {
  String? _identityNumber;

  final Lock _lock = Lock();

  @override
  AsyncValue<Database> build() {
    ref.keepAlive();

    final identityNumber = ref.watch(
      authAccountProvider.select((value) => value?.identityNumber),
    );

    ref.onDispose(() {
      unawaited(_disposeAsync());
    });

    Future<void>(() => _syncIdentity(identityNumber));

    return stateOrNull ?? const AsyncValue.loading();
  }

  Future<void> _syncIdentity(String? identityNumber) async {
    if (_identityNumber == identityNumber) return;

    if (_identityNumber != null || stateOrNull?.hasValue == true) {
      await close();
    }

    _identityNumber = identityNumber;
    if (identityNumber == null) {
      state = const AsyncValue.loading();
      return;
    }

    await open();
  }

  Future<void> open() => _lock.synchronized(() async {
    final identityNumber = _identityNumber;
    if (identityNumber == null) {
      state = const AsyncValue.loading();
      return;
    }

    i('connect to database: $identityNumber');
    if (state.hasValue) {
      e('database already opened');
      return;
    }
    try {
      final mixinDatabase = await connectToDatabase(
        identityNumber,
        fromMainIsolate: true,
      );
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

  Future<void> _disposeAsync() async {
    _identityNumber = null;
    // Only dispose the database resource, don't modify state
    // since this is called from onDispose where state modification is forbidden.
    await state.value?.dispose();
  }

  Future<void> close() async {
    await state.value?.dispose();
    state = const AsyncValue.loading();
  }
}
