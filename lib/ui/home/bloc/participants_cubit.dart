import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../bloc/subscribe_mixin.dart';
import '../../../db/dao/user_dao.dart';
import '../../../db/mixin_database.dart';
import 'conversation_cubit.dart';

class ParticipantsCubit extends Cubit<List<User>> with SubscribeMixin {
  ParticipantsCubit({
    required UserDao userDao,
    required ConversationCubit conversationCubit,
  }) : super(const []) {
    StreamSubscription<List<User>>? streamSubscription;
    Future<void> resetConversationId(String? conversationId) async {
      if (conversationId?.isEmpty ?? true) return;

      await streamSubscription?.cancel();

      final selectable =
          userDao.groupParticipants(conversationId: conversationId!);
      emit(await selectable.get());
      final stream = selectable.watch();
      streamSubscription = stream.listen(emit);
      addSubscription(streamSubscription);
    }

    resetConversationId(conversationCubit.state?.conversationId);
    addSubscription(
      conversationCubit.stream
          .map((event) => event?.conversationId)
          .where((event) => event?.isNotEmpty == true)
          .distinct()
          .listen(resetConversationId),
    );
  }
}
