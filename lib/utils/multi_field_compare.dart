class MultiFieldCompareParameter<T> {
  const MultiFieldCompareParameter(this.getField, [this.desc = false]);

  final dynamic Function(T t) getField;
  final bool desc;
}

int Function(T a, T b) multiFieldCompare<T>(
        List<MultiFieldCompareParameter<T>> parameters) =>
    (T a, T b) {
      for (final p in parameters) {
        final dynamic tempA = p.getField(a);
        final dynamic tempB = p.getField(b);

        int result;

        if (tempA == null && tempB == null)
          result ??= 0;
        else if (tempA != null && tempB != null)
          result ??= tempA.compareTo(tempB);
        else if (a == null)
          result ??= -1;
        else
          result ??= 1;

        if (result != 0) return result * (p.desc ? -1 : 1);
      }
      return 0;
    };
