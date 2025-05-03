@TestOn('linux || mac-os')
@Timeout(Duration(minutes: 1))
library;

import 'dart:async' show Completer, Future;
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/utils/attachment/attachment_util.dart';
import 'package:flutter_app/utils/device_transfer/device_transfer_receiver.dart';
import 'package:flutter_app/utils/device_transfer/device_transfer_sender.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

const List<Asset> assets = [
  Asset(
    assetId: 'BTC',
    symbol: 'BTC',
    name: 'Bitcoin',
    iconUrl: 'https://example.com/btc.png',
    balance: '2.5',
    destination: '15sYbVpRh6dyWycZMwPdxJWD4xbfxReeHe',
    priceBtc: '1.0',
    priceUsd: '32000.00',
    chainId: 'BTC',
    changeUsd: '1.0',
    changeBtc: '0.1',
    confirmations: 3,
  ),
  Asset(
    assetId: 'ETH',
    symbol: 'ETH',
    name: 'Ethereum',
    iconUrl: 'https://example.com/eth.png',
    balance: '10.0',
    destination: '0x1abc...',
    priceBtc: '0.05',
    priceUsd: '2500.00',
    chainId: 'ETH',
    changeUsd: '0.5',
    changeBtc: '0.01',
    confirmations: 12,
  ),
  Asset(
    assetId: 'DOGE',
    symbol: 'DOGE',
    name: 'Dogecoin',
    iconUrl: 'https://example.com/doge.png',
    balance: '100000.0',
    destination: 'DTqYmyq2dKjMw1WWniuqcMSeLThpRc1ZbD',
    priceBtc: '0.000001',
    priceUsd: '0.30',
    chainId: 'DOGE',
    changeUsd: '-0.1',
    changeBtc: '-0.000001',
    confirmations: 6,
  ),
];

final List<Message> messages = [
  Message(
    messageId: '1',
    conversationId: '1001',
    userId: 'user1',
    category: 'text',
    content: 'Hello, how are you?',
    status: sdk.MessageStatus.sent,
    createdAt: DateTime.now(),
  ),
  Message(
    messageId: '2',
    conversationId: '1002',
    userId: 'user2',
    category: 'image',
    mediaUrl: 'https://example.com/image.jpg',
    mediaMimeType: 'image/jpeg',
    mediaSize: 1024 * 1024,
    mediaWidth: 640,
    mediaHeight: 480,
    mediaStatus: MediaStatus.done,
    status: sdk.MessageStatus.sending,
    createdAt: DateTime.now(),
    caption: 'A beautiful sunset',
  ),
  Message(
    messageId: '3',
    conversationId: '1003',
    userId: 'user1',
    category: 'quote',
    status: sdk.MessageStatus.read,
    createdAt: DateTime.now(),
    quoteMessageId: '2',
    quoteContent: 'A beautiful sunset',
  ),
];

extension _DatabasePreset on Database {
  void addTestData(String currentUserId) {
    for (final asset in assets) {
      assetDao.insertAsset(asset);
    }
    for (final message in messages) {
      messageDao.insert(message, currentUserId);
    }
  }
}

class _SlowDeviceTransferSender extends DeviceTransferSender {
  _SlowDeviceTransferSender({
    required super.database,
    required super.attachmentUtil,
    required super.protocolTempFileDir,
    required super.deviceId,
    super.onSenderProgressUpdate,
    super.onSenderStart,
    super.onSenderSucceed,
    super.onSenderFailed,
  });

  @override
  Future<void> onPacketSend() {
    super.onPacketSend();
    return Future.delayed(const Duration(milliseconds: 200));
  }
}

void main() {
  setUpAll(() {
    mixinDocumentsDirectory = Directory(
      p.join(Directory.systemTemp.path, 'test'),
    );
    EventBus.initialize();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    ansiColorDisabled = false;
  });

  late Database receiverDatabase;
  late Database senderDatabase;

  var receiverStartCount = 0;
  var receiverSucceedCount = 0;
  var receiverFailedCount = 0;
  var senderStartCount = 0;
  var senderSucceedCount = 0;
  var senderFailedCount = 0;

  late DeviceTransferReceiver receiver;
  late DeviceTransferSender sender;

  final receiverProgress = <double>[];
  final senderProgress = <double>[];

  late Completer<void> receiverCompleter;
  late Completer<void> senderCompleter;

  late Completer<void> receiverStartCompleter;
  late Completer<void> senderStartCompleter;

  setUp(() {
    receiverDatabase = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );

    final userId = const Uuid().v4();
    const identifyNumber = '10000';
    final receiverDeviceId = const Uuid().v4();

    receiverCompleter = Completer();
    senderCompleter = Completer();

    receiverStartCompleter = Completer();
    senderStartCompleter = Completer();

    receiver = DeviceTransferReceiver(
      userId: userId,
      database: receiverDatabase,
      attachmentUtil: AttachmentUtilBase.of(identifyNumber),
      protocolTempFileDir: p.join(mixinDocumentsDirectory.path, 'receive_temp'),
      deviceId: receiverDeviceId,
      onReceiverStart: () {
        receiverStartCount++;
        receiverStartCompleter.complete();
      },
      onReceiverSucceed: () {
        receiverSucceedCount++;
        receiverCompleter.complete();
      },
      onReceiverFailed: () {
        receiverFailedCount++;
        receiverCompleter.complete();
      },
      onReceiverProgressUpdate: receiverProgress.add,
    );

    senderDatabase = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    )..addTestData(userId);
    final senderDeviceId = const Uuid().v4();

    sender = _SlowDeviceTransferSender(
      database: senderDatabase,
      attachmentUtil: AttachmentUtilBase.of(identifyNumber),
      protocolTempFileDir: '',
      deviceId: senderDeviceId,
      onSenderStart: () {
        senderStartCount++;
        senderStartCompleter.complete();
      },
      onSenderSucceed: () {
        senderSucceedCount++;
        senderCompleter.complete();
      },
      onSenderFailed: () {
        senderFailedCount++;
        senderCompleter.complete();
      },
      onSenderProgressUpdate: senderProgress.add,
    );
  });

  tearDown(() async {
    receiver.close();
    await sender.close();
    await receiverCompleter.future;
    await senderCompleter.future;
    receiverProgress.clear();
    senderProgress.clear();
    receiverStartCount = 0;
    receiverSucceedCount = 0;
    receiverFailedCount = 0;
    senderStartCount = 0;
    senderSucceedCount = 0;
    senderFailedCount = 0;
  });

  test('test receiver', () async {
    const verificationCode = 1231;
    final (port, secretKey) = await sender.startServerSocket(verificationCode);
    d('startServerSocket: $port');
    expect(senderStartCount, 0);
    await receiver.connectToServer(
      'localhost',
      port,
      verificationCode,
      secretKey,
    );

    await senderStartCompleter.future;
    expect(senderStartCount, 1);
    expect(senderFailedCount, 0);
    expect(senderSucceedCount, 0);

    await receiverStartCompleter.future;
    expect(receiverStartCount, 1);
    expect(receiverFailedCount, 0);
    expect(receiverSucceedCount, 0);

    await senderCompleter.future;
    expect(senderStartCount, 1);
    expect(senderFailedCount, 0);
    expect(senderSucceedCount, 1);
    expect(senderProgress.first, 0);
    expect(senderProgress.last, 100);

    await receiverCompleter.future;
    expect(receiverStartCount, 1);
    expect(receiverFailedCount, 0);
    expect(receiverSucceedCount, 1);
    expect(receiverProgress.first, 0);
    expect(receiverProgress.last, 100);

    d('senderProgress: $senderProgress');
    d('receiverProgress: $receiverProgress');
  });

  test('connect with wrong verification code', () async {
    const verificationCode = 1232;
    final (port, secretKey) = await sender.startServerSocket(verificationCode);
    d('startServerSocket: $port');
    expect(senderStartCount, 0);
    await receiver.connectToServer(
      'localhost',
      port,
      verificationCode + 1,
      secretKey,
    );

    await receiverCompleter.future;

    await sender.close(debugReason: 'test');
    await senderCompleter.future;

    expect(senderStartCount, 0);
    expect(senderFailedCount, 1);
    expect(senderSucceedCount, 0);

    expect(receiverStartCount, 0);
    expect(receiverFailedCount, 1);
    expect(receiverSucceedCount, 0);
  });

  test('connected but sender close', () async {
    const verificationCode = 1233;
    final (port, secretKey) = await sender.startServerSocket(verificationCode);
    d('startServerSocket: $port');
    expect(senderStartCount, 0);
    await receiver.connectToServer(
      'localhost',
      port,
      verificationCode,
      secretKey,
    );

    await receiverStartCompleter.future;
    await senderStartCompleter.future;

    expect(senderStartCount, 1);
    expect(senderFailedCount, 0);
    expect(senderSucceedCount, 0);

    expect(receiverStartCount, 1);
    expect(receiverFailedCount, 0);
    expect(receiverSucceedCount, 0);

    await sender.close();
    await senderCompleter.future;
    await receiverCompleter.future;

    expect(senderStartCount, 1);
    expect(senderFailedCount, 1);
    expect(senderSucceedCount, 0);

    expect(receiverStartCount, 1);
    expect(receiverFailedCount, 1);
    expect(receiverSucceedCount, 0);
  });

  test('connected but receiver close', () async {
    const verificationCode = 1234;
    final (port, secretKey) = await sender.startServerSocket(verificationCode);
    d('startServerSocket: $port');
    expect(senderStartCount, 0);
    await receiver.connectToServer(
      'localhost',
      port,
      verificationCode,
      secretKey,
    );

    await senderStartCompleter.future;
    expect(senderStartCount, 1);
    expect(senderFailedCount, 0);
    expect(senderSucceedCount, 0);

    await receiverStartCompleter.future;
    expect(receiverStartCount, 1);
    expect(receiverFailedCount, 0);
    expect(receiverSucceedCount, 0);

    receiver.close();

    await receiverCompleter.future;

    expect(receiverStartCount, 1);
    expect(receiverFailedCount, 1);
    expect(receiverSucceedCount, 0);

    await senderCompleter.future;

    expect(senderStartCount, 1);
    expect(senderFailedCount, 1);
    expect(senderSucceedCount, 0);
  });
}
