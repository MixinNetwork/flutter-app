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
import 'package:hooks_riverpod/hooks_riverpod.dart' hide Provider;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../account/account_server.dart';
import '../../ai/ai_chat_controller.dart';
import '../../blaze/vo/pin_message_minimal.dart';
import '../../bloc/simple_cubit.dart';
import '../../constants/icon_fonts.dart';
import '../../constants/resources.dart';
import '../../db/dao/sticker_dao.dart';
import '../../db/mixin_database.dart' hide Message, Offset;
import '../../enum/media_status.dart';
import '../../enum/message_category.dart';
import '../../ui/home/bloc/blink_cubit.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../ui/provider/is_bot_group_provider.dart';
import '../../ui/provider/message_selection_provider.dart';
import '../../ui/provider/quote_message_provider.dart';
import '../../ui/provider/recall_message_reedit_provider.dart';
import '../../ui/provider/setting_provider.dart';
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
      converter: (state) => state.isTranscriptPage,
    );

bool useIsPinnedPage() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
      converter: (state) => state.isPinnedPage,
    );

bool useShowNip() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
      converter: (state) => state.showNip,
    );

bool useIsCurrentUser() =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, bool>(
      converter: (state) => state.isCurrentUser,
    );

MessageItem useMessage() =>
    useMessageConverter<MessageItem>(converter: (state) => state);

T useMessageConverter<T>({required T Function(MessageItem) converter}) =>
    useBlocStateConverter<_MessageContextCubit, _MessageContext, T>(
      converter: (state) => converter(state.message),
    );

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
    context.providerContainer.read(quoteMessageProvider.notifier).state =
        context.message;
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

enum _MessageAiAction { translate, explain, suggestReplies }

class _InlineMessageAiState with EquatableMixin {
  const _InlineMessageAiState({this.entries = const {}});

  final Map<_MessageAiAction, _InlineMessageAiEntry> entries;

  _InlineMessageAiState put(
    _MessageAiAction action,
    _InlineMessageAiEntry entry,
  ) => _InlineMessageAiState(
    entries: Map<_MessageAiAction, _InlineMessageAiEntry>.from(entries)
      ..[action] = entry,
  );

  _InlineMessageAiEntry? operator [](_MessageAiAction action) =>
      entries[action];

  bool get hasVisibleEntry =>
      entries.values.any((entry) => entry.loading || entry.hasContent);

  @override
  List<Object?> get props => [entries];
}

class _InlineMessageAiEntry with EquatableMixin {
  const _InlineMessageAiEntry({
    this.loading = false,
    this.result,
    this.error,
  });

  final bool loading;
  final String? result;
  final String? error;

  bool get hasContent =>
      (result != null && result!.trim().isNotEmpty) ||
      (error != null && error!.trim().isNotEmpty);

  @override
  List<Object?> get props => [loading, result, error];
}

String? _messageAiText(MessageItem message) {
  final content = message.content?.trim();
  if ((message.type.isText || message.type.isPost) &&
      content != null &&
      content.isNotEmpty) {
    return content;
  }

  final caption = message.caption?.trim();
  if (caption != null && caption.isNotEmpty) {
    return caption;
  }
  return null;
}

Future<void> _runMessageAiAction(
  BuildContext context, {
  required MessageItem message,
  required String input,
  required _MessageAiAction action,
  required void Function(_MessageAiAction, _InlineMessageAiEntry)
  onStateChanged,
}) async {
  final language = _currentLanguageTag(context);
  final instruction = switch (action) {
    _MessageAiAction.translate =>
      'Translate this chat message into $language. Return only the translation.',
    _MessageAiAction.explain =>
      'Explain this chat message clearly and concisely. Clarify slang, abbreviations, technical terms, and implied meaning when useful.',
    _MessageAiAction.suggestReplies =>
      'Suggest three concise, natural replies to this chat message using the recent conversation context. Return one reply per line, without numbering.',
  };
  final title = switch (action) {
    _MessageAiAction.translate => 'Translate',
    _MessageAiAction.explain => 'Explain',
    _MessageAiAction.suggestReplies => 'Suggest replies',
  };

  onStateChanged(action, const _InlineMessageAiEntry(loading: true));
  try {
    final result = await AiChatController(context.database).assistText(
      instruction: instruction,
      input: input,
      conversationId: message.conversationId,
    );
    if (!context.mounted) return;
    onStateChanged(
      action,
      _InlineMessageAiEntry(result: result.trim()),
    );
  } catch (error, stackTrace) {
    e('AI message assist failed: $error, $stackTrace');
    if (!context.mounted) return;
    onStateChanged(
      action,
      _InlineMessageAiEntry(error: '$title failed: $error'),
    );
  }
}

String _currentLanguageTag(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final countryCode = locale.countryCode;
  if (countryCode == null || countryCode.isEmpty) return locale.languageCode;
  return '${locale.languageCode}-$countryCode';
}

List<String> _parseAiReplySuggestions(String result) => result
    .split('\n')
    .map((line) => line.trim().replaceFirst(RegExp(r'^[-*\d.)\s]+'), ''))
    .where((line) => line.isNotEmpty)
    .take(3)
    .toList(growable: false);

class MessageItemWidget extends HookConsumerWidget {
  const MessageItemWidget({
    required this.message,
    super.key,
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
  Widget build(BuildContext context, WidgetRef ref) {
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

    final showedMenuCubit = useBloc(() => SimpleCubit(false));
    final focusNode = useFocusScopeNode(
      debugLabel: 'message_item_${message.messageId}',
    );

    final blinkCubit = context.read<BlinkCubit>();

    final blinkColor =
        useMemoizedStream(
          () => Rx.combineLatest2(
            blinkCubit.stream.startWith(blinkCubit.state),
            showedMenuCubit.stream.startWith(showedMenuCubit.state),
            (blinkState, showedMenu) {
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
    final inlineAiState = useState(const _InlineMessageAiState());

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
                  isBot: message.isBot,
                  isVerified: message.isVerified,
                  aiSection: _InlineMessageAiSection(
                    state: inlineAiState.value,
                  ),
                  buildMenus: (request) {
                    request.onShowMenu.addListener(() {
                      showedMenuCubit.emit(true);
                      focusNode.requestFocus();
                    });
                    request.onHideMenu.addListener(() {
                      showedMenuCubit.emit(false);
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
                    final enableRecall = !isTranscriptPage && message.canRecall;

                    final enableDelete = !isTranscriptPage && !isPinnedPage;

                    final addStickerMenuAction = [
                      if (message.type.isSticker)
                        MenuAction(
                          image: MenuImage.icon(IconFonts.sticker),
                          title: context.l10n.addSticker,
                          callback: () => _onAddSticker(context),
                        ),
                      if (message.type.isImage && message.canForward)
                        MenuAction(
                          image: MenuImage.icon(IconFonts.sticker),
                          title: context.l10n.addSticker,
                          callback: () => _onAddImageAsSticker(context),
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
                              .selectMessage(message),
                        ),
                      if (pinEnabled)
                        MenuAction(
                          image: MenuImage.icon(
                            message.pinned ? IconFonts.unPin : IconFonts.pin,
                          ),
                          title: message.pinned
                              ? context.l10n.unpin
                              : context.l10n.pinTitle,
                          callback: () async {
                            final pinMessageMinimal = PinMessageMinimal(
                              messageId: message.messageId,
                              type: message.type,
                              content: message.type.isText
                                  ? message.content
                                  : null,
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
                              title: context.l10n.copyText,
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
                                ? context.l10n.copy
                                : context.l10n.copySelectedText,
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
                            title: context.l10n.generateQrcode,
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
                            title: context.l10n.copySelectedText,
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
                          callback: () => context.accountServer.deleteMessage(
                            message.messageId,
                          ),
                        ),
                    ];

                    final aiText = _messageAiText(message);
                    final aiActions = [
                      if (aiText != null)
                        MenuAction(
                          image: MenuImage.icon(Icons.translate),
                          title: 'Translate',
                          callback: () => unawaited(
                            _runMessageAiAction(
                              context,
                              message: message,
                              input: aiText,
                              action: _MessageAiAction.translate,
                              onStateChanged: (action, entry) {
                                inlineAiState.value = inlineAiState.value.put(
                                  action,
                                  entry,
                                );
                              },
                            ),
                          ),
                        ),
                      if (aiText != null)
                        MenuAction(
                          image: MenuImage.icon(Icons.psychology_alt),
                          title: 'Explain',
                          callback: () => unawaited(
                            _runMessageAiAction(
                              context,
                              message: message,
                              input: aiText,
                              action: _MessageAiAction.explain,
                              onStateChanged: (action, entry) {
                                inlineAiState.value = inlineAiState.value.put(
                                  action,
                                  entry,
                                );
                              },
                            ),
                          ),
                        ),
                      if (aiText != null && !isTranscriptPage)
                        MenuAction(
                          image: MenuImage.icon(Icons.auto_awesome),
                          title: 'Suggest replies',
                          callback: () => unawaited(
                            _runMessageAiAction(
                              context,
                              message: message,
                              input: aiText,
                              action: _MessageAiAction.suggestReplies,
                              onStateChanged: (action, entry) {
                                inlineAiState.value = inlineAiState.value.put(
                                  action,
                                  entry,
                                );
                              },
                            ),
                          ),
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
                        aiActions,
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

                    if (message.type == MessageCategory.systemAccountSnapshot) {
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

                    if (message.type == MessageCategory.systemSafeInscription) {
                      return const InscriptionMessage();
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
        onVisibilityChanged: (info) {
          if (info.visibleFraction < 1) return;
          context.accountServer.markMentionRead(
            message.messageId,
            message.conversationId,
          );
        },
        key: ValueKey(message.messageId),
        child: child,
      );
    }

    return FocusScope(
      node: focusNode,
      child: MessageContext(
        isTranscriptPage: isTranscriptPage,
        isPinnedPage: isPinnedPage,
        showNip: showNip,
        isCurrentUser: isCurrentUser,
        message: message,
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: () => _quickReply(context),
            child: Padding(
              padding: sameUserPrev
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(top: 8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddImageAsSticker(BuildContext context) async {
    await showAddStickerDialog(
      context,
      filepath: context.accountServer.convertMessageAbsolutePath(
        message,
        isTranscriptPage,
      ),
    );
  }

  Future<void> _onAddSticker(BuildContext context) async {
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
    _MessageContext newMessageContext() => _MessageContext(
      isTranscriptPage: isTranscriptPage,
      isPinnedPage: isPinnedPage,
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      message: message,
    );

    final messageContextCubit = useBloc(
      () => _MessageContextCubit(newMessageContext()),
    );

    useEffect(() {
      messageContextCubit.emit(newMessageContext());
    }, [isTranscriptPage, isPinnedPage, showNip, isCurrentUser, message]);

    return Provider.value(value: messageContextCubit, child: child);
  }
}

Future<void> saveAs(
  BuildContext context,
  AccountServer accountServer,
  MessageItem message,
  bool isTranscriptPage,
) async {
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
        context,
        path,
        suggestName: message.mediaName,
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
    required this.aiSection,
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
  final Widget aiSection;

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
            onTap: () => _quickReply(context),
            child: Builder(builder: builder),
          ),
        ),
        aiSection,
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

class _InlineMessageAiSection extends StatelessWidget {
  const _InlineMessageAiSection({required this.state});

  final _InlineMessageAiState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasVisibleEntry) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      for (final action in _MessageAiAction.values)
        if (state[action]?.loading == true || state[action]?.hasContent == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _InlineMessageAiCard(
              action: action,
              entry: state[action]!,
            ),
          ),
    ];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _InlineMessageAiCard extends StatelessWidget {
  const _InlineMessageAiCard({
    required this.action,
    required this.entry,
  });

  final _MessageAiAction action;
  final _InlineMessageAiEntry entry;

  @override
  Widget build(BuildContext context) {
    final title = switch (action) {
      _MessageAiAction.translate => 'Translation',
      _MessageAiAction.explain => 'Explanation',
      _MessageAiAction.suggestReplies => 'Suggested replies',
    };
    final loadingText = switch (action) {
      _MessageAiAction.translate => 'Translating...',
      _MessageAiAction.explain => 'Explaining...',
      _MessageAiAction.suggestReplies => 'Generating replies...',
    };

    Widget content;
    if (entry.loading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: context.theme.secondaryText,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            loadingText,
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      );
    } else if (entry.error?.isNotEmpty == true) {
      content = Text(
        entry.error!,
        style: TextStyle(
          color: context.theme.red,
          fontSize: 13,
          height: 1.45,
        ),
      );
    } else if (action == _MessageAiAction.suggestReplies) {
      content = _InlineReplySuggestions(result: entry.result ?? '');
    } else {
      content = SelectableText(
        entry.result ?? '',
        style: TextStyle(
          color: context.theme.text,
          fontSize: 13,
          height: 1.45,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.dynamicColor(
          const Color.fromRGBO(245, 247, 250, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
}

class _InlineReplySuggestions extends StatelessWidget {
  const _InlineReplySuggestions({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    final replies = _parseAiReplySuggestions(result);
    if (replies.isEmpty) {
      return SelectableText(
        result,
        style: TextStyle(
          color: context.theme.text,
          fontSize: 13,
          height: 1.45,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < replies.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == replies.length - 1 ? 0 : 6),
            child: _InlineReplyButton(reply: replies[i]),
          ),
      ],
    );
  }
}

class _InlineReplyButton extends StatelessWidget {
  const _InlineReplyButton({required this.reply});

  final String reply;

  @override
  Widget build(BuildContext context) => InteractiveDecoratedBox(
    onTap: () => context.providerContainer
        .read(recallMessageNotifierProvider)
        .onReedit(reply),
    decoration: BoxDecoration(
      color: context.dynamicColor(
        const Color.fromRGBO(255, 255, 255, 0.92),
        darkColor: const Color.fromRGBO(255, 255, 255, 0.04),
      ),
      borderRadius: const BorderRadius.all(Radius.circular(6)),
    ),
    hoveringDecoration: BoxDecoration(
      color: context.dynamicColor(
        const Color.fromRGBO(0, 0, 0, 0.03),
        darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
      ),
      borderRadius: const BorderRadius.all(Radius.circular(6)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        reply,
        style: TextStyle(
          color: context.theme.text,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    ),
  );
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
        fontSize: context.messageStyle.secondaryFontSize,
      ),
    ),
  );
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
          ? () => ref.read(messageSelectionProvider).toggleSelection(message)
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
            color: selected
                ? context.theme.accent
                : context.theme.secondaryText,
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
