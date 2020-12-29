import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';

class ConversationCubit extends SimpleCubit<Conversation> {
  ConversationCubit([Conversation conversation]) : super(conversation);
}
