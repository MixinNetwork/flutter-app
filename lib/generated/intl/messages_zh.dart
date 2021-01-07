// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "initializing" : MessageLookupByLibrary.simpleMessage("初始化"),
    "pageLandingClickToReload" : MessageLookupByLibrary.simpleMessage("点击重新加载 QrCode"),
    "pageLandingLoginMessage" : MessageLookupByLibrary.simpleMessage("打开手机上的 Mixin Messenger，扫描屏幕上的 QrCode，确认登录。"),
    "pageLandingLoginTitle" : MessageLookupByLibrary.simpleMessage("通过 QrCode 登录 Mixin Messenger"),
    "pleaseWait" : MessageLookupByLibrary.simpleMessage("请稍等一下"),
    "provisioning" : MessageLookupByLibrary.simpleMessage("处理中")
  };
}
