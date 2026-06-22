import 'package:flutter/material.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('BlinkNotifier holds then fades the target highlight', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());

    final notifier = BlinkNotifier(tester);
    addTearDown(notifier.dispose);

    notifier.blinkByMessageId('message');
    await tester.pump();

    expect(notifier.value.messageId, 'message');
    expect(notifier.value.opacity, 1);

    await tester.pump(const Duration(milliseconds: 500));
    expect(notifier.value.messageId, 'message');
    expect(notifier.value.opacity, 1);

    await tester.pump(const Duration(milliseconds: 101));
    expect(notifier.value.messageId, 'message');
    expect(notifier.value.opacity, closeTo(0.5, 0.05));

    await tester.pump(const Duration(milliseconds: 100));
    expect(notifier.value.messageId, isNull);
    expect(notifier.value.opacity, 0);
  });

  testWidgets('nullable provider lookup finds BlinkNotifier', (tester) async {
    final notifier = BlinkNotifier(tester);
    addTearDown(notifier.dispose);
    BlinkNotifier? found;

    await tester.pumpWidget(
      ChangeNotifierProvider<BlinkNotifier>.value(
        value: notifier,
        child: Builder(
          builder: (context) {
            found = Provider.of<BlinkNotifier?>(context, listen: false);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(found, same(notifier));
  });
}
