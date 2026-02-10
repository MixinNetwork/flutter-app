int Function(E a, E b) compareValuesBy<E>(int Function(E) selector) =>
    (a, b) => selector(a) - selector(b);
