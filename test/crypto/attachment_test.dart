import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/attachment/crypto_attachment.dart';

void main() {
  testDecryptAttachment();
  testEncryptAttachment();
  debugPrint('Done!');
}

void testDecryptAttachment() {
  // [27, -64, 111, 96, -117, 47, -74, 50, -101, -108, 112, -119, -23, -48, 35, -73, 84, -44, -114, -105, 82, 68, -65, 13, -18, 10, -48, 28, 101, -66, 107, -28, 47, 47, -7, 45, 85, 125, -121, 72, -15, -10, 84, 113, 68, 43, 39, -109, -8, 80, 5, 74, 106, 18, -63, -91, -22, -111, 85, -28, 98, 21, -104, 101];
  final encryptedBin = base64Decode(
      'G8BvYIsvtjKblHCJ6dAjt1TUjpdSRL8N7grQHGW+a+QvL/ktVX2HSPH2VHFEKyeT+FAFSmoSwaXqkVXkYhWYZQ==');
  // [94, 46, 48, 106, -39, -44, 5, 15, 110, -25, 59, -118, -85, -114, -24, -105, 3, -11, 1, 66, -69, 72, -36, 121, 96, 104, -71, 67, 81, -77, -76, 70, -81, 12, 17, -15, 50, -104, -112, 51, 93, 121, 21, 15, 79, -23, -118, 14, -88, -108, 31, 16, -79, -33, -113, -59, -108, 2, -11, 73, 111, -76, -33, -86];
  final keys = base64Decode(
      'Xi4watnUBQ9u5zuKq47olwP1AUK7SNx5YGi5Q1GztEavDBHxMpiQM115FQ9P6YoOqJQfELHfj8WUAvVJb7Tfqg==');
  // [3, -48, 108, -61, 90, 19, 10, 11, 82, 51, 4, -120, -41, -29, -18, 87, 63, -18, -14, -22, 62, 69, 67, -5, -86, -68, -83, -13, 27, -111, -78, -102];
  final theirDigest =
      base64Decode('A9Bsw1oTCgtSMwSI1+PuVz/u8uo+RUP7qryt8xuRspo=');
  // [84, 101, 115, 116, 32, 116, 101, 115, 116, 32, 116, 101, 115, 116, 10]
  final result = base64Decode('VGVzdCB0ZXN0IHRlc3QK');
  final decrypt =
      CryptoAttachment().decryptAttachment(encryptedBin, keys, theirDigest);
  assert(listEquals(decrypt, result));
}

void testEncryptAttachment() {
  // [84, 101, 115, 116, 32, 116, 101, 115, 116, 32, 116, 101, 115, 116, 10];
  final plainText = base64Decode('VGVzdCB0ZXN0IHRlc3QK');
  // [6, 86, -81, -13, 102, -19, -3, 29, -93, 80, -114, -54, -73, 55, -79, -35, 75, -14, -75, -73, -75, -21, 101, 48, -116, 14, 93, 45, -23, 65, 123, 26, 18, -33, 16, 103, 95, -60, 57, 93, 15, -13, -92, 21, 35, -62, -75, 50, -120, 31, -122, 53, -75, -24, 76, -89, 53, 51, -127, -21, -63, -86, 125, 1]
  final keys = base64Decode(
      'Blav82bt/R2jUI7Ktzex3Uvytbe162UwjA5dLelBexoS3xBnX8Q5XQ/zpBUjwrUyiB+GNbXoTKc1M4Hrwap9AQ==');
  // [83, -102, 46, 63, 100, -106, -94, -10, 15, -98, 32, 43, -22, -84, 71, 63]
  final iv = base64Decode('U5ouP2SWovYPniAr6qxHPw==');
  // [83, -102, 46, 63, 100, -106, -94, -10, 15, -98, 32, 43, -22, -84, 71, 63, -116, 110, -47, 112, -30, -70, -50, -86, -15, 99, 26, 46, -57, 97, 6, -103, -124, -8, -91, 59, 61, 30, 104, 74, 122, 107, 86, -28, 111, -113, -26, -51, -56, -53, 11, 80, 106, -44, 126, 12, 56, -22, -72, -83, 58, -62, -128, 78]
  final cipherText = base64Decode(
      'U5ouP2SWovYPniAr6qxHP4xu0XDius6q8WMaLsdhBpmE+KU7PR5oSnprVuRvj+bNyMsLUGrUfgw46ritOsKATg==');
  // [-103, -58, 63, 80, 21, 63, 107, 34, -123, 0, 18, 37, 84, -115, 66, -42, -72, 13, -40, -28, -120, 56, -24, -49, -21, -114, -67, -56, 19, -71, 121, 69
  final digest = base64Decode('mcY/UBU/ayKFABIlVI1C1rgN2OSIOOjP6469yBO5eUU=');

  final result = CryptoAttachment().encryptAttachment(plainText, keys, iv);
  assert(listEquals(cipherText, result.item1));
  assert(listEquals(digest, result.item2));
}
