import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/deferred_mount.dart';
import 'package:flutter_test/flutter_test.dart';

class _Slow extends StatelessWidget {
  const _Slow(this.index, {this.micros = 1000});

  final int index;
  final int micros;

  @override
  Widget build(BuildContext context) {
    final watch = Stopwatch()..start();
    while (watch.elapsedMicroseconds < micros) {}
    return Text('$index', textDirection: TextDirection.ltr);
  }
}

void main() {
  Widget list(Widget Function(int index) child) => Column(
    children: [
      for (var i = 0; i < 20; i++)
        DeferredMount(
          placeholder: const SizedBox(height: 10),
          child: child(i),
        ),
    ],
  );

  List<int> shown() => [
    for (var i = 0; i < 20; i++)
      if (find.text('$i').evaluate().isNotEmpty) i,
  ];

  testWidgets('costly children appear over frames in mount order', (
    tester,
  ) async {
    await tester.pumpWidget(list(_Slow.new));
    final first = shown();
    expect(first, isNotEmpty);
    expect(first.length, lessThan(20));
    expect(first, List.generate(first.length, (i) => i));

    var frames = 1;
    while (shown().length < 20) {
      final before = shown().length;
      await tester.pump();
      frames++;
      expect(shown(), List.generate(shown().length, (i) => i));
      expect(shown().length, greaterThan(before));
    }
    expect(frames, greaterThan(1));
  });

  testWidgets('cheap children appear in the first frame', (tester) async {
    await tester.pumpWidget(
      list((i) => SizedBox(key: ValueKey(i), height: 10)),
    );
    for (var i = 0; i < 20; i++) {
      expect(find.byKey(ValueKey(i)), findsOneWidget);
    }
  });

  testWidgets('later frames keep the budget when children cost more', (
    tester,
  ) async {
    // The first children are cheap, as rows with recently laid out text are.
    await tester.pumpWidget(
      list((i) => _Slow(i, micros: i < 10 ? 100 : 2000)),
    );
    while (shown().length < 20) {
      final before = shown().length;
      await tester.pump();
      expect(shown().length - before, lessThanOrEqualTo(2));
    }
  });
}
