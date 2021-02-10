import 'dart:ui';

import 'package:flutter_app/constants.dart';
import 'package:uuid/uuid.dart';

Color getNameColorById(String userId) {
  final hashCode = Uuid().parse(userId).hashCode;
  return nameColors[hashCode % nameColors.length];
}

Color getAvatarColorById(String userId) {
  final hashCode = Uuid().parse(userId).hashCode;
  return avatarColors[hashCode % avatarColors.length];
}

Color getCircleColorById(String circleId) {
  final hashCode = Uuid().parse(circleId).hashCode;
  return circleColors[hashCode % circleColors.length];
}

Color colorHex(String hexString) {
  try {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return null;
  }
}
