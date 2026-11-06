import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

// The keys that sign deposit entries. Android and iOS use the same keys.
final _depositEntryPublicKeys = [
  '8f94e89d03fa128a7081c5fe73c6814010c5ca74438411a42df87c6023dfa94d',
  '2dc073588908a02284197ad78fc863e83c760dabcd5d9a508e09a799ebc1ecb8',
].map((key) => ed.PublicKey(hex.decode(key))).toList();

/// Whether one of the deposit keys signed the destination and the tag of
/// [entry]. A client must not show an entry that fails this check, because
/// the server response alone does not prove that the address is ours.
bool isDepositEntrySignatureValid(SafeDepositEntry entry) =>
    isDepositSignatureValid(
      destination: entry.destination,
      tag: entry.tag,
      signature: entry.signature,
      publicKeys: _depositEntryPublicKeys,
    );

bool isDepositSignatureValid({
  required String destination,
  required String? tag,
  required String signature,
  required List<ed.PublicKey> publicKeys,
}) {
  final content = tag == null || tag.isEmpty
      ? destination
      : '$destination:$tag';
  final hash = sha3Hash(Uint8List.fromList(utf8.encode(content)));
  final Uint8List signatureBytes;
  try {
    signatureBytes = Uint8List.fromList(hex.decode(signature));
  } on FormatException {
    return false;
  }
  return publicKeys.any((key) => ed.verify(key, hash, signatureBytes));
}

/// Returns the primary deposit entry of [chainId] for [assetId], or null when
/// no primary entry has a valid signature.
Future<SafeDepositEntry?> fetchDepositEntry(
  Client client, {
  required String chainId,
  required String assetId,
}) async {
  final entries = (await client.utxoApi.createSafeDepositEntries(
    chainId: chainId,
    assetId: assetId,
  )).data;
  return entries
      .where(isDepositEntrySignatureValid)
      .firstWhereOrNull((e) => e.isPrimary);
}
