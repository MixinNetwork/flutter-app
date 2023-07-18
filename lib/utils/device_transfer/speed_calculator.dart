import 'dart:collection';

/// Calculate latest 5 seconds transfer speed
class SpeedCalculator {
  final _count = Queue<int>();
  final _time = Queue<int>();

  void reset() {
    _count.clear();
    _time.clear();
  }

  /// Add a new transfer size
  void add(int count) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_count.isEmpty) {
      _count.add(count);
      _time.add(now);
      return;
    }
    final last = _time.last;
    if (now - last < 1000) {
      _count.addLast(_count.removeLast() + count);
    } else {
      _count.add(count);
      _time.add(now);
    }

    if (_count.length > 5) {
      _count.removeFirst();
      _time.removeFirst();
    }
  }

  double get speed {
    if (_count.isEmpty) {
      return 0;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _time.first;
    if (now == last) {
      return 0;
    }
    return _count.reduce((a, b) => a + b) / (now - last) * 1000;
  }
}
