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
