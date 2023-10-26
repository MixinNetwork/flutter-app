import 'package:equatable/equatable.dart';

enum LandingStatus {
  needReload,
  provisioning,
  ready,
}

class LandingState extends Equatable {
  const LandingState({
    this.authUrl,
    required this.status,
    this.errorMessage,
  });

  final String? authUrl;
  final LandingStatus status;

  final String? errorMessage;

  @override
  List<Object?> get props => [authUrl, status, errorMessage];

  LandingState needReload(String errorMessage) => LandingState(
        status: LandingStatus.needReload,
        errorMessage: errorMessage,
        authUrl: authUrl,
      );

  LandingState copyWith({
    String? authUrl,
    LandingStatus? status,
  }) =>
      LandingState(
        authUrl: authUrl ?? this.authUrl,
        status: status ?? this.status,
      );
}
