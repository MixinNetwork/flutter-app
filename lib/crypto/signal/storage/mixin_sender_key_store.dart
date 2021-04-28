import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/groups/state/SenderKeyRecord.dart';

class MixinSenderKeyStore extends SenderKeyStore {
  @override
  SenderKeyRecord loadSenderKey(SenderKeyName senderKeyName) {
    // TODO: implement loadSenderKey
    throw UnimplementedError();
  }

  @override
  void storeSenderKey(SenderKeyName senderKeyName, SenderKeyRecord record) {
    // TODO: implement storeSenderKey
  }
}
