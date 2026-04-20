import 'package:equatable/equatable.dart';

class AiModeState extends Equatable {
  const AiModeState({
    this.enabled = false,
    this.providerId,
  });

  final bool enabled;
  final String? providerId;

  @override
  List<Object?> get props => [enabled, providerId];

  AiModeState copyWith({
    bool? enabled,
    String? providerId,
    bool clearProviderId = false,
  }) => AiModeState(
    enabled: enabled ?? this.enabled,
    providerId: clearProviderId ? null : (providerId ?? this.providerId),
  );
}
