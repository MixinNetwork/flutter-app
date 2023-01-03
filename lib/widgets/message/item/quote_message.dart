import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants/resources.dart';
import '../../../db/extension/message.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../ui/home/bloc/blink_cubit.dart';
import '../../../ui/home/bloc/conversation_cubit.dart';
import '../../../ui/home/bloc/message_bloc.dart';
import '../../../ui/home/bloc/pending_jump_message_cubit.dart';
import '../../../utils/color_utils.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/logger.dart';
import '../../avatar_view/avatar_view.dart';
import '../../cache_image.dart';
import '../../image.dart';
import '../../sticker_page/sticker_item.dart';
import '../message.dart';
import '../message_style.dart';
import 'action/action_data.dart';
import 'action_card/action_card_data.dart';
import 'text/mention_builder.dart';

// ignore_for_file: avoid_dynamic_calls
class QuoteMessage extends HookWidget {
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
  Widget build(BuildContext context) {
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
            color: iconColor,
          ),
          inputMode: inputMode,
          onTap: () {},
        );
      }
      final userId = quote?.userId as String?;
      final userFullName = quote?.userFullName as String?;
      if (type.isText) {
        return HookBuilder(
          builder: (context) {
            final rawContent = quote.content as String;
            final mentionCache = context.read<MentionCache>();
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
          image: Image(
            image:
                MixinFileImage(File(context.accountServer.convertAbsolutePath(
              type,
              quote.conversationId as String,
              quote.mediaUrl as String?,
              isTranscriptPage,
            ))),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                ImageByBlurHashOrBase64(imageData: thumbImage!),
          ),
          icon: SvgPicture.asset(
            Resources.assetsImagesImageSvg,
            color: iconColor,
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
            color: iconColor,
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
            color: iconColor,
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
            color: iconColor,
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
            color: iconColor,
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
            color: iconColor,
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
            color: iconColor,
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
            color: iconColor,
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
            assetType: quote.assetType as String,
          ),
          icon: SvgPicture.asset(
            Resources.assetsImagesStickerSvg,
            color: iconColor,
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
            color: iconColor,
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
            break;
          case MessageCategory.appCard:
            description =
                AppCardData.fromJson(json as Map<String, dynamic>).title;
            break;
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
            color: iconColor,
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
        color: iconColor,
      ),
      inputMode: inputMode,
      onTap: () {},
    );
  }
}

class _QuoteMessageBase extends StatelessWidget {
  const _QuoteMessageBase({
    required this.messageId,
    required this.quoteMessageId,
    required this.userId,
    this.name,
    required this.description,
    this.icon,
    this.image,
    required this.inputMode,
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
  Widget build(BuildContext context) {
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
              ConversationCubit.selectConversation(
                context,
                context.message.conversationId,
                initIndexMessageId: quoteMessageId,
              );
              return;
            }
          } catch (_) {}

          context.read<PendingJumpMessageCubit>().emit(messageId);
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
                                child: Text(
                                  name!,
                                  style: TextStyle(
                                    fontSize:
                                        context.messageStyle.secondaryFontSize,
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
                                  child: Text(
                                    _description,
                                    style: TextStyle(
                                      fontSize:
                                          context.messageStyle.tertiaryFontSize,
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
