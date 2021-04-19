import 'package:uuid/uuid.dart';

extension StringExtension on String {
  String fts5ContentFilter() {
    final text = trim();
    var i = 0;
    var content = '';
    var lastFlag = false;
    while (i < text.length) {
      final spFlag = regExp.hasMatch(text[i]);
      if (lastFlag && !spFlag) {
        content += ' ';
      }
      content += text[i];
      if (!spFlag) {
        content += ' ';
      }
      lastFlag = spFlag;
      i++;
    }
    return content;
  }

  static final regExp = RegExp(r'[a-zA-Z0-9]');
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
