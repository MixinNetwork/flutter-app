import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/extension/message.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/utils/color_utils.dart';
import 'package:flutter_app/widgets/avatar_view/avatar_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_app/db/extension/message_category.dart';
import 'package:provider/provider.dart';

import '../../brightness_observer.dart';
import '../../cache_image.dart';
import 'action/action_data.dart';
import 'action_card/action_card_data.dart';

class QuoteMessage extends StatelessWidget {
  const QuoteMessage({
    Key? key,
    this.content,
    this.id,
  }) : super(key: key);

  final String? content;
  final String? id;

  @override
  Widget build(BuildContext context) {
    if (id?.isEmpty ?? true) return const SizedBox();

    try {
      final map = jsonDecode(content!);
      final quote = mapToQuoteMessage(map);
      if (quote.type.isText)
        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          description: quote.content!,
        );
      if (quote.type.isImage)
        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          image: Image.file(
            File(quote.mediaUrl ?? ''),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.memory(
              base64Decode(quote.thumbImage!),
              fit: BoxFit.cover,
            ),
          ),
          icon: SvgPicture.asset(Resources.assetsImagesImageSvg),
          description: Localization.of(context).image,
        );
      if (quote.type.isVideo)
        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          image: Image.memory(
            base64Decode(quote.thumbImage!),
            fit: BoxFit.cover,
          ),
          icon: SvgPicture.asset(Resources.assetsImagesVideoSvg),
          description: Localization.of(context).video,
        );

      if (quote.type.isLive)
        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          image: Image.memory(
            base64Decode(quote.thumbImage!),
            fit: BoxFit.cover,
          ),
          icon: SvgPicture.asset(Resources.assetsImagesLiveSvg),
          description: Localization.of(context).live,
        );

      if (quote.type.isData)
        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          icon: SvgPicture.asset(Resources.assetsImagesFileSvg),
          description: quote.mediaName ?? Localization.of(context).file,
        );
      if (quote.type.isPost)
        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          icon: SvgPicture.asset(Resources.assetsImagesFileSvg),
          //TODO MD ??
          description: Localization.of(context).post,
        );
      if (quote.type.isLocation)
        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          icon: SvgPicture.asset(Resources.assetsImagesLocationSvg),
          description: Localization.of(context).location,
        );
      if (quote.type.isAudio)
        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          icon: SvgPicture.asset(Resources.assetsImagesAudioSvg),
          description: Localization.of(context).audio,
        );
      if (quote.type.isSticker)
        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          image: CacheImage(quote.assetUrl!),
          icon: SvgPicture.asset(Resources.assetsImagesStickerSvg),
          description: Localization.of(context).sticker,
        );
      if (quote.type.isContact)
        return _QuoteMessageBase(
          messageId: id!,
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
          icon: SvgPicture.asset(Resources.assetsImagesContactSvg),
          description: quote.sharedUserIdentityNumber,
        );
      if (quote.type == MessageCategory.appCard ||
          quote.type == MessageCategory.appButtonGroup) {
        String? description;
        switch (quote.type) {
          case MessageCategory.appButtonGroup:
            description = jsonDecode(quote.content!)
                .map((e) => ActionData.fromJson(e))
                .map((e) => '[${e.label}]')
                .join();
            break;
          case MessageCategory.appCard:
            description =
                AppCardData.fromJson(jsonDecode(quote.content!)).title;
            break;
          default:
            break;
        }

        return _QuoteMessageBase(
          messageId: id!,
          userId: quote.userId,
          name: quote.userFullName,
          icon: SvgPicture.asset(Resources.assetsImagesAppButtonSvg),
          description: description ?? Localization.of(context).extensions,
        );
      }
    } catch (_) {}

    return _QuoteMessageBase(
      messageId: id!,
      userId: null,
      description: Localization.of(context).chatNotFound,
      icon: SvgPicture.asset(Resources.assetsImagesRecallSvg),
    );
  }
}

class _QuoteMessageBase extends StatelessWidget {
  const _QuoteMessageBase({
    Key? key,
    required this.messageId,
    required this.userId,
    this.name,
    required this.description,
    this.icon,
    this.image,
  }) : super(key: key);

  final String messageId;
  final String? userId;
  final String? name;
  final String description;
  final Widget? icon;
  final Widget? image;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.read<MessageBloc>().scrollTo(messageId),
        child: Container(
          height: 50,
          color: const Color.fromRGBO(0, 0, 0, 0.04),
          margin: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    Resources.assetsImagesQuoteBorderSvg,
                    height: 50,
                    width: 6,
                    color: userId?.isNotEmpty == true
                        ? getNameColorById(userId!)
                        : BrightnessData.themeOf(context).accent,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      left: 6,
                      bottom: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (name != null)
                          Text(
                            name!,
                            style: TextStyle(
                              fontSize: 14,
                              color: BrightnessData.themeOf(context).accent,
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
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: BrightnessData.themeOf(context)
                                    .secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              if (image != null)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: image!,
                  ),
                ),
            ],
          ),
        ),
      );
}
