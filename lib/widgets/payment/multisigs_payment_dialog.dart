import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/resources.dart';
import '../../db/dao/asset_dao.dart';
import '../../db/database_event_bus.dart';
import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../avatar_view/avatar_view.dart';
import '../buttons.dart';
import '../dialog.dart';
import '../message/item/transfer/transfer_page.dart';
import '../qr_code.dart';

class MultisigsPaymentItem {
  const MultisigsPaymentItem({
    required this.senders,
    required this.receivers,
    required this.threshold,
    required this.asset,
    required this.amount,
    required this.state,
    required this.uri,
  });

  final List<String> senders;
  final List<String> receivers;
  final int threshold;
  final AssetItem asset;
  final String amount;

  final String state;

  final Uri uri;
}

class Multi2MultiItem extends MultisigsPaymentItem {
  Multi2MultiItem({
    required super.senders,
    required super.receivers,
    required super.threshold,
    required super.asset,
    required super.amount,
    required super.state,
    required this.action,
    required super.uri,
  });

  final String action;
}

Future<void> showMultisigsPaymentDialog(
  BuildContext context, {
  required MultisigsPaymentItem item,
}) async {
  await showMixinDialog(
    context: context,
    child: _PaymentDialog(item: item),
  );
}

extension _PaymentCodeResponseExt on MultisigsPaymentItem {
  bool get isDone => {'signed', 'unlocked', 'paid'}.contains(state);
}

class _PaymentDialog extends ConsumerWidget {
  const _PaymentDialog({required this.item});

  final MultisigsPaymentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 340,
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
            _MultisigsPaymentBody(item: item),
          ],
        ),
      ),
    ],
  );
}

class _MultisigsPaymentBody extends HookConsumerWidget {
  const _MultisigsPaymentBody({required this.item});

  final MultisigsPaymentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final asset = item.asset;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          (item is Multi2MultiItem &&
                  (item as Multi2MultiItem).action == 'unlock')
              ? l10n.revokeMultisigTransaction
              : l10n.multisigTransaction,
          style: TextStyle(
            fontSize: 18,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 24),
        _UsersLayout(senders: item.senders, receivers: item.receivers),
        const SizedBox(height: 24),
        SymbolIconWithBorder(
          size: 48,
          symbolUrl: asset.iconUrl,
          chainUrl: asset.chainIconUrl,
          chainSize: 14,
        ),
        const SizedBox(height: 10),
        Text(
          '${item.amount.numberFormat()} ${asset.symbol}',
          style: TextStyle(
            fontSize: 16,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 8),
        if (item.isDone) const _DoneLayout() else _QrCodeLayout(uri: item.uri),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _UsersLayout extends ConsumerWidget {
  const _UsersLayout({required this.senders, required this.receivers});

  final List<String> senders;
  final List<String> receivers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _OverlappedUserAvatars(
          children: [
            if (senders.length <= 3)
              for (final sender in senders) _UserIcon(userId: sender),
            if (senders.length > 3)
              for (final sender in senders.take(2)) _UserIcon(userId: sender),
            if (senders.length > 3) _UserCountIcon(count: senders.length - 2),
          ],
        ),
        SizedBox.square(
          dimension: 24,
          child: SvgPicture.asset(
            Resources.assetsImagesIcArrowRightSvg,
            colorFilter: ColorFilter.mode(
              theme.green,
              BlendMode.srcIn,
            ),
          ),
        ),
        _OverlappedUserAvatars(
          children: [
            if (receivers.length <= 3)
              for (final receiver in receivers) _UserIcon(userId: receiver),
            if (receivers.length > 3)
              for (final receiver in receivers.take(2))
                _UserIcon(userId: receiver),
            if (receivers.length > 3)
              _UserCountIcon(count: receivers.length - 2),
          ],
        ),
      ],
    );
  }
}

class _UserCountIcon extends ConsumerWidget {
  const _UserCountIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.listSelected,
        shape: BoxShape.circle,
      ),
      width: 24,
      height: 24,
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            fontSize: 12,
            color: theme.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _OverlappedUserAvatars extends ConsumerWidget {
  const _OverlappedUserAvatars({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Stack(
      children: [
        for (var index = 0; index < children.length; index++)
          Padding(
            padding: EdgeInsets.fromLTRB(index.toDouble() * 20, 0, 0, 0),
            child: ClipOval(
              child: Container(
                color: theme.popUp,
                padding: const EdgeInsets.all(2),
                child: children[index],
              ),
            ),
          ),
      ].reversed.toList(),
    );
  }
}

class _UserIcon extends HookConsumerWidget {
  const _UserIcon({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final user = useMemoizedStream(
      () => accountServer.database.userDao
          .userById(userId)
          .watchSingleOrNullWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateUserStream([userId]),
            ],
            duration: kDefaultThrottleDuration,
          ),
      keys: [accountServer, userId],
    ).data;

    final Widget child;

    if (user == null) {
      child = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            theme.listSelected,
            theme.popUp,
          ),
          shape: BoxShape.circle,
        ),
      );
    } else {
      child = AvatarWidget(
        userId: user.userId,
        name: user.fullName,
        avatarUrl: user.avatarUrl,
        size: 24,
      );
    }
    return child;
  }
}

class _QrCodeLayout extends StatelessWidget {
  const _QrCodeLayout({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 32),
      ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: QrCode(dimension: 180, data: uri.toString()),
      ),
      const SizedBox(height: 32),
    ],
  );
}

class _DoneLayout extends ConsumerWidget {
  const _DoneLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.green.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox.square(
              dimension: 60,
              child: SvgPicture.asset(
                Resources.assetsImagesCheckedSvg,
                colorFilter: ColorFilter.mode(
                  theme.green,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.done,
          style: TextStyle(
            fontSize: 14,
            color: theme.secondaryText,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
