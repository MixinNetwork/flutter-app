import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    hide SelectableRegion, SelectableRegionState;
import 'package:flutter/rendering.dart' show SelectedContent, SelectionStatus;
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../blaze/vo/pin_message_minimal.dart';
import '../../constants/icon_fonts.dart';
import '../../db/dao/sticker_dao.dart';
import '../../db/mixin_database.dart' hide Message;
import '../../enum/media_status.dart';
import '../../ui/home/chat/message_jump.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../ui/provider/message_selection_provider.dart';
import '../../ui/provider/quote_message_provider.dart';
import '../../ui/provider/recall_message_reedit_provider.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../../utils/platform.dart';
import '../../utils/system/clipboard.dart';
import '../menu.dart';
import '../qr_code.dart';
import '../sticker_page/add_sticker_dialog.dart';
import '../toast.dart';
import '../user_selector/conversation_selector.dart';
import 'item/action_card/action_card_data.dart';
import 'item/text/selectable.dart';
import 'message_file_actions.dart';

Menu? buildMessageActionsMenu({
  required BuildContext context,
  required WidgetRef ref,
  required MenuRequest request,
  required MessageItem message,
  required bool isTranscriptPage,
  required bool isPinnedPage,
  required ValueNotifier<bool> showedMenu,
  required FocusNode focusNode,
}) {
  request.onShowMenu.addListener(() {
    showedMenu.value = true;
    focusNode.requestFocus();
  });
  request.onHideMenu.addListener(() {
    showedMenu.value = false;
  });

  if (ref.read(hasSelectedMessageProvider)) return null;

  final role = ref.read(conversationProvider.select((value) => value?.role));

  final pinEnabled =
      !isTranscriptPage &&
      message.type.canReply &&
      const [
        MessageStatus.delivered,
        MessageStatus.read,
        MessageStatus.sent,
      ].contains(message.status) &&
      role != null;
  final enableReply =
      !isTranscriptPage && message.type.canReply && !isPinnedPage;
  final enableForward = !isTranscriptPage && message.canForward;
  final enableSelect = !isTranscriptPage;
  final enableSaveMobile =
      kPlatformIsMobile && (message.type.isImage || message.type.isVideo);
  final enableSaveDesktop =
      kPlatformIsDesktop &&
      message.mediaStatus == MediaStatus.done &&
      message.mediaUrl?.isNotEmpty == true &&
      (message.type.isData ||
          message.type.isImage ||
          message.type.isVideo ||
          message.type.isAudio);
  final enableRecall = !isTranscriptPage && message.canRecall;

  final enableDelete = !isTranscriptPage && !isPinnedPage;

  final addStickerMenuAction = [
    if (message.type.isSticker)
      MenuAction(
        image: MenuImage.icon(IconFonts.sticker),
        title: context.l10n.addSticker,
        callback: () => _onAddSticker(context, message),
      ),
    if (message.type.isImage && message.canForward)
      MenuAction(
        image: MenuImage.icon(IconFonts.sticker),
        title: context.l10n.addSticker,
        callback: () => _onAddImageAsSticker(
          context,
          message,
          isTranscriptPage,
        ),
      ),
  ];

  final replayAction = [
    if (enableReply)
      MenuAction(
        image: MenuImage.icon(IconFonts.reply),
        title: context.l10n.reply,
        callback: () =>
            context.providerContainer
                    .read(quoteMessageProvider.notifier)
                    .state =
                message,
      ),
  ];

  final messageActions = [
    if (isPinnedPage)
      MenuAction(
        image: MenuImage.icon(IconFonts.positionToChat),
        title: context.l10n.locateToChat,
        callback: () {
          unawaited(
            context.jumpToMessageInChat(
              message.messageId,
              closeSideAfterJump: true,
            ),
          );
        },
      ),
    if (enableForward)
      MenuAction(
        image: MenuImage.icon(IconFonts.forward),
        title: context.l10n.forward,
        callback: () async {
          final result = await showConversationSelector(
            context: context,
            singleSelect: true,
            title: context.l10n.forward,
            onlyContact: false,
          );
          if (result == null || result.isEmpty) return;
          await context.accountServer.forwardMessage(
            message.messageId,
            result.first.encryptCategory!,
            conversationId: result.first.conversationId,
            recipientId: result.first.userId,
          );
        },
      ),
    if (enableSelect)
      MenuAction(
        image: MenuImage.icon(IconFonts.select),
        title: context.l10n.select,
        callback: () => ref
            .read(messageSelectionProvider)
            .selectMessage(
              message,
            ),
      ),
    if (pinEnabled)
      MenuAction(
        image: MenuImage.icon(message.pinned ? IconFonts.unPin : IconFonts.pin),
        title: message.pinned ? context.l10n.unpin : context.l10n.pinTitle,
        callback: () async {
          final pinMessageMinimal = PinMessageMinimal(
            messageId: message.messageId,
            type: message.type,
            content: message.type.isText ? message.content : null,
          );
          if (message.pinned) {
            await context.accountServer.unpinMessage(
              conversationId: message.conversationId,
              pinMessageMinimals: [pinMessageMinimal],
            );
            return;
          }
          await context.accountServer.pinMessage(
            conversationId: message.conversationId,
            pinMessageMinimals: [pinMessageMinimal],
          );
        },
      ),
  ];

  final copyActions = <MenuAction>[];
  if (message.type.isPost) {
    copyActions.add(
      MenuAction(
        image: MenuImage.icon(IconFonts.copy),
        title: context.l10n.copy,
        callback: () {
          Clipboard.setData(ClipboardData(text: message.content ?? ''));
        },
      ),
    );
  } else if (message.type.isImage) {
    copyActions.add(
      MenuAction(
        image: MenuImage.icon(IconFonts.copy),
        title: context.l10n.copyImage,
        callback: () {
          copyFile(
            context.accountServer.convertMessageAbsolutePath(
              message,
              isTranscriptPage,
            ),
          );
        },
      ),
    );
    if (!message.caption.isNullOrBlank()) {
      final selectedContent = _findSelectedContent(context);
      if (selectedContent != null) {
        copyActions.add(
          MenuAction(
            image: MenuImage.icon(IconFonts.copy),
            title: context.l10n.copySelectedText,
            callback: () {
              Clipboard.setData(
                ClipboardData(text: selectedContent.plainText),
              );
            },
          ),
        );
      } else {
        copyActions.add(
          MenuAction(
            image: MenuImage.icon(IconFonts.copy),
            title: context.l10n.copyText,
            callback: () {
              Clipboard.setData(ClipboardData(text: message.caption ?? ''));
            },
          ),
        );
      }
    }
  } else if (message.type.isText) {
    final selectedContent = _findSelectedContent(context);
    copyActions
      ..add(
        MenuAction(
          image: MenuImage.icon(IconFonts.copy),
          title: selectedContent == null
              ? context.l10n.copy
              : context.l10n.copySelectedText,
          callback: () {
            Clipboard.setData(
              ClipboardData(
                text: selectedContent?.plainText ?? message.content ?? '',
              ),
            );
          },
        ),
      )
      ..add(
        MenuAction(
          image: MenuImage.icon(Icons.qr_code),
          title: context.l10n.generateQrcode,
          callback: () {
            final content = selectedContent?.plainText ?? message.content ?? '';
            showQrCodeDialog(context, content);
          },
        ),
      );
  } else if (message.type.isAppCard) {
    final selectedContent = _findSelectedContent(context);
    if (selectedContent != null) {
      copyActions.add(
        MenuAction(
          image: MenuImage.icon(IconFonts.copy),
          title: context.l10n.copySelectedText,
          callback: () {
            String text;
            try {
              final data = AppCardData.fromJson(
                jsonDecode(message.content!) as Map<String, dynamic>,
              );
              text = data.generateCopyTextWithBreakLine(
                selectedContent.plainText,
              );
            } catch (error) {
              e('ActionCard decode error: $error');
              text = selectedContent.plainText;
            }
            Clipboard.setData(ClipboardData(text: text));
          },
        ),
      );
    }
  }

  final saveActions = [
    if (enableSaveMobile)
      MenuAction(
        image: MenuImage.icon(IconFonts.download),
        title: context.l10n.saveToCameraRoll,
        callback: () => saveAs(
          context,
          context.accountServer,
          message,
          isTranscriptPage,
        ),
      ),
    if (enableSaveDesktop)
      MenuAction(
        image: MenuImage.icon(IconFonts.download),
        title: context.l10n.saveAs,
        callback: () => saveAs(
          context,
          context.accountServer,
          message,
          isTranscriptPage,
        ),
      ),
  ];
  final deleteActions = [
    if (enableRecall)
      MenuAction(
        image: MenuImage.icon(IconFonts.recall),
        title: context.l10n.deleteForEveryone,
        callback: () async {
          String? content;
          if (message.type.isText) {
            content = message.content;
          }
          await context.accountServer.sendRecallMessage([
            message.messageId,
          ], conversationId: message.conversationId);
          if (content != null) {
            context.providerContainer
                .read(recallMessageNotifierProvider)
                .onRecalled(message.messageId, content);
          }
        },
      ),
    if (enableDelete)
      MenuAction(
        image: MenuImage.icon(IconFonts.delete),
        title: context.l10n.deleteForMe,
        callback: () => context.accountServer.deleteMessage(message.messageId),
      ),
  ];

  final devActions = [
    if (!kReleaseMode)
      MenuAction(
        image: MenuImage.icon(IconFonts.copy),
        title: 'Copy message',
        callback: () =>
            Clipboard.setData(ClipboardData(text: message.toString())),
      ),
  ];

  return MenusWithSeparator(
    childrens: [
      replayAction,
      copyActions,
      messageActions,
      saveActions,
      addStickerMenuAction,
      deleteActions,
      devActions,
    ],
  );
}

SelectedContent? _findSelectedContent(BuildContext context) {
  SelectableRegionState? findSelectableRegionState(BuildContext context) {
    if (context is! Element) return null;
    if (context.widget is SelectableRegion) {
      return (context as StatefulElement).state as SelectableRegionState;
    }
    SelectableRegionState? find;
    context.visitChildren((element) {
      if (find != null) return;
      find = findSelectableRegionState(element);
    });
    return find;
  }

  final selectableRegion = findSelectableRegionState(context);
  final status = selectableRegion?.selectable?.value.status;
  final content = selectableRegion?.selectable?.getSelectedContent();
  d('status: $status, content: $content');
  if (status == SelectionStatus.uncollapsed && content != null) {
    return content;
  }
  return null;
}

Future<void> _onAddImageAsSticker(
  BuildContext context,
  MessageItem message,
  bool isTranscriptPage,
) async {
  await showAddStickerDialog(
    context,
    filepath: context.accountServer.convertMessageAbsolutePath(
      message,
      isTranscriptPage,
    ),
  );
}

Future<void> _onAddSticker(BuildContext context, MessageItem message) async {
  showToastLoading();
  try {
    final accountServer = context.accountServer;

    final mixinResponse = await accountServer.client.accountApi.addSticker(
      StickerRequest(stickerId: message.stickerId),
    );

    final database = context.database;

    final personalAlbum = await database.stickerAlbumDao
        .personalAlbum()
        .getSingleOrNull();
    if (personalAlbum == null) {
      unawaited(accountServer.refreshSticker(force: true));
    } else {
      final data = mixinResponse.data;
      await database.mixinDatabase.transaction(() async {
        await database.stickerDao.insert(data.asStickersCompanion);
        await database.stickerRelationshipDao.insert(
          StickerRelationship(
            albumId: personalAlbum.albumId,
            stickerId: data.stickerId,
          ),
        );
      });
    }
    showToastSuccessful();
  } catch (_) {
    showToastFailed(ToastError(context.l10n.addStickerFailed));
  }
}
