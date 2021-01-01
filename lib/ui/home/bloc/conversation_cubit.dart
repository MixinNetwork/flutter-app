import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';

class ConversationCubit extends SimpleCubit<Conversation> {
  ConversationCubit(this.draftCubit, [Conversation conversation])
      : super(conversation);
  final DraftCubit draftCubit;

  @override
  void emit(Conversation state) {
    draftCubit.update(this.state?.name);
    super.emit(state);
    if (state != null) draftCubit.show(state.name);
  }
}
