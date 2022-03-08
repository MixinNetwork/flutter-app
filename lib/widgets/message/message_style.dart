import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../account/account_key_value.dart';

class MessageStyle with EquatableMixin {
  MessageStyle({
    required this.showAvatar,
  });

  final bool showAvatar;

  @override
  List<Object?> get props => [showAvatar];

  MessageStyle copyWith({
    bool? showAvatar,
  }) =>
      MessageStyle(
        showAvatar: showAvatar ?? this.showAvatar,
      );
}

class MessageStyleCubit extends Cubit<MessageStyle> {
  MessageStyleCubit(MessageStyle initialState) : super(initialState);

  factory MessageStyleCubit.fromAccountKeyValue() => MessageStyleCubit(
        MessageStyle(
          showAvatar: AccountKeyValue.instance.messageShowAvatar,
        ),
      );

  void showAvatar(bool showAvatar) {
    AccountKeyValue.instance.messageShowAvatar = showAvatar;
    emit(state.copyWith(showAvatar: showAvatar));
  }
}
