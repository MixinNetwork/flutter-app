// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class Localization {
  Localization();

  static Localization? _current;

  static Localization get current {
    assert(_current != null,
        'No instance of Localization was loaded. Try to initialize the Localization delegate before accessing Localization.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<Localization> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = Localization();
      Localization._current = instance;

      return instance;
    });
  }

  static Localization of(BuildContext context) {
    final instance = Localization.maybeOf(context);
    assert(instance != null,
        'No instance of Localization present in the widget tree. Did you add Localization.delegate in localizationsDelegates?');
    return instance!;
  }

  static Localization? maybeOf(BuildContext context) {
    return Localizations.of<Localization>(context, Localization);
  }

  /// `a message`
  String get aMessage {
    return Intl.message(
      'a message',
      name: 'aMessage',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get about {
    return Intl.message(
      'About',
      name: 'about',
      desc: '',
      args: [],
    );
  }

  /// `Access denied`
  String get accessDenied {
    return Intl.message(
      'Access denied',
      name: 'accessDenied',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get account {
    return Intl.message(
      'Account',
      name: 'account',
      desc: '',
      args: [],
    );
  }

  /// `Activity`
  String get activity {
    return Intl.message(
      'Activity',
      name: 'activity',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: '',
      args: [],
    );
  }

  /// `+ Add Bot`
  String get addBotWithPlus {
    return Intl.message(
      '+ Add Bot',
      name: 'addBotWithPlus',
      desc: '',
      args: [],
    );
  }

  /// `Add Contact`
  String get addContact {
    return Intl.message(
      'Add Contact',
      name: 'addContact',
      desc: '',
      args: [],
    );
  }

  /// `+ Add Contact`
  String get addContactWithPlus {
    return Intl.message(
      '+ Add Contact',
      name: 'addContactWithPlus',
      desc: '',
      args: [],
    );
  }

  /// `Add File`
  String get addFile {
    return Intl.message(
      'Add File',
      name: 'addFile',
      desc: '',
      args: [],
    );
  }

  /// `Add group description`
  String get addGroupDescription {
    return Intl.message(
      'Add group description',
      name: 'addGroupDescription',
      desc: '',
      args: [],
    );
  }

  /// `Add Participants`
  String get addParticipants {
    return Intl.message(
      'Add Participants',
      name: 'addParticipants',
      desc: '',
      args: [],
    );
  }

  /// `Mixin ID or Phone number`
  String get addPeopleSearchHint {
    return Intl.message(
      'Mixin ID or Phone number',
      name: 'addPeopleSearchHint',
      desc: '',
      args: [],
    );
  }

  /// `Add Proxy`
  String get addProxy {
    return Intl.message(
      'Add Proxy',
      name: 'addProxy',
      desc: '',
      args: [],
    );
  }

  /// `Add Sticker`
  String get addSticker {
    return Intl.message(
      'Add Sticker',
      name: 'addSticker',
      desc: '',
      args: [],
    );
  }

  /// `Add sticker failed`
  String get addStickerFailed {
    return Intl.message(
      'Add sticker failed',
      name: 'addStickerFailed',
      desc: '',
      args: [],
    );
  }

  /// `Add Stickers`
  String get addStickers {
    return Intl.message(
      'Add Stickers',
      name: 'addStickers',
      desc: '',
      args: [],
    );
  }

  /// `Add to Circle`
  String get addToCircle {
    return Intl.message(
      'Add to Circle',
      name: 'addToCircle',
      desc: '',
      args: [],
    );
  }

  /// `Added`
  String get added {
    return Intl.message(
      'Added',
      name: 'added',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message(
      'Address',
      name: 'address',
      desc: '',
      args: [],
    );
  }

  /// `Admin`
  String get admin {
    return Intl.message(
      'Admin',
      name: 'admin',
      desc: '',
      args: [],
    );
  }

  /// `sent you a contact`
  String get alertKeyContactContactMessage {
    return Intl.message(
      'sent you a contact',
      name: 'alertKeyContactContactMessage',
      desc: '',
      args: [],
    );
  }

  /// `Chats`
  String get allChats {
    return Intl.message(
      'Chats',
      name: 'allChats',
      desc: '',
      args: [],
    );
  }

  /// `Animals & Nature`
  String get animalsAndNature {
    return Intl.message(
      'Animals & Nature',
      name: 'animalsAndNature',
      desc: '',
      args: [],
    );
  }

  /// `Anonymous Number`
  String get anonymousNumber {
    return Intl.message(
      'Anonymous Number',
      name: 'anonymousNumber',
      desc: '',
      args: [],
    );
  }

  /// `Disallow sharing of this URL`
  String get appCardShareDisallow {
    return Intl.message(
      'Disallow sharing of this URL',
      name: 'appCardShareDisallow',
      desc: '',
      args: [],
    );
  }

  /// `Appearance`
  String get appearance {
    return Intl.message(
      'Appearance',
      name: 'appearance',
      desc: '',
      args: [],
    );
  }

  /// `archived folder`
  String get archivedFolder {
    return Intl.message(
      'archived folder',
      name: 'archivedFolder',
      desc: '',
      args: [],
    );
  }

  /// `Asset Type`
  String get assetType {
    return Intl.message(
      'Asset Type',
      name: 'assetType',
      desc: '',
      args: [],
    );
  }

  /// `Audio`
  String get audio {
    return Intl.message(
      'Audio',
      name: 'audio',
      desc: '',
      args: [],
    );
  }

  /// `Audios`
  String get audios {
    return Intl.message(
      'Audios',
      name: 'audios',
      desc: '',
      args: [],
    );
  }

  /// `Auto Backup`
  String get autoBackup {
    return Intl.message(
      'Auto Backup',
      name: 'autoBackup',
      desc: '',
      args: [],
    );
  }

  /// `Auto Lock`
  String get autoLock {
    return Intl.message(
      'Auto Lock',
      name: 'autoLock',
      desc: '',
      args: [],
    );
  }

  /// `Avatar`
  String get avatar {
    return Intl.message(
      'Avatar',
      name: 'avatar',
      desc: '',
      args: [],
    );
  }

  /// `Backup`
  String get backup {
    return Intl.message(
      'Backup',
      name: 'backup',
      desc: '',
      args: [],
    );
  }

  /// `Biography`
  String get biography {
    return Intl.message(
      'Biography',
      name: 'biography',
      desc: '',
      args: [],
    );
  }

  /// `Biometric`
  String get biometric {
    return Intl.message(
      'Biometric',
      name: 'biometric',
      desc: '',
      args: [],
    );
  }

  /// `Block`
  String get block {
    return Intl.message(
      'Block',
      name: 'block',
      desc: '',
      args: [],
    );
  }

  /// `Bot not found`
  String get botNotFound {
    return Intl.message(
      'Bot not found',
      name: 'botNotFound',
      desc: '',
      args: [],
    );
  }

  /// `BOTS`
  String get bots {
    return Intl.message(
      'BOTS',
      name: 'bots',
      desc: '',
      args: [],
    );
  }

  /// `Bots`
  String get botsTitle {
    return Intl.message(
      'Bots',
      name: 'botsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Bring All To Front`
  String get bringAllToFront {
    return Intl.message(
      'Bring All To Front',
      name: 'bringAllToFront',
      desc: '',
      args: [],
    );
  }

  /// `Can not recognize the QR code`
  String get canNotRecognizeQrCode {
    return Intl.message(
      'Can not recognize the QR code',
      name: 'canNotRecognizeQrCode',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Card`
  String get card {
    return Intl.message(
      'Card',
      name: 'card',
      desc: '',
      args: [],
    );
  }

  /// `Change`
  String get change {
    return Intl.message(
      'Change',
      name: 'change',
      desc: '',
      args: [],
    );
  }

  /// `Change Number`
  String get changeNumber {
    return Intl.message(
      'Change Number',
      name: 'changeNumber',
      desc: '',
      args: [],
    );
  }

  /// `Change Number Instead`
  String get changeNumberInstead {
    return Intl.message(
      'Change Number Instead',
      name: 'changeNumberInstead',
      desc: '',
      args: [],
    );
  }

  /// `{arg0} changed disappearing message settings.`
  String changedDisappearingMessageSettings(Object arg0) {
    return Intl.message(
      '$arg0 changed disappearing message settings.',
      name: 'changedDisappearingMessageSettings',
      desc: '',
      args: [arg0],
    );
  }

  /// `Chat Backup`
  String get chatBackup {
    return Intl.message(
      'Chat Backup',
      name: 'chatBackup',
      desc: '',
      args: [],
    );
  }

  /// `Tap the button to interact with the bot`
  String get chatBotReceptionTitle {
    return Intl.message(
      'Tap the button to interact with the bot',
      name: 'chatBotReceptionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Waiting for {arg0} to get online and establish an encrypted session.`
  String chatDecryptionFailedHint(Object arg0) {
    return Intl.message(
      'Waiting for $arg0 to get online and establish an encrypted session.',
      name: 'chatDecryptionFailedHint',
      desc: '',
      args: [arg0],
    );
  }

  /// `{count, plural, one{Delete {arg0} message?} other{Delete {arg0} messages?}}`
  String chatDeleteMessage(num count, Object arg0) {
    return Intl.plural(
      count,
      one: 'Delete $arg0 message?',
      other: 'Delete $arg0 messages?',
      name: 'chatDeleteMessage',
      desc: '',
      args: [count, arg0],
    );
  }

  /// `{arg0} added {arg1}`
  String chatGroupAdd(Object arg0, Object arg1) {
    return Intl.message(
      '$arg0 added $arg1',
      name: 'chatGroupAdd',
      desc: '',
      args: [arg0, arg1],
    );
  }

  /// `{arg0} left`
  String chatGroupExit(Object arg0) {
    return Intl.message(
      '$arg0 left',
      name: 'chatGroupExit',
      desc: '',
      args: [arg0],
    );
  }

  /// `{arg0} joined the group via invite link`
  String chatGroupJoin(Object arg0) {
    return Intl.message(
      '$arg0 joined the group via invite link',
      name: 'chatGroupJoin',
      desc: '',
      args: [arg0],
    );
  }

  /// `{arg0} removed {arg1}`
  String chatGroupRemove(Object arg0, Object arg1) {
    return Intl.message(
      '$arg0 removed $arg1',
      name: 'chatGroupRemove',
      desc: '',
      args: [arg0, arg1],
    );
  }

  /// `End to end encrypted`
  String get chatHintE2e {
    return Intl.message(
      'End to end encrypted',
      name: 'chatHintE2e',
      desc: '',
      args: [],
    );
  }

  /// `This type of url is not supported, please check on your phone.`
  String get chatNotSupportUriOnPhone {
    return Intl.message(
      'This type of url is not supported, please check on your phone.',
      name: 'chatNotSupportUriOnPhone',
      desc: '',
      args: [],
    );
  }

  /// `https://mixinmessenger.zendesk.com/hc/articles/360043776071`
  String get chatNotSupportUrl {
    return Intl.message(
      'https://mixinmessenger.zendesk.com/hc/articles/360043776071',
      name: 'chatNotSupportUrl',
      desc: '',
      args: [],
    );
  }

  /// `This type of message is not supported, please check on your phone.`
  String get chatNotSupportViewOnPhone {
    return Intl.message(
      'This type of message is not supported, please check on your phone.',
      name: 'chatNotSupportViewOnPhone',
      desc: '',
      args: [],
    );
  }

  /// `{arg0} pinned {arg1}`
  String chatPinMessage(Object arg0, Object arg1) {
    return Intl.message(
      '$arg0 pinned $arg1',
      name: 'chatPinMessage',
      desc: '',
      args: [arg0, arg1],
    );
  }

  /// `Chat Text Size`
  String get chatTextSize {
    return Intl.message(
      'Chat Text Size',
      name: 'chatTextSize',
      desc: '',
      args: [],
    );
  }

  /// `Check new version`
  String get checkNewVersion {
    return Intl.message(
      'Check new version',
      name: 'checkNewVersion',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{{arg0} Conversation} other{{arg0} Conversations}}`
  String circleSubtitle(num count, Object arg0) {
    return Intl.plural(
      count,
      one: '$arg0 Conversation',
      other: '$arg0 Conversations',
      name: 'circleSubtitle',
      desc: '',
      args: [count, arg0],
    );
  }

  /// `{arg0}'s Circles`
  String circleTitle(Object arg0) {
    return Intl.message(
      '$arg0\'s Circles',
      name: 'circleTitle',
      desc: '',
      args: [arg0],
    );
  }

  /// `Circles`
  String get circles {
    return Intl.message(
      'Circles',
      name: 'circles',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get clear {
    return Intl.message(
      'Clear',
      name: 'clear',
      desc: '',
      args: [],
    );
  }

  /// `Clear Chat`
  String get clearChat {
    return Intl.message(
      'Clear Chat',
      name: 'clearChat',
      desc: '',
      args: [],
    );
  }

  /// `Clear filter`
  String get clearFilter {
    return Intl.message(
      'Clear filter',
      name: 'clearFilter',
      desc: '',
      args: [],
    );
  }

  /// `Click to reload QR code`
  String get clickToReloadQrcode {
    return Intl.message(
      'Click to reload QR code',
      name: 'clickToReloadQrcode',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `Close window`
  String get closeWindow {
    return Intl.message(
      'Close window',
      name: 'closeWindow',
      desc: '',
      args: [],
    );
  }

  /// `Closing Balance`
  String get closingBalance {
    return Intl.message(
      'Closing Balance',
      name: 'closingBalance',
      desc: '',
      args: [],
    );
  }

  /// `Collapse`
  String get collapse {
    return Intl.message(
      'Collapse',
      name: 'collapse',
      desc: '',
      args: [],
    );
  }

  /// `Combine and forward`
  String get combineAndForward {
    return Intl.message(
      'Combine and forward',
      name: 'combineAndForward',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get confirm {
    return Intl.message(
      'Confirm',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `Enter again to confirm the passcode`
  String get confirmPasscodeDesc {
    return Intl.message(
      'Enter again to confirm the passcode',
      name: 'confirmPasscodeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure to sync the chat history from the phone?`
  String get confirmSyncChatsFromPhone {
    return Intl.message(
      'Are you sure to sync the chat history from the phone?',
      name: 'confirmSyncChatsFromPhone',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure to sync the chat history to the phone?`
  String get confirmSyncChatsToPhone {
    return Intl.message(
      'Are you sure to sync the chat history to the phone?',
      name: 'confirmSyncChatsToPhone',
      desc: '',
      args: [],
    );
  }

  /// `Contact`
  String get contact {
    return Intl.message(
      'Contact',
      name: 'contact',
      desc: '',
      args: [],
    );
  }

  /// `Mixin ID: {arg0}`
  String contactMixinId(Object arg0) {
    return Intl.message(
      'Mixin ID: $arg0',
      name: 'contactMixinId',
      desc: '',
      args: [arg0],
    );
  }

  /// `Mute notifications for…`
  String get contactMuteTitle {
    return Intl.message(
      'Mute notifications for…',
      name: 'contactMuteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Contacts`
  String get contactTitle {
    return Intl.message(
      'Contacts',
      name: 'contactTitle',
      desc: '',
      args: [],
    );
  }

  /// `Content too long`
  String get contentTooLong {
    return Intl.message(
      'Content too long',
      name: 'contentTooLong',
      desc: '',
      args: [],
    );
  }

  /// `[Voice call]`
  String get contentVoice {
    return Intl.message(
      '[Voice call]',
      name: 'contentVoice',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get continueText {
    return Intl.message(
      'Continue',
      name: 'continueText',
      desc: '',
      args: [],
    );
  }

  /// `Conversation`
  String get conversation {
    return Intl.message(
      'Conversation',
      name: 'conversation',
      desc: '',
      args: [],
    );
  }

  /// `Delete chat: {arg0}`
  String conversationDeleteTitle(Object arg0) {
    return Intl.message(
      'Delete chat: $arg0',
      name: 'conversationDeleteTitle',
      desc: '',
      args: [arg0],
    );
  }

  /// `Copy`
  String get copy {
    return Intl.message(
      'Copy',
      name: 'copy',
      desc: '',
      args: [],
    );
  }

  /// `Copy Invite Link`
  String get copyInvite {
    return Intl.message(
      'Copy Invite Link',
      name: 'copyInvite',
      desc: '',
      args: [],
    );
  }

  /// `Copy Link`
  String get copyLink {
    return Intl.message(
      'Copy Link',
      name: 'copyLink',
      desc: '',
      args: [],
    );
  }

  /// `Create`
  String get create {
    return Intl.message(
      'Create',
      name: 'create',
      desc: '',
      args: [],
    );
  }

  /// `New Circle`
  String get createCircle {
    return Intl.message(
      'New Circle',
      name: 'createCircle',
      desc: '',
      args: [],
    );
  }

  /// `New Conversation`
  String get createConversation {
    return Intl.message(
      'New Conversation',
      name: 'createConversation',
      desc: '',
      args: [],
    );
  }

  /// `New Group`
  String get createGroup {
    return Intl.message(
      'New Group',
      name: 'createGroup',
      desc: '',
      args: [],
    );
  }

  /// `Created {arg0}`
  String created(Object arg0) {
    return Intl.message(
      'Created $arg0',
      name: 'created',
      desc: '',
      args: [arg0],
    );
  }

  /// `{arg0} created this group`
  String createdThisGroup(Object arg0) {
    return Intl.message(
      '$arg0 created this group',
      name: 'createdThisGroup',
      desc: '',
      args: [arg0],
    );
  }

  /// `Custom Time`
  String get customTime {
    return Intl.message(
      'Custom Time',
      name: 'customTime',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get dark {
    return Intl.message(
      'Dark',
      name: 'dark',
      desc: '',
      args: [],
    );
  }

  /// `Data and Storage Usage`
  String get dataAndStorageUsage {
    return Intl.message(
      'Data and Storage Usage',
      name: 'dataAndStorageUsage',
      desc: '',
      args: [],
    );
  }

  /// `Data error`
  String get dataError {
    return Intl.message(
      'Data error',
      name: 'dataError',
      desc: '',
      args: [],
    );
  }

  /// `Data loading, please wait...`
  String get dataLoading {
    return Intl.message(
      'Data loading, please wait...',
      name: 'dataLoading',
      desc: '',
      args: [],
    );
  }

  /// `The database is corrupted and cannot be recovered. Clicking continue will create a new database file.`
  String get databaseCorruptedTips {
    return Intl.message(
      'The database is corrupted and cannot be recovered. Clicking continue will create a new database file.',
      name: 'databaseCorruptedTips',
      desc: '',
      args: [],
    );
  }

  /// `The database file is locked and cannot be accessed. Please try restarting the application or the system and try again.`
  String get databaseLockedTips {
    return Intl.message(
      'The database file is locked and cannot be accessed. Please try restarting the application or the system and try again.',
      name: 'databaseLockedTips',
      desc: '',
      args: [],
    );
  }

  /// `Cannot open the database. The file is not a valid database file.`
  String get databaseNotADbTips {
    return Intl.message(
      'Cannot open the database. The file is not a valid database file.',
      name: 'databaseNotADbTips',
      desc: '',
      args: [],
    );
  }

  /// `Create a new database file and the old file will be deleted.`
  String get databaseRecreateTips {
    return Intl.message(
      'Create a new database file and the old file will be deleted.',
      name: 'databaseRecreateTips',
      desc: '',
      args: [],
    );
  }

  /// `The database is being upgraded, it may take several minutes, please do not close this App.`
  String get databaseUpgradeTips {
    return Intl.message(
      'The database is being upgraded, it may take several minutes, please do not close this App.',
      name: 'databaseUpgradeTips',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Local messages and iCloud Backups will not be deleted automatically`
  String get deleteAccountDetailHint {
    return Intl.message(
      'Local messages and iCloud Backups will not be deleted automatically',
      name: 'deleteAccountDetailHint',
      desc: '',
      args: [],
    );
  }

  /// `Delete your account info and profile photo`
  String get deleteAccountHint {
    return Intl.message(
      'Delete your account info and profile photo',
      name: 'deleteAccountHint',
      desc: '',
      args: [],
    );
  }

  /// `Delete Chat`
  String get deleteChat {
    return Intl.message(
      'Delete Chat',
      name: 'deleteChat',
      desc: '',
      args: [],
    );
  }

  /// `Deleting chat will remove messages form this devices only. They will not be removed from other devices.`
  String get deleteChatDescription {
    return Intl.message(
      'Deleting chat will remove messages form this devices only. They will not be removed from other devices.',
      name: 'deleteChatDescription',
      desc: '',
      args: [],
    );
  }

  /// `Delete Circle`
  String get deleteCircle {
    return Intl.message(
      'Delete Circle',
      name: 'deleteCircle',
      desc: '',
      args: [],
    );
  }

  /// `Delete for Everyone`
  String get deleteForEveryone {
    return Intl.message(
      'Delete for Everyone',
      name: 'deleteForEveryone',
      desc: '',
      args: [],
    );
  }

  /// `Delete for me`
  String get deleteForMe {
    return Intl.message(
      'Delete for me',
      name: 'deleteForMe',
      desc: '',
      args: [],
    );
  }

  /// `Delete Group`
  String get deleteGroup {
    return Intl.message(
      'Delete Group',
      name: 'deleteGroup',
      desc: '',
      args: [],
    );
  }

  /// `Delete My Account`
  String get deleteMyAccount {
    return Intl.message(
      'Delete My Account',
      name: 'deleteMyAccount',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to delete {arg0} circle?`
  String deleteTheCircle(Object arg0) {
    return Intl.message(
      'Do you want to delete $arg0 circle?',
      name: 'deleteTheCircle',
      desc: '',
      args: [arg0],
    );
  }

  /// `Deposit`
  String get deposit {
    return Intl.message(
      'Deposit',
      name: 'deposit',
      desc: '',
      args: [],
    );
  }

  /// `Developer`
  String get developer {
    return Intl.message(
      'Developer',
      name: 'developer',
      desc: '',
      args: [],
    );
  }

  /// `{arg0} disabled disappearing message`
  String disableDisappearingMessage(Object arg0) {
    return Intl.message(
      '$arg0 disabled disappearing message',
      name: 'disableDisappearingMessage',
      desc: '',
      args: [arg0],
    );
  }

  /// `Disabled`
  String get disabled {
    return Intl.message(
      'Disabled',
      name: 'disabled',
      desc: '',
      args: [],
    );
  }

  /// `The maximum time is {arg0}.`
  String disappearingCustomTimeMaxWarning(Object arg0) {
    return Intl.message(
      'The maximum time is $arg0.',
      name: 'disappearingCustomTimeMaxWarning',
      desc: '',
      args: [arg0],
    );
  }

  /// `Disappearing Messages`
  String get disappearingMessage {
    return Intl.message(
      'Disappearing Messages',
      name: 'disappearingMessage',
      desc: '',
      args: [],
    );
  }

  /// `When enabled, new messages sent and received in this chat will disappear after they have been seen, read the document to **learn more**.`
  String get disappearingMessageHint {
    return Intl.message(
      'When enabled, new messages sent and received in this chat will disappear after they have been seen, read the document to **learn more**.',
      name: 'disappearingMessageHint',
      desc: '',
      args: [],
    );
  }

  /// `Discard`
  String get discard {
    return Intl.message(
      'Discard',
      name: 'discard',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to stop recording and discard your voice message?`
  String get discardRecordingWarning {
    return Intl.message(
      'Are you sure you want to stop recording and discard your voice message?',
      name: 'discardRecordingWarning',
      desc: '',
      args: [],
    );
  }

  /// `Dismiss as Admin`
  String get dismissAsAdmin {
    return Intl.message(
      'Dismiss as Admin',
      name: 'dismissAsAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get done {
    return Intl.message(
      'Done',
      name: 'done',
      desc: '',
      args: [],
    );
  }

  /// `Download`
  String get download {
    return Intl.message(
      'Download',
      name: 'download',
      desc: '',
      args: [],
    );
  }

  /// `Download Link:`
  String get downloadLink {
    return Intl.message(
      'Download Link:',
      name: 'downloadLink',
      desc: '',
      args: [],
    );
  }

  /// `Draft`
  String get draft {
    return Intl.message(
      'Draft',
      name: 'draft',
      desc: '',
      args: [],
    );
  }

  /// `Drag and drop files here`
  String get dragAndDropFileHere {
    return Intl.message(
      'Drag and drop files here',
      name: 'dragAndDropFileHere',
      desc: '',
      args: [],
    );
  }

  /// `Duration is too short`
  String get durationIsTooShort {
    return Intl.message(
      'Duration is too short',
      name: 'durationIsTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Edit Circle Name`
  String get editCircleName {
    return Intl.message(
      'Edit Circle Name',
      name: 'editCircleName',
      desc: '',
      args: [],
    );
  }

  /// `Edit Conversations`
  String get editConversations {
    return Intl.message(
      'Edit Conversations',
      name: 'editConversations',
      desc: '',
      args: [],
    );
  }

  /// `Edit Group Description`
  String get editGroupDescription {
    return Intl.message(
      'Edit Group Description',
      name: 'editGroupDescription',
      desc: '',
      args: [],
    );
  }

  /// `Edit Group Name`
  String get editGroupName {
    return Intl.message(
      'Edit Group Name',
      name: 'editGroupName',
      desc: '',
      args: [],
    );
  }

  /// `All changes will be lost. Are you sure you want to exit?`
  String get editImageClearWarning {
    return Intl.message(
      'All changes will be lost. Are you sure you want to exit?',
      name: 'editImageClearWarning',
      desc: '',
      args: [],
    );
  }

  /// `Edit Name`
  String get editName {
    return Intl.message(
      'Edit Name',
      name: 'editName',
      desc: '',
      args: [],
    );
  }

  /// `Edit Profile`
  String get editProfile {
    return Intl.message(
      'Edit Profile',
      name: 'editProfile',
      desc: '',
      args: [],
    );
  }

  /// `Enter your PIN to delete your account`
  String get enterPinToDeleteAccount {
    return Intl.message(
      'Enter your PIN to delete your account',
      name: 'enterPinToDeleteAccount',
      desc: '',
      args: [],
    );
  }

  /// `Return/Enter ⏎ to Send`
  String get enterToSend {
    return Intl.message(
      'Return/Enter ⏎ to Send',
      name: 'enterToSend',
      desc: '',
      args: [],
    );
  }

  /// `Enter your phone number`
  String get enterYourPhoneNumber {
    return Intl.message(
      'Enter your phone number',
      name: 'enterYourPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter your PIN to continue`
  String get enterYourPinToContinue {
    return Intl.message(
      'Enter your PIN to continue',
      name: 'enterYourPinToContinue',
      desc: '',
      args: [],
    );
  }

  /// `The address does not exist, please make sure that the address is added successfully`
  String get errorAddressExists {
    return Intl.message(
      'The address does not exist, please make sure that the address is added successfully',
      name: 'errorAddressExists',
      desc: '',
      args: [],
    );
  }

  /// `Address refresh failed, please try again`
  String get errorAddressNotSync {
    return Intl.message(
      'Address refresh failed, please try again',
      name: 'errorAddressNotSync',
      desc: '',
      args: [],
    );
  }

  /// `Asset does not exist`
  String get errorAssetExists {
    return Intl.message(
      'Asset does not exist',
      name: 'errorAssetExists',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 401: Sign in to continue`
  String get errorAuthentication {
    return Intl.message(
      'ERROR 401: Sign in to continue',
      name: 'errorAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 10002: The request data has invalid field`
  String get errorBadData {
    return Intl.message(
      'ERROR 10002: The request data has invalid field',
      name: 'errorBadData',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 30100: Blockchain not in sync, please try again later.`
  String get errorBlockchain {
    return Intl.message(
      'ERROR 30100: Blockchain not in sync, please try again later.',
      name: 'errorBlockchain',
      desc: '',
      args: [],
    );
  }

  /// `Network connection timeout, please try again`
  String get errorConnectionTimeout {
    return Intl.message(
      'Network connection timeout, please try again',
      name: 'errorConnectionTimeout',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20116: The group chat is full.`
  String get errorFullGroup {
    return Intl.message(
      'ERROR 20116: The group chat is full.',
      name: 'errorFullGroup',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20117: Insufficient balance`
  String get errorInsufficientBalance {
    return Intl.message(
      'ERROR 20117: Insufficient balance',
      name: 'errorInsufficientBalance',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20124: Insufficient transaction fee. Please make sure your wallet has {arg0} as fee`
  String errorInsufficientTransactionFeeWithAmount(Object arg0) {
    return Intl.message(
      'ERROR 20124: Insufficient transaction fee. Please make sure your wallet has $arg0 as fee',
      name: 'errorInsufficientTransactionFeeWithAmount',
      desc: '',
      args: [arg0],
    );
  }

  /// `ERROR 30102: Invalid address format. Please enter the correct {arg0} {arg1} address!`
  String errorInvalidAddress(Object arg0, Object arg1) {
    return Intl.message(
      'ERROR 30102: Invalid address format. Please enter the correct $arg0 $arg1 address!',
      name: 'errorInvalidAddress',
      desc: '',
      args: [arg0, arg1],
    );
  }

  /// `ERROR 30102: Invalid address format.`
  String get errorInvalidAddressPlain {
    return Intl.message(
      'ERROR 30102: Invalid address format.',
      name: 'errorInvalidAddressPlain',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20129: Send verification code too frequent, please try again later.`
  String get errorInvalidCodeTooFrequent {
    return Intl.message(
      'ERROR 20129: Send verification code too frequent, please try again later.',
      name: 'errorInvalidCodeTooFrequent',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20130: Invalid emergency contact`
  String get errorInvalidEmergencyContact {
    return Intl.message(
      'ERROR 20130: Invalid emergency contact',
      name: 'errorInvalidEmergencyContact',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20118: Invalid PIN format.`
  String get errorInvalidPinFormat {
    return Intl.message(
      'ERROR 20118: Invalid PIN format.',
      name: 'errorInvalidPinFormat',
      desc: '',
      args: [],
    );
  }

  /// `Network connection failed. Check or switch your network and try again`
  String get errorNetworkTaskFailed {
    return Intl.message(
      'Network connection failed. Check or switch your network and try again',
      name: 'errorNetworkTaskFailed',
      desc: '',
      args: [],
    );
  }

  /// `No token, Please log in again and try this feature again.`
  String get errorNoPinToken {
    return Intl.message(
      'No token, Please log in again and try this feature again.',
      name: 'errorNoPinToken',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 404: Not found`
  String get errorNotFound {
    return Intl.message(
      'ERROR 404: Not found',
      name: 'errorNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Not supported audio format, please open by other app.`
  String get errorNotSupportedAudioFormat {
    return Intl.message(
      'Not supported audio format, please open by other app.',
      name: 'errorNotSupportedAudioFormat',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20132: The number has reached the limit.`
  String get errorNumberReachedLimit {
    return Intl.message(
      'ERROR 20132: The number has reached the limit.',
      name: 'errorNumberReachedLimit',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 10006: Please update Mixin({arg0}) to continue use the service.`
  String errorOldVersion(Object arg0) {
    return Intl.message(
      'ERROR 10006: Please update Mixin($arg0) to continue use the service.',
      name: 'errorOldVersion',
      desc: '',
      args: [arg0],
    );
  }

  /// `Can't find an map app`
  String get errorOpenLocation {
    return Intl.message(
      'Can\'t find an map app',
      name: 'errorOpenLocation',
      desc: '',
      args: [],
    );
  }

  /// `Please open the necessary permissions`
  String get errorPermission {
    return Intl.message(
      'Please open the necessary permissions',
      name: 'errorPermission',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20110: Invalid phone number`
  String get errorPhoneInvalidFormat {
    return Intl.message(
      'ERROR 20110: Invalid phone number',
      name: 'errorPhoneInvalidFormat',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 10003: Failed to deliver SMS`
  String get errorPhoneSmsDelivery {
    return Intl.message(
      'ERROR 10003: Failed to deliver SMS',
      name: 'errorPhoneSmsDelivery',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20114: Expired phone verification code`
  String get errorPhoneVerificationCodeExpired {
    return Intl.message(
      'ERROR 20114: Expired phone verification code',
      name: 'errorPhoneVerificationCodeExpired',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20113: Invalid phone verification code`
  String get errorPhoneVerificationCodeInvalid {
    return Intl.message(
      'ERROR 20113: Invalid phone verification code',
      name: 'errorPhoneVerificationCodeInvalid',
      desc: '',
      args: [],
    );
  }

  /// `You have tried more than 5 times, please wait at least 24 hours to try again.`
  String get errorPinCheckTooManyRequest {
    return Intl.message(
      'You have tried more than 5 times, please wait at least 24 hours to try again.',
      name: 'errorPinCheckTooManyRequest',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20119: PIN incorrect`
  String get errorPinIncorrect {
    return Intl.message(
      'ERROR 20119: PIN incorrect',
      name: 'errorPinIncorrect',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{ERROR 20119: PIN incorrect. You still have {arg0} chance. Please wait for 24 hours to retry later.} other{ERROR 20119: PIN incorrect. You still have {arg0} chances. Please wait for 24 hours to retry later.}}`
  String errorPinIncorrectWithTimes(num count, Object arg0) {
    return Intl.plural(
      count,
      one:
          'ERROR 20119: PIN incorrect. You still have $arg0 chance. Please wait for 24 hours to retry later.',
      other:
          'ERROR 20119: PIN incorrect. You still have $arg0 chances. Please wait for 24 hours to retry later.',
      name: 'errorPinIncorrectWithTimes',
      desc: '',
      args: [count, arg0],
    );
  }

  /// `ERROR 10004: Recaptcha is invalid`
  String get errorRecaptchaIsInvalid {
    return Intl.message(
      'ERROR 10004: Recaptcha is invalid',
      name: 'errorRecaptchaIsInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Server is under maintenance: {arg0}`
  String errorServer5xxCode(Object arg0) {
    return Intl.message(
      'Server is under maintenance: $arg0',
      name: 'errorServer5xxCode',
      desc: '',
      args: [arg0],
    );
  }

  /// `ERROR 429: Rate limit exceeded`
  String get errorTooManyRequest {
    return Intl.message(
      'ERROR 429: Rate limit exceeded',
      name: 'errorTooManyRequest',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20126: Too many stickers`
  String get errorTooManyStickers {
    return Intl.message(
      'ERROR 20126: Too many stickers',
      name: 'errorTooManyStickers',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20120: Transfer amount is too small`
  String get errorTooSmallTransferAmount {
    return Intl.message(
      'ERROR 20120: Transfer amount is too small',
      name: 'errorTooSmallTransferAmount',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20127: Withdraw amount too small`
  String get errorTooSmallWithdrawAmount {
    return Intl.message(
      'ERROR 20127: Withdraw amount too small',
      name: 'errorTooSmallWithdrawAmount',
      desc: '',
      args: [],
    );
  }

  /// `Please forward all attachments after they have been downloaded`
  String get errorTranscriptForward {
    return Intl.message(
      'Please forward all attachments after they have been downloaded',
      name: 'errorTranscriptForward',
      desc: '',
      args: [],
    );
  }

  /// `Can't find an app able to open this media.`
  String get errorUnableToOpenMedia {
    return Intl.message(
      'Can\'t find an app able to open this media.',
      name: 'errorUnableToOpenMedia',
      desc: '',
      args: [],
    );
  }

  /// `ERROR: {arg0}`
  String errorUnknownWithCode(Object arg0) {
    return Intl.message(
      'ERROR: $arg0',
      name: 'errorUnknownWithCode',
      desc: '',
      args: [arg0],
    );
  }

  /// `ERROR: {arg0}`
  String errorUnknownWithMessage(Object arg0) {
    return Intl.message(
      'ERROR: $arg0',
      name: 'errorUnknownWithMessage',
      desc: '',
      args: [arg0],
    );
  }

  /// `Failed to upload message attachment`
  String get errorUploadAttachmentFailed {
    return Intl.message(
      'Failed to upload message attachment',
      name: 'errorUploadAttachmentFailed',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20122: This phone number is already associated with another account.`
  String get errorUsedPhone {
    return Intl.message(
      'ERROR 20122: This phone number is already associated with another account.',
      name: 'errorUsedPhone',
      desc: '',
      args: [],
    );
  }

  /// `Invalid user id`
  String get errorUserInvalidFormat {
    return Intl.message(
      'Invalid user id',
      name: 'errorUserInvalidFormat',
      desc: '',
      args: [],
    );
  }

  /// `ERROR 20131: Withdrawal memo format incorrect.`
  String get errorWithdrawalMemoFormatIncorrect {
    return Intl.message(
      'ERROR 20131: Withdrawal memo format incorrect.',
      name: 'errorWithdrawalMemoFormatIncorrect',
      desc: '',
      args: [],
    );
  }

  /// `Exit`
  String get exit {
    return Intl.message(
      'Exit',
      name: 'exit',
      desc: '',
      args: [],
    );
  }

  /// `Exit Group`
  String get exitGroup {
    return Intl.message(
      'Exit Group',
      name: 'exitGroup',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get failed {
    return Intl.message(
      'Failed',
      name: 'failed',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred while opening the database.`
  String get failedToOpenDatabase {
    return Intl.message(
      'An error occurred while opening the database.',
      name: 'failedToOpenDatabase',
      desc: '',
      args: [],
    );
  }

  /// `Fee`
  String get fee {
    return Intl.message(
      'Fee',
      name: 'fee',
      desc: '',
      args: [],
    );
  }

  /// `File`
  String get file {
    return Intl.message(
      'File',
      name: 'file',
      desc: '',
      args: [],
    );
  }

  /// `File chooser error`
  String get fileChooserError {
    return Intl.message(
      'File chooser error',
      name: 'fileChooserError',
      desc: '',
      args: [],
    );
  }

  /// `File does not exist`
  String get fileDoesNotExist {
    return Intl.message(
      'File does not exist',
      name: 'fileDoesNotExist',
      desc: '',
      args: [],
    );
  }

  /// `File error`
  String get fileError {
    return Intl.message(
      'File error',
      name: 'fileError',
      desc: '',
      args: [],
    );
  }

  /// `Files`
  String get files {
    return Intl.message(
      'Files',
      name: 'files',
      desc: '',
      args: [],
    );
  }

  /// `Flags`
  String get flags {
    return Intl.message(
      'Flags',
      name: 'flags',
      desc: '',
      args: [],
    );
  }

  /// `Follow System`
  String get followSystem {
    return Intl.message(
      'Follow System',
      name: 'followSystem',
      desc: '',
      args: [],
    );
  }

  /// `Follow us on Facebook`
  String get followUsOnFacebook {
    return Intl.message(
      'Follow us on Facebook',
      name: 'followUsOnFacebook',
      desc: '',
      args: [],
    );
  }

  /// `Follow us on Twitter`
  String get followUsOnTwitter {
    return Intl.message(
      'Follow us on Twitter',
      name: 'followUsOnTwitter',
      desc: '',
      args: [],
    );
  }

  /// `Food & Drink`
  String get foodAndDrink {
    return Intl.message(
      'Food & Drink',
      name: 'foodAndDrink',
      desc: '',
      args: [],
    );
  }

  /// `Format not supported`
  String get formatNotSupported {
    return Intl.message(
      'Format not supported',
      name: 'formatNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `Forward`
  String get forward {
    return Intl.message(
      'Forward',
      name: 'forward',
      desc: '',
      args: [],
    );
  }

  /// `From`
  String get from {
    return Intl.message(
      'From',
      name: 'from',
      desc: '',
      args: [],
    );
  }

  /// `From:`
  String get fromWithColon {
    return Intl.message(
      'From:',
      name: 'fromWithColon',
      desc: '',
      args: [],
    );
  }

  /// `You already in the group`
  String get groupAlreadyIn {
    return Intl.message(
      'You already in the group',
      name: 'groupAlreadyIn',
      desc: '',
      args: [],
    );
  }

  /// `You can't send messages to this group because you're no longer a participant.`
  String get groupCantSend {
    return Intl.message(
      'You can\'t send messages to this group because you\'re no longer a participant.',
      name: 'groupCantSend',
      desc: '',
      args: [],
    );
  }

  /// `Group Name`
  String get groupName {
    return Intl.message(
      'Group Name',
      name: 'groupName',
      desc: '',
      args: [],
    );
  }

  /// `Participants`
  String get groupParticipants {
    return Intl.message(
      'Participants',
      name: 'groupParticipants',
      desc: '',
      args: [],
    );
  }

  /// `Message {arg0}`
  String groupPopMenuMessage(Object arg0) {
    return Intl.message(
      'Message $arg0',
      name: 'groupPopMenuMessage',
      desc: '',
      args: [arg0],
    );
  }

  /// `Remove {arg0}`
  String groupPopMenuRemove(Object arg0) {
    return Intl.message(
      'Remove $arg0',
      name: 'groupPopMenuRemove',
      desc: '',
      args: [arg0],
    );
  }

  /// `Groups`
  String get groups {
    return Intl.message(
      'Groups',
      name: 'groups',
      desc: '',
      args: [],
    );
  }

  /// `Groups In Common`
  String get groupsInCommon {
    return Intl.message(
      'Groups In Common',
      name: 'groupsInCommon',
      desc: '',
      args: [],
    );
  }

  /// `Help`
  String get help {
    return Intl.message(
      'Help',
      name: 'help',
      desc: '',
      args: [],
    );
  }

  /// `Help center`
  String get helpCenter {
    return Intl.message(
      'Help center',
      name: 'helpCenter',
      desc: '',
      args: [],
    );
  }

  /// `Hide Mixin`
  String get hideMixin {
    return Intl.message(
      'Hide Mixin',
      name: 'hideMixin',
      desc: '',
      args: [],
    );
  }

  /// `Host`
  String get host {
    return Intl.message(
      'Host',
      name: 'host',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{{arg0} Hour} other{{arg0} Hours}}`
  String hour(num count, Object arg0) {
    return Intl.plural(
      count,
      one: '$arg0 Hour',
      other: '$arg0 Hours',
      name: 'hour',
      desc: '',
      args: [count, arg0],
    );
  }

  /// `Hi, how are you?`
  String get howAreYou {
    return Intl.message(
      'Hi, how are you?',
      name: 'howAreYou',
      desc: '',
      args: [],
    );
  }

  /// `I’m good.`
  String get iAmGood {
    return Intl.message(
      'I’m good.',
      name: 'iAmGood',
      desc: '',
      args: [],
    );
  }

  /// `Ignore the new version`
  String get ignoreThisVersion {
    return Intl.message(
      'Ignore the new version',
      name: 'ignoreThisVersion',
      desc: '',
      args: [],
    );
  }

  /// `image`
  String get image {
    return Intl.message(
      'image',
      name: 'image',
      desc: '',
      args: [],
    );
  }

  /// `Include Files`
  String get includeFiles {
    return Intl.message(
      'Include Files',
      name: 'includeFiles',
      desc: '',
      args: [],
    );
  }

  /// `Include Videos`
  String get includeVideos {
    return Intl.message(
      'Include Videos',
      name: 'includeVideos',
      desc: '',
      args: [],
    );
  }

  /// `Initializing…`
  String get initializing {
    return Intl.message(
      'Initializing…',
      name: 'initializing',
      desc: '',
      args: [],
    );
  }

  /// `Anyone with Mixin can follow this link to join this group. Only share it with people you trust.`
  String get inviteInfo {
    return Intl.message(
      'Anyone with Mixin can follow this link to join this group. Only share it with people you trust.',
      name: 'inviteInfo',
      desc: '',
      args: [],
    );
  }

  /// `Invite to Group via Link`
  String get inviteToGroupViaLink {
    return Intl.message(
      'Invite to Group via Link',
      name: 'inviteToGroupViaLink',
      desc: '',
      args: [],
    );
  }

  /// `+ Join group`
  String get joinGroupWithPlus {
    return Intl.message(
      '+ Join group',
      name: 'joinGroupWithPlus',
      desc: '',
      args: [],
    );
  }

  /// `Joined on {arg0}`
  String joinedIn(Object arg0) {
    return Intl.message(
      'Joined on $arg0',
      name: 'joinedIn',
      desc: '',
      args: [arg0],
    );
  }

  /// `Your account will be deleted on {arg0}, if you continue to log in, the request to delete your account will be cancelled.`
  String landingDeleteContent(Object arg0) {
    return Intl.message(
      'Your account will be deleted on $arg0, if you continue to log in, the request to delete your account will be cancelled.',
      name: 'landingDeleteContent',
      desc: '',
      args: [arg0],
    );
  }

  /// `We will send a 4-digit code to your phone number {arg0}, please enter the code in next screen.`
  String landingInvitationDialogContent(Object arg0) {
    return Intl.message(
      'We will send a 4-digit code to your phone number $arg0, please enter the code in next screen.',
      name: 'landingInvitationDialogContent',
      desc: '',
      args: [arg0],
    );
  }

  /// `Enter the 4-digit code sent to you at {arg0}`
  String landingValidationTitle(Object arg0) {
    return Intl.message(
      'Enter the 4-digit code sent to you at $arg0',
      name: 'landingValidationTitle',
      desc: '',
      args: [arg0],
    );
  }

  /// `Learn More`
  String get learnMore {
    return Intl.message(
      'Learn More',
      name: 'learnMore',
      desc: '',
      args: [],
    );
  }

  /// `less`
  String get less {
    return Intl.message(
      'less',
      name: 'less',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get light {
    return Intl.message(
      'Light',
      name: 'light',
      desc: '',
      args: [],
    );
  }

  /// `linked device`
  String get linkedDevice {
    return Intl.message(
      'linked device',
      name: 'linkedDevice',
      desc: '',
      args: [],
    );
  }

  /// `Live`
  String get live {
    return Intl.message(
      'Live',
      name: 'live',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `System time is unusual, please continue to use again after correction`
  String get loadingTime {
    return Intl.message(
      'System time is unusual, please continue to use again after correction',
      name: 'loadingTime',
      desc: '',
      args: [],
    );
  }

  /// `locate to chat`
  String get locateToChat {
    return Intl.message(
      'locate to chat',
      name: 'locateToChat',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get location {
    return Intl.message(
      'Location',
      name: 'location',
      desc: '',
      args: [],
    );
  }

  /// `Lock`
  String get lock {
    return Intl.message(
      'Lock',
      name: 'lock',
      desc: '',
      args: [],
    );
  }

  /// `Log in`
  String get logIn {
    return Intl.message(
      'Log in',
      name: 'logIn',
      desc: '',
      args: [],
    );
  }

  /// `Continue to log in and abort account deletion`
  String get loginAndAbortAccountDeletion {
    return Intl.message(
      'Continue to log in and abort account deletion',
      name: 'loginAndAbortAccountDeletion',
      desc: '',
      args: [],
    );
  }

  /// `Login to Mixin Messenger by QR Code`
  String get loginByQrcode {
    return Intl.message(
      'Login to Mixin Messenger by QR Code',
      name: 'loginByQrcode',
      desc: '',
      args: [],
    );
  }

  /// `Open Mixin Messenger on your phone.`
  String get loginByQrcodeTips1 {
    return Intl.message(
      'Open Mixin Messenger on your phone.',
      name: 'loginByQrcodeTips1',
      desc: '',
      args: [],
    );
  }

  /// `Scan the QR Code on the screen and confirm your login.`
  String get loginByQrcodeTips2 {
    return Intl.message(
      'Scan the QR Code on the screen and confirm your login.',
      name: 'loginByQrcodeTips2',
      desc: '',
      args: [],
    );
  }

  /// `Make group admin`
  String get makeGroupAdmin {
    return Intl.message(
      'Make group admin',
      name: 'makeGroupAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Media`
  String get media {
    return Intl.message(
      'Media',
      name: 'media',
      desc: '',
      args: [],
    );
  }

  /// `Memo`
  String get memo {
    return Intl.message(
      'Memo',
      name: 'memo',
      desc: '',
      args: [],
    );
  }

  /// `Messages to this conversation are encrypted end-to-end, tap for more info.`
  String get messageE2ee {
    return Intl.message(
      'Messages to this conversation are encrypted end-to-end, tap for more info.',
      name: 'messageE2ee',
      desc: '',
      args: [],
    );
  }

  /// `Message not found`
  String get messageNotFound {
    return Intl.message(
      'Message not found',
      name: 'messageNotFound',
      desc: '',
      args: [],
    );
  }

  /// `This type of message is not supported, please upgrade Mixin to the latest version.`
  String get messageNotSupport {
    return Intl.message(
      'This type of message is not supported, please upgrade Mixin to the latest version.',
      name: 'messageNotSupport',
      desc: '',
      args: [],
    );
  }

  /// `Message Preview`
  String get messagePreview {
    return Intl.message(
      'Message Preview',
      name: 'messagePreview',
      desc: '',
      args: [],
    );
  }

  /// `Preview message text inside new message notifications.`
  String get messagePreviewDescription {
    return Intl.message(
      'Preview message text inside new message notifications.',
      name: 'messagePreviewDescription',
      desc: '',
      args: [],
    );
  }

  /// `Messages`
  String get messages {
    return Intl.message(
      'Messages',
      name: 'messages',
      desc: '',
      args: [],
    );
  }

  /// `Minimize`
  String get minimize {
    return Intl.message(
      'Minimize',
      name: 'minimize',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{{arg0} Minute} other{{arg0} Minutes}}`
  String minute(num count, Object arg0) {
    return Intl.plural(
      count,
      one: '$arg0 Minute',
      other: '$arg0 Minutes',
      name: 'minute',
      desc: '',
      args: [count, arg0],
    );
  }

  /// `Mixin Messenger Desktop`
  String get mixinMessengerDesktop {
    return Intl.message(
      'Mixin Messenger Desktop',
      name: 'mixinMessengerDesktop',
      desc: '',
      args: [],
    );
  }

  /// `More`
  String get more {
    return Intl.message(
      'More',
      name: 'more',
      desc: '',
      args: [],
    );
  }

  /// `Multisig Transaction`
  String get multisigTransaction {
    return Intl.message(
      'Multisig Transaction',
      name: 'multisigTransaction',
      desc: '',
      args: [],
    );
  }

  /// `Mute`
  String get mute {
    return Intl.message(
      'Mute',
      name: 'mute',
      desc: '',
      args: [],
    );
  }

  /// `My Mixin ID: {arg0}`
  String myMixinId(Object arg0) {
    return Intl.message(
      'My Mixin ID: $arg0',
      name: 'myMixinId',
      desc: '',
      args: [arg0],
    );
  }

  /// `My Stickers`
  String get myStickers {
    return Intl.message(
      'My Stickers',
      name: 'myStickers',
      desc: '',
      args: [],
    );
  }

  /// `N/A`
  String get na {
    return Intl.message(
      'N/A',
      name: 'na',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `Network connection failed`
  String get networkConnectionFailed {
    return Intl.message(
      'Network connection failed',
      name: 'networkConnectionFailed',
      desc: '',
      args: [],
    );
  }

  /// `Network error`
  String get networkError {
    return Intl.message(
      'Network error',
      name: 'networkError',
      desc: '',
      args: [],
    );
  }

  /// `New version available`
  String get newVersionAvailable {
    return Intl.message(
      'New version available',
      name: 'newVersionAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Mixin Messenger {arg0} is now available, you have {arg1}. Would you like to download it now?`
  String newVersionDescription(Object arg0, Object arg1) {
    return Intl.message(
      'Mixin Messenger $arg0 is now available, you have $arg1. Would you like to download it now?',
      name: 'newVersionDescription',
      desc: '',
      args: [arg0, arg1],
    );
  }

  /// `Next`
  String get next {
    return Intl.message(
      'Next',
      name: 'next',
      desc: '',
      args: [],
    );
  }

  /// `Next conversation`
  String get nextConversation {
    return Intl.message(
      'Next conversation',
      name: 'nextConversation',
      desc: '',
      args: [],
    );
  }

  /// `NO AUDIO`
  String get noAudio {
    return Intl.message(
      'NO AUDIO',
      name: 'noAudio',
      desc: '',
      args: [],
    );
  }

  /// `No camera`
  String get noCamera {
    return Intl.message(
      'No camera',
      name: 'noCamera',
      desc: '',
      args: [],
    );
  }

  /// `No Data`
  String get noData {
    return Intl.message(
      'No Data',
      name: 'noData',
      desc: '',
      args: [],
    );
  }

  /// `NO FILES`
  String get noFiles {
    return Intl.message(
      'NO FILES',
      name: 'noFiles',
      desc: '',
      args: [],
    );
  }

  /// `NO LINKS`
  String get noLinks {
    return Intl.message(
      'NO LINKS',
      name: 'noLinks',
      desc: '',
      args: [],
    );
  }

  /// `NO MEDIA`
  String get noMedia {
    return Intl.message(
      'NO MEDIA',
      name: 'noMedia',
      desc: '',
      args: [],
    );
  }

  /// `No network connection`
  String get noNetworkConnection {
    return Intl.message(
      'No network connection',
      name: 'noNetworkConnection',
      desc: '',
      args: [],
    );
  }

  /// `NO POSTS`
  String get noPosts {
    return Intl.message(
      'NO POSTS',
      name: 'noPosts',
      desc: '',
      args: [],
    );
  }

  /// `NO RESULTS`
  String get noResults {
    return Intl.message(
      'NO RESULTS',
      name: 'noResults',
      desc: '',
      args: [],
    );
  }

  /// `Not found`
  String get notFound {
    return Intl.message(
      'Not found',
      name: 'notFound',
      desc: '',
      args: [],
    );
  }

  /// `This Device is not supported Biometric authentication`
  String get notSupportBiometric {
    return Intl.message(
      'This Device is not supported Biometric authentication',
      name: 'notSupportBiometric',
      desc: '',
      args: [],
    );
  }

  /// `Don't miss messages from your friends.`
  String get notificationContent {
    return Intl.message(
      'Don\'t miss messages from your friends.',
      name: 'notificationContent',
      desc: '',
      args: [],
    );
  }

  /// `Notifications are not allowed, please go to Notification Settings to turn on.`
  String get notificationPermissionManually {
    return Intl.message(
      'Notifications are not allowed, please go to Notification Settings to turn on.',
      name: 'notificationPermissionManually',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notifications {
    return Intl.message(
      'Notifications',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `{arg0} now an admin`
  String nowAnAddmin(Object arg0) {
    return Intl.message(
      '$arg0 now an admin',
      name: 'nowAnAddmin',
      desc: '',
      args: [arg0],
    );
  }

  /// `Objects`
  String get objects {
    return Intl.message(
      'Objects',
      name: 'objects',
      desc: '',
      args: [],
    );
  }

  /// `One-by-One Forward`
  String get oneByOneForward {
    return Intl.message(
      'One-by-One Forward',
      name: 'oneByOneForward',
      desc: '',
      args: [],
    );
  }

  /// `1 Hour`
  String get oneHour {
    return Intl.message(
      '1 Hour',
      name: 'oneHour',
      desc: '',
      args: [],
    );
  }

  /// `1 Week`
  String get oneWeek {
    return Intl.message(
      '1 Week',
      name: 'oneWeek',
      desc: '',
      args: [],
    );
  }

  /// `1 Year`
  String get oneYear {
    return Intl.message(
      '1 Year',
      name: 'oneYear',
      desc: '',
      args: [],
    );
  }

  /// `Open Home page`
  String get openHomePage {
    return Intl.message(
      'Open Home page',
      name: 'openHomePage',
      desc: '',
      args: [],
    );
  }

  /// `Open Link: {arg0}`
  String openLink(Object arg0) {
    return Intl.message(
      'Open Link: $arg0',
      name: 'openLink',
      desc: '',
      args: [arg0],
    );
  }

  /// `open log directory`
  String get openLogDirectory {
    return Intl.message(
      'open log directory',
      name: 'openLogDirectory',
      desc: '',
      args: [],
    );
  }

  /// `Opening Balance`
  String get openingBalance {
    return Intl.message(
      'Opening Balance',
      name: 'openingBalance',
      desc: '',
      args: [],
    );
  }

  /// `Original`
  String get originalImage {
    return Intl.message(
      'Original',
      name: 'originalImage',
      desc: '',
      args: [],
    );
  }

  /// `Owner`
  String get owner {
    return Intl.message(
      'Owner',
      name: 'owner',
      desc: '',
      args: [],
    );
  }

  /// `{arg0} PARTICIPANTS`
  String participantsCount(Object arg0) {
    return Intl.message(
      '$arg0 PARTICIPANTS',
      name: 'participantsCount',
      desc: '',
      args: [arg0],
    );
  }

  /// `Passcode incorrect`
  String get passcodeIncorrect {
    return Intl.message(
      'Passcode incorrect',
      name: 'passcodeIncorrect',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{{arg0}/{arg1} confirmation} other{{arg0}/{arg1} confirmations}}`
  String pendingConfirmation(num count, Object arg0, Object arg1) {
    return Intl.plural(
      count,
      one: '$arg0/$arg1 confirmation',
      other: '$arg0/$arg1 confirmations',
      name: 'pendingConfirmation',
      desc: '',
      args: [count, arg0, arg1],
    );
  }

  /// `Phone Number`
  String get phoneNumber {
    return Intl.message(
      'Phone Number',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Photos`
  String get photos {
    return Intl.message(
      'Photos',
      name: 'photos',
      desc: '',
      args: [],
    );
  }

  /// `Select a conversation and start sending a message`
  String get pickAConversation {
    return Intl.message(
      'Select a conversation and start sending a message',
      name: 'pickAConversation',
      desc: '',
      args: [],
    );
  }

  /// `Pin`
  String get pinTitle {
    return Intl.message(
      'Pin',
      name: 'pinTitle',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{{arg0} Pinned Message} other{{arg0} Pinned Messages}}`
  String pinnedMessageTitle(num count, Object arg0) {
    return Intl.plural(
      count,
      one: '$arg0 Pinned Message',
      other: '$arg0 Pinned Messages',
      name: 'pinnedMessageTitle',
      desc: '',
      args: [count, arg0],
    );
  }

  /// `Port`
  String get port {
    return Intl.message(
      'Port',
      name: 'port',
      desc: '',
      args: [],
    );
  }

  /// `Post`
  String get post {
    return Intl.message(
      'Post',
      name: 'post',
      desc: '',
      args: [],
    );
  }

  /// `Preferences`
  String get preferences {
    return Intl.message(
      'Preferences',
      name: 'preferences',
      desc: '',
      args: [],
    );
  }

  /// `Previous conversation`
  String get previousConversation {
    return Intl.message(
      'Previous conversation',
      name: 'previousConversation',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Proxy`
  String get proxy {
    return Intl.message(
      'Proxy',
      name: 'proxy',
      desc: '',
      args: [],
    );
  }

  /// `Authentication (Optional)`
  String get proxyAuth {
    return Intl.message(
      'Authentication (Optional)',
      name: 'proxyAuth',
      desc: '',
      args: [],
    );
  }

  /// `Connection`
  String get proxyConnection {
    return Intl.message(
      'Connection',
      name: 'proxyConnection',
      desc: '',
      args: [],
    );
  }

  /// `Proxy Type`
  String get proxyType {
    return Intl.message(
      'Proxy Type',
      name: 'proxyType',
      desc: '',
      args: [],
    );
  }

  /// `QR Code expired, please retry`
  String get qrCodeExpiredDesc {
    return Intl.message(
      'QR Code expired, please retry',
      name: 'qrCodeExpiredDesc',
      desc: '',
      args: [],
    );
  }

  /// `Quick search`
  String get quickSearch {
    return Intl.message(
      'Quick search',
      name: 'quickSearch',
      desc: '',
      args: [],
    );
  }

  /// `Quit Mixin`
  String get quitMixin {
    return Intl.message(
      'Quit Mixin',
      name: 'quitMixin',
      desc: '',
      args: [],
    );
  }

  /// `Raw`
  String get raw {
    return Intl.message(
      'Raw',
      name: 'raw',
      desc: '',
      args: [],
    );
  }

  /// `Rebate`
  String get rebate {
    return Intl.message(
      'Rebate',
      name: 'rebate',
      desc: '',
      args: [],
    );
  }

  /// `Recaptcha timeout`
  String get recaptchaTimeout {
    return Intl.message(
      'Recaptcha timeout',
      name: 'recaptchaTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Receiver`
  String get receiver {
    return Intl.message(
      'Receiver',
      name: 'receiver',
      desc: '',
      args: [],
    );
  }

  /// `CHATS`
  String get recentChats {
    return Intl.message(
      'CHATS',
      name: 'recentChats',
      desc: '',
      args: [],
    );
  }

  /// `Re-edit`
  String get reedit {
    return Intl.message(
      'Re-edit',
      name: 'reedit',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get refresh {
    return Intl.message(
      'Refresh',
      name: 'refresh',
      desc: '',
      args: [],
    );
  }

  /// `Remove Bot`
  String get removeBot {
    return Intl.message(
      'Remove Bot',
      name: 'removeBot',
      desc: '',
      args: [],
    );
  }

  /// `Remove Chat from circle`
  String get removeChatFromCircle {
    return Intl.message(
      'Remove Chat from circle',
      name: 'removeChatFromCircle',
      desc: '',
      args: [],
    );
  }

  /// `Remove Contact`
  String get removeContact {
    return Intl.message(
      'Remove Contact',
      name: 'removeContact',
      desc: '',
      args: [],
    );
  }

  /// `Remove Stickers`
  String get removeStickers {
    return Intl.message(
      'Remove Stickers',
      name: 'removeStickers',
      desc: '',
      args: [],
    );
  }

  /// `Reply`
  String get reply {
    return Intl.message(
      'Reply',
      name: 'reply',
      desc: '',
      args: [],
    );
  }

  /// `Report`
  String get report {
    return Intl.message(
      'Report',
      name: 'report',
      desc: '',
      args: [],
    );
  }

  /// `Report and block?`
  String get reportAndBlock {
    return Intl.message(
      'Report and block?',
      name: 'reportAndBlock',
      desc: '',
      args: [],
    );
  }

  /// `Send the conversation log to developers?`
  String get reportTitle {
    return Intl.message(
      'Send the conversation log to developers?',
      name: 'reportTitle',
      desc: '',
      args: [],
    );
  }

  /// `Resend code`
  String get resendCode {
    return Intl.message(
      'Resend code',
      name: 'resendCode',
      desc: '',
      args: [],
    );
  }

  /// `Resend code in {arg0} s`
  String resendCodeIn(Object arg0) {
    return Intl.message(
      'Resend code in $arg0 s',
      name: 'resendCodeIn',
      desc: '',
      args: [arg0],
    );
  }

  /// `Reset`
  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      desc: '',
      args: [],
    );
  }

  /// `Reset Link`
  String get resetLink {
    return Intl.message(
      'Reset Link',
      name: 'resetLink',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retry {
    return Intl.message(
      'Retry',
      name: 'retry',
      desc: '',
      args: [],
    );
  }

  /// `Retry upload failed.`
  String get retryUploadFailed {
    return Intl.message(
      'Retry upload failed.',
      name: 'retryUploadFailed',
      desc: '',
      args: [],
    );
  }

  /// `Revoke Multisig Transaction`
  String get revokeMultisigTransaction {
    return Intl.message(
      'Revoke Multisig Transaction',
      name: 'revokeMultisigTransaction',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Save as`
  String get saveAs {
    return Intl.message(
      'Save as',
      name: 'saveAs',
      desc: '',
      args: [],
    );
  }

  /// `Save to Camera Roll`
  String get saveToCameraRoll {
    return Intl.message(
      'Save to Camera Roll',
      name: 'saveToCameraRoll',
      desc: '',
      args: [],
    );
  }

  /// `Say Hi`
  String get sayHi {
    return Intl.message(
      'Say Hi',
      name: 'sayHi',
      desc: '',
      args: [],
    );
  }

  /// `Warning: Many users reported this account as a scam. Please be careful, especially if it asks you for money`
  String get scamWarning {
    return Intl.message(
      'Warning: Many users reported this account as a scam. Please be careful, especially if it asks you for money',
      name: 'scamWarning',
      desc: '',
      args: [],
    );
  }

  /// `Screen Passcode`
  String get screenPasscode {
    return Intl.message(
      'Screen Passcode',
      name: 'screenPasscode',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `Search contact`
  String get searchContact {
    return Intl.message(
      'Search contact',
      name: 'searchContact',
      desc: '',
      args: [],
    );
  }

  /// `Search Conversation`
  String get searchConversation {
    return Intl.message(
      'Search Conversation',
      name: 'searchConversation',
      desc: '',
      args: [],
    );
  }

  /// `No chats, contacts or messages found.`
  String get searchEmpty {
    return Intl.message(
      'No chats, contacts or messages found.',
      name: 'searchEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Search Mixin ID or phone number:`
  String get searchPlaceholderNumber {
    return Intl.message(
      'Search Mixin ID or phone number:',
      name: 'searchPlaceholderNumber',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{{arg0} related message} other{{arg0} related messages}}`
  String searchRelatedMessage(num count, Object arg0) {
    return Intl.plural(
      count,
      one: '$arg0 related message',
      other: '$arg0 related messages',
      name: 'searchRelatedMessage',
      desc: '',
      args: [count, arg0],
    );
  }

  /// `Search Unread`
  String get searchUnread {
    return Intl.message(
      'Search Unread',
      name: 'searchUnread',
      desc: '',
      args: [],
    );
  }

  /// `https://mixin.one/pages/1000007`
  String get secretUrl {
    return Intl.message(
      'https://mixin.one/pages/1000007',
      name: 'secretUrl',
      desc: '',
      args: [],
    );
  }

  /// `Security`
  String get security {
    return Intl.message(
      'Security',
      name: 'security',
      desc: '',
      args: [],
    );
  }

  /// `Select`
  String get select {
    return Intl.message(
      'Select',
      name: 'select',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get send {
    return Intl.message(
      'Send',
      name: 'send',
      desc: '',
      args: [],
    );
  }

  /// `Archived all files in one zip file`
  String get sendArchived {
    return Intl.message(
      'Archived all files in one zip file',
      name: 'sendArchived',
      desc: '',
      args: [],
    );
  }

  /// `Send quickly`
  String get sendQuickly {
    return Intl.message(
      'Send quickly',
      name: 'sendQuickly',
      desc: '',
      args: [],
    );
  }

  /// `Send to Developer`
  String get sendToDeveloper {
    return Intl.message(
      'Send to Developer',
      name: 'sendToDeveloper',
      desc: '',
      args: [],
    );
  }

  /// `Send without compression`
  String get sendWithoutCompression {
    return Intl.message(
      'Send without compression',
      name: 'sendWithoutCompression',
      desc: '',
      args: [],
    );
  }

  /// `Send Without Sound`
  String get sendWithoutSound {
    return Intl.message(
      'Send Without Sound',
      name: 'sendWithoutSound',
      desc: '',
      args: [],
    );
  }

  /// `Set`
  String get set {
    return Intl.message(
      'Set',
      name: 'set',
      desc: '',
      args: [],
    );
  }

  /// `{arg0} set disappearing message time to {arg1}`
  String setDisappearingMessageTimeTo(Object arg0, Object arg1) {
    return Intl.message(
      '$arg0 set disappearing message time to $arg1',
      name: 'setDisappearingMessageTimeTo',
      desc: '',
      args: [arg0, arg1],
    );
  }

  /// `Set Passcode to unlock Mixin Messenger`
  String get setPasscodeDesc {
    return Intl.message(
      'Set Passcode to unlock Mixin Messenger',
      name: 'setPasscodeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Mixin ID, Name`
  String get settingAuthSearchHint {
    return Intl.message(
      'Mixin ID, Name',
      name: 'settingAuthSearchHint',
      desc: '',
      args: [],
    );
  }

  /// `Back up your chat history to iCloud. if you lose your iPhone or switch to a new one, you can restore your chat history when you reinstall Mixin Messenger. Messages you back up are not protected by Mixin Messenger end-to-end encryption while in iCloud.`
  String get settingBackupTips {
    return Intl.message(
      'Back up your chat history to iCloud. if you lose your iPhone or switch to a new one, you can restore your chat history when you reinstall Mixin Messenger. Messages you back up are not protected by Mixin Messenger end-to-end encryption while in iCloud.',
      name: 'settingBackupTips',
      desc: '',
      args: [],
    );
  }

  /// `If you continue, your profile and account details will be delete on {arg0}. read our document to **learn more**.`
  String settingDeleteAccountPinContent(Object arg0) {
    return Intl.message(
      'If you continue, your profile and account details will be delete on $arg0. read our document to **learn more**.',
      name: 'settingDeleteAccountPinContent',
      desc: '',
      args: [arg0],
    );
  }

  /// `https://mixinmessenger.zendesk.com/hc/articles/4414170627988`
  String get settingDeleteAccountUrl {
    return Intl.message(
      'https://mixinmessenger.zendesk.com/hc/articles/4414170627988',
      name: 'settingDeleteAccountUrl',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get share {
    return Intl.message(
      'Share',
      name: 'share',
      desc: '',
      args: [],
    );
  }

  /// `Shared Apps`
  String get shareApps {
    return Intl.message(
      'Shared Apps',
      name: 'shareApps',
      desc: '',
      args: [],
    );
  }

  /// `Share Contact`
  String get shareContact {
    return Intl.message(
      'Share Contact',
      name: 'shareContact',
      desc: '',
      args: [],
    );
  }

  /// `Share error.`
  String get shareError {
    return Intl.message(
      'Share error.',
      name: 'shareError',
      desc: '',
      args: [],
    );
  }

  /// `Share Link`
  String get shareLink {
    return Intl.message(
      'Share Link',
      name: 'shareLink',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to send a {arg0} from {arg1}?`
  String shareMessageDescription(Object arg0, Object arg1) {
    return Intl.message(
      'Are you sure you want to send a $arg0 from $arg1?',
      name: 'shareMessageDescription',
      desc: '',
      args: [arg0, arg1],
    );
  }

  /// `Are you sure you want to send the {arg0}?`
  String shareMessageDescriptionEmpty(Object arg0) {
    return Intl.message(
      'Are you sure you want to send the $arg0?',
      name: 'shareMessageDescriptionEmpty',
      desc: '',
      args: [arg0],
    );
  }

  /// `Shared Media`
  String get sharedMedia {
    return Intl.message(
      'Shared Media',
      name: 'sharedMedia',
      desc: '',
      args: [],
    );
  }

  /// `Show`
  String get show {
    return Intl.message(
      'Show',
      name: 'show',
      desc: '',
      args: [],
    );
  }

  /// `Show avatar`
  String get showAvatar {
    return Intl.message(
      'Show avatar',
      name: 'showAvatar',
      desc: '',
      args: [],
    );
  }

  /// `Show Mixin`
  String get showMixin {
    return Intl.message(
      'Show Mixin',
      name: 'showMixin',
      desc: '',
      args: [],
    );
  }

  /// `Sign in`
  String get signIn {
    return Intl.message(
      'Sign in',
      name: 'signIn',
      desc: '',
      args: [],
    );
  }

  /// `Sign Out`
  String get signOut {
    return Intl.message(
      'Sign Out',
      name: 'signOut',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with phone number`
  String get signWithPhoneNumber {
    return Intl.message(
      'Sign in with phone number',
      name: 'signWithPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with QR code`
  String get signWithQrcode {
    return Intl.message(
      'Sign in with QR code',
      name: 'signWithQrcode',
      desc: '',
      args: [],
    );
  }

  /// `Smileys & People`
  String get smileysAndPeople {
    return Intl.message(
      'Smileys & People',
      name: 'smileysAndPeople',
      desc: '',
      args: [],
    );
  }

  /// `Snapshot Hash`
  String get snapshotHash {
    return Intl.message(
      'Snapshot Hash',
      name: 'snapshotHash',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get status {
    return Intl.message(
      'Status',
      name: 'status',
      desc: '',
      args: [],
    );
  }

  /// `Sticker`
  String get sticker {
    return Intl.message(
      'Sticker',
      name: 'sticker',
      desc: '',
      args: [],
    );
  }

  /// `Sticker album detail`
  String get stickerAlbumDetail {
    return Intl.message(
      'Sticker album detail',
      name: 'stickerAlbumDetail',
      desc: '',
      args: [],
    );
  }

  /// `Sticker Store`
  String get stickerStore {
    return Intl.message(
      'Sticker Store',
      name: 'stickerStore',
      desc: '',
      args: [],
    );
  }

  /// `Change auto-download settings for medias.`
  String get storageAutoDownloadDescription {
    return Intl.message(
      'Change auto-download settings for medias.',
      name: 'storageAutoDownloadDescription',
      desc: '',
      args: [],
    );
  }

  /// `Storage Usage`
  String get storageUsage {
    return Intl.message(
      'Storage Usage',
      name: 'storageUsage',
      desc: '',
      args: [],
    );
  }

  /// `This sender is not in your contacts`
  String get strangerHint {
    return Intl.message(
      'This sender is not in your contacts',
      name: 'strangerHint',
      desc: '',
      args: [],
    );
  }

  /// `Strangers`
  String get strangers {
    return Intl.message(
      'Strangers',
      name: 'strangers',
      desc: '',
      args: [],
    );
  }

  /// `Successful`
  String get successful {
    return Intl.message(
      'Successful',
      name: 'successful',
      desc: '',
      args: [],
    );
  }

  /// `Symbols`
  String get symbols {
    return Intl.message(
      'Symbols',
      name: 'symbols',
      desc: '',
      args: [],
    );
  }

  /// `Terms of Service`
  String get termsOfService {
    return Intl.message(
      'Terms of Service',
      name: 'termsOfService',
      desc: '',
      args: [],
    );
  }

  /// `Text`
  String get text {
    return Intl.message(
      'Text',
      name: 'text',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get theme {
    return Intl.message(
      'Theme',
      name: 'theme',
      desc: '',
      args: [],
    );
  }

  /// `This message was deleted`
  String get thisMessageWasDeleted {
    return Intl.message(
      'This message was deleted',
      name: 'thisMessageWasDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Time`
  String get time {
    return Intl.message(
      'Time',
      name: 'time',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get today {
    return Intl.message(
      'Today',
      name: 'today',
      desc: '',
      args: [],
    );
  }

  /// `Toggle chat info`
  String get toggleChatInfo {
    return Intl.message(
      'Toggle chat info',
      name: 'toggleChatInfo',
      desc: '',
      args: [],
    );
  }

  /// `Trace`
  String get trace {
    return Intl.message(
      'Trace',
      name: 'trace',
      desc: '',
      args: [],
    );
  }

  /// `Transaction Hash`
  String get transactionHash {
    return Intl.message(
      'Transaction Hash',
      name: 'transactionHash',
      desc: '',
      args: [],
    );
  }

  /// `Transaction Id`
  String get transactionId {
    return Intl.message(
      'Transaction Id',
      name: 'transactionId',
      desc: '',
      args: [],
    );
  }

  /// `Transaction Type`
  String get transactionType {
    return Intl.message(
      'Transaction Type',
      name: 'transactionType',
      desc: '',
      args: [],
    );
  }

  /// `Transactions`
  String get transactions {
    return Intl.message(
      'Transactions',
      name: 'transactions',
      desc: '',
      args: [],
    );
  }

  /// `Transactions CANNOT be deleted`
  String get transactionsCannotBeDeleted {
    return Intl.message(
      'Transactions CANNOT be deleted',
      name: 'transactionsCannotBeDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Transcript`
  String get transcript {
    return Intl.message(
      'Transcript',
      name: 'transcript',
      desc: '',
      args: [],
    );
  }

  /// `Transfer`
  String get transfer {
    return Intl.message(
      'Transfer',
      name: 'transfer',
      desc: '',
      args: [],
    );
  }

  /// `Transfer completed`
  String get transferCompleted {
    return Intl.message(
      'Transfer completed',
      name: 'transferCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Transfer failed`
  String get transferFailed {
    return Intl.message(
      'Transfer failed',
      name: 'transferFailed',
      desc: '',
      args: [],
    );
  }

  /// `Protocol version does not match, transfer failed. Please upgrade the application first.`
  String get transferProtocolVersionNotMatched {
    return Intl.message(
      'Protocol version does not match, transfer failed. Please upgrade the application first.',
      name: 'transferProtocolVersionNotMatched',
      desc: '',
      args: [],
    );
  }

  /// `Transferring Chat`
  String get transferringChats {
    return Intl.message(
      'Transferring Chat',
      name: 'transferringChats',
      desc: '',
      args: [],
    );
  }

  /// `Please do not turn off the screen and keep the Mixin running in the foreground while syncing.`
  String get transferringChatsTips {
    return Intl.message(
      'Please do not turn off the screen and keep the Mixin running in the foreground while syncing.',
      name: 'transferringChatsTips',
      desc: '',
      args: [],
    );
  }

  /// `Travel & Places`
  String get travelAndPlaces {
    return Intl.message(
      'Travel & Places',
      name: 'travelAndPlaces',
      desc: '',
      args: [],
    );
  }

  /// `Turn On Notifications`
  String get turnOnNotifications {
    return Intl.message(
      'Turn On Notifications',
      name: 'turnOnNotifications',
      desc: '',
      args: [],
    );
  }

  /// `Type message`
  String get typeMessage {
    return Intl.message(
      'Type message',
      name: 'typeMessage',
      desc: '',
      args: [],
    );
  }

  /// `Unable to open file: {arg0}`
  String unableToOpenFile(Object arg0) {
    return Intl.message(
      'Unable to open file: $arg0',
      name: 'unableToOpenFile',
      desc: '',
      args: [arg0],
    );
  }

  /// `Unblock`
  String get unblock {
    return Intl.message(
      'Unblock',
      name: 'unblock',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{day} other{days}}`
  String unitDay(num count) {
    return Intl.plural(
      count,
      one: 'day',
      other: 'days',
      name: 'unitDay',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{hour} other{hours}}`
  String unitHour(num count) {
    return Intl.plural(
      count,
      one: 'hour',
      other: 'hours',
      name: 'unitHour',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{minute} other{minutes}}`
  String unitMinute(num count) {
    return Intl.plural(
      count,
      one: 'minute',
      other: 'minutes',
      name: 'unitMinute',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{second} other{seconds}}`
  String unitSecond(num count) {
    return Intl.plural(
      count,
      one: 'second',
      other: 'seconds',
      name: 'unitSecond',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{week} other{weeks}}`
  String unitWeek(num count) {
    return Intl.plural(
      count,
      one: 'week',
      other: 'weeks',
      name: 'unitWeek',
      desc: '',
      args: [count],
    );
  }

  /// `Unknow error`
  String get unknowError {
    return Intl.message(
      'Unknow error',
      name: 'unknowError',
      desc: '',
      args: [],
    );
  }

  /// `Unlock Mixin Messenger`
  String get unlockMixinMessenger {
    return Intl.message(
      'Unlock Mixin Messenger',
      name: 'unlockMixinMessenger',
      desc: '',
      args: [],
    );
  }

  /// `Enter Passcode to unlock Mixin Messenger`
  String get unlockWithWasscode {
    return Intl.message(
      'Enter Passcode to unlock Mixin Messenger',
      name: 'unlockWithWasscode',
      desc: '',
      args: [],
    );
  }

  /// `Unmute`
  String get unmute {
    return Intl.message(
      'Unmute',
      name: 'unmute',
      desc: '',
      args: [],
    );
  }

  /// `Unpin`
  String get unpin {
    return Intl.message(
      'Unpin',
      name: 'unpin',
      desc: '',
      args: [],
    );
  }

  /// `Unpin All Messages`
  String get unpinAllMessages {
    return Intl.message(
      'Unpin All Messages',
      name: 'unpinAllMessages',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to unpin all messages?`
  String get unpinAllMessagesConfirmation {
    return Intl.message(
      'Are you sure you want to unpin all messages?',
      name: 'unpinAllMessagesConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Unread messages`
  String get unreadMessages {
    return Intl.message(
      'Unread messages',
      name: 'unreadMessages',
      desc: '',
      args: [],
    );
  }

  /// `Upgrading`
  String get upgrading {
    return Intl.message(
      'Upgrading',
      name: 'upgrading',
      desc: '',
      args: [],
    );
  }

  /// `Use Biometric`
  String get useBiometric {
    return Intl.message(
      'Use Biometric',
      name: 'useBiometric',
      desc: '',
      args: [],
    );
  }

  /// `The user has deleted his own account.`
  String get userDeleteHint {
    return Intl.message(
      'The user has deleted his own account.',
      name: 'userDeleteHint',
      desc: '',
      args: [],
    );
  }

  /// `User not found`
  String get userNotFound {
    return Intl.message(
      'User not found',
      name: 'userNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message(
      'Username',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  /// `value now {arg0}`
  String valueNow(Object arg0) {
    return Intl.message(
      'value now $arg0',
      name: 'valueNow',
      desc: '',
      args: [arg0],
    );
  }

  /// `value then {arg0}`
  String valueThen(Object arg0) {
    return Intl.message(
      'value then $arg0',
      name: 'valueThen',
      desc: '',
      args: [arg0],
    );
  }

  /// `Verify PIN`
  String get verifyPin {
    return Intl.message(
      'Verify PIN',
      name: 'verifyPin',
      desc: '',
      args: [],
    );
  }

  /// `Video`
  String get video {
    return Intl.message(
      'Video',
      name: 'video',
      desc: '',
      args: [],
    );
  }

  /// `Videos`
  String get videos {
    return Intl.message(
      'Videos',
      name: 'videos',
      desc: '',
      args: [],
    );
  }

  /// `Waiting for this message.`
  String get waitingForThisMessage {
    return Intl.message(
      'Waiting for this message.',
      name: 'waitingForThisMessage',
      desc: '',
      args: [],
    );
  }

  /// `The device has not installed the WebView2 Runtime component. Please download and install WebView2 Runtime first.`
  String get webview2RuntimeInstallDescription {
    return Intl.message(
      'The device has not installed the WebView2 Runtime component. Please download and install WebView2 Runtime first.',
      name: 'webview2RuntimeInstallDescription',
      desc: '',
      args: [],
    );
  }

  /// `WebView runtime is unavailable`
  String get webviewRuntimeUnavailable {
    return Intl.message(
      'WebView runtime is unavailable',
      name: 'webviewRuntimeUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `What's your name?`
  String get whatsYourName {
    return Intl.message(
      'What\'s your name?',
      name: 'whatsYourName',
      desc: '',
      args: [],
    );
  }

  /// `Window`
  String get window {
    return Intl.message(
      'Window',
      name: 'window',
      desc: '',
      args: [],
    );
  }

  /// `Withdraw`
  String get withdrawal {
    return Intl.message(
      'Withdraw',
      name: 'withdrawal',
      desc: '',
      args: [],
    );
  }

  /// `You`
  String get you {
    return Intl.message(
      'You',
      name: 'you',
      desc: '',
      args: [],
    );
  }

  /// `You deleted this message`
  String get youDeletedThisMessage {
    return Intl.message(
      'You deleted this message',
      name: 'youDeletedThisMessage',
      desc: '',
      args: [],
    );
  }

  /// `Zoom`
  String get zoom {
    return Intl.message(
      'Zoom',
      name: 'zoom',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<Localization> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'in'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ms'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'zh-HK'),
      Locale.fromSubtags(languageCode: 'zh-TW'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<Localization> load(Locale locale) => Localization.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
