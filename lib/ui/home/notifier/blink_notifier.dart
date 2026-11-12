import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class BlinkState extends Equatable {
  const BlinkState({this.messageId, this.opacity = 0, this.token = 0});

  final String? messageId;
  final double opacity;
  final int token;

  @override
  List<Object?> get props => [messageId, opacity, token];
}

class BlinkNotifier extends ValueNotifier<BlinkState> {
  BlinkNotifier(TickerProvider tickerProvider)
    : _animationController = AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: tickerProvider,
      ),
      super(const BlinkState()) {
    _animationController
      ..addListener(_onUpdate)
      ..addStatusListener(_onComplete);
  }

  final AnimationController _animationController;
  int _token = 0;

  void _onUpdate() {
    final messageId = value.messageId;
    if (messageId == null) return;
    value = BlinkState(
      messageId: messageId,
      opacity: _opacityAt(_animationController.value),
      token: value.token,
    );
  }

  void _onComplete(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    value = BlinkState(token: _token);
  }

  void blinkByMessageId(String messageId) {
    _token++;
    value = BlinkState(messageId: messageId, opacity: 1, token: _token);
    _animationController
      ..reset()
      ..forward();
  }

  double _opacityAt(double value) {
    const hold = 5 / 7;
    if (value <= hold) return 1;
    return 1 - ((value - hold) / (1 - hold)).clamp(0.0, 1.0);
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
