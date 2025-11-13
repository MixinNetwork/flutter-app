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
  static final _alphaNumeric = RegExp(r'^[a-zA-Z0-9]+$');

  /// check if the string contains only letters (a-zA-Z).
  bool isAlphabet() => _alpha.hasMatch(this);

  /// check if the string contains only numbers
  bool isNumeric() => _numeric.hasMatch(this);

  /// check if the string contains only letters and numbers
  bool isAlphabetDigitsOnly() => _alphaNumeric.hasMatch(this);

  String joinWithCharacter(String char) {
    assert(char.length == 1);
    final result = StringBuffer();
    final characters = this.characters.toList();
    for (var i = 0; i < characters.length; i++) {
      final c = characters[i];
      final lookAhead = i < characters.length - 1 ? characters[i + 1] : char;
      final isSameType =
          (c.isAlphabet() && lookAhead.isAlphabet()) ||
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

  bool isNullOrBlank() => this == null || this?.trim().isEmpty == true;
}

String minOf(String a, String b) => a.compareTo(b) < 0 ? a : b;

String maxOf(String a, String b) => a.compareTo(b) > 0 ? a : b;

extension SqlStringExt on String {
  String escapeSql() => RegExp.escape(this);

  String escapeFts5({bool tokenize = true}) =>
      replaceQuotationMark()._escapeFts5Symbols(tokenize);

  String _escapeFts5Symbols(bool tokenize) {
    var tokens = split(' ').map((e) => e.trim()).where((e) => e.isNotEmpty);

    if (tokenize && kPlatformIsDarwin) {
      // use string_tokenizer to tokenize the string.
      tokens = tokens
          .map(
            (e) => string_tokenizer.tokenize(
              e,
              options: [string_tokenizer.TokenizerUnit.wordBoundary],
            ),
          )
          // to avoid some special case which will cause the tokenizer spilt the
          // number and alphabet into two tokens, we need to merge them.
          // for example: "1a" might be spilt into "1" and "a", but we need to
          // merge them into "1a".
          .map((e) => e.mergeSiblingDigitAlphabetTokens())
          .expand((e) => e);
    }

    tokens = tokens.map((e) => e.joinWhiteSpace());

    final result = StringBuffer();
    for (final token in tokens) {
      result.write('"$token"*');
    }
    return result.toString();
  }

  String joinStar() => joinWithCharacter('*');

  String joinWhiteSpace() => joinWithCharacter(' ');

  String replaceQuotationMark() => replaceAll('"', '');
}

extension StringListExtension on List<String> {
  // combine the sibling digit, alphabet tokens
  List<String> mergeSiblingDigitAlphabetTokens() {
    final result = <String>[];
    var lastIsAlphabetDigitsOnly = false;
    for (var i = 0; i < length; i++) {
      final current = this[i];
      final isAlphabetDigitsOnly = current.isAlphabetDigitsOnly();

      if (lastIsAlphabetDigitsOnly && isAlphabetDigitsOnly) {
        result.last += current;
      } else {
        result.add(current);
      }
      lastIsAlphabetDigitsOnly = isAlphabetDigitsOnly;
    }
    return result;
  }
}
