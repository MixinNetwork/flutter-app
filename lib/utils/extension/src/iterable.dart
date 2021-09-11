part of '../extension.dart';

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T? element) test) =>
      cast<T?>().firstWhere(test, orElse: () => null);
}

extension IterableExtenstionNull<T> on Iterable<T?> {
  Iterable<T> whereNotNull() => where((e) => e != null).cast();
}

extension ListExtension<T> on List<T> {
  List<List<T>> partition(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

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
}
