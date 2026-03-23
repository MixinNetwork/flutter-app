import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/mixin_database.dart';
import 'database_provider.dart';

class _UserCacheState extends Notifier<User?> {
  _UserCacheState(this.userId);

  final String userId;

  @override
  User? build() {
    // Minimize frequent calls to userById by keeping it alive for 10 minutes.
    final keepAlive = ref.keepAlive();
    ref.onDispose(
      () => Future.delayed(const Duration(minutes: 10), keepAlive.close),
    );

    final userDao = ref.watch(
      databaseProvider.select((value) => value.value?.userDao),
    );
    if (userDao != null) {
      Future<void>(() async {
        state = await userDao.userById(userId).getSingle();
      });
    }
    return null;
  }
}

final userCacheProvider = NotifierProvider.autoDispose
    .family<_UserCacheState, User?, String>(
      _UserCacheState.new,
    );
