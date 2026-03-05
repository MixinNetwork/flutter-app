import 'package:flutter_app/runtime/sync/patch.dart';
import 'package:flutter_app/runtime/sync/tick_patch_batcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flushes pending patches at tick end in a single batch', () async {
    final flushed = <List<SyncPatch>>[];
    TickPatchBatcher(
        onFlush: flushed.add,
        flushDelay: const Duration(milliseconds: 20),
      )
      ..add(SyncPatch.updateConversation(['c1']))
      ..add(SyncPatch.updateConversation(['c2']))
      ..add(SyncPatch.updateConversation(['c3']));

    expect(flushed, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(flushed, hasLength(1));
    expect(flushed.single, hasLength(3));
    expect(
      flushed.single.every((p) => p.type == SyncPatchType.updateConversation),
      isTrue,
    );
  });

  test('dispose flushes pending patches immediately', () {
    final flushed = <List<SyncPatch>>[];
    TickPatchBatcher(
        onFlush: flushed.add,
        flushDelay: const Duration(seconds: 1),
      )
      ..add(SyncPatch.updateUser(['u1']))
      ..dispose();

    expect(flushed, hasLength(1));
    expect(flushed.single, hasLength(1));
    expect(flushed.single.first.type, SyncPatchType.updateUser);
  });
}
