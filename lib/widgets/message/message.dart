import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../account/account_server.dart';
import '../../blaze/vo/pin_message_minimal.dart';
import '../../bloc/setting_cubit.dart';
import '../../bloc/simple_cubit.dart';
import '../../constants/resources.dart';
import '../../db/dao/sticker_dao.dart';
import '../../db/mixin_database.dart' hide Offset, Message;
import '../../enum/media_status.dart';
import '../../enum/message_category.dart';
import '../../ui/home/bloc/blink_cubit.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../ui/home/bloc/message_selection_cubit.dart';
import '../../ui/home/bloc/quote_message_cubit.dart';
import '../../ui/home/bloc/recall_message_bloc.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/double_tap_util.dart';
import '../../utils/extension/extension.dart';
import '../../utils/file.dart';
import '../../utils/hook.dart';
import '../../utils/platform.dart';
import '../avatar_view/avatar_view.dart';
import '../interactive_decorated_box.dart';
import '../menu.dart';
import '../toast.dart';
import '../user/user_dialog.dart';
import '../user_selector/conversation_selector.dart';
import 'item/action/action_message.dart';
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
import 'item/text/text_message.dart';
import 'item/transcript_message.dart';
import 'item/transfer/transfer_message.dart';
import 'item/unknown_message.dart';
import 'item/video_message.dart';
import 'item/waiting_message.dart';
import 'message_day_time.dart';
import 'message_name.dart';

class _MessageContextCubit extends SimpleCubit<_MessageContext> {
  _MessageContextCubit(super.initialState);
}

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

bool useIsTranscriptPage() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
        converter: (state) => state.isTranscriptPage);

bool useIsPinnedPage() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
        converter: (state) => state.isPinnedPage);

bool useShowNip() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
        converter: (state) => state.showNip);

bool useIsCurrentUser() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
        converter: (state) => state.isCurrentUser);

MessageItem useMessage() =>
    useMessageConverter<MessageItem>(converter: (state) => state);

T useMessageConverter<T>({required T Function(MessageItem) converter}) =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, T>(
        converter: (state) => converter(state.message));

extension MessageContextExtension on BuildContext {
  MessageItem get message => read<_MessageContextCubit>().state.message;

  bool get isPinnedPage => read<_MessageContextCubit>().state.isPinnedPage;

  bool get isTranscriptPage =>
      read<_MessageContextCubit>().state.isTranscriptPage;
}

const _pinArrowWidth = 32.0;

void _quickReply(BuildContext context) {
  if (context.isPinnedPage) return;
  if (context.isTranscriptPage) return;
  if (!context.message.type.canReply) return;

  doubleTap('_quickReply', const Duration(milliseconds: 300), () {
    context.read<BlinkCubit>().blinkByMessageId(context.message.messageId);
    context.read<QuoteMessageCubit>().emit(context.message);
  });
}

class MessageItemWidget extends HookWidget {
  const MessageItemWidget({
    super.key,
    required this.message,
    this.prev,
    this.next,
    this.lastReadMessageId,
    this.isTranscriptPage = false,
    this.blink = true,
    this.isPinnedPage = false,
  });

  final MessageItem message;
  final MessageItem? prev;
  final MessageItem? next;
  final String? lastReadMessageId;
  final bool isTranscriptPage;
  final bool blink;
  final bool isPinnedPage;

  static const primaryFontSize = 16.0;
  static const secondaryFontSize = 14.0;
  static const tertiaryFontSize = 12.0;

  static const statusFontSize = 10.0;

  @override
  Widget build(BuildContext context) {
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
            message.userId != message.conversationOwnerId;

    final enableShowAvatar =
        useBlocStateConverter<SettingCubit, SettingState, bool>(
      converter: (style) => style.messageShowAvatar,
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

    final showedMenuCubit = useBloc(() => SimpleCubit(false));

    final blinkCubit = context.read<BlinkCubit>();

    final blinkColor = useMemoizedStream(
          () => Rx.combineLatest2(
            blinkCubit.stream.startWith(blinkCubit.state),
            showedMenuCubit.stream.startWith(showedMenuCubit.state),
            (BlinkState blinkState, bool showedMenu) {
              if (showedMenu) return context.theme.listSelected;
              if (blinkState.messageId == message.messageId && blink) {
                return blinkState.color;
              }
              return Colors.transparent;
            },
          ),
          keys: [message.messageId],
        ).data ??
        Colors.transparent;

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (datetime != null) MessageDayTime(dateTime: datetime),
        ColoredBox(
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
                  showedMenu: showedMenuCubit.emit,
                  buildMenus: () => [
                    if (message.type.isSticker)
                      ContextMenu(
                        icon: Resources.assetsImagesContextMenuStickerSvg,
                        title: context.l10n.addSticker,
                        onTap: () => _onAddSticker(context),
                      ),
                    if (!isTranscriptPage &&
                        message.type.canReply &&
                        !isPinnedPage)
                      ContextMenu(
                        icon: Resources.assetsImagesContextMenuReplySvg,
                        title: context.l10n.reply,
                        onTap: () =>
                            context.read<QuoteMessageCubit>().emit(message),
                      ),
                    if (!isTranscriptPage &&
                        message.type.canReply &&
                        const [
                          MessageStatus.delivered,
                          MessageStatus.read,
                          MessageStatus.sent
                        ].contains(message.status))
                      _PinMenu(message: message),
                    if (!isTranscriptPage && message.canForward)
                      ContextMenu(
                        icon: Resources.assetsImagesContextMenuForwardSvg,
                        title: context.l10n.forward,
                        onTap: () async {
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
                    if (!isTranscriptPage)
                      ContextMenu(
                        icon: Resources.assetsImagesMultiSelectionSvg,
                        title: context.l10n.select,
                        onTap: () => context
                            .read<MessageSelectionCubit>()
                            .selectMessage(message),
                      ),
                    if (message.type.isText || message.type.isPost)
                      ContextMenu(
                        icon: Resources.assetsImagesContextMenuCopySvg,
                        title: context.l10n.copy,
                        onTap: () => Clipboard.setData(
                            ClipboardData(text: message.content)),
                      ),
                    if (kPlatformIsMobile &&
                        (message.type.isImage || message.type.isVideo))
                      ContextMenu(
                        icon: Resources.assetsImagesContextMenuDownloadSvg,
                        title: context.l10n.saveToCameraRoll,
                        onTap: () => saveAs(context, context.accountServer,
                            message, isTranscriptPage),
                      ),
                    if (kPlatformIsDesktop &&
                        message.mediaStatus == MediaStatus.done &&
                        message.mediaUrl?.isNotEmpty == true &&
                        (message.type.isData ||
                            message.type.isImage ||
                            message.type.isVideo ||
                            message.type.isAudio)) ...[
                      ContextMenu(
                        icon: Resources.assetsImagesContextMenuDownloadSvg,
                        title: context.l10n.saveAs,
                        onTap: () => saveAs(context, context.accountServer,
                            message, isTranscriptPage),
                      ),
                    ],
                    if ([
                          MessageStatus.sent,
                          MessageStatus.delivered,
                          MessageStatus.read,
                        ].contains(message.status) &&
                        !isTranscriptPage &&
                        isCurrentUser &&
                        message.type.canRecall &&
                        DateTime.now().isBefore(
                            message.createdAt.add(const Duration(minutes: 30))))
                      ContextMenu(
                        icon: Resources.assetsImagesContextMenuRecallSvg,
                        title: context.l10n.deleteForEveryone,
                        isDestructiveAction: true,
                        onTap: () async {
                          String? content;
                          if (message.type.isText) {
                            content = message.content;
                          }
                          await context.accountServer.sendRecallMessage(
                            [message.messageId],
                            conversationId: message.conversationId,
                          );
                          if (content != null) {
                            context
                                .read<RecallMessageReeditCubit>()
                                .onRecalled(message.messageId, content);
                          }
                        },
                      ),
                    if (!isTranscriptPage)
                      ContextMenu(
                        icon: Resources.assetsImagesContextMenuDeleteSvg,
                        title: context.l10n.deleteForMe,
                        isDestructiveAction: true,
                        onTap: () => context.accountServer
                            .deleteMessage(message.messageId),
                      ),
                    if (!kReleaseMode)
                      ContextMenu(
                        icon: Resources.assetsImagesContextMenuCopySvg,
                        title: 'Copy message',
                        onTap: () => Clipboard.setData(
                            ClipboardData(text: message.toString())),
                      ),
                  ],
                  builder: (BuildContext context) {
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

                    if (message.type == MessageCategory.systemAccountSnapshot) {
                      return const TransferMessage();
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

                    return const UnknownMessage();
                  },
                ),
              );
            },
          ),
        ),
        if (message.messageId == lastReadMessageId && next != null)
          const _UnreadMessageBar(),
      ],
    );

    if (message.mentionRead == false) {
      child = VisibilityDetector(
        onVisibilityChanged: (VisibilityInfo info) {
          if (info.visibleFraction < 1) return;
          context.accountServer
              .markMentionRead(message.messageId, message.conversationId);
        },
        key: ValueKey(message.messageId),
        child: child,
      );
    }

    return MessageContext(
      isTranscriptPage: isTranscriptPage,
      isPinnedPage: isPinnedPage,
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      message: message,
      child: Builder(
        builder: (context) => GestureDetector(
          onTap: () => _quickReply(context),
          child: Padding(
            padding:
                sameUserPrev ? EdgeInsets.zero : const EdgeInsets.only(top: 8),
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> _onAddSticker(BuildContext context) async {
    showToastLoading(context);
    try {
      final accountServer = context.accountServer;

      final mixinResponse = await accountServer.client.accountApi.addSticker(
        StickerRequest(
          stickerId: message.stickerId,
        ),
      );

      final database = context.database;

      final personalAlbum =
          await database.stickerAlbumDao.personalAlbum().getSingleOrNull();
      if (personalAlbum == null) {
        unawaited(accountServer.refreshSticker(force: true));
      } else {
        final data = mixinResponse.data;
        await database.mixinDatabase.transaction(() async {
          await database.stickerDao.insert(data.asStickersCompanion);
          await database.stickerRelationshipDao.insert(StickerRelationship(
            albumId: personalAlbum.albumId,
            stickerId: data.stickerId,
          ));
        });
      }
      showToastSuccessful(context);
    } catch (_) {
      await showToastFailed(context, ToastError(context.l10n.addStickerFailed));
    }
  }
}

class MessageContext extends HookWidget {
  const MessageContext({
    super.key,
    required this.isTranscriptPage,
    required this.isPinnedPage,
    required this.showNip,
    required this.isCurrentUser,
    required this.message,
    required this.child,
  });

  MessageContext.fromMessageItem({
    super.key,
    required this.message,
    required this.child,
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
  Widget build(BuildContext context) {
    _MessageContext newMessageContext() => _MessageContext(
          isTranscriptPage: isTranscriptPage,
          isPinnedPage: isPinnedPage,
          showNip: showNip,
          isCurrentUser: isCurrentUser,
          message: message,
        );

    final messageContextCubit =
        useBloc(() => _MessageContextCubit(newMessageContext()));

    useEffect(() {
      messageContextCubit.emit(newMessageContext());
    }, [isTranscriptPage, isPinnedPage, showNip, isCurrentUser, message]);

    return Provider.value(
      value: messageContextCubit,
      child: child,
    );
  }
}

Future<void> saveAs(BuildContext context, AccountServer accountServer,
    MessageItem message, bool isTranscriptPage) async {
  final path =
      accountServer.convertMessageAbsolutePath(message, isTranscriptPage);
  if (Platform.isAndroid || Platform.isIOS) {
    if (message.type.isImage || message.type.isVideo) {
      final result = message.type.isImage
          ? await GallerySaver.saveImage(path)
          : await GallerySaver.saveVideo(path);
      if (result != true) {
        return showToastFailed(context, null);
      } else {
        showToastSuccessful(context);
        return;
      }
    } else {
      await OpenFile.open(path);
    }
  } else {
    try {
      final result = await saveFileToSystem(
        context,
        path,
        suggestName: message.mediaName,
      );
      if (result) return showToastSuccessful(context);
    } catch (error) {
      return showToastFailed(context, error);
    }
  }
}

class _PinMenu extends HookWidget {
  const _PinMenu({
    required this.message,
  });

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final role = useBlocStateConverter<ConversationCubit, ConversationState?,
        ParticipantRole?>(
      converter: (state) => state?.role,
    );

    if (role == null ||
        [MessageStatus.failed, MessageStatus.unknown, MessageStatus.sending]
            .contains(message.status)) return const SizedBox();

    return ContextMenu(
      icon: message.pinned
          ? Resources.assetsImagesContextMenuUnpinSvg
          : Resources.assetsImagesContextMenuPinSvg,
      title: message.pinned ? context.l10n.unpin : context.l10n.pinTitle,
      onTap: () async {
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
    );
  }
}

class _MessageBubbleMargin extends HookWidget {
  const _MessageBubbleMargin({
    required this.isCurrentUser,
    required this.userName,
    required this.userId,
    required this.builder,
    required this.buildMenus,
    required this.pinArrowWidth,
    this.showedMenu,
    required this.userAvatarUrl,
    required this.showAvatar,
  });

  final bool isCurrentUser;
  final String? userName;
  final String? userId;
  final WidgetBuilder builder;
  final List<Widget> Function() buildMenus;
  final double pinArrowWidth;
  final ValueChanged<bool>? showedMenu;
  final String? userAvatarUrl;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final inMultiSelectMode = useBlocStateConverter<MessageSelectionCubit,
        MessageSelectionState, bool>(
      converter: (state) => state.hasSelectedMessage,
    );

    final messageColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (userName != null && userId != null)
          MessageName(
            userName: userName!,
            userId: userId!,
          ),
        ContextMenuPortalEntry(
          buildMenus: buildMenus,
          showedMenu: showedMenu,
          enable: !inMultiSelectMode,
          onTap: () => _quickReply(context),
          child: Builder(builder: builder),
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
          onTap: () => showUserDialog(context, userId),
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

class _UnreadMessageBar extends StatelessWidget {
  const _UnreadMessageBar();

  @override
  Widget build(BuildContext context) => Container(
        color: context.theme.background,
        padding: const EdgeInsets.symmetric(vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        child: Text(
          context.l10n.unreadMessages,
          style: TextStyle(
            color: context.theme.secondaryText,
            fontSize: MessageItemWidget.secondaryFontSize,
          ),
        ),
      );
}

class _MessageSelectionWrapper extends HookWidget {
  const _MessageSelectionWrapper({
    required this.child,
    required this.message,
  });

  final Widget child;

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final inMultiSelectMode = useBlocStateConverter<MessageSelectionCubit,
        MessageSelectionState, bool>(
      converter: (state) => state.hasSelectedMessage,
    );

    final selected = useBlocStateConverter<MessageSelectionCubit,
        MessageSelectionState, bool>(
      converter: (state) =>
          state.selectedMessageIds.contains(message.messageId),
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inMultiSelectMode
          ? () => context.read<MessageSelectionCubit>().toggleSelection(message)
          : null,
      child: Row(
        children: [
          _AnimatedSelectionIcon(
            selected: selected,
            inSelectedMode: inMultiSelectMode,
          ),
          Expanded(
            child: IgnorePointer(
              ignoring: inMultiSelectMode,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSelectionIcon extends HookWidget {
  const _AnimatedSelectionIcon({
    required this.selected,
    required this.inSelectedMode,
  });

  final bool selected;

  final bool inSelectedMode;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final animation = useMemoized(
        () => animationController.drive(
              Tween<double>(
                begin: 0,
                end: 48,
              ).chain(
                CurveTween(
                  curve: Curves.easeInOut,
                ),
              ),
            ),
        [animationController]);

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
            color:
                selected ? context.theme.accent : context.theme.secondaryText,
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
