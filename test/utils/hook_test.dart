import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

class _StreamProbe extends HookWidget {
  const _StreamProbe({required this.query, required this.stream});

  final String query;
  final Stream<String> stream;

  @override
  Widget build(BuildContext context) {
    final snapshot = useMemoizedStream(
      () => stream,
      initialData: 'empty',
      keys: [query],
      preserveState: false,
    );
    return Text(snapshot.data ?? 'loading');
  }
}

class _FutureProbe extends HookWidget {
  const _FutureProbe({required this.query, required this.future});

  final String query;
  final Future<String> future;

  @override
  Widget build(BuildContext context) {
    final snapshot = useMemoizedFuture(
      () => future,
      'empty',
      keys: [query],
      preserveState: false,
    );
    return Text(snapshot.data ?? 'loading');
  }
}

class _Converted extends HookWidget {
  const _Converted({required this.notifier, required this.suffix});

  final ValueNotifier<String> notifier;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final value = useListenableConverter<ValueNotifier<String>, String>(
      notifier,
      converter: (notifier) => '${notifier.value}$suffix',
      keys: [suffix],
    ).data;
    return Text('$value', textDirection: TextDirection.ltr);
  }
}

void main() {
  testWidgets('clears a stale stream result when its key changes', (
    tester,
  ) async {
    final oldStream = StreamController<String>.broadcast();
    final currentStream = StreamController<String>.broadcast();
    addTearDown(oldStream.close);
    addTearDown(currentStream.close);

    await tester.pumpWidget(
      MaterialApp(
        home: _StreamProbe(query: 'old', stream: oldStream.stream),
      ),
    );
    oldStream.add('old result');
    await tester.pump();
    expect(find.text('old result'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: _StreamProbe(query: 'current', stream: currentStream.stream),
      ),
    );
    await tester.pump();
    expect(find.text('empty'), findsOneWidget);

    await tester.pump();
    expect(currentStream.hasListener, isTrue);
    currentStream.add('current result');
    await tester.pump();
    await tester.pump();
    expect(find.text('current result'), findsOneWidget);
  });

  testWidgets('clears a stale future result when its key changes', (
    tester,
  ) async {
    final oldFuture = Completer<String>();
    final currentFuture = Completer<String>();

    await tester.pumpWidget(
      MaterialApp(
        home: _FutureProbe(query: 'old', future: oldFuture.future),
      ),
    );
    oldFuture.complete('old result');
    await tester.pump();
    expect(find.text('old result'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: _FutureProbe(query: 'current', future: currentFuture.future),
      ),
    );
    await tester.pump();
    expect(find.text('empty'), findsOneWidget);

    currentFuture.complete('current result');
    await tester.pump();
    await tester.pump();
    expect(find.text('current result'), findsOneWidget);
  });

  testWidgets('a new key converts again without a notification', (
    tester,
  ) async {
    final notifier = ValueNotifier('a');
    addTearDown(notifier.dispose);

    await tester.pumpWidget(_Converted(notifier: notifier, suffix: '1'));
    expect(find.text('a1'), findsOneWidget);

    // An input of the converter changes, such as a mention that resolves to
    // a name, while the notifier stays the same.
    await tester.pumpWidget(_Converted(notifier: notifier, suffix: '2'));
    await tester.pump();
    expect(find.text('a2'), findsOneWidget);

    // The stream delivers the notification after this frame.
    notifier.value = 'b';
    await tester.pump();
    await tester.pump();
    expect(find.text('b2'), findsOneWidget);
  });
}
