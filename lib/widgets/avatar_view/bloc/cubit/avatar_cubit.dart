import 'package:bloc/bloc.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/participants_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';

class AvatarCubit extends Cubit<List<User>> with SubscribeMixin {
  AvatarCubit(
    ParticipantsDao participantsDao,
    String conversationId,
  ) : super(const []) {
    final selectable =
        participantsDao.participantsAvatar(conversationId);

    selectable.get().then(emit);
    addSubscription(selectable.watch().listen(emit));
  }
}
