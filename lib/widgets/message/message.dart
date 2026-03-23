import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    hide SelectableRegion, SelectableRegionState;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gal/gal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide Key;
import 'package:open_file/open_file.dart';
import 'package:rxdart/rxdart.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../account/account_server.dart';
import '../../blaze/vo/pin_message_minimal.dart';
import '../../constants/icon_fonts.dart';
import '../../constants/resources.dart';
import '../../db/dao/sticker_dao.dart';
import '../../db/mixin_database.dart' hide Message, Offset;
import '../../enum/media_status.dart';
import '../../enum/message_category.dart';
import '../../ui/home/controllers/blink_controller.dart';
import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../ui/provider/database_provider.dart';
import '../../ui/provider/is_bot_group_provider.dart';
import '../../ui/provider/message_selection_provider.dart';
import '../../ui/provider/quote_message_provider.dart';
import '../../ui/provider/recall_message_reedit_provider.dart';
import '../../ui/provider/setting_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/double_tap_util.dart';
import '../../utils/extension/extension.dart';
import '../../utils/file.dart';
import '../../utils/hook.dart';
import '../../utils/logger.dart';
import '../../utils/platform.dart';
import '../../utils/system/clipboard.dart';
import '../avatar_view/avatar_view.dart';
import '../interactive_decorated_box.dart';
import '../menu.dart';
import '../qr_code.dart';
import '../sticker_page/add_sticker_dialog.dart';
import '../toast.dart';
import '../user/user_dialog.dart';
import '../user_selector/conversation_selector.dart';
import 'item/action/action_message.dart';
import 'item/action_card/action_card_data.dart';
import 'item/action_card/action_message.dart';
import 'item/audio_message.dart';
import 'item/contact_message_widget.dart';
import 'item/file_message.dart';
import 'item/image/image_message.dart';
import 'item/location/location_message_widget.dart';
import 'item/pin_message.dart';
import 'item/post_message.dart';
import 'item/recall_message.dart';
import 'item/secret_message.dart';
import 'item/sticker_message.dart';
import 'item/stranger_message.dart';
import 'item/system_message.dart';
import 'item/text/selectable.dart';
import 'item/text/text_message.dart';
import 'item/transcript_message.dart';
import 'item/transfer/inscription_message/inscription_message.dart';
import 'item/transfer/safe_transfer_message.dart';
import 'item/transfer/transfer_message.dart';
import 'item/unknown_message.dart';
import 'item/video/video_message.dart';
import 'item/waiting_message.dart';
import 'message_day_time.dart';
import 'message_name.dart';
import 'message_style.dart';

class _MessageContext with EquatableMixin {
  _MessageContext({
    required this.isTranscriptPage,
    required this.isPinnedPage,
    required this.showNip,
    required this.isCurrentUser,
    required this.message,
  });

  final bool isTranscriptPage;
  final bool isPinnedPage;
  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  List<Object?> get props => [
    isTranscriptPage,
    isPinnedPage,
    showNip,
    isCurrentUser,
    message,
  ];
}

class _MessageContextScope extends InheritedWidget {
  const _MessageContextScope({
    required this.value,
    required super.child,
  });

  final _MessageContext value;

  static _MessageContext of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_MessageContextScope>();
    assert(scope != null, '_MessageContextScope is missing');
    return scope!.value;
  }

  @override
  bool updateShouldNotify(_MessageContextScope oldWidget) =>
      oldWidget.value != value;
}

bool useIsTranscriptPage() =>
    _MessageContextScope.of(useContext()).isTranscriptPage;

bool useIsPinnedPage() => _MessageContextScope.of(useContext()).isPinnedPage;

bool useShowNip() => _MessageContextScope.of(useContext()).showNip;

bool useIsCurrentUser() => _MessageContextScope.of(useContext()).isCurrentUser;

MessageItem useMessage() =>
    useMessageConverter<MessageItem>(converter: (state) => state);

T useMessageConverter<T>({required T Function(MessageItem) converter}) =>
    converter(_MessageContextScope.of(useContext()).message);

extension MessageContextExtension on BuildContext {
  MessageItem get message => _MessageContextScope.of(this).message;

  bool get isPinnedPage => _MessageContextScope.of(this).isPinnedPage;

  bool get isTranscriptPage => _MessageContextScope.of(this).isTranscriptPage;
}

const _pinArrowWidth = 32.0;

void _quickReply(BuildContext context, WidgetRef ref) {
  if (context.isPinnedPage) return;
  if (context.isTranscriptPage) return;
  if (!context.message.type.canReply) return;

  doubleTap('_quickReply', const Duration(milliseconds: 300), () {
    ref
        .read(blinkControllerProvider.notifier)
        .blinkByMessageId(context.message.messageId);
    ref.read(quoteMessageProvider.notifier).set(context.message);
  });
}

SelectedContent? _findSelectedContent(BuildContext context) {
  SelectableRegionState? findSelectableRegionState(BuildContext context) {
    if (context is! Element) {
      return null;
    }
    if (context.widget is SelectableRegion) {
      return (context as StatefulElement).state as SelectableRegionState;
    }
    SelectableRegionState? find;
    context.visitChildren((element) {
      if (find != null) {
        return;
      }
      final result = findSelectableRegionState(element);
      if (result != null) {
        find = result;
      }
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

class MessageItemWidget extends HookConsumerWidget {
  const MessageItemWidget({
    required this.message,
    super.key,
    this.prev,
    this.next,
    this.bodyKey,
    this.lastReadMessageId,
    this.isTranscriptPage = false,
    this.blink = true,
    this.isPinnedPage = false,
  });

  final MessageItem message;
  final MessageItem? prev;
  final MessageItem? next;
  final Key? bodyKey;
  final String? lastReadMessageId;
  final bool isTranscriptPage;
  final bool blink;
  final bool isPinnedPage;

  static const primaryFontSize = 16.0;
  static const secondaryFontSize = 14.0;
  static const tertiaryFontSize = 12.0;

  static const statusFontSize = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final isCurrentUser = message.relationship == UserRelationship.me;

    final sameDayPrev = isSameDay(prev?.createdAt, message.createdAt);
    final prevIsSystem = prev?.type.isSystem ?? false;
    final prevIsPin = prev?.type.isPin ?? false;
    final sameUserPrev =
        !prevIsSystem && !prevIsPin && prev?.userId == message.userId;

    final sameDayNext = isSameDay(next?.createdAt, message.createdAt);
    final sameUserNext = next?.userId == message.userId;

    final isGroupOrBotGroupConversation =
        message.conversionCategory == ConversationCategory.group ||
        message.userId != message.conversationOwnerId ||
        ref.watch(isBotGroupProvider(message.conversationId));

    final enableShowAvatar = ref.watch(
      settingProvider.select((value) => value.messageShowAvatar),
    );
    final showAvatar = isGroupOrBotGroupConversation && enableShowAvatar;

    final showNip =
        !(sameUserNext && sameDayNext) && (!showAvatar || isCurrentUser);
    final datetime = sameDayPrev ? null : message.createdAt;
    String? userName;
    String? userId;
    String? userAvatarUrl;

    if (isGroupOrBotGroupConversation &&
        !isCurrentUser &&
        (!sameUserPrev || !sameDayPrev)) {
      userName = message.userFullName;
      userId = message.userId;
      userAvatarUrl = message.avatarUrl;
    }

    final showedMenuController = useState(false);
    final focusNode = useFocusScopeNode(
      debugLabel: 'message_item_${message.messageId}',
    );

    final showedMenu = useValueListenable(showedMenuController);
    final currentBlinkColor = ref.watch(
      blinkControllerProvider.select((blinkState) {
        if (!blink || blinkState.messageId != message.messageId) {
          return Colors.transparent;
        }
        return blinkState.color;
      }),
    );
    final blinkColor = showedMenu ? theme.listSelected : currentBlinkColor;

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (datetime != null) MessageDayTime(dateTime: datetime),
        KeyedSubtree(
          key: bodyKey,
          child: ColoredBox(
            color: blinkColor,
            child: Builder(
              builder: (context) {
                if (message.type == MessageCategory.systemConversation) {
                  return const SystemMessage();
                }

                if (message.type.isPin) {
                  return const PinMessageWidget();
                }

                if (message.type == MessageCategory.secret) {
                  return const SecretMessage();
                }

                if (message.type == MessageCategory.stranger) {
                  return const StrangerMessage();
                }

                return _MessageSelectionWrapper(
                  message: message,
                  child: _MessageBubbleMargin(
                    userName: userName,
                    userId: userId,
                    userAvatarUrl: userAvatarUrl,
                    showAvatar: showAvatar,
                    isCurrentUser: isCurrentUser,
                    pinArrowWidth: isPinnedPage ? _pinArrowWidth : 0,
                    isBot: message.isBot,
                    isVerified: message.isVerified,
                    buildMenus: (request) {
                      request.onShowMenu.addListener(() {
                        showedMenuController.value = true;
                        focusNode.requestFocus();
                      });
                      request.onHideMenu.addListener(() {
                        showedMenuController.value = false;
                      });

                      final enable = !ref.read(hasSelectedMessageProvider);

                      if (!enable) return null;

                      final role = ref.read(
                        conversationProvider.select((value) => value?.role),
                      );

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
                          !isTranscriptPage &&
                          message.type.canReply &&
                          !isPinnedPage;
                      final enableForward =
                          !isTranscriptPage && message.canForward;
                      final enableSelect = !isTranscriptPage;
                      final enableSaveMobile =
                          kPlatformIsMobile &&
                          (message.type.isImage || message.type.isVideo);
                      final enableSaveDesktop =
                          kPlatformIsDesktop &&
                          message.mediaStatus == MediaStatus.done &&
                          message.mediaUrl?.isNotEmpty == true &&
                          (message.type.isData ||
                              message.type.isImage ||
                              message.type.isVideo ||
                              message.type.isAudio);
                      final enableRecall =
                          !isTranscriptPage && message.canRecall;

                      final enableDelete = !isTranscriptPage && !isPinnedPage;

                      final addStickerMenuAction = [
                        if (message.type.isSticker)
                          MenuAction(
                            image: MenuImage.icon(IconFonts.sticker),
                            title: l10n.addSticker,
                            callback: () => _onAddSticker(context, ref),
                          ),
                        if (message.type.isImage && message.canForward)
                          MenuAction(
                            image: MenuImage.icon(IconFonts.sticker),
                            title: l10n.addSticker,
                            callback: () => _onAddImageAsSticker(ref),
                          ),
                      ];

                      final replayAction = [
                        if (enableReply)
                          MenuAction(
                            image: MenuImage.icon(IconFonts.reply),
                            title: l10n.reply,
                            callback: () => ref
                                .read(quoteMessageProvider.notifier)
                                .set(
                                  message,
                                ),
                          ),
                      ];

                      final messageActions = [
                        if (enableForward)
                          MenuAction(
                            image: MenuImage.icon(IconFonts.forward),
                            title: l10n.forward,
                            callback: () async {
                              final result = await showConversationSelector(
                                context: context,
                                singleSelect: true,
                                title: l10n.forward,
                                onlyContact: false,
                              );
                              if (result == null || result.isEmpty) return;
                              final accountServer = ref
                                  .read(accountServerProvider)
                                  .requireValue;
                              await accountServer.forwardMessage(
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
                            title: l10n.select,
                            callback: () => ref
                                .read(messageSelectionProvider.notifier)
                                .selectMessage(message),
                          ),
                        if (pinEnabled)
                          MenuAction(
                            image: MenuImage.icon(
                              message.pinned ? IconFonts.unPin : IconFonts.pin,
                            ),
                            title: message.pinned ? l10n.unpin : l10n.pinTitle,
                            callback: () async {
                              final pinMessageMinimal = PinMessageMinimal(
                                messageId: message.messageId,
                                type: message.type,
                                content: message.type.isText
                                    ? message.content
                                    : null,
                              );
                              if (message.pinned) {
                                await ref
                                    .read(accountServerProvider)
                                    .requireValue
                                    .unpinMessage(
                                      conversationId: message.conversationId,
                                      pinMessageMinimals: [pinMessageMinimal],
                                    );
                                return;
                              }
                              await ref
                                  .read(accountServerProvider)
                                  .requireValue
                                  .pinMessage(
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
                            title: l10n.copy,
                            callback: () {
                              Clipboard.setData(
                                ClipboardData(text: message.content ?? ''),
                              );
                            },
                          ),
                        );
                      } else if (message.type.isImage) {
                        copyActions.add(
                          MenuAction(
                            image: MenuImage.icon(IconFonts.copy),
                            title: l10n.copyImage,
                            callback: () {
                              final accountServer = ref
                                  .read(accountServerProvider)
                                  .requireValue;
                              copyFile(
                                accountServer.convertMessageAbsolutePath(
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
                                title: l10n.copySelectedText,
                                callback: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: selectedContent.plainText,
                                    ),
                                  );
                                },
                              ),
                            );
                          } else {
                            copyActions.add(
                              MenuAction(
                                image: MenuImage.icon(IconFonts.copy),
                                title: l10n.copyText,
                                callback: () {
                                  Clipboard.setData(
                                    ClipboardData(text: message.caption ?? ''),
                                  );
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
                                  ? l10n.copy
                                  : l10n.copySelectedText,
                              callback: () {
                                if (selectedContent != null) {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: selectedContent.plainText,
                                    ),
                                  );
                                } else {
                                  Clipboard.setData(
                                    ClipboardData(text: message.content ?? ''),
                                  );
                                }
                              },
                            ),
                          )
                          ..add(
                            MenuAction(
                              image: MenuImage.icon(Icons.qr_code),
                              title: l10n.generateQrcode,
                              callback: () {
                                final content =
                                    selectedContent?.plainText ??
                                    message.content ??
                                    '';
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
                              title: l10n.copySelectedText,
                              callback: () {
                                String text;
                                try {
                                  final data = AppCardData.fromJson(
                                    jsonDecode(message.content!)
                                        as Map<String, dynamic>,
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
                            title: l10n.saveToCameraRoll,
                            callback: () => saveAs(
                              context,
                              ref.read(accountServerProvider).requireValue,
                              message,
                              isTranscriptPage,
                              confirmButtonText: l10n.save,
                            ),
                          ),
                        if (enableSaveDesktop)
                          MenuAction(
                            image: MenuImage.icon(IconFonts.download),
                            title: l10n.saveAs,
                            callback: () => saveAs(
                              context,
                              ref.read(accountServerProvider).requireValue,
                              message,
                              isTranscriptPage,
                              confirmButtonText: l10n.save,
                            ),
                          ),
                      ];
                      final deleteActions = [
                        if (enableRecall)
                          MenuAction(
                            image: MenuImage.icon(IconFonts.recall),
                            title: l10n.deleteForEveryone,
                            callback: () async {
                              String? content;
                              if (message.type.isText) {
                                content = message.content;
                              }
                              await ref
                                  .read(accountServerProvider)
                                  .requireValue
                                  .sendRecallMessage([
                                    message.messageId,
                                  ], conversationId: message.conversationId);
                              if (content != null) {
                                ref
                                    .read(recallMessageNotifierProvider)
                                    .onRecalled(message.messageId, content);
                              }
                            },
                          ),
                        if (enableDelete)
                          MenuAction(
                            image: MenuImage.icon(IconFonts.delete),
                            title: l10n.deleteForMe,
                            callback: () => ref
                                .read(accountServerProvider)
                                .requireValue
                                .deleteMessage(message.messageId),
                          ),
                      ];

                      final devActions = [
                        if (!kReleaseMode)
                          MenuAction(
                            image: MenuImage.icon(IconFonts.copy),
                            title: 'Copy message',
                            callback: () => Clipboard.setData(
                              ClipboardData(text: message.toString()),
                            ),
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
                    },
                    builder: (context) {
                      if (message.type.isIllegalMessageCategory ||
                          message.status == MessageStatus.unknown) {
                        return const UnknownMessage();
                      }

                      if (message.status == MessageStatus.failed) {
                        return const WaitingMessage();
                      }

                      if (message.type.isTranscript) {
                        return const TranscriptMessageWidget();
                      }

                      if (message.type.isLocation) {
                        return const LocationMessageWidget();
                      }

                      if (message.type.isPost) {
                        return const PostMessage();
                      }

                      if (message.type ==
                          MessageCategory.systemAccountSnapshot) {
                        return const TransferMessage();
                      }

                      if (message.type == MessageCategory.systemSafeSnapshot) {
                        return const SafeTransferMessage();
                      }

                      if (message.type.isContact) {
                        return const ContactMessageWidget();
                      }

                      if (message.type == MessageCategory.appButtonGroup) {
                        return const ActionMessage();
                      }

                      if (message.type == MessageCategory.appCard) {
                        return const ActionCardMessage();
                      }

                      if (message.type.isData) {
                        return const FileMessage();
                      }

                      if (message.type.isText) {
                        return const TextMessage();
                      }

                      if (message.type.isSticker) {
                        return const StickerMessageWidget();
                      }

                      if (message.type.isImage) {
                        return const ImageMessageWidget();
                      }

                      if (message.type.isVideo || message.type.isLive) {
                        return const VideoMessageWidget();
                      }

                      if (message.type.isAudio) {
                        return const AudioMessage();
                      }

                      if (message.type.isRecall) {
                        return const RecallMessage();
                      }

                      if (message.type ==
                          MessageCategory.systemSafeInscription) {
                        return const InscriptionMessage();
                      }

                      return const UnknownMessage();
                    },
                  ),
                );
              },
            ),
          ),
        ),
        if (message.messageId == lastReadMessageId && next != null)
          const _UnreadMessageBar(),
      ],
    );

    if (message.mentionRead == false) {
      child = VisibilityDetector(
        onVisibilityChanged: (info) {
          if (info.visibleFraction < 1) return;
          ref
              .read(accountServerProvider)
              .requireValue
              .markMentionRead(
                message.messageId,
                message.conversationId,
              );
        },
        key: ValueKey(message.messageId),
        child: child,
      );
    }

    return MessageStyleScope(
      child: FocusScope(
        node: focusNode,
        child: MessageContext(
          isTranscriptPage: isTranscriptPage,
          isPinnedPage: isPinnedPage,
          showNip: showNip,
          isCurrentUser: isCurrentUser,
          message: message,
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => _quickReply(context, ref),
              child: Padding(
                padding: sameUserPrev
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(top: 8),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddImageAsSticker(WidgetRef ref) async {
    await showAddStickerDialog(
      ref.context,
      filepath: ref
          .read(accountServerProvider)
          .requireValue
          .convertMessageAbsolutePath(message, isTranscriptPage),
    );
  }

  Future<void> _onAddSticker(BuildContext context, WidgetRef ref) async {
    showToastLoading();
    try {
      final accountServer = ref.read(accountServerProvider).requireValue;

      final mixinResponse = await accountServer.client.accountApi.addSticker(
        StickerRequest(stickerId: message.stickerId),
      );

      final database = ref.read(databaseProvider).requireValue;

      final personalAlbum = await database.stickerAlbumDao
          .personalAlbum()
          .getSingleOrNull();
      if (personalAlbum == null) {
        unawaited(accountServer.refreshSticker(force: true));
      } else {
        final data = mixinResponse.data;
        await accountServer.insertStickerAndRelationship(
          data.asStickersCompanion,
          StickerRelationship(
            albumId: personalAlbum.albumId,
            stickerId: data.stickerId,
          ),
        );
      }
      showToastSuccessful();
    } catch (_) {
      final l10n = ref.read(localizationProvider);
      showToastFailed(ToastError(l10n.addStickerFailed));
    }
  }
}

class MessageContext extends HookConsumerWidget {
  const MessageContext({
    required this.isTranscriptPage,
    required this.isPinnedPage,
    required this.showNip,
    required this.isCurrentUser,
    required this.message,
    required this.child,
    super.key,
  });

  MessageContext.fromMessageItem({
    required this.message,
    required this.child,
    super.key,
    this.isTranscriptPage = false,
    this.isPinnedPage = false,
    this.showNip = false,
  }) : isCurrentUser = message.relationship == UserRelationship.me;

  final bool isTranscriptPage;
  final bool isPinnedPage;
  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageContext = _MessageContext(
      isTranscriptPage: isTranscriptPage,
      isPinnedPage: isPinnedPage,
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      message: message,
    );
    return _MessageContextScope(value: messageContext, child: child);
  }
}

Future<void> saveAs(
  BuildContext context,
  AccountServer accountServer,
  MessageItem message,
  bool isTranscriptPage, {
  required String confirmButtonText,
}) async {
  final path = accountServer.convertMessageAbsolutePath(
    message,
    isTranscriptPage,
  );
  if (Platform.isAndroid || Platform.isIOS) {
    if (message.type.isImage || message.type.isVideo) {
      try {
        if (message.type.isImage) {
          await Gal.putImage(path);
        } else {
          await Gal.putVideo(path);
        }
        showToastSuccessful();
      } catch (error, s) {
        d('save file error: $error, stack: $s');
        return showToastFailed(error);
      }
    } else {
      await OpenFile.open(path);
    }
  } else {
    try {
      final result = await saveFileToSystem(
        path,
        suggestName: message.mediaName,
        confirmButtonText: confirmButtonText,
      );
      if (result) return showToastSuccessful();
    } catch (error, s) {
      d('save file error: $error, stack: $s');
      return showToastFailed(error);
    }
  }
}

class _MessageBubbleMargin extends HookConsumerWidget {
  const _MessageBubbleMargin({
    required this.isCurrentUser,
    required this.userName,
    required this.userId,
    required this.builder,
    required this.buildMenus,
    required this.pinArrowWidth,
    required this.userAvatarUrl,
    required this.showAvatar,
    required this.isBot,
    required this.isVerified,
  });

  final bool isCurrentUser;
  final String? userName;
  final String? userId;
  final WidgetBuilder builder;
  final MenuProvider buildMenus;
  final double pinArrowWidth;
  final String? userAvatarUrl;
  final bool showAvatar;
  final bool isBot;
  final bool isVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdentityNumber = useMessageConverter(
      converter: (m) => m.userIdentityNumber,
    );
    final membership = useMessageConverter(converter: (m) => m.membership);

    final messageColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (userName != null && userId != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: MessageName(
                  userName: userName!,
                  userId: userId!,
                  userIdentityNumber: userIdentityNumber,
                  membership: membership,
                  isBot: isBot,
                  verified: isVerified,
                ),
              ),
            ],
          ),
        CustomContextMenuWidget(
          hitTestBehavior: HitTestBehavior.translucent,
          menuProvider: buildMenus,
          desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
          child: GestureDetector(
            onTap: () => _quickReply(context, ref),
            child: Builder(builder: builder),
          ),
        ),
      ],
    );

    final needShowAvatar = !isCurrentUser && userName != null;
    if (!showAvatar || !needShowAvatar) {
      return Padding(
        padding: EdgeInsets.only(
          left: isCurrentUser ? 65 - pinArrowWidth : (showAvatar ? 40 : 16),
          right: !isCurrentUser ? 65 - pinArrowWidth : 16,
          top: 2,
          bottom: 2,
        ),
        child: messageColumn,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        InteractiveDecoratedBox(
          onTap: () => showUserDialog(context, ref.container, userId),
          cursor: SystemMouseCursors.click,
          child: AvatarWidget(
            userId: userId,
            name: userName,
            avatarUrl: userAvatarUrl,
            size: 32,
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: messageColumn,
          ),
        ),
        SizedBox(width: 65 - pinArrowWidth),
      ],
    );
  }
}

class _UnreadMessageBar extends ConsumerWidget {
  const _UnreadMessageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    return Container(
      color: theme.background,
      padding: const EdgeInsets.symmetric(vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      child: Text(
        l10n.unreadMessages,
        style: TextStyle(
          color: theme.secondaryText,
          fontSize: context.messageStyle.secondaryFontSize,
        ),
      ),
    );
  }
}

class _MessageSelectionWrapper extends HookConsumerWidget {
  const _MessageSelectionWrapper({required this.child, required this.message});

  final Widget child;

  final MessageItem message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inMultiSelectMode = ref.watch(hasSelectedMessageProvider);

    final selected = ref.watch(
      messageSelectionProvider.select(
        (value) => value.selectedMessageIds.contains(message.messageId),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inMultiSelectMode
          ? () => ref
                .read(messageSelectionProvider.notifier)
                .toggleSelection(message)
          : null,
      child: Row(
        children: [
          _AnimatedSelectionIcon(
            selected: selected,
            inSelectedMode: inMultiSelectMode,
          ),
          Expanded(
            child: IgnorePointer(ignoring: inMultiSelectMode, child: child),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSelectionIcon extends HookConsumerWidget {
  const _AnimatedSelectionIcon({
    required this.selected,
    required this.inSelectedMode,
  });

  final bool selected;

  final bool inSelectedMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final animation = useMemoized(
      () => animationController.drive(
        Tween<double>(
          begin: 0,
          end: 48,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      [animationController],
    );

    useEffect(() {
      if (inSelectedMode) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
    }, [inSelectedMode]);

    useListenable(animation);

    if (animation.isDismissed) {
      return const SizedBox();
    }
    return SizedBox(
      width: animation.value,
      height: 20,
      child: Center(
        child: ClipOval(
          child: Container(
            color: selected ? theme.accent : theme.secondaryText,
            height: 16,
            width: 16,
            alignment: const Alignment(0, -0.2),
            child: SvgPicture.asset(
              Resources.assetsImagesSelectedSvg,
              height: 10,
              width: 10,
            ),
          ),
        ),
      ),
    );
  }
}
