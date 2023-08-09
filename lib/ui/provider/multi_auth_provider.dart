// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/global_hive.dart';
import '../../utils/hydrated_bloc.dart';

class AuthState extends Equatable {
  const AuthState({
    required this.account,
    required this.privateKey,
  });

  factory AuthState.fromMap(Map<String, dynamic> map) => AuthState(
        account: Account.fromJson(map['account'] as Map<String, dynamic>),
        privateKey: map['privateKey'] as String,
      );

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

class MultiAuthChangeNotifier extends ChangeNotifier {
  MultiAuthChangeNotifier(this._state);

  static const _kMultiAuthNotifierProviderKey = 'auths';

  MultiAuthState _state;

  AuthState? get current => _state.current;

  void signIn(AuthState authState) {
    _state = MultiAuthState(
      auths: {
        ..._state._auths.where(
            (element) => element.account.userId != authState.account.userId),
        authState,
      },
    );

    notifyListeners();
  }

  void updateAccount(Account account) {
    var authState = _state._auths
        .cast<AuthState?>()
        .firstWhere((element) => element?.account.userId == account.userId);
    if (authState == null) {
      i('update account, but ${account.userId} auth state not found.');
      return;
    }
    authState = AuthState(account: account, privateKey: authState.privateKey);
    _state = MultiAuthState(
      auths: {
        ..._state._auths.where(
            (element) => element.account.userId != authState?.account.userId),
        authState,
      },
    );

    notifyListeners();
  }

  void signOut() {
    if (_state._auths.isEmpty) return;
    _state = MultiAuthState(
        auths: _state._auths.toSet()..remove(_state._auths.last));

    notifyListeners();
  }

  @override
  void notifyListeners() {
    globalBox.put(_kMultiAuthNotifierProviderKey, _state.toJson());
    super.notifyListeners();
  }
}

@Deprecated('Use multiAuthNotifierProvider instead')
const _kMultiAuthCubitKey = 'MultiAuthCubit';

final multiAuthNotifierProvider =
    ChangeNotifierProvider.autoDispose<MultiAuthChangeNotifier>((ref) {
  ref.keepAlive();

  //  migrate
  {
    final oldJson = HydratedBloc.storage.read(_kMultiAuthCubitKey);
    if (oldJson != null) {
      final multiAuthState = fromHydratedJson(oldJson, MultiAuthState.fromMap);
      if (multiAuthState == null) {
        return MultiAuthChangeNotifier(const MultiAuthState());
      }

      globalBox.put(MultiAuthChangeNotifier._kMultiAuthNotifierProviderKey,
          multiAuthState.toJson());

      HydratedBloc.storage.delete(_kMultiAuthCubitKey);

      return MultiAuthChangeNotifier(multiAuthState);
    }

    final json =
        globalBox.get(MultiAuthChangeNotifier._kMultiAuthNotifierProviderKey);
    if (json != null && json is String) {
      return MultiAuthChangeNotifier(MultiAuthState.fromJson(json));
    }
  }

  return MultiAuthChangeNotifier(const MultiAuthState());
});

final multiAuthProvider =
    multiAuthNotifierProvider.select((value) => value._state);

final authProvider = multiAuthNotifierProvider.select((value) => value.current);

final authAccountProvider = authProvider.select((value) => value?.account);
