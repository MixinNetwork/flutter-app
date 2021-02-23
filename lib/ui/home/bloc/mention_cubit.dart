import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/users_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/participants_cubit.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import 'multi_auth_cubit.dart';

class MentionCubit extends Cubit<Tuple2<String, List<User>>>
    with SubscribeMixin {
  MentionCubit({
    @required this.userDao,
    @required this.multiAuthCubit,
    @required this.participantsCubit,
  }) : super(const Tuple2(null, [])) {
    addSubscription(
      Rx.combineLatest2<String, List<User>, Tuple2<String, List<User>>>(
        streamController.stream,
        participantsCubit,
        (a, b) => Tuple2(
          a,
          a != null
              ? participantsCubit.state
                  .where(
                    (user) =>
                        user.fullName.contains(a) ||
                        user.identityNumber.contains(a),
                  )
                  .toList()
              : [],
        ),
      ).listen(emit),
    );
  }

  final UserDao userDao;
  final MultiAuthCubit multiAuthCubit;
  final ParticipantsCubit participantsCubit;
  final StreamController streamController = StreamController<String>();

  @override
  Future<void> close() async {
    await streamController.close();
    await super.close();
  }

  void add(String keyword) => streamController.add(keyword);
}
