import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';

class ConversationCubit extends SimpleCubit<ConversationItem> {
  ConversationCubit(
    this.draftCubit,
    this.accountServer,
  ) : super(null);
  final DraftCubit draftCubit;
  final AccountServer accountServer;

  @override
  void emit(ConversationItem state) {
    accountServer.selectConversation(state?.conversationId);
    draftCubit.update(this.state?.name);
    super.emit(state);
    if (state != null) draftCubit.show(state.name);
  }
}
