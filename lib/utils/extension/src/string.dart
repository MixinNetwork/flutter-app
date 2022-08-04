part of '../extension.dart';

extension StringExtension on String {
  String get overflow => Characters(this)
      // ignore: avoid-non-ascii-symbols
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

  String escapeSqliteSingleQuotationMarks() => replaceAll("'", "''");

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

String minOf(String a, String b) => a.compareTo(b) < 0 ? a : b;

String maxOf(String a, String b) => a.compareTo(b) > 0 ? a : b;

extension SqlStringExt on String {
  String escapeSql() => RegExp.escape(this);

  String escapeFts5() => replaceQuotationMark()._escapeFts5Symbols();

  String _escapeFts5Symbols() {
    final result = <String>[];

    final buffer = StringBuffer();

    var lastIsGroup = false;
    for (final char in characters) {
      final runes = char.codeUnits;
      assert(runes.isNotEmpty, '$char is not a valid character');
      final first = runes.first;
      if ((first >= 0x2E80 && first <= 0xA4CF) || // // cjk
              (first >= 0xAC00 && first <= 0xD7AF) || // hangul
              (first >= 0x0E00 && first <= 0x0E7F) || // thai
              (first >= 0x0E80 && first <= 0x0EFF) || // Lao
              (first >= 0x0F00 && first <= 0x0FFF) || // Tibetan
              (first >= 0x1000 && first <= 0x109F) || // Myanmar
              (first >= 0x1780 && first <= 0x17FF) || // Khmer
              (first >= 0x1100 && first <= 0x11FF) || // Hangul Jamo
              (first >= 0xA900 && first <= 0xA92F) || // Kayah Li
              (first >= 0xA930 && first <= 0xA95F) || // Rejang
              (first >= 0xA960 && first <= 0xA97F) || // Hangul Jamo Extended-A
              (first >= 0xA9E0 && first <= 0xA9FF) || // Myanmar Extended-B
              (first >= 0xAA60 && first <= 0xAA7F) || // Myanmar Extended-A
              (first >= 0xAC00 && first <= 0xD7AF) || // Hangul Syllables
              (first >= 0xD7B0 && first <= 0xD7FF) || // Hangul Jamo Extended-B
              (first >= 0xF900 &&
                  first <= 0xFAFF) || // CJK Compatibility Ideographs
              (first >= 0xFE30 && first <= 0xFE4F) // CJK Compatibility Forms
          ) {
        if (buffer.isNotEmpty) {
          result.add(buffer.toString());
          buffer.clear();
        }
        result.add(char);
        lastIsGroup = false;
        continue;
      } else {
        if (lastIsGroup) {
          assert(buffer.isNotEmpty, 'buffer is empty');
        }
        buffer.write(char);
        lastIsGroup = true;
        continue;
      }
    }
    if (buffer.isNotEmpty) {
      result.add(buffer.toString());
    }
    return '${result.map((e) => '"$e"').join('*')}*';
  }

  String joinStar() => joinWithCharacter('*');

  String joinWhiteSpace() => joinWithCharacter(' ');

  String replaceQuotationMark() => replaceAll('"', '');
}
