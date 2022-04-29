final mentionRegExp = RegExp(r'@(\S*)$');
final mentionNumberRegExp = RegExp(r'@(\d{4,})');
final uriRegExp = RegExp(r'[a-zA-z]+://[^\s].*?((?=["\s，）)(（。：])|$)');
final botNumberRegExp = RegExp(r'(?<=^|\D)7000\d{6}(?=$|\D)');
final mailRegExp = RegExp(
    r'[a-zA-Z0-9\+\.\_\%\-\+]{1,256}\@[a-zA-Z0-9][a-zA-Z0-9\-]{0,64}(\.[a-zA-Z0-9][a-zA-Z0-9\-]{0,25})+');
