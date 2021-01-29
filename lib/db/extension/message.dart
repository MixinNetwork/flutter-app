import 'package:flutter_app/db/mixin_database.dart';

extension Message on MessageItem {
  bool get isLottie => assetType?.toLowerCase() == 'json';
}
