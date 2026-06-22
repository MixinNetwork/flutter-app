import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    hide ChangeNotifierProvider, Provider;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide Key;
import 'package:provider/provider.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../constants/resources.dart';
import '../../db/mixin_database.dart' hide Message, Offset;
import '../../enum/message_category.dart';
import '../../ui/home/notifier/blink_notifier.dart';
import '../../ui/provider/is_bot_group_provider.dart';
import '../../ui/provider/message_selection_provider.dart';
import '../../ui/provider/quote_message_provider.dart';
import '../../ui/provider/setting_provider.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/double_tap_util.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../avatar_view/avatar_view.dart';
import '../interactive_decorated_box.dart';
import '../menu.dart';
import '../user/user_dialog.dart';
import 'item/pin_message.dart';
import 'item/secret_message.dart';
import 'item/stranger_message.dart';
import 'item/system_message.dart';
import 'message_actions_menu.dart';
import 'message_content.dart';
import 'message_day_time.dart';
import 'message_name.dart';
import 'message_style.dart';

export 'message_file_actions.dart';

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

class MessageRowModel {
  MessageRowModel({
    required this.message,
    this.prev,
    this.next,
  }) : sameDayPrev = isSameDay(prev?.createdAt, message.createdAt),
       sameDayNext = isSameDay(next?.createdAt, message.createdAt),
       prevIsSystem = prev?.type.isSystem ?? false,
       prevIsPin = prev?.type.isPin ?? false,
       sameUserNext = next?.userId == message.userId {
    sameUserPrev =
        !prevIsSystem && !prevIsPin && prev?.userId == message.userId;
    dateTime = sameDayPrev ? null : message.createdAt;
  }

  final MessageItem message;
  final MessageItem? prev;
  final MessageItem? next;
  final bool sameDayPrev;
  final bool sameDayNext;
  final bool prevIsSystem;
  final bool prevIsPin;
  late final bool sameUserPrev;
  final bool sameUserNext;
  late final DateTime? dateTime;
}

bool useIsTranscriptPage() =>
    _useMessageContextConverter((state) => state.isTranscriptPage);

bool useIsPinnedPage() =>
    _useMessageContextConverter((state) => state.isPinnedPage);

bool useShowNip() => _useMessageContextConverter((state) => state.showNip);

bool useIsCurrentUser() =>
    _useMessageContextConverter((state) => state.isCurrentUser);

MessageItem useMessage() =>
    useMessageConverter<MessageItem>(converter: (state) => state);

T useMessageConverter<T>({required T Function(MessageItem) converter}) =>
    _useMessageContextConverter((state) => converter(state.message));

T _useMessageContextConverter<T>(T Function(_MessageContext) converter) {
  final notifier = useContext().read<ValueNotifier<_MessageContext>>();
  return useListenableConverter<ValueNotifier<_MessageContext>, T>(
        notifier,
        converter: (notifier) => converter(notifier.value),
      ).data
      as T;
}

extension MessageContextExtension on BuildContext {
  _MessageContext get _messageContext =>
      read<ValueNotifier<_MessageContext>>().value;

  MessageItem get message => _messageContext.message;

  bool get isPinnedPage => _messageContext.isPinnedPage;

  bool get isTranscriptPage => _messageContext.isTranscriptPage;
}

const _pinArrowWidth = 32.0;

void _quickReply(BuildContext context) {
  if (context.isPinnedPage) return;
  if (context.isTranscriptPage) return;
  if (!context.message.type.canReply) return;

  doubleTap('_quickReply', const Duration(milliseconds: 300), () {
    context.read<BlinkNotifier>().blinkByMessageId(context.message.messageId);
    context.providerContainer.read(quoteMessageProvider.notifier).state =
        context.message;
  });
}

class MessageItemWidget extends HookConsumerWidget {
  const MessageItemWidget({
    required this.message,
    super.key,
    this.prev,
    this.next,
    this.row,
    this.lastReadMessageId,
    this.isTranscriptPage = false,
    this.blink = true,
    this.isPinnedPage = false,
    this.dateTimeKey,
  });

  final MessageItem message;
  final MessageItem? prev;
  final MessageItem? next;
  final MessageRowModel? row;
  final String? lastReadMessageId;
  final bool isTranscriptPage;
  final bool blink;
  final bool isPinnedPage;
  final Key? dateTimeKey;

  static const primaryFontSize = 16.0;
  static const secondaryFontSize = 14.0;
  static const tertiaryFontSize = 12.0;

  static const statusFontSize = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row =
        this.row ??
        MessageRowModel(message: this.message, prev: prev, next: next);
    final message = row.message;
    final isCurrentUser = message.relationship == UserRelationship.me;

    final isGroupOrBotGroupConversation =
        message.conversionCategory == ConversationCategory.group ||
        message.userId != message.conversationOwnerId ||
        ref.watch(isBotGroupProvider(message.conversationId));

    final enableShowAvatar = ref.watch(
      settingProvider.select((value) => value.messageShowAvatar),
    );
    final showAvatar = isGroupOrBotGroupConversation && enableShowAvatar;

    final showNip =
        !(row.sameUserNext && row.sameDayNext) &&
        (!showAvatar || isCurrentUser);
    final datetime = row.dateTime;
    String? userName;
    String? userId;
    String? userAvatarUrl;

    if (isGroupOrBotGroupConversation &&
        !isCurrentUser &&
        (!row.sameUserPrev || !row.sameDayPrev)) {
      userName = message.userFullName;
      userId = message.userId;
      userAvatarUrl = message.avatarUrl;
    }

    final showedMenu = useState(false);
    final focusNode = useFocusScopeNode(
      debugLabel: 'message_item_${message.messageId}',
    );

    final blinkNotifier = context.read<BlinkNotifier>();
    final blinkState = useValueListenable(blinkNotifier);

    final blinkColor = showedMenu.value
        ? context.theme.listSelected
        : blinkState.messageId == message.messageId && blink
        ? blinkState.color
        : Colors.transparent;

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (datetime != null)
          MessageDayTime(key: dateTimeKey, dateTime: datetime),
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
                  buildMenus: (request) => buildMessageActionsMenu(
                    context: context,
                    ref: ref,
                    request: request,
                    message: message,
                    isTranscriptPage: isTranscriptPage,
                    isPinnedPage: isPinnedPage,
                    showedMenu: showedMenu,
                    focusNode: focusNode,
                  ),
                  builder: (_) => MessageContent(message: message),
                ),
              );
            },
          ),
        ),
        if (message.messageId == lastReadMessageId && row.next != null)
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
              padding: row.sameUserPrev
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(top: 8),
              child: child,
            ),
          ),
        ),
      ),
    );
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

    final messageContext = useMemoized(
      () => ValueNotifier(newMessageContext()),
    );
    useEffect(() => messageContext.dispose, [messageContext]);

    useEffect(() {
      messageContext.value = newMessageContext();
      return null;
    }, [isTranscriptPage, isPinnedPage, showNip, isCurrentUser, message]);

    return ChangeNotifierProvider<ValueNotifier<_MessageContext>>.value(
      value: messageContext,
      child: child,
    );
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
            onTap: () => _quickReply(context),
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
