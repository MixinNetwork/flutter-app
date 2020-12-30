import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class MixinClient {
  factory MixinClient() {
    return _singleton;
  }

  MixinClient._internal();

  static final MixinClient _singleton = MixinClient._internal();
  final Client client = Client();
}
