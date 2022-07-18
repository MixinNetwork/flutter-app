import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/dp_utils.dart';
import '../../../utils/extension/extension.dart';
import '../../interactive_decorated_box.dart';
import '../../sticker_page/sticker_item.dart';
import '../../sticker_page/sticker_store.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

const kMaxWidth = 140.0;

class StickerMessageWidget extends HookWidget {
  const StickerMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final assetWidth =
        useMessageConverter(converter: (state) => state.assetWidth);
    final assetHeight =
        useMessageConverter(converter: (state) => state.assetHeight);
    final assetType =
        useMessageConverter(converter: (state) => state.assetType);
    final assetUrl = useMessageConverter(converter: (state) => state.assetUrl);
    final stickerId =
        useMessageConverter(converter: (state) => state.stickerId);

    double width;
    double height;
    if (assetWidth == null || assetHeight == null) {
      height = kMaxWidth;
      width = kMaxWidth;
    } else if (assetWidth * 2 < dpToPx(context, 48) ||
        assetHeight * 2 < dpToPx(context, 48)) {
      if (assetWidth < assetHeight) {
        if (dpToPx(context, 48) * assetHeight / assetWidth >
            dpToPx(context, kMaxWidth)) {
          height = kMaxWidth;
          width = kMaxWidth * assetWidth / assetHeight;
        } else {
          width = 48;
          height = assetHeight * 48 / assetWidth;
        }
      } else {
        if (dpToPx(context, 48) * assetWidth / assetHeight >
            dpToPx(context, kMaxWidth)) {
          width = kMaxWidth;
          height = kMaxWidth * assetHeight / assetWidth;
        } else {
          height = 48;
          width = assetWidth * 48 / assetHeight;
        }
      }
    } else if (assetWidth * 2 < dpToPx(context, kMaxWidth) ||
        assetHeight * 2 > dpToPx(context, kMaxWidth)) {
      if (assetWidth > assetHeight) {
        width = kMaxWidth;
        height = kMaxWidth * assetHeight / assetWidth;
      } else {
        height = kMaxWidth;
        width = kMaxWidth * assetWidth / assetHeight;
      }
    } else {
      width = pxToDp(context, assetWidth * 2);
      height = pxToDp(context, assetHeight * 2);
    }
    final placeholder = Container(
      width: width,
      height: height,
      color: context.theme.stickerPlaceholderColor,
    );
    return MessageBubble(
      showBubble: false,
      padding: EdgeInsets.zero,
      clip: true,
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(),
      child: Builder(
        builder: (context) {
          if (assetUrl == null) return placeholder;

          return InteractiveDecoratedBox(
            onTap: () {
              if (stickerId == null) return;

              showStickerPageDialog(context, stickerId);
            },
            child: StickerItem(
              assetUrl: assetUrl,
              assetType: assetType,
              placeholder: placeholder,
              width: width,
              height: height,
            ),
          );
        },
      ),
    );
  }
}
