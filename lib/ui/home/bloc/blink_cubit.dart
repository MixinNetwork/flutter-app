import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../bloc/subscribe_mixin.dart';

class BlinkState extends Equatable {
  const BlinkState({this.color = Colors.transparent, this.messageId});

  final Color color;
  final String? messageId;

  @override
  List<Object?> get props => [color, messageId];

  BlinkState copyWith({Color? color, String? messageId}) => BlinkState(
    color: color ?? this.color,
    messageId: messageId ?? this.messageId,
  );
}

class BlinkCubit extends Cubit<BlinkState> with SubscribeMixin {
  BlinkCubit(this.tickerProvider, this.blinkColor) : super(const BlinkState()) {
    animationController
      ..addListener(_onUpdate)
      ..addStatusListener(_onComplete);
  }

  final TickerProvider tickerProvider;
  final Color blinkColor;

  late final AnimationController animationController = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: tickerProvider,
  );

  late final colorTween = ColorTween(
    begin: Colors.transparent,
    end: blinkColor,
  );

  void _onUpdate() {
    emit(state.copyWith(color: colorTween.evaluate(animationController)));
  }

  void _onComplete(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    animationController.reverse();
  }

  void blinkByMessageId(String messageId) {
    emit(BlinkState(messageId: messageId));
    animationController
      ..reset()
      ..forward();
  }

  @override
  Future<void> close() {
    animationController
      ..removeListener(_onUpdate)
      ..removeStatusListener(_onComplete);
    return super.close();
  }
}
