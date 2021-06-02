import 'dart:ui';

import '../constants/brightness_theme_data.dart';
import 'string_extension.dart';

Color getNameColorById(String userId) {
  final hashCode = userId.trim().uuidHashcode();
  return nameColors[hashCode.abs() % nameColors.length];
}

Color getAvatarColorById(String userId) {
  final hashCode = userId.trim().uuidHashcode();
  return avatarColors[hashCode.abs() % avatarColors.length];
}

Color getCircleColorById(String circleId) {
  final hashCode = circleId.trim().uuidHashcode();
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
