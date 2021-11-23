part of '../extension.dart';

extension StreamExtensionWhereNotNull<T> on Stream<T?> {
  Stream<T> whereNotNull() => where((e) => e != null).cast<T>();
}

extension StreamExtension<T> on Stream<T> {
  StreamSubscription asyncListen<E>(FutureOr<E> Function(T event) convert) =>
      asyncMap((e) => convert(e)).listen((_) {});
}
