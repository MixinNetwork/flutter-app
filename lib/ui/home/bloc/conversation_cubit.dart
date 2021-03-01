import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/db/mixin_database.dart';

class ConversationCubit extends SimpleCubit<ConversationItem?> {
  ConversationCubit(
    this.accountServer,
  ) : super(null);
  final AccountServer accountServer;

  @override
  void emit(ConversationItem? state) {
    accountServer.selectConversation(state?.conversationId);
    super.emit(state);
  }
}
