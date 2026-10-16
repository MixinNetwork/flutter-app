import 'dart:ui';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/brightness_theme_data.dart';

// Rows compute the colors of their ids on each build; the hash parses the
// id, so it is kept per id.
final _uuidHashes = <String, int>{};

int _uuidHash(String id) {
  if (_uuidHashes.length >= 4096) _uuidHashes.clear();
  return _uuidHashes[id] ??= id.trim().uuidHashcode();
}

Color getNameColorById(String userId) {
  final hashCode = _uuidHash(userId);
  return nameColors[hashCode.abs() % nameColors.length];
}

Color getAvatarColorById(String userId) {
  final hashCode = _uuidHash(userId);
  return avatarColors[hashCode.abs() % avatarColors.length];
}

Color getCircleColorById(String circleId) {
  final hashCode = _uuidHash(circleId);
  return circleColors[hashCode.abs() % circleColors.length];
}

Color? colorHex(String hexString) {
  try {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return null;
  }
}
