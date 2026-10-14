import 'dart:io';

import 'package:emojis/emoji.dart';
import 'package:flutter/cupertino.dart';

import 'platform.dart';
import 'system/windows.dart';

final _emojis = Map.fromEntries(Emoji.all().map((e) => MapEntry(e.char, e)));

final kEmojiFontFamily = () {
  if (kPlatformIsDarwin) {
    return 'Apple Color Emoji';
  } else if (Platform.isWindows) {
    if (isWindows10OrGreater()) {
      return 'Segoe UI Emoji';
    } else {
      return 'NotoColorEmoji';
    }
  } else {
    return 'NotoColorEmoji';
  }
}();

/// Whether [text] may hold an emoji that text fonts also draw: a symbol from
/// the Basic Multilingual Plane, or the emoji presentation selector.
///
/// Only such emoji need the emoji font set on their span. Other emoji are not
/// in text fonts and reach the emoji font through the theme's
/// fontFamilyFallback, and a span with its own font family makes paragraph
/// layout several times slower.
bool mayContainTextStyleEmoji(String text) {
  for (final unit in text.codeUnits) {
    if ((unit >= 0x203C && unit <= 0x2BFF) ||
        unit == 0xFE0F ||
        unit == 0xA9 ||
        unit == 0xAE ||
        unit == 0x3030 ||
        unit == 0x303D ||
        unit == 0x3297 ||
        unit == 0x3299) {
      return true;
    }
  }
  return false;
}

/// Whether [emoji] starts with a symbol that text fonts may draw as text.
bool isTextStyleEmoji(String emoji) =>
    emoji.isNotEmpty && emoji.codeUnitAt(0) < 0xD800;

List<String> extractEmoji(String text) {
  final characters = Characters(text);
  final emojis = <String>[];
  for (final char in characters) {
    final emoji = _emojis[char];
    if (emoji != null) {
      emojis.add(emoji.char);
    }
  }
  return emojis;
}

extension EmojiExtension on String {
  void splitEmoji({
    required void Function(String) onEmoji,
    required void Function(String) onText,
  }) {
    final characters = Characters(this);
    final buffer = StringBuffer();
    for (final char in characters) {
      final emoji = _emojis[char];
      if (emoji != null && isTextStyleEmoji(emoji.char)) {
        if (buffer.isNotEmpty) {
          onText(buffer.toString());
          buffer.clear();
        }
        onEmoji(emoji.char);
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) {
      onText(buffer.toString());
    }
  }
}
