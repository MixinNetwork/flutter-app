// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../utils/hydrated_bloc.dart';
import '../../utils/rivepod.dart';

class AuthState extends Equatable {
  const AuthState({
    required this.account,
    required this.privateKey,
  });

  factory AuthState.fromMap(Map<String, dynamic> map) {
    final account = map['account'] as Map<String, dynamic>;
    // migration from old version
    if (account['has_safe'] == null) {
      account['has_safe'] = false;
    }
    if (account['tip_counter'] == null) {
      account['tip_counter'] = 0;
    }
    if (account['tip_key_base64'] == null) {
      account['tip_key_base64'] = '';
    }
    return AuthState(
      account: Account.fromJson(account),
      privateKey: map['privateKey'] as String,
    );
  }

  final Account account;
  final String privateKey;

  String get userId => account.userId;

  @override
  List<Object?> get props => [account, privateKey];

  Map<String, dynamic> toMap() => {
        'account': account.toJson(),
        'privateKey': privateKey,
      };
}

class MultiAuthState extends Equatable {
  const MultiAuthState({
    Set<AuthState> auths = const {},
  }) : _auths = auths;

  factory MultiAuthState.fromMap(Map<String, dynamic> map) {
    final list = map['auths'] as Iterable<dynamic>?;
    return MultiAuthState(
      auths: list
              ?.map((e) => AuthState.fromMap(e as Map<String, dynamic>))
              .toSet() ??
          {},
    );
  }

  factory MultiAuthState.fromJson(String source) =>
      MultiAuthState.fromMap(json.decode(source) as Map<String, dynamic>);

  final Set<AuthState> _auths;

  AuthState? get current => _auths.isNotEmpty ? _auths.last : null;

  @override
  List<Object> get props => [_auths];

  Map<String, dynamic> toMap() => {
        'auths': _auths.map((x) => x.toMap()).toList(),
      };

  String toJson() => json.encode(toMap());
}

class MultiAuthStateNotifier extends DistinctStateNotifier<MultiAuthState> {
  MultiAuthStateNotifier(super.state);

  AuthState? get current => state.current;

  void signIn(AuthState authState) {
    state = MultiAuthState(
      auths: {
        ...state._auths.where(
            (element) => element.account.userId != authState.account.userId),
        authState,
      },
    );
  }

  void updateAccount(Account account) {
    var authState = state._auths
        .cast<AuthState?>()
        .firstWhere((element) => element?.account.userId == account.userId);
    if (authState == null) {
      i('update account, but ${account.userId} auth state not found.');
      return;
    }
    authState = AuthState(account: account, privateKey: authState.privateKey);
    state = MultiAuthState(
      auths: {
        ...state._auths.where(
            (element) => element.account.userId != authState?.account.userId),
        authState,
      },
    );
  }

  void signOut() {
    if (state._auths.isEmpty) return;
    state =
        MultiAuthState(auths: state._auths.toSet()..remove(state._auths.last));
  }

  @override
  @protected
  set state(MultiAuthState value) {
    final hydratedJson = toHydratedJson(state.toMap());
    HydratedBloc.storage.write(_kMultiAuthCubitKey, hydratedJson);
    super.state = value;
  }
}

@Deprecated('Use multiAuthNotifierProvider instead')
const _kMultiAuthCubitKey = 'MultiAuthCubit';

final multiAuthStateNotifierProvider =
    StateNotifierProvider.autoDispose<MultiAuthStateNotifier, MultiAuthState>(
        (ref) {
  ref.keepAlive();

  final oldJson = HydratedBloc.storage.read(_kMultiAuthCubitKey);
  if (oldJson != null) {
    final multiAuthState = fromHydratedJson(oldJson, MultiAuthState.fromMap);
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
