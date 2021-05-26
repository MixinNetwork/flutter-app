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
        buffer..add(separator)..add(iterator.current);
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
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
