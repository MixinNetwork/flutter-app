part of '../extension.dart';

extension AppIterableExtension<T> on Iterable<T> {
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
}

extension AppListExtension<T> on List<T> {
  T? getOrNull(int index) => index < 0 || index >= length ? null : this[index];
}
