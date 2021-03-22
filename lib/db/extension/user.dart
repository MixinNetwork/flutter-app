import '../mixin_database.dart';

extension UserExtension on User {
  bool get isBot => appId != null;
}
