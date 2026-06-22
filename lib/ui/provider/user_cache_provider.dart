import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/dao/user_dao.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../utils/rivepod.dart';
import 'database_provider.dart';

class _UserCacheState extends DistinctStateNotifier<User?> {
  _UserCacheState(String userId, UserDao? userDao) : super(null) {
    if (userDao == null) return;

    Future<void> load() async {
      state = await userDao.userById(userId).getSingleOrNull();
    }

    unawaited(load());
    _subscription = DataBaseEventBus.instance
        .watchUpdateUserStream([userId])
        .listen((_) => unawaited(load()));
  }

  StreamSubscription<List<String>>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

final userCacheProvider = StateNotifierProvider.autoDispose
    .family<_UserCacheState, User?, String>(
      (ref, userId) => _UserCacheState(
        userId,
        ref.watch(databaseProvider.select((value) => value.value?.userDao)),
      ),
    );
