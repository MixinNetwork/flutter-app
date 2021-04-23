import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/blaze/blaze_message.dart';
import 'package:flutter_app/blaze/blaze_param.dart';
import 'package:flutter_app/crypto/signal/signal_database.dart';
import 'package:flutter_app/crypto/signal/storage/mixin_identity_key_store.dart';
import 'package:flutter_app/crypto/signal/storage/mixin_prekey_store.dart';
import 'package:flutter_app/crypto/signal/storage/mixin_sender_key_store.dart';
import 'package:flutter_app/crypto/signal/storage/mixin_session_store.dart';
import 'package:flutter_app/crypto/signal/storage/mixin_signal_protocol_store.dart';
import 'package:flutter_app/crypto/signal/encrypt_result.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/utils/string_extension.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/InvalidMessageException.dart';
import 'package:moor/moor.dart';

import 'identity_key_util.dart';

class SignalProtocol {
  SignalProtocol(this._sessionId);

  static const int defaultDeviceId = 1;

  final String _sessionId;

  late SignalDatabase db;

  late MixinSignalProtocolStore mixinSignalProtocolStore;
  late MixinSenderKeyStore senderKeyStore;

  static Future initSignal() async {
    await IdentityKeyUtil.generateIdentityKeyPair(SignalDatabase.get);
  }

  Future init() async {
    db = SignalDatabase.get;
    final preKeyStore = MixinPreKeyStore(db);
    final signedPreKeyStore = MixinPreKeyStore(db);
    final identityKeyStore = MixinIdentityKeyStore(db, _sessionId);
    final sessionStore = MixinSessionStore(db);
    mixinSignalProtocolStore = MixinSignalProtocolStore(
        preKeyStore, signedPreKeyStore, identityKeyStore, sessionStore);
    senderKeyStore = MixinSenderKeyStore(db);
  }

  Future<Uint8List?> getSenderKeyPublic(String groupId, String userId,
      {String? sessionId}) async {
    final senderKeyName = SenderKeyName(
        groupId, SignalProtocolAddress(userId, sessionId.getDeviceId()));
    final sender = await senderKeyStore.loadSenderKey(senderKeyName);
    try {
      return (sender.getSenderKeyState().signingKeyPublic as DjbECPublicKey)
          .publicKey;
    } on Exception {
      return null;
    }
  }

  Future<SenderKeyDistributionMessageWrapper> getSenderKeyDistribution(
      String groupId, String senderId) async {
    final senderKeyName = SenderKeyName(
        groupId, SignalProtocolAddress(senderId, defaultDeviceId));
    final build = GroupSessionBuilder(senderKeyStore);
    return build.create(senderKeyName);
  }

  Future<EncryptResult> encryptSenderKey(
      String conversationId, String recipientId,
      {int deviceId = defaultDeviceId}) async {
    final senderKeyDistributionMessage =
        await getSenderKeyDistribution(conversationId, _sessionId);
    try {
      final cipherMessage = await encryptSession(
          senderKeyDistributionMessage.serialize(), recipientId, deviceId);
      final compose = ComposeMessageData(
          cipherMessage.getType(), cipherMessage.serialize());
      final cipher = encodeMessageData(compose);
      return EncryptResult(cipher, false);
    } on UntrustedIdentityException {
      final remoteAddress = SignalProtocolAddress(recipientId, deviceId);
      mixinSignalProtocolStore
        ..removeIdentity(remoteAddress)
        ..deleteSession(remoteAddress);
      return EncryptResult(null, true);
    }
  }

  Future<CiphertextMessage> encryptSession(
      Uint8List content, String destination, int deviceId) async {
    final remoteAddress = SignalProtocolAddress(destination, deviceId);
    final sessionCipher =
        SessionCipher.fromStore(mixinSignalProtocolStore, remoteAddress);
    return sessionCipher.encrypt(content);
  }

  void decrypt(
      String groupId,
      String senderId,
      int dataType,
      Uint8List cipherText,
      String category,
      String? sessionId,
      DecryptionCallback callback) {
    final address = SignalProtocolAddress(senderId, sessionId.getDeviceId());
    final sessionCipher =
        SessionCipher.fromStore(mixinSignalProtocolStore, address);
    if (category == MessageCategory.signalKey.toString()) {
      if (dataType == CiphertextMessage.PREKEY_TYPE) {
        sessionCipher.decryptWithCallback(PreKeySignalMessage(cipherText),
            (plainText) {
          processGroupSession(groupId, address,
              SenderKeyDistributionMessageWrapper.fromSerialized(plainText));
          callback.call(plainText);
        });
      } else if (dataType == CiphertextMessage.WHISPER_TYPE) {
        sessionCipher.decryptFromSignalWithCallback(
            SignalMessage.fromSerialized(cipherText), (plaintext) {
          processGroupSession(groupId, address,
              SenderKeyDistributionMessageWrapper.fromSerialized(plaintext));
          callback.call(plaintext);
        });
      }
    } else {
      if (dataType == CiphertextMessage.PREKEY_TYPE) {
        sessionCipher.decryptWithCallback(
            PreKeySignalMessage(cipherText), callback);
      } else if (dataType == CiphertextMessage.WHISPER_TYPE) {
        sessionCipher.decryptFromSignalWithCallback(
            SignalMessage.fromSerialized(cipherText), callback);
      } else if (dataType == CiphertextMessage.SENDERKEY_TYPE) {
        decryptGroupMessage(groupId, address, cipherText, callback);
      } else {
        throw InvalidMessageException('Unknown type: $dataType');
      }
    }
  }

  Future<bool> isExistSenderKey(String groupId, String senderId) async {
    final senderKeyName = SenderKeyName(
        groupId, SignalProtocolAddress(_sessionId, defaultDeviceId));
    final senderKeyRecord = await senderKeyStore.loadSenderKey(senderKeyName);
    return !senderKeyRecord.isEmpty;
  }

  Future<bool> containsUserSession(String recipientId) async {
    final sessions = await mixinSignalProtocolStore.sessionStore.sessionDao
        .getSessions(recipientId);
    return sessions.isNotEmpty;
  }

  Future<bool> containsSession(String recipientId,
      {int deviceId = defaultDeviceId}) async {
    final signalProtocolAddress = SignalProtocolAddress(recipientId, deviceId);
    return await mixinSignalProtocolStore
        .containsSession(signalProtocolAddress);
  }

  void clearSenderKey(String groupId, String senderId) {
    final senderKeyName = SenderKeyName(
        groupId, SignalProtocolAddress(senderId, defaultDeviceId));
    senderKeyStore.removeSenderKey(senderKeyName);
  }

  Future deleteSession(String userId) async {
    await mixinSignalProtocolStore.sessionStore.sessionDao
        .deleteSessionsByAddress(userId);
  }

  void processSession(String userId, PreKeyBundle preKeyBundle) {
    final signalProtocolAddress =
        SignalProtocolAddress(userId, preKeyBundle.getDeviceId());
    final sessionBuilder = SessionBuilder.fromSignalStore(
        mixinSignalProtocolStore, signalProtocolAddress);
    try {
      sessionBuilder.processPreKeyBundle(preKeyBundle);
    } on UntrustedIdentityException {
      mixinSignalProtocolStore.removeIdentity(signalProtocolAddress);
      sessionBuilder.processPreKeyBundle(preKeyBundle);
    }
  }

  Future<BlazeMessage> encryptSessionMessage(
      Message message, String recipientId,
      {String? resendMessageId,
      String? sessionId,
      List<String>? mentionData}) async {
    final cipher = await encryptSession(
        Uint8List.fromList(utf8.encode(message.content!)),
        recipientId,
        sessionId.getDeviceId());
    final data = encodeMessageData(ComposeMessageData(
        cipher.getType(), cipher.serialize(),
        resendMessageId: resendMessageId));
    final blazeParam = BlazeMessageParam(
      conversationId: message.conversationId,
      recipientId: recipientId,
      messageId: message.messageId,
      category: message.category,
      data: data,
      quoteMessageId: message.quoteMessageId,
      sessionId: sessionId,
      mentions: mentionData,
    );
    return createParamBlazeMessage(blazeParam);
  }

  Future<BlazeMessage> encryptGroupMessage(
      SendingMessage message, List<String>? mentionData) async {
    final address = SignalProtocolAddress(message.userId, defaultDeviceId);
    final senderKeyName = SenderKeyName(message.conversationId, address);
    final groupCipher = GroupCipher(senderKeyStore, senderKeyName);
    var cipher = <int>[];
    try {
      cipher = await groupCipher
          .encrypt(Uint8List.fromList(utf8.encode(message.content!)));
    } on NoSessionException catch (e) {
      debugPrint('No such session $e');
    }

    final data = encodeMessageData(ComposeMessageData(
        CiphertextMessage.SENDERKEY_TYPE, Uint8List.fromList(cipher)));
    final blazeParam = BlazeMessageParam(
      conversationId: message.conversationId,
      messageId: message.messageId,
      category: message.category,
      data: data,
      quoteMessageId: message.quoteMessageId,
      mentions: mentionData,
    );
    return createParamBlazeMessage(blazeParam);
  }

  void processGroupSession(String groupId, SignalProtocolAddress address,
      SenderKeyDistributionMessageWrapper senderKeyDM) {
    final builder = GroupSessionBuilder(senderKeyStore);
    final senderKeyName = SenderKeyName(groupId, address);
    builder.process(senderKeyName, senderKeyDM);
  }

  Future<Uint8List> decryptGroupMessage(
      String groupId,
      SignalProtocolAddress address,
      Uint8List cipherText,
      DecryptionCallback callback) async {
    final senderKeyName = SenderKeyName(groupId, address);
    final groupCipher = GroupCipher(senderKeyStore, senderKeyName);
    return groupCipher.decryptWithCallback(cipherText, callback);
  }

  String encodeMessageData(ComposeMessageData data) {
    if (data.resendMessageId == null) {
      final header = Uint8List.fromList(<int>[
        CiphertextMessage.CURRENT_VERSION,
        data.keyType,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
      final cipherText = header + data.cipher;
      return base64.encode(cipherText);
    } else {
      final header = Uint8List.fromList(<int>[
        CiphertextMessage.CURRENT_VERSION,
        data.keyType,
        1,
        0,
        0,
        0,
        0,
        0,
      ]);
      final messageId = utf8.encode(data.resendMessageId!);
      final cipherText = header + messageId + data.cipher;
      return base64.encode(cipherText);
    }
  }

  ComposeMessageData decodeMessageData(String encoded) {
    final cipherText = base64.decode(encoded);
    final header = cipherText.sublist(0, 7);
    final version = header[0].toInt();
    if (version != CiphertextMessage.CURRENT_VERSION) {
      throw InvalidMessageException('Unknown version: $version');
    }
    final dataType = header[1].toInt();
    final isResendMessage = header[2].toInt() == 1;
    if (isResendMessage) {
      final messageId = utf8.decode(cipherText.sublist(8, 43));
      final data = cipherText.sublist(44, cipherText.length - 1);
      return ComposeMessageData(dataType, data, resendMessageId: messageId);
    } else {
      final data = cipherText.sublist(8, cipherText.length - 1);
      return ComposeMessageData(dataType, data);
    }
  }
}

class ComposeMessageData {
  ComposeMessageData(this.keyType, this.cipher, {this.resendMessageId});

  final int keyType;
  final Uint8List cipher;
  final String? resendMessageId;
}
