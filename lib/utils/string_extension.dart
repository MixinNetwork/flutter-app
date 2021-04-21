import 'package:uuid/uuid.dart';

extension StringExtension on String {
  String fts5ContentFilter() {
    final text = trim();
    var i = 0;
    final content = StringBuffer();
    var lastFlag = false;
    while (i < text.length) {
      final spFlag = regExp.hasMatch(text[i]);
      if (lastFlag && !spFlag) {
        content.write(' ');
      }
      content.write(text[i]);
      if (!spFlag) {
        content.write(' ');
      }
      lastFlag = spFlag;
      i++;
    }
    return content.toString();
  }

  static final regExp = RegExp('[a-zA-Z0-9]');
}

extension NullableStringExtension on String? {
  int getDeviceId() {
    if (this == null || this?.isEmpty == true) {
      return 1;
    }
    return const Uuid().v4().hashCode;
  }
}

String minOf(String a, String b) {
  if (a.compareTo(b) < 0) {
    return a;
  } else {
    return b;
  }
}

String maxOf(String a, String b) {
  if (a.compareTo(b) > 0) {
    return a;
  } else {
    return b;
  }
}
