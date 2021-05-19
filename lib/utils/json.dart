dynamic dynamicToJson(dynamic object) {
  try {
    if (object?.toJson != null) return object.toJson();
  } catch (_) {}
  return object;
}
