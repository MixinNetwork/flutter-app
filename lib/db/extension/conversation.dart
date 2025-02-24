import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../dao/conversation_dao.dart';
import 'user.dart';

extension SearchConversationItemExtension on SearchConversationItem {
  bool get isGroupConversation => category == ConversationCategory.group;

  bool get isMute =>
      (isGroupConversation && muteUntil?.isAfter(DateTime.now()) == true) ||
      (!isGroupConversation && ownerMuteUntil?.isAfter(DateTime.now()) == true);

  String get validName => conversationValidName(groupName, fullName);
}

extension ConversationItemExtension on ConversationItem {
  bool get isContactConversation =>
      category == ConversationCategory.contact &&
      relationship == UserRelationship.friend &&
      appId == null;

  bool get isGroupConversation => category == ConversationCategory.group;

  bool get isBotConversation =>
      category == ConversationCategory.contact &&
      UserExtension.isBotIdentityNumber(ownerIdentityNumber);

  bool get isStrangerConversation =>
      category == ConversationCategory.contact &&
      relationship == UserRelationship.stranger &&
      appId == null;

  String get validName => conversationValidName(groupName, name);

  bool get isMute =>
      (isGroupConversation && muteUntil?.isAfter(DateTime.now()) == true) ||
      (!isGroupConversation && ownerMuteUntil?.isAfter(DateTime.now()) == true);

  DateTime? get validMuteUntil =>
      isGroupConversation ? muteUntil : ownerMuteUntil;

  Duration get expireDuration {
    final expireIn = this.expireIn ?? 0;
    return expireIn == 0 ? Duration.zero : Duration(seconds: expireIn);
  }
}

String conversationValidName(String? groupName, String? fullName) =>
    groupName?.trim().isNotEmpty == true ? groupName! : fullName ?? '';
