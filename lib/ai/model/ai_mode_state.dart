import 'package:equatable/equatable.dart';

class AiModeState extends Equatable {
  const AiModeState({
    this.enabled = false,
    this.providerId,
    this.model,
  });

  final bool enabled;
  final String? providerId;
  final String? model;

  @override
  List<Object?> get props => [enabled, providerId, model];

  AiModeState copyWith({
    bool? enabled,
    String? providerId,
    String? model,
    bool clearProviderId = false,
    bool clearModel = false,
  }) => AiModeState(
    enabled: enabled ?? this.enabled,
    providerId: clearProviderId ? null : (providerId ?? this.providerId),
    model: clearModel ? null : (model ?? this.model),
  );
}
