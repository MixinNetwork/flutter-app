import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

import '../../db/dao/conversation_dao.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../utils/color_utils.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../media_image_pipeline.dart';
import '../mixin_image.dart';

class ConversationAvatarWidget extends HookConsumerWidget {
  const ConversationAvatarWidget({
    required this.size,
    super.key,
    this.conversation,
    this.conversationId,
    this.userId,
    this.fullName,
    this.groupIconUrl,
    this.avatarUrl,
    this.category,
    this.groupAvatarUsers,
  });

  final ConversationItem? conversation;
  final String? userId;
  final String? conversationId;
  final String? fullName;
  final String? groupIconUrl;
  final String? avatarUrl;
  final ConversationCategory? category;
  final List<User>? groupAvatarUsers;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _conversationId = conversation?.conversationId ?? conversationId;
    assert(_conversationId != null);
    final _name = conversation?.name ?? fullName;
    final _groupIconUrl = conversation?.groupIconUrl ?? groupIconUrl;
    final _avatarUrl = conversation?.avatarUrl ?? avatarUrl;
    final _category = conversation?.category ?? category;
    assert(_category != null);

    final _userId = conversation?.ownerId ?? userId;
    // A group photo that an owner or admin uploaded replaces the member puzzle.
    final hasGroupPhoto =
        _category == ConversationCategory.group &&
        (_groupIconUrl?.startsWith('https://') == true ||
            _groupIconUrl?.startsWith('http://') == true);

    final list =
        useMemoizedStream(
          () {
            if (groupAvatarUsers == null &&
                _category == ConversationCategory.group) {
              return context.database.participantDao
                  .participantsAvatar(_conversationId!)
                  .watchWithStream(
                    eventStreams: [
                      DataBaseEventBus.instance.watchUpdateParticipantStream(
                        conversationIds: [_conversationId],
                      ),
                    ],
                    duration: kVerySlowThrottleDuration * 2,
                  );
            }
            return const Stream<List<User>>.empty();
          },
          keys: [_conversationId, _category, groupAvatarUsers != null],
          initialData: <User>[],
        ).data ??
        <User>[];
    final users = groupAvatarUsers ?? list;

    return SizedBox.fromSize(
      size: Size.square(size),
      child: ClipOval(
        child: _category == ConversationCategory.contact
            ? AvatarWidget(
                userId: _userId,
                name: _name,
                avatarUrl: _avatarUrl ?? _groupIconUrl ?? '',
                size: size,
              )
            : hasGroupPhoto
            ? _GroupPhoto(
                key: ValueKey(_conversationId),
                url: _groupIconUrl!,
                users: users,
                size: size,
              )
            : AvatarPuzzlesWidget(users, size),
      ),
    );
  }
}

class _GroupPhoto extends HookWidget {
  const _GroupPhoto({
    required this.url,
    required this.users,
    required this.size,
    super.key,
  });

  final String url;
  final List<User> users;
  final double size;

  @override
  Widget build(BuildContext context) {
    // A new photo of the same group loads first, then fades in over the old
    // one. Thus the letter or the member puzzle does not show between them.
    final shownUrl = useState(url);
    useEffect(() {
      if (url == shownUrl.value) return null;
      var active = true;
      final image = resolveMediaImageProvider(
        NetworkImage(url),
        context.database.settingProperties.activatedProxy,
      );
      precacheImage(image, context, onError: (_, _) {}).whenComplete(() {
        if (active) shownUrl.value = url;
      });
      return () => active = false;
    }, [url]);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: MixinImage.network(
        shownUrl.value,
        key: ValueKey(shownUrl.value),
        width: size,
        height: size,
        placeholder: () => AvatarPuzzlesWidget(users, size),
        errorBuilder: (_, _, _) => AvatarPuzzlesWidget(users, size),
      ),
    );
  }
}

class AvatarPuzzlesWidget extends HookConsumerWidget {
  const AvatarPuzzlesWidget(this.users, this.size, {super.key});

  final List<User> users;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        return Row(children: users.map(_buildAvatarImage).toList());
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
              ),
            ),
            Expanded(
              child: Column(
                children: users.sublist(1).map(_buildAvatarImage).toList(),
              ),
            ),
          ],
        );
      default:
        return Row(
          children: [users.sublist(0, 2), users.sublist(2)]
              .map(
                (e) => Expanded(
                  child: Column(
                    children: e.map(_buildAvatarImage).toList(),
                  ),
                ),
              )
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
    required this.size,
    required this.avatarUrl,
    required this.userId,
    required this.name,
    super.key,
    this.clipOval = true,
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
        ? MixinImage.network(
            avatarUrl!,
            width: size,
            height: size,
            placeholder: () => placeholder,
            errorBuilder: (_, _, _) => placeholder,
          )
        : placeholder;

    if (clipOval) return ClipOval(child: child);
    return child;
  }
}
