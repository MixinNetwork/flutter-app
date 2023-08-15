T? fromHydratedJson<T>(
  dynamic json,
  T Function(Map<String, dynamic>) fromJson,
) {
  final dynamic traversedJson = _traverseRead(json);
  final castJson = _cast<Map<String, dynamic>>(traversedJson);
  return fromJson(castJson ?? <String, dynamic>{});
}

dynamic _traverseRead(dynamic value) {
  if (value is Map) {
    return value.map<String, dynamic>(
        (dynamic key, dynamic value) => MapEntry<String, dynamic>(
              _cast<String>(key) ?? '',
              _traverseRead(value),
            ));
  }
  if (value is List) {
    for (var i = 0; i < value.length; i++) {
      value[i] = _traverseRead(value[i]);
    }
  }
  return value;
}

T? _cast<T>(dynamic x) => x is T ? x : null;
