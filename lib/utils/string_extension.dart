import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/widgets.dart';
import 'package:ulid/ulid.dart';
import 'package:uuid/uuid.dart';

extension StringExtension on String {
  String get overflow => Characters(this)
      .replaceAll(Characters(''), Characters('\u{200B}'))
      .toString();

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

  String joinWhiteSpace() => joinWithCharacter(' ');

  String replaceQuotationMark() => replaceAll('"', '');
}
