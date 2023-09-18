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
      if (emoji != null) {
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
