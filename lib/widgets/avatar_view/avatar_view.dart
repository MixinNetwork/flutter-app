import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/db/extension/conversation.dart';
import 'package:flutter_app/utils/color_utils.dart';
import 'package:flutter_app/widgets/avatar_view/bloc/cubit/avatar_cubit.dart';
import 'package:flutter_app/widgets/cache_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:provider/provider.dart';

class ConversationAvatarWidget extends StatelessWidget {
  const ConversationAvatarWidget({
    Key? key,
    this.conversation,
    required this.size,
    this.conversationId,
    this.fullName,
    this.groupIconUrl,
    this.avatarUrl,
    this.category,
  }) : super(key: key);

  final ConversationItem? conversation;
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

    return SizedBox.fromSize(
      size: Size.square(size),
      child: ClipOval(
        child: Builder(
          builder: (context) {
            return BlocProvider(
              key: Key(_conversationId!),
              create: (context) => AvatarCubit(
                Provider.of<AccountServer>(context, listen: false)
                    .database
                    .participantsDao,
                _conversationId,
              ),
              child: Builder(
                builder: (context) {
                  if (!(_category == ConversationCategory.group)) {
                    return AvatarWidget(
                      userId: _conversationId,
                      name: _name ?? '',
                      avatarUrl: _groupIconUrl ?? _avatarUrl ?? '',
                      size: size,
                    );
                  }
                  return BlocConverter<AvatarCubit, List<User>, List<User>>(
                    converter: (state) =>
                        _category == ConversationCategory.contact
                            ? state
                                .where((element) =>
                                    element.relationship != UserRelationship.me)
                                .toList()
                            : state,
                    builder: (context, state) =>
                        AvatarPuzzlesWidget(state, size),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class AvatarPuzzlesWidget extends StatelessWidget {
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
          name: user.fullName!,
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
  final String userId;
  final String name;
  final double size;
  final bool clipOval;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (avatarUrl?.isNotEmpty == true)
      child = CacheImage(
        avatarUrl!,
        width: size,
        height: size,
      );
    else
      child = SizedBox.fromSize(
        size: Size.square(size),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: getAvatarColorById(userId),
          ),
          child: Center(
            child: Text(
              name[0],
              style: TextStyle(
                color: getNameColorById(userId),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

    if (clipOval) return ClipOval(child: child);
    return child;
  }
}
