import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' show SnapshotType;

import '../../../../db/dao/snapshot_dao.dart';
import '../../../../db/database_event_bus.dart';
import '../../../../db/mixin_database.dart' hide Offset;
import '../../../../ui/provider/transfer_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../buttons.dart';
import '../../../dialog.dart';
import 'transfer_page.dart';

Future<void> showSafeTransferDialog(BuildContext context, String snapshotId) =>
    showMixinDialog(
      context: context,
      child: _SafeTransferDialog(snapshotId: snapshotId),
    );

SnapshotItem _createSafeSnapshotItem(
  SafeSnapshot snapshot, {
  Token? token,
  Chain? chain,
}) {
  final amount = double.tryParse(snapshot.amount);
  final isPositive = amount != null && amount > 0;
  return SnapshotItem(
    snapshotId: snapshot.snapshotId,
    traceId: snapshot.traceId,
    type: !snapshot.opponentId.isNullOrBlank()
        ? SnapshotType.transfer
        : (snapshot.type == SnapshotType.pending
            ? SnapshotType.pending
            : isPositive
                ? SnapshotType.deposit
                : SnapshotType.withdrawal),
    assetId: snapshot.assetId,
    amount: snapshot.amount,
    createdAt: DateTime.parse(snapshot.createdAt),
    opponentId: snapshot.opponentId,
    transactionHash: snapshot.transactionHash,
    memo: snapshot.memo,
    confirmations: snapshot.confirmations,
    openingBalance: snapshot.openingBalance,
    closingBalance: snapshot.closingBalance,
    priceUsd: token?.priceUsd,
    chainId: token?.chainId,
    symbol: token?.symbol,
    symbolName: token?.name,
    assetConfirmations: token?.confirmations,
    symbolIconUrl: token?.iconUrl,
    chainIconUrl: chain?.iconUrl,
  );
}

class _SafeTransferDialog extends HookConsumerWidget {
  const _SafeTransferDialog({required this.snapshotId});

  final String snapshotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(safeSnapshotProvider(snapshotId));
    useEffect(() {
      context.accountServer.updateSafeSnapshotById(snapshotId: snapshotId);
    }, [snapshotId]);

    var token = const AsyncValue<Token?>.loading();
    if (snapshot.valueOrNull != null) {
      token = ref.watch(tokenProvider(snapshot.value!.assetId));
    }
    useEffect(
      () {
        if (snapshot.hasValue && snapshot.value == null) {
          context.accountServer
              .updateTokenById(assetId: snapshot.value!.assetId);
        }
      },
      [token],
    );

    final snapshotValue = snapshot.valueOrNull;
    final tokenValue = token.valueOrNull;

    final opponentFullName = useMemoizedStream<User?>(() {
      final opponentId = snapshotValue?.opponentId;
      if (opponentId != null && opponentId.trim().isNotEmpty) {
        final stream = context.database.userDao
            .userById(opponentId)
            .watchSingleOrNullWithStream(
          eventStreams: [
            DataBaseEventBus.instance.watchUpdateUserStream([opponentId])
          ],
          duration: kSlowThrottleDuration,
        );
        return stream.map((event) {
          if (event == null) context.accountServer.refreshUsers([opponentId]);
          return event;
        });
      }
      return Stream.value(null);
    }, keys: [snapshotValue?.opponentId]).data?.fullName;

    final chain = ref.watch(assetChainProvider(tokenValue?.chainId));

    final snapshotItem = useMemoized(
      () {
        if (snapshotValue == null) {
          return null;
        }
        return _createSafeSnapshotItem(
          snapshotValue,
          token: token.valueOrNull,
          chain: chain.valueOrNull,
        );
      },
      [snapshotValue, tokenValue, chain.valueOrNull],
    );

    if (snapshotItem == null) {
      return const SizedBox();
    }
    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Spacer(),
              Padding(
                padding: EdgeInsets.only(right: 12, top: 12),
                child: MixinCloseButton(),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SnapshotDetailHeader(snapshot: snapshotItem),
                  Container(
                    color: context.theme.divider,
                    height: 10,
                  ),
                  TransactionDetailInfo(
                    snapshot: snapshotItem,
                    opponentFullName: opponentFullName,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
