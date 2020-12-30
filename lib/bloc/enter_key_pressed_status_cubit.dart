import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';

class EnterKeyPressedStatusCubit extends Cubit<bool> with SubscribeMixin {
  EnterKeyPressedStatusCubit() : super(null) {
    RawKeyboard.instance.addListener(handleKey);
  }

  void handleKey(RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if(event is RawKeyDownEvent) {
        emit(true);
      }else if(event is RawKeyUpEvent) {
        emit(false);
      }
    }
  }

  @override
  Future<void> close() {
    RawKeyboard.instance.removeListener(handleKey);
    return super.close();
  }
}
