import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide Snapshot, Asset, User;
import 'package:rxdart/rxdart.dart';

import '../../../../db/dao/snapshot_dao.dart';
import '../../../../db/mixin_database.dart' hide Offset;
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../buttons.dart';
import '../../../cache_image.dart';
import '../../../dialog.dart';

Future<void> showTransferDialog(
  BuildContext context,
  String snapshotId,
) =>
    showMixinDialog(
      context: context,
      child: _TransferPage(snapshotId),
    );

class _TransferPage extends HookWidget {
  const _TransferPage(
    this.snapshotId,
  );

  final String snapshotId;

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      context.accountServer.updateFiats();
    }, []);

    final snapshotItem = useMemoizedStream(() => context.database.snapshotDao
        .snapshotItemById(
            snapshotId, context.multiAuthState.currentUser!.fiatCurrency)
        .watchSingleOrNullThrottle(kDefaultThrottleDuration)).data;

    final opponentFullName = useMemoizedStream<User?>(() {
      final opponentId = snapshotItem?.opponentId;
      if (opponentId != null && opponentId.trim().isNotEmpty) {
        final stream = context.database.userDao
            .userById(opponentId)
            .watchSingleOrNullThrottle(kSlowThrottleDuration);
        return stream.doOnData((event) {
          if (event != null) return;
          context.accountServer.refreshUsers([opponentId]);
        });
      }
      return Stream.value(null);
    }, keys: [snapshotItem?.opponentId]).data?.fullName;

    useEffect(() {
      context.accountServer.updateSnapshotById(snapshotId: snapshotId);
    }, [snapshotId]);

    useEffect(() {
      final assetId = snapshotItem?.assetId;
      if (assetId == null) return;
      context.accountServer.updateAssetById(assetId: assetId);
    }, [snapshotItem?.assetId]);

    useEffect(() {
      final chainId = snapshotItem?.chainId;
      if (chainId == null) return;
      context.accountServer.updateAssetById(assetId: chainId);
    }, [snapshotItem?.chainId]);

    if (snapshotItem == null) return const SizedBox();
    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: const [
              Spacer(),
              Padding(
                padding: EdgeInsets.only(right: 12, top: 12),
                child: MixinCloseButton(),
              ),
            ],
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SnapshotDetailHeader(snapshot: snapshotItem),
                Container(
                  color: context.theme.divider,
                  height: 10,
                ),
                _TransactionDetailInfo(
                  snapshot: snapshotItem,
                  opponentFullName: opponentFullName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotDetailHeader extends HookWidget {
  const _SnapshotDetailHeader({
    required this.snapshot,
  });

  final SnapshotItem snapshot;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          _SymbolIconWithBorder(
            symbolUrl: snapshot.symbolIconUrl ?? '',
            chainUrl: snapshot.chainIconUrl,
            size: 58,
            chainSize: 14,
            chainBorder: const BorderSide(color: Colors.white, width: 2),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SelectableText.rich(
              TextSpan(children: [
                TextSpan(
                    text: snapshot.amount.numberFormat(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: snapshot.type == SnapshotType.pending
                          ? context.theme.text
                          : snapshot.isPositive
                              ? context.theme.green
                              : context.theme.red,
                    )),
                const TextSpan(text: ' '),
                TextSpan(
                    text: snapshot.symbol?.overflow,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.theme.text,
                    )),
              ]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Builder(
              builder: (context) {
                if (snapshot.priceUsd != null && snapshot.fiatRate != null) {
                  return _ValuesDescription(snapshot: snapshot);
                }
                return const SizedBox();
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
}

class _ValuesDescription extends HookWidget {
  const _ValuesDescription({
    required this.snapshot,
  });

  final SnapshotItem snapshot;

  @override
  Widget build(BuildContext context) {
    final ticker = useMemoizedFuture(
      () => context.accountServer.client.snapshotApi.getTicker(
        snapshot.assetId,
        offset: snapshot.createdAt.toIso8601String(),
      ),
      null,
      keys: [snapshot.snapshotId],
    ).data?.data;

    final String? thatTimeValue;

    final current = snapshot.amountOfCurrentCurrency().abs();
    final unitValue = context
        .currencyFormat((current / snapshot.amount.asDecimal.abs()).toDouble());
    final symbol = snapshot.symbol?.overflow ?? '';
    final currentValue = '${context.l10n.valueNow(
      context.currencyFormat(current),
    )}($unitValue/$symbol)';

    if (ticker == null) {
      thatTimeValue = null;
    } else if (ticker.priceUsd == '0') {
      thatTimeValue = context.l10n.valueThen(context.l10n.na);
    } else {
      final past = (snapshot.amount.asDecimal *
              ticker.priceUsd.asDecimal *
              snapshot.fiatRate!.asDecimal)
          .abs();
      final unitValue = context
          .currencyFormat((past / snapshot.amount.asDecimal.abs()).toDouble());
      thatTimeValue = '${context.l10n.valueThen(
        context.currencyFormat(past),
      )}($unitValue/$symbol)';
    }
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: context.theme.secondaryText,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            currentValue,
            enableInteractiveSelection: false,
          ),
          if (thatTimeValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SelectableText(
                thatTimeValue,
                enableInteractiveSelection: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionDetailInfo extends StatelessWidget {
  const _TransactionDetailInfo({
    required this.snapshot,
    required this.opponentFullName,
  });

  final SnapshotItem snapshot;
  final String? opponentFullName;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TransactionInfoTile(
              title: Text(context.l10n.transactionId),
              subtitle: SelectableText(snapshot.snapshotId),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.assetType),
              subtitle: SelectableText(snapshot.symbolName ?? ''),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.transactionType),
              subtitle: SelectableText(snapshot.l10nType(context)),
            ),
            if (opponentFullName?.isNotEmpty ?? false)
              TransactionInfoTile(
                title: Text(snapshot.isPositive
                    ? context.l10n.from
                    : context.l10n.receiver),
                subtitle: SelectableText(opponentFullName ?? ''),
              ),
            if (snapshot.memo?.isNotEmpty ?? false)
              TransactionInfoTile(
                title: Text(context.l10n.memo),
                subtitle: SelectableText(snapshot.memo!),
              ),
            TransactionInfoTile(
              title: Text(context.l10n.time),
              subtitle: SelectableText(
                  '${DateFormat.yMMMMd().format(snapshot.createdAt)} '
                  '${DateFormat.Hms().format(snapshot.createdAt)}'),
            ),
            if (snapshot.traceId != null && snapshot.traceId!.isNotEmpty)
              TransactionInfoTile(
                title: const Text('Trace Id'),
                subtitle: SelectableText(snapshot.traceId ?? ''),
              ),
          ],
        ),
      );
}

class TransactionInfoTile extends StatelessWidget {
  const TransactionInfoTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
  });

  final Widget title;
  final Widget subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 16,
              height: 1,
              color: context.theme.secondaryText,
            ),
            child: title,
          ),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 16,
              height: 1,
              color: subtitleColor ?? context.theme.text,
            ),
            child: subtitle,
          ),
          const SizedBox(height: 12),
        ],
      );
}

class _SymbolIconWithBorder extends StatelessWidget {
  const _SymbolIconWithBorder({
    required this.symbolUrl,
    this.chainUrl,
    required this.size,
    required this.chainSize,
    this.chainBorder = const BorderSide(color: Colors.white),
  });

  final String symbolUrl;
  final String? chainUrl;
  final double size;
  final double chainSize;

  final BorderSide chainBorder;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size + chainBorder.width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.all(chainBorder.width),
              child: CacheImage(symbolUrl),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(chainBorder),
                ),
                child: Padding(
                  padding: EdgeInsets.all(chainBorder.width),
                  child: SizedBox.square(
                    dimension: chainSize,
                    child: CacheImage(
                      chainUrl ?? '',
                      width: chainSize,
                      height: chainSize,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
