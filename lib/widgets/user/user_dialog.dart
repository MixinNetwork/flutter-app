import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/resources.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../ui/home/chat/chat_page.dart';
import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../ui/provider/database_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/logger.dart';
import '../action_button.dart';
import '../avatar_view/avatar_view.dart';
import '../buttons.dart';
import '../conversation/badges_widget.dart';
import '../dialog.dart';
import '../high_light_text.dart';
import '../menu.dart';
import '../more_extended_text.dart';
import '../toast.dart';
import '../user_selector/conversation_selector.dart';

Future<void> showUserDialog(
  BuildContext context,
  ProviderContainer container,
  String? userId, [
  String? identityNumber,
]) async {
  final database = container.read(databaseProvider).requireValue;
  final accountServer = container.read(accountServerProvider).requireValue;
  final l10n = container.read(localizationProvider);
  var _userId = userId;
  assert(_userId != null || identityNumber != null);

  final existed = await database.userDao.hasUser(
    _userId ?? identityNumber!,
  );
  if (existed) {
    Toast.dismiss();
    _userId ??= (await database.userDao.findMultiUserIdsByIdentityNumbers([
      identityNumber!,
    ])).first;
    await showMixinDialog(
      context: context,
      child: UserDialog(userId: _userId),
    );
    return;
  }

  showToastLoading();

  User? user;
  if (_userId != null) {
    user = (await accountServer.refreshUsers([
      _userId,
    ], force: true))?.firstOrNull;
  }

  if (user == null && identityNumber != null) {
    user = (await accountServer.updateUserByIdentityNumber(
      identityNumber,
    ))?.firstOrNull;
  }

  if (user == null) {
    showToastFailed(ToastError(l10n.userNotFound));
    return;
  }

  _userId ??= (await database.userDao.findMultiUserIdsByIdentityNumbers(
    [
      identityNumber!,
    ],
  )).first;

  Toast.dismiss();
  await showMixinDialog(
    context: context,
    child: UserDialog(userId: _userId, refreshUser: false),
  );
}

class UserDialog extends StatelessWidget {
  const UserDialog({required this.userId, super.key, this.refreshUser = true});

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
            const Row(
              children: [
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

class _UserProfileLoader extends HookConsumerWidget {
  const _UserProfileLoader(this.userId, {this.refreshUser = true});

  final String userId;
  final bool refreshUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServer = ref.read(accountServerProvider).requireValue;
    final user = useMemoizedStream(
      () => accountServer.database.userDao
          .userById(userId)
          .watchSingleOrNullWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateUserStream([userId]),
            ],
            duration: kDefaultThrottleDuration,
          ),
      keys: [userId],
    ).data;

    useEffect(() {
      if (refreshUser) {
        accountServer.refreshUsers([userId], force: true);
      }
    }, [userId, refreshUser]);

    if (user == null) return const SizedBox();
    return _UserProfileBody(user: user);
  }
}

class _UserProfileBody extends ConsumerWidget {
  const _UserProfileBody({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    final anonymous = user.identityNumber == '0';
    final biographyIsNotEmpty = !(user.biography?.isEmpty ?? true);

    final isDeactivated = user.isDeactivated ?? false;
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              final copy = HardwareKeyboard.instance.logicalKeysPressed
                  .contains(LogicalKeyboardKey.altLeft);
              if (copy) {
                Clipboard.setData(
                  ClipboardData(text: 'mixin://users/${user.userId}'),
                );
              }
            },
            child: AvatarWidget(
              size: 90,
              avatarUrl: user.avatarUrl,
              userId: user.userId,
              name: user.fullName,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: CustomSelectableArea(
                    child: CustomText(
                      user.fullName ?? '',
                      style: TextStyle(
                        color: brightnessTheme.text,
                        fontSize: 16,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                BadgesWidget(
                  verified: user.isVerified ?? false,
                  isBot: !anonymous && user.appId != null,
                  membership: user.membership,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!anonymous)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CustomSelectableText(
                    l10n.contactMixinId(user.identityNumber),
                    style: TextStyle(
                      color: brightnessTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (!anonymous && user.isStranger && !isDeactivated)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _AddToContactsButton(user: user),
                ),
              if (biographyIsNotEmpty && !isDeactivated)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _BioText(biography: user.biography ?? ''),
                ),
              if (isDeactivated)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(top: 20, right: 20, left: 20),
                  decoration: BoxDecoration(
                    color: brightnessTheme.listSelected,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Text(
                    l10n.userDeleteHint,
                    style: TextStyle(
                      color: brightnessTheme.red,
                    ),
                  ),
                ),
              if (!anonymous)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _UserProfileButtonBar(user: user),
                ),
            ],
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }
}

class _BioText extends ConsumerWidget {
  const _BioText({required this.biography});

  final String biography;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 120, minWidth: 160),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: MoreExtendedText(
            biography,
            style: TextStyle(
              color: brightnessTheme.text,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddToContactsButton extends ConsumerWidget {
  const _AddToContactsButton({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServer = ref.read(accountServerProvider).requireValue;
    final l10n = ref.watch(localizationProvider);
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    return DialogAddOrJoinButton(
      onTap: () {
        assert(user.fullName != null, ' username should not be null.');
        runFutureWithToast(accountServer.addUser(user.userId, user.fullName));
      },
      title: Text(
        user.isBot ? l10n.addBotWithPlus : l10n.addContactWithPlus,
        style: TextStyle(
          fontSize: 12,
          color: brightnessTheme.accent,
        ),
      ),
    );
  }
}

class _UserProfileButtonBar extends ConsumerWidget {
  const _UserProfileButtonBar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServer = ref.read(accountServerProvider).requireValue;
    final l10n = ref.watch(localizationProvider);
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    final isSelf = user.userId == accountServer.userId;
    final children = [
      ActionButton(
        name: Resources.assetsImagesInviteShareSvg,
        size: 30,
        onTap: () async {
          final result = await showConversationSelector(
            context: context,
            singleSelect: true,
            title: l10n.shareContact,
            onlyContact: false,
            action: CustomPopupMenuButton(
              alignment: Alignment.bottomCenter,
              itemBuilder: (context) => [
                CustomPopupMenuItem(
                  icon: Resources.assetsImagesContextMenuCopySvg,
                  title: l10n.copyLink,
                  value: null,
                ),
              ],
              onSelected: (_) async {
                final codeUrl = user.codeUrl;
                if (codeUrl == null) {
                  e('codeUrl is null: $user');
                  return;
                }
                i('share contact ${user.userId} $codeUrl');
                await Clipboard.setData(ClipboardData(text: codeUrl));
              },
              color: brightnessTheme.icon,
              icon: Resources.assetsImagesInviteShareSvg,
            ),
          );

          if (result == null || result.isEmpty) return;
          final conversationId = result.first.conversationId;

          await runFutureWithToast(
            accountServer.sendContactMessage(
              user.userId,
              user.fullName,
              result.first.encryptCategory!,
              conversationId: conversationId,
              recipientId: result.first.userId,
            ),
          );
        },
        color: brightnessTheme.icon,
      ),
      if (!isSelf)
        ActionButton(
          name: Resources.assetsImagesChatSmallSvg,
          size: 30,
          onTap: () async {
            if (user.userId == accountServer.userId) {
              // skip self.
              return;
            }
            await ConversationStateNotifier.selectUser(
              ref.container,
              context,
              user.userId,
            );
            Navigator.pop(context);
          },
          color: brightnessTheme.icon,
        ),
      if (!isSelf)
        ActionButton(
          name: Resources.assetsImagesInformationSvg,
          size: 30,
          onTap: () async {
            await ConversationStateNotifier.selectUser(
              ref.container,
              context,
              user.userId,
              initialChatSidePage: ChatSideController.infoPage,
            );
            Navigator.pop(context);
          },
          color: brightnessTheme.icon,
        ),
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
