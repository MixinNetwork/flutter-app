import 'package:mixin_logger/mixin_logger.dart';

import '../mixin_database.dart';

List<String>? _parseFromString(String? content) {
  if (content == null) {
    return null;
  }
  try {
    var str = content.trim();
    if (str.startsWith('[')) {
      str = str.substring(1);
    }
    if (str.endsWith(']')) {
      str = str.substring(0, str.length - 1);
    }
    return str
        .trim()
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
  } catch (error, stacktrace) {
    e('parseFromString error: $error, stacktrace: $stacktrace');
    return null;
  }
}

extension AppExt on App {
  List<String>? get capabilitiesList => _parseFromString(capabilities);

  List<String>? get resourcePatternsList => _parseFromString(resourcePatterns);
}
