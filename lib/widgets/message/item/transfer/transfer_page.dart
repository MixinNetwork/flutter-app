import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide Asset, Snapshot, Token, User;

import '../../../../db/dao/snapshot_dao.dart';
import '../../../../db/database_event_bus.dart';
import '../../../../db/mixin_database.dart' hide Offset;
import '../../../../ui/provider/account_server_provider.dart';
import '../../../../ui/provider/database_provider.dart';
import '../../../../ui/provider/multi_auth_provider.dart';
import '../../../../ui/provider/ui_context_providers.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../buttons.dart';
import '../../../dialog.dart';
import '../../../high_light_text.dart';
import '../../../mixin_image.dart';

Future<void> showTransferDialog(BuildContext context, String snapshotId) =>
    showMixinDialog(context: context, child: _TransferPage(snapshotId));

class _TransferPage extends HookConsumerWidget {
  const _TransferPage(this.snapshotId);

  final String snapshotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final database = ref.read(databaseProvider).requireValue;
    final account = ref.watch(authAccountProvider);
    useEffect(() {
      accountServer.updateFiats();
      return null;
    }, []);

    final snapshotItem = useMemoizedStream(
      () => database.snapshotDao
          .snapshotItemById(snapshotId, account!.fiatCurrency)
          .watchSingleOrNullWithStream(
            eventStreams: [
              DataBaseEventBus.instance.updateSnapshotStream.where(
                (event) => event.any((element) => element.contains(snapshotId)),
              ),
              DataBaseEventBus.instance.updateAssetStream,
            ],
            duration: kDefaultThrottleDuration,
          ),
    ).data;

    final opponentFullName = useMemoizedStream<User?>(() {
      final opponentId = snapshotItem?.opponentId;
      if (opponentId != null && opponentId.trim().isNotEmpty) {
        final stream = database.userDao
            .userById(opponentId)
            .watchSingleOrNullWithStream(
              eventStreams: [
                DataBaseEventBus.instance.watchUpdateUserStream([
                  opponentId,
                ]),
              ],
              duration: kSlowThrottleDuration,
            );
        return stream.map((event) {
          if (event == null) {
            accountServer.refreshUsers([opponentId]);
          }
          return event;
        });
      }
      return Stream.value(null);
    }, keys: [snapshotItem?.opponentId]).data?.fullName;

    useEffect(() {
      accountServer.updateSnapshotById(snapshotId: snapshotId);
      return null;
    }, [snapshotId]);

    useEffect(() {
      final assetId = snapshotItem?.assetId;
      if (assetId == null) return null;
      accountServer.updateAssetById(assetId: assetId);
      return null;
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
                  SnapshotDetailHeader(
                    symbolIconUrl: snapshotItem.symbolIconUrl ?? '',
                    chainIconUrl: snapshotItem.chainIconUrl ?? '',
                    amount: snapshotItem.amount,
                    symbol: snapshotItem.symbol ?? '',
                    snapshotType: snapshotItem.type,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: Builder(
                      builder: (context) {
                        if (snapshotItem.priceUsd != null &&
                            snapshotItem.fiatRate != null) {
                          return _ValuesDescription(snapshot: snapshotItem);
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    color: theme.divider,
                    height: 10,
                  ),
                  TransactionDetailInfo(
                    snapshot: snapshotItem,
                    opponentFullName: opponentFullName,
                    currentUserFullName: account?.fullName,
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

bool _isPositive(String amount) => (double.tryParse(amount) ?? 0) > 0;

class SnapshotDetailHeader extends HookConsumerWidget {
  const SnapshotDetailHeader({
    required this.symbolIconUrl,
    required this.chainIconUrl,
    required this.amount,
    required this.symbol,
    required this.snapshotType,
    super.key,
  });

  final String symbolIconUrl;
  final String chainIconUrl;
  final String amount;
  final String symbol;
  final String snapshotType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        SymbolIconWithBorder(
          symbolUrl: symbolIconUrl,
          chainUrl: chainIconUrl,
          size: 58,
          chainSize: 16,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: CustomSelectableText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: amount.numberFormat(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'MixinCondensed',
                    color: snapshotType == SnapshotType.pending
                        ? theme.text
                        : _isPositive(amount)
                        ? theme.green
                        : theme.red,
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: symbol.overflow,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.text,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ValuesDescription extends HookConsumerWidget {
  const _ValuesDescription({required this.snapshot});

  final SnapshotItem snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final fiatCurrency = ref.watch(authAccountProvider)?.fiatCurrency;
    final accountServer = ref.read(accountServerProvider).requireValue;
    final ticker = useMemoizedFuture(
      () => accountServer.client.snapshotApi.getTicker(
        snapshot.assetId,
        offset: snapshot.createdAt.toIso8601String(),
      ),
      null,
      keys: [snapshot.snapshotId],
    ).data?.data;

    final String? thatTimeValue;

    final current = snapshot.amountOfCurrentCurrency().abs();
    final unitValue = currencyFormat(
      (current / snapshot.amount.asDecimal.abs()).toDouble(),
      fiatCurrency: fiatCurrency,
    );
    final symbol = snapshot.symbol?.overflow ?? '';
    final currentValue =
        '${l10n.valueNow(currencyFormat(current, fiatCurrency: fiatCurrency))}($unitValue/$symbol)';

    if (ticker == null) {
      thatTimeValue = null;
    } else if (ticker.priceUsd == '0') {
      thatTimeValue = l10n.valueThen(l10n.na);
    } else {
      final past =
          (snapshot.amount.asDecimal *
                  ticker.priceUsd.asDecimal *
                  snapshot.fiatRate!.asDecimal)
              .abs();
      final unitValue = currencyFormat(
        (past / snapshot.amount.asDecimal.abs()).toDouble(),
        fiatCurrency: fiatCurrency,
      );
      thatTimeValue =
          '${l10n.valueThen(currencyFormat(past, fiatCurrency: fiatCurrency))}($unitValue/$symbol)';
    }
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: theme.secondaryText,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomSelectableText(currentValue, enableInteractiveSelection: false),
          if (thatTimeValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CustomSelectableText(
                thatTimeValue,
                enableInteractiveSelection: false,
              ),
            ),
        ],
      ),
    );
  }
}

class TransactionDetailInfo extends ConsumerWidget {
  const TransactionDetailInfo({
    required this.snapshot,
    required this.opponentFullName,
    required this.currentUserFullName,
    super.key,
  });

  final SnapshotItem snapshot;
  final String? opponentFullName;
  final String? currentUserFullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final createdAt = snapshot.createdAt.toLocal();
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TransactionInfoTile(
            title: Text(l10n.transactionId),
            subtitle: CustomSelectableText(snapshot.snapshotId),
          ),
          if (snapshot.snapshotHash?.isNotEmpty ?? false)
            TransactionInfoTile(
              title: Text(l10n.snapshotHash),
              subtitle: CustomSelectableText(snapshot.snapshotHash!),
            ),
          TransactionInfoTile(
            title: Text(l10n.assetType),
            subtitle: CustomSelectableText(snapshot.symbolName ?? ''),
          ),
          TransactionInfoTile(
            title: Text(l10n.transactionType),
            subtitle: CustomSelectableText(snapshot.l10nType(l10n)),
          ),
          if (snapshot.type == SnapshotType.deposit) ...[
            TransactionInfoTile(
              title: Text(l10n.from),
              subtitle: CustomSelectableText(snapshot.sender ?? ''),
            ),
            TransactionInfoTile(
              title: Text(l10n.transactionHash),
              subtitle: CustomSelectableText(snapshot.transactionHash ?? ''),
            ),
          ] else if (snapshot.type == SnapshotType.pending) ...[
            TransactionInfoTile(
              title: Text(l10n.status),
              subtitle: CustomSelectableText(
                l10n.pendingConfirmation(
                  snapshot.confirmations ?? 0,
                  snapshot.confirmations ?? 0,
                  snapshot.assetConfirmations ?? 0,
                ),
              ),
            ),
            TransactionInfoTile(
              title: Text(l10n.from),
              subtitle: CustomSelectableText(snapshot.sender ?? ''),
            ),
            TransactionInfoTile(
              title: Text(l10n.transactionHash),
              subtitle: CustomSelectableText(snapshot.transactionHash ?? ''),
            ),
          ] else if (snapshot.type == SnapshotType.transfer) ...[
            TransactionInfoTile(
              title: Text(l10n.from),
              subtitle: CustomSelectableText(
                (snapshot.isPositive
                        ? opponentFullName
                        : currentUserFullName) ??
                    '',
              ),
            ),
            TransactionInfoTile(
              title: Text(l10n.receiver),
              subtitle: CustomSelectableText(
                (!snapshot.isPositive
                        ? opponentFullName
                        : currentUserFullName) ??
                    '',
              ),
            ),
          ] else if (snapshot.tag?.isNotEmpty ?? false) ...[
            TransactionInfoTile(
              title: Text(l10n.transactionHash),
              subtitle: CustomSelectableText(snapshot.transactionHash ?? ''),
            ),
            TransactionInfoTile(
              title: Text(l10n.address),
              subtitle: CustomSelectableText(snapshot.receiver ?? ''),
            ),
          ] else ...[
            TransactionInfoTile(
              title: Text(l10n.transactionHash),
              subtitle: CustomSelectableText(snapshot.transactionHash ?? ''),
            ),
            TransactionInfoTile(
              title: Text(l10n.receiver),
              subtitle: CustomSelectableText(snapshot.receiver ?? ''),
            ),
          ],
          if (snapshot.memo?.isNotEmpty ?? false)
            TransactionInfoTile(
              title: Text(l10n.memo),
              subtitle: CustomSelectableText(snapshot.memo!),
            ),
          if ((snapshot.openingBalance?.isNotEmpty ?? false) &&
              (snapshot.symbol?.isNotEmpty ?? false))
            TransactionInfoTile(
              title: Text(l10n.openingBalance),
              subtitle: CustomSelectableText(
                '${snapshot.openingBalance!} ${snapshot.symbol!}',
              ),
            ),
          if ((snapshot.closingBalance?.isNotEmpty ?? false) &&
              (snapshot.symbol?.isNotEmpty ?? false))
            TransactionInfoTile(
              title: Text(l10n.closingBalance),
              subtitle: CustomSelectableText(
                '${snapshot.closingBalance ?? ''} ${snapshot.symbol ?? ''}',
              ),
            ),
          TransactionInfoTile(
            title: Text(l10n.time),
            subtitle: CustomSelectableText(
              '${DateFormat.yMMMMd().format(createdAt)}'
              '${DateFormat.Hms().format(createdAt)}',
            ),
          ),
          if (snapshot.type == SnapshotType.transfer &&
              snapshot.traceId != null &&
              snapshot.traceId!.isNotEmpty)
            TransactionInfoTile(
              title: Text(l10n.trace),
              subtitle: CustomSelectableText(snapshot.traceId ?? ''),
            ),
        ],
      ),
    );
  }
}

class TransactionInfoTile extends ConsumerWidget {
  const TransactionInfoTile({
    required this.title,
    required this.subtitle,
    super.key,
    this.subtitleColor,
  });

  final Widget title;
  final Widget subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 16,
            height: 1,
            color: theme.secondaryText,
          ),
          child: title,
        ),
        const SizedBox(height: 8),
        DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 16,
            height: 1,
            color: subtitleColor ?? theme.text,
          ),
          child: subtitle,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class SymbolIconWithBorder extends StatelessWidget {
  const SymbolIconWithBorder({
    required this.symbolUrl,
    super.key,
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
            child: MixinImage.network(symbolUrl),
          ),
        ),
        if (chainUrl != null)
          Positioned(
            right: chainBorder / 2,
            bottom: chainBorder / 2,
            child: MixinImage.network(
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
      ..addOval(
        Offset(
              size.width - chainPlaceholderSize,
              size.height - chainPlaceholderSize,
            ) &
            Size.square(chainPlaceholderSize),
      );

    return Path.combine(PathOperation.difference, symbol, chain);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) =>
      this != oldClipper;

  @override
  List<Object?> get props => [chainPlaceholderSize];
}
