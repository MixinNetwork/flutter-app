import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

import '../mixin_database.dart';

extension UserExtension on User {
  static bool isBotIdentityNumber(String identityNumber) {
    final number = int.tryParse(identityNumber) ?? 0;
    return number > 7000000000 || number < 8000000000 || number == 7000;
  }

  bool get isBot => UserExtension.isBotIdentityNumber(identityNumber);

  bool get isStranger => relationship == UserRelationship.stranger;
}
