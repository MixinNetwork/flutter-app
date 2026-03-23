import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/dao/conversation_dao.dart';
import 'database_provider.dart';

class _IsBotGroupNotifier extends Notifier<bool> {
  _IsBotGroupNotifier(this.conversationId);

  final String conversationId;

  ConversationDao? get _conversationDao => ref.watch(
    databaseProvider.select((value) => value.value?.conversationDao),
  );

  @override
  bool build() {
    final keepAlive = ref.keepAlive();
    ref.onDispose(
      () => Future.delayed(const Duration(minutes: 10), keepAlive.close),
    );

    final conversationDao = _conversationDao;
    if (conversationDao != null) {
      Future<void>(() async {
        state = await conversationDao.isBotGroup(conversationId).getSingle();
      });
    }
    return false;
  }
}

final isBotGroupProvider = NotifierProvider.autoDispose
    .family<_IsBotGroupNotifier, bool, String>(
      _IsBotGroupNotifier.new,
    );
