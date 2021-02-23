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
    final auths = state.auths.toSet()
      ..removeWhere(
        (element) => element.account.userId == authState.account.userId,
      )
      ..add(authState);
    emit(
      MultiAuthState(
        auths: auths,
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

  @override
  MultiAuthState fromJson(Map<String, dynamic> json) =>
      MultiAuthState.fromMap(json);

  @override
  Map<String, dynamic> toJson(MultiAuthState state) => state.toMap();

  static MultiAuthCubit of(BuildContext context) =>
      BlocProvider.of<MultiAuthCubit>(context);

  String get currentUserId => state?.current?.account?.userId;
}
