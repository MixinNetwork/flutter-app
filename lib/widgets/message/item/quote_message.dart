import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../constants/resources.dart';
import '../../../db/extension/message.dart';
import '../../../db/extension/message_category.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../generated/l10n.dart';
import '../../../ui/home/bloc/blink_cubit.dart';
import '../../../ui/home/bloc/message_bloc.dart';
import '../../../ui/home/bloc/pending_jump_message_cubit.dart';
import '../../../utils/color_utils.dart';
import '../../../utils/file.dart';
import '../../../utils/logger.dart';
import '../../../utils/markdown.dart';
import '../../avatar_view/avatar_view.dart';
import '../../brightness_observer.dart';
import '../../cache_image.dart';
import '../../image.dart';
import 'action/action_data.dart';
import 'action_card/action_card_data.dart';

// ignore_for_file: avoid_dynamic_calls
class QuoteMessage extends HookWidget {
  const QuoteMessage({
    Key? key,
    this.content,
    this.quoteMessageId,
    this.messageId,
    this.message,
  }) : super(key: key);

  final String? content;
  final String? quoteMessageId;
  final String? messageId;
  final MessageItem? message;

  @override
  Widget build(BuildContext context) {
    final decodeMap = useMemoized(() {
      if (content == null) return null;
      return jsonDecode(content!);
    }, [content]);

    if (quoteMessageId?.isEmpty ?? true) return const SizedBox();
    var inputMode = false;

    final iconColor = BrightnessData.themeOf(context).secondaryText;

    try {
      late dynamic quote;
      if (message != null) {
        quote = message;
        inputMode = true;
      } else {
        quote = mapToQuoteMessage(decodeMap);
      }
      if ((quote?.type as String?).isIllegalMessageCategory) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: null,
          description: Localization.of(context).chatNotSupport,
          icon: SvgPicture.asset(
            Resources.assetsImagesRecallSvg,
            color: iconColor,
          ),
          inputMode: inputMode,
          onTap: () {},
        );
      }
      final String type = quote.type;
      if (type.isText) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
          description: quote.content!,
          inputMode: inputMode,
        );
      }
      if (type.isImage) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
          image: Image.file(
            File((quote.mediaUrl as String?)?.absolutePath ?? ''),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                ImageByBlurHashOrBase64(imageData: quote.thumbImage),
          ),
          icon: SvgPicture.asset(
            Resources.assetsImagesImageSvg,
            color: iconColor,
          ),
          description: Localization.of(context).image,
          inputMode: inputMode,
        );
      }
      if (type.isVideo) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
          image: ImageByBase64(quote.thumbImage!),
          icon: SvgPicture.asset(
            Resources.assetsImagesVideoSvg,
            color: iconColor,
          ),
          description: Localization.of(context).video,
          inputMode: inputMode,
        );
      }

      if (type.isLive) {
        final placeholder = quote.thumbImage != null
            ? ImageByBase64(quote.thumbImage!)
            : const SizedBox();
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
          image: CacheImage(
            quote.thumbUrl,
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => placeholder,
          ),
          icon: SvgPicture.asset(
            Resources.assetsImagesLiveSvg,
            color: iconColor,
          ),
          description: Localization.of(context).live,
          inputMode: inputMode,
        );
      }

      if (type.isData) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesFileSvg,
            color: iconColor,
          ),
          description: quote.mediaName ?? Localization.of(context).file,
          inputMode: inputMode,
        );
      }
      if (type.isPost) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
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
          userId: quote.userId,
          name: quote.userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesLocationSvg,
            color: iconColor,
          ),
          description: Localization.of(context).location,
          inputMode: inputMode,
        );
      }
      if (type.isAudio) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesAudioSvg,
            color: iconColor,
          ),
          description: Localization.of(context).audio,
          inputMode: inputMode,
        );
      }
      if (type.isSticker) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
          image: CacheImage(quote.assetUrl!),
          icon: SvgPicture.asset(
            Resources.assetsImagesStickerSvg,
            color: iconColor,
          ),
          description: Localization.of(context).sticker,
          inputMode: inputMode,
        );
      }
      if (type.isContact) {
        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
          image: Padding(
            padding: const EdgeInsets.all(6),
            child: AvatarWidget(
              name: quote.sharedUserFullName!,
              userId: quote.sharedUserId!,
              size: 48,
              avatarUrl: quote.sharedUserAvatarUrl,
            ),
          ),
          icon: SvgPicture.asset(
            Resources.assetsImagesContactSvg,
            color: iconColor,
          ),
          description: quote.sharedUserIdentityNumber,
          inputMode: inputMode,
        );
      }
      if (type == MessageCategory.appCard ||
          type == MessageCategory.appButtonGroup) {
        String? description;
        switch (type) {
          case MessageCategory.appButtonGroup:
            description = decodeMap
                .map((e) => ActionData.fromJson(e))
                .map((e) => '[${e.label}]')
                .join();
            break;
          case MessageCategory.appCard:
            description = AppCardData.fromJson(decodeMap).title;
            break;
          default:
            break;
        }

        return _QuoteMessageBase(
          messageId: messageId,
          quoteMessageId: quoteMessageId!,
          userId: quote.userId,
          name: quote.userFullName,
          icon: SvgPicture.asset(
            Resources.assetsImagesAppButtonSvg,
            color: iconColor,
          ),
          description: description ?? Localization.of(context).extensions,
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
      description: Localization.of(context).chatNotFound,
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
    Key? key,
    required this.messageId,
    required this.quoteMessageId,
    required this.userId,
    this.name,
    required this.description,
    this.icon,
    this.image,
    required this.inputMode,
    this.onTap,
  }) : super(key: key);

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
        : BrightnessData.themeOf(context).accent;
    return ClipRRect(
      borderRadius: inputMode ? BorderRadius.zero : BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!();
            return;
          }
          context.read<PendingJumpMessageCubit>().emit(messageId);
          context.read<BlinkCubit>().blinkByMessageId(quoteMessageId);
          context.read<MessageBloc>().scrollTo(quoteMessageId);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 50,
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
                                    fontSize: 14,
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
                                      fontSize: 12,
                                      color: BrightnessData.themeOf(context)
                                          .secondaryText,
                                      height: 1,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: image,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
