import 'dart:async';

import 'package:flutter_app/ui/home/controllers/blink_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('blink controller updates state without ticker scope', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(blinkControllerProvider.notifier);
    expect(container.read(blinkControllerProvider), const BlinkState());

    final completer = Completer<BlinkState>();
    final sub = notifier.stream.listen((state) {
      if (!completer.isCompleted && state.messageId == 'message-1') {
        completer.complete(state);
      }
    });
    addTearDown(sub.cancel);

    notifier.blinkByMessageId('message-1');

    final state = await completer.future.timeout(const Duration(seconds: 1));
    expect(state.messageId, 'message-1');
    expect(state.color.alpha, greaterThanOrEqualTo(0));
  });
}
