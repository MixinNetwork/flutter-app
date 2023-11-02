import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../db/dao/snapshot_dao.dart';
import '../../../../db/mixin_database.dart' hide Offset;
import '../../../../ui/provider/transfer_provider.dart';
import '../../../../utils/extension/extension.dart';
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
}) =>
    SnapshotItem(
      snapshotId: snapshot.snapshotId,
      traceId: snapshot.traceId,
      type: snapshot.type,
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

    if (snapshotValue == null || tokenValue == null) {
      return const SizedBox();
    }

    final snapshotItem = useMemoized(
      () => _createSafeSnapshotItem(snapshot.valueOrNull!,
          token: token.valueOrNull),
      [snapshotValue, tokenValue],
    );

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
                    opponentFullName: 'opponentFullName',
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
