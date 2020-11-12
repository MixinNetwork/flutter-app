import 'package:bot_api_dart_client/bot_api_dart_client.dart';

class MixinClient {
  static final MixinClient _signleton = MixinClient._internal();

  final Client client = Client('UA');

  factory MixinClient() {
    return _signleton;
  }

  MixinClient._internal();
}
