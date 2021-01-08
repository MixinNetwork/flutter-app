import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

part 'multi_auth_state.dart';

class MultiAuthCubit extends HydratedCubit<MultiAuthState> {
  MultiAuthCubit() : super(const MultiAuthState());

  void signIn(AuthState authState) {
    state.auths.removeWhere(
      (element) => element.account.userId == authState.account.userId,
    );
    emit(
      MultiAuthState(
        auths: state.auths.toSet()..add(authState),
      ),
    );
  }

  void signOut() {
    emit(
      MultiAuthState(
        auths: state.auths.toSet()..remove(state.auths.last),
      ),
    );
  }

  @protected
  @override
  void emit(MultiAuthState state) {
    throw Error();
  }

  @override
  MultiAuthState fromJson(Map<String, dynamic> json) =>
      MultiAuthState.fromMap(json);

  @override
  Map<String, dynamic> toJson(MultiAuthState state) => state.toMap();

  static MultiAuthCubit of(BuildContext context) =>
      BlocProvider.of<MultiAuthCubit>(context);
}
