// ignore_for_file: avoid_dynamic_calls
dynamic dynamicToJson(dynamic object) {
  try {
    if (object?.toJson != null) return object.toJson();
  } catch (_) {}
  return object;
}
