import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class MixinClient {
  static final MixinClient _singleton = MixinClient._internal();

  final Client client = Client('UA');

  factory MixinClient() {
    return _singleton;
  }

  MixinClient._internal();
}
