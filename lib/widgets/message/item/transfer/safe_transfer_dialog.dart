import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' show SnapshotType;

import '../../../../db/database_event_bus.dart';
import '../../../../db/mixin_database.dart' hide Offset;
import '../../../../ui/provider/account/account_server_provider.dart';
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

final _snapshotTypeProvider =
    Provider.family.autoDispose<String, SafeSnapshot>((ref, snapshot) {
  if (snapshot.opponentId.isNullOrBlank()) {
    if (snapshot.type == SnapshotType.pending) {
      return SnapshotType.pending;
    } else {
      final amount = double.tryParse(snapshot.amount);
      final isPositive = amount != null && amount > 0;
      return isPositive ? SnapshotType.deposit : SnapshotType.withdrawal;
    }
  } else {
    return SnapshotType.transfer;
  }
});

final _userProvider =
    StreamProvider.family.autoDispose<User?, String>((ref, userId) {
  final accountServer = ref.read(accountServerProvider).requireValue;

  final stream = accountServer.database.userDao
      .userById(userId)
      .watchSingleOrNullWithStream(
    eventStreams: [
      DataBaseEventBus.instance.watchUpdateUserStream([userId])
    ],
    duration: kSlowThrottleDuration,
  );

  return stream.map((event) {
    if (event == null) accountServer.refreshUsers([userId]);
    return event;
  });
});

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
    final chain = ref.watch(assetChainProvider(tokenValue?.chainId));

    if (snapshotValue == null) {
      return const SizedBox();
    }

    final isPositive = (double.tryParse(snapshotValue.amount) ?? 0) > 0;
    final type = ref.watch(_snapshotTypeProvider(snapshotValue));

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
                  SnapshotDetailHeader(
                    symbolIconUrl: tokenValue?.iconUrl ?? '',
                    chainIconUrl: chain.valueOrNull?.iconUrl ?? '',
                    amount: snapshotValue.amount,
                    symbol: tokenValue?.symbol ?? '',
                    snapshotType: type,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    color: context.theme.divider,
                    height: 10,
                  ),
                  _SafeTransactionDetailInfo(
                    snapshot: snapshotValue,
                    token: tokenValue,
                    isPositive: isPositive,
                    type: type,
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

class _SafeTransactionDetailInfo extends ConsumerWidget {
  const _SafeTransactionDetailInfo({
    required this.snapshot,
    required this.type,
    required this.token,
    required this.isPositive,
  });

  final SafeSnapshot snapshot;
  final String type;
  final Token? token;
  final bool isPositive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdAt = DateTime.parse(snapshot.createdAt).toLocal();
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (type == SnapshotType.pending) ...[
            TransactionInfoTile(
              title: Text(context.l10n.status),
              subtitle: SelectableText(
                context.l10n.pendingConfirmation(
                  snapshot.confirmations ?? 0,
                  snapshot.confirmations ?? 0,
                  token?.confirmations ?? '',
                ),
              ),
            ),
            if (snapshot.deposit != null)
              TransactionInfoTile(
                title: Text(context.l10n.depositHash),
                subtitle: SelectableText(snapshot.deposit!.depositHash),
              ),
          ] else ...[
            TransactionInfoTile(
              title: Text(context.l10n.transactionId),
              subtitle: SelectableText(snapshot.snapshotId),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.transactionHash),
              subtitle: SelectableText(snapshot.transactionHash),
            ),
          ],
          if (type == SnapshotType.transfer) ...[
            TransactionInfoTile(
              title: Text(isPositive ? context.l10n.from : context.l10n.to),
              subtitle: SelectableText(
                snapshot.opponentId.isNullOrBlank()
                    ? context.l10n.anonymous
                    : (ref
                            .watch(_userProvider(snapshot.opponentId))
                            .valueOrNull
                            ?.fullName ??
                        ''),
              ),
            ),
            if (!snapshot.memo.isNullOrBlank())
              TransactionInfoTile(
                title: Text(context.l10n.memo),
                subtitle: SelectableText(snapshot.memo),
              ),
          ] else if (type == SnapshotType.deposit &&
              snapshot.deposit != null) ...[
            TransactionInfoTile(
              title: Text(context.l10n.depositHash),
              subtitle: SelectableText(snapshot.deposit?.depositHash ?? ''),
            ),
          ] else if (type == SnapshotType.withdrawal) ...[
            TransactionInfoTile(
              title: Text(context.l10n.to),
              subtitle: SelectableText(snapshot.withdrawal?.receiver ?? ''),
            ),
            // ignore: unnecessary_parenthesis
            if ((snapshot.withdrawal?.withdrawalHash).isNullOrBlank())
              TransactionInfoTile(
                title: Text(context.l10n.withdrawalHash),
                subtitle: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.theme.secondaryText,
                  ),
                ),
              )
            else
              TransactionInfoTile(
                title: Text(context.l10n.withdrawalHash),
                subtitle:
                    SelectableText(snapshot.withdrawal?.withdrawalHash ?? ''),
              ),
          ],
          TransactionInfoTile(
            title: Text(context.l10n.time),
            subtitle: SelectableText('${DateFormat.yMMMMd().format(createdAt)} '
                '${DateFormat.Hms().format(createdAt)}'),
          ),
        ],
      ),
    );
  }
}
