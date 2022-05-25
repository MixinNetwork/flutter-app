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

  static m0(arg0) => "Waiting for ${arg0} to get online and establish an encrypted session.";

  static m1(arg0, arg1) => "${arg0} added ${arg1}";

  static m2(arg0) => "${arg0} left";

  static m3(arg0) => "${arg0} joined the group via invite link";

  static m4(arg0, arg1) => "${arg0} removed ${arg1}";

  static m5(arg0, arg1) => "${arg0} pinned ${arg1}";

  static m6(count, arg0) => "${Intl.plural(count, one: '${arg0} Conversation', other: '${arg0} Conversations')}";

  static m7(arg0) => "${arg0}\'s Circles";

  static m8(arg0) => "Mixin ID: ${arg0}";

  static m9(arg0) => "Delete chat: ${arg0}";

  static m10(arg0) => "${arg0} created this group";

  static m11(arg0) => "Do you want to delete ${arg0} circle?";

  static m12(arg0) => "ERROR ${arg0}: Sign in to continue";

  static m13(arg0) => "ERROR ${arg0}: The request data has invalid field";

  static m14(arg0) => "ERROR ${arg0}: Blockchain not in sync, please try again later.";

  static m15(arg0) => "ERROR ${arg0}: The group chat is full.";

  static m16(arg0) => "ERROR ${arg0}: Insufficient balance";

  static m17(arg0, arg1) => "ERROR ${arg0}: Insufficient transaction fee. Please make sure your wallet has ${arg1} as fee";

  static m18(arg0, arg1, arg2) => "ERROR ${arg0}: Invalid address format. Please enter the correct ${arg1} ${arg2} address!";

  static m19(arg0) => "ERROR ${arg0}: Invalid address format.";

  static m20(arg0) => "ERROR ${arg0}: Send verification code too frequent, please try again later.";

  static m21(arg0) => "ERROR ${arg0}: Invalid emergency contact";

  static m22(arg0) => "ERROR ${arg0}: Invalid PIN format.";

  static m23(arg0) => "ERROR ${arg0}: Not found";

  static m24(arg0) => "ERROR ${arg0}: The number has reached the limit.";

  static m25(arg0, arg1) => "ERROR ${arg0}: Please update Mixin(${arg1}) to continue use the service.";

  static m26(arg0) => "ERROR ${arg0}: Invalid phone number";

  static m27(arg0) => "ERROR ${arg0}: Failed to deliver SMS";

  static m28(arg0) => "ERROR ${arg0}: Expired phone verification code";

  static m29(arg0) => "ERROR ${arg0}: Invalid phone verification code";

  static m30(arg0) => "ERROR ${arg0}: PIN incorrect";

  static m31(count, arg0, arg1) => "${Intl.plural(count, one: 'ERROR ${arg0}: PIN incorrect. You still have ${arg1} chance. Please wait for 24 hours to retry later.', other: 'ERROR ${arg0}: PIN incorrect. You still have ${arg1} chances. Please wait for 24 hours to retry later.')}";

  static m32(arg0) => "ERROR ${arg0}: Recaptcha is invalid";

  static m33(arg0) => "Server is under maintenance: ${arg0}";

  static m34(arg0) => "ERROR ${arg0}: Rate limit exceeded";

  static m35(arg0) => "ERROR ${arg0}: Too many stickers";

  static m36(arg0) => "ERROR ${arg0}: Transfer amount is too small";

  static m37(arg0) => "ERROR ${arg0}: Withdraw amount too small";

  static m38(arg0) => "ERROR: ${arg0}";

  static m39(arg0) => "ERROR: ${arg0}";

  static m40(arg0) => "ERROR ${arg0}: This phone number is already associated with another account.";

  static m41(arg0) => "ERROR ${arg0}: Withdrawal memo format incorrect.";

  static m42(arg0) => "Message ${arg0}";

  static m43(arg0) => "Remove ${arg0}";

  static m44(count) => "${Intl.plural(count, one: '%d Hour', other: '%d Hours')}";

  static m45(arg0) => "Joined in ${arg0}";

  static m46(arg0) => "Your account will be deleted on ${arg0}, if you continue to log in, the request to delete your account will be cancelled.";

  static m47(arg0) => "We will send a 4-digit code to your phone number ${arg0}, please enter the code in next screen.";

  static m48(arg0) => "Enter the 4-digit code sent to you at ${arg0}";

  static m49(arg0) => "My Mixin ID: ${arg0}";

  static m50(arg0, arg1) => "Mixin Messenger ${arg0} is now available, you have ${arg1}. Would you like to download it now?";

  static m51(arg0) => "${arg0} now an admin";

  static m52(arg0) => "${arg0} PARTICIPANTS";

  static m53(count, arg0) => "${Intl.plural(count, one: '${arg0} Pinned Message', other: '${arg0} Pinned Messages')}";

  static m54(arg0) => "Resend code in ${arg0} s";

  static m55(count, arg0) => "${Intl.plural(count, one: '${arg0} related message', other: '${arg0} related messages')}";

  static m56(arg0) => "Unable to open file: ${arg0}";

  static m57(arg0) => "value now ${arg0}";

  static m58(arg0) => "value then ${arg0}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "aMessage" : MessageLookupByLibrary.simpleMessage("a message"),
    "about" : MessageLookupByLibrary.simpleMessage("About"),
    "accessDenied" : MessageLookupByLibrary.simpleMessage("Access denied"),
    "add" : MessageLookupByLibrary.simpleMessage("Add"),
    "addBotWithPlus" : MessageLookupByLibrary.simpleMessage("+ Add Bot"),
    "addContact" : MessageLookupByLibrary.simpleMessage("Add Contact"),
    "addContactWithPlus" : MessageLookupByLibrary.simpleMessage("+ Add Contact"),
    "addFile" : MessageLookupByLibrary.simpleMessage("Add File"),
    "addGroupDescription" : MessageLookupByLibrary.simpleMessage("Add group description"),
    "addParticipants" : MessageLookupByLibrary.simpleMessage("Add Participants"),
    "addPeopleSearchHint" : MessageLookupByLibrary.simpleMessage("Mixin ID or Phone number"),
    "addSticker" : MessageLookupByLibrary.simpleMessage("Add Sticker"),
    "addStickerFailed" : MessageLookupByLibrary.simpleMessage("Add sticker failed"),
    "addStickers" : MessageLookupByLibrary.simpleMessage("Add Stickers"),
    "added" : MessageLookupByLibrary.simpleMessage("Added"),
    "admin" : MessageLookupByLibrary.simpleMessage("Admin"),
    "alertKeyContactContactMessage" : MessageLookupByLibrary.simpleMessage("sent you a contact"),
    "allChats" : MessageLookupByLibrary.simpleMessage("Chats"),
    "appCardShareDisallow" : MessageLookupByLibrary.simpleMessage("Disallow sharing of this URL"),
    "appearance" : MessageLookupByLibrary.simpleMessage("Appearance"),
    "archivedFolder" : MessageLookupByLibrary.simpleMessage("archived folder"),
    "assetType" : MessageLookupByLibrary.simpleMessage("Asset Type"),
    "audio" : MessageLookupByLibrary.simpleMessage("Audio"),
    "audios" : MessageLookupByLibrary.simpleMessage("Audios"),
    "autoBackup" : MessageLookupByLibrary.simpleMessage("Auto Backup"),
    "avatar" : MessageLookupByLibrary.simpleMessage("Avatar"),
    "backup" : MessageLookupByLibrary.simpleMessage("Backup"),
    "biography" : MessageLookupByLibrary.simpleMessage("Biography"),
    "block" : MessageLookupByLibrary.simpleMessage("Block"),
    "bots" : MessageLookupByLibrary.simpleMessage("BOTS"),
    "canNotRecognizeQrCode" : MessageLookupByLibrary.simpleMessage("Can not recognize the QR code"),
    "cancel" : MessageLookupByLibrary.simpleMessage("Cancel"),
    "card" : MessageLookupByLibrary.simpleMessage("Card"),
    "change" : MessageLookupByLibrary.simpleMessage("Change"),
    "chatAppReceptionTitle" : MessageLookupByLibrary.simpleMessage("Tap the button to interact with the bot"),
    "chatBackup" : MessageLookupByLibrary.simpleMessage("Chat Backup"),
    "chatDecryptionFailedHint" : m0,
    "chatGroupAdd" : m1,
    "chatGroupExit" : m2,
    "chatGroupJoin" : m3,
    "chatGroupRemove" : m4,
    "chatHintE2e" : MessageLookupByLibrary.simpleMessage("End to end encrypted"),
    "chatNotSupportUriOnPhone" : MessageLookupByLibrary.simpleMessage("This type of url is not supported, please check on your phone."),
    "chatNotSupportUrl" : MessageLookupByLibrary.simpleMessage("https://mixinmessenger.zendesk.com/hc/articles/360043776071"),
    "chatNotSupportViewOnPhone" : MessageLookupByLibrary.simpleMessage("This type of message is not supported, please check on your phone."),
    "chatPinMessage" : m5,
    "checkNewVersion" : MessageLookupByLibrary.simpleMessage("Check new version"),
    "circleSubtitle" : m6,
    "circleTitle" : m7,
    "circles" : MessageLookupByLibrary.simpleMessage("Circles"),
    "clear" : MessageLookupByLibrary.simpleMessage("Clear"),
    "clearChat" : MessageLookupByLibrary.simpleMessage("Clear Chat"),
    "clickToReloadQrcode" : MessageLookupByLibrary.simpleMessage("Click to reload QR code"),
    "closeWindow" : MessageLookupByLibrary.simpleMessage("Close window"),
    "collapse" : MessageLookupByLibrary.simpleMessage("Collapse"),
    "confirm" : MessageLookupByLibrary.simpleMessage("Confirm"),
    "contact" : MessageLookupByLibrary.simpleMessage("Contact"),
    "contactMixinId" : m8,
    "contactMuteTitle" : MessageLookupByLibrary.simpleMessage("Mute notifications for…"),
    "contacts" : MessageLookupByLibrary.simpleMessage("CONTACTS"),
    "contentTooLong" : MessageLookupByLibrary.simpleMessage("Content too long"),
    "contentVoice" : MessageLookupByLibrary.simpleMessage("[Voice call]"),
    "continueText" : MessageLookupByLibrary.simpleMessage("Continue"),
    "conversation" : MessageLookupByLibrary.simpleMessage("Conversation"),
    "conversationDeleteTitle" : m9,
    "copy" : MessageLookupByLibrary.simpleMessage("Copy"),
    "copyInvite" : MessageLookupByLibrary.simpleMessage("Copy Invite Link"),
    "create" : MessageLookupByLibrary.simpleMessage("Create"),
    "createCircle" : MessageLookupByLibrary.simpleMessage("New Circle"),
    "createConversation" : MessageLookupByLibrary.simpleMessage("New Conversation"),
    "createGroup" : MessageLookupByLibrary.simpleMessage("New Group"),
    "createdThisGroup" : m10,
    "dark" : MessageLookupByLibrary.simpleMessage("Dark"),
    "dataAndStorageUsage" : MessageLookupByLibrary.simpleMessage("Data and Storage Usage"),
    "dataError" : MessageLookupByLibrary.simpleMessage("Data error"),
    "dataLoading" : MessageLookupByLibrary.simpleMessage("Data loading, please wait..."),
    "delete" : MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteChat" : MessageLookupByLibrary.simpleMessage("Delete Chat"),
    "deleteChatDescription" : MessageLookupByLibrary.simpleMessage("Deleting chat will remove messages form this devices only. They will not be removed from other devices."),
    "deleteCircle" : MessageLookupByLibrary.simpleMessage("Delete Circle"),
    "deleteForEveryone" : MessageLookupByLibrary.simpleMessage("Delete for Everyone"),
    "deleteForMe" : MessageLookupByLibrary.simpleMessage("Delete for me"),
    "deleteGroup" : MessageLookupByLibrary.simpleMessage("Delete Group"),
    "deleteTheCircle" : m11,
    "developer" : MessageLookupByLibrary.simpleMessage("Developer"),
    "dismissAsAdmin" : MessageLookupByLibrary.simpleMessage("Dismiss as Admin"),
    "done" : MessageLookupByLibrary.simpleMessage("Done"),
    "download" : MessageLookupByLibrary.simpleMessage("Download"),
    "downloadLink" : MessageLookupByLibrary.simpleMessage("Download Link:"),
    "dragAndDropFileHere" : MessageLookupByLibrary.simpleMessage("Drag and drop files here"),
    "durationIsTooShort" : MessageLookupByLibrary.simpleMessage("Duration is too short"),
    "editCircleName" : MessageLookupByLibrary.simpleMessage("Edit Circle Name"),
    "editGroupDescription" : MessageLookupByLibrary.simpleMessage("Edit Group Description"),
    "editGroupName" : MessageLookupByLibrary.simpleMessage("Edit Group Name"),
    "editImageClearWarning" : MessageLookupByLibrary.simpleMessage("All changes will be lost. Are you sure you want to exit?"),
    "editName" : MessageLookupByLibrary.simpleMessage("Edit Name"),
    "editProfile" : MessageLookupByLibrary.simpleMessage("Edit Profile"),
    "enterYourPhoneNumber" : MessageLookupByLibrary.simpleMessage("Enter your phone number"),
    "errorAddressExists" : MessageLookupByLibrary.simpleMessage("The address does not exist, please make sure that the address is added successfully"),
    "errorAddressNotSync" : MessageLookupByLibrary.simpleMessage("Address refresh failed, please try again"),
    "errorAssetExists" : MessageLookupByLibrary.simpleMessage("Asset does not exist"),
    "errorAuthentication" : m12,
    "errorBadData" : m13,
    "errorBlockchain" : m14,
    "errorConnectionTimeout" : MessageLookupByLibrary.simpleMessage("Network connection timeout, please try again"),
    "errorFullGroup" : m15,
    "errorInsufficientBalance" : m16,
    "errorInsufficientTransactionFeeWithAmount" : m17,
    "errorInvalidAddress" : m18,
    "errorInvalidAddressPlain" : m19,
    "errorInvalidCodeTooFrequent" : m20,
    "errorInvalidEmergencyContact" : m21,
    "errorInvalidPinFormat" : m22,
    "errorNetworkTaskFailed" : MessageLookupByLibrary.simpleMessage("Network connection failed. Check or switch your network and try again"),
    "errorNotFound" : m23,
    "errorNotSupportedAudioFormat" : MessageLookupByLibrary.simpleMessage("Not supported audio format, please open by other app."),
    "errorNumberReachedLimit" : m24,
    "errorOldVersion" : m25,
    "errorOpenLocation" : MessageLookupByLibrary.simpleMessage("Can\'t find an map app"),
    "errorPermission" : MessageLookupByLibrary.simpleMessage("Please open the necessary permissions"),
    "errorPhoneInvalidFormat" : m26,
    "errorPhoneSmsDelivery" : m27,
    "errorPhoneVerificationCodeExpired" : m28,
    "errorPhoneVerificationCodeInvalid" : m29,
    "errorPinCheckTooManyRequest" : MessageLookupByLibrary.simpleMessage("You have tried more than 5 times, please wait at least 24 hours to try again."),
    "errorPinIncorrect" : m30,
    "errorPinIncorrectWithTimes" : m31,
    "errorRecaptchaIsInvalid" : m32,
    "errorServer5xxCode" : m33,
    "errorTooManyRequest" : m34,
    "errorTooManyStickers" : m35,
    "errorTooSmallTransferAmount" : m36,
    "errorTooSmallWithdrawAmount" : m37,
    "errorTranscriptForward" : MessageLookupByLibrary.simpleMessage("Please forward all attachments after they have been downloaded"),
    "errorUnableToOpenMedia" : MessageLookupByLibrary.simpleMessage("Can\'t find an app able to open this media."),
    "errorUnknownWithCode" : m38,
    "errorUnknownWithMessage" : m39,
    "errorUsedPhone" : m40,
    "errorUserInvalidFormat" : MessageLookupByLibrary.simpleMessage("Invalid user id"),
    "errorWithdrawalMemoFormatIncorrect" : m41,
    "exit" : MessageLookupByLibrary.simpleMessage("Exit"),
    "exitGroup" : MessageLookupByLibrary.simpleMessage("Exit Group"),
    "failed" : MessageLookupByLibrary.simpleMessage("Failed"),
    "file" : MessageLookupByLibrary.simpleMessage("File"),
    "fileChooserError" : MessageLookupByLibrary.simpleMessage("File chooser error"),
    "fileDoesNotExist" : MessageLookupByLibrary.simpleMessage("File does not exist"),
    "fileError" : MessageLookupByLibrary.simpleMessage("File error"),
    "files" : MessageLookupByLibrary.simpleMessage("Files"),
    "followSystem" : MessageLookupByLibrary.simpleMessage("Follow System"),
    "followUsOnFacebook" : MessageLookupByLibrary.simpleMessage("Follow us on Facebook"),
    "followUsOnTwitter" : MessageLookupByLibrary.simpleMessage("Follow us on Twitter"),
    "formatNotSupported" : MessageLookupByLibrary.simpleMessage("Format not supported"),
    "forward" : MessageLookupByLibrary.simpleMessage("Forward"),
    "from" : MessageLookupByLibrary.simpleMessage("From"),
    "fromWithColon" : MessageLookupByLibrary.simpleMessage("From:"),
    "groupCantSend" : MessageLookupByLibrary.simpleMessage("You can\'t send messages to this group because you\'re no longer a participant."),
    "groupName" : MessageLookupByLibrary.simpleMessage("Group Name"),
    "groupParticipants" : MessageLookupByLibrary.simpleMessage("Participants"),
    "groupPopMenuMessage" : m42,
    "groupPopMenuRemove" : m43,
    "groups" : MessageLookupByLibrary.simpleMessage("Groups"),
    "groupsInCommon" : MessageLookupByLibrary.simpleMessage("Groups In Common"),
    "help" : MessageLookupByLibrary.simpleMessage("Help"),
    "helpCenter" : MessageLookupByLibrary.simpleMessage("Help center"),
    "hideMixin" : MessageLookupByLibrary.simpleMessage("Hide Mixin"),
    "hour" : m44,
    "ignoreThisVersion" : MessageLookupByLibrary.simpleMessage("Ignore the new version"),
    "image" : MessageLookupByLibrary.simpleMessage("image"),
    "includeFiles" : MessageLookupByLibrary.simpleMessage("Include Files"),
    "includeVideos" : MessageLookupByLibrary.simpleMessage("Include Videos"),
    "initializing" : MessageLookupByLibrary.simpleMessage("Initializing"),
    "inviteInfo" : MessageLookupByLibrary.simpleMessage("Anyone with Mixin can follow this link to join this group. Only share it with people you trust."),
    "inviteToGroupViaLink" : MessageLookupByLibrary.simpleMessage("Invite to Group via Link"),
    "joinGroupWithPlus" : MessageLookupByLibrary.simpleMessage("+ Join group"),
    "joinedIn" : m45,
    "landingDeleteContent" : m46,
    "landingInvitationDialogContent" : m47,
    "landingValidationTitle" : m48,
    "learnMore" : MessageLookupByLibrary.simpleMessage("Learn More"),
    "less" : MessageLookupByLibrary.simpleMessage("less"),
    "light" : MessageLookupByLibrary.simpleMessage("Light"),
    "live" : MessageLookupByLibrary.simpleMessage("Live"),
    "loading" : MessageLookupByLibrary.simpleMessage("Loading..."),
    "loadingTime" : MessageLookupByLibrary.simpleMessage("System time is unusual, please continue to use again after correction"),
    "locateToChat" : MessageLookupByLibrary.simpleMessage("locate to chat"),
    "location" : MessageLookupByLibrary.simpleMessage("Location"),
    "logIn" : MessageLookupByLibrary.simpleMessage("Log in"),
    "loginAndAbortAccountDeletion" : MessageLookupByLibrary.simpleMessage("Continue to log in and abort account deletion"),
    "loginByQrcode" : MessageLookupByLibrary.simpleMessage("Login to Mixin Messenger by QR Code"),
    "loginByQrcodeTips" : MessageLookupByLibrary.simpleMessage("Open Mixin Messenger on your phone, scan the QR Code on the screen and confirm your login."),
    "makeGroupAdmin" : MessageLookupByLibrary.simpleMessage("Make group admin"),
    "media" : MessageLookupByLibrary.simpleMessage("Media"),
    "memo" : MessageLookupByLibrary.simpleMessage("Memo"),
    "messageE2ee" : MessageLookupByLibrary.simpleMessage("Messages to this conversation are encrypted end-to-end, tap for more info."),
    "messageNotFound" : MessageLookupByLibrary.simpleMessage("Message not found"),
    "messageNotSupport" : MessageLookupByLibrary.simpleMessage("This type of message is not supported, please upgrade Mixin to the latest version."),
    "messagePreview" : MessageLookupByLibrary.simpleMessage("Message Preview"),
    "messagePreviewDescription" : MessageLookupByLibrary.simpleMessage("Preview message text inside new message notifications."),
    "messages" : MessageLookupByLibrary.simpleMessage("Messages"),
    "minimize" : MessageLookupByLibrary.simpleMessage("Minimize"),
    "mixinMessengerDesktop" : MessageLookupByLibrary.simpleMessage("Mixin Messenger Desktop"),
    "more" : MessageLookupByLibrary.simpleMessage("More"),
    "mute" : MessageLookupByLibrary.simpleMessage("Mute"),
    "muted" : MessageLookupByLibrary.simpleMessage("Muted"),
    "myMixinId" : m49,
    "myStickers" : MessageLookupByLibrary.simpleMessage("My Stickers"),
    "na" : MessageLookupByLibrary.simpleMessage("N/A"),
    "name" : MessageLookupByLibrary.simpleMessage("Name"),
    "networkError" : MessageLookupByLibrary.simpleMessage("Network error"),
    "newVersionAvailable" : MessageLookupByLibrary.simpleMessage("New version available"),
    "newVersionDescription" : m50,
    "next" : MessageLookupByLibrary.simpleMessage("Next"),
    "nextConversation" : MessageLookupByLibrary.simpleMessage("Next conversation"),
    "noAudio" : MessageLookupByLibrary.simpleMessage("NO AUDIO"),
    "noCamera" : MessageLookupByLibrary.simpleMessage("No camera"),
    "noData" : MessageLookupByLibrary.simpleMessage("No Data"),
    "noFile" : MessageLookupByLibrary.simpleMessage("NO FILE"),
    "noLink" : MessageLookupByLibrary.simpleMessage("NO LINK"),
    "noMedia" : MessageLookupByLibrary.simpleMessage("NO MEDIA"),
    "noNetworkConnection" : MessageLookupByLibrary.simpleMessage("No network connection"),
    "noPost" : MessageLookupByLibrary.simpleMessage("NO POST"),
    "noResult" : MessageLookupByLibrary.simpleMessage("No result"),
    "notFound" : MessageLookupByLibrary.simpleMessage("Not found"),
    "notificationContent" : MessageLookupByLibrary.simpleMessage("Don\'t miss messages from your friends."),
    "notificationPermissionManually" : MessageLookupByLibrary.simpleMessage("Notifications are not allowed, please go to Notification Settings to turn on."),
    "notifications" : MessageLookupByLibrary.simpleMessage("Notifications"),
    "nowAnAddmin" : m51,
    "oneHour" : MessageLookupByLibrary.simpleMessage("1 Hour"),
    "oneWeek" : MessageLookupByLibrary.simpleMessage("1 Week"),
    "oneYear" : MessageLookupByLibrary.simpleMessage("1 Year"),
    "openHomePage" : MessageLookupByLibrary.simpleMessage("Open Home page"),
    "openLogDirectory" : MessageLookupByLibrary.simpleMessage("open log directory"),
    "originalImage" : MessageLookupByLibrary.simpleMessage("Original"),
    "owner" : MessageLookupByLibrary.simpleMessage("Owner"),
    "participantsCount" : m52,
    "phoneNumber" : MessageLookupByLibrary.simpleMessage("Phone Number"),
    "photos" : MessageLookupByLibrary.simpleMessage("Photos"),
    "pickAConversation" : MessageLookupByLibrary.simpleMessage("Select a conversation and start sending a message"),
    "pinTitle" : MessageLookupByLibrary.simpleMessage("Pin"),
    "pinnedMessageTitle" : m53,
    "post" : MessageLookupByLibrary.simpleMessage("Post"),
    "preferences" : MessageLookupByLibrary.simpleMessage("Preferences"),
    "previousConversation" : MessageLookupByLibrary.simpleMessage("Previous conversation"),
    "privacyPolicy" : MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "quickSearch" : MessageLookupByLibrary.simpleMessage("Quick search"),
    "quitMixin" : MessageLookupByLibrary.simpleMessage("Quit Mixin"),
    "recaptchaTimeout" : MessageLookupByLibrary.simpleMessage("Recaptcha timeout"),
    "receiver" : MessageLookupByLibrary.simpleMessage("Receiver"),
    "recentChats" : MessageLookupByLibrary.simpleMessage("CHATS"),
    "reedit" : MessageLookupByLibrary.simpleMessage("Re-edit"),
    "refresh" : MessageLookupByLibrary.simpleMessage("Refresh"),
    "removeBot" : MessageLookupByLibrary.simpleMessage("Remove Bot"),
    "removeChatFromCircle" : MessageLookupByLibrary.simpleMessage("Remove Chat from circle"),
    "removeContact" : MessageLookupByLibrary.simpleMessage("Remove Contact"),
    "removeStickers" : MessageLookupByLibrary.simpleMessage("Remove Stickers"),
    "reply" : MessageLookupByLibrary.simpleMessage("Reply"),
    "report" : MessageLookupByLibrary.simpleMessage("Report"),
    "reportAndBlock" : MessageLookupByLibrary.simpleMessage("Report and block?"),
    "resendCode" : MessageLookupByLibrary.simpleMessage("Resend code"),
    "resendCodeIn" : m54,
    "reset" : MessageLookupByLibrary.simpleMessage("Reset"),
    "resetLink" : MessageLookupByLibrary.simpleMessage("Reset Link"),
    "retryUploadFailed" : MessageLookupByLibrary.simpleMessage("Retry upload failed."),
    "save" : MessageLookupByLibrary.simpleMessage("Save"),
    "saveAs" : MessageLookupByLibrary.simpleMessage("Save as"),
    "saveToCameraRoll" : MessageLookupByLibrary.simpleMessage("Save to Camera Roll"),
    "sayHi" : MessageLookupByLibrary.simpleMessage("Say Hi"),
    "scamWarning" : MessageLookupByLibrary.simpleMessage("Warning: Many users reported this account as a scam. Please be careful, especially if it asks you for money"),
    "search" : MessageLookupByLibrary.simpleMessage("Search"),
    "searchContact" : MessageLookupByLibrary.simpleMessage("Search contact"),
    "searchConversation" : MessageLookupByLibrary.simpleMessage("Search Conversation"),
    "searchEmpty" : MessageLookupByLibrary.simpleMessage("No chats, contacts or messages found."),
    "searchRelatedMessage" : m55,
    "secretUrl" : MessageLookupByLibrary.simpleMessage("https://mixin.one/pages/1000007"),
    "send" : MessageLookupByLibrary.simpleMessage("Send"),
    "sendArchived" : MessageLookupByLibrary.simpleMessage("Archived all files in one zip file"),
    "sendQuickly" : MessageLookupByLibrary.simpleMessage("Send quickly"),
    "sendWithoutCompression" : MessageLookupByLibrary.simpleMessage("Send without compression"),
    "sendWithoutSound" : MessageLookupByLibrary.simpleMessage("Send Without Sound"),
    "settingAuthSearchHint" : MessageLookupByLibrary.simpleMessage("Mixin ID, Name"),
    "settingBackupTips" : MessageLookupByLibrary.simpleMessage("Back up your chat history to iCloud. if you lose your iPhone or switch to a new one, you can restore your chat history when you reinstall Mixin Messenger. Messages you back up are not protected by Mixin Messenger end-to-end encryption while in iCloud."),
    "share" : MessageLookupByLibrary.simpleMessage("Share"),
    "shareApps" : MessageLookupByLibrary.simpleMessage("Shared Apps"),
    "shareContact" : MessageLookupByLibrary.simpleMessage("Share Contact"),
    "shareError" : MessageLookupByLibrary.simpleMessage("Share error."),
    "shareLink" : MessageLookupByLibrary.simpleMessage("Share Link"),
    "sharedMedia" : MessageLookupByLibrary.simpleMessage("Shared Media"),
    "show" : MessageLookupByLibrary.simpleMessage("Show"),
    "showAvatar" : MessageLookupByLibrary.simpleMessage("Show avatar"),
    "showMixin" : MessageLookupByLibrary.simpleMessage("Show Mixin"),
    "signIn" : MessageLookupByLibrary.simpleMessage("Sign in"),
    "signOut" : MessageLookupByLibrary.simpleMessage("Sign Out"),
    "signWithPhoneNumber" : MessageLookupByLibrary.simpleMessage("Sign in with phone number"),
    "signWithQrcode" : MessageLookupByLibrary.simpleMessage("Sign in with QrCode"),
    "sticker" : MessageLookupByLibrary.simpleMessage("Sticker"),
    "stickerAlbumDetail" : MessageLookupByLibrary.simpleMessage("Sticker album detail"),
    "stickerStore" : MessageLookupByLibrary.simpleMessage("Sticker Store"),
    "storageAutoDownloadDescription" : MessageLookupByLibrary.simpleMessage("Change auto-download settings for medias."),
    "storageUsage" : MessageLookupByLibrary.simpleMessage("Storage Usage"),
    "strangerHint" : MessageLookupByLibrary.simpleMessage("This sender is not in your contacts"),
    "strangers" : MessageLookupByLibrary.simpleMessage("Strangers"),
    "successful" : MessageLookupByLibrary.simpleMessage("Successful"),
    "termsOfService" : MessageLookupByLibrary.simpleMessage("Terms of Service"),
    "text" : MessageLookupByLibrary.simpleMessage("Text"),
    "theme" : MessageLookupByLibrary.simpleMessage("Theme"),
    "thisMessageWasDeleted" : MessageLookupByLibrary.simpleMessage("This message was deleted"),
    "time" : MessageLookupByLibrary.simpleMessage("Time"),
    "today" : MessageLookupByLibrary.simpleMessage("Today"),
    "toggleChatInfo" : MessageLookupByLibrary.simpleMessage("Toggle chat info"),
    "transactionId" : MessageLookupByLibrary.simpleMessage("Transaction Id"),
    "transactions" : MessageLookupByLibrary.simpleMessage("Transactions"),
    "transcript" : MessageLookupByLibrary.simpleMessage("Transcript"),
    "transfer" : MessageLookupByLibrary.simpleMessage("Transfer"),
    "turnOnNotifications" : MessageLookupByLibrary.simpleMessage("Turn On Notifications"),
    "typeMessage" : MessageLookupByLibrary.simpleMessage("Type message"),
    "unableToOpenFile" : m56,
    "unblock" : MessageLookupByLibrary.simpleMessage("Unblock"),
    "unmute" : MessageLookupByLibrary.simpleMessage("Unmute"),
    "unpin" : MessageLookupByLibrary.simpleMessage("Unpin"),
    "unpinAllMessages" : MessageLookupByLibrary.simpleMessage("Unpin All Messages"),
    "unpinAllMessagesConfirmation" : MessageLookupByLibrary.simpleMessage("Are you sure you want to unpin all messages?"),
    "unreadMessages" : MessageLookupByLibrary.simpleMessage("Unread messages"),
    "userNotFound" : MessageLookupByLibrary.simpleMessage("User not found"),
    "valueNow" : m57,
    "valueThen" : m58,
    "video" : MessageLookupByLibrary.simpleMessage("Video"),
    "videos" : MessageLookupByLibrary.simpleMessage("Videos"),
    "waitingForThisMessage" : MessageLookupByLibrary.simpleMessage("Waiting for this message."),
    "webview2RuntimeInstallDescription" : MessageLookupByLibrary.simpleMessage("The device has not installed the WebView2 Runtime component. Please download and install WebView2 Runtime first."),
    "webviewRuntimeUnavailable" : MessageLookupByLibrary.simpleMessage("WebView runtime is unavailable"),
    "whatsYourName" : MessageLookupByLibrary.simpleMessage("What\'s your name?"),
    "window" : MessageLookupByLibrary.simpleMessage("Window"),
    "writeCircles" : MessageLookupByLibrary.simpleMessage("Write Circles"),
    "you" : MessageLookupByLibrary.simpleMessage("You"),
    "youDeletedThisMessage" : MessageLookupByLibrary.simpleMessage("You deleted this message")
  };
}
