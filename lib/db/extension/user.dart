import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

import '../mixin_database.dart';

extension UserExtension on User {
  bool get isBot => appId != null;
  bool get isStranger => relationship == UserRelationship.stranger;
}
