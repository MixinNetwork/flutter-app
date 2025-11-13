// ignore_for_file: avoid_catching_errors

import 'package:hydrated_bloc/hydrated_bloc.dart';

T? fromHydratedJson<T>(
  dynamic json,
  T Function(Map<String, dynamic>) fromJson,
) {
  final dynamic traversedJson = _traverseRead(json);
  final castJson = _cast<Map<String, dynamic>>(traversedJson);
  return fromJson(castJson ?? <String, dynamic>{});
}

Map<String, dynamic>? toHydratedJson(Map<String, dynamic> state) =>
    _cast<Map<String, dynamic>>(_traverseWrite(state).value);

dynamic _traverseRead(dynamic value) {
  if (value is Map) {
    return value.map<String, dynamic>(
      (dynamic key, dynamic value) => MapEntry<String, dynamic>(
        _cast<String>(key) ?? '',
        _traverseRead(value),
      ),
    );
  }
  if (value is List) {
    for (var i = 0; i < value.length; i++) {
      value[i] = _traverseRead(value[i]);
    }
  }
  return value;
}

class NIL {
  const NIL();
}

enum _Outcome { atomic, complex }

class _Traversed {
  _Traversed._({required this.outcome, required this.value});

  _Traversed.atomic(dynamic value)
    : this._(outcome: _Outcome.atomic, value: value);

  _Traversed.complex(dynamic value)
    : this._(outcome: _Outcome.complex, value: value);
  final _Outcome outcome;
  final dynamic value;
}

dynamic _traverseAtomicJson(dynamic object) {
  if (object is num) {
    if (!object.isFinite) return const NIL();
    return object;
  } else if (identical(object, true)) {
    return true;
  } else if (identical(object, false)) {
    return false;
  } else if (object == null) {
    return null;
  } else if (object is String) {
    return object;
  }
  return const NIL();
}

dynamic _traverseComplexJson(dynamic object) {
  if (object is List) {
    if (object.isEmpty) return object;
    List<dynamic>? list;
    for (var i = 0; i < object.length; i++) {
      final traversed = _traverseWrite(object[i]);
      list ??= traversed.outcome == _Outcome.atomic
          ? object.sublist(0)
          : (<dynamic>[]..length = object.length);
      list[i] = traversed.value;
    }
    return list;
  } else if (object is Map) {
    final map = <String, dynamic>{};
    object.forEach((dynamic key, dynamic value) {
      final castKey = _cast<String>(key);
      if (castKey != null) {
        map[castKey] = _traverseWrite(value).value;
      }
    });
    return map;
  }
  return const NIL();
}

// ignore: avoid_dynamic_calls
dynamic _toEncodable(dynamic object) => object.toJson();

dynamic _traverseJson(dynamic object) {
  final dynamic traversedAtomicJson = _traverseAtomicJson(object);
  return traversedAtomicJson is! NIL
      ? traversedAtomicJson
      : _traverseComplexJson(object);
}

_Traversed _traverseWrite(Object? value) {
  final dynamic traversedAtomicJson = _traverseAtomicJson(value);
  if (traversedAtomicJson is! NIL) {
    return _Traversed.atomic(traversedAtomicJson);
  }
  final dynamic traversedComplexJson = _traverseComplexJson(value);
  if (traversedComplexJson is! NIL) {
    return _Traversed.complex(traversedComplexJson);
  }
  try {
    final dynamic customJson = _toEncodable(value);
    final dynamic traversedCustomJson = _traverseJson(customJson);
    if (traversedCustomJson is NIL) {
      throw HydratedUnsupportedError(value);
    }
    return _Traversed.complex(traversedCustomJson);
  } on HydratedCyclicError catch (e, s) {
    Error.throwWithStackTrace(HydratedUnsupportedError(value, cause: e), s);
  } on HydratedUnsupportedError {
    rethrow; // do not stack `HydratedUnsupportedError`
  } catch (e, s) {
    Error.throwWithStackTrace(HydratedUnsupportedError(value, cause: e), s);
  }
}

T? _cast<T>(dynamic x) => x is T ? x : null;
