import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

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

  void setCurrentSetting({
    bool? messagePreview,
    bool? photoAutoDownload,
    bool? videoAutoDownload,
    bool? fileAutoDownload,
  }) {
    final current = state.current;
    assert(current != null);

    final auths = state._auths.toSet()
      ..remove(current)
      ..add(current!.copyWith(
        messagePreview: messagePreview,
        photoAutoDownload: photoAutoDownload,
        videoAutoDownload: videoAutoDownload,
        fileAutoDownload: fileAutoDownload,
      ));

    emit(MultiAuthState(
      auths: auths,
    ));
  }
}
