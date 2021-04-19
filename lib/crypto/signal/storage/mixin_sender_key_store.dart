import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/signal/dao/sender_key_dao.dart';
import 'package:flutter_app/crypto/signal/vo/SenderKey.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/groups/state/SenderKeyRecord.dart';
import 'package:objectbox/objectbox.dart';

class MixinSenderKeyStore extends SenderKeyStore {
  MixinSenderKeyStore(Store store) {
    senderKeyDao = SenderKeyDao(store);
  }

  late SenderKeyDao senderKeyDao;

  @override
  SenderKeyRecord loadSenderKey(SenderKeyName senderKeyName) {
    final senderKey = senderKeyDao.getSenderKey(
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
  void storeSenderKey(SenderKeyName senderKeyName, SenderKeyRecord record) {
    senderKeyDao.insert(SenderKey(senderKeyName.groupId,
        senderKeyName.sender.toString(), record.serialize()));
  }

  void removeSenderKey(SenderKeyName senderKeyName) {
    senderKeyDao.delete(senderKeyName.groupId, senderKeyName.sender.toString());
  }
}
