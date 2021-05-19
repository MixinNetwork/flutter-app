dynamic dynamicToJson(dynamic object) {
  if (object?.toJson != null) return object.toJson();
  return object;
}
