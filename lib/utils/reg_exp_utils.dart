final mentionRegExp = RegExp(r'@(\S*)$');
final mentionNumberRegExp = RegExp(r'@(\d{4,})');
// ignore: avoid-non-ascii-symbols
final uriRegExp = RegExp(r'[a-zA-z]+://\S.*?((?=["\s，）)(（。：])|$)');
final botNumberRegExp = RegExp(r'(?<=^|\D)7000\d{6}(?=$|\D)');
final mailRegExp = RegExp(
    r'[a-zA-Z\d_.%+\-]{1,256}@[a-zA-Z\d][a-zA-Z\d\-]{0,64}(\.[a-zA-Z\d][a-zA-Z\d\-]{0,25})+');
final numberRegExp = RegExp(r'\d{4,}');
