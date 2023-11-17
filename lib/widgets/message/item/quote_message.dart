import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/resources.dart';
import '../../../db/extension/message.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../ui/home/bloc/blink_cubit.dart';
import '../../../ui/home/bloc/message_bloc.dart';
import '../../../ui/provider/conversation_provider.dart';
import '../../../ui/provider/mention_cache_provider.dart';
import '../../../ui/provider/pending_jump_message_provider.dart';
import '../../../utils/color_utils.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/logger.dart';
import '../../avatar_view/avatar_view.dart';
import '../../cache_image.dart';
import '../../high_light_text.dart';
import '../../image.dart';
import '../../sticker_page/sticker_item.dart';
import '../message.dart';
import '../message_style.dart';
import 'action/action_data.dart';
import 'action_card/action_card_data.dart';

// ignore_for_file: avoid_dynamic_calls
class QuoteMessage extends HookConsumerWidget {
  const QuoteMessage({
    super.key,
    this.content,
    this.quoteMessageId,
    this.messageId,
    this.message,
    this.isTranscriptPage = false,
  });

  final String? content;
  final String? quoteMessageId;
  final String? messageId;
  final MessageItem? message;
  final bool isTranscriptPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decodeMap = useMemoized(() {
      if (content == null) return null;
      return jsonDecode(content!);
    }, [content]);

    if (quoteMessageId?.isEmpty ?? true) return const SizedBox();
    var inputMode = false;

    final iconColor = context.theme.secondaryText;

    try {
      dynamic quote;
      if (message != null) {
        quote = message;
        inputMode = true;
      } else if (decodeMap != null) {
        quote = mapToQuoteMessage(decodeMap as Map<String, dynamic>);
      }
      final type = quote?.type as String?;
      if (content != null && (type == null || type.isIllegalMessageCategory)) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: null,
          description: context.l10n.messageNotSupport,
          icon: SvgPicture.asset(
            Resources.assetsImagesRecallSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          inputMode: inputMode,
          onTap: () {},
        );
      }
      final userId = quote?.userId as String?;
      final userFullName = quote?.userFullName as String?;
      if (type.isText) {
        return HookConsumer(
          builder: (context, ref, _) {
            final rawContent = quote.content as String;
            final mentionCache = ref.read(mentionCacheProvider);

            final content = useMemoizedFuture(
              () async => mentionCache.replaceMention(
                rawContent,
                await mentionCache.checkMentionCache({rawContent}),
              ),
              rawContent,
              keys: [rawContent],
            ).requireData;

            return _QuoteMessageBase(
              messageId: messageId,
              quoteMessageId: quoteMessageId!,
              userId: userId,
              name: userFullName,
              description: content!,
              inputMode: inputMode,
            );
          },
        );
      }
      final thumbImage = quote?.thumbImage as String?;
      if (type != null && type.isImage) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          image: _QuoteImage(
            quote: quote,
            type: type,
            isTranscriptPage: isTranscriptPage,
            quoteMessageId: quoteMessageId!,
            messageId: messageId,
          ),
          icon: SvgPicture.asset(
            Resources.assetsImagesImageSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: context.l10n.image,
          inputMode: inputMode,
        );
      }
      if (type.isVideo) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          image: ImageByBlurHashOrBase64(imageData: thumbImage!),
          icon: SvgPicture.asset(
            Resources.assetsImagesVideoSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: context.l10n.video,
          inputMode: inputMode,
        );
      }

      if (type.isLive) {
        final placeholder = thumbImage != null
            ? ImageByBlurHashOrBase64(imageData: thumbImage)
            : const SizedBox();
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          image: CacheImage(
            quote.thumbUrl as String,
            placeholder: () => placeholder,
            errorWidget: () => placeholder,
          ),
          icon: SvgPicture.asset(
            Resources.assetsImagesLiveSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: context.l10n.live,
          inputMode: inputMode,
        );
      }
      if (type.isData) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesFileSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: quote.mediaName as String? ?? context.l10n.file,
          inputMode: inputMode,
        );
      }
      if (type.isTranscript) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesFileSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: context.l10n.transcript,
          inputMode: inputMode,
        );
      }
      if (type.isPost) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesFileSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: (quote.content! as String).postOptimizeMarkdown,
          inputMode: inputMode,
        );
      }
      if (type.isLocation) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesLocationSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: context.l10n.location,
          inputMode: inputMode,
        );
      }
      if (type.isAudio) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesAudioSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: context.l10n.audio,
          inputMode: inputMode,
        );
      }
      if (type.isSticker) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          image: StickerItem(
            assetUrl: quote.assetUrl as String,
            assetType: quote.assetType as String?,
          ),
          icon: SvgPicture.asset(
            Resources.assetsImagesStickerSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: context.l10n.sticker,
          inputMode: inputMode,
        );
      }
      if (type.isContact) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          image: Padding(
            padding: const EdgeInsets.all(6),
            child: AvatarWidget(
              name: quote.sharedUserFullName as String?,
              userId: quote.sharedUserId as String?,
              size: 48,
              avatarUrl: quote.sharedUserAvatarUrl as String?,
            ),
          ),
          icon: SvgPicture.asset(
            Resources.assetsImagesContactSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: quote.sharedUserIdentityNumber as String,
          inputMode: inputMode,
        );
      }
      if (type == MessageCategory.appCard ||
          type == MessageCategory.appButtonGroup) {
        String? description;
        final json = jsonDecode(quote.content as String);
        switch (type) {
          case MessageCategory.appButtonGroup:
            description = (json as List?)
                ?.map((e) => ActionData.fromJson(e as Map<String, dynamic>))
                .map((e) => '[${e.label}]')
                .join();
          case MessageCategory.appCard:
            description =
                AppCardData.fromJson(json as Map<String, dynamic>).title;
          default:
            break;
        }

        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: userId,
          name: userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesAppButtonSvg,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          description: description ?? context.l10n.bots,
          inputMode: inputMode,
        );
      }
    } catch (e, s) {
      w('quote message error: $e, $s');
    }

    return _QuoteMessageBase(
      messageId: messageId,
      quoteMessageId: quoteMessageId!,
      userId: null,
      description: context.l10n.messageNotFound,
      icon: SvgPicture.asset(
        Resources.assetsImagesRecallSvg,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
      inputMode: inputMode,
      onTap: () {},
    );
  }
}

class _QuoteImage extends HookWidget {
  const _QuoteImage({
    required this.quote,
    required this.type,
    required this.isTranscriptPage,
    required this.quoteMessageId,
    required this.messageId,
  });

  final dynamic quote;
  final String type;
  final bool isTranscriptPage;
  final String quoteMessageId;
  final String? messageId;

  @override
  Widget build(BuildContext context) {
    final thumbImage = quote?.thumbImage as String?;
    final mediaUrl = quote?.mediaUrl as String?;

    useEffect(
      () {
        if (messageId == null) {
          // Quote is display in input container. no need to update quote content
          return;
        }
        if (mediaUrl == null) {
          scheduleMicrotask(() async {
            final messageDao = context.database.messageDao;
            final messageItem =
                await messageDao.findMessageItemByMessageId(quoteMessageId);
            if (messageItem == null) {
              return;
            }
            await messageDao.updateMessageQuoteContent(
              messageId!,
              messageItem.toJson(),
            );
          });
        }
      },
      [mediaUrl, messageId],
    );

    return Image(
      image: MixinFileImage(File(context.accountServer.convertAbsolutePath(
        type,
        quote.conversationId as String,
        mediaUrl,
        isTranscriptPage,
      ))),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          ImageByBlurHashOrBase64(imageData: thumbImage!),
    );
  }
}

class _QuoteMessageBase extends ConsumerWidget {
  const _QuoteMessageBase({
    required this.messageId,
    required this.quoteMessageId,
    required this.userId,
    required this.description,
    required this.inputMode,
    this.name,
    this.icon,
    this.image,
    this.onTap,
  });

  final String? messageId;
  final String quoteMessageId;
  final String? userId;
  final String? name;
  final String description;
  final Widget? icon;
  final Widget? image;
  final bool inputMode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iterator = LineSplitter.split(description).iterator;
    final _description =
        '${iterator.moveNext() ? iterator.current : ''}${iterator.moveNext() ? '...' : ''}';
    final color = userId?.isNotEmpty == true
        ? getNameColorById(userId!)
        : context.theme.accent;
    return ClipRRect(
      borderRadius: inputMode
          ? BorderRadius.zero
          : const BorderRadius.all(Radius.circular(8)),
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!();
            return;
          }
          context.read<BlinkCubit>().blinkByMessageId(quoteMessageId);

          try {
            if (context.isPinnedPage) {
              ConversationStateNotifier.selectConversation(
                context,
                context.message.conversationId,
                initIndexMessageId: quoteMessageId,
              );
              return;
            }
          } catch (_) {}

          context.providerContainer
              .read(pendingJumpMessageProvider.notifier)
              .state = messageId;
          context.read<MessageBloc>().scrollTo(quoteMessageId);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          color: inputMode ? null : const Color.fromRGBO(0, 0, 0, 0.04),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      color: color,
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 6,
                          left: 6,
                          bottom: 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (name != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: CustomText(
                                  name!,
                                  style: TextStyle(
                                    fontSize: ref
                                        .watch(messageStyleProvider)
                                        .secondaryFontSize,
                                    color: color,
                                    height: 1,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icon != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: icon,
                                  ),
                                Flexible(
                                  child: CustomText(
                                    _description,
                                    style: TextStyle(
                                      fontSize: ref
                                          .watch(messageStyleProvider)
                                          .tertiaryFontSize,
                                      color: context.theme.secondaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (image != null)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                      child: image,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
