import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:ulid/ulid.dart';

extension StringExtension on String {
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

  static final regExp = RegExp('[a-zA-Z0-9]');

  String md5() => crypto.md5.convert(utf8.encode(this)).toString();
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
