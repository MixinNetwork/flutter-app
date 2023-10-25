import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../utils/hydrated_bloc.dart';
import '../../utils/rivepod.dart';

part 'multi_auth_provider.g.dart';

@JsonSerializable()
class AuthState extends Equatable {
  const AuthState({
    required this.account,
    required this.privateKey,
  });

  factory AuthState.fromJson(Map<String, dynamic> map) =>
      _$AuthStateFromJson(map);

  @JsonKey(name: 'account')
  final Account account;
  @JsonKey(name: 'privateKey')
  final String privateKey;

  String get userId => account.userId;

  @override
  List<Object?> get props => [account, privateKey];

  Map<String, dynamic> toJson() => _$AuthStateToJson(this);
}

@JsonSerializable()
class MultiAuthState extends Equatable {
  const MultiAuthState({
    this.auths = const {},
  });

  factory MultiAuthState.fromJson(Map<String, dynamic> map) =>
      _$MultiAuthStateFromJson(map);

  @JsonKey(name: 'auths')
  final Set<AuthState> auths;

  AuthState? get current => auths.isNotEmpty ? auths.last : null;

  @override
  List<Object> get props => [auths];

  Map<String, dynamic> toJson() => _$MultiAuthStateToJson(this);
}

class MultiAuthStateNotifier extends DistinctStateNotifier<MultiAuthState> {
  MultiAuthStateNotifier(super.state);

  AuthState? get current => state.current;

  void signIn(AuthState authState) {
    state = MultiAuthState(
      auths: {
        ...state.auths.where(
            (element) => element.account.userId != authState.account.userId),
        authState,
      },
    );
  }

  void updateAccount(Account account) {
    var authState = state.auths
        .cast<AuthState?>()
        .firstWhere((element) => element?.account.userId == account.userId);
    if (authState == null) {
      i('update account, but ${account.userId} auth state not found.');
      return;
    }
    authState = AuthState(account: account, privateKey: authState.privateKey);
    state = MultiAuthState(
      auths: {
        ...state.auths.where(
            (element) => element.account.userId != authState?.account.userId),
        authState,
      },
    );
  }

  void signOut() {
    if (state.auths.isEmpty) return;
    state =
        MultiAuthState(auths: state.auths.toSet()..remove(state.auths.last));
  }

  @override
  @protected
  set state(MultiAuthState value) {
    final hydratedJson = toHydratedJson(state.toJson());
    HydratedBloc.storage.write(_kMultiAuthCubitKey, hydratedJson);
    super.state = value;
  }
}

const _kMultiAuthCubitKey = 'MultiAuthCubit';

final multiAuthStateNotifierProvider =
    StateNotifierProvider.autoDispose<MultiAuthStateNotifier, MultiAuthState>(
        (ref) {
  ref.keepAlive();

  final oldJson = HydratedBloc.storage.read(_kMultiAuthCubitKey);
  if (oldJson != null) {
    final multiAuthState = fromHydratedJson(oldJson, MultiAuthState.fromJson);
    if (multiAuthState == null) {
      return MultiAuthStateNotifier(const MultiAuthState());
    }

    return MultiAuthStateNotifier(multiAuthState);
  }

  return MultiAuthStateNotifier(const MultiAuthState());
});

final authProvider =
    multiAuthStateNotifierProvider.select((value) => value.current);

final authAccountProvider = authProvider.select((value) => value?.account);
