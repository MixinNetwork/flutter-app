import 'ai_provider_type.dart';

class AiProviderConfig {
  AiProviderConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.enabled = true,
  });

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) =>
      AiProviderConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AiProviderType.fromValue(json['type'] as String? ?? ''),
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        model: json['model'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );

  final String id;
  final String name;
  final AiProviderType type;
  final String baseUrl;
  final String apiKey;
  final String model;
  final bool enabled;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.value,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
    'enabled': enabled,
  };

  AiProviderConfig copyWith({
    String? id,
    String? name,
    AiProviderType? type,
    String? baseUrl,
    String? apiKey,
    String? model,
    bool? enabled,
  }) => AiProviderConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    model: model ?? this.model,
    enabled: enabled ?? this.enabled,
  );
}
