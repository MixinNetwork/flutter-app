import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../bloc/subscribe_mixin.dart';

class PinMessageState {
  PinMessageState({
    required this.messageIds,
    this.lastMessage,
  });

  final List<String> messageIds;
  final String? lastMessage;
}

extension PinMessageCubitExtension on BuildContext {
  List<String> get currentPinMessageIds =>
      read<PinMessageCubit>().state.messageIds;

  String? get lastMessage => read<PinMessageCubit>().state.lastMessage;
}

class PinMessageCubit extends Cubit<PinMessageState> with SubscribeMixin {
  PinMessageCubit()
      : super(PinMessageState(
          messageIds: [],
        ));
}
