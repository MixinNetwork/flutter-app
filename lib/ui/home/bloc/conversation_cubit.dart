import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';

class ConversationCubit extends SimpleCubit<ConversationItemsResult> {
  ConversationCubit(this.draftCubit, [ConversationItemsResult conversation])
      : super(conversation);
  final DraftCubit draftCubit;

  @override
  void emit(ConversationItemsResult state) {
    draftCubit.update(this.state?.name);
    super.emit(state);
    if (state != null) draftCubit.show(state.name);
  }
}
