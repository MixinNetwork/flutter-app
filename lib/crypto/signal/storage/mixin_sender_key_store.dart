import 'dart:io';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../../utils/logger.dart';
import '../dao/sender_key_dao.dart';
import '../signal_database.dart';

class MixinSenderKeyStore extends SenderKeyStore {
  MixinSenderKeyStore(SignalDatabase db) : super() {
    senderKeyDao = SenderKeyDao(db);
  }

  late SenderKeyDao senderKeyDao;

  @override
  Future<SenderKeyRecord> loadSenderKey(SenderKeyName senderKeyName) async {
    final senderKey = await senderKeyDao.getSenderKey(
      senderKeyName.groupId,
      senderKeyName.sender.toString(),
    );
    try {
      if (senderKey != null) {
        return SenderKeyRecord.fromSerialized(senderKey.record);
      }
    } on IOException catch (e) {
      w('loadSenderKey $e');
    }
    return SenderKeyRecord();
  }

  @override
  Future<void> storeSenderKey(
    SenderKeyName senderKeyName,
    SenderKeyRecord record,
  ) async {
    await senderKeyDao.insert(
      SenderKey(
        groupId: senderKeyName.groupId,
        senderId: senderKeyName.sender.toString(),
        record: record.serialize(),
      ),
    );
  }

  Future<void> removeSenderKey(SenderKeyName senderKeyName) async {
    await senderKeyDao.deleteByGroupIdAndSenderId(
      senderKeyName.groupId,
      senderKeyName.sender.toString(),
    );
  }
}
