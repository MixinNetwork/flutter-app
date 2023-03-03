import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(EventBus.initialize);
  test('send event in main isolate', () async {
    final events = <String>[];
    EventBus.instance.on.listen((event) {
      if (event is String) {
        events.add(event);
      }
    });
    EventBus.instance.fire('a');
    EventBus.instance.fire('b');
    EventBus.instance.fire('c');

    await Future.delayed(const Duration(milliseconds: 100));
    expect(events, ['a', 'b', 'c']);
  });

  test('send event from other isolate', () async {
    final events = <String>[];
    EventBus.instance.on.listen((event) {
      if (event is String) {
        events.add(event);
      }
    });

    await Isolate.spawn((message) {
      EventBus.instance.fire('a');
      EventBus.instance.fire('b');
      EventBus.instance.fire('c');
    }, null);

    await Future.delayed(const Duration(milliseconds: 100));
    expect(events, ['a', 'b', 'c']);
  });

  test('send event to other isolate', () async {
    final events = compute((message) async {
      final events = <String>[];
      EventBus.instance.on.listen((event) {
        if (event is String) {
          events.add(event);
        }
      });
      await Future.delayed(const Duration(milliseconds: 200));
      return events;
    }, null);

    await Future.delayed(const Duration(milliseconds: 100));
    EventBus.instance.fire('a');
    EventBus.instance.fire('b');
    EventBus.instance.fire('c');

    await Future.delayed(const Duration(milliseconds: 200));

    expect(await events, ['a', 'b', 'c']);
  });

  test('send event to an dead isolate', () async {
    final events = compute((message) async {
      final events = <String>[];
      EventBus.instance.on.listen((event) {
        if (event is String) {
          events.add(event);
        }
      });
      await Future.delayed(const Duration(milliseconds: 200));
      return events;
    }, null);

    await Future.delayed(const Duration(milliseconds: 100));
    EventBus.instance.fire('a');
    EventBus.instance.fire('b');
    EventBus.instance.fire('c');

    await Future.delayed(const Duration(milliseconds: 200));

    expect(await events, ['a', 'b', 'c']);

    EventBus.instance.fire('d');
  });
}
