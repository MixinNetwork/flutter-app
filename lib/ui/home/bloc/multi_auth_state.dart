part of 'multi_auth_cubit.dart';

class MultiAuthState extends Equatable {
  const MultiAuthState({
    this.auths = const {},
  });

  factory MultiAuthState.fromMap(Map<String, dynamic> map) {
    return MultiAuthState(
      auths:
          Set<AuthState>.from(map['auths']?.map((x) => AuthState.fromMap(x))),
    );
  }

  factory MultiAuthState.fromJson(String source) =>
      MultiAuthState.fromMap(json.decode(source));

  final Set<AuthState> auths;

  AuthState? get current => auths.isNotEmpty ? auths.last : null;

  @override
  List<Object> get props => [
        auths,
      ];

  Map<String, dynamic> toMap() {
    return {
      'auths': auths.map((x) => x.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());
}

class AuthState extends Equatable {
  const AuthState({
    required this.account,
    required this.privateKey,
  });

  factory AuthState.fromMap(Map<String, dynamic> map) {
    return AuthState(
      account: Account.fromJson(map['account']),
      privateKey: map['privateKey'],
    );
  }
  factory AuthState.fromJson(String source) =>
      AuthState.fromMap(json.decode(source));

  final Account account;
  final String privateKey;

  @override
  List<Object> get props => [account, privateKey];

  AuthState copyWith({
    Account? account,
    String? privateKey,
  }) {
    return AuthState(
      account: account ?? this.account,
      privateKey: privateKey ?? this.privateKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account': account.toJson(),
      'privateKey': privateKey,
    };
  }

  String toJson() => json.encode(toMap());
}
