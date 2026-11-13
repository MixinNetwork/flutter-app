import 'package:flutter/material.dart';
import 'package:flutter_app/ui/wallet/wallet_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _rows(List<String> items) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: AnimatedRows<String>(
      items: items,
      idOf: (item) => item,
      rowHeight: 10,
      itemBuilder: (context, item) => Text(item),
    ),
  ),
);

double _top(WidgetTester tester, String item) =>
    tester.getTopLeft(find.text(item)).dy;

void main() {
  test('formatChange floors to two decimals and shows only a minus sign', () {
    expect(formatChange('0.012345'), '1.23%');
    expect(formatChange('-0.012345'), '-1.23%');
    expect(formatChange('0.1'), '10%');
    expect(formatChange('-0.00001'), '0%');
    expect(formatChange(''), '0%');
  });

  testWidgets('the first rows show at once', (tester) async {
    await tester.pumpWidget(_rows(['a', 'b']));
    final opacity = tester.widget<FadeTransition>(
      find.ancestor(of: find.text('b'), matching: find.byType(FadeTransition)),
    );
    expect(opacity.opacity.value, 1);
    expect(_top(tester, 'b'), 10);
  });

  testWidgets('a removed row fades out while the rows below move up', (
    tester,
  ) async {
    await tester.pumpWidget(_rows(['a', 'b', 'c']));
    await tester.pumpAndSettle();
    expect(_top(tester, 'c'), 20);

    await tester.pumpWidget(_rows(['a', 'c']));
    await tester.pump(kWalletLeaveMotion ~/ 2);
    expect(find.text('b'), findsOneWidget);
    final midTop = _top(tester, 'c');
    expect(midTop, lessThan(20));
    expect(midTop, greaterThan(10));

    await tester.pumpAndSettle();
    expect(find.text('b'), findsNothing);
    expect(_top(tester, 'c'), 10);
    expect(tester.getSize(find.byType(AnimatedRows<String>)).height, 20);
  });

  testWidgets('a reorder moves each row, not a new copy', (tester) async {
    await tester.pumpWidget(_rows(['a', 'b']));
    await tester.pumpAndSettle();
    final state = tester.renderObject(
      find.ancestor(
        of: find.text('a'),
        matching: find.byType(FadeTransition),
      ),
    );

    await tester.pumpWidget(_rows(['b', 'a']));
    await tester.pump(kWalletMotion ~/ 2);
    expect(_top(tester, 'a'), inExclusiveRange(0, 10));
    await tester.pumpAndSettle();
    expect(_top(tester, 'a'), 10);
    expect(_top(tester, 'b'), 0);
    expect(
      tester.renderObject(
        find.ancestor(
          of: find.text('a'),
          matching: find.byType(FadeTransition),
        ),
      ),
      same(state),
    );
  });

  testWidgets('a row that comes back before it is gone stays', (tester) async {
    await tester.pumpWidget(_rows(['a', 'b']));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_rows(['a']));
    await tester.pump(kWalletLeaveMotion ~/ 2);
    await tester.pumpWidget(_rows(['a', 'b']));
    await tester.pumpAndSettle();
    expect(find.text('b'), findsOneWidget);
    expect(_top(tester, 'b'), 10);
  });
}
