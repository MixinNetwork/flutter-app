import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/users_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:tuple/tuple.dart';

import 'conversation_cubit.dart';
import 'multi_auth_cubit.dart';

class _MentionBloc extends Bloc<String, Tuple2<String, List<User>>> {
  _MentionBloc({
    @required this.userDao,
    @required this.multiAuthCubit,
    @required this.conversationId,
  }) : super(const Tuple2(null, []));

  final UserDao userDao;
  final MultiAuthCubit multiAuthCubit;
  final String conversationId;

  @override
  Stream<Tuple2<String, List<User>>> mapEventToState(String keyword) async* {
    if (keyword == null)
      yield const Tuple2(null, []);
    else if (keyword.isEmpty)
      yield Tuple2(
        keyword,
        await userDao
            .groupParticipants(
              conversationId: conversationId,
              id: multiAuthCubit.currentUserId,
            )
            .get(),
      );
    else
      yield Tuple2(
        keyword,
        await userDao
            .fuzzySearchGroupUser(
              id: multiAuthCubit.currentUserId,
              conversationId: conversationId,
              username: keyword,
              identityNumber: keyword,
            )
            .get(),
      );
  }
}

class MentionCubit extends Cubit<Tuple2<String, List<User>>>
    with SubscribeMixin {
  MentionCubit({
    @required this.userDao,
    @required this.multiAuthCubit,
    @required ConversationCubit conversationCubit,
  }) : super(const Tuple2(null, [])) {
    renewMentionBloc(conversationCubit.state.conversationId);
    addSubscription(conversationCubit
        .map((event) => event.conversationId)
        .distinct()
        .listen(renewMentionBloc));
  }

  final UserDao userDao;
  final MultiAuthCubit multiAuthCubit;

  _MentionBloc mentionBloc;

  @override
  Future<void> close() async {
    await super.close();
    await mentionBloc?.close();
  }

  void renewMentionBloc(String conversationId) {
    if (conversationId == null) return;
    mentionBloc?.close();
    mentionBloc = _MentionBloc(
      multiAuthCubit: multiAuthCubit,
      userDao: userDao,
      conversationId: conversationId,
    );
    addSubscription(mentionBloc.listen(emit));
    emit(mentionBloc.state);
  }

  void add(String mention) => mentionBloc?.add(mention);

  void clear() => add(null);
}
