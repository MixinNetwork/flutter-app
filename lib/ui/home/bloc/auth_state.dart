part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.account,
    this.privateKey,
  });

  final Account account;
  final String privateKey;

  @override
  List<Object> get props => [account, privateKey];

  static AuthState fromJson(Map<String, dynamic> json) {
    Account account;
    if (json['account'] != null)
      account = Account.fromJson(json['account'] ?? {});
    return AuthState(
      account: account,
      privateKey: json['privateKey'],
    );
  }

  static Map<String, dynamic> toJson(AuthState state) => {
        'account': state?.account?.toJson(),
        'privateKey': state?.privateKey,
      };

  AuthState copyWith({
    final Account account,
    final String privateKey,
  }) {
    return AuthState(
      account: account ?? this.account,
      privateKey: privateKey ?? this.privateKey,
    );
  }
}
