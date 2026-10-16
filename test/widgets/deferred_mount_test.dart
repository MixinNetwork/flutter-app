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

  testWidgets('children that must not wait appear in the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      Column(
        children: [
          for (var i = 0; i < 20; i++)
            DeferredMount(defer: false, child: _Slow(i)),
        ],
      ),
    );
    expect(shown().length, 20);
  });

  testWidgets('later frames keep the budget when children cost more', (
    tester,
  ) async {
    // The first children are cheap, as rows with recently laid out text are.
    await tester.pumpWidget(
      list((i) => _Slow(i, micros: i < 10 ? 100 : 2000)),
    );
    // Cheap children may still fill in on a loaded machine; the costly ones
    // must not exceed the budget.
    int costly() => shown().where((i) => i >= 10).length;
    while (shown().length < 20) {
      final before = costly();
      await tester.pump();
      expect(costly() - before, lessThanOrEqualTo(2));
    }
  });

  testWidgets('a long queue rebuilds only its head in a frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (var i = 0; i < 200; i++)
                DeferredMount(
                  placeholder: const SizedBox(height: 10),
                  child: _Slow(i),
                ),
            ],
          ),
        ),
      ),
    );
    expect(shown().length, lessThan(20));

    var retried = 0;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (element.widget is DeferredMount) retried++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    await tester.pump();
    debugOnRebuildDirtyWidget = null;

    expect(retried, lessThan(50));
  });

  testWidgets('a waiting child that must not wait any more frees its place', (
    tester,
  ) async {
    Widget rows(Set<int> shownBefore) => Column(
      children: [
        for (var i = 0; i < 20; i++)
          DeferredMount(
            key: ValueKey(i),
            // A list shows a child it showed before without waiting.
            defer: !shownBefore.contains(i),
            placeholder: const SizedBox(height: 10),
            child: _Slow(i),
          ),
      ],
    );

    await tester.pumpWidget(rows({}));
    final first = shown();
    expect(first.length, lessThan(20));

    // The head of the queue stops waiting before its retry, as the shared
    // media list does when it rebuilds its cached items.
    final head = {for (var i = first.length; i < first.length + 8; i++) i};
    await tester.pumpWidget(rows(head));

    for (var frame = 0; frame < 40 && shown().length < 20; frame++) {
      await tester.pump();
    }
    expect(shown().length, 20, reason: 'the rest of the queue shows');
  });
}
