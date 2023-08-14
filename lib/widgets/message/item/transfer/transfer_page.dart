import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide Snapshot, Asset, User;

import '../../../../db/dao/snapshot_dao.dart';
import '../../../../db/database_event_bus.dart';
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
          snapshotId,
          context.account!.fiatCurrency,
        )
            .watchSingleOrNullWithStream(
          eventStreams: [
            DataBaseEventBus.instance.updateSnapshotStream.where((event) =>
                event.any((element) => element.contains(snapshotId))),
            DataBaseEventBus.instance.updateAssetStream,
          ],
          duration: kDefaultThrottleDuration,
        )).data;

    final opponentFullName = useMemoizedStream<User?>(() {
      final opponentId = snapshotItem?.opponentId;
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
    }, keys: [snapshotItem?.opponentId]).data?.fullName;

    useEffect(() {
      context.accountServer.updateSnapshotById(snapshotId: snapshotId);
    }, [snapshotId]);

    useEffect(() {
      final assetId = snapshotItem?.assetId;
      if (assetId == null) return;
      context.accountServer.updateAssetById(assetId: assetId);
    }, [snapshotItem?.assetId]);

    if (snapshotItem == null) return const SizedBox();
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
          SymbolIconWithBorder(
            symbolUrl: snapshot.symbolIconUrl ?? '',
            chainUrl: snapshot.chainIconUrl,
            size: 58,
            chainSize: 16,
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
  Widget build(BuildContext context) {
    final createdAt = snapshot.createdAt.toLocal();
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TransactionInfoTile(
            title: Text(context.l10n.transactionId),
            subtitle: SelectableText(snapshot.snapshotId),
          ),
          if (snapshot.snapshotHash?.isNotEmpty ?? false)
            TransactionInfoTile(
              title: Text(context.l10n.snapshotHash),
              subtitle: SelectableText(snapshot.snapshotHash!),
            ),
          TransactionInfoTile(
            title: Text(context.l10n.assetType),
            subtitle: SelectableText(snapshot.symbolName ?? ''),
          ),
          TransactionInfoTile(
            title: Text(context.l10n.transactionType),
            subtitle: SelectableText(snapshot.l10nType(context)),
          ),
          if (snapshot.type == SnapshotType.deposit) ...[
            TransactionInfoTile(
              title: Text(context.l10n.from),
              subtitle: SelectableText(snapshot.sender ?? ''),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.transactionHash),
              subtitle: SelectableText(snapshot.transactionHash ?? ''),
            ),
          ] else if (snapshot.type == SnapshotType.pending) ...[
            TransactionInfoTile(
              title: Text(context.l10n.status),
              subtitle: SelectableText(
                context.l10n.pendingConfirmation(
                  snapshot.confirmations ?? 0,
                  snapshot.confirmations ?? 0,
                  snapshot.assetConfirmations ?? 0,
                ),
              ),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.from),
              subtitle: SelectableText(snapshot.sender ?? ''),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.transactionHash),
              subtitle: SelectableText(snapshot.transactionHash ?? ''),
            ),
          ] else if (snapshot.type == SnapshotType.transfer) ...[
            TransactionInfoTile(
              title: Text(context.l10n.from),
              subtitle: SelectableText((snapshot.isPositive
                      ? opponentFullName
                      : context.account?.fullName) ??
                  ''),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.receiver),
              subtitle: SelectableText((!snapshot.isPositive
                      ? opponentFullName
                      : context.account?.fullName) ??
                  ''),
            ),
          ] else if (snapshot.tag?.isNotEmpty ?? false) ...[
            TransactionInfoTile(
              title: Text(context.l10n.transactionHash),
              subtitle: SelectableText(snapshot.transactionHash ?? ''),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.address),
              subtitle: SelectableText(snapshot.receiver ?? ''),
            ),
          ] else ...[
            TransactionInfoTile(
              title: Text(context.l10n.transactionHash),
              subtitle: SelectableText(snapshot.transactionHash ?? ''),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.receiver),
              subtitle: SelectableText(snapshot.receiver ?? ''),
            ),
          ],
          if (snapshot.memo?.isNotEmpty ?? false)
            TransactionInfoTile(
              title: Text(context.l10n.memo),
              subtitle: SelectableText(snapshot.memo!),
            ),
          if ((snapshot.openingBalance?.isNotEmpty ?? false) &&
              (snapshot.symbol?.isNotEmpty ?? false))
            TransactionInfoTile(
              title: Text(context.l10n.openingBalance),
              subtitle: SelectableText(
                  '${snapshot.openingBalance!} ${snapshot.symbol!}'),
            ),
          if ((snapshot.closingBalance?.isNotEmpty ?? false) &&
              (snapshot.symbol?.isNotEmpty ?? false))
            TransactionInfoTile(
              title: Text(context.l10n.closingBalance),
              subtitle: SelectableText(
                  '${snapshot.closingBalance ?? ''} ${snapshot.symbol ?? ''}'),
            ),
          TransactionInfoTile(
            title: Text(context.l10n.time),
            subtitle: SelectableText('${DateFormat.yMMMMd().format(createdAt)}'
                '${DateFormat.Hms().format(createdAt)}'),
          ),
          if (snapshot.type == SnapshotType.transfer &&
              snapshot.traceId != null &&
              snapshot.traceId!.isNotEmpty)
            TransactionInfoTile(
              title: Text(context.l10n.trace),
              subtitle: SelectableText(snapshot.traceId ?? ''),
            ),
        ],
      ),
    );
  }
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

class SymbolIconWithBorder extends StatelessWidget {
  const SymbolIconWithBorder({
    super.key,
    required this.symbolUrl,
    this.chainUrl,
    this.size = 44,
    this.chainSize = 10,
    this.chainBorder = 2,
  });

  final String symbolUrl;
  final String? chainUrl;
  final double size;
  final double chainSize;
  final double chainBorder;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: size,
        width: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipPath(
                clipper: _SymbolCustomClipper(
                  chainPlaceholderSize: chainSize + chainBorder,
                ),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: CacheImage(symbolUrl),
              ),
            ),
            if (chainUrl != null)
              Positioned(
                right: chainBorder / 2,
                bottom: chainBorder / 2,
                child: CacheImage(
                  chainUrl!,
                  width: chainSize,
                  height: chainSize,
                ),
              ),
          ],
        ),
      );
}

class _SymbolCustomClipper extends CustomClipper<Path> with EquatableMixin {
  _SymbolCustomClipper({this.chainPlaceholderSize = 12});

  final double chainPlaceholderSize;

  @override
  Path getClip(Size size) {
    assert(size.shortestSide > chainPlaceholderSize);

    final symbol = Path()..addOval(Offset.zero & size);
    final chain = Path()
      ..addOval(Offset(size.width - chainPlaceholderSize,
              size.height - chainPlaceholderSize) &
          Size.square(chainPlaceholderSize));

    return Path.combine(PathOperation.difference, symbol, chain);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) =>
      this != oldClipper;

  @override
  List<Object?> get props => [chainPlaceholderSize];
}
