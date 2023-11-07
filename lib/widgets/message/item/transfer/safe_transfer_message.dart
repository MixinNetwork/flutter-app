import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../../../constants/resources.dart';
import '../../../../db/extension/job.dart';
import '../../../../db/mixin_database.dart';
import '../../../../ui/provider/transfer_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../cache_image.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../unknown_message.dart';
import 'safe_transfer_dialog.dart';

class SafeTransferMessage extends HookConsumerWidget {
  const SafeTransferMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetId = useMessageConverter(converter: (state) => state.assetId);

    var assetIcon = useMessageConverter(converter: (state) => state.assetIcon);
    final snapshotAmount =
        useMessageConverter(converter: (state) => state.snapshotAmount);
    var assetSymbol =
        useMessageConverter(converter: (state) => state.assetSymbol);

    final snapshotMemo =
        useMessageConverter(converter: (state) => state.snapshotMemo);

    final token = ref.watch(tokenProvider(assetId));

    assetIcon = assetIcon ?? token.valueOrNull?.iconUrl;
    assetSymbol = assetSymbol ?? token.valueOrNull?.symbol;

    useEffect(() {
      if (assetId == null) {
        e('${context.message.snapshotId}: assetId is null');
        return;
      }
      if (token.hasValue && token.value == null) {
        i('${context.message.snapshotId}: token is null');
        context.accountServer.updateTokenById(assetId: assetId);
      }
    }, [token]);

    final snapshotId =
        useMessageConverter(converter: (state) => state.snapshotId);
    useEffect(
      () {
        if (snapshotId != null) {
          return;
        }
        // try to parse transfer message content from old version.
        final content = context.message.content;
        if (content == null) {
          return;
        }
        final database = context.database;
        final messageId = context.message.messageId;
        scheduleMicrotask(() async {
          try {
            final snapshot = SafeSnapshot.fromJson(
              jsonDecode(
                utf8.decode(
                  base64Decode(content),
                  allowMalformed: true,
                ),
              ) as Map<String, dynamic>,
            );
            context.accountServer.addUpdateTokenJob(
              createUpdateTokenJob(snapshot.assetId),
            );
            await database.safeSnapshotDao.insert(snapshot);
            await database.messageDao
                .updateSafeSnapshotMessage(messageId, snapshot.snapshotId);
          } catch (error, stacktrace) {
            e('handle old transfer message failed', error, stacktrace);
          }
        });
      },
      [snapshotId],
    );
    if (snapshotId == null) {
      return const UnknownMessage();
    }
    return MessageBubble(
      forceIsCurrentUserColor: false,
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(),
      child: InteractiveDecoratedBox(
        onTap: () {
          final snapshotId = context.message.snapshotId;
          if (snapshotId == null) return;
          showSafeTransferDialog(context, snapshotId);
        },
        child: SizedBox(
          width: 174,
          child: _SnapshotLayout(
            assetSymbol: assetSymbol ?? '',
            assetIcon: assetIcon,
            snapshotAmount: snapshotAmount,
            memo: snapshotMemo ?? '',
          ),
        ),
      ),
    );
  }
}

class _SnapshotLayout extends StatelessWidget {
  const _SnapshotLayout({
    this.assetIcon,
    this.snapshotAmount,
    required this.assetSymbol,
    required this.memo,
  });

  final String? assetIcon;
  final String? snapshotAmount;
  final String assetSymbol;
  final String memo;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(Resources.assetsImagesBgSnapshotSvg),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (assetIcon == null)
                      const SizedBox.square(dimension: 16)
                    else
                      ClipOval(
                        child: CacheImage(
                          assetIcon!,
                          width: 16,
                          height: 16,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      assetSymbol,
                      style: TextStyle(
                        color: context.theme.text,
                        fontSize: 13,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                AutoSizeText(
                  snapshotAmount ?? '',
                  maxFontSize: 36,
                  minFontSize: 24,
                  style: TextStyle(
                    color: context.theme.text,
                    fontFamily: 'MixinCondensed',
                    fontSize: 36,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (memo.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    memo,
                    style: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                ] else
                  const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      );
}
