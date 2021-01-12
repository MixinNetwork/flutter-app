List<T> joinList<T>(List<T> list, T separator) {
  final iterator = list.iterator;
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
