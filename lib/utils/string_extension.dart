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
