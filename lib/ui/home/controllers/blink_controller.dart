import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/brightness_theme_data.dart';
import '../../provider/ui_context_providers.dart';

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

final blinkColorProvider = Provider<Color>(
  (ref) {
    try {
      return ref
          .watch(brightnessThemeDataProvider)
          .accent
          .withValues(alpha: 0.5);
    } catch (_) {
      return lightBrightnessThemeData.accent.withValues(alpha: 0.5);
    }
  },
  dependencies: [brightnessThemeDataProvider],
);

final blinkControllerProvider =
    NotifierProvider.autoDispose<_BlinkNotifier, BlinkState>(
      _BlinkNotifier.new,
      dependencies: [blinkColorProvider],
    );

class _BlinkNotifier extends Notifier<BlinkState> {
  final StreamController<BlinkState> _streamController =
      StreamController<BlinkState>.broadcast();
  Timer? _timer;
  Color? _blinkColor;
  static const _blinkDuration = Duration(milliseconds: 1200);
  static const _tickInterval = Duration(milliseconds: 16);

  Stream<BlinkState> get stream => _streamController.stream;

  void _emit(BlinkState nextState) {
    if (state == nextState) return;
    state = nextState;
    if (!_streamController.isClosed) {
      _streamController.add(nextState);
    }
  }

  void _stopBlinking() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  BlinkState build() {
    ref.onDispose(() {
      _stopBlinking();
      unawaited(_streamController.close());
    });

    final blinkColor = ref.watch(blinkColorProvider);
    if (_blinkColor != blinkColor) {
      _blinkColor = blinkColor;
    }
    return stateOrNull ?? const BlinkState();
  }

  void blinkByMessageId(String messageId) {
    final blinkColor = _blinkColor ?? ref.read(blinkColorProvider);
    _stopBlinking();
    final startedAt = DateTime.now();

    void emitForProgress(double progress) {
      final normalized = progress.clamp(0.0, 1.0);
      final triangle = normalized <= 0.5
          ? normalized * 2
          : (1 - normalized) * 2;
      final eased = Curves.easeInOut.transform(triangle);
      _emit(
        BlinkState(
          messageId: messageId,
          color: Color.lerp(Colors.transparent, blinkColor, eased)!,
        ),
      );
    }

    emitForProgress(0);
    _timer = Timer.periodic(_tickInterval, (timer) {
      final elapsed = DateTime.now().difference(startedAt);
      final progress = elapsed.inMicroseconds / _blinkDuration.inMicroseconds;
      if (progress >= 1) {
        timer.cancel();
        _timer = null;
        _emit(const BlinkState());
        return;
      }
      emitForProgress(progress);
    });
  }
}
