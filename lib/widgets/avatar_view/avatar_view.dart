import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

import '../../db/mixin_database.dart';
import '../../utils/color_utils.dart';
import '../../utils/extension/extension.dart';
import '../cache_image.dart';

class ConversationAvatarWidget extends HookWidget {
  const ConversationAvatarWidget({
    Key? key,
    this.conversation,
    required this.size,
    this.conversationId,
    this.userId,
    this.fullName,
    this.groupIconUrl,
    this.avatarUrl,
    this.category,
  }) : super(key: key);

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

    final list = useStream(
          useMemoized(
            () {
              if (_category == ConversationCategory.group) {
                return context.database.participantDao
                    .participantsAvatar(_conversationId!)
                    .watchThrottle(const Duration(minutes: 6))
                    .map((event) => _category == ConversationCategory.contact
                        ? event
                            .where((element) =>
                                element.relationship != UserRelationship.me)
                            .toList()
                        : event);
              }
              return const Stream<List<User>>.empty();
            },
            [_conversationId, _category],
          ),
          initialData: <User>[],
        ).data ??
        <User>[];

    Widget child;
    if (_category == ConversationCategory.contact) {
      child = AvatarWidget(
        userId: _userId,
        name: _name ?? '',
        avatarUrl: _groupIconUrl ?? _avatarUrl ?? '',
        size: size,
      );
    } else {
      child = AvatarPuzzlesWidget(list, size);
    }

    return SizedBox.fromSize(
      size: Size.square(size),
      child: ClipOval(
        child: child,
      ),
    );
  }
}

class AvatarPuzzlesWidget extends HookWidget {
  const AvatarPuzzlesWidget(this.users, this.size, {Key? key})
      : super(key: key);

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
          name: users.single.fullName!,
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
              userId: users[0].userId,
              name: users[0].fullName!,
              avatarUrl: users[0].avatarUrl,
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
          name: user.fullName ?? '?',
          avatarUrl: user.avatarUrl,
          size: size,
          clipOval: false,
        ),
      );
}

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    Key? key,
    required this.size,
    this.clipOval = true,
    required this.avatarUrl,
    required this.userId,
    required this.name,
  }) : super(key: key);

  final String? avatarUrl;
  final String? userId;
  final String name;
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
            name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    Widget child;
    if (avatarUrl?.isNotEmpty == true) {
      child = CacheImage(
        avatarUrl!,
        width: size,
        height: size,
        placeholder: (_, __) => placeholder,
      );
    } else {
      child = placeholder;
    }

    if (clipOval) return ClipOval(child: child);
    return child;
  }
}
