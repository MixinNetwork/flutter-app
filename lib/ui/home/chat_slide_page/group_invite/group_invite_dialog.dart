import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../account/account_server.dart';
import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../generated/l10n.dart';
import '../../../../widgets/action_button.dart';
import '../../../../widgets/avatar_view/avatar_view.dart';
import '../../../../widgets/brightness_observer.dart';
import '../../../../widgets/dialog.dart';
import '../../../../widgets/interacter_decorated_box.dart';
import '../../../../widgets/toast.dart';
import '../../../../widgets/user_selector/conversation_selector.dart';
import '../../bloc/conversation_cubit.dart';

Future<void> showGroupInviteByLinkDialog(BuildContext context,
    {required String conversationId}) async {
  await showMixinDialog(
      context: context,
      child: _GroupInviteByLinkDialog(
        conversationId: conversationId,
      ));
}

class _GroupInviteByLinkDialog extends HookWidget {
  const _GroupInviteByLinkDialog({
    Key? key,
    required this.conversationId,
  }) : super(key: key);

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final conversation = useStream(
      useMemoized(() {
        final accountServer = context.read<AccountServer>()
          ..refreshGroup(conversationId);
        return accountServer.database.conversationDao
            .conversationById(conversationId)
            .watchSingleOrNull();
      }, [conversationId]),
    ).data;
    return Material(
        color: BrightnessData.themeOf(context).popUp,
        child: SizedBox(
            width: 480,
            height: 600,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                if (conversation != null)
                  _GroupInviteBody(conversation: conversation),
                Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text(
                        Localization.of(context).groupInvite,
                        style: TextStyle(
                          fontSize: 18,
                          color: BrightnessData.themeOf(context).text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 30.0, top: 20),
                      child: _CloseButton(),
                    )),
              ],
            )));
  }
}

class _GroupInviteBody extends StatelessWidget {
  const _GroupInviteBody({Key? key, required this.conversation})
      : super(key: key);

  final Conversation conversation;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          ConversationAvatarWidget(
            size: 90,
            conversationId: conversation.conversationId,
            fullName: conversation.name,
            groupIconUrl: conversation.iconUrl,
            category: conversation.category,
          ),
          const SizedBox(height: 16),
          Text(
            conversation.name ?? '',
            style: TextStyle(
              fontSize: 18,
              color: BrightnessData.themeOf(context).text,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 320,
            child: SelectableText(
              conversation.codeUrl ?? '',
              style: TextStyle(
                fontSize: 14,
                color: BrightnessData.themeOf(context).text,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              toolbarOptions: const ToolbarOptions(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 338,
            child: Text(
              Localization.of(context).groupInviteInfo,
              style: TextStyle(
                fontSize: 12,
                color: BrightnessData.themeOf(context).secondaryText,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 61),
          _ActionButtons(conversation: conversation),
        ],
      );
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ActionButton(
        name: Resources.assetsImagesIcCloseSvg,
        color: BrightnessData.themeOf(context).icon,
        onTap: () => Navigator.pop(context),
      );
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  final Conversation conversation;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _IconButton(
            label: Localization.of(context).groupInviteShare,
            iconAssetName: Resources.assetsImagesInviteShareSvg,
            onTap: () async {
              assert(conversation.codeUrl != null);
              final result = await showConversationSelector(
                context: context,
                singleSelect: true,
                title: Localization.of(context).forward,
                onlyContact: false,
              );
              if (result.isEmpty) return;
              await runFutureWithToast(
                  context,
                  context.read<AccountServer>().sendTextMessage(
                        conversation.codeUrl!,
                        isPlain(result.first.isGroup, result.first.isBot),
                        conversationId: result.first.conversationId,
                        recipientId: result.first.userId,
                      ));
            },
          ),
          _IconButton(
            label: Localization.of(context).groupInviteCopy,
            iconAssetName: Resources.assetsImagesInviteCopySvg,
            onTap: () async {
              await Clipboard.setData(
                  ClipboardData(text: conversation.codeUrl));
              showToastSuccessful(context);
            },
          ),
          _IconButton(
            label: Localization.of(context).groupInviteReset,
            iconAssetName: Resources.assetsImagesInviteRefreshSvg,
            onTap: () {
              runFutureWithToast(
                  context,
                  context
                      .read<AccountServer>()
                      .rotate(conversation.conversationId));
            },
          ),
        ],
      );
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    Key? key,
    required this.label,
    required this.iconAssetName,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final String iconAssetName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractableDecoratedBox.color(
        onTap: onTap,
        decoration: const BoxDecoration(shape: BoxShape.rectangle),
        hoveringColor: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(0, 0, 0, 0.03),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconAssetName,
                width: 24,
                height: 24,
                color: BrightnessData.themeOf(context).icon,
              ),
              const SizedBox(height: 15),
              Text(
                label,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).text,
                  fontSize: 14,
                ),
              )
            ],
          ),
        ),
      );
}
