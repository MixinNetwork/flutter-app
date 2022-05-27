import 'dart:async';

import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test drop', () async {
    const count = 64;
    const delayedMilliseconds = 10;

    final streamController = StreamController<int>();
    for (var i = 0; i < count; i++) {
      streamController.add(i);
    }

    final callTimes = <int>[];
    streamController.stream.asyncDropListen((event) async {
      callTimes.add(event);
      await Future.delayed(const Duration(milliseconds: delayedMilliseconds));
    });

    await Future.delayed(
        const Duration(milliseconds: count * delayedMilliseconds * 2));

    expect(callTimes.length, inInclusiveRange(1, 4));
  });
}
