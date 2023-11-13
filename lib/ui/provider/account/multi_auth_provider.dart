import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../../utils/extension/extension.dart';
import '../../../utils/hydrated_bloc.dart';
import '../../../utils/rivepod.dart';

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
  MultiAuthState({
    this.auths = const [],
    String? activeUserId,
  }) : activeUserId = activeUserId ?? auths.lastOrNull?.userId;

  factory MultiAuthState.fromJson(Map<String, dynamic> map) =>
      _$MultiAuthStateFromJson(map);

  @JsonKey(name: 'auths')
  final List<AuthState> auths;

  /// activeUserId is the current activated account userId
  @JsonKey(name: 'activeUserId')
  final String? activeUserId;

  AuthState? get current {
    if (auths.isEmpty) {
      return null;
    }
    if (activeUserId != null) {
      return auths
          .firstWhereOrNull((element) => element.userId == activeUserId);
    }
    w('activeUserId is null');
    return auths.lastOrNull;
  }

  @override
  List<Object?> get props => [auths, activeUserId];

  Map<String, dynamic> toJson() => _$MultiAuthStateToJson(this);
}

class MultiAuthStateNotifier extends DistinctStateNotifier<MultiAuthState> {
  MultiAuthStateNotifier(super.state);

  AuthState? get current => state.current;

  void signIn(AuthState authState) {
    state = MultiAuthState(
      auths: [
        ...state.auths.where((element) => element.userId != authState.userId),
        authState,
      ],
      activeUserId: authState.userId,
    );
  }

  void updateAccount(Account account) {
    final index =
        state.auths.indexWhere((element) => element.userId == account.userId);
    if (index == -1) {
      i('update account, but ${account.userId} auth state not found.');
      return;
    }
    final auths = state.auths.toList();
    auths[index] = AuthState(
      account: account,
      privateKey: state.auths[index].privateKey,
    );
    state = MultiAuthState(auths: auths, activeUserId: state.activeUserId);
  }

  void signOut(String userId) {
    if (state.auths.isEmpty) return;
    final auths = state.auths.toList()
      ..removeWhere((element) => element.userId == userId);
    final activeUserId = state.activeUserId == userId
        ? auths.lastOrNull?.userId
        : state.activeUserId;
    state = MultiAuthState(auths: auths, activeUserId: activeUserId);
  }

  @override
  @protected
  set state(MultiAuthState value) {
    final hydratedJson = toHydratedJson(value.toJson());
    HydratedBloc.storage.write(_kMultiAuthCubitKey, hydratedJson);
    super.state = value;
  }

  void active(String userId) {
    final exist = state.auths.any((element) => element.userId == userId);
    if (!exist) {
      e('failed to active, no account exist for id: $userId');
      return;
    }
    i('active account: $userId');
    state = MultiAuthState(
      auths: state.auths,
      activeUserId: userId,
    );
  }
}

const _kMultiAuthCubitKey = 'MultiAuthCubit';

final multiAuthStateNotifierProvider =
    StateNotifierProvider<MultiAuthStateNotifier, MultiAuthState>((ref) {
  final oldJson = HydratedBloc.storage.read(_kMultiAuthCubitKey);
  if (oldJson != null) {
    final multiAuthState = fromHydratedJson(oldJson, MultiAuthState.fromJson);
    if (multiAuthState == null) {
      return MultiAuthStateNotifier(MultiAuthState());
    }

    return MultiAuthStateNotifier(multiAuthState);
  }

  return MultiAuthStateNotifier(MultiAuthState());
});

final authProvider =
    multiAuthStateNotifierProvider.select((value) => value.current);

final authAccountProvider = authProvider.select((value) => value?.account);
