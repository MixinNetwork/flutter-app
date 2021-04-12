import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/users_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';

import 'conversation_cubit.dart';

class ParticipantsCubit extends Cubit<List<User>> with SubscribeMixin {
  ParticipantsCubit({
    required UserDao userDao,
    required ConversationCubit conversationCubit,
    required String userId,
  }) : super(const []) {
    StreamSubscription<List<User>>? streamSubscription;
    final resetConversationId = (String? conversationId) async {
      if (conversationId?.isEmpty ?? true) return;

      await streamSubscription?.cancel();

      final selectable = userDao.groupParticipants(
          conversationId: conversationId!, id: userId);
      emit(await selectable.get());
      final stream = selectable.watch();
      streamSubscription = stream.listen(emit);
      addSubscription(streamSubscription);
    };
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
