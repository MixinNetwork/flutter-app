// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(name) => "${name} disabled disappearing message.";

  static String m1(name, duration) =>
      "${name} set disappearing message time to ${duration}.";

  static String m2(name) => "${name} changed disappearing message settings.";

  static String m3(name, addedName) => "${name} added ${addedName}";

  static String m4(name, groupName) => "${name} created group ${groupName}";

  static String m5(name) => "${name} left";

  static String m6(name) => "${name} joined the group via invite link";

  static String m7(name, removedName) => "${name} removed ${removedName}";

  static String m8(name) =>
      "Waiting for ${name} to get online and establish an encrypted session.";

  static String m9(name) => "${name}\'s Circles";

  static String m10(mixinId) => "Mixin ID: ${mixinId}";

  static String m11(count) => "${count} Conversations";

  static String m12(id) => "ID: ${id}";

  static String m13(count) => "${count} Participants";

  static String m14(count) => "${count} Participants";

  static String m15(ID) => "My Mixin ID: ${ID}";

  static String m16(value) => "Delete chat: ${value}";

  static String m17(max) => "The maximum time is ${max}.";

  static String m18(phone) => "Enter the 4-digit code sent to you at ${phone}";

  static String m19(code) => "ERROR ${code}: Sign in to continue";

  static String m20(code) =>
      "ERROR ${code}: The request data has invalid field";

  static String m21(code) =>
      "ERROR ${code}: Blockchain not in sync, please try again later.";

  static String m22(code) => "ERROR ${code}: The number has reached the limit.";

  static String m23(code) => "ERROR ${code}: The group chat is full.";

  static String m24(code) => "ERROR ${code}: Insufficient balance";

  static String m25(code, fee) =>
      "ERROR ${code}: Insufficient transaction fee. Please make sure your wallet has ${fee} as fee";

  static String m26(code, type, address) =>
      "ERROR ${code}: Invalid address format. Please enter the correct ${type} ${address} address!";

  static String m27(code) => "ERROR ${code}: Invalid address format.";

  static String m28(code) =>
      "ERROR ${code}: Send verification code too frequent, please try again later.";

  static String m29(code) => "ERROR ${code}: Invalid emergency contact";

  static String m30(code) => "ERROR ${code}: Invalid PIN format";

  static String m31(code) => "ERROR ${code}: Not found";

  static String m32(code, version) =>
      "ERROR ${code}: Please update Mixin(${version}) to continue use the service.";

  static String m33(code) => "ERROR ${code}: Invalid phone number";

  static String m34(code) => "ERROR ${code}: Failed to deliver SMS";

  static String m35(code) => "ERROR ${code}: Expired phone verification code";

  static String m36(code) => "ERROR ${code}: Invalid phone verification code";

  static String m37(code) => "ERROR ${code}: PIN incorrect";

  static String m38(code, times) =>
      "${code}: PIN incorrect. You still have ${times} chances. Please wait for 24 hours to retry later.";

  static String m39(code) => "ERROR ${code}: Recaptcha is invalid";

  static String m40(code) => "Server is under maintenance: ${code}";

  static String m41(code) => "ERROR ${code}: Rate limit exceeded";

  static String m42(code) => "ERROR ${code}: Too many stickers";

  static String m43(code) => "ERROR ${code}: The amount is too small";

  static String m44(code) => "ERROR ${code}: Withdraw amount too small";

  static String m45(code) => "ERROR: ${code}";

  static String m46(message) => "ERROR: ${message}";

  static String m47(code) => "ERROR ${code}: Phone is used by someone else.";

  static String m48(code) => "ERROR ${code}: Withdrawal memo format incorrect.";

  static String m49(name) => "Failed to open file ${name}";

  static String m50(name) => "Message ${name}";

  static String m51(name) => "Remove ${name}";

  static String m52(date) =>
      "Your account will be deleted on ${date}, if you continue to log in, the request to delete your account will be cancelled.";

  static String m53(newVersion, current) =>
      "Mixin Messenger ${newVersion} is now available, you have ${current}. Would you like to download it now?";

  static String m54(name) => "Do you want to delete ${name} circle?";

  static String m55(date) => "${date} join";

  static String m56(count) => "${count} Participants";

  static String m57(count) => "${count} Pinned Messages";

  static String m58(user, preview) => "${user} pinned ${preview}";

  static String m59(time) => "Resend code in ${time}s";

  static String m60(count) => "${count} related messages";

  static String m61(phone) =>
      "We will send a 4-digit code to your phone number ${phone}, please enter the code in next screen.";

  static String m62(value, unitValue, symbol) =>
      "value now ${value} (${unitValue}/${symbol})";

  static String m63(value, unitValue, symbol) =>
      "value then ${value} (${unitValue}/${symbol})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aMessage": MessageLookupByLibrary.simpleMessage("a message"),
        "about": MessageLookupByLibrary.simpleMessage("About"),
        "aboutEncryptedInfo": MessageLookupByLibrary.simpleMessage(
            "Messages to this conversation are encrypted end-to-end, tap for more info."),
        "aboutEncryptedInfoUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixin.one/pages/1000007"),
        "activity": MessageLookupByLibrary.simpleMessage("Activity"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addAnnouncement":
            MessageLookupByLibrary.simpleMessage("Add group description"),
        "addContact": MessageLookupByLibrary.simpleMessage("Add contact"),
        "addSticker": MessageLookupByLibrary.simpleMessage("Add sticker"),
        "addStickerFailed":
            MessageLookupByLibrary.simpleMessage("Add sticker failed"),
        "addStickers": MessageLookupByLibrary.simpleMessage("Add Stickers"),
        "addToCircle": MessageLookupByLibrary.simpleMessage("Add to Circle"),
        "added": MessageLookupByLibrary.simpleMessage("Added"),
        "animalsAndNature":
            MessageLookupByLibrary.simpleMessage("Animals & Nature"),
        "appCard": MessageLookupByLibrary.simpleMessage("Card"),
        "appCardShareDisallow": MessageLookupByLibrary.simpleMessage(
            "Disallow sharing of this URL"),
        "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
        "archivedFolder":
            MessageLookupByLibrary.simpleMessage("archived folder"),
        "assetType": MessageLookupByLibrary.simpleMessage("Asset Type"),
        "audio": MessageLookupByLibrary.simpleMessage("Audio"),
        "audios": MessageLookupByLibrary.simpleMessage("Audios"),
        "autoBackup": MessageLookupByLibrary.simpleMessage("Auto Backup"),
        "avatar": MessageLookupByLibrary.simpleMessage("Avatar"),
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "block": MessageLookupByLibrary.simpleMessage("Block"),
        "botInteractHi": MessageLookupByLibrary.simpleMessage("Say hi"),
        "botInteractInfo": MessageLookupByLibrary.simpleMessage(
            "Click the button to interact with the bot"),
        "botInteractOpen":
            MessageLookupByLibrary.simpleMessage("Open Home page"),
        "bots": MessageLookupByLibrary.simpleMessage("Bots"),
        "bringAllToFront":
            MessageLookupByLibrary.simpleMessage("Bring All To Front"),
        "canNotRecognize": MessageLookupByLibrary.simpleMessage(
            "Can not recognize the QR code"),
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
        "chatExpiredDisabled": m0,
        "chatExpiredSet": m1,
        "chatExpiredSetWithoutDuration": m2,
        "chatGroupAdd": m3,
        "chatGroupCreate": m4,
        "chatGroupExit": m5,
        "chatGroupJoin": m6,
        "chatGroupRemove": m7,
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
        "chatWaiting": m8,
        "chatWaitingDesktop": MessageLookupByLibrary.simpleMessage("desktop"),
        "chats": MessageLookupByLibrary.simpleMessage("Chats"),
        "checkUpdate":
            MessageLookupByLibrary.simpleMessage("Check for updates"),
        "circleTitle": m9,
        "circles": MessageLookupByLibrary.simpleMessage("Circles"),
        "clear": MessageLookupByLibrary.simpleMessage("Clear"),
        "clearChat": MessageLookupByLibrary.simpleMessage("Clear Chat"),
        "closeWindow": MessageLookupByLibrary.simpleMessage("Close window"),
        "collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
        "combineAndForward":
            MessageLookupByLibrary.simpleMessage("Combine and Forward"),
        "comingSoon": MessageLookupByLibrary.simpleMessage("Coming soon..."),
        "confirm": MessageLookupByLibrary.simpleMessage("OK"),
        "contact": MessageLookupByLibrary.simpleMessage("Contact"),
        "contactMixinId": m10,
        "contacts": MessageLookupByLibrary.simpleMessage("Contacts"),
        "continueText": MessageLookupByLibrary.simpleMessage("Continue"),
        "conversationAddBot": MessageLookupByLibrary.simpleMessage("+ Add Bot"),
        "conversationAddContact":
            MessageLookupByLibrary.simpleMessage("+ Add Contact"),
        "conversationCount": m11,
        "conversationID": m12,
        "conversationName":
            MessageLookupByLibrary.simpleMessage("Conversation Name"),
        "conversationParticipantsCount": m13,
        "conversationParticipantsCountDescription": m14,
        "conversations": MessageLookupByLibrary.simpleMessage("Conversations"),
        "copy": MessageLookupByLibrary.simpleMessage("Copy"),
        "create": MessageLookupByLibrary.simpleMessage("Create"),
        "createCircle": MessageLookupByLibrary.simpleMessage("New Circle"),
        "createConversation":
            MessageLookupByLibrary.simpleMessage("New Conversation"),
        "createGroupConversation":
            MessageLookupByLibrary.simpleMessage("New Group"),
        "currentIdentityNumber": m15,
        "dataAndStorageUsage":
            MessageLookupByLibrary.simpleMessage("Data and Storage Usage"),
        "day": MessageLookupByLibrary.simpleMessage("day"),
        "days": MessageLookupByLibrary.simpleMessage("days"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "deleteChat": MessageLookupByLibrary.simpleMessage("Delete Chat"),
        "deleteChatDescription": MessageLookupByLibrary.simpleMessage(
            "Deleting chat will remove messages form this devices only. They will not be removed from other devices."),
        "deleteChatHint": m16,
        "deleteCircle": MessageLookupByLibrary.simpleMessage("Delete Circle"),
        "deleteForEveryone":
            MessageLookupByLibrary.simpleMessage("Delete for Everyone"),
        "deleteForMe": MessageLookupByLibrary.simpleMessage("Delete for me"),
        "deleteGroup": MessageLookupByLibrary.simpleMessage("Delete Group"),
        "deleteSelectedMessageWarning": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to delete the selected message?"),
        "developer": MessageLookupByLibrary.simpleMessage("Developer"),
        "disappearingCustomTime":
            MessageLookupByLibrary.simpleMessage("Custom time"),
        "disappearingCustomTimeMaxWarning": m17,
        "disappearingMessages":
            MessageLookupByLibrary.simpleMessage("Disappearing messages"),
        "disappearingMessagesDescription": MessageLookupByLibrary.simpleMessage(
            "When enabled, new messages sent and received in this chat will disappear after they have been seen, read the document to learn more."),
        "discard": MessageLookupByLibrary.simpleMessage("Discard"),
        "discardRecordingWarning": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to stop recording and discard your voice message?"),
        "done": MessageLookupByLibrary.simpleMessage("Done"),
        "download": MessageLookupByLibrary.simpleMessage("Download"),
        "downloadLink": MessageLookupByLibrary.simpleMessage("Download Link: "),
        "editAnnouncement":
            MessageLookupByLibrary.simpleMessage("Edit group description"),
        "editCircle": MessageLookupByLibrary.simpleMessage("Manage Circle"),
        "editCircleName":
            MessageLookupByLibrary.simpleMessage("Edit Circle Name"),
        "editImageClearWarning": MessageLookupByLibrary.simpleMessage(
            "All changes will be lost. Are you sure you want to exit?"),
        "editName": MessageLookupByLibrary.simpleMessage("Edit Name"),
        "editProfile": MessageLookupByLibrary.simpleMessage("Edit Profile"),
        "enterNameTitle":
            MessageLookupByLibrary.simpleMessage("What\'s your name?"),
        "enterVerificationCode": m18,
        "enterYourPhoneNumber":
            MessageLookupByLibrary.simpleMessage("Enter your phone number"),
        "errorAddressExists": MessageLookupByLibrary.simpleMessage(
            "The address does not exist, please make sure that the address is added successfully"),
        "errorAddressNotSync": MessageLookupByLibrary.simpleMessage(
            "Address refresh failed, please try again"),
        "errorAppNotFound":
            MessageLookupByLibrary.simpleMessage("App not found"),
        "errorAssetExists":
            MessageLookupByLibrary.simpleMessage("Asset does not exist"),
        "errorAuthentication": m19,
        "errorBadData": m20,
        "errorBlockchain": m21,
        "errorConnectionTimeout":
            MessageLookupByLibrary.simpleMessage("Connection timeout"),
        "errorConversationNotFound":
            MessageLookupByLibrary.simpleMessage("Conversation not found"),
        "errorData": MessageLookupByLibrary.simpleMessage("Data error"),
        "errorDurationShort":
            MessageLookupByLibrary.simpleMessage("Duration is too short"),
        "errorFavoriteLimit": m22,
        "errorFileChooser":
            MessageLookupByLibrary.simpleMessage("File chooser error"),
        "errorFileExists":
            MessageLookupByLibrary.simpleMessage("File does not exist"),
        "errorForbidden": MessageLookupByLibrary.simpleMessage("Forbidden"),
        "errorFormat":
            MessageLookupByLibrary.simpleMessage("Format not supported"),
        "errorFullGroup": m23,
        "errorImage": MessageLookupByLibrary.simpleMessage("File error"),
        "errorInsufficientBalance": m24,
        "errorInsufficientTransactionFeeWithAmount": m25,
        "errorInvalidAddress": m26,
        "errorInvalidAddressPlain": m27,
        "errorInvalidCodeTooFrequent": m28,
        "errorInvalidEmergencyContact": m29,
        "errorInvalidPinFormat": m30,
        "errorNetworkError":
            MessageLookupByLibrary.simpleMessage("Network error"),
        "errorNoCamera": MessageLookupByLibrary.simpleMessage("No camera"),
        "errorNoConnection":
            MessageLookupByLibrary.simpleMessage("No connection"),
        "errorNotFound": m31,
        "errorNotFoundMessage":
            MessageLookupByLibrary.simpleMessage("Not found"),
        "errorNotSupportedAudioFormat": MessageLookupByLibrary.simpleMessage(
            "Not supported audio format, please open by other app."),
        "errorOldVersion": m32,
        "errorOpenLocation":
            MessageLookupByLibrary.simpleMessage("Can\'t find an map app"),
        "errorPermission": MessageLookupByLibrary.simpleMessage(
            "Please open the necessary permissions"),
        "errorPhoneInvalidFormat": m33,
        "errorPhoneSmsDelivery": m34,
        "errorPhoneVerificationCodeExpired": m35,
        "errorPhoneVerificationCodeInvalid": m36,
        "errorPinCheckTooManyRequest": MessageLookupByLibrary.simpleMessage(
            "You have tried more than 5 times, please wait at least 24 hours to try again."),
        "errorPinIncorrect": m37,
        "errorPinIncorrectWithTimes": m38,
        "errorRecaptchaIsInvalid": m39,
        "errorRecaptchaTimeout":
            MessageLookupByLibrary.simpleMessage("Recaptcha timeout"),
        "errorRetryUpload":
            MessageLookupByLibrary.simpleMessage("Retry upload failed."),
        "errorServer5xx": m40,
        "errorShare": MessageLookupByLibrary.simpleMessage("Share error."),
        "errorTooManyRequests": m41,
        "errorTooManyStickers": m42,
        "errorTooSmall": m43,
        "errorTooSmallWithdrawAmount": m44,
        "errorTranscriptForward": MessageLookupByLibrary.simpleMessage(
            "Please forward all attachments after they have been downloaded"),
        "errorUnableToOpenMedia": MessageLookupByLibrary.simpleMessage(
            "Can\'t find an app able to open this media."),
        "errorUnknownWithCode": m45,
        "errorUnknownWithMessage": m46,
        "errorUsedPhone": m47,
        "errorUserInvalidFormat":
            MessageLookupByLibrary.simpleMessage("Invalid user id"),
        "errorUserNotFound":
            MessageLookupByLibrary.simpleMessage("User not found"),
        "errorWithdrawalMemoFormatIncorrect": m48,
        "exit": MessageLookupByLibrary.simpleMessage("Exit"),
        "exitGroup": MessageLookupByLibrary.simpleMessage("Delete and Exit"),
        "extensions": MessageLookupByLibrary.simpleMessage("Extensions"),
        "failed": MessageLookupByLibrary.simpleMessage("Failed"),
        "failedToOpenFile": m49,
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "files": MessageLookupByLibrary.simpleMessage("Files"),
        "flags": MessageLookupByLibrary.simpleMessage("Flags"),
        "followFacebook":
            MessageLookupByLibrary.simpleMessage("Follow us on Facebook"),
        "followTwitter":
            MessageLookupByLibrary.simpleMessage("Follow us on Twitter"),
        "foodAndDrink": MessageLookupByLibrary.simpleMessage("Food & Drink"),
        "forward": MessageLookupByLibrary.simpleMessage("Forward"),
        "forwardOneByOne":
            MessageLookupByLibrary.simpleMessage("Forward One By One"),
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
        "groupPopMenuMessage": m50,
        "groupPopMenuRemoveParticipants": m51,
        "groupSearchParticipants":
            MessageLookupByLibrary.simpleMessage("Mixin ID, Name"),
        "groups": MessageLookupByLibrary.simpleMessage("Groups"),
        "groupsInCommon":
            MessageLookupByLibrary.simpleMessage("Groups in common"),
        "help": MessageLookupByLibrary.simpleMessage("Help"),
        "helpCenter": MessageLookupByLibrary.simpleMessage("Help center"),
        "hideMixin": MessageLookupByLibrary.simpleMessage("Hide Mixin"),
        "hour": MessageLookupByLibrary.simpleMessage("hour"),
        "hours": MessageLookupByLibrary.simpleMessage("hours"),
        "ignoreThisUpdate":
            MessageLookupByLibrary.simpleMessage("Ignore this update"),
        "image": MessageLookupByLibrary.simpleMessage("Image"),
        "includeFiles": MessageLookupByLibrary.simpleMessage("Include Files"),
        "includeVideos": MessageLookupByLibrary.simpleMessage("Include Videos"),
        "initializing": MessageLookupByLibrary.simpleMessage("Initializing"),
        "introduction": MessageLookupByLibrary.simpleMessage("Introduction"),
        "joinGroup": MessageLookupByLibrary.simpleMessage("+ Join the group"),
        "landingDeletionWarningContent": m52,
        "landingDeletionWarningTitle": MessageLookupByLibrary.simpleMessage(
            "Continue to log in and abort account deletion"),
        "learnMore": MessageLookupByLibrary.simpleMessage("Learn more"),
        "less": MessageLookupByLibrary.simpleMessage("less"),
        "links": MessageLookupByLibrary.simpleMessage("Links"),
        "live": MessageLookupByLibrary.simpleMessage("Live"),
        "loading": MessageLookupByLibrary.simpleMessage("Loading"),
        "localTimeErrorDescription": MessageLookupByLibrary.simpleMessage(
            "System time is unusual, please continue to use again after correction"),
        "location": MessageLookupByLibrary.simpleMessage("Location"),
        "login": MessageLookupByLibrary.simpleMessage("Login"),
        "loginWithMobile":
            MessageLookupByLibrary.simpleMessage("Login with mobile number"),
        "loginWithQRCode":
            MessageLookupByLibrary.simpleMessage("Login with QR code"),
        "media": MessageLookupByLibrary.simpleMessage("Media"),
        "memo": MessageLookupByLibrary.simpleMessage("Memo"),
        "messagePreview":
            MessageLookupByLibrary.simpleMessage("Message Preview"),
        "messagePreviewDescription": MessageLookupByLibrary.simpleMessage(
            "Preview message text inside new message notifications."),
        "messageTooLong":
            MessageLookupByLibrary.simpleMessage("Message content is too long"),
        "messages": MessageLookupByLibrary.simpleMessage("Messages"),
        "minimize": MessageLookupByLibrary.simpleMessage("Minimize"),
        "minute": MessageLookupByLibrary.simpleMessage("minute"),
        "minutes": MessageLookupByLibrary.simpleMessage("minutes"),
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
        "myStickerAlbums": MessageLookupByLibrary.simpleMessage("My Stickers"),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "networkConnectionFailed":
            MessageLookupByLibrary.simpleMessage("Network connection failed"),
        "newVersionAvailable":
            MessageLookupByLibrary.simpleMessage("New version available"),
        "newVersionDescription": m53,
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "nextConversation":
            MessageLookupByLibrary.simpleMessage("Next conversation"),
        "noAudio": MessageLookupByLibrary.simpleMessage("NO AUDIO"),
        "noData": MessageLookupByLibrary.simpleMessage("NO DATA"),
        "noFile": MessageLookupByLibrary.simpleMessage("NO FILE"),
        "noLink": MessageLookupByLibrary.simpleMessage("NO LINK"),
        "noMedia": MessageLookupByLibrary.simpleMessage("NO MEDIA"),
        "noPost": MessageLookupByLibrary.simpleMessage("NO POST"),
        "noResults": MessageLookupByLibrary.simpleMessage("No results"),
        "notification": MessageLookupByLibrary.simpleMessage("Notification"),
        "notificationPermissionDescription":
            MessageLookupByLibrary.simpleMessage(
                "Don\'t miss messages from you friends."),
        "notificationPermissionManually": MessageLookupByLibrary.simpleMessage(
            "Notifications are not allowed, please go to Notification Settings to turn on."),
        "notificationPermissionTitle":
            MessageLookupByLibrary.simpleMessage("Turn On Notifications"),
        "objects": MessageLookupByLibrary.simpleMessage("Objects"),
        "off": MessageLookupByLibrary.simpleMessage("Off"),
        "openLogDirectory":
            MessageLookupByLibrary.simpleMessage("open log directory"),
        "originalImage": MessageLookupByLibrary.simpleMessage("Original"),
        "pageDeleteCircle": m54,
        "pageEditProfileJoin": m55,
        "pageLandingClickToReload":
            MessageLookupByLibrary.simpleMessage("CLICK TO RELOAD QR CODE"),
        "pageLandingLoginMessage": MessageLookupByLibrary.simpleMessage(
            "1. Open Mixin Messenger on your phone \n2. Scan the QR Code on the screen \n3. Confirm your login."),
        "pageLandingLoginTitle": MessageLookupByLibrary.simpleMessage(
            "Login to Mixin Messenger by QR Code"),
        "pageRightEmptyMessage": MessageLookupByLibrary.simpleMessage(
            "Select a conversation to start messaging"),
        "participantsCount": m56,
        "phoneNumber": MessageLookupByLibrary.simpleMessage("Phone number"),
        "photos": MessageLookupByLibrary.simpleMessage("Photos"),
        "pin": MessageLookupByLibrary.simpleMessage("Pin"),
        "pinMessageCount": m57,
        "pinned": m58,
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Please wait a moment"),
        "post": MessageLookupByLibrary.simpleMessage("Post"),
        "preferences": MessageLookupByLibrary.simpleMessage("Preferences"),
        "preview": MessageLookupByLibrary.simpleMessage("Preview"),
        "previousConversation":
            MessageLookupByLibrary.simpleMessage("Previous conversation"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "provisioning": MessageLookupByLibrary.simpleMessage("Provisioning"),
        "quickSearch": MessageLookupByLibrary.simpleMessage("Quick search"),
        "quitMixin": MessageLookupByLibrary.simpleMessage("Quit Mixin"),
        "recentConversations":
            MessageLookupByLibrary.simpleMessage("Recent conversations"),
        "reedit": MessageLookupByLibrary.simpleMessage("Re-edit"),
        "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
        "removeBot": MessageLookupByLibrary.simpleMessage("Remove Bot"),
        "removeChatFromCircle":
            MessageLookupByLibrary.simpleMessage("Remove Chat from circle"),
        "removeContact": MessageLookupByLibrary.simpleMessage("Remove Contact"),
        "removeStickers":
            MessageLookupByLibrary.simpleMessage("Remove Stickers"),
        "reply": MessageLookupByLibrary.simpleMessage("Reply"),
        "report": MessageLookupByLibrary.simpleMessage("Report"),
        "reportWarning": MessageLookupByLibrary.simpleMessage(
            "Do you want to report and block this contact?"),
        "resendCode": MessageLookupByLibrary.simpleMessage("Resend code"),
        "resendCodeIn": m59,
        "reset": MessageLookupByLibrary.simpleMessage("Reset"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "saveAs": MessageLookupByLibrary.simpleMessage("Save as"),
        "saveToGallery":
            MessageLookupByLibrary.simpleMessage("Save to Gallery"),
        "scamWarning": MessageLookupByLibrary.simpleMessage(
            "Warning: Many users reported this account as a scam. Please be careful, especially if it asks you for money"),
        "search": MessageLookupByLibrary.simpleMessage("Search"),
        "searchEmpty": MessageLookupByLibrary.simpleMessage(
            "No chats, \ncontacts or messages found."),
        "searchMessageHistory": MessageLookupByLibrary.simpleMessage("Search"),
        "searchRelatedMessage": m60,
        "searchUser": MessageLookupByLibrary.simpleMessage("Search contact"),
        "searchUserHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID or Phone number"),
        "second": MessageLookupByLibrary.simpleMessage("second"),
        "seconds": MessageLookupByLibrary.simpleMessage("seconds"),
        "select": MessageLookupByLibrary.simpleMessage("Select"),
        "send": MessageLookupByLibrary.simpleMessage("send"),
        "sendArchived": MessageLookupByLibrary.simpleMessage(
            "Archived all files in one zip file"),
        "sendCodeConfirm": m61,
        "sendQuick": MessageLookupByLibrary.simpleMessage("Send quickly"),
        "sendWithoutCompression":
            MessageLookupByLibrary.simpleMessage("Send without compression"),
        "sendWithoutSound":
            MessageLookupByLibrary.simpleMessage("Send Without Sound"),
        "sentYouAMessage":
            MessageLookupByLibrary.simpleMessage("Sent you a message"),
        "set": MessageLookupByLibrary.simpleMessage("Set"),
        "settingTheme": MessageLookupByLibrary.simpleMessage("Theme"),
        "settingThemeAuto":
            MessageLookupByLibrary.simpleMessage("Follow system"),
        "settingThemeLight": MessageLookupByLibrary.simpleMessage("Light"),
        "settingThemeNight": MessageLookupByLibrary.simpleMessage("Dark"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "shareContact": MessageLookupByLibrary.simpleMessage("Share Contact"),
        "sharedApps": MessageLookupByLibrary.simpleMessage("Shared Apps"),
        "sharedMedia": MessageLookupByLibrary.simpleMessage("Shared Media"),
        "show": MessageLookupByLibrary.simpleMessage("Show"),
        "showAvatar": MessageLookupByLibrary.simpleMessage("Show avatar"),
        "showMixin": MessageLookupByLibrary.simpleMessage("Show Mixin"),
        "signOut": MessageLookupByLibrary.simpleMessage("Sign Out"),
        "smileysAndPeople":
            MessageLookupByLibrary.simpleMessage("Smileys & People"),
        "sticker": MessageLookupByLibrary.simpleMessage("Sticker"),
        "stickerAlbumDetail":
            MessageLookupByLibrary.simpleMessage("Sticker album detail"),
        "stickerShop": MessageLookupByLibrary.simpleMessage("Sticker shop"),
        "storageAutoDownloadDescription": MessageLookupByLibrary.simpleMessage(
            "Change auto-download settings for medias. "),
        "storageUsage": MessageLookupByLibrary.simpleMessage("Storage Usage"),
        "strangerFromMessage": MessageLookupByLibrary.simpleMessage(
            "This sender is not in your contacts"),
        "strangers": MessageLookupByLibrary.simpleMessage("Strangers"),
        "successful": MessageLookupByLibrary.simpleMessage("Successful"),
        "symbols": MessageLookupByLibrary.simpleMessage("Symbols"),
        "termsService":
            MessageLookupByLibrary.simpleMessage("Terms of Service"),
        "text": MessageLookupByLibrary.simpleMessage("Text"),
        "time": MessageLookupByLibrary.simpleMessage("Time"),
        "to": MessageLookupByLibrary.simpleMessage("To"),
        "today": MessageLookupByLibrary.simpleMessage("Today"),
        "toggleChatInfo":
            MessageLookupByLibrary.simpleMessage("Toggle chat info"),
        "transactions": MessageLookupByLibrary.simpleMessage("Transactions"),
        "transactionsId":
            MessageLookupByLibrary.simpleMessage("Transaction Id"),
        "transfer": MessageLookupByLibrary.simpleMessage("Transfer"),
        "travelAndPlaces":
            MessageLookupByLibrary.simpleMessage("Travel & Places"),
        "typeAMessage": MessageLookupByLibrary.simpleMessage("Type message"),
        "unMute": MessageLookupByLibrary.simpleMessage("Unmute"),
        "unPin": MessageLookupByLibrary.simpleMessage("Unpin"),
        "unblock": MessageLookupByLibrary.simpleMessage("Unblock"),
        "unpinAllMessages":
            MessageLookupByLibrary.simpleMessage("Unpin All Messages"),
        "unpinAllMessagesDescription": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to unpin all messages?"),
        "unread": MessageLookupByLibrary.simpleMessage("New Messages"),
        "uriCheckOnPhone": MessageLookupByLibrary.simpleMessage(
            "This type of url is not supported, please check on your phone."),
        "userNotFound": MessageLookupByLibrary.simpleMessage("User not found"),
        "video": MessageLookupByLibrary.simpleMessage("Video"),
        "videoCall": MessageLookupByLibrary.simpleMessage("Video call"),
        "videos": MessageLookupByLibrary.simpleMessage("Videos"),
        "waitingForThisMessage":
            MessageLookupByLibrary.simpleMessage("Waiting for this message."),
        "walletTransactionCurrentValue": m62,
        "walletTransactionThatTimeNoValue":
            MessageLookupByLibrary.simpleMessage("value then N/A"),
        "walletTransactionThatTimeValue": m63,
        "webView2RuntimeInstallDescription": MessageLookupByLibrary.simpleMessage(
            "The device has not installed the WebView2 Runtime component. Please download and install WebView2 Runtime first."),
        "webViewRuntimeNotAvailable": MessageLookupByLibrary.simpleMessage(
            "WebView2 Runtime is not available"),
        "week": MessageLookupByLibrary.simpleMessage("week"),
        "weeks": MessageLookupByLibrary.simpleMessage("weeks"),
        "window": MessageLookupByLibrary.simpleMessage("Window"),
        "you": MessageLookupByLibrary.simpleMessage("you"),
        "youStart": MessageLookupByLibrary.simpleMessage("You"),
        "zoom": MessageLookupByLibrary.simpleMessage("Zoom")
      };
}
