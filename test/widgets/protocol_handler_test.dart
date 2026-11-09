import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/auth.dart' show appLocked;
import 'package:flutter_app/widgets/protocol_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final calls = <(String, bool)>[];
  Future<bool> open(
    BuildContext context,
    String url, {
    required bool confirmSend,
  }) async {
    calls.add((url, confirmSend));
    return true;
  }

  setUp(calls.clear);
  tearDown(() => appLocked.value = false);

  testWidgets('an external link sends only after a confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    const url = 'mixin://send?user=x&category=text&data=aGk';

    expect(await openExternalUri(context, url, open: open), isTrue);
    expect(calls, [(url, true)]);
  });

  testWidgets('an external link does nothing while the app is locked', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    appLocked.value = true;

    expect(
      await openExternalUri(context, 'mixin://send', open: open),
      isFalse,
    );
    expect(calls, isEmpty);
  });
}
