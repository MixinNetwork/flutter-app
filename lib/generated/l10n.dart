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

  /// `Open Mixin Messenger on your phone, scan the qr code on the screen and confirm your login.`
  String get pageLandingLoginMessage {
    return Intl.message(
      'Open Mixin Messenger on your phone, scan the qr code on the screen and confirm your login.',
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

  /// `Edit Conversations`
  String get editConversations {
    return Intl.message(
      'Edit Conversations',
      name: 'editConversations',
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

  /// `New Group Conversation`
  String get createGroupConversation {
    return Intl.message(
      'New Group Conversation',
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

  /// `New circle`
  String get createCircle {
    return Intl.message(
      'New circle',
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

  /// `People`
  String get people {
    return Intl.message(
      'People',
      name: 'people',
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
