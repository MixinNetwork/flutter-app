import 'package:flutter_app/db/mixin_database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

extension Conversation on ConversationItem {
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

  String get validName =>
      groupName?.trim().isNotEmpty == true ? groupName! : name ?? '';
}

void importConversationExtension() {}
