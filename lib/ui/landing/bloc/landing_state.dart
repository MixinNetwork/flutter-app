part of 'landing_cubit.dart';

enum LandingStatus {
  needReload,
  provisioning,
  ready,
  init,
}

class LandingState extends Equatable {
  const LandingState({
    this.authUrl,
    this.status = LandingStatus.init,
  });

  final String? authUrl;
  final LandingStatus status;

  @override
  List<Object?> get props => [authUrl, status];

  LandingState copyWith({
    final String? authUrl,
    final LandingStatus? status,
  }) {
    return LandingState(
      authUrl: authUrl ?? this.authUrl,
      status: status ?? this.status,
    );
  }
}
