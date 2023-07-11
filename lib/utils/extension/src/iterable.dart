part of '../extension.dart';

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T? element) test) =>
      cast<T?>().firstWhere(test, orElse: () => null);
}

extension ListExtension<T> on List<T> {
  List<T> joinList(T separator) {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return [];
    final buffer = <T>[];
    if (separator == null) {
      do {
        buffer.add(iterator.current);
      } while (iterator.moveNext());
    } else {
      buffer.add(iterator.current);
      while (iterator.moveNext()) {
        buffer
          ..add(separator)
          ..add(iterator.current);
      }
    }

    return buffer;
  }

  T? getOrNull(int index) {
    if (index < 0) return null;
    if (isEmpty) return null;
    if (length < index + 1) return null;
    return this[index];
  }

  T? get lastOrNull {
    try {
      return last;
    } catch (e) {
      return null;
    }
  }

  T? get firstOrNull {
    try {
      return first;
    } catch (e) {
      return null;
    }
  }

  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  List<List<T>> chunked(int size) {
    if (size <= 1) {
      throw ArgumentError('size must be greater than 1');
    }
    final result = <List<T>>[];
    var i = 0;
    while (i < length) {
      final end = min(i + size, length);
      result.add(sublist(i, end));
      i = end;
    }
    return result;
  }
}

Future<void> futureForEachIndexed<T>(
  Iterable<T> iterable,
  FutureOr<void> Function(int index, T element) action,
) async {
  var index = 0;
  for (final element in iterable) {
    await action(index, element);
    index++;
  }
}
