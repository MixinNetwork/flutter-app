import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/message/message_day_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('date traversal skips non-message sliver children', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SizedBox(
            height: 200,
            child: MessageDayTimeViewportWidget.chatPage(
              entries: const [],
              scrollController: scrollController,
              child: CustomScrollView(
                controller: scrollController,
                slivers: const [
                  SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
