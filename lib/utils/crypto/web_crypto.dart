// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:webcrypto/src/boringssl/lookup/lookup.dart' as lookup;
import 'package:webcrypto/src/third_party/boringssl/generated_bindings.dart';

export 'package:webcrypto/src/third_party/boringssl/generated_bindings.dart';

extension NativeUint8List on Uint8List {
  Pointer<Uint8> toNative() {
    final ptr = malloc<Uint8>(length)..asTypedList(length).setAll(0, this);
    return ptr;
  }
}

class _SslAllocator implements Allocator {
  const _SslAllocator();

  /// Allocate [byteCount] bytes.
  ///
  /// Must be de-allocated with [free].
  @override
  ffi.Pointer<T> allocate<T extends ffi.NativeType>(
    int byteCount, {
    int? alignment,
  }) {
    final p = ssl.OPENSSL_malloc(byteCount);
    checkOp(p.address != 0, fallback: 'allocation failure');
    return p.cast<T>();
  }

  /// Release memory allocated with [allocate].
  @override
  void free(ffi.Pointer pointer) {
    ssl.OPENSSL_free(pointer.cast());
  }
}

const _sslAlloc = _SslAllocator();

BoringSsl get ssl => lookup.ssl;

void checkOpIsOne(int retval, {String? message, String? fallback}) =>
    checkOp(retval == 1, message: message, fallback: fallback);

void checkOp(bool condition, {String? message, String? fallback}) {
  if (!condition) {
    // Always extract the error to ensure we clear the error queue.
    final err = _extractError();
    message ??= err ?? fallback ?? 'unknown error';
    throw Exception(message);
  }
}

String? _extractError() {
  try {
    // Get the error.
    final err = ssl.ERR_get_error();
    if (err == 0) {
      return null;
    }
    const N = 4096; // Max error message size
    final out = _sslAlloc<ffi.Char>(N);
    try {
      ssl.ERR_error_string_n(err, out, N);
      final data = out.cast<ffi.Uint8>().asTypedList(N);
      // Take everything until '\0'
      return utf8.decode(data.takeWhile((i) => i != 0).toList());
    } finally {
      _sslAlloc.free(out);
    }
  } finally {
    // Always clear error queue, so we continue
    ssl.ERR_clear_error();
  }
}
