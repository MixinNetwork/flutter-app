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

  /// `Mixin Messenger`
  String get mixinMessenger {
    return Intl.message(
      'Mixin Messenger',
      name: 'mixinMessenger',
      desc: '',
      args: [],
    );
  }

  /// `Initializing`
  String get initializing {
    return Intl.message(
      'Initializing',
      name: 'initializing',
      desc: '',
      args: [],
    );
  }

  /// `Provisioning`
  String get provisioning {
    return Intl.message(
      'Provisioning',
      name: 'provisioning',
      desc: '',
      args: [],
    );
  }

  /// `Please wait a moment`
  String get pleaseWait {
    return Intl.message(
      'Please wait a moment',
      name: 'pleaseWait',
      desc: '',
      args: [],
    );
  }

  /// `Login to Mixin Messenger by QR Code`
  String get pageLandingLoginTitle {
    return Intl.message(
      'Login to Mixin Messenger by QR Code',
      name: 'pageLandingLoginTitle',
      desc: '',
      args: [],
    );
  }

  /// `Open Mixin Messenger on your phone, scan the QR Code on the screen and confirm your login.`
  String get pageLandingLoginMessage {
    return Intl.message(
      'Open Mixin Messenger on your phone, scan the QR Code on the screen and confirm your login.',
      name: 'pageLandingLoginMessage',
      desc: '',
      args: [],
    );
  }

  /// `CLICK TO RELOAD QR CODE`
  String get pageLandingClickToReload {
    return Intl.message(
      'CLICK TO RELOAD QR CODE',
      name: 'pageLandingClickToReload',
      desc: '',
      args: [],
    );
  }

  /// `Contacts`
  String get contacts {
    return Intl.message(
      'Contacts',
      name: 'contacts',
      desc: '',
      args: [],
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

  /// `Bots`
  String get bots {
    return Intl.message(
      'Bots',
      name: 'bots',
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

  /// `Select a conversation to start messaging`
  String get pageRightEmptyMessage {
    return Intl.message(
      'Select a conversation to start messaging',
      name: 'pageRightEmptyMessage',
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

  /// `Edit Profile`
  String get editProfile {
    return Intl.message(
      'Edit Profile',
      name: 'editProfile',
      desc: '',
      args: [],
    );
  }

  /// `Notification`
  String get notification {
    return Intl.message(
      'Notification',
      name: 'notification',
      desc: '',
      args: [],
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

  /// `Data and Storage Usage`
  String get dataAndStorageUsage {
    return Intl.message(
      'Data and Storage Usage',
      name: 'dataAndStorageUsage',
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

  /// `About`
  String get about {
    return Intl.message(
      'About',
      name: 'about',
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

  /// `NO DATA`
  String get noData {
    return Intl.message(
      'NO DATA',
      name: 'noData',
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

  /// `Introduction`
  String get introduction {
    return Intl.message(
      'Introduction',
      name: 'introduction',
      desc: '',
      args: [],
    );
  }

  /// `Phone number`
  String get phoneNumber {
    return Intl.message(
      'Phone number',
      name: 'phoneNumber',
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

  /// `{date} join`
  String pageEditProfileJoin(Object date) {
    return Intl.message(
      '$date join',
      name: 'pageEditProfileJoin',
      desc: '',
      args: [date],
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

  /// `Manage Circle`
  String get editCircle {
    return Intl.message(
      'Manage Circle',
      name: 'editCircle',
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

  /// `Reply`
  String get reply {
    return Intl.message(
      'Reply',
      name: 'reply',
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

  /// `Copy`
  String get copy {
    return Intl.message(
      'Copy',
      name: 'copy',
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

  /// `Pin`
  String get pin {
    return Intl.message(
      'Pin',
      name: 'pin',
      desc: '',
      args: [],
    );
  }

  /// `Unpin`
  String get unPin {
    return Intl.message(
      'Unpin',
      name: 'unPin',
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

  /// `Mute`
  String get mute {
    return Intl.message(
      'Mute',
      name: 'mute',
      desc: '',
      args: [],
    );
  }

  /// `Unmute`
  String get unMute {
    return Intl.message(
      'Unmute',
      name: 'unMute',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to delete {name} circle?`
  String pageDeleteCircle(Object name) {
    return Intl.message(
      'Do you want to delete $name circle?',
      name: 'pageDeleteCircle',
      desc: '',
      args: [name],
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

  /// `Waiting for this message.`
  String get waitingForThisMessage {
    return Intl.message(
      'Waiting for this message.',
      name: 'waitingForThisMessage',
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

  /// `Sticker`
  String get sticker {
    return Intl.message(
      'Sticker',
      name: 'sticker',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get image {
    return Intl.message(
      'Image',
      name: 'image',
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

  /// `Live`
  String get live {
    return Intl.message(
      'Live',
      name: 'live',
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

  /// `Post`
  String get post {
    return Intl.message(
      'Post',
      name: 'post',
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

  /// `Audio`
  String get audio {
    return Intl.message(
      'Audio',
      name: 'audio',
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

  /// `Video call`
  String get videoCall {
    return Intl.message(
      'Video call',
      name: 'videoCall',
      desc: '',
      args: [],
    );
  }

  /// `Preview`
  String get preview {
    return Intl.message(
      'Preview',
      name: 'preview',
      desc: '',
      args: [],
    );
  }

  /// `This sender is not in your contacts`
  String get strangerFromMessage {
    return Intl.message(
      'This sender is not in your contacts',
      name: 'strangerFromMessage',
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

  /// `Add contact`
  String get addContact {
    return Intl.message(
      'Add contact',
      name: 'addContact',
      desc: '',
      args: [],
    );
  }

  /// `Click the button to interact with the bot`
  String get botInteractInfo {
    return Intl.message(
      'Click the button to interact with the bot',
      name: 'botInteractInfo',
      desc: '',
      args: [],
    );
  }

  /// `Open Home page`
  String get botInteractOpen {
    return Intl.message(
      'Open Home page',
      name: 'botInteractOpen',
      desc: '',
      args: [],
    );
  }

  /// `Say hi`
  String get botInteractHi {
    return Intl.message(
      'Say hi',
      name: 'botInteractHi',
      desc: '',
      args: [],
    );
  }

  /// `This type of message is not supported, please upgrade Mixin to the latest version.`
  String get chatNotSupport {
    return Intl.message(
      'This type of message is not supported, please upgrade Mixin to the latest version.',
      name: 'chatNotSupport',
      desc: '',
      args: [],
    );
  }

  /// `This type of message is not supported, please check on your phone.`
  String get chatCheckOnPhone {
    return Intl.message(
      'This type of message is not supported, please check on your phone.',
      name: 'chatCheckOnPhone',
      desc: '',
      args: [],
    );
  }

  /// `Learn more`
  String get chatLearn {
    return Intl.message(
      'Learn more',
      name: 'chatLearn',
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

  /// `Messages to this conversation are encrypted end-to-end, tap for more info.`
  String get aboutEncryptedInfo {
    return Intl.message(
      'Messages to this conversation are encrypted end-to-end, tap for more info.',
      name: 'aboutEncryptedInfo',
      desc: '',
      args: [],
    );
  }

  /// `https://mixin.one/pages/1000007`
  String get aboutEncryptedInfoUrl {
    return Intl.message(
      'https://mixin.one/pages/1000007',
      name: 'aboutEncryptedInfoUrl',
      desc: '',
      args: [],
    );
  }

  /// `Waiting for {name} to get online and establish an encrypted session.`
  String chatWaiting(Object name) {
    return Intl.message(
      'Waiting for $name to get online and establish an encrypted session.',
      name: 'chatWaiting',
      desc: '',
      args: [name],
    );
  }

  /// `desktop`
  String get chatWaitingDesktop {
    return Intl.message(
      'desktop',
      name: 'chatWaitingDesktop',
      desc: '',
      args: [],
    );
  }

  /// `{name} joined the group via invite link`
  String chatGroupJoin(Object name) {
    return Intl.message(
      '$name joined the group via invite link',
      name: 'chatGroupJoin',
      desc: '',
      args: [name],
    );
  }

  /// `you`
  String get you {
    return Intl.message(
      'you',
      name: 'you',
      desc: '',
      args: [],
    );
  }

  /// `You`
  String get youStart {
    return Intl.message(
      'You',
      name: 'youStart',
      desc: '',
      args: [],
    );
  }

  /// `{name} left`
  String chatGroupExit(Object name) {
    return Intl.message(
      '$name left',
      name: 'chatGroupExit',
      desc: '',
      args: [name],
    );
  }

  /// `{name} added {addedName}`
  String chatGroupAdd(Object name, Object addedName) {
    return Intl.message(
      '$name added $addedName',
      name: 'chatGroupAdd',
      desc: '',
      args: [name, addedName],
    );
  }

  /// `{name} removed {removedName}`
  String chatGroupRemove(Object name, Object removedName) {
    return Intl.message(
      '$name removed $removedName',
      name: 'chatGroupRemove',
      desc: '',
      args: [name, removedName],
    );
  }

  /// `{name} created group {groupName}`
  String chatGroupCreate(Object name, Object groupName) {
    return Intl.message(
      '$name created group $groupName',
      name: 'chatGroupCreate',
      desc: '',
      args: [name, groupName],
    );
  }

  /// `You're now an admin`
  String get chatGroupRole {
    return Intl.message(
      'You\'re now an admin',
      name: 'chatGroupRole',
      desc: '',
      args: [],
    );
  }

  /// `Message not found`
  String get chatNotFound {
    return Intl.message(
      'Message not found',
      name: 'chatNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Extensions`
  String get extensions {
    return Intl.message(
      'Extensions',
      name: 'extensions',
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

  /// `Delete for Everyone`
  String get deleteForEveryone {
    return Intl.message(
      'Delete for Everyone',
      name: 'deleteForEveryone',
      desc: '',
      args: [],
    );
  }

  /// `You deleted this message`
  String get chatRecallMe {
    return Intl.message(
      'You deleted this message',
      name: 'chatRecallMe',
      desc: '',
      args: [],
    );
  }

  /// `This message was deleted`
  String get chatRecallDelete {
    return Intl.message(
      'This message was deleted',
      name: 'chatRecallDelete',
      desc: '',
      args: [],
    );
  }

  /// `Recent conversations`
  String get recentConversations {
    return Intl.message(
      'Recent conversations',
      name: 'recentConversations',
      desc: '',
      args: [],
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
  String get createGroupConversation {
    return Intl.message(
      'New Group',
      name: 'createGroupConversation',
      desc: '',
      args: [],
    );
  }

  /// `{count} Participants`
  String participantsCount(Object count) {
    return Intl.message(
      '$count Participants',
      name: 'participantsCount',
      desc: '',
      args: [count],
    );
  }

  /// `Conversation Name`
  String get conversationName {
    return Intl.message(
      'Conversation Name',
      name: 'conversationName',
      desc: '',
      args: [],
    );
  }

  /// `End to end encrypted`
  String get chatInputHint {
    return Intl.message(
      'End to end encrypted',
      name: 'chatInputHint',
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

  /// `No chats, \ncontacts or messages found.`
  String get searchEmpty {
    return Intl.message(
      'No chats, \ncontacts or messages found.',
      name: 'searchEmpty',
      desc: '',
      args: [],
    );
  }

  /// `more`
  String get more {
    return Intl.message(
      'more',
      name: 'more',
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

  /// `{count} related messages`
  String searchRelatedMessage(Object count) {
    return Intl.message(
      '$count related messages',
      name: 'searchRelatedMessage',
      desc: '',
      args: [count],
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

  /// `Messages`
  String get messages {
    return Intl.message(
      'Messages',
      name: 'messages',
      desc: '',
      args: [],
    );
  }

  /// `ID: {id}`
  String conversationID(Object id) {
    return Intl.message(
      'ID: $id',
      name: 'conversationID',
      desc: '',
      args: [id],
    );
  }

  /// `{count} Participants`
  String conversationParticipantsCount(Object count) {
    return Intl.message(
      '$count Participants',
      name: 'conversationParticipantsCount',
      desc: '',
      args: [count],
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

  /// `Shared Media`
  String get sharedMedia {
    return Intl.message(
      'Shared Media',
      name: 'sharedMedia',
      desc: '',
      args: [],
    );
  }

  /// `Shared Apps`
  String get sharedApps {
    return Intl.message(
      'Shared Apps',
      name: 'sharedApps',
      desc: '',
      args: [],
    );
  }

  /// `Mute`
  String get muted {
    return Intl.message(
      'Mute',
      name: 'muted',
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

  /// `Transactions`
  String get transactions {
    return Intl.message(
      'Transactions',
      name: 'transactions',
      desc: '',
      args: [],
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

  /// `Remove Contact`
  String get removeContact {
    return Intl.message(
      'Remove Contact',
      name: 'removeContact',
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

  /// `Report`
  String get report {
    return Intl.message(
      'Report',
      name: 'report',
      desc: '',
      args: [],
    );
  }

  /// `Delete and Exit`
  String get exitGroup {
    return Intl.message(
      'Delete and Exit',
      name: 'exitGroup',
      desc: '',
      args: [],
    );
  }

  /// `Loading`
  String get loading {
    return Intl.message(
      'Loading',
      name: 'loading',
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

  /// `Successful`
  String get successful {
    return Intl.message(
      'Successful',
      name: 'successful',
      desc: '',
      args: [],
    );
  }

  /// `Chats`
  String get chats {
    return Intl.message(
      'Chats',
      name: 'chats',
      desc: '',
      args: [],
    );
  }

  /// `{name}'s Circles`
  String circleTitle(Object name) {
    return Intl.message(
      '$name\'s Circles',
      name: 'circleTitle',
      desc: '',
      args: [name],
    );
  }

  /// `{count} Conversations`
  String conversationCount(Object count) {
    return Intl.message(
      '$count Conversations',
      name: 'conversationCount',
      desc: '',
      args: [count],
    );
  }

  /// `Do you want to report and block this contact?`
  String get reportWarning {
    return Intl.message(
      'Do you want to report and block this contact?',
      name: 'reportWarning',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get confirm {
    return Intl.message(
      'OK',
      name: 'confirm',
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

  /// `Unblock`
  String get unblock {
    return Intl.message(
      'Unblock',
      name: 'unblock',
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

  /// `Mute notifications for…`
  String get muteTitle {
    return Intl.message(
      'Mute notifications for…',
      name: 'muteTitle',
      desc: '',
      args: [],
    );
  }

  /// `1 Hour`
  String get mute1hour {
    return Intl.message(
      '1 Hour',
      name: 'mute1hour',
      desc: '',
      args: [],
    );
  }

  /// `8 Hours`
  String get mute8hours {
    return Intl.message(
      '8 Hours',
      name: 'mute8hours',
      desc: '',
      args: [],
    );
  }

  /// `1 Week`
  String get mute1week {
    return Intl.message(
      '1 Week',
      name: 'mute1week',
      desc: '',
      args: [],
    );
  }

  /// `1 Year`
  String get mute1year {
    return Intl.message(
      '1 Year',
      name: 'mute1year',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get searchMessageHistory {
    return Intl.message(
      'Search',
      name: 'searchMessageHistory',
      desc: '',
      args: [],
    );
  }

  /// `Add group description`
  String get addAnnouncement {
    return Intl.message(
      'Add group description',
      name: 'addAnnouncement',
      desc: '',
      args: [],
    );
  }

  /// `Edit group description`
  String get editAnnouncement {
    return Intl.message(
      'Edit group description',
      name: 'editAnnouncement',
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

  /// `Links`
  String get links {
    return Intl.message(
      'Links',
      name: 'links',
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

  /// `NO AUDIO`
  String get noAudio {
    return Intl.message(
      'NO AUDIO',
      name: 'noAudio',
      desc: '',
      args: [],
    );
  }

  /// `NO POST`
  String get noPost {
    return Intl.message(
      'NO POST',
      name: 'noPost',
      desc: '',
      args: [],
    );
  }

  /// `NO FILE`
  String get noFile {
    return Intl.message(
      'NO FILE',
      name: 'noFile',
      desc: '',
      args: [],
    );
  }

  /// `NO LINK`
  String get noLink {
    return Intl.message(
      'NO LINK',
      name: 'noLink',
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

  /// `Follow us on Twitter`
  String get followTwitter {
    return Intl.message(
      'Follow us on Twitter',
      name: 'followTwitter',
      desc: '',
      args: [],
    );
  }

  /// `Follow us on Facebook`
  String get followFacebook {
    return Intl.message(
      'Follow us on Facebook',
      name: 'followFacebook',
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

  /// `Terms of Service`
  String get termsService {
    return Intl.message(
      'Terms of Service',
      name: 'termsService',
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

  /// `Photos`
  String get photos {
    return Intl.message(
      'Photos',
      name: 'photos',
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

  /// `Audios`
  String get audios {
    return Intl.message(
      'Audios',
      name: 'audios',
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

  /// `Storage Usage`
  String get storageUsage {
    return Intl.message(
      'Storage Usage',
      name: 'storageUsage',
      desc: '',
      args: [],
    );
  }

  /// `Change auto-download settings for medias. `
  String get storageAutoDownloadDescription {
    return Intl.message(
      'Change auto-download settings for medias. ',
      name: 'storageAutoDownloadDescription',
      desc: '',
      args: [],
    );
  }

  /// `Back up your chat history to iCloud so if you lose your iPhone or switch to a new one, your chat history is safe. You can restore your chat history when you reinstall MixinMessenger. messenger you back up are encryption while in icloud.`
  String get chatBackupDescription {
    return Intl.message(
      'Back up your chat history to iCloud so if you lose your iPhone or switch to a new one, your chat history is safe. You can restore your chat history when you reinstall MixinMessenger. messenger you back up are encryption while in icloud.',
      name: 'chatBackupDescription',
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

  /// `Auto Backup`
  String get autoBackup {
    return Intl.message(
      'Auto Backup',
      name: 'autoBackup',
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

  /// `Clear`
  String get clear {
    return Intl.message(
      'Clear',
      name: 'clear',
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

  /// `Participants`
  String get groupParticipants {
    return Intl.message(
      'Participants',
      name: 'groupParticipants',
      desc: '',
      args: [],
    );
  }

  /// `admin`
  String get groupAdmin {
    return Intl.message(
      'admin',
      name: 'groupAdmin',
      desc: '',
      args: [],
    );
  }

  /// `owner`
  String get groupOwner {
    return Intl.message(
      'owner',
      name: 'groupOwner',
      desc: '',
      args: [],
    );
  }

  /// `Message {name}`
  String groupPopMenuMessage(Object name) {
    return Intl.message(
      'Message $name',
      name: 'groupPopMenuMessage',
      desc: '',
      args: [name],
    );
  }

  /// `Make group admin`
  String get groupPopMenuMakeAdmin {
    return Intl.message(
      'Make group admin',
      name: 'groupPopMenuMakeAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Dismiss admin`
  String get groupPopMenuDismissAdmin {
    return Intl.message(
      'Dismiss admin',
      name: 'groupPopMenuDismissAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Remove {name}`
  String groupPopMenuRemoveParticipants(Object name) {
    return Intl.message(
      'Remove $name',
      name: 'groupPopMenuRemoveParticipants',
      desc: '',
      args: [name],
    );
  }

  /// `Mixin ID, Name`
  String get groupSearchParticipants {
    return Intl.message(
      'Mixin ID, Name',
      name: 'groupSearchParticipants',
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

  /// `+ Add Contact`
  String get conversationAddContact {
    return Intl.message(
      '+ Add Contact',
      name: 'conversationAddContact',
      desc: '',
      args: [],
    );
  }

  /// `+ Add Bot`
  String get conversationAddBot {
    return Intl.message(
      '+ Add Bot',
      name: 'conversationAddBot',
      desc: '',
      args: [],
    );
  }

  /// `New Messages`
  String get unread {
    return Intl.message(
      'New Messages',
      name: 'unread',
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

  /// `Dark`
  String get settingThemeNight {
    return Intl.message(
      'Dark',
      name: 'settingThemeNight',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get settingThemeLight {
    return Intl.message(
      'Light',
      name: 'settingThemeLight',
      desc: '',
      args: [],
    );
  }

  /// `Follow system`
  String get settingThemeAuto {
    return Intl.message(
      'Follow system',
      name: 'settingThemeAuto',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get settingTheme {
    return Intl.message(
      'Theme',
      name: 'settingTheme',
      desc: '',
      args: [],
    );
  }

  /// `You can't send messages to this group because you're no longer a participant.`
  String get groupCantSendDes {
    return Intl.message(
      'You can\'t send messages to this group because you\'re no longer a participant.',
      name: 'groupCantSendDes',
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

  /// `Add Participants`
  String get groupAdd {
    return Intl.message(
      'Add Participants',
      name: 'groupAdd',
      desc: '',
      args: [],
    );
  }

  /// `Invite to Group via Link`
  String get groupInvite {
    return Intl.message(
      'Invite to Group via Link',
      name: 'groupInvite',
      desc: '',
      args: [],
    );
  }

  /// `Anyone with Mixin can follow this link to join this group. Only share it with people you trust.`
  String get groupInviteInfo {
    return Intl.message(
      'Anyone with Mixin can follow this link to join this group. Only share it with people you trust.',
      name: 'groupInviteInfo',
      desc: '',
      args: [],
    );
  }

  /// `Share Link`
  String get groupInviteShare {
    return Intl.message(
      'Share Link',
      name: 'groupInviteShare',
      desc: '',
      args: [],
    );
  }

  /// `Copy Link`
  String get groupInviteCopy {
    return Intl.message(
      'Copy Link',
      name: 'groupInviteCopy',
      desc: '',
      args: [],
    );
  }

  /// `Reset Link`
  String get groupInviteReset {
    return Intl.message(
      'Reset Link',
      name: 'groupInviteReset',
      desc: '',
      args: [],
    );
  }

  /// `Mixin ID: {mixinId}`
  String contactMixinId(Object mixinId) {
    return Intl.message(
      'Mixin ID: $mixinId',
      name: 'contactMixinId',
      desc: '',
      args: [mixinId],
    );
  }

  /// `Drag and drop files here`
  String get chatDragHint {
    return Intl.message(
      'Drag and drop files here',
      name: 'chatDragHint',
      desc: '',
      args: [],
    );
  }

  /// `Add Item`
  String get chatDragMoreFile {
    return Intl.message(
      'Add Item',
      name: 'chatDragMoreFile',
      desc: '',
      args: [],
    );
  }

  /// `send`
  String get send {
    return Intl.message(
      'send',
      name: 'send',
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

  /// `Send quickly`
  String get sendQuick {
    return Intl.message(
      'Send quickly',
      name: 'sendQuick',
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

  /// `Archived all files in one zip file`
  String get sendArchived {
    return Intl.message(
      'Archived all files in one zip file',
      name: 'sendArchived',
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

  /// `Conversations`
  String get conversations {
    return Intl.message(
      'Conversations',
      name: 'conversations',
      desc: '',
      args: [],
    );
  }

  /// `Transcript`
  String get chatTranscript {
    return Intl.message(
      'Transcript',
      name: 'chatTranscript',
      desc: '',
      args: [],
    );
  }

  /// `{user} pinned {preview}`
  String pinned(Object user, Object preview) {
    return Intl.message(
      '$user pinned $preview',
      name: 'pinned',
      desc: '',
      args: [user, preview],
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
  String get unpinAllMessagesDescription {
    return Intl.message(
      'Are you sure you want to unpin all messages?',
      name: 'unpinAllMessagesDescription',
      desc: '',
      args: [],
    );
  }

  /// `{count} Pinned Messages`
  String pinMessageCount(Object count) {
    return Intl.message(
      '$count Pinned Messages',
      name: 'pinMessageCount',
      desc: '',
      args: [count],
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

  /// `a message`
  String get aMessage {
    return Intl.message(
      'a message',
      name: 'aMessage',
      desc: '',
      args: [],
    );
  }

  /// `{count} Participants`
  String conversationParticipantsCountDescription(Object count) {
    return Intl.message(
      '$count Participants',
      name: 'conversationParticipantsCountDescription',
      desc: '',
      args: [count],
    );
  }

  /// `+ Join the group`
  String get joinGroup {
    return Intl.message(
      '+ Join the group',
      name: 'joinGroup',
      desc: '',
      args: [],
    );
  }

  /// `Search contact`
  String get searchUser {
    return Intl.message(
      'Search contact',
      name: 'searchUser',
      desc: '',
      args: [],
    );
  }

  /// `Mixin ID or Phone number`
  String get searchUserHint {
    return Intl.message(
      'Mixin ID or Phone number',
      name: 'searchUserHint',
      desc: '',
      args: [],
    );
  }

  /// `My Mixin ID: {ID}`
  String currentIdentityNumber(Object ID) {
    return Intl.message(
      'My Mixin ID: $ID',
      name: 'currentIdentityNumber',
      desc: '',
      args: [ID],
    );
  }

  /// `From: `
  String get fromWithColon {
    return Intl.message(
      'From: ',
      name: 'fromWithColon',
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

  /// `Show`
  String get show {
    return Intl.message(
      'Show',
      name: 'show',
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

  /// `Done`
  String get done {
    return Intl.message(
      'Done',
      name: 'done',
      desc: '',
      args: [],
    );
  }

  /// `Coming soon...`
  String get comingSoon {
    return Intl.message(
      'Coming soon...',
      name: 'comingSoon',
      desc: '',
      args: [],
    );
  }

  /// `Sent you a message`
  String get sentYouAMessage {
    return Intl.message(
      'Sent you a message',
      name: 'sentYouAMessage',
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

  /// `System time is unusual, please continue to use again after correction`
  String get localTimeErrorDescription {
    return Intl.message(
      'System time is unusual, please continue to use again after correction',
      name: 'localTimeErrorDescription',
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

  /// `Card`
  String get appCard {
    return Intl.message(
      'Card',
      name: 'appCard',
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

  /// `Memo`
  String get memo {
    return Intl.message(
      'Memo',
      name: 'memo',
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

  /// `Transaction Id`
  String get transactionsId {
    return Intl.message(
      'Transaction Id',
      name: 'transactionsId',
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

  /// `To`
  String get to {
    return Intl.message(
      'To',
      name: 'to',
      desc: '',
      args: [],
    );
  }

  /// `value now {value} ({unitValue}/{symbol})`
  String walletTransactionCurrentValue(
      Object value, Object unitValue, Object symbol) {
    return Intl.message(
      'value now $value ($unitValue/$symbol)',
      name: 'walletTransactionCurrentValue',
      desc: '',
      args: [value, unitValue, symbol],
    );
  }

  /// `value then {value} ({unitValue}/{symbol})`
  String walletTransactionThatTimeValue(
      Object value, Object unitValue, Object symbol) {
    return Intl.message(
      'value then $value ($unitValue/$symbol)',
      name: 'walletTransactionThatTimeValue',
      desc: '',
      args: [value, unitValue, symbol],
    );
  }

  /// `value then N/A`
  String get walletTransactionThatTimeNoValue {
    return Intl.message(
      'value then N/A',
      name: 'walletTransactionThatTimeNoValue',
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

  /// `Developer`
  String get developer {
    return Intl.message(
      'Developer',
      name: 'developer',
      desc: '',
      args: [],
    );
  }

  /// `Go to chat`
  String get goToChat {
    return Intl.message(
      'Go to chat',
      name: 'goToChat',
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

  /// `Don't miss messages from you friends.`
  String get notificationPermissionDescription {
    return Intl.message(
      'Don\'t miss messages from you friends.',
      name: 'notificationPermissionDescription',
      desc: '',
      args: [],
    );
  }

  /// `Turn On Notifications`
  String get notificationPermissionTitle {
    return Intl.message(
      'Turn On Notifications',
      name: 'notificationPermissionTitle',
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

  /// `WebView2 Runtime is not available`
  String get webViewRuntimeNotAvailable {
    return Intl.message(
      'WebView2 Runtime is not available',
      name: 'webViewRuntimeNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `The device has not installed the WebView2 Runtime component. Please download and install WebView2 Runtime first.`
  String get webView2RuntimeInstallDescription {
    return Intl.message(
      'The device has not installed the WebView2 Runtime component. Please download and install WebView2 Runtime first.',
      name: 'webView2RuntimeInstallDescription',
      desc: '',
      args: [],
    );
  }

  /// `Download Link: `
  String get downloadLink {
    return Intl.message(
      'Download Link: ',
      name: 'downloadLink',
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

  /// `Delete chat: {value}`
  String deleteChatHint(Object value) {
    return Intl.message(
      'Delete chat: $value',
      name: 'deleteChatHint',
      desc: '',
      args: [value],
    );
  }

  /// `This type of url is not supported, please check on your phone.`
  String get uriCheckOnPhone {
    return Intl.message(
      'This type of url is not supported, please check on your phone.',
      name: 'uriCheckOnPhone',
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

  /// `No results`
  String get noResults {
    return Intl.message(
      'No results',
      name: 'noResults',
      desc: '',
      args: [],
    );
  }

  /// `Save to Gallery`
  String get saveToGallery {
    return Intl.message(
      'Save to Gallery',
      name: 'saveToGallery',
      desc: '',
      args: [],
    );
  }

  /// `Type message`
  String get typeAMessage {
    return Intl.message(
      'Type message',
      name: 'typeAMessage',
      desc: '',
      args: [],
    );
  }

  /// `Sticker shop`
  String get stickerShop {
    return Intl.message(
      'Sticker shop',
      name: 'stickerShop',
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

  /// `Added`
  String get added {
    return Intl.message(
      'Added',
      name: 'added',
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

  /// `Add Stickers`
  String get addStickers {
    return Intl.message(
      'Add Stickers',
      name: 'addStickers',
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

  /// `My Stickers`
  String get myStickerAlbums {
    return Intl.message(
      'My Stickers',
      name: 'myStickerAlbums',
      desc: '',
      args: [],
    );
  }

  /// `Add sticker`
  String get addSticker {
    return Intl.message(
      'Add sticker',
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

  /// `Original`
  String get originalImage {
    return Intl.message(
      'Original',
      name: 'originalImage',
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

  /// `Reset`
  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      desc: '',
      args: [],
    );
  }

  /// `Groups in common`
  String get groupsInCommon {
    return Intl.message(
      'Groups in common',
      name: 'groupsInCommon',
      desc: '',
      args: [],
    );
  }

  /// `Failed to open file {name}`
  String failedToOpenFile(Object name) {
    return Intl.message(
      'Failed to open file $name',
      name: 'failedToOpenFile',
      desc: '',
      args: [name],
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

  /// `Message content is too long`
  String get messageTooLong {
    return Intl.message(
      'Message content is too long',
      name: 'messageTooLong',
      desc: '',
      args: [],
    );
  }

  /// `Check for updates`
  String get checkUpdate {
    return Intl.message(
      'Check for updates',
      name: 'checkUpdate',
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

  /// `Ignore this update`
  String get ignoreThisUpdate {
    return Intl.message(
      'Ignore this update',
      name: 'ignoreThisUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Mixin Messenger {newVersion} is now available, you have {current}. Would you like to download it now?`
  String newVersionDescription(Object newVersion, Object current) {
    return Intl.message(
      'Mixin Messenger $newVersion is now available, you have $current. Would you like to download it now?',
      name: 'newVersionDescription',
      desc: '',
      args: [newVersion, current],
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

  /// `Avatar`
  String get avatar {
    return Intl.message(
      'Avatar',
      name: 'avatar',
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

  /// `Login with mobile number`
  String get loginWithMobile {
    return Intl.message(
      'Login with mobile number',
      name: 'loginWithMobile',
      desc: '',
      args: [],
    );
  }

  /// `Login with QR code`
  String get loginWithQRCode {
    return Intl.message(
      'Login with QR code',
      name: 'loginWithQRCode',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `Can not recognize the QR code`
  String get canNotRecognize {
    return Intl.message(
      'Can not recognize the QR code',
      name: 'canNotRecognize',
      desc: '',
      args: [],
    );
  }

  /// `No connection`
  String get errorNoConnection {
    return Intl.message(
      'No connection',
      name: 'errorNoConnection',
      desc: '',
      args: [],
    );
  }

  /// `Connection timeout`
  String get errorConnectionTimeout {
    return Intl.message(
      'Connection timeout',
      name: 'errorConnectionTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Network error`
  String get errorNetworkError {
    return Intl.message(
      'Network error',
      name: 'errorNetworkError',
      desc: '',
      args: [],
    );
  }

  /// `Server is under maintenance: {code}`
  String errorServer5xx(Object code) {
    return Intl.message(
      'Server is under maintenance: $code',
      name: 'errorServer5xx',
      desc: '',
      args: [code],
    );
  }

  /// `Data error`
  String get errorData {
    return Intl.message(
      'Data error',
      name: 'errorData',
      desc: '',
      args: [],
    );
  }

  /// `ERROR: {code}`
  String errorUnknownWithCode(Object code) {
    return Intl.message(
      'ERROR: $code',
      name: 'errorUnknownWithCode',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR: {message}`
  String errorUnknownWithMessage(Object message) {
    return Intl.message(
      'ERROR: $message',
      name: 'errorUnknownWithMessage',
      desc: '',
      args: [message],
    );
  }

  /// `Forbidden`
  String get errorForbidden {
    return Intl.message(
      'Forbidden',
      name: 'errorForbidden',
      desc: '',
      args: [],
    );
  }

  /// `ERROR {code}: Not found`
  String errorNotFound(Object code) {
    return Intl.message(
      'ERROR $code: Not found',
      name: 'errorNotFound',
      desc: '',
      args: [code],
    );
  }

  /// `Not found`
  String get errorNotFoundMessage {
    return Intl.message(
      'Not found',
      name: 'errorNotFoundMessage',
      desc: '',
      args: [],
    );
  }

  /// `ERROR {code}: Rate limit exceeded`
  String errorTooManyRequests(Object code) {
    return Intl.message(
      'ERROR $code: Rate limit exceeded',
      name: 'errorTooManyRequests',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Sign in to continue`
  String errorAuthentication(Object code) {
    return Intl.message(
      'ERROR $code: Sign in to continue',
      name: 'errorAuthentication',
      desc: '',
      args: [code],
    );
  }

  /// `No camera`
  String get errorNoCamera {
    return Intl.message(
      'No camera',
      name: 'errorNoCamera',
      desc: '',
      args: [],
    );
  }

  /// `File error`
  String get errorImage {
    return Intl.message(
      'File error',
      name: 'errorImage',
      desc: '',
      args: [],
    );
  }

  /// `Format not supported`
  String get errorFormat {
    return Intl.message(
      'Format not supported',
      name: 'errorFormat',
      desc: '',
      args: [],
    );
  }

  /// `ERROR {code}: The group chat is full.`
  String errorFullGroup(Object code) {
    return Intl.message(
      'ERROR $code: The group chat is full.',
      name: 'errorFullGroup',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Insufficient balance`
  String errorInsufficientBalance(Object code) {
    return Intl.message(
      'ERROR $code: Insufficient balance',
      name: 'errorInsufficientBalance',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Invalid PIN format`
  String errorInvalidPinFormat(Object code) {
    return Intl.message(
      'ERROR $code: Invalid PIN format',
      name: 'errorInvalidPinFormat',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: PIN incorrect`
  String errorPinIncorrect(Object code) {
    return Intl.message(
      'ERROR $code: PIN incorrect',
      name: 'errorPinIncorrect',
      desc: '',
      args: [code],
    );
  }

  /// `{code}: PIN incorrect. You still have {times} chances. Please wait for 24 hours to retry later.`
  String errorPinIncorrectWithTimes(Object code, Object times) {
    return Intl.message(
      '$code: PIN incorrect. You still have $times chances. Please wait for 24 hours to retry later.',
      name: 'errorPinIncorrectWithTimes',
      desc: '',
      args: [code, times],
    );
  }

  /// `ERROR {code}: The amount is too small`
  String errorTooSmall(Object code) {
    return Intl.message(
      'ERROR $code: The amount is too small',
      name: 'errorTooSmall',
      desc: '',
      args: [code],
    );
  }

  /// `User not found`
  String get errorUserNotFound {
    return Intl.message(
      'User not found',
      name: 'errorUserNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Conversation not found`
  String get errorConversationNotFound {
    return Intl.message(
      'Conversation not found',
      name: 'errorConversationNotFound',
      desc: '',
      args: [],
    );
  }

  /// `App not found`
  String get errorAppNotFound {
    return Intl.message(
      'App not found',
      name: 'errorAppNotFound',
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

  /// `Can't find an map app`
  String get errorOpenLocation {
    return Intl.message(
      'Can\'t find an map app',
      name: 'errorOpenLocation',
      desc: '',
      args: [],
    );
  }

  /// `File does not exist`
  String get errorFileExists {
    return Intl.message(
      'File does not exist',
      name: 'errorFileExists',
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

  /// `You have tried more than 5 times, please wait at least 24 hours to try again.`
  String get errorPinCheckTooManyRequest {
    return Intl.message(
      'You have tried more than 5 times, please wait at least 24 hours to try again.',
      name: 'errorPinCheckTooManyRequest',
      desc: '',
      args: [],
    );
  }

  /// `ERROR {code}: Phone is used by someone else.`
  String errorUsedPhone(Object code) {
    return Intl.message(
      'ERROR $code: Phone is used by someone else.',
      name: 'errorUsedPhone',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Insufficient transaction fee. Please make sure your wallet has {fee} as fee`
  String errorInsufficientTransactionFeeWithAmount(Object code, Object fee) {
    return Intl.message(
      'ERROR $code: Insufficient transaction fee. Please make sure your wallet has $fee as fee',
      name: 'errorInsufficientTransactionFeeWithAmount',
      desc: '',
      args: [code, fee],
    );
  }

  /// `ERROR {code}: Blockchain not in sync, please try again later.`
  String errorBlockchain(Object code) {
    return Intl.message(
      'ERROR $code: Blockchain not in sync, please try again later.',
      name: 'errorBlockchain',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Invalid address format.`
  String errorInvalidAddressPlain(Object code) {
    return Intl.message(
      'ERROR $code: Invalid address format.',
      name: 'errorInvalidAddressPlain',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Invalid address format. Please enter the correct {type} {address} address!`
  String errorInvalidAddress(Object code, Object type, Object address) {
    return Intl.message(
      'ERROR $code: Invalid address format. Please enter the correct $type $address address!',
      name: 'errorInvalidAddress',
      desc: '',
      args: [code, type, address],
    );
  }

  /// `ERROR {code}: Expired phone verification code`
  String errorPhoneVerificationCodeExpired(Object code) {
    return Intl.message(
      'ERROR $code: Expired phone verification code',
      name: 'errorPhoneVerificationCodeExpired',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Invalid phone verification code`
  String errorPhoneVerificationCodeInvalid(Object code) {
    return Intl.message(
      'ERROR $code: Invalid phone verification code',
      name: 'errorPhoneVerificationCodeInvalid',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Invalid phone number`
  String errorPhoneInvalidFormat(Object code) {
    return Intl.message(
      'ERROR $code: Invalid phone number',
      name: 'errorPhoneInvalidFormat',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Failed to deliver SMS`
  String errorPhoneSmsDelivery(Object code) {
    return Intl.message(
      'ERROR $code: Failed to deliver SMS',
      name: 'errorPhoneSmsDelivery',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: The request data has invalid field`
  String errorBadData(Object code) {
    return Intl.message(
      'ERROR $code: The request data has invalid field',
      name: 'errorBadData',
      desc: '',
      args: [code],
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

  /// `Invalid user id`
  String get errorUserInvalidFormat {
    return Intl.message(
      'Invalid user id',
      name: 'errorUserInvalidFormat',
      desc: '',
      args: [],
    );
  }

  /// `Share error.`
  String get errorShare {
    return Intl.message(
      'Share error.',
      name: 'errorShare',
      desc: '',
      args: [],
    );
  }

  /// `ERROR {code}: Recaptcha is invalid`
  String errorRecaptchaIsInvalid(Object code) {
    return Intl.message(
      'ERROR $code: Recaptcha is invalid',
      name: 'errorRecaptchaIsInvalid',
      desc: '',
      args: [code],
    );
  }

  /// `Recaptcha timeout`
  String get errorRecaptchaTimeout {
    return Intl.message(
      'Recaptcha timeout',
      name: 'errorRecaptchaTimeout',
      desc: '',
      args: [],
    );
  }

  /// `ERROR {code}: Please update Mixin({version}) to continue use the service.`
  String errorOldVersion(Object code, Object version) {
    return Intl.message(
      'ERROR $code: Please update Mixin($version) to continue use the service.',
      name: 'errorOldVersion',
      desc: '',
      args: [code, version],
    );
  }

  /// `File chooser error`
  String get errorFileChooser {
    return Intl.message(
      'File chooser error',
      name: 'errorFileChooser',
      desc: '',
      args: [],
    );
  }

  /// `Duration is too short`
  String get errorDurationShort {
    return Intl.message(
      'Duration is too short',
      name: 'errorDurationShort',
      desc: '',
      args: [],
    );
  }

  /// `ERROR {code}: Too many stickers`
  String errorTooManyStickers(Object code) {
    return Intl.message(
      'ERROR $code: Too many stickers',
      name: 'errorTooManyStickers',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Withdraw amount too small`
  String errorTooSmallWithdrawAmount(Object code) {
    return Intl.message(
      'ERROR $code: Withdraw amount too small',
      name: 'errorTooSmallWithdrawAmount',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Send verification code too frequent, please try again later.`
  String errorInvalidCodeTooFrequent(Object code) {
    return Intl.message(
      'ERROR $code: Send verification code too frequent, please try again later.',
      name: 'errorInvalidCodeTooFrequent',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Invalid emergency contact`
  String errorInvalidEmergencyContact(Object code) {
    return Intl.message(
      'ERROR $code: Invalid emergency contact',
      name: 'errorInvalidEmergencyContact',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: Withdrawal memo format incorrect.`
  String errorWithdrawalMemoFormatIncorrect(Object code) {
    return Intl.message(
      'ERROR $code: Withdrawal memo format incorrect.',
      name: 'errorWithdrawalMemoFormatIncorrect',
      desc: '',
      args: [code],
    );
  }

  /// `ERROR {code}: The number has reached the limit.`
  String errorFavoriteLimit(Object code) {
    return Intl.message(
      'ERROR $code: The number has reached the limit.',
      name: 'errorFavoriteLimit',
      desc: '',
      args: [code],
    );
  }

  /// `Retry upload failed.`
  String get errorRetryUpload {
    return Intl.message(
      'Retry upload failed.',
      name: 'errorRetryUpload',
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

  /// `Please forward all attachments after they have been downloaded`
  String get errorTranscriptForward {
    return Intl.message(
      'Please forward all attachments after they have been downloaded',
      name: 'errorTranscriptForward',
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

  /// `Enter the 4-digit code sent to you at {phone}`
  String enterVerificationCode(Object phone) {
    return Intl.message(
      'Enter the 4-digit code sent to you at $phone',
      name: 'enterVerificationCode',
      desc: '',
      args: [phone],
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

  /// `Resend code in {time}s`
  String resendCodeIn(Object time) {
    return Intl.message(
      'Resend code in ${time}s',
      name: 'resendCodeIn',
      desc: '',
      args: [time],
    );
  }

  /// `We will send a 4-digit code to your phone number {phone}, please enter the code in next screen.`
  String sendCodeConfirm(Object phone) {
    return Intl.message(
      'We will send a 4-digit code to your phone number $phone, please enter the code in next screen.',
      name: 'sendCodeConfirm',
      desc: '',
      args: [phone],
    );
  }

  /// `What's your name?`
  String get enterNameTitle {
    return Intl.message(
      'What\'s your name?',
      name: 'enterNameTitle',
      desc: '',
      args: [],
    );
  }

  /// `Continue to log in and abort account deletion`
  String get landingDeletionWarningTitle {
    return Intl.message(
      'Continue to log in and abort account deletion',
      name: 'landingDeletionWarningTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your account will be deleted on {date}, if you continue to log in, the request to delete your account will be cancelled.`
  String landingDeletionWarningContent(Object date) {
    return Intl.message(
      'Your account will be deleted on $date, if you continue to log in, the request to delete your account will be cancelled.',
      name: 'landingDeletionWarningContent',
      desc: '',
      args: [date],
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

  /// `Share`
  String get share {
    return Intl.message(
      'Share',
      name: 'share',
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

  /// `Preferences`
  String get preferences {
    return Intl.message(
      'Preferences',
      name: 'preferences',
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

  /// `Show Mixin`
  String get showMixin {
    return Intl.message(
      'Show Mixin',
      name: 'showMixin',
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

  /// `Quick search`
  String get quickSearch {
    return Intl.message(
      'Quick search',
      name: 'quickSearch',
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

  /// `Window`
  String get window {
    return Intl.message(
      'Window',
      name: 'window',
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

  /// `Previous conversation`
  String get previousConversation {
    return Intl.message(
      'Previous conversation',
      name: 'previousConversation',
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

  /// `Toggle chat info`
  String get toggleChatInfo {
    return Intl.message(
      'Toggle chat info',
      name: 'toggleChatInfo',
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
