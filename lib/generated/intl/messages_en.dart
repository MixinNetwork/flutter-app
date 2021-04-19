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

  static m6(name) => "${name}\'s Circles";

  static m7(count) => "${count} Conversations";

  static m8(id) => "ID: ${id}";

  static m9(count) => "${count} Participants";

  static m10(name) => "Do you want to delete ${name} circle?";

  static m11(date) => "${date} join";

  static m12(count) => "${count} Participants";

  static m13(count) => "${count} related messages";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "about" : MessageLookupByLibrary.simpleMessage("About"),
    "aboutEncryptedInfo" : MessageLookupByLibrary.simpleMessage("Messages to this conversation are encrypted end-to-end, tap for more info."),
    "aboutEncryptedInfoUrl" : MessageLookupByLibrary.simpleMessage("https://mixin.one/pages/1000007"),
    "addAnnouncement" : MessageLookupByLibrary.simpleMessage("Add group description"),
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
    "chatNotFound" : MessageLookupByLibrary.simpleMessage("Message not found"),
    "chatNotSupport" : MessageLookupByLibrary.simpleMessage("This type of message is not supported, please upgrade Mixin to the latest version."),
    "chatNotSupportUrl" : MessageLookupByLibrary.simpleMessage("https://mixinmessenger.zendesk.com/hc/articles/360043776071"),
    "chatRecallDelete" : MessageLookupByLibrary.simpleMessage("This message was deleted"),
    "chatRecallMe" : MessageLookupByLibrary.simpleMessage("You deleted this message"),
    "chatWaiting" : m5,
    "chatWaitingDesktop" : MessageLookupByLibrary.simpleMessage("desktop"),
    "chats" : MessageLookupByLibrary.simpleMessage("Chats"),
    "circleTitle" : m6,
    "circles" : MessageLookupByLibrary.simpleMessage("Circles"),
    "clearChat" : MessageLookupByLibrary.simpleMessage("Clear Chat"),
    "confirm" : MessageLookupByLibrary.simpleMessage("OK"),
    "contact" : MessageLookupByLibrary.simpleMessage("Contact"),
    "contacts" : MessageLookupByLibrary.simpleMessage("Contacts"),
    "conversationCount" : m7,
    "conversationID" : m8,
    "conversationName" : MessageLookupByLibrary.simpleMessage("Conversation Name"),
    "conversationParticipantsCount" : m9,
    "copy" : MessageLookupByLibrary.simpleMessage("Copy"),
    "create" : MessageLookupByLibrary.simpleMessage("Create"),
    "createCircle" : MessageLookupByLibrary.simpleMessage("New circle"),
    "createConversation" : MessageLookupByLibrary.simpleMessage("New Conversation"),
    "createGroupConversation" : MessageLookupByLibrary.simpleMessage("New Group Conversation"),
    "dataAndStorageUsage" : MessageLookupByLibrary.simpleMessage("Data and Storage Usage"),
    "delete" : MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteChat" : MessageLookupByLibrary.simpleMessage("Delete Chat"),
    "deleteCircle" : MessageLookupByLibrary.simpleMessage("Delete Circle"),
    "deleteForEveryone" : MessageLookupByLibrary.simpleMessage("Delete for Everyone"),
    "deleteForMe" : MessageLookupByLibrary.simpleMessage("Delete for me"),
    "deleteGroup" : MessageLookupByLibrary.simpleMessage("Delete Group"),
    "editAnnouncement" : MessageLookupByLibrary.simpleMessage("Edit group description"),
    "editCircleName" : MessageLookupByLibrary.simpleMessage("Edit Circle Name"),
    "editConversations" : MessageLookupByLibrary.simpleMessage("Edit Conversations"),
    "editName" : MessageLookupByLibrary.simpleMessage("Edit Name"),
    "editProfile" : MessageLookupByLibrary.simpleMessage("Edit Profile"),
    "exitGroup" : MessageLookupByLibrary.simpleMessage("Delete and Exit"),
    "extensions" : MessageLookupByLibrary.simpleMessage("Extensions"),
    "failed" : MessageLookupByLibrary.simpleMessage("Failed"),
    "file" : MessageLookupByLibrary.simpleMessage("File"),
    "forward" : MessageLookupByLibrary.simpleMessage("Forward"),
    "group" : MessageLookupByLibrary.simpleMessage("Group"),
    "image" : MessageLookupByLibrary.simpleMessage("Image"),
    "initializing" : MessageLookupByLibrary.simpleMessage("Initializing"),
    "introduction" : MessageLookupByLibrary.simpleMessage("Introduction"),
    "less" : MessageLookupByLibrary.simpleMessage("less"),
    "links" : MessageLookupByLibrary.simpleMessage("Links"),
    "live" : MessageLookupByLibrary.simpleMessage("Live"),
    "loading" : MessageLookupByLibrary.simpleMessage("Loading"),
    "location" : MessageLookupByLibrary.simpleMessage("Location"),
    "media" : MessageLookupByLibrary.simpleMessage("Media"),
    "messages" : MessageLookupByLibrary.simpleMessage("Messages"),
    "more" : MessageLookupByLibrary.simpleMessage("more"),
    "mute" : MessageLookupByLibrary.simpleMessage("Mute"),
    "mute1hour" : MessageLookupByLibrary.simpleMessage("1 Hour"),
    "mute1week" : MessageLookupByLibrary.simpleMessage("1 Week"),
    "mute1year" : MessageLookupByLibrary.simpleMessage("1 Year"),
    "mute8hours" : MessageLookupByLibrary.simpleMessage("8 Hours"),
    "muteTitle" : MessageLookupByLibrary.simpleMessage("Mute notifications for…"),
    "muted" : MessageLookupByLibrary.simpleMessage("Muted"),
    "name" : MessageLookupByLibrary.simpleMessage("Name"),
    "next" : MessageLookupByLibrary.simpleMessage("Next"),
    "noAudio" : MessageLookupByLibrary.simpleMessage("NO AUDIO"),
    "noData" : MessageLookupByLibrary.simpleMessage("NO DATA"),
    "noFile" : MessageLookupByLibrary.simpleMessage("NO FILE"),
    "noLink" : MessageLookupByLibrary.simpleMessage("NO LINK"),
    "noMedia" : MessageLookupByLibrary.simpleMessage("NO MEDIA"),
    "noPost" : MessageLookupByLibrary.simpleMessage("NO POST"),
    "notification" : MessageLookupByLibrary.simpleMessage("Notification"),
    "pageDeleteCircle" : m10,
    "pageEditProfileJoin" : m11,
    "pageLandingClickToReload" : MessageLookupByLibrary.simpleMessage("CLICK TO RELOAD QR CODE"),
    "pageLandingLoginMessage" : MessageLookupByLibrary.simpleMessage("Open Mixin Messenger on your phone, scan the qr code on the screen and confirm your login."),
    "pageLandingLoginTitle" : MessageLookupByLibrary.simpleMessage("Login to Mixin Messenger by QR Code"),
    "pageRightEmptyMessage" : MessageLookupByLibrary.simpleMessage("Select a conversation to start messaging"),
    "participantsCount" : m12,
    "people" : MessageLookupByLibrary.simpleMessage("People"),
    "phoneNumber" : MessageLookupByLibrary.simpleMessage("Phone number"),
    "pin" : MessageLookupByLibrary.simpleMessage("Pin"),
    "pleaseWait" : MessageLookupByLibrary.simpleMessage("Please wait a moment"),
    "post" : MessageLookupByLibrary.simpleMessage("Post"),
    "preview" : MessageLookupByLibrary.simpleMessage("Preview"),
    "provisioning" : MessageLookupByLibrary.simpleMessage("Provisioning"),
    "recentConversations" : MessageLookupByLibrary.simpleMessage("Recent conversations"),
    "removeBot" : MessageLookupByLibrary.simpleMessage("Remove Bot"),
    "removeContact" : MessageLookupByLibrary.simpleMessage("Remove Contact"),
    "reply" : MessageLookupByLibrary.simpleMessage("Reply"),
    "report" : MessageLookupByLibrary.simpleMessage("Report"),
    "reportWarning" : MessageLookupByLibrary.simpleMessage("Do you want to report and block this contact?"),
    "save" : MessageLookupByLibrary.simpleMessage("Save"),
    "search" : MessageLookupByLibrary.simpleMessage("Search"),
    "searchEmpty" : MessageLookupByLibrary.simpleMessage("No chats, \ncontacts or messages found."),
    "searchMessageHistory" : MessageLookupByLibrary.simpleMessage("Search Conversation"),
    "searchRelatedMessage" : m13,
    "shareContact" : MessageLookupByLibrary.simpleMessage("Share Contact"),
    "sharedApps" : MessageLookupByLibrary.simpleMessage("Shared Apps"),
    "sharedMedia" : MessageLookupByLibrary.simpleMessage("Shared Media"),
    "signOut" : MessageLookupByLibrary.simpleMessage("Sign Out"),
    "sticker" : MessageLookupByLibrary.simpleMessage("Sticker"),
    "strangerFromMessage" : MessageLookupByLibrary.simpleMessage("This sender is not in your contacts"),
    "strangers" : MessageLookupByLibrary.simpleMessage("Strangers"),
    "successful" : MessageLookupByLibrary.simpleMessage("Successful"),
    "transactions" : MessageLookupByLibrary.simpleMessage("Transactions"),
    "transfer" : MessageLookupByLibrary.simpleMessage("Transfer"),
    "unMute" : MessageLookupByLibrary.simpleMessage("UnMute"),
    "unPin" : MessageLookupByLibrary.simpleMessage("UnPin"),
    "unblock" : MessageLookupByLibrary.simpleMessage("Unblock"),
    "video" : MessageLookupByLibrary.simpleMessage("Video"),
    "videoCall" : MessageLookupByLibrary.simpleMessage("Video call"),
    "waitingForThisMessage" : MessageLookupByLibrary.simpleMessage("Waiting for this message."),
    "you" : MessageLookupByLibrary.simpleMessage("You")
  };
}
