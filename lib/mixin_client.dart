import 'package:flutter_app/ui/home/bloc/auth_cubit.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class MixinClient {
  factory MixinClient() {
    return _singleton;
  }

  MixinClient._internal();

  static final MixinClient _singleton = MixinClient._internal();
  final Client client = Client();

  void init(AuthCubit authCubit) {
    final account = authCubit.state.account;
    final privateKey = authCubit.state.privateKey;
    client.initMixin(account.userId, account.sessionId, privateKey,
        'PROFILE:READ PROFILE:WRITE PHONE:READ PHONE:WRITE CONTACTS:READ CONTACTS:WRITE MESSAGES:READ MESSAGES:WRITE ASSETS:READ SNAPSHOTS:READ CIRCLES:READ CIRCLES:WRITE');
  }
}
