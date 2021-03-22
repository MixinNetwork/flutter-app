int Function(E a, E b) compareValuesBy<E>(int Function(E) selector) =>
    (E a, E b) => selector(a) - selector(b);
