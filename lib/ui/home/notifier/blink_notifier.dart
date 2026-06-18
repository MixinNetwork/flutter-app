import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

class BlinkNotifier extends ValueNotifier<BlinkState> {
  BlinkNotifier(TickerProvider tickerProvider, Color blinkColor)
    : _animationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: tickerProvider,
      ),
      _colorTween = ColorTween(begin: Colors.transparent, end: blinkColor),
      super(const BlinkState()) {
    _animationController
      ..addListener(_onUpdate)
      ..addStatusListener(_onComplete);
  }

  final AnimationController _animationController;
  final ColorTween _colorTween;

  void _onUpdate() {
    value = value.copyWith(color: _colorTween.evaluate(_animationController));
  }

  void _onComplete(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _animationController.reverse();
  }

  void blinkByMessageId(String messageId) {
    value = BlinkState(messageId: messageId);
    _animationController
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _animationController
      ..removeListener(_onUpdate)
      ..removeStatusListener(_onComplete)
      ..dispose();
    super.dispose();
  }
}
