import 'ai_provider_type.dart';

class AiProviderConfig {
  AiProviderConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.apiKey,
    required String model,
    List<String>? models,
    String? defaultModel,
    this.enabled = true,
  }) : models = _normalizeModels(models, model, defaultModel),
       defaultModel = _resolveDefaultModel(models, model, defaultModel);

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) => () {
    final legacyModel = json['model'] as String? ?? '';
    final models = (json['models'] as List?)
        ?.whereType<String>()
        .map((model) => model.trim())
        .where((model) => model.isNotEmpty)
        .toList();
    return AiProviderConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AiProviderType.fromValue(json['type'] as String? ?? ''),
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      model: legacyModel,
      models: models,
      defaultModel: json['defaultModel'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }();

  final String id;
  final String name;
  final AiProviderType type;
  final String baseUrl;
  final String apiKey;
  final List<String> models;
  final String defaultModel;
  final bool enabled;

  String get model => defaultModel;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.value,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
    'models': models,
    'defaultModel': defaultModel,
    'enabled': enabled,
  };

  AiProviderConfig copyWith({
    String? id,
    String? name,
    AiProviderType? type,
    String? baseUrl,
    String? apiKey,
    String? model,
    List<String>? models,
    String? defaultModel,
    bool? enabled,
  }) => AiProviderConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    model: model ?? this.model,
    models: models ?? this.models,
    defaultModel: defaultModel ?? this.defaultModel,
    enabled: enabled ?? this.enabled,
  );

  static List<String> _normalizeModels(
    List<String>? models,
    String model,
    String? defaultModel,
  ) {
    final values =
        [
              ...?models,
              model,
              ...(switch (defaultModel) {
                final String value => [value],
                null => const <String>[],
              }),
            ]
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty);
    return values.toSet().toList(growable: false);
  }

  static String _resolveDefaultModel(
    List<String>? models,
    String model,
    String? defaultModel,
  ) {
    final normalizedModels = _normalizeModels(models, model, defaultModel);
    final candidate = defaultModel?.trim() ?? model.trim();
    if (candidate.isNotEmpty && normalizedModels.contains(candidate)) {
      return candidate;
    }
    return normalizedModels.isNotEmpty ? normalizedModels.first : '';
  }
}
