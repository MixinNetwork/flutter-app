import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../constants/icon_fonts.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/extension/conversation.dart';
import '../../../widgets/conversation/mute_dialog.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/toast.dart';
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/database_provider.dart';
import '../../provider/slide_category_provider.dart';
import '../../provider/ui_context_providers.dart';

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

    final accountServer = ref.read(accountServerProvider).requireValue;
    final database = ref.read(databaseProvider).requireValue;
    final l10n = ref.watch(localizationProvider);

    return CustomContextMenuWidget(
      desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
      menuProvider: (request) async {
        final circleId = ref.read(
          slideCategoryProvider.select((value) {
            if (value.type != SlideCategoryType.circle) return null;
            return value.id;
          }),
        );

        final circles = await database.circleDao
            .otherCircleByConversationId(conversationId)
            .get();

        return MenusWithSeparator(
          childrens: [
            [
              if (pinTime != null)
                MenuAction(
                  image: MenuImage.icon(IconFonts.unPin),
                  title: l10n.unpin,
                  callback: () =>
                      runFutureWithToast(accountServer.unpin(conversationId)),
                )
              else
                MenuAction(
                  image: MenuImage.icon(IconFonts.pin),
                  title: l10n.pinTitle,
                  callback: () =>
                      runFutureWithToast(accountServer.pin(conversationId)),
                ),
              if (isMute)
                MenuAction(
                  image: MenuImage.icon(IconFonts.unMute),
                  title: l10n.unmute,
                  callback: () => runFutureWithToast(
                    accountServer.unMuteConversation(
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
                  title: l10n.mute,
                  callback: () async {
                    final result = await showMixinDialog<int?>(
                      context: context,
                      child: const MuteDialog(),
                    );
                    if (result == null) return;
                    await runFutureWithToast(
                      accountServer.muteConversation(
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
                  title: l10n.addToCircle,
                  children: circles
                      .map(
                        (e) => MenuAction(
                          title: e.name,
                          callback: () async {
                            await runFutureWithToast(() async {
                              await accountServer.editCircleConversation(
                                e.circleId,
                                [
                                  CircleConversationRequest(
                                    action: CircleConversationAction.add,
                                    conversationId: conversationId,
                                    userId: isGroupConversation
                                        ? null
                                        : ownerId,
                                  ),
                                ],
                              );
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
                title: l10n.deleteChat,
                callback: () async {
                  final name =
                      conversation?.validName ?? searchConversation!.validName;
                  final ret = await showConfirmMixinDialog(
                    context,
                    l10n.conversationDeleteTitle(name),
                    description: l10n.deleteChatDescription,
                  );
                  if (ret == null) return;
                  await accountServer.deleteMessagesByConversationId(
                    conversationId,
                  );
                  await accountServer.deleteConversation(conversationId);
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
                  title: l10n.removeChatFromCircle,
                  callback: () => runFutureWithToast(
                    accountServer.editCircleConversation(circleId, [
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
