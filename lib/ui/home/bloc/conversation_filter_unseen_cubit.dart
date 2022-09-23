import 'package:bloc/bloc.dart';

class ConversationFilterUnseenCubit extends Cubit<bool> {
  ConversationFilterUnseenCubit() : super(false);

  void toggle() => emit(!state);

  void reset() => emit(false);
}
