import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../ui/home/chat/chat_page.dart';
import '../../ui/home/conversation_page.dart';
import '../../utils/extension/extension.dart';
import '../action_button.dart';
import '../avatar_view/avatar_view.dart';
import '../buttons.dart';
import '../dialog.dart';
import '../more_extended_text.dart';
import '../toast.dart';
import '../user_selector/conversation_selector.dart';

Future<void> showUserDialog(BuildContext context, String? userId,
    [String? identityNumber]) async {
  var _userId = userId;
  assert(_userId != null || identityNumber != null);

  final existed =
      await context.database.userDao.hasUser(_userId ?? identityNumber!);
  if (existed) {
    Toast.dismiss();
    _userId ??= (await context.database.userDao
            .findMultiUserIdsByIdentityNumbers([identityNumber!]))
        .first;
    await showMixinDialog(context: context, child: UserDialog(userId: _userId));
    return;
  }

  showToastLoading(context);

  User? user;
  if (_userId != null) {
    user = (await context.accountServer.refreshUsers([_userId], force: true))
        ?.firstOrNull;
  }

  if (identityNumber != null) {
    user =
        (await context.accountServer.updateUserByIdentityNumber(identityNumber))
            ?.firstOrNull;
  }

  if (user == null) {
    await showToastFailed(
      context,
      ToastError(
        context.l10n.userNotFound,
      ),
    );
    return;
  }

  _userId ??= (await context.database.userDao
          .findMultiUserIdsByIdentityNumbers([identityNumber!]))
      .first;

  Toast.dismiss();
  await showMixinDialog(
    context: context,
    child: UserDialog(
      userId: _userId,
      refreshUser: false,
    ),
  );
}

class UserDialog extends StatelessWidget {
  const UserDialog({
    Key? key,
    required this.userId,
    this.refreshUser = true,
  }) : super(key: key);

  final String userId;
  final bool refreshUser;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: 12, top: 12),
                      child: MixinCloseButton(),
                    ),
                  ],
                ),
                _UserProfileLoader(userId, refreshUser: refreshUser),
              ],
            ),
          ),
        ],
      );
}

class _UserProfileLoader extends HookWidget {
  const _UserProfileLoader(
    this.userId, {
    Key? key,
    this.refreshUser = true,
  }) : super(key: key);

  final String userId;
  final bool refreshUser;

  @override
  Widget build(BuildContext context) {
    final accountServer = context.accountServer;
    final user = useStream(useMemoized(
        () => accountServer.database.userDao
            .userById(userId)
            .watchSingleOrNullThrottle(),
        [userId])).data;

    useEffect(() {
      if (refreshUser) {
        accountServer.refreshUsers([userId], force: true);
      }
    }, [userId, refreshUser]);

    if (user == null) return const SizedBox();
    return _UserProfileBody(
      user: user,
      isSelf: accountServer.userId == user.userId,
    );
  }
}

class _UserProfileBody extends StatelessWidget {
  const _UserProfileBody({
    Key? key,
    required this.user,
    required this.isSelf,
  }) : super(key: key);
  final User user;
  final bool isSelf;

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 150),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarWidget(
              size: 90,
              avatarUrl: user.avatarUrl,
              userId: user.userId,
              name: user.fullName ?? '',
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SelectableText(
                    user.fullName ?? '',
                    style: TextStyle(
                      color: context.theme.text,
                      fontSize: 16,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                VerifiedOrBotWidget(
                  verified: user.isVerified,
                  isBot: user.appId != null,
                )
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(
              context.l10n.contactMixinId(user.identityNumber),
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 12,
              ),
            ),
            if (user.isStranger)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _AddToContactsButton(user: user),
              ),
            const SizedBox(height: 20),
            _BioText(biography: user.biography ?? ''),
            const SizedBox(height: 24),
            _UserProfileButtonBar(user: user),
            const SizedBox(height: 56),
          ],
        ),
      );
}

class _BioText extends StatelessWidget {
  const _BioText({
    Key? key,
    required this.biography,
  }) : super(key: key);

  final String biography;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 74,
          minWidth: 160,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: MoreExtendedText(
              biography,
              style: TextStyle(
                color: context.theme.text,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
}

class _AddToContactsButton extends StatelessWidget {
  const _AddToContactsButton({
    Key? key,
    required this.user,
  }) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) => DialogAddOrJoinButton(
        onTap: () {
          assert(user.fullName != null, ' username should not be null.');
          runFutureWithToast(
            context,
            context.accountServer.addUser(
              user.userId,
              user.fullName,
            ),
          );
        },
        title: Text(
          user.isBot
              ? context.l10n.conversationAddBot
              : context.l10n.conversationAddContact,
          style: TextStyle(fontSize: 12, color: context.theme.accent),
        ),
      );
}

class _UserProfileButtonBar extends StatelessWidget {
  const _UserProfileButtonBar({Key? key, required this.user}) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) {
    final isSelf = user.userId == context.accountServer.userId;
    final children = [
      ActionButton(
        name: Resources.assetsImagesInviteShareSvg,
        size: 30,
        onTap: () async {
          final result = await showConversationSelector(
            context: context,
            singleSelect: true,
            title: context.l10n.shareContact,
            onlyContact: false,
          );

          if (result == null || result.isEmpty) return;
          final conversationId = result[0].conversationId;

          await runFutureWithToast(
            context,
            context.accountServer.sendContactMessage(
              user.userId,
              user.fullName!,
              result.first.encryptCategory!,
              conversationId: conversationId,
              recipientId: result[0].userId,
            ),
          );
        },
        color: context.theme.icon,
      ),
      if (!isSelf)
        ActionButton(
          name: Resources.assetsImagesChatSmallSvg,
          size: 30,
          onTap: () async {
            if (user.userId == context.accountServer.userId) {
              // skip self.
              return;
            }
            await ConversationCubit.selectUser(
              context,
              user.userId,
            );
            Navigator.pop(context);
          },
          color: context.theme.icon,
        ),
      if (!isSelf)
        ActionButton(
          name: Resources.assetsImagesInformationSvg,
          size: 30,
          onTap: () async {
            await ConversationCubit.selectUser(
              context,
              user.userId,
              initialChatSidePage: ChatSideCubit.infoPage,
            );
            Navigator.pop(context);
          },
          color: context.theme.icon,
        )
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45),
      child: Row(
        mainAxisAlignment: children.length == 1
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: children,
      ),
    );
  }
}
