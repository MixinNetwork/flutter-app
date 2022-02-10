final mentionRegExp = RegExp(r'@(\S*)$');
final mentionNumberRegExp = RegExp(r'@(\d{4,})');
final uriRegExp = RegExp(r'[a-zA-z]+://[^\s].*?((?=["\s，）)(（。：])|$)');
final botNumberStartRegExp = RegExp(r'^\s*@(700\d*)');
final botNumberRegExp = RegExp(r'7000\d{6}');
