import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

const int blockSize = 16;
const int aesKeySize = 32;
const int macKeySize = 32;

class CryptoDecryptor {
  Future createFromAttachment(File file, int plaintextLength, List<int> keys, List<int>? digest) async {
   final aesKey = keys.sublist(0, aesKeySize);
   final macKey = keys.sublist(aesKeySize, aesKeySize + macKeySize);
   final hmac = crypto.Hmac(crypto.sha256, macKey);

   // check mac len

   if (digest == null) {
     throw InvalidKeyException('Missing digest!');
   }

   final fileStream = file.openRead();
   fileStream.transform(StreamTransformer.fromHandlers(
       handleData: (data, sink) {

       }
   ));
  }

  Future verifyMac(Stream<List<int>> stream, int length, crypto.Hmac hmac, List<int> theirDigest) async {
    final digest = crypto.sha256;
    final macOutput = AccumulatorSink<crypto.Digest>();
    final macInput = hmac.startChunkedConversion(macOutput);
    final digestOutput = AccumulatorSink<crypto.Digest>();
    final digestInput = digest.startChunkedConversion(digestOutput);

    await stream.transform(StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          macInput.add(data);
          digestInput.add(data);
        },
        handleDone: (sink) {
        }
    ));
    macInput.close();
    digestInput.close();
    final ourMac = macOutput.events.single.bytes;
    final ourDigest = digestOutput.events.single.bytes;

  }
}