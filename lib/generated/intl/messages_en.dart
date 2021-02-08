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

  static m0(name, addedName) => "${name} added ${addedName}";

  static m1(name, groupName) => "${name} created group ${groupName}";

  static m2(name) => "${name} left";

  static m3(name) => "${name} joined the group via invite link";

  static m4(name, removedName) => "${name} removed ${removedName}";

  static m5(name) => "Waiting for ${name} to get online and establish an encrypted session.";

  static m6(name) => "Do you want to delete ${name} circle?";

  static m7(date) => "${date} join";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "about" : MessageLookupByLibrary.simpleMessage("About"),
    "aboutEncryptedInfo" : MessageLookupByLibrary.simpleMessage("Messages to this conversation are encrypted end-to-end, tap for more info."),
    "aboutEncryptedInfoUrl" : MessageLookupByLibrary.simpleMessage("https://mixin.one/pages/1000007"),
    "addContact" : MessageLookupByLibrary.simpleMessage("Add contact"),
    "appearance" : MessageLookupByLibrary.simpleMessage("Appearance"),
    "audio" : MessageLookupByLibrary.simpleMessage("Audio"),
    "block" : MessageLookupByLibrary.simpleMessage("Block"),
    "botInteractHi" : MessageLookupByLibrary.simpleMessage("Say hi"),
    "botInteractInfo" : MessageLookupByLibrary.simpleMessage("Click the button to interact with the bot"),
    "botInteractOpen" : MessageLookupByLibrary.simpleMessage("Open Home page"),
    "bots" : MessageLookupByLibrary.simpleMessage("Bots"),
    "cancel" : MessageLookupByLibrary.simpleMessage("Cancel"),
    "chatBackup" : MessageLookupByLibrary.simpleMessage("Chat Backup"),
    "chatGroupAdd" : m0,
    "chatGroupCreate" : m1,
    "chatGroupExit" : m2,
    "chatGroupJoin" : m3,
    "chatGroupRemove" : m4,
    "chatGroupRole" : MessageLookupByLibrary.simpleMessage("You\'re now an admin"),
    "chatLearn" : MessageLookupByLibrary.simpleMessage("Learn more"),
    "chatNotSupport" : MessageLookupByLibrary.simpleMessage("This type of message is not supported, please upgrade Mixin to the latest version."),
    "chatNotSupportUrl" : MessageLookupByLibrary.simpleMessage("https://mixinmessenger.zendesk.com/hc/articles/360043776071"),
    "chatWaiting" : m5,
    "chatWaitingDesktop" : MessageLookupByLibrary.simpleMessage("desktop"),
    "circle" : MessageLookupByLibrary.simpleMessage("Circle"),
    "contact" : MessageLookupByLibrary.simpleMessage("Contact"),
    "contacts" : MessageLookupByLibrary.simpleMessage("Contacts"),
    "copy" : MessageLookupByLibrary.simpleMessage("Copy"),
    "dataAndStorageUsage" : MessageLookupByLibrary.simpleMessage("Data and Storage Usage"),
    "delete" : MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteChat" : MessageLookupByLibrary.simpleMessage("Delete Chat"),
    "deleteCircle" : MessageLookupByLibrary.simpleMessage("Delete Circle"),
    "editCircleName" : MessageLookupByLibrary.simpleMessage("Edit Circle Name"),
    "editConversations" : MessageLookupByLibrary.simpleMessage("Edit Conversations"),
    "editProfile" : MessageLookupByLibrary.simpleMessage("Edit Profile"),
    "file" : MessageLookupByLibrary.simpleMessage("File"),
    "forward" : MessageLookupByLibrary.simpleMessage("Forward"),
    "group" : MessageLookupByLibrary.simpleMessage("Group"),
    "image" : MessageLookupByLibrary.simpleMessage("Image"),
    "initializing" : MessageLookupByLibrary.simpleMessage("Initializing"),
    "introduction" : MessageLookupByLibrary.simpleMessage("Introduction"),
    "live" : MessageLookupByLibrary.simpleMessage("Live"),
    "location" : MessageLookupByLibrary.simpleMessage("Location"),
    "mute" : MessageLookupByLibrary.simpleMessage("Mute"),
    "name" : MessageLookupByLibrary.simpleMessage("Name"),
    "noData" : MessageLookupByLibrary.simpleMessage("NO DATA"),
    "notification" : MessageLookupByLibrary.simpleMessage("Notification"),
    "pageDeleteCircle" : m6,
    "pageEditProfileJoin" : m7,
    "pageLandingClickToReload" : MessageLookupByLibrary.simpleMessage("CLICK TO RELOAD QR CODE"),
    "pageLandingLoginMessage" : MessageLookupByLibrary.simpleMessage("Open Mixin Messenger on your phone, scan the qr code on the screen and confirm your login."),
    "pageLandingLoginTitle" : MessageLookupByLibrary.simpleMessage("Login to Mixin Messenger by QR Code"),
    "pageRightEmptyMessage" : MessageLookupByLibrary.simpleMessage("Select a conversation to start messaging"),
    "phoneNumber" : MessageLookupByLibrary.simpleMessage("Phone number"),
    "pin" : MessageLookupByLibrary.simpleMessage("Pin"),
    "pleaseWait" : MessageLookupByLibrary.simpleMessage("Please wait a moment"),
    "preview" : MessageLookupByLibrary.simpleMessage("Preview"),
    "provisioning" : MessageLookupByLibrary.simpleMessage("Provisioning"),
    "reply" : MessageLookupByLibrary.simpleMessage("Reply"),
    "save" : MessageLookupByLibrary.simpleMessage("Save"),
    "search" : MessageLookupByLibrary.simpleMessage("Search"),
    "signOut" : MessageLookupByLibrary.simpleMessage("Sign Out"),
    "sticker" : MessageLookupByLibrary.simpleMessage("Sticker"),
    "strangerFromMessage" : MessageLookupByLibrary.simpleMessage("This sender is not in your contacts"),
    "strangers" : MessageLookupByLibrary.simpleMessage("Strangers"),
    "transfer" : MessageLookupByLibrary.simpleMessage("Transfer"),
    "unMute" : MessageLookupByLibrary.simpleMessage("UnMute"),
    "unPin" : MessageLookupByLibrary.simpleMessage("UnPin"),
    "video" : MessageLookupByLibrary.simpleMessage("Video"),
    "videoCall" : MessageLookupByLibrary.simpleMessage("Video call"),
    "waitingForThisMessage" : MessageLookupByLibrary.simpleMessage("Waiting for this message."),
    "you" : MessageLookupByLibrary.simpleMessage("You")
  };
}
