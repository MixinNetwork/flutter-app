import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:ulid/ulid.dart';
import 'package:uuid/uuid.dart';

extension StringExtension on String {
  String get overflow => replaceAll('', '\u{200B}').toString();

  String fts5ContentFilter() {
    final text = trim();
    var i = 0;
    final content = StringBuffer();
    var lastFlag = false;
    while (i < text.length) {
      final spFlag = regExp.hasMatch(text[i]);
      if (lastFlag && !spFlag) {
        content.write(' ');
      }
      content.write(text[i]);
      if (!spFlag) {
        content.write(' ');
      }
      lastFlag = spFlag;
      i++;
    }
    return content.toString();
  }

  String escapeSqliteSingleQuotationMarks() => replaceAll('\'', '\'\'');

  static final regExp = RegExp('[a-zA-Z0-9]');

  String md5() => crypto.md5.convert(utf8.encode(this)).toString();

  String nameUuid() {
    final md5Bytes = crypto.md5.convert(utf8.encode(this)).bytes;
    md5Bytes[6] &= 0x0f; /* clear version        */
    md5Bytes[6] |= 0x30; /* set to version 3     */
    md5Bytes[8] &= 0x3f; /* clear variant        */
    md5Bytes[8] |= 0x80;
    return UuidValue.fromList(md5Bytes).uuid;
  }

  static final RegExp _alpha = RegExp(r'^[a-zA-Z]+$');
  static final RegExp _numeric = RegExp(r'^-?[0-9]+$');

  /// check if the string contains only letters (a-zA-Z).
  bool isAlphabet() => _alpha.hasMatch(this);

  /// check if the string contains only numbers
  bool isNumeric() => _numeric.hasMatch(this);

  String joinWithCharacter(String char) {
    assert(char.length == 1);
    final result = StringBuffer();
    for (var i = 0; i < length; i++) {
      final c = this[i];
      final lookAhead = i < length - 1 ? this[i + 1] : char;
      final isSameType = (c.isAlphabet() && lookAhead.isAlphabet()) ||
          (c.isNumeric() && lookAhead.isNumeric());
      final needSpace = !isSameType && c != ' ';
      result.write(c);
      if (needSpace) {
        result.write(char);
      }
    }
    return result.toString().trim();
  }

  int uuidHashcode() {
    final components = split('-');
    assert(components.length == 5);
    final mostSigBits = (int.parse(components[0], radix: 16) << 32) |
        (int.parse(components[1], radix: 16) << 16) |
        (int.parse(components[2], radix: 16));
    final leastSigBits = (int.parse(components[3], radix: 16) << 48) |
        (int.parse(components[4], radix: 16));
    final hilo = mostSigBits ^ leastSigBits;
    final i = Uint8List(8)..buffer.asByteData().setInt64(0, hilo, Endian.big);
    final a = toInt32(i.sublist(0, 4));
    final b = toInt32(i.sublist(4, 8));
    return a ^ b;
  }
}

extension NullableStringExtension on String? {
  int getDeviceId() {
    if (this == null || this?.isEmpty == true) {
      return 1;
    }
    // this must be a valid uuid
    return Ulid.parse(this!).hashCode;
  }
}

int toInt32(Uint8List list) {
  final buffer = list.buffer;
  final data = ByteData.view(buffer);
  final short = data.getInt32(0, Endian.big);
  return short;
}

String minOf(String a, String b) {
  if (a.compareTo(b) < 0) {
    return a;
  } else {
    return b;
  }
}

String maxOf(String a, String b) {
  if (a.compareTo(b) > 0) {
    return a;
  } else {
    return b;
  }
}

const _kEscapeSqlChars = {'\\', '%', '_', '[', ']'};

extension SqlStringExt on String {
  String escapeSql() {
    var result = this;
    for (var c in _kEscapeSqlChars) {
      result = result.replaceAll(c.toString(), '\\$c');
    }
    return result;
  }

  String joinStar() => joinWithCharacter('*');

  String replaceQuotationMark() => replaceAll('"', '');
}
