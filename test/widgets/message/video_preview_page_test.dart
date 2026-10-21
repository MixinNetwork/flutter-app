import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/message/item/video/video_preview_page.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pauses when the window is hidden and stays paused', (
    tester,
  ) async {
    final calls = <String>[];

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          usePauseWhenWindowHidden(() => calls.add('pause'));
          return const SizedBox();
        },
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(calls, isEmpty, reason: 'unfocused window keeps playing');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(calls, ['pause']);

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, ['pause']);
  });
}
