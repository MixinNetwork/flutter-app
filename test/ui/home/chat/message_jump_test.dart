import 'package:flutter/material.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/ui/home/chat/message_jump.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('latest jump only uses loaded window when message state is latest', () {
    expect(
      shouldUseLoadedLatestWindowForLatestJump(MessageState(isLatest: true)),
      isTrue,
    );
    expect(
      shouldUseLoadedLatestWindowForLatestJump(MessageState()),
      isFalse,
    );
  });

  testWidgets('popChatSideRouteIfNeeded keeps non-route side pages open', (
    tester,
  ) async {
    final routeContextKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          key: routeContextKey,
          builder: (context) => const Text('side-page'),
        ),
      ),
    );

    routeContextKey.currentContext!.popChatSideRouteIfNeeded();
    await tester.pumpAndSettle();

    expect(find.text('side-page'), findsOneWidget);
  });

  testWidgets('popChatSideRouteIfNeeded pops route-mode side pages', (
    tester,
  ) async {
    final routeContextKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Builder(
                    key: routeContextKey,
                    builder: (_) => const Text('route-side-page'),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    routeContextKey.currentContext!.popChatSideRouteIfNeeded();
    await tester.pumpAndSettle();

    expect(find.text('route-side-page'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
