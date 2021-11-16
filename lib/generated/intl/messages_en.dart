// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(name, addedName) => "${name} added ${addedName}";

  static String m1(name, groupName) => "${name} created group ${groupName}";

  static String m2(name) => "${name} left";

  static String m3(name) => "${name} joined the group via invite link";

  static String m4(name, removedName) => "${name} removed ${removedName}";

  static String m5(name) =>
      "Waiting for ${name} to get online and establish an encrypted session.";

  static String m6(name) => "${name}\'s Circles";

  static String m7(mixinId) => "Mixin ID: ${mixinId}";

  static String m8(count) => "${count} Conversations";

  static String m9(id) => "ID: ${id}";

  static String m10(count) => "${count} Participants";

  static String m11(count) => "${count} Participants";

  static String m12(ID) => "My Mixin ID: ${ID}";

  static String m13(name) => "Message ${name}";

  static String m14(name) => "Remove ${name}";

  static String m15(name) => "Do you want to delete ${name} circle?";

  static String m16(date) => "${date} join";

  static String m17(count) => "${count} Participants";

  static String m18(count) => "${count} Pinned Messages";

  static String m19(user, preview) => "${user} pinned ${preview}";

  static String m20(count) => "${count} related messages";

  static String m21(value) => "value now ${value}";

  static String m22(value) => "value then ${value}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aMessage": MessageLookupByLibrary.simpleMessage("a message"),
        "about": MessageLookupByLibrary.simpleMessage("About"),
        "aboutEncryptedInfo": MessageLookupByLibrary.simpleMessage(
            "Messages to this conversation are encrypted end-to-end, tap for more info."),
        "aboutEncryptedInfoUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixin.one/pages/1000007"),
        "addAnnouncement":
            MessageLookupByLibrary.simpleMessage("Add group description"),
        "addContact": MessageLookupByLibrary.simpleMessage("Add contact"),
        "appCard": MessageLookupByLibrary.simpleMessage("Card"),
        "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
        "archivedFolder":
            MessageLookupByLibrary.simpleMessage("archived folder"),
        "assetType": MessageLookupByLibrary.simpleMessage("Asset Type"),
        "audio": MessageLookupByLibrary.simpleMessage("Audio"),
        "audios": MessageLookupByLibrary.simpleMessage("Audios"),
        "autoBackup": MessageLookupByLibrary.simpleMessage("Auto Backup"),
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "block": MessageLookupByLibrary.simpleMessage("Block"),
        "botInteractHi": MessageLookupByLibrary.simpleMessage("Say hi"),
        "botInteractInfo": MessageLookupByLibrary.simpleMessage(
            "Click the button to interact with the bot"),
        "botInteractOpen":
            MessageLookupByLibrary.simpleMessage("Open Home page"),
        "bots": MessageLookupByLibrary.simpleMessage("Bots"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "change": MessageLookupByLibrary.simpleMessage("Change"),
        "chatBackup": MessageLookupByLibrary.simpleMessage("Chat Backup"),
        "chatBackupDescription": MessageLookupByLibrary.simpleMessage(
            "Back up your chat history to iCloud so if you lose your iPhone or switch to a new one, your chat history is safe. You can restore your chat history when you reinstall MixinMessenger. messenger you back up are encryption while in icloud."),
        "chatCheckOnPhone": MessageLookupByLibrary.simpleMessage(
            "This type of message is not supported, please check on your phone."),
        "chatDragHint":
            MessageLookupByLibrary.simpleMessage("Drag and drop files here"),
        "chatDragMoreFile": MessageLookupByLibrary.simpleMessage("Add Item"),
        "chatGroupAdd": m0,
        "chatGroupCreate": m1,
        "chatGroupExit": m2,
        "chatGroupJoin": m3,
        "chatGroupRemove": m4,
        "chatGroupRole":
            MessageLookupByLibrary.simpleMessage("You\'re now an admin"),
        "chatInputHint":
            MessageLookupByLibrary.simpleMessage("End to end encrypted"),
        "chatLearn": MessageLookupByLibrary.simpleMessage("Learn more"),
        "chatNotFound":
            MessageLookupByLibrary.simpleMessage("Message not found"),
        "chatNotSupport": MessageLookupByLibrary.simpleMessage(
            "This type of message is not supported, please upgrade Mixin to the latest version."),
        "chatNotSupportUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixinmessenger.zendesk.com/hc/articles/360043776071"),
        "chatRecallDelete":
            MessageLookupByLibrary.simpleMessage("This message was deleted"),
        "chatRecallMe":
            MessageLookupByLibrary.simpleMessage("You deleted this message"),
        "chatTranscript": MessageLookupByLibrary.simpleMessage("Transcript"),
        "chatWaiting": m5,
        "chatWaitingDesktop": MessageLookupByLibrary.simpleMessage("desktop"),
        "chats": MessageLookupByLibrary.simpleMessage("Chats"),
        "circleTitle": m6,
        "circles": MessageLookupByLibrary.simpleMessage("Circles"),
        "clear": MessageLookupByLibrary.simpleMessage("Clear"),
        "clearChat": MessageLookupByLibrary.simpleMessage("Clear Chat"),
        "collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
        "comingSoon": MessageLookupByLibrary.simpleMessage("Coming soon..."),
        "confirm": MessageLookupByLibrary.simpleMessage("OK"),
        "contact": MessageLookupByLibrary.simpleMessage("Contacts"),
        "contactMixinId": m7,
        "contacts": MessageLookupByLibrary.simpleMessage("Contacts"),
        "continueText": MessageLookupByLibrary.simpleMessage("Continue"),
        "conversationAddBot": MessageLookupByLibrary.simpleMessage("+ Add Bot"),
        "conversationAddContact":
            MessageLookupByLibrary.simpleMessage("+ Add Contact"),
        "conversationCount": m8,
        "conversationID": m9,
        "conversationName":
            MessageLookupByLibrary.simpleMessage("Conversation Name"),
        "conversationParticipantsCount": m10,
        "conversationParticipantsCountDescription": m11,
        "conversations": MessageLookupByLibrary.simpleMessage("Conversations"),
        "copy": MessageLookupByLibrary.simpleMessage("Copy"),
        "create": MessageLookupByLibrary.simpleMessage("Create"),
        "createCircle": MessageLookupByLibrary.simpleMessage("New Circle"),
        "createConversation":
            MessageLookupByLibrary.simpleMessage("New Conversation"),
        "createGroupConversation":
            MessageLookupByLibrary.simpleMessage("New Group Conversation"),
        "currentIdentityNumber": m12,
        "dataAndStorageUsage":
            MessageLookupByLibrary.simpleMessage("Data and Storage Usage"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "deleteChat": MessageLookupByLibrary.simpleMessage("Delete Chat"),
        "deleteCircle": MessageLookupByLibrary.simpleMessage("Delete Circle"),
        "deleteForEveryone":
            MessageLookupByLibrary.simpleMessage("Delete for Everyone"),
        "deleteForMe": MessageLookupByLibrary.simpleMessage("Delete for me"),
        "deleteGroup": MessageLookupByLibrary.simpleMessage("Delete Group"),
        "developer": MessageLookupByLibrary.simpleMessage("Developer"),
        "done": MessageLookupByLibrary.simpleMessage("Done"),
        "downloadLink": MessageLookupByLibrary.simpleMessage("Download Link: "),
        "editAnnouncement":
            MessageLookupByLibrary.simpleMessage("Edit group description"),
        "editCircle": MessageLookupByLibrary.simpleMessage("Manage Circle"),
        "editCircleName":
            MessageLookupByLibrary.simpleMessage("Edit Circle Name"),
        "editName": MessageLookupByLibrary.simpleMessage("Edit Name"),
        "editProfile": MessageLookupByLibrary.simpleMessage("Edit Profile"),
        "exit": MessageLookupByLibrary.simpleMessage("Exit"),
        "exitGroup": MessageLookupByLibrary.simpleMessage("Delete and Exit"),
        "extensions": MessageLookupByLibrary.simpleMessage("Extensions"),
        "failed": MessageLookupByLibrary.simpleMessage("Failed"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "files": MessageLookupByLibrary.simpleMessage("Files"),
        "followFacebook":
            MessageLookupByLibrary.simpleMessage("Follow us on Facebook"),
        "followTwitter":
            MessageLookupByLibrary.simpleMessage("Follow us on Twitter"),
        "forward": MessageLookupByLibrary.simpleMessage("Forward"),
        "from": MessageLookupByLibrary.simpleMessage("From"),
        "fromWithColon": MessageLookupByLibrary.simpleMessage("From: "),
        "goToChat": MessageLookupByLibrary.simpleMessage("Go to chat"),
        "groupAdd": MessageLookupByLibrary.simpleMessage("Add Participants"),
        "groupAdmin": MessageLookupByLibrary.simpleMessage("admin"),
        "groupCantSendDes": MessageLookupByLibrary.simpleMessage(
            "You can\'t send messages to this group because you\'re no longer a participant."),
        "groupInvite":
            MessageLookupByLibrary.simpleMessage("Invite to Group via Link"),
        "groupInviteCopy": MessageLookupByLibrary.simpleMessage("Copy Link"),
        "groupInviteInfo": MessageLookupByLibrary.simpleMessage(
            "Anyone with Mixin can follow this link to join this group. Only share it with people you trust."),
        "groupInviteReset": MessageLookupByLibrary.simpleMessage("Reset Link"),
        "groupInviteShare": MessageLookupByLibrary.simpleMessage("Share Link"),
        "groupOwner": MessageLookupByLibrary.simpleMessage("owner"),
        "groupParticipants":
            MessageLookupByLibrary.simpleMessage("Participants"),
        "groupPopMenuDismissAdmin":
            MessageLookupByLibrary.simpleMessage("Dismiss admin"),
        "groupPopMenuMakeAdmin":
            MessageLookupByLibrary.simpleMessage("Make group admin"),
        "groupPopMenuMessage": m13,
        "groupPopMenuRemoveParticipants": m14,
        "groupSearchParticipants":
            MessageLookupByLibrary.simpleMessage("Mixin ID, Name"),
        "groups": MessageLookupByLibrary.simpleMessage("Groups"),
        "helpCenter": MessageLookupByLibrary.simpleMessage("Help center"),
        "image": MessageLookupByLibrary.simpleMessage("Image"),
        "includeFiles": MessageLookupByLibrary.simpleMessage("Include Files"),
        "includeVideos": MessageLookupByLibrary.simpleMessage("Include Videos"),
        "initializing": MessageLookupByLibrary.simpleMessage("Initializing"),
        "introduction": MessageLookupByLibrary.simpleMessage("Introduction"),
        "joinGroup": MessageLookupByLibrary.simpleMessage("+ Join the group"),
        "less": MessageLookupByLibrary.simpleMessage("less"),
        "links": MessageLookupByLibrary.simpleMessage("Links"),
        "live": MessageLookupByLibrary.simpleMessage("Live"),
        "loading": MessageLookupByLibrary.simpleMessage("Loading"),
        "localTimeErrorDescription": MessageLookupByLibrary.simpleMessage(
            "System time is unusual, please continue to use again after correction"),
        "location": MessageLookupByLibrary.simpleMessage("Location"),
        "media": MessageLookupByLibrary.simpleMessage("Media"),
        "memo": MessageLookupByLibrary.simpleMessage("Memo"),
        "messagePreview":
            MessageLookupByLibrary.simpleMessage("Message Preview"),
        "messagePreviewDescription": MessageLookupByLibrary.simpleMessage(
            "Preview message text inside new message notifications."),
        "messages": MessageLookupByLibrary.simpleMessage("Messages"),
        "mixinMessenger":
            MessageLookupByLibrary.simpleMessage("Mixin Messenger"),
        "more": MessageLookupByLibrary.simpleMessage("more"),
        "mute": MessageLookupByLibrary.simpleMessage("Mute"),
        "mute1hour": MessageLookupByLibrary.simpleMessage("1 Hour"),
        "mute1week": MessageLookupByLibrary.simpleMessage("1 Week"),
        "mute1year": MessageLookupByLibrary.simpleMessage("1 Year"),
        "mute8hours": MessageLookupByLibrary.simpleMessage("8 Hours"),
        "muteTitle":
            MessageLookupByLibrary.simpleMessage("Mute notifications for…"),
        "muted": MessageLookupByLibrary.simpleMessage("Mute"),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "networkConnectionFailed":
            MessageLookupByLibrary.simpleMessage("Network connection failed"),
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "noAudio": MessageLookupByLibrary.simpleMessage("NO AUDIO"),
        "noData": MessageLookupByLibrary.simpleMessage("NO DATA"),
        "noFile": MessageLookupByLibrary.simpleMessage("NO FILE"),
        "noLink": MessageLookupByLibrary.simpleMessage("NO LINK"),
        "noMedia": MessageLookupByLibrary.simpleMessage("NO MEDIA"),
        "noPost": MessageLookupByLibrary.simpleMessage("NO POST"),
        "notification": MessageLookupByLibrary.simpleMessage("Notification"),
        "notificationPermissionDescription":
            MessageLookupByLibrary.simpleMessage(
                "Don\'t miss messages from you friends."),
        "notificationPermissionManually": MessageLookupByLibrary.simpleMessage(
            "Notifications are not allowed, please go to Notification Settings to turn on."),
        "notificationPermissionTitle":
            MessageLookupByLibrary.simpleMessage("Turn On Notifications"),
        "pageDeleteCircle": m15,
        "pageEditProfileJoin": m16,
        "pageLandingClickToReload":
            MessageLookupByLibrary.simpleMessage("CLICK TO RELOAD QR CODE"),
        "pageLandingLoginMessage": MessageLookupByLibrary.simpleMessage(
            "Open Mixin Messenger on your phone, scan the qr code on the screen and confirm your login."),
        "pageLandingLoginTitle": MessageLookupByLibrary.simpleMessage(
            "Login to Mixin Messenger by QR Code"),
        "pageRightEmptyMessage": MessageLookupByLibrary.simpleMessage(
            "Select a conversation to start messaging"),
        "participantsCount": m17,
        "phoneNumber": MessageLookupByLibrary.simpleMessage("Phone number"),
        "photos": MessageLookupByLibrary.simpleMessage("Photos"),
        "pin": MessageLookupByLibrary.simpleMessage("Pin"),
        "pinMessageCount": m18,
        "pinned": m19,
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Please wait a moment"),
        "post": MessageLookupByLibrary.simpleMessage("Post"),
        "preview": MessageLookupByLibrary.simpleMessage("Preview"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "provisioning": MessageLookupByLibrary.simpleMessage("Provisioning"),
        "recentConversations":
            MessageLookupByLibrary.simpleMessage("Recent conversations"),
        "reedit": MessageLookupByLibrary.simpleMessage("Re-edit"),
        "removeBot": MessageLookupByLibrary.simpleMessage("Remove Bot"),
        "removeChatFromCircle":
            MessageLookupByLibrary.simpleMessage("Remove Chat from circle"),
        "removeContact": MessageLookupByLibrary.simpleMessage("Remove Contact"),
        "reply": MessageLookupByLibrary.simpleMessage("Reply"),
        "report": MessageLookupByLibrary.simpleMessage("Report"),
        "reportWarning": MessageLookupByLibrary.simpleMessage(
            "Do you want to report and block this contact?"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "scamWarning": MessageLookupByLibrary.simpleMessage(
            "Warning: Many users reported this account as a scam. Please be careful, especially if it asks you for money"),
        "search": MessageLookupByLibrary.simpleMessage("Search"),
        "searchEmpty": MessageLookupByLibrary.simpleMessage(
            "No chats, \ncontacts or messages found."),
        "searchMessageHistory": MessageLookupByLibrary.simpleMessage("Search"),
        "searchRelatedMessage": m20,
        "searchUser": MessageLookupByLibrary.simpleMessage("Search contact"),
        "searchUserHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID or Phone number"),
        "send": MessageLookupByLibrary.simpleMessage("send"),
        "sendArchived": MessageLookupByLibrary.simpleMessage(
            "Archived all files in one zip file"),
        "sendQuick": MessageLookupByLibrary.simpleMessage("Send quickly"),
        "sendWithoutCompression":
            MessageLookupByLibrary.simpleMessage("Send without compression"),
        "sendWithoutSound":
            MessageLookupByLibrary.simpleMessage("Send Without Sound"),
        "sentYouAMessage":
            MessageLookupByLibrary.simpleMessage("Sent you a message"),
        "settingTheme": MessageLookupByLibrary.simpleMessage("Theme"),
        "settingThemeAuto":
            MessageLookupByLibrary.simpleMessage("Follow system"),
        "settingThemeLight": MessageLookupByLibrary.simpleMessage("Light"),
        "settingThemeNight": MessageLookupByLibrary.simpleMessage("Dark"),
        "shareContact": MessageLookupByLibrary.simpleMessage("Share Contact"),
        "sharedApps": MessageLookupByLibrary.simpleMessage("Shared Apps"),
        "sharedMedia": MessageLookupByLibrary.simpleMessage("Shared Media"),
        "show": MessageLookupByLibrary.simpleMessage("Show"),
        "signOut": MessageLookupByLibrary.simpleMessage("Sign Out"),
        "sticker": MessageLookupByLibrary.simpleMessage("Sticker"),
        "storageAutoDownloadDescription": MessageLookupByLibrary.simpleMessage(
            "Change auto-download settings for medias. "),
        "storageUsage": MessageLookupByLibrary.simpleMessage("Storage Usage"),
        "strangerFromMessage": MessageLookupByLibrary.simpleMessage(
            "This sender is not in your contacts"),
        "strangers": MessageLookupByLibrary.simpleMessage("Strangers"),
        "successful": MessageLookupByLibrary.simpleMessage("Successful"),
        "termsService":
            MessageLookupByLibrary.simpleMessage("Terms of Service"),
        "text": MessageLookupByLibrary.simpleMessage("Text"),
        "time": MessageLookupByLibrary.simpleMessage("Time"),
        "to": MessageLookupByLibrary.simpleMessage("To"),
        "today": MessageLookupByLibrary.simpleMessage("Today"),
        "transactions": MessageLookupByLibrary.simpleMessage("Transactions"),
        "transactionsId":
            MessageLookupByLibrary.simpleMessage("Transaction Id"),
        "transfer": MessageLookupByLibrary.simpleMessage("Transfer"),
        "unMute": MessageLookupByLibrary.simpleMessage("Unmute"),
        "unPin": MessageLookupByLibrary.simpleMessage("Unpin"),
        "unblock": MessageLookupByLibrary.simpleMessage("Unblock"),
        "unpinAllMessages":
            MessageLookupByLibrary.simpleMessage("Unpin All Messages"),
        "unpinAllMessagesDescription": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to unpin all messages?"),
        "unread": MessageLookupByLibrary.simpleMessage("New Messages"),
        "userNotFound": MessageLookupByLibrary.simpleMessage("User not found"),
        "video": MessageLookupByLibrary.simpleMessage("Video"),
        "videoCall": MessageLookupByLibrary.simpleMessage("Video call"),
        "videos": MessageLookupByLibrary.simpleMessage("Videos"),
        "waitingForThisMessage":
            MessageLookupByLibrary.simpleMessage("Waiting for this message."),
        "walletTransactionCurrentValue": m21,
        "walletTransactionThatTimeNoValue":
            MessageLookupByLibrary.simpleMessage("value then N/A"),
        "walletTransactionThatTimeValue": m22,
        "webView2RuntimeInstallDescription": MessageLookupByLibrary.simpleMessage(
            "The device has not installed the WebView2 Runtime component. Please download and install WebView2 Runtime first."),
        "webViewRuntimeNotAvailable": MessageLookupByLibrary.simpleMessage(
            "WebView2 Runtime is not available"),
        "you": MessageLookupByLibrary.simpleMessage("you"),
        "youStart": MessageLookupByLibrary.simpleMessage("You")
      };
}
