import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../account/account_server.dart';
import '../../constants/resources.dart';
import '../../db/extension/user.dart';
import '../../db/mixin_database.dart';
import '../../generated/l10n.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../ui/home/chat_page.dart';
import '../../ui/home/conversation_page.dart';
import '../action_button.dart';
import '../avatar_view/avatar_view.dart';
import '../brightness_observer.dart';
import '../buttons.dart';
import '../dialog.dart';
import '../more_extended_text.dart';
import '../toast.dart';
import '../user_selector/conversation_selector.dart';

Future<void> showUserDialog(BuildContext context, String userId) async {
  final existed =
      await context.read<AccountServer>().database.userDao.hasUser(userId);
  if (existed) {
    Toast.dismiss();
    await showMixinDialog(context: context, child: _UserDialog(userId: userId));
    return;
  }

  showToastLoading(context);

  final result =
      await context.read<AccountServer>().refreshUsers([userId], force: true);

  if (result?.isEmpty ?? true) {
    await showToastFailed(
        context,
        ToastError(
          Localization.of(context).userNotFound,
        ));
    return;
  }

  Toast.dismiss();
  await showMixinDialog(
    context: context,
    child: _UserDialog(
      userId: userId,
      refreshUser: false,
    ),
  );
}

class _UserDialog extends StatelessWidget {
  const _UserDialog({
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
          Material(
            color: BrightnessData.themeOf(context).popUp,
            child: SizedBox(
              width: 340,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Center(
                      child:
                          _UserProfileLoader(userId, refreshUser: refreshUser)),
                  const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 12, top: 12),
                        child: MixinCloseButton(),
                      )),
                ],
              ),
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
    final accountServer = context.read<AccountServer>();
    final user = useStream(useMemoized(
        () =>
            accountServer.database.userDao.userById(userId).watchSingleOrNull(),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 72),
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
                SelectableText(
                  user.fullName ?? '',
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).text,
                    fontSize: 16,
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
              Localization.of(context).contactMixinId(user.identityNumber),
              style: TextStyle(
                color: BrightnessData.themeOf(context).secondaryText,
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
          minHeight: 0,
          minWidth: 160,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: MoreExtendedText(
              biography,
              style: TextStyle(
                color: BrightnessData.themeOf(context).text,
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
  Widget build(BuildContext context) => TextButton(
        style: TextButton.styleFrom(
          backgroundColor: BrightnessData.themeOf(context).statusBackground,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          assert(user.fullName != null, ' username should not be null.');
          runFutureWithToast(
            context,
            context.read<AccountServer>().addUser(
                  user.userId,
                  user.fullName,
                ),
          );
        },
        child: Text(
          user.isBot
              ? Localization.of(context).conversationAddBot
              : Localization.of(context).conversationAddContact,
          style: TextStyle(
              fontSize: 12, color: BrightnessData.themeOf(context).accent),
        ),
      );
}

class _UserProfileButtonBar extends StatelessWidget {
  const _UserProfileButtonBar({Key? key, required this.user}) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) {
    final isSelf = user.userId == context.read<AccountServer>().userId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ActionButton(
            name: Resources.assetsImagesInviteShareSvg,
            size: 30,
            onTap: () async {
              final result = await showConversationSelector(
                context: context,
                singleSelect: true,
                title: Localization.of(context).shareContact,
                onlyContact: false,
              );

              if (result.isEmpty) return;
              final conversationId = result[0].conversationId;

              assert(!(result[0].isGroup && result[0].userId != null),
                  'group conversation should not contains userId!');

              await runFutureWithToast(
                context,
                context.read<AccountServer>().sendContactMessage(
                      user.userId,
                      user.fullName!,
                      isPlain(result.first.isGroup, result.first.isBot),
                      conversationId: conversationId,
                      recipientId: result[0].userId,
                    ),
              );
            },
            color: BrightnessData.themeOf(context).icon,
          ),
          if (!isSelf)
            ActionButton(
              name: Resources.assetsImagesChatSvg,
              size: 30,
              onTap: () async {
                if (user.userId == context.read<AccountServer>().userId) {
                  // skip self.
                  return;
                }
                await ConversationCubit.selectUser(
                  context,
                  user.userId,
                );
                Navigator.pop(context);
              },
              color: BrightnessData.themeOf(context).icon,
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
              color: BrightnessData.themeOf(context).icon,
            )
        ],
      ),
    );
  }
}
