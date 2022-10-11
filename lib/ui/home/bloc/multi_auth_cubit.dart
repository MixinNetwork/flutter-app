import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../utils/logger.dart';

part 'multi_auth_state.dart';

class MultiAuthCubit extends HydratedCubit<MultiAuthState> {
  MultiAuthCubit() : super(const MultiAuthState());

  static Account? currentAccount;

  void signIn(AuthState authState) {
    var _authState = state._auths.cast<AuthState?>().firstWhere(
          (element) => element?.account.userId == authState.account.userId,
          orElse: () => null,
        );
    _authState = _authState?.copyWith(
          account: authState.account,
          privateKey: authState.privateKey,
        ) ??
        authState;

    emit(
      MultiAuthState(
        auths: {
          ...state._auths.where(
              (element) => element.account.userId != authState.account.userId),
          _authState,
        },
      ),
    );
    currentAccount = authState.account;
  }

  void updateAccount(Account account) {
    var authState = state._auths
        .cast<AuthState?>()
        .firstWhere((element) => element?.account.userId == account.userId);
    if (authState == null) {
      i('update account, but ${account.userId} auth state not found.');
      return;
    }
    authState = authState.copyWith(account: account);
    emit(
      MultiAuthState(
        auths: {
          ...state._auths.where(
              (element) => element.account.userId != authState?.account.userId),
          authState,
        },
      ),
    );
    currentAccount = authState.account;
  }

  void signOut() {
    if (state._auths.isEmpty) return;
    emit(
      MultiAuthState(
        auths: state._auths.toSet()..remove(state._auths.last),
      ),
    );
  }

  @override
  MultiAuthState fromJson(Map<String, dynamic> json) =>
      MultiAuthState.fromMap(json);

  @override
  Map<String, dynamic> toJson(MultiAuthState state) => state.toMap();

  void cleanCurrentSetting() {
    final current = state.current;
    if (current == null) return;

    final auths = state._auths.toSet()
      ..remove(current)
      ..add(AuthState(
        account: current.account,
        privateKey: current.privateKey,
      ));

    emit(MultiAuthState(
      auths: auths,
    ));
  }
}
