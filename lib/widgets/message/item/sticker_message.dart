import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../interactive_decorated_box.dart';
import '../../sticker_page/sticker_item.dart';
import '../../sticker_page/sticker_store.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

const kMaxWidth = 140.0;

class _StickerData with EquatableMixin {
  _StickerData({
    required this.assetUrl,
    required this.assetWidth,
    required this.assetHeight,
    required this.assetType,
  });

  final String assetUrl;
  final int? assetWidth;
  final int? assetHeight;
  final String? assetType;

  @override
  List<Object?> get props => [
        assetUrl,
        assetWidth,
        assetHeight,
        assetType,
      ];
}

class StickerMessageWidget extends HookWidget {
  const StickerMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final stickerId =
        useMessageConverter(converter: (state) => state.stickerId);

    final messageAssetUrl =
        useMessageConverter(converter: (state) => state.assetUrl);

    final stickerData = useMemoizedStream(
      () {
        if (messageAssetUrl != null) {
          final message = context.message;
          assert(
            message.assetType != null,
            'messageAssetUrl is not null, but assetType is null',
          );
          return Stream.value(
            _StickerData(
              assetUrl: messageAssetUrl,
              assetWidth: message.assetWidth,
              assetHeight: message.assetHeight,
              assetType: message.assetType,
            ),
          );
        } else {
          assert(
            stickerId != null,
            'stickerId is null. ${context.message.messageId}',
          );
          return context.database.stickerDao
              .sticker(stickerId!)
              .watchSingleOrNull()
              .whereNotNull()
              .map(
                (event) => _StickerData(
                  assetUrl: event.assetUrl,
                  assetWidth: event.assetWidth,
                  assetHeight: event.assetHeight,
                  assetType: event.assetType,
                ),
              );
        }
      },
      keys: [messageAssetUrl, stickerId],
    ).data;

    final assetType = stickerData?.assetType;

    const width = kMaxWidth;
    const height = kMaxWidth;

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
      child: HookBuilder(
        builder: (context) {
          if (stickerData == null) return placeholder;

          return InteractiveDecoratedBox(
            onTap: () {
              if (stickerId == null) return;

              showStickerPageDialog(context, stickerId);
            },
            child: StickerItem(
              assetUrl: stickerData.assetUrl,
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
