import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/signal/dao/sender_key_dao.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/groups/state/SenderKeyRecord.dart';

import '../signal_database.dart';

class MixinSenderKeyStore extends SenderKeyStore {
  MixinSenderKeyStore(SignalDatabase db) : super() {
    senderKeyDao = SenderKeyDao(db);
  }

  late SenderKeyDao senderKeyDao;

  @override
  Future<SenderKeyRecord> loadSenderKey(SenderKeyName senderKeyName) async {
    final senderKey = await senderKeyDao.getSenderKey(
        senderKeyName.groupId, senderKeyName.sender.toString());
    try {
      if (senderKey != null) {
        return SenderKeyRecord.fromSerialized(senderKey.record);
      }
    } on IOException catch (e) {
      debugPrint('$e');
    }
    return SenderKeyRecord();
  }

  @override
  Future storeSenderKey(
      SenderKeyName senderKeyName, SenderKeyRecord record) async {
    await senderKeyDao.insert(SenderKey(
        groupId: senderKeyName.groupId,
        senderId: senderKeyName.sender.toString(),
        record: record.serialize()));
  }

  void removeSenderKey(SenderKeyName senderKeyName) {
    senderKeyDao.deleteByGroupIdAndSenderId(
        senderKeyName.groupId, senderKeyName.sender.toString());
  }
}
