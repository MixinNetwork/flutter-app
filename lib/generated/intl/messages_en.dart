// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "initializing" : MessageLookupByLibrary.simpleMessage("Initializing"),
    "pageLandingClickToReload" : MessageLookupByLibrary.simpleMessage("CLICK TO RELOAD QR CODE"),
    "pageLandingLoginMessage" : MessageLookupByLibrary.simpleMessage("Open Mixin Messenger on your phone, scan the qr code on the screen and confirm your login."),
    "pageLandingLoginTitle" : MessageLookupByLibrary.simpleMessage("Login to Mixin Messenger by QR Code"),
    "pleaseWait" : MessageLookupByLibrary.simpleMessage("Please wait a moment"),
    "provisioning" : MessageLookupByLibrary.simpleMessage("Provisioning")
  };
}
