import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart'
    hide generateIdentityKeyPair;

// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/invalid_message_exception.dart';
import 'package:uuid/uuid.dart';

import '../../blaze/blaze_message.dart';
import '../../blaze/blaze_message_param.dart';
import '../../db/dao/message_dao.dart';
import '../../enum/message_category.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import 'encrypt_result.dart';
import 'identity_key_util.dart';
import 'signal_database.dart';
import 'storage/mixin_identity_key_store.dart';
import 'storage/mixin_prekey_store.dart';
import 'storage/mixin_sender_key_store.dart';
import 'storage/mixin_session_store.dart';
import 'storage/mixin_signal_protocol_store.dart';

class SignalProtocol {
  SignalProtocol(this._accountId, this.db);

  static const int defaultDeviceId = 1;

  final String _accountId;

  final SignalDatabase db;

  late MixinSignalProtocolStore mixinSignalProtocolStore;
  late MixinSenderKeyStore senderKeyStore;

  static Future<void> initSignal(
      String identityNumber, int registrationId, List<int>? private) async {
    final db = await SignalDatabase.connect(
      identityNumber: identityNumber,
      fromMainIsolate: true,
    );
    try {
      await generateSignalDatabaseIdentityKeyPair(db, private, registrationId);
    } finally {
      await db.close();
    }
  }

  void init() {
    final preKeyStore = MixinPreKeyStore(db);
    final signedPreKeyStore = MixinPreKeyStore(db);
    final identityKeyStore = MixinIdentityKeyStore(db, _accountId);
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
        await getSenderKeyDistribution(conversationId, _accountId);
    try {
      final cipherMessage = await encryptSession(
          senderKeyDistributionMessage.serialize(), recipientId, deviceId);
      final compose = ComposeMessageData(
          cipherMessage.getType(), cipherMessage.serialize());
      final cipher = encodeMessageData(compose);
      return EncryptResult(cipher, false);
    } on UntrustedIdentityException {
      final remoteAddress = SignalProtocolAddress(recipientId, deviceId);
      await mixinSignalProtocolStore.removeIdentity(remoteAddress);
      await mixinSignalProtocolStore.deleteSession(remoteAddress);
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

  Future<void> decrypt(
      String groupId,
      String senderId,
      int dataType,
      Uint8List cipherText,
      String category,
      String? sessionId,
      DecryptionCallback callback) async {
    final address = SignalProtocolAddress(senderId, sessionId.getDeviceId());
    final sessionCipher =
        SessionCipher.fromStore(mixinSignalProtocolStore, address);
    d('decrypt category: $category, dataType: $dataType');
    if (category == MessageCategory.signalKey) {
      if (dataType == CiphertextMessage.prekeyType) {
        await sessionCipher.decryptWithCallback(PreKeySignalMessage(cipherText),
            (plainText) {
          processGroupSession(groupId, address,
              SenderKeyDistributionMessageWrapper.fromSerialized(plainText));
          callback.call(plainText);
        });
      } else if (dataType == CiphertextMessage.whisperType) {
        await sessionCipher.decryptFromSignalWithCallback(
            SignalMessage.fromSerialized(cipherText), (plaintext) {
          processGroupSession(groupId, address,
              SenderKeyDistributionMessageWrapper.fromSerialized(plaintext));
          callback.call(plaintext);
        });
      }
    } else {
      if (dataType == CiphertextMessage.prekeyType) {
        await sessionCipher.decryptWithCallback(
            PreKeySignalMessage(cipherText), callback);
      } else if (dataType == CiphertextMessage.whisperType) {
        await sessionCipher.decryptFromSignalWithCallback(
            SignalMessage.fromSerialized(cipherText), callback);
      } else if (dataType == CiphertextMessage.senderKeyType) {
        await decryptGroupMessage(groupId, address, cipherText, callback);
      } else {
        throw InvalidMessageException('Unknown type: $dataType');
      }
    }
  }

  Future<bool> isExistSenderKey(String groupId, String senderId) async {
    final senderKeyName = SenderKeyName(
        groupId, SignalProtocolAddress(senderId, defaultDeviceId));
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
    return mixinSignalProtocolStore.containsSession(signalProtocolAddress);
  }

  Future<void> clearSenderKey(String groupId, String senderId) async {
    final senderKeyName = SenderKeyName(
        groupId, SignalProtocolAddress(senderId, defaultDeviceId));
    await senderKeyStore.removeSenderKey(senderKeyName);
  }

  Future<void> deleteSession(String userId) async {
    await mixinSignalProtocolStore.sessionStore.sessionDao
        .deleteSessionsByAddress(userId);
  }

  Future<void> processSession(String userId, PreKeyBundle preKeyBundle) async {
    final signalProtocolAddress =
        SignalProtocolAddress(userId, preKeyBundle.getDeviceId());
    final sessionBuilder = SessionBuilder.fromSignalStore(
        mixinSignalProtocolStore, signalProtocolAddress);
    try {
      await sessionBuilder.processPreKeyBundle(preKeyBundle);
    } on UntrustedIdentityException {
      await mixinSignalProtocolStore.removeIdentity(signalProtocolAddress);
      await sessionBuilder.processPreKeyBundle(preKeyBundle);
    }
  }

  Future<BlazeMessage> encryptSessionMessage(
    SendingMessage message,
    String recipientId, {
    String? resendMessageId,
    String? sessionId,
    List<String>? mentionData,
    bool silent = false,
    int expireIn = 0,
  }) async {
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
      messageId: const Uuid().v4(),
      category: message.category,
      data: data,
      quoteMessageId: message.quoteMessageId,
      sessionId: sessionId,
      mentions: mentionData,
      silent: silent,
      expireIn: expireIn,
    );
    return createParamBlazeMessage(blazeParam);
  }

  Future<BlazeMessage> encryptGroupMessage(
    SendingMessage message,
    List<String>? mentionData, {
    bool silent = false,
    int expireIn = 0,
  }) async {
    final address = SignalProtocolAddress(message.userId, defaultDeviceId);
    final senderKeyName = SenderKeyName(message.conversationId, address);
    final groupCipher = GroupCipher(senderKeyStore, senderKeyName);
    var cipher = <int>[];
    try {
      cipher = await groupCipher
          .encrypt(Uint8List.fromList(utf8.encode(message.content!)));
    } on NoSessionException catch (e) {
      w('No such session $e');
    }

    final data = encodeMessageData(ComposeMessageData(
        CiphertextMessage.senderKeyType, Uint8List.fromList(cipher)));
    final blazeParam = BlazeMessageParam(
      conversationId: message.conversationId,
      messageId: message.messageId,
      category: message.category,
      data: data,
      quoteMessageId: message.quoteMessageId,
      mentions: mentionData,
      silent: silent,
      expireIn: expireIn,
    );
    return createParamBlazeMessage(blazeParam);
  }

  Future<void> processGroupSession(
      String groupId,
      SignalProtocolAddress address,
      SenderKeyDistributionMessageWrapper senderKeyDM) async {
    final builder = GroupSessionBuilder(senderKeyStore);
    final senderKeyName = SenderKeyName(groupId, address);
    await builder.process(senderKeyName, senderKeyDM);
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
        CiphertextMessage.currentVersion,
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
        CiphertextMessage.currentVersion,
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
    final header = cipherText.sublist(0, 8);
    final version = header.first;
    if (version != CiphertextMessage.currentVersion) {
      throw InvalidMessageException('Unknown version: $version');
    }
    final dataType = header[1];
    final isResendMessage = header[2] == 1;
    if (isResendMessage) {
      final messageId =
          utf8.decode(cipherText.sublist(8, 44), allowMalformed: true);
      final data = cipherText.sublist(44, cipherText.length);
      return ComposeMessageData(dataType, data, resendMessageId: messageId);
    } else {
      final data = cipherText.sublist(8, cipherText.length);
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
