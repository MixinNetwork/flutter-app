import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_app/account/deposit_entry.dart';
import 'package:flutter_test/flutter_test.dart';

// The fixture holds the verdict of the iOS code for each case; see its
// `source`. The desktop check must give the same verdict.
void main() {
  final fixture =
      jsonDecode(
            File(
              'test/account/deposit_entry_ios_vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final publicKeys = [
    ed.PublicKey(hex.decode(fixture['public_key'] as String)),
  ];

  for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    test('matches iOS: ${c['name']}', () {
      expect(
        isDepositSignatureValid(
          destination: c['destination'] as String,
          tag: c['tag'] as String?,
          signature: c['signature'] as String,
          publicKeys: publicKeys,
        ),
        c['ios_valid'],
      );
    });
  }
}
