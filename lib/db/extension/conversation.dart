import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../dao/conversation_dao.dart';

extension SearchConversationItemExtension on SearchConversationItem {
  bool get isGroupConversation => category == ConversationCategory.group;

  bool get isMute => muteUntil?.isAfter(DateTime.now()) == true;
}

extension ConversationItemExtension on ConversationItem {
  bool get isContactConversation =>
      category == ConversationCategory.contact &&
      relationship == UserRelationship.friend &&
      appId == null;

  bool get isGroupConversation => category == ConversationCategory.group;

  bool get isBotConversation =>
      category == ConversationCategory.contact && appId != null;

  bool get isStrangerConversation =>
      category == ConversationCategory.contact &&
      relationship == UserRelationship.stranger &&
      appId == null;

  bool get isMute => muteUntil?.isAfter(DateTime.now()) == true;

  Duration get expireDuration {
    final expireIn = this.expireIn ?? 0;
    return expireIn == 0 ? Duration.zero : Duration(seconds: expireIn);
  }
}
