import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/setting_cubit.dart';

extension MessageStyleExt on BuildContext {
  MessageStyle get messageStyle =>
      MessageStyle.defaultStyle + watch<SettingCubit>().state.chatFontSize;
}

class MessageStyle {
  const MessageStyle({
    required this.primaryFontSize,
    required this.secondaryFontSize,
    required this.tertiaryFontSize,
    required this.statusFontSize,
  });

  static const MessageStyle defaultStyle = MessageStyle(
    primaryFontSize: 16,
    secondaryFontSize: 14,
    tertiaryFontSize: 12,
    statusFontSize: 10,
  );

  final double primaryFontSize;
  final double secondaryFontSize;
  final double tertiaryFontSize;
  final double statusFontSize;

  MessageStyle operator *(double factor) => MessageStyle(
        primaryFontSize: primaryFontSize * factor,
        secondaryFontSize: secondaryFontSize * factor,
        tertiaryFontSize: tertiaryFontSize * factor,
        statusFontSize: statusFontSize * factor,
      );

  MessageStyle operator +(double delta) => MessageStyle(
        primaryFontSize: primaryFontSize + delta,
        secondaryFontSize: secondaryFontSize + delta,
        tertiaryFontSize: tertiaryFontSize + delta,
        statusFontSize: statusFontSize + delta,
      );
}

class MessageStyleCubit extends Cubit<MessageStyle> {
  MessageStyleCubit(SettingCubit setting)
      : super(MessageStyle.defaultStyle * setting.state.chatFontSize) {
    _subscription = setting.stream.listen((state) {
      emit(MessageStyle.defaultStyle * state.chatFontSize);
    });
  }

  StreamSubscription? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
