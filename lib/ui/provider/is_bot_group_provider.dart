import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/dao/conversation_dao.dart';
import '../../utils/rivepod.dart';
import 'database_provider.dart';

class _IsBotGroupState extends DistinctStateNotifier<bool> {
  _IsBotGroupState(String conversationId, ConversationDao? conversationDao)
    : super(false) {
    if (conversationDao == null) return;

    conversationDao
        .isBotGroup(conversationId)
        .getSingle()
        .then((value) => state = value);
  }
}

final isBotGroupProvider = StateNotifierProvider.autoDispose
    .family<_IsBotGroupState, bool, String>((ref, conversationId) {
      // Minimize frequent calls to isBotGroup by keeping it alive for 10 minutes
      final keepAlive = ref.keepAlive();
      ref.onDispose(
        () => Future.delayed(const Duration(minutes: 10), keepAlive.close),
      );

      return _IsBotGroupState(
        conversationId,
        ref.watch(
          databaseProvider.select((value) => value.value?.conversationDao),
        ),
      );
    });
