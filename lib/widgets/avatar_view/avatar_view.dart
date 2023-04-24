import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../utils/color_utils.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../cache_image.dart';

class ConversationAvatarWidget extends HookWidget {
  const ConversationAvatarWidget({
    super.key,
    this.conversation,
    required this.size,
    this.conversationId,
    this.userId,
    this.fullName,
    this.groupIconUrl,
    this.avatarUrl,
    this.category,
  });

  final ConversationItem? conversation;
  final String? userId;
  final String? conversationId;
  final String? fullName;
  final String? groupIconUrl;
  final String? avatarUrl;
  final ConversationCategory? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final _conversationId = conversation?.conversationId ?? conversationId;
    assert(_conversationId != null);
    final _name = conversation?.name ?? fullName;
    final _groupIconUrl = conversation?.groupIconUrl ?? groupIconUrl;
    final _avatarUrl = conversation?.avatarUrl ?? avatarUrl;
    final _category = conversation?.category ?? category;
    assert(_category != null);

    final _userId = conversation?.ownerId ?? userId;

    final list = useMemoizedStream(
          () {
            if (_category == ConversationCategory.group) {
              return context.database.participantDao
                  .participantsAvatar(_conversationId!)
                  .watchWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateParticipantStream(
                      conversationIds: [_conversationId])
                ],
                duration: kVerySlowThrottleDuration * 2,
              ).map((event) => _category == ConversationCategory.contact
                      ? event
                          .where((element) =>
                              element.relationship != UserRelationship.me)
                          .toList()
                      : event);
            }
            return const Stream<List<User>>.empty();
          },
          keys: [_conversationId, _category],
          initialData: <User>[],
        ).data ??
        <User>[];

    final child = _category == ConversationCategory.contact
        ? AvatarWidget(
            userId: _userId,
            name: _name,
            avatarUrl: _groupIconUrl ?? _avatarUrl ?? '',
            size: size)
        : AvatarPuzzlesWidget(list, size);

    return SizedBox.fromSize(
      size: Size.square(size),
      child: ClipOval(
        child: child,
      ),
    );
  }
}

class AvatarPuzzlesWidget extends HookWidget {
  const AvatarPuzzlesWidget(this.users, this.size, {super.key});

  final List<User> users;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return SizedBox.fromSize(size: Size.square(size));
    switch (users.length) {
      case 1:
        return AvatarWidget(
          size: size,
          clipOval: false,
          userId: users.single.userId,
          name: users.single.fullName,
          avatarUrl: users.single.avatarUrl,
        );
      case 2:
        return Row(
          children: users.map(_buildAvatarImage).toList(),
        );
      case 3:
        return Row(
          children: [
            Expanded(
                child: AvatarWidget(
              userId: users.first.userId,
              name: users.first.fullName,
              avatarUrl: users.first.avatarUrl,
              size: size,
              clipOval: false,
            )),
            Expanded(
              child: Column(
                children: users.sublist(1).map(_buildAvatarImage).toList(),
              ),
            ),
          ],
        );
      default:
        return Row(
          children: [
            users.sublist(0, 2),
            users.sublist(2),
          ]
              .map((e) => Expanded(
                    child: Column(
                      children: e.map(_buildAvatarImage).toList(),
                    ),
                  ))
              .toList(),
        );
    }
  }

  Widget _buildAvatarImage(User user) => Expanded(
        child: AvatarWidget(
          userId: user.userId,
          name: user.fullName,
          avatarUrl: user.avatarUrl,
          size: size,
          clipOval: false,
        ),
      );
}

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.size,
    this.clipOval = true,
    required this.avatarUrl,
    required this.userId,
    required this.name,
  });

  final String? avatarUrl;
  final String? userId;
  final String? name;
  final double size;
  final bool clipOval;

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox.fromSize(
      size: Size.square(size),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: userId != null
              ? getAvatarColorById(userId!)
              : context.theme.listSelected,
        ),
        child: Center(
          child: Text(
            (name?.isNotEmpty == true)
                ? name!.characters.first.toUpperCase()
                : '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    final child = avatarUrl?.isNotEmpty == true
        ? CacheImage(
            avatarUrl!,
            width: size,
            height: size,
            placeholder: () => placeholder,
            errorWidget: () => placeholder,
          )
        : placeholder;

    if (clipOval) return ClipOval(child: child);
    return child;
  }
}
