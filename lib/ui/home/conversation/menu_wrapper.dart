import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../constants/icon_fonts.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/extension/conversation.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/conversation/mute_dialog.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/toast.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/slide_category_provider.dart';

class ConversationMenuWrapper extends HookConsumerWidget {
  const ConversationMenuWrapper({
    required this.child,
    super.key,
    this.conversation,
    this.searchConversation,
    this.removeChatFromCircle = false,
  });

  final ConversationItem? conversation;
  final SearchConversationItem? searchConversation;
  final Widget child;
  final bool removeChatFromCircle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(conversation != null || searchConversation != null);

    final conversationId =
        conversation?.conversationId ?? searchConversation!.conversationId;
    final ownerId = conversation?.ownerId ?? searchConversation!.ownerId;
    final pinTime = conversation?.pinTime ?? searchConversation?.pinTime;
    final isMute = conversation?.isMute ?? searchConversation!.isMute;
    final isGroupConversation =
        conversation?.isGroupConversation ??
        searchConversation!.isGroupConversation;

    return CustomContextMenuWidget(
      desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
      menuProvider: (MenuRequest request) async {
        final circleId = ref.read(
          slideCategoryStateProvider.select((value) {
            if (value.type != SlideCategoryType.circle) return null;
            return value.id;
          }),
        );

        final circles = await context.database.circleDao
            .otherCircleByConversationId(conversationId)
            .get();

        return MenusWithSeparator(
          childrens: [
            [
              if (pinTime != null)
                MenuAction(
                  image: MenuImage.icon(IconFonts.unPin),
                  title: context.l10n.unpin,
                  callback: () => runFutureWithToast(
                    context.accountServer.unpin(conversationId),
                  ),
                )
              else
                MenuAction(
                  image: MenuImage.icon(IconFonts.pin),
                  title: context.l10n.pinTitle,
                  callback: () => runFutureWithToast(
                    context.accountServer.pin(conversationId),
                  ),
                ),
              if (isMute)
                MenuAction(
                  image: MenuImage.icon(IconFonts.unMute),
                  title: context.l10n.unmute,
                  callback: () => runFutureWithToast(
                    context.accountServer.unMuteConversation(
                      conversationId: isGroupConversation
                          ? conversationId
                          : null,
                      userId: isGroupConversation ? null : ownerId,
                    ),
                  ),
                )
              else
                MenuAction(
                  image: MenuImage.icon(IconFonts.mute),
                  title: context.l10n.mute,
                  callback: () async {
                    final result = await showMixinDialog<int?>(
                      context: context,
                      child: const MuteDialog(),
                    );
                    if (result == null) return;
                    await runFutureWithToast(
                      context.accountServer.muteConversation(
                        result,
                        conversationId: isGroupConversation
                            ? conversationId
                            : null,
                        userId: isGroupConversation ? null : ownerId,
                      ),
                    );
                    return;
                  },
                ),
            ],
            [
              if (circles.isNotEmpty)
                Menu(
                  image: MenuImage.icon(IconFonts.circle),
                  title: context.l10n.addToCircle,
                  children: circles
                      .map(
                        (e) => MenuAction(
                          title: e.name,
                          callback: () async {
                            await runFutureWithToast(() async {
                              await context.accountServer
                                  .editCircleConversation(e.circleId, [
                                    CircleConversationRequest(
                                      action: CircleConversationAction.add,
                                      conversationId: conversationId,
                                      userId: isGroupConversation
                                          ? null
                                          : ownerId,
                                    ),
                                  ]);
                            }());
                          },
                        ),
                      )
                      .toList(),
                ),
            ],
            [
              MenuAction(
                image: MenuImage.icon(IconFonts.delete),
                title: context.l10n.deleteChat,
                callback: () async {
                  final name =
                      conversation?.validName ?? searchConversation!.validName;
                  final ret = await showConfirmMixinDialog(
                    context,
                    context.l10n.conversationDeleteTitle(name),
                    description: context.l10n.deleteChatDescription,
                  );
                  if (ret == null) return;
                  await context.accountServer.deleteMessagesByConversationId(
                    conversationId,
                  );
                  await context.database.conversationDao.deleteConversation(
                    conversationId,
                  );
                  if (ref.read(conversationProvider)?.conversationId ==
                      conversationId) {
                    ref.read(conversationProvider.notifier).unselected();
                  }
                },
              ),
              if (removeChatFromCircle &&
                  circleId != null &&
                  circleId.isNotEmpty)
                MenuAction(
                  image: MenuImage.icon(IconFonts.delete),
                  title: context.l10n.removeChatFromCircle,
                  callback: () => runFutureWithToast(
                    context.accountServer.editCircleConversation(circleId, [
                      CircleConversationRequest(
                        action: CircleConversationAction.remove,
                        conversationId: conversationId,
                        userId: isGroupConversation ? null : ownerId,
                      ),
                    ]),
                  ),
                ),
            ],
          ],
        );
      },
      child: child,
    );
  }
}
