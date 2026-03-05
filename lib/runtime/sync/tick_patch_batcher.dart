import 'dart:async';

import 'patch.dart';

class TickPatchBatcher {
  TickPatchBatcher({
    required this.onFlush,
    this.flushDelay = const Duration(milliseconds: 16),
  });

  final void Function(List<SyncPatch> patches) onFlush;
  final Duration flushDelay;

  final List<SyncPatch> _pending = <SyncPatch>[];
  Timer? _timer;
  bool _disposed = false;

  void add(SyncPatch patch) {
    if (_disposed) return;
    _pending.add(patch);
    _timer ??= Timer(flushDelay, _flush);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _flush();
  }

  void _flush() {
    if (_pending.isEmpty) return;
    final pending = List<SyncPatch>.unmodifiable(_pending.toList());
    _pending.clear();
    _timer = null;
    onFlush(pending);
  }
}
