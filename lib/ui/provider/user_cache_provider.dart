import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/dao/user_dao.dart';
import '../../db/mixin_database.dart';
import '../../utils/rivepod.dart';
import 'database_provider.dart';

class _UserCacheState extends DistinctStateNotifier<User?> {
  _UserCacheState(String userId, UserDao? userDao) : super(null) {
    if (userDao == null) return;

    userDao.userById(userId).getSingle().then((value) => state = value);
  }
}

//  !!! Only query once in 10 minutes !!!
final userCacheProvider = StateNotifierProvider.autoDispose.family<
  _UserCacheState,
  User?,
  String
>((ref, userId) {
  // Minimize frequent calls to isBotGroup by keeping it alive for 10 minutes
  final keepAlive = ref.keepAlive();
  ref.onDispose(
    () => Future.delayed(const Duration(minutes: 10), keepAlive.close),
  );

  return _UserCacheState(
    userId,
    ref.watch(databaseProvider.select((value) => value.value?.userDao)),
  );
});
