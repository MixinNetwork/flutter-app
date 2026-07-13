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
