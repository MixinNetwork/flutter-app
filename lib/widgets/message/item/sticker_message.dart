import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../../db/database_event_bus.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../interactive_decorated_box.dart';
import '../../sticker_page/sticker_item.dart';
import '../../sticker_page/sticker_store.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

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

class StickerMessageWidget extends HookConsumerWidget {
  const StickerMessageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickerId =
        useMessageConverter(converter: (state) => state.stickerId);

    final messageAssetUrl =
        useMessageConverter(converter: (state) => state.assetUrl);

    final messageStickerData = useMemoized(
      () {
        if (messageAssetUrl == null) {
          return null;
        }
        final message = context.message;
        assert(
          message.assetType != null,
          'messageAssetUrl is not null, but assetType is null',
        );
        return _StickerData(
          assetUrl: messageAssetUrl,
          assetWidth: message.assetWidth,
          assetHeight: message.assetHeight,
          assetType: message.assetType,
        );
      },
      [stickerId, messageAssetUrl],
    );

    final stickerData = useMemoizedStream(
          () {
            if (messageStickerData != null) {
              return const Stream<_StickerData>.empty();
            } else {
              assert(
                stickerId != null,
                'stickerId is null. ${context.message.messageId}',
              );
              if (stickerId == null) return const Stream<_StickerData?>.empty();
              d('stickerData2: $stickerId, ${context.message.messageId}');
              return context.database.stickerDao
                  .sticker(stickerId)
                  .watchSingleOrNullWithStream(eventStreams: [
                    DataBaseEventBus.instance
                        .watchUpdateStickerStream(stickerIds: [stickerId])
                  ], duration: kDefaultThrottleDuration)
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
          keys: [messageStickerData, stickerId],
        ).data ??
        messageStickerData;

    final assetType = stickerData?.assetType;

    final stickerSize = _calculateSize(
      context,
      stickerData?.assetWidth?.toDouble(),
      stickerData?.assetHeight?.toDouble(),
      assetType,
    );

    final errorWidget = Container(
      width: stickerSize.width,
      height: stickerSize.height,
      color: context.theme.stickerPlaceholderColor,
    );
    return MessageBubble(
      showBubble: false,
      padding: EdgeInsets.zero,
      clip: true,
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(),
      child: HookBuilder(
        builder: (context) {
          if (stickerData == null) return errorWidget;

          return InteractiveDecoratedBox(
            onTap: () {
              if (stickerId == null) return;

              showStickerPageDialog(context, stickerId);
            },
            child: StickerItem(
              assetUrl: stickerData.assetUrl,
              assetType: assetType,
              errorWidget: errorWidget,
              width: stickerSize.width,
              height: stickerSize.height,
            ),
          );
        },
      ),
    );
  }
}

const kMaxWidth = 140.0;

Size _calculateSize(
  BuildContext context,
  double? assetWidth,
  double? assetHeight,
  String? assetType,
) {
  final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

  double width;
  double height;

  double scale;

  final minSizeInPx = 60 * devicePixelRatio;
  final maxSizeInPx = kMaxWidth * devicePixelRatio;

  if (assetWidth == null ||
      assetHeight == null ||
      assetWidth <= 0 ||
      assetHeight <= 0) {
    width = maxSizeInPx;
    height = maxSizeInPx;
    scale = 1;
  } else if (assetWidth < minSizeInPx) {
    scale = minSizeInPx / assetWidth;
    if (scale * assetHeight > maxSizeInPx) {
      width = maxSizeInPx;
      height = scale * assetHeight;
    } else {
      width = scale * assetWidth;
      height = scale * assetHeight;
    }
  } else if (assetHeight < minSizeInPx) {
    scale = minSizeInPx / assetHeight;
    if (scale * assetWidth > maxSizeInPx) {
      height = maxSizeInPx;
      width = scale * assetWidth;
    } else {
      width = scale * assetWidth;
      height = scale * assetHeight;
    }
  } else if (assetWidth > maxSizeInPx || assetHeight > maxSizeInPx) {
    if (assetWidth > assetHeight) {
      scale = maxSizeInPx / assetWidth;
      width = maxSizeInPx;
      height = scale * assetHeight;
    } else {
      scale = maxSizeInPx / assetHeight;
      height = maxSizeInPx;
      width = scale * assetWidth;
    }
  } else {
    width = assetWidth;
    height = assetHeight;
    scale = 1;
  }

  var size = Size(width, height) / devicePixelRatio;
  final isJson = assetType == 'json';
  if (!isJson && scale > 2 && MediaQuery.of(context).devicePixelRatio <= 1.5) {
    d('scale: $scale, devicePixelRatio: $devicePixelRatio');
    if (size.longestSide >= kMaxWidth) {
      // scale up max to 200px for less than 1.5x device. eg. Windows 1920 * 1080
      size = size * (200 / kMaxWidth);
    }
  }

  return size;
}
