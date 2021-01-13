import 'package:bloc/bloc.dart';
import 'package:flutter_app/acount/account_server.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';

class ConversationListCubit extends Cubit<List<ConversationItemsResult>>
    with SubscribeMixin {
  ConversationListCubit(
    // todo
    // ignore: avoid_unused_constructor_parameters
    SlideCategoryCubit slideCategoryCubit,
    AccountServer accountServer,
  ) : super(const []) {
    // switchConversationList(slideCategoryCubit.state);
    // addSubscription(slideCategoryCubit.listen(switchConversationList));
    addSubscription(
        accountServer.database.conversationDao.conversationList().listen(emit));
  }
}
