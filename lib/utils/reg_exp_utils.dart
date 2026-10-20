final mentionRegExp = RegExp(r'@(\S*)$');
final mentionNumberRegExp = RegExp(r'@(\d{4,})');
final uriRegExp = RegExp(
  r'\b[a-zA-z+]+:(?://)?[\w-]+(?:\.[\w-]+)*(?:[\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?\b/?',
);
final botNumberRegExp = RegExp(r'(?<!\d)7000\d{6}(?!\d)');
final mailRegExp = RegExp(r'\b[\w.%+-]+@[\w.-]+\.[A-Za-z]{2,}\b');
final numberRegExp = RegExp(r'^\d{4,}$');
