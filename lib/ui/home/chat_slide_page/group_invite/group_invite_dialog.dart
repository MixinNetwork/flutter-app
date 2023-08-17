import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/resources.dart';
import '../../../../db/database_event_bus.dart';
import '../../../../db/mixin_database.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../../widgets/avatar_view/avatar_view.dart';
import '../../../../widgets/buttons.dart';
import '../../../../widgets/dialog.dart';
import '../../../../widgets/interactive_decorated_box.dart';
import '../../../../widgets/toast.dart';
import '../../../../widgets/user_selector/conversation_selector.dart';

Future<void> showGroupInviteByLinkDialog(BuildContext context,
    {required String conversationId}) async {
  await showMixinDialog(
      context: context,
      child: _GroupInviteByLinkDialog(
        conversationId: conversationId,
      ));
}

class _GroupInviteByLinkDialog extends HookConsumerWidget {
  const _GroupInviteByLinkDialog({
    required this.conversationId,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = useMemoizedStream(
      () {
        context.accountServer.refreshConversation(conversationId);
        return context.database.conversationDao
            .conversationById(conversationId)
            .watchSingleOrNullWithStream(
          eventStreams: [
            DataBaseEventBus.instance
                .watchUpdateConversationStream([conversationId]),
          ],
          duration: kDefaultThrottleDuration,
        );
      },
      keys: [conversationId],
    ).data;
    return Material(
        color: context.theme.popUp,
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
                        context.l10n.inviteToGroupViaLink,
                        style: TextStyle(
                          fontSize: 18,
                          color: context.theme.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 30, top: 20),
                      child: MixinCloseButton(),
                    )),
              ],
            )));
  }
}

class _GroupInviteBody extends StatelessWidget {
  const _GroupInviteBody({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: 120),
          ConversationAvatarWidget(
            size: 90,
            conversationId: conversation.conversationId,
            fullName: conversation.name,
            groupIconUrl: conversation.iconUrl,
            category: conversation.category,
            userId: conversation.ownerId,
          ),
          const SizedBox(height: 16),
          Text(
            conversation.name ?? '',
            style: TextStyle(
              fontSize: 18,
              color: context.theme.text,
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
                color: context.theme.text,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 338,
            child: Text(
              context.l10n.inviteInfo,
              style: TextStyle(
                fontSize: 12,
                color: context.theme.secondaryText,
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

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.conversation,
  });

  final Conversation conversation;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _IconButton(
            label: context.l10n.shareLink,
            iconAssetName: Resources.assetsImagesInviteShareSvg,
            onTap: () async {
              assert(conversation.codeUrl != null);
              final result = await showConversationSelector(
                context: context,
                singleSelect: true,
                title: context.l10n.forward,
                onlyContact: false,
              );
              if (result == null || result.isEmpty) return;
              await runFutureWithToast(context.accountServer.sendTextMessage(
                conversation.codeUrl!,
                result.first.encryptCategory!,
                conversationId: result.first.conversationId,
                recipientId: result.first.userId,
              ));
            },
          ),
          if (conversation.codeUrl != null)
            _IconButton(
              label: context.l10n.copyInvite,
              iconAssetName: Resources.assetsImagesInviteCopySvg,
              onTap: () async {
                final codeUrl = conversation.codeUrl;
                await Clipboard.setData(ClipboardData(text: codeUrl!));
                showToastSuccessful();
              },
            ),
          _IconButton(
            label: context.l10n.resetLink,
            iconAssetName: Resources.assetsImagesInviteRefreshSvg,
            onTap: () {
              runFutureWithToast(
                  context.accountServer.rotate(conversation.conversationId));
            },
          ),
        ],
      );
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.label,
    required this.iconAssetName,
    required this.onTap,
  });

  final String label;
  final String iconAssetName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveDecoratedBox.color(
        onTap: onTap,
        decoration: const BoxDecoration(),
        hoveringColor: context.dynamicColor(
          const Color.fromRGBO(0, 0, 0, 0.03),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconAssetName,
                width: 24,
                height: 24,
                colorFilter:
                    ColorFilter.mode(context.theme.icon, BlendMode.srcIn),
              ),
              const SizedBox(height: 15),
              Text(
                label,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 14,
                ),
              )
            ],
          ),
        ),
      );
}
