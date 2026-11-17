import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_app/account/deposit_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  test('hashes with SHA3-256, not Keccak-256', () {
    // FIPS 202 test vector for "abc".
    expect(
      hex.encode(sha3Hash(Uint8List.fromList(utf8.encode('abc')))),
      '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532',
    );
  });

  final key = ed.newKeyFromSeed(Uint8List.fromList(List.filled(32, 7)));
  final publicKeys = [ed.public(key)];

  String sign(String content) => hex.encode(
    ed.sign(key, sha3Hash(Uint8List.fromList(utf8.encode(content)))),
  );

  bool isValid(String destination, String? tag, String signature) =>
      isDepositSignatureValid(
        destination: destination,
        tag: tag,
        signature: signature,
        publicKeys: publicKeys,
      );

  test('signs the destination when there is no tag', () {
    final signature = sign('addr');
    expect(isValid('addr', null, signature), isTrue);
    expect(isValid('addr', '', signature), isTrue);
    expect(isValid('addr2', null, signature), isFalse);
  });

  test('signs the destination and the tag', () {
    final signature = sign('addr:memo');
    expect(isValid('addr', 'memo', signature), isTrue);
    expect(isValid('addr', null, signature), isFalse);
    expect(isValid('addr', 'other', signature), isFalse);
  });

  test('rejects a signature that is not hex', () {
    expect(isValid('addr', null, 'zz'), isFalse);
  });

  test('rejects an entry that the deposit keys did not sign', () {
    final entry = SafeDepositEntry(
      entryId: '',
      chainId: '',
      destination: 'addr',
      members: const [],
      tag: null,
      signature: sign('addr'),
      threshold: 1,
      isPrimary: true,
    );
    expect(isDepositEntrySignatureValid(entry), isFalse);
  });

  test(
    'fetchDepositEntry does not return a primary entry with a bad signature',
    () async {
      final client = Client(
        interceptors: [
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {
                      'entry_id': 'entry',
                      'chain_id': 'chain',
                      'destination': 'addr',
                      'members': <String>[],
                      'tag': null,
                      // Signed by a key that is not a deposit key.
                      'signature': sign('addr'),
                      'threshold': 1,
                      'is_primary': true,
                    },
                  ],
                },
              ),
            ),
          ),
        ],
      );

      expect(
        await fetchDepositEntry(client, chainId: 'chain', assetId: 'asset'),
        isNull,
      );
    },
  );

  /// A client whose requests get [body] back, after the SDK's own response
  /// handling, and that counts them.
  ({Client client, int Function() count}) fakeClient(
    Map<String, dynamic> body,
  ) {
    var count = 0;
    final client = Client(
      interceptors: [
        InterceptorsWrapper(
          onRequest: (options, handler) {
            count++;
            handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: body),
              true,
            );
          },
        ),
      ],
    );
    return (client: client, count: () => count);
  }

  final badEntry = {
    'entry_id': 'entry',
    'chain_id': 'chain',
    'destination': 'addr',
    'members': <String>[],
    'tag': null,
    'signature': sign('addr'),
    'threshold': 1,
    'is_primary': true,
  };

  test(
    'fetchDepositEntryRetrying asks again while the signature is bad',
    () async {
      final fake = fakeClient({
        'data': [badEntry],
      });
      final entry = await fetchDepositEntryRetrying(
        fake.client,
        chainId: 'chain',
        assetId: 'asset',
        interval: Duration.zero,
        isActive: () => fake.count() < 3,
      );
      expect(entry, isNull);
      expect(fake.count(), 3);
    },
  );

  test('fetchDepositEntryRetrying stops at a suspended deposit', () async {
    final fake = fakeClient({
      'error': {
        'status': 202,
        'code': depositSuspendedCode,
        'description': 'address generating.',
      },
    });
    await expectLater(
      fetchDepositEntryRetrying(
        fake.client,
        chainId: 'chain',
        assetId: 'asset',
        interval: Duration.zero,
        isActive: () => fake.count() < 3,
      ),
      throwsA(isA<MixinApiError>()),
    );
    expect(fake.count(), 1);
  });
}
