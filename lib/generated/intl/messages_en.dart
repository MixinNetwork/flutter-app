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

  static String m0(arg0) => "${arg0} changed disappearing message settings.";

  static String m1(arg0) =>
      "Waiting for ${arg0} to get online and establish an encrypted session.";

  static String m2(count, arg0) =>
      "${Intl.plural(count, one: 'Delete ${arg0} message?', other: 'Delete ${arg0} messages?')}";

  static String m3(arg0, arg1) => "${arg0} added ${arg1}";

  static String m4(arg0) => "${arg0} left";

  static String m5(arg0) => "${arg0} joined the group via invite link";

  static String m6(arg0, arg1) => "${arg0} removed ${arg1}";

  static String m7(arg0, arg1) => "${arg0} pinned ${arg1}";

  static String m8(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} Conversation', other: '${arg0} Conversations')}";

  static String m9(arg0) => "${arg0}\'s Circles";

  static String m10(arg0) => "Mixin ID: ${arg0}";

  static String m11(arg0) => "Delete chat: ${arg0}";

  static String m12(arg0) => "Created ${arg0}";

  static String m13(arg0) => "${arg0} created this group";

  static String m14(arg0) => "Do you want to delete ${arg0} circle?";

  static String m15(arg0) => "${arg0} disabled disappearing message";

  static String m16(arg0) => "The maximum time is ${arg0}.";

  static String m17(arg0) =>
      "ERROR 20124: Insufficient transaction fee. Please make sure your wallet has ${arg0} as fee";

  static String m18(arg0, arg1) =>
      "ERROR 30102: Invalid address format. Please enter the correct ${arg0} ${arg1} address!";

  static String m19(arg0) =>
      "ERROR 10006: Please update Mixin(${arg0}) to continue use the service.";

  static String m20(count, arg0) =>
      "${Intl.plural(count, one: 'ERROR 20119: PIN incorrect. You still have ${arg0} chance. Please wait for 24 hours to retry later.', other: 'ERROR 20119: PIN incorrect. You still have ${arg0} chances. Please wait for 24 hours to retry later.')}";

  static String m21(arg0) => "Server is under maintenance: ${arg0}";

  static String m22(arg0) => "ERROR: ${arg0}";

  static String m23(arg0) => "ERROR: ${arg0}";

  static String m24(arg0) => "Message ${arg0}";

  static String m25(arg0) => "Remove ${arg0}";

  static String m26(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} Hour', other: '${arg0} Hours')}";

  static String m27(arg0) => "Joined on ${arg0}";

  static String m28(arg0) =>
      "Your account will be deleted on ${arg0}, if you continue to log in, the request to delete your account will be cancelled.";

  static String m29(arg0) =>
      "We will send a 4-digit code to your phone number ${arg0}, please enter the code in next screen.";

  static String m30(arg0) => "Enter the 4-digit code sent to you at ${arg0}";

  static String m31(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} Minute', other: '${arg0} Minutes')}";

  static String m32(arg0) => "My Mixin ID: ${arg0}";

  static String m33(arg0, arg1) =>
      "Mixin Messenger ${arg0} is now available, you have ${arg1}. Would you like to download it now?";

  static String m34(arg0) => "${arg0} now an admin";

  static String m35(arg0) => "Open Link: ${arg0}";

  static String m36(arg0) => "${arg0} PARTICIPANTS";

  static String m37(count, arg0, arg1) =>
      "${Intl.plural(count, one: '${arg0}/${arg1} confirmation', other: '${arg0}/${arg1} confirmations')}";

  static String m38(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} Pinned Message', other: '${arg0} Pinned Messages')}";

  static String m39(arg0) => "Resend code in ${arg0} s";

  static String m40(count, arg0) =>
      "${Intl.plural(count, one: '${arg0} related message', other: '${arg0} related messages')}";

  static String m41(arg0, arg1) =>
      "${arg0} set disappearing message time to ${arg1}";

  static String m42(arg0) =>
      "If you continue, your profile and account details will be delete on ${arg0}. read our document to **learn more**.";

  static String m43(arg0, arg1) =>
      "Are you sure you want to send a ${arg0} from ${arg1}?";

  static String m44(arg0) => "Are you sure you want to send the ${arg0}?";

  static String m45(arg0) => "Unable to open file: ${arg0}";

  static String m46(count) =>
      "${Intl.plural(count, one: 'day', other: 'days')}";

  static String m47(count) =>
      "${Intl.plural(count, one: 'hour', other: 'hours')}";

  static String m48(count) =>
      "${Intl.plural(count, one: 'minute', other: 'minutes')}";

  static String m49(count) =>
      "${Intl.plural(count, one: 'second', other: 'seconds')}";

  static String m50(count) =>
      "${Intl.plural(count, one: 'week', other: 'weeks')}";

  static String m51(arg0) => "value now ${arg0}";

  static String m52(arg0) => "value then ${arg0}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aMessage": MessageLookupByLibrary.simpleMessage("a message"),
        "about": MessageLookupByLibrary.simpleMessage("About"),
        "accessDenied": MessageLookupByLibrary.simpleMessage("Access denied"),
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "activity": MessageLookupByLibrary.simpleMessage("Activity"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addBotWithPlus": MessageLookupByLibrary.simpleMessage("+ Add Bot"),
        "addContact": MessageLookupByLibrary.simpleMessage("Add Contact"),
        "addContactWithPlus":
            MessageLookupByLibrary.simpleMessage("+ Add Contact"),
        "addFile": MessageLookupByLibrary.simpleMessage("Add File"),
        "addGroupDescription":
            MessageLookupByLibrary.simpleMessage("Add group description"),
        "addParticipants":
            MessageLookupByLibrary.simpleMessage("Add Participants"),
        "addPeopleSearchHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID or Phone number"),
        "addProxy": MessageLookupByLibrary.simpleMessage("Add Proxy"),
        "addSticker": MessageLookupByLibrary.simpleMessage("Add Sticker"),
        "addStickerFailed":
            MessageLookupByLibrary.simpleMessage("Add sticker failed"),
        "addStickers": MessageLookupByLibrary.simpleMessage("Add Stickers"),
        "addToCircle": MessageLookupByLibrary.simpleMessage("Add to Circle"),
        "added": MessageLookupByLibrary.simpleMessage("Added"),
        "address": MessageLookupByLibrary.simpleMessage("Address"),
        "admin": MessageLookupByLibrary.simpleMessage("Admin"),
        "alertKeyContactContactMessage":
            MessageLookupByLibrary.simpleMessage("sent you a contact"),
        "allChats": MessageLookupByLibrary.simpleMessage("Chats"),
        "animalsAndNature":
            MessageLookupByLibrary.simpleMessage("Animals & Nature"),
        "anonymousNumber":
            MessageLookupByLibrary.simpleMessage("Anonymous Number"),
        "appCardShareDisallow": MessageLookupByLibrary.simpleMessage(
            "Disallow sharing of this URL"),
        "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
        "archivedFolder":
            MessageLookupByLibrary.simpleMessage("archived folder"),
        "assetType": MessageLookupByLibrary.simpleMessage("Asset Type"),
        "audio": MessageLookupByLibrary.simpleMessage("Audio"),
        "audios": MessageLookupByLibrary.simpleMessage("Audios"),
        "autoBackup": MessageLookupByLibrary.simpleMessage("Auto Backup"),
        "autoLock": MessageLookupByLibrary.simpleMessage("Auto Lock"),
        "avatar": MessageLookupByLibrary.simpleMessage("Avatar"),
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "biography": MessageLookupByLibrary.simpleMessage("Biography"),
        "block": MessageLookupByLibrary.simpleMessage("Block"),
        "botNotFound": MessageLookupByLibrary.simpleMessage("Bot not found"),
        "bots": MessageLookupByLibrary.simpleMessage("BOTS"),
        "botsTitle": MessageLookupByLibrary.simpleMessage("Bots"),
        "bringAllToFront":
            MessageLookupByLibrary.simpleMessage("Bring All To Front"),
        "canNotRecognizeQrCode": MessageLookupByLibrary.simpleMessage(
            "Can not recognize the QR code"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "card": MessageLookupByLibrary.simpleMessage("Card"),
        "change": MessageLookupByLibrary.simpleMessage("Change"),
        "changeNumber": MessageLookupByLibrary.simpleMessage("Change Number"),
        "changeNumberInstead":
            MessageLookupByLibrary.simpleMessage("Change Number Instead"),
        "changedDisappearingMessageSettings": m0,
        "chatBackup": MessageLookupByLibrary.simpleMessage("Chat Backup"),
        "chatBotReceptionTitle": MessageLookupByLibrary.simpleMessage(
            "Tap the button to interact with the bot"),
        "chatDecryptionFailedHint": m1,
        "chatDeleteMessage": m2,
        "chatGroupAdd": m3,
        "chatGroupExit": m4,
        "chatGroupJoin": m5,
        "chatGroupRemove": m6,
        "chatHintE2e":
            MessageLookupByLibrary.simpleMessage("End to end encrypted"),
        "chatNotSupportUriOnPhone": MessageLookupByLibrary.simpleMessage(
            "This type of url is not supported, please check on your phone."),
        "chatNotSupportUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixinmessenger.zendesk.com/hc/articles/360043776071"),
        "chatNotSupportViewOnPhone": MessageLookupByLibrary.simpleMessage(
            "This type of message is not supported, please check on your phone."),
        "chatPinMessage": m7,
        "chatTextSize": MessageLookupByLibrary.simpleMessage("Chat Text Size"),
        "checkNewVersion":
            MessageLookupByLibrary.simpleMessage("Check new version"),
        "circleSubtitle": m8,
        "circleTitle": m9,
        "circles": MessageLookupByLibrary.simpleMessage("Circles"),
        "clear": MessageLookupByLibrary.simpleMessage("Clear"),
        "clearChat": MessageLookupByLibrary.simpleMessage("Clear Chat"),
        "clearFilter": MessageLookupByLibrary.simpleMessage("Clear filter"),
        "clickToReloadQrcode":
            MessageLookupByLibrary.simpleMessage("Click to reload QR code"),
        "close": MessageLookupByLibrary.simpleMessage("Close"),
        "closeWindow": MessageLookupByLibrary.simpleMessage("Close window"),
        "closingBalance":
            MessageLookupByLibrary.simpleMessage("Closing Balance"),
        "collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
        "combineAndForward":
            MessageLookupByLibrary.simpleMessage("Combine and forward"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
        "confirmPasscodeDesc": MessageLookupByLibrary.simpleMessage(
            "Enter again to confirm the passcode"),
        "confirmSyncChatsFromPhone": MessageLookupByLibrary.simpleMessage(
            "Are you sure to sync the chat history from the phone?"),
        "confirmSyncChatsToPhone": MessageLookupByLibrary.simpleMessage(
            "Are you sure to sync the chat history to the phone?"),
        "contact": MessageLookupByLibrary.simpleMessage("Contact"),
        "contactMixinId": m10,
        "contactMuteTitle":
            MessageLookupByLibrary.simpleMessage("Mute notifications for…"),
        "contactTitle": MessageLookupByLibrary.simpleMessage("Contacts"),
        "contentTooLong":
            MessageLookupByLibrary.simpleMessage("Content too long"),
        "contentVoice": MessageLookupByLibrary.simpleMessage("[Voice call]"),
        "continueText": MessageLookupByLibrary.simpleMessage("Continue"),
        "conversation": MessageLookupByLibrary.simpleMessage("Conversation"),
        "conversationDeleteTitle": m11,
        "copy": MessageLookupByLibrary.simpleMessage("Copy"),
        "copyInvite": MessageLookupByLibrary.simpleMessage("Copy Invite Link"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copy Link"),
        "create": MessageLookupByLibrary.simpleMessage("Create"),
        "createCircle": MessageLookupByLibrary.simpleMessage("New Circle"),
        "createConversation":
            MessageLookupByLibrary.simpleMessage("New Conversation"),
        "createGroup": MessageLookupByLibrary.simpleMessage("New Group"),
        "created": m12,
        "createdThisGroup": m13,
        "customTime": MessageLookupByLibrary.simpleMessage("Custom Time"),
        "dark": MessageLookupByLibrary.simpleMessage("Dark"),
        "dataAndStorageUsage":
            MessageLookupByLibrary.simpleMessage("Data and Storage Usage"),
        "dataError": MessageLookupByLibrary.simpleMessage("Data error"),
        "dataLoading": MessageLookupByLibrary.simpleMessage(
            "Data loading, please wait..."),
        "databaseUpgradeTips": MessageLookupByLibrary.simpleMessage(
            "The database is being upgraded, it may take several minutes, please do not close this App."),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "deleteAccountDetailHint": MessageLookupByLibrary.simpleMessage(
            "Local messages and iCloud Backups will not be deleted automatically"),
        "deleteAccountHint": MessageLookupByLibrary.simpleMessage(
            "Delete your account info and profile photo"),
        "deleteChat": MessageLookupByLibrary.simpleMessage("Delete Chat"),
        "deleteChatDescription": MessageLookupByLibrary.simpleMessage(
            "Deleting chat will remove messages form this devices only. They will not be removed from other devices."),
        "deleteCircle": MessageLookupByLibrary.simpleMessage("Delete Circle"),
        "deleteForEveryone":
            MessageLookupByLibrary.simpleMessage("Delete for Everyone"),
        "deleteForMe": MessageLookupByLibrary.simpleMessage("Delete for me"),
        "deleteGroup": MessageLookupByLibrary.simpleMessage("Delete Group"),
        "deleteMyAccount":
            MessageLookupByLibrary.simpleMessage("Delete My Account"),
        "deleteTheCircle": m14,
        "deposit": MessageLookupByLibrary.simpleMessage("Deposit"),
        "developer": MessageLookupByLibrary.simpleMessage("Developer"),
        "disableDisappearingMessage": m15,
        "disabled": MessageLookupByLibrary.simpleMessage("Disabled"),
        "disappearingCustomTimeMaxWarning": m16,
        "disappearingMessage":
            MessageLookupByLibrary.simpleMessage("Disappearing Messages"),
        "disappearingMessageHint": MessageLookupByLibrary.simpleMessage(
            "When enabled, new messages sent and received in this chat will disappear after they have been seen, read the document to **learn more**."),
        "discard": MessageLookupByLibrary.simpleMessage("Discard"),
        "discardRecordingWarning": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to stop recording and discard your voice message?"),
        "dismissAsAdmin":
            MessageLookupByLibrary.simpleMessage("Dismiss as Admin"),
        "done": MessageLookupByLibrary.simpleMessage("Done"),
        "download": MessageLookupByLibrary.simpleMessage("Download"),
        "downloadLink": MessageLookupByLibrary.simpleMessage("Download Link:"),
        "draft": MessageLookupByLibrary.simpleMessage("Draft"),
        "dragAndDropFileHere":
            MessageLookupByLibrary.simpleMessage("Drag and drop files here"),
        "durationIsTooShort":
            MessageLookupByLibrary.simpleMessage("Duration is too short"),
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "editCircleName":
            MessageLookupByLibrary.simpleMessage("Edit Circle Name"),
        "editConversations":
            MessageLookupByLibrary.simpleMessage("Edit Conversations"),
        "editGroupDescription":
            MessageLookupByLibrary.simpleMessage("Edit Group Description"),
        "editGroupName":
            MessageLookupByLibrary.simpleMessage("Edit Group Name"),
        "editImageClearWarning": MessageLookupByLibrary.simpleMessage(
            "All changes will be lost. Are you sure you want to exit?"),
        "editName": MessageLookupByLibrary.simpleMessage("Edit Name"),
        "editProfile": MessageLookupByLibrary.simpleMessage("Edit Profile"),
        "enterPinToDeleteAccount": MessageLookupByLibrary.simpleMessage(
            "Enter your PIN to delete your account"),
        "enterToSend":
            MessageLookupByLibrary.simpleMessage("Return/Enter ⏎ to Send"),
        "enterYourPhoneNumber":
            MessageLookupByLibrary.simpleMessage("Enter your phone number"),
        "enterYourPinToContinue":
            MessageLookupByLibrary.simpleMessage("Enter your PIN to continue"),
        "errorAddressExists": MessageLookupByLibrary.simpleMessage(
            "The address does not exist, please make sure that the address is added successfully"),
        "errorAddressNotSync": MessageLookupByLibrary.simpleMessage(
            "Address refresh failed, please try again"),
        "errorAssetExists":
            MessageLookupByLibrary.simpleMessage("Asset does not exist"),
        "errorAuthentication": MessageLookupByLibrary.simpleMessage(
            "ERROR 401: Sign in to continue"),
        "errorBadData": MessageLookupByLibrary.simpleMessage(
            "ERROR 10002: The request data has invalid field"),
        "errorBlockchain": MessageLookupByLibrary.simpleMessage(
            "ERROR 30100: Blockchain not in sync, please try again later."),
        "errorConnectionTimeout": MessageLookupByLibrary.simpleMessage(
            "Network connection timeout, please try again"),
        "errorFullGroup": MessageLookupByLibrary.simpleMessage(
            "ERROR 20116: The group chat is full."),
        "errorInsufficientBalance": MessageLookupByLibrary.simpleMessage(
            "ERROR 20117: Insufficient balance"),
        "errorInsufficientTransactionFeeWithAmount": m17,
        "errorInvalidAddress": m18,
        "errorInvalidAddressPlain": MessageLookupByLibrary.simpleMessage(
            "ERROR 30102: Invalid address format."),
        "errorInvalidCodeTooFrequent": MessageLookupByLibrary.simpleMessage(
            "ERROR 20129: Send verification code too frequent, please try again later."),
        "errorInvalidEmergencyContact": MessageLookupByLibrary.simpleMessage(
            "ERROR 20130: Invalid emergency contact"),
        "errorInvalidPinFormat": MessageLookupByLibrary.simpleMessage(
            "ERROR 20118: Invalid PIN format."),
        "errorNetworkTaskFailed": MessageLookupByLibrary.simpleMessage(
            "Network connection failed. Check or switch your network and try again"),
        "errorNoPinToken": MessageLookupByLibrary.simpleMessage(
            "No token, Please log in again and try this feature again."),
        "errorNotFound":
            MessageLookupByLibrary.simpleMessage("ERROR 404: Not found"),
        "errorNotSupportedAudioFormat": MessageLookupByLibrary.simpleMessage(
            "Not supported audio format, please open by other app."),
        "errorNumberReachedLimit": MessageLookupByLibrary.simpleMessage(
            "ERROR 20132: The number has reached the limit."),
        "errorOldVersion": m19,
        "errorOpenLocation":
            MessageLookupByLibrary.simpleMessage("Can\'t find an map app"),
        "errorPermission": MessageLookupByLibrary.simpleMessage(
            "Please open the necessary permissions"),
        "errorPhoneInvalidFormat": MessageLookupByLibrary.simpleMessage(
            "ERROR 20110: Invalid phone number"),
        "errorPhoneSmsDelivery": MessageLookupByLibrary.simpleMessage(
            "ERROR 10003: Failed to deliver SMS"),
        "errorPhoneVerificationCodeExpired":
            MessageLookupByLibrary.simpleMessage(
                "ERROR 20114: Expired phone verification code"),
        "errorPhoneVerificationCodeInvalid":
            MessageLookupByLibrary.simpleMessage(
                "ERROR 20113: Invalid phone verification code"),
        "errorPinCheckTooManyRequest": MessageLookupByLibrary.simpleMessage(
            "You have tried more than 5 times, please wait at least 24 hours to try again."),
        "errorPinIncorrect":
            MessageLookupByLibrary.simpleMessage("ERROR 20119: PIN incorrect"),
        "errorPinIncorrectWithTimes": m20,
        "errorRecaptchaIsInvalid": MessageLookupByLibrary.simpleMessage(
            "ERROR 10004: Recaptcha is invalid"),
        "errorServer5xxCode": m21,
        "errorTooManyRequest": MessageLookupByLibrary.simpleMessage(
            "ERROR 429: Rate limit exceeded"),
        "errorTooManyStickers": MessageLookupByLibrary.simpleMessage(
            "ERROR 20126: Too many stickers"),
        "errorTooSmallTransferAmount": MessageLookupByLibrary.simpleMessage(
            "ERROR 20120: Transfer amount is too small"),
        "errorTooSmallWithdrawAmount": MessageLookupByLibrary.simpleMessage(
            "ERROR 20127: Withdraw amount too small"),
        "errorTranscriptForward": MessageLookupByLibrary.simpleMessage(
            "Please forward all attachments after they have been downloaded"),
        "errorUnableToOpenMedia": MessageLookupByLibrary.simpleMessage(
            "Can\'t find an app able to open this media."),
        "errorUnknownWithCode": m22,
        "errorUnknownWithMessage": m23,
        "errorUploadAttachmentFailed": MessageLookupByLibrary.simpleMessage(
            "Failed to upload message attachment"),
        "errorUsedPhone": MessageLookupByLibrary.simpleMessage(
            "ERROR 20122: This phone number is already associated with another account."),
        "errorUserInvalidFormat":
            MessageLookupByLibrary.simpleMessage("Invalid user id"),
        "errorWithdrawalMemoFormatIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "ERROR 20131: Withdrawal memo format incorrect."),
        "exit": MessageLookupByLibrary.simpleMessage("Exit"),
        "exitGroup": MessageLookupByLibrary.simpleMessage("Exit Group"),
        "failed": MessageLookupByLibrary.simpleMessage("Failed"),
        "fee": MessageLookupByLibrary.simpleMessage("Fee"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "fileChooserError":
            MessageLookupByLibrary.simpleMessage("File chooser error"),
        "fileDoesNotExist":
            MessageLookupByLibrary.simpleMessage("File does not exist"),
        "fileError": MessageLookupByLibrary.simpleMessage("File error"),
        "files": MessageLookupByLibrary.simpleMessage("Files"),
        "flags": MessageLookupByLibrary.simpleMessage("Flags"),
        "followSystem": MessageLookupByLibrary.simpleMessage("Follow System"),
        "followUsOnFacebook":
            MessageLookupByLibrary.simpleMessage("Follow us on Facebook"),
        "followUsOnTwitter":
            MessageLookupByLibrary.simpleMessage("Follow us on Twitter"),
        "foodAndDrink": MessageLookupByLibrary.simpleMessage("Food & Drink"),
        "formatNotSupported":
            MessageLookupByLibrary.simpleMessage("Format not supported"),
        "forward": MessageLookupByLibrary.simpleMessage("Forward"),
        "from": MessageLookupByLibrary.simpleMessage("From"),
        "fromWithColon": MessageLookupByLibrary.simpleMessage("From:"),
        "groupAlreadyIn":
            MessageLookupByLibrary.simpleMessage("You already in the group"),
        "groupCantSend": MessageLookupByLibrary.simpleMessage(
            "You can\'t send messages to this group because you\'re no longer a participant."),
        "groupName": MessageLookupByLibrary.simpleMessage("Group Name"),
        "groupParticipants":
            MessageLookupByLibrary.simpleMessage("Participants"),
        "groupPopMenuMessage": m24,
        "groupPopMenuRemove": m25,
        "groups": MessageLookupByLibrary.simpleMessage("Groups"),
        "groupsInCommon":
            MessageLookupByLibrary.simpleMessage("Groups In Common"),
        "help": MessageLookupByLibrary.simpleMessage("Help"),
        "helpCenter": MessageLookupByLibrary.simpleMessage("Help center"),
        "hideMixin": MessageLookupByLibrary.simpleMessage("Hide Mixin"),
        "host": MessageLookupByLibrary.simpleMessage("Host"),
        "hour": m26,
        "howAreYou": MessageLookupByLibrary.simpleMessage("Hi, how are you?"),
        "iAmGood": MessageLookupByLibrary.simpleMessage("I’m good."),
        "ignoreThisVersion":
            MessageLookupByLibrary.simpleMessage("Ignore the new version"),
        "image": MessageLookupByLibrary.simpleMessage("image"),
        "includeFiles": MessageLookupByLibrary.simpleMessage("Include Files"),
        "includeVideos": MessageLookupByLibrary.simpleMessage("Include Videos"),
        "initializing": MessageLookupByLibrary.simpleMessage("Initializing…"),
        "inviteInfo": MessageLookupByLibrary.simpleMessage(
            "Anyone with Mixin can follow this link to join this group. Only share it with people you trust."),
        "inviteToGroupViaLink":
            MessageLookupByLibrary.simpleMessage("Invite to Group via Link"),
        "joinGroupWithPlus":
            MessageLookupByLibrary.simpleMessage("+ Join group"),
        "joinedIn": m27,
        "landingDeleteContent": m28,
        "landingInvitationDialogContent": m29,
        "landingValidationTitle": m30,
        "learnMore": MessageLookupByLibrary.simpleMessage("Learn More"),
        "less": MessageLookupByLibrary.simpleMessage("less"),
        "light": MessageLookupByLibrary.simpleMessage("Light"),
        "linkedDevice": MessageLookupByLibrary.simpleMessage("linked device"),
        "live": MessageLookupByLibrary.simpleMessage("Live"),
        "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
        "loadingTime": MessageLookupByLibrary.simpleMessage(
            "System time is unusual, please continue to use again after correction"),
        "locateToChat": MessageLookupByLibrary.simpleMessage("locate to chat"),
        "location": MessageLookupByLibrary.simpleMessage("Location"),
        "lock": MessageLookupByLibrary.simpleMessage("Lock"),
        "logIn": MessageLookupByLibrary.simpleMessage("Log in"),
        "loginAndAbortAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Continue to log in and abort account deletion"),
        "loginByQrcode": MessageLookupByLibrary.simpleMessage(
            "Login to Mixin Messenger by QR Code"),
        "loginByQrcodeTips1": MessageLookupByLibrary.simpleMessage(
            "Open Mixin Messenger on your phone."),
        "loginByQrcodeTips2": MessageLookupByLibrary.simpleMessage(
            "Scan the QR Code on the screen and confirm your login."),
        "makeGroupAdmin":
            MessageLookupByLibrary.simpleMessage("Make group admin"),
        "media": MessageLookupByLibrary.simpleMessage("Media"),
        "memo": MessageLookupByLibrary.simpleMessage("Memo"),
        "messageE2ee": MessageLookupByLibrary.simpleMessage(
            "Messages to this conversation are encrypted end-to-end, tap for more info."),
        "messageNotFound":
            MessageLookupByLibrary.simpleMessage("Message not found"),
        "messageNotSupport": MessageLookupByLibrary.simpleMessage(
            "This type of message is not supported, please upgrade Mixin to the latest version."),
        "messagePreview":
            MessageLookupByLibrary.simpleMessage("Message Preview"),
        "messagePreviewDescription": MessageLookupByLibrary.simpleMessage(
            "Preview message text inside new message notifications."),
        "messages": MessageLookupByLibrary.simpleMessage("Messages"),
        "minimize": MessageLookupByLibrary.simpleMessage("Minimize"),
        "minute": m31,
        "mixinMessengerDesktop":
            MessageLookupByLibrary.simpleMessage("Mixin Messenger Desktop"),
        "more": MessageLookupByLibrary.simpleMessage("More"),
        "multisigTransaction":
            MessageLookupByLibrary.simpleMessage("Multisig Transaction"),
        "mute": MessageLookupByLibrary.simpleMessage("Mute"),
        "myMixinId": m32,
        "myStickers": MessageLookupByLibrary.simpleMessage("My Stickers"),
        "na": MessageLookupByLibrary.simpleMessage("N/A"),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "networkConnectionFailed":
            MessageLookupByLibrary.simpleMessage("Network connection failed"),
        "networkError": MessageLookupByLibrary.simpleMessage("Network error"),
        "newVersionAvailable":
            MessageLookupByLibrary.simpleMessage("New version available"),
        "newVersionDescription": m33,
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "nextConversation":
            MessageLookupByLibrary.simpleMessage("Next conversation"),
        "noAudio": MessageLookupByLibrary.simpleMessage("NO AUDIO"),
        "noCamera": MessageLookupByLibrary.simpleMessage("No camera"),
        "noData": MessageLookupByLibrary.simpleMessage("No Data"),
        "noFiles": MessageLookupByLibrary.simpleMessage("NO FILES"),
        "noLinks": MessageLookupByLibrary.simpleMessage("NO LINKS"),
        "noMedia": MessageLookupByLibrary.simpleMessage("NO MEDIA"),
        "noNetworkConnection":
            MessageLookupByLibrary.simpleMessage("No network connection"),
        "noPosts": MessageLookupByLibrary.simpleMessage("NO POSTS"),
        "noResults": MessageLookupByLibrary.simpleMessage("NO RESULTS"),
        "notFound": MessageLookupByLibrary.simpleMessage("Not found"),
        "notificationContent": MessageLookupByLibrary.simpleMessage(
            "Don\'t miss messages from your friends."),
        "notificationPermissionManually": MessageLookupByLibrary.simpleMessage(
            "Notifications are not allowed, please go to Notification Settings to turn on."),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
        "nowAnAddmin": m34,
        "objects": MessageLookupByLibrary.simpleMessage("Objects"),
        "oneByOneForward":
            MessageLookupByLibrary.simpleMessage("One-by-One Forward"),
        "oneHour": MessageLookupByLibrary.simpleMessage("1 Hour"),
        "oneWeek": MessageLookupByLibrary.simpleMessage("1 Week"),
        "oneYear": MessageLookupByLibrary.simpleMessage("1 Year"),
        "openHomePage": MessageLookupByLibrary.simpleMessage("Open Home page"),
        "openLink": m35,
        "openLogDirectory":
            MessageLookupByLibrary.simpleMessage("open log directory"),
        "openingBalance":
            MessageLookupByLibrary.simpleMessage("Opening Balance"),
        "originalImage": MessageLookupByLibrary.simpleMessage("Original"),
        "owner": MessageLookupByLibrary.simpleMessage("Owner"),
        "participantsCount": m36,
        "passcodeIncorrect":
            MessageLookupByLibrary.simpleMessage("Passcode incorrect"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "pendingConfirmation": m37,
        "phoneNumber": MessageLookupByLibrary.simpleMessage("Phone Number"),
        "photos": MessageLookupByLibrary.simpleMessage("Photos"),
        "pickAConversation": MessageLookupByLibrary.simpleMessage(
            "Select a conversation and start sending a message"),
        "pinTitle": MessageLookupByLibrary.simpleMessage("Pin"),
        "pinnedMessageTitle": m38,
        "port": MessageLookupByLibrary.simpleMessage("Port"),
        "post": MessageLookupByLibrary.simpleMessage("Post"),
        "preferences": MessageLookupByLibrary.simpleMessage("Preferences"),
        "previousConversation":
            MessageLookupByLibrary.simpleMessage("Previous conversation"),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "proxy": MessageLookupByLibrary.simpleMessage("Proxy"),
        "proxyAuth":
            MessageLookupByLibrary.simpleMessage("Authentication (Optional)"),
        "proxyConnection": MessageLookupByLibrary.simpleMessage("Connection"),
        "proxyType": MessageLookupByLibrary.simpleMessage("Proxy Type"),
        "quickSearch": MessageLookupByLibrary.simpleMessage("Quick search"),
        "quitMixin": MessageLookupByLibrary.simpleMessage("Quit Mixin"),
        "raw": MessageLookupByLibrary.simpleMessage("Raw"),
        "rebate": MessageLookupByLibrary.simpleMessage("Rebate"),
        "recaptchaTimeout":
            MessageLookupByLibrary.simpleMessage("Recaptcha timeout"),
        "receiver": MessageLookupByLibrary.simpleMessage("Receiver"),
        "recentChats": MessageLookupByLibrary.simpleMessage("CHATS"),
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
        "reportAndBlock":
            MessageLookupByLibrary.simpleMessage("Report and block?"),
        "reportTitle": MessageLookupByLibrary.simpleMessage(
            "Send the conversation log to developers?"),
        "resendCode": MessageLookupByLibrary.simpleMessage("Resend code"),
        "resendCodeIn": m39,
        "reset": MessageLookupByLibrary.simpleMessage("Reset"),
        "resetLink": MessageLookupByLibrary.simpleMessage("Reset Link"),
        "retry": MessageLookupByLibrary.simpleMessage("Retry"),
        "retryUploadFailed":
            MessageLookupByLibrary.simpleMessage("Retry upload failed."),
        "revokeMultisigTransaction":
            MessageLookupByLibrary.simpleMessage("Revoke Multisig Transaction"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "saveAs": MessageLookupByLibrary.simpleMessage("Save as"),
        "saveToCameraRoll":
            MessageLookupByLibrary.simpleMessage("Save to Camera Roll"),
        "sayHi": MessageLookupByLibrary.simpleMessage("Say Hi"),
        "scamWarning": MessageLookupByLibrary.simpleMessage(
            "Warning: Many users reported this account as a scam. Please be careful, especially if it asks you for money"),
        "screenPasscode":
            MessageLookupByLibrary.simpleMessage("Screen Passcode"),
        "search": MessageLookupByLibrary.simpleMessage("Search"),
        "searchContact": MessageLookupByLibrary.simpleMessage("Search contact"),
        "searchConversation":
            MessageLookupByLibrary.simpleMessage("Search Conversation"),
        "searchEmpty": MessageLookupByLibrary.simpleMessage(
            "No chats, contacts or messages found."),
        "searchPlaceholderNumber": MessageLookupByLibrary.simpleMessage(
            "Search Mixin ID or phone number:"),
        "searchRelatedMessage": m40,
        "searchUnread": MessageLookupByLibrary.simpleMessage("Search Unread"),
        "secretUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixin.one/pages/1000007"),
        "security": MessageLookupByLibrary.simpleMessage("Security"),
        "select": MessageLookupByLibrary.simpleMessage("Select"),
        "send": MessageLookupByLibrary.simpleMessage("Send"),
        "sendArchived": MessageLookupByLibrary.simpleMessage(
            "Archived all files in one zip file"),
        "sendQuickly": MessageLookupByLibrary.simpleMessage("Send quickly"),
        "sendToDeveloper":
            MessageLookupByLibrary.simpleMessage("Send to Developer"),
        "sendWithoutCompression":
            MessageLookupByLibrary.simpleMessage("Send without compression"),
        "sendWithoutSound":
            MessageLookupByLibrary.simpleMessage("Send Without Sound"),
        "set": MessageLookupByLibrary.simpleMessage("Set"),
        "setDisappearingMessageTimeTo": m41,
        "setPasscodeDesc": MessageLookupByLibrary.simpleMessage(
            "Set Passcode to unlock Mixin Messenger"),
        "settingAuthSearchHint":
            MessageLookupByLibrary.simpleMessage("Mixin ID, Name"),
        "settingBackupTips": MessageLookupByLibrary.simpleMessage(
            "Back up your chat history to iCloud. if you lose your iPhone or switch to a new one, you can restore your chat history when you reinstall Mixin Messenger. Messages you back up are not protected by Mixin Messenger end-to-end encryption while in iCloud."),
        "settingDeleteAccountPinContent": m42,
        "settingDeleteAccountUrl": MessageLookupByLibrary.simpleMessage(
            "https://mixinmessenger.zendesk.com/hc/articles/4414170627988"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "shareApps": MessageLookupByLibrary.simpleMessage("Shared Apps"),
        "shareContact": MessageLookupByLibrary.simpleMessage("Share Contact"),
        "shareError": MessageLookupByLibrary.simpleMessage("Share error."),
        "shareLink": MessageLookupByLibrary.simpleMessage("Share Link"),
        "shareMessageDescription": m43,
        "shareMessageDescriptionEmpty": m44,
        "sharedMedia": MessageLookupByLibrary.simpleMessage("Shared Media"),
        "show": MessageLookupByLibrary.simpleMessage("Show"),
        "showAvatar": MessageLookupByLibrary.simpleMessage("Show avatar"),
        "showMixin": MessageLookupByLibrary.simpleMessage("Show Mixin"),
        "signIn": MessageLookupByLibrary.simpleMessage("Sign in"),
        "signOut": MessageLookupByLibrary.simpleMessage("Sign Out"),
        "signWithPhoneNumber":
            MessageLookupByLibrary.simpleMessage("Sign in with phone number"),
        "signWithQrcode":
            MessageLookupByLibrary.simpleMessage("Sign in with QR code"),
        "smileysAndPeople":
            MessageLookupByLibrary.simpleMessage("Smileys & People"),
        "snapshotHash": MessageLookupByLibrary.simpleMessage("Snapshot Hash"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "sticker": MessageLookupByLibrary.simpleMessage("Sticker"),
        "stickerAlbumDetail":
            MessageLookupByLibrary.simpleMessage("Sticker album detail"),
        "stickerStore": MessageLookupByLibrary.simpleMessage("Sticker Store"),
        "storageAutoDownloadDescription": MessageLookupByLibrary.simpleMessage(
            "Change auto-download settings for medias."),
        "storageUsage": MessageLookupByLibrary.simpleMessage("Storage Usage"),
        "strangerHint": MessageLookupByLibrary.simpleMessage(
            "This sender is not in your contacts"),
        "strangers": MessageLookupByLibrary.simpleMessage("Strangers"),
        "successful": MessageLookupByLibrary.simpleMessage("Successful"),
        "symbols": MessageLookupByLibrary.simpleMessage("Symbols"),
        "termsOfService":
            MessageLookupByLibrary.simpleMessage("Terms of Service"),
        "text": MessageLookupByLibrary.simpleMessage("Text"),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "thisMessageWasDeleted":
            MessageLookupByLibrary.simpleMessage("This message was deleted"),
        "time": MessageLookupByLibrary.simpleMessage("Time"),
        "today": MessageLookupByLibrary.simpleMessage("Today"),
        "toggleChatInfo":
            MessageLookupByLibrary.simpleMessage("Toggle chat info"),
        "trace": MessageLookupByLibrary.simpleMessage("Trace"),
        "transactionHash":
            MessageLookupByLibrary.simpleMessage("Transaction Hash"),
        "transactionId": MessageLookupByLibrary.simpleMessage("Transaction Id"),
        "transactionType":
            MessageLookupByLibrary.simpleMessage("Transaction Type"),
        "transactions": MessageLookupByLibrary.simpleMessage("Transactions"),
        "transactionsCannotBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Transactions CANNOT be deleted"),
        "transcript": MessageLookupByLibrary.simpleMessage("Transcript"),
        "transfer": MessageLookupByLibrary.simpleMessage("Transfer"),
        "transferCompleted":
            MessageLookupByLibrary.simpleMessage("Transfer completed"),
        "transferFailed":
            MessageLookupByLibrary.simpleMessage("Transfer failed"),
        "transferProtocolVersionNotMatched": MessageLookupByLibrary.simpleMessage(
            "Protocol version does not match, transfer failed. Please upgrade the application first."),
        "transferringChats":
            MessageLookupByLibrary.simpleMessage("Transferring Chat"),
        "transferringChatsTips": MessageLookupByLibrary.simpleMessage(
            "Please do not turn off the screen and keep the Mixin running in the foreground while syncing."),
        "travelAndPlaces":
            MessageLookupByLibrary.simpleMessage("Travel & Places"),
        "turnOnNotifications":
            MessageLookupByLibrary.simpleMessage("Turn On Notifications"),
        "typeMessage": MessageLookupByLibrary.simpleMessage("Type message"),
        "unableToOpenFile": m45,
        "unblock": MessageLookupByLibrary.simpleMessage("Unblock"),
        "unitDay": m46,
        "unitHour": m47,
        "unitMinute": m48,
        "unitSecond": m49,
        "unitWeek": m50,
        "unknowError": MessageLookupByLibrary.simpleMessage("Unknow error"),
        "unlockWithWasscode": MessageLookupByLibrary.simpleMessage(
            "Enter Passcode to unlock Mixin Messenger"),
        "unmute": MessageLookupByLibrary.simpleMessage("Unmute"),
        "unpin": MessageLookupByLibrary.simpleMessage("Unpin"),
        "unpinAllMessages":
            MessageLookupByLibrary.simpleMessage("Unpin All Messages"),
        "unpinAllMessagesConfirmation": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to unpin all messages?"),
        "unreadMessages":
            MessageLookupByLibrary.simpleMessage("Unread messages"),
        "upgrading": MessageLookupByLibrary.simpleMessage("Upgrading"),
        "userNotFound": MessageLookupByLibrary.simpleMessage("User not found"),
        "username": MessageLookupByLibrary.simpleMessage("Username"),
        "valueNow": m51,
        "valueThen": m52,
        "verifyPin": MessageLookupByLibrary.simpleMessage("Verify PIN"),
        "video": MessageLookupByLibrary.simpleMessage("Video"),
        "videos": MessageLookupByLibrary.simpleMessage("Videos"),
        "waitingForThisMessage":
            MessageLookupByLibrary.simpleMessage("Waiting for this message."),
        "webview2RuntimeInstallDescription": MessageLookupByLibrary.simpleMessage(
            "The device has not installed the WebView2 Runtime component. Please download and install WebView2 Runtime first."),
        "webviewRuntimeUnavailable": MessageLookupByLibrary.simpleMessage(
            "WebView runtime is unavailable"),
        "whatsYourName":
            MessageLookupByLibrary.simpleMessage("What\'s your name?"),
        "window": MessageLookupByLibrary.simpleMessage("Window"),
        "withdrawal": MessageLookupByLibrary.simpleMessage("Withdraw"),
        "you": MessageLookupByLibrary.simpleMessage("You"),
        "youDeletedThisMessage":
            MessageLookupByLibrary.simpleMessage("You deleted this message"),
        "zoom": MessageLookupByLibrary.simpleMessage("Zoom")
      };
}
