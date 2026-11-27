import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/account/security_key_value.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

const _identityNumber = '1000';
const _code = '739142';

void main() {
  late Directory directory;
  final security = SecurityKeyValue.instance;

  File boxFile() => File(
    p.join(
      directory.path,
      _identityNumber,
      'security_box',
      'security_box.hive',
    ),
  );

  bool diskContains(String text) =>
      latin1.decode(boxFile().readAsBytesSync()).contains(text);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('security_box');
    mixinDocumentsDirectory = directory;
  });

  tearDown(() async {
    await security.delete();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('the passcode is never written to disk', () async {
    await security.init(_identityNumber);
    await security.setPasscode(_code);

    expect(security.hasPasscode, isTrue);
    expect(await security.verifyPasscode(_code), isTrue);
    expect(await security.verifyPasscode('000000'), isFalse);
    expect(diskContains(_code), isFalse);
  });

  test('a stored plain passcode is replaced and wiped from disk', () async {
    final boxDirectory = boxFile().parent..createSync(recursive: true);
    Hive.init(boxDirectory.path);
    final old = await Hive.openBox<dynamic>('security_box');
    await old.put('passcode', _code);
    await old.put('lockDuration', 5);
    await old.put('biometric', true);
    await old.close();
    expect(diskContains(_code), isTrue);

    await security.init(_identityNumber);

    expect(security.hasPasscode, isTrue);
    expect(await security.verifyPasscode(_code), isTrue);
    expect(await security.verifyPasscode('000000'), isFalse);
    expect(security.lockDuration, const Duration(minutes: 5));
    expect(security.biometric, isTrue);
    expect(diskContains(_code), isFalse);
  });

  test('a run that stopped before compacting is cleaned up', () async {
    final boxDirectory = boxFile().parent..createSync(recursive: true);
    Hive.init(boxDirectory.path);
    final old = await Hive.openBox<dynamic>('security_box');
    await old.put('passcode', _code);
    await old.put('passcodeVerifier', 'AAAA:AAAA');
    await old.delete('passcode');
    await old.close();
    expect(diskContains(_code), isTrue);

    await security.init(_identityNumber);

    expect(diskContains(_code), isFalse);
  });

  test('deriving the verifier does not stall the caller', () async {
    await security.init(_identityNumber);
    await security.setPasscode(_code);
    var done = false;
    var ticks = 0;
    final verification = security.verifyPasscode(_code).whenComplete(() {
      done = true;
    });
    while (!done) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      ticks++;
    }

    expect(await verification, isTrue);
    // A synchronous derivation ends before the first tick returns.
    expect(ticks, greaterThan(1));
  });

  test('a deleted account has no passcode', () async {
    await security.init(_identityNumber);
    await security.setPasscode(_code);

    // Signing out deletes the box while the lock screen guard is mounted.
    await security.delete();

    expect(security.hasPasscode, isFalse);
  });

  test('equal passcodes get different verifiers', () async {
    await security.init(_identityNumber);
    await security.setPasscode(_code);
    final first = security.box.get('passcodeVerifier') as String;
    await security.setPasscode(_code);

    expect(security.box.get('passcodeVerifier'), isNot(first));
  });

  test('removing the passcode turns the lock off', () async {
    await security.init(_identityNumber);
    await security.setPasscode(_code);
    security
      ..biometric = true
      ..lockDuration = const Duration(minutes: 5);
    final changes = <bool>[];
    final subscription = security.watchHasPasscode().listen(changes.add);
    await pumpEventQueue();

    await security.setPasscode(null);
    await pumpEventQueue();
    await subscription.cancel();

    expect(security.hasPasscode, isFalse);
    expect(await security.verifyPasscode(_code), isFalse);
    expect(security.biometric, isFalse);
    expect(security.lockDuration, const Duration(minutes: 1));
    expect(changes, [true, false]);
  });

  test('the passcode must have 6 digits', () async {
    await security.init(_identityNumber);

    await expectLater(security.setPasscode('123'), throwsArgumentError);
    expect(security.hasPasscode, isFalse);
  });

  test(
    'clearing the passcode while a write is in flight keeps it off',
    () async {
      await security.init(_identityNumber);

      final setting = security.setPasscode(_code);
      final clearing = security.setPasscode(null);
      await Future.wait([setting, clearing]);

      expect(security.hasPasscode, isFalse);
      expect(await security.verifyPasscode(_code), isFalse);
    },
  );

  test(
    'deleting the account while a write is in flight does not throw',
    () async {
      await security.init(_identityNumber);

      final setting = security.setPasscode(_code);
      await security.delete();
      await setting;

      expect(security.hasPasscode, isFalse);
    },
  );

  test(
    'a queued clear from a deleted account does not clear the next account',
    () async {
      await security.init(_identityNumber);

      final setting = security.setPasscode(_code);
      final clearing = security.setPasscode(null);
      final deleting = security.delete();
      final initNext = security.init('2000');
      final setNext = security.setPasscode('654321');
      await Future.wait([setting, clearing, deleting, initNext, setNext]);

      expect(security.box.path, contains('2000'));
      expect(security.hasPasscode, isTrue);
      expect(await security.verifyPasscode('654321'), isTrue);
    },
  );

  test(
    'a queued init from a deleted account does not reopen its box',
    () async {
      await security.init(_identityNumber);

      final setting = security.setPasscode(_code);
      final queuedInit = security.init(_identityNumber);
      await security.delete();
      await Future.wait([setting, queuedInit]);
      await security.init('2000');

      expect(security.box.path, contains('2000'));
      expect(security.hasPasscode, isFalse);
    },
  );
}
