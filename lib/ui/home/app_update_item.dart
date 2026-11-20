import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/dialog.dart';
import '../../widgets/select_item.dart';
import '../provider/app_update_provider.dart';

/// The sidebar item that shows when a new version can be installed.
class AppUpdateItem extends ConsumerWidget {
  const AppUpdateItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);
    if (state.status == AppUpdateStatus.none) return const SizedBox.shrink();

    final accent = context.theme.accent;
    final Widget icon;
    final String title;
    switch (state.status) {
      case AppUpdateStatus.downloading:
        icon = Padding(
          padding: const EdgeInsets.all(3),
          child: CircularProgressIndicator(
            value: state.progress,
            strokeWidth: 2,
            color: accent,
            backgroundColor: accent.withValues(alpha: 0.2),
          ),
        );
        title = '${context.l10n.upgrade} ${(state.progress * 100).floor()}%';
      case AppUpdateStatus.failed:
        icon = SvgPicture.asset(
          Resources.assetsImagesRecordRetrySvg,
          colorFilter: ColorFilter.mode(context.theme.red, BlendMode.srcIn),
        );
        title = context.l10n.retry;
      case AppUpdateStatus.available || AppUpdateStatus.none:
        icon = Padding(
          padding: const EdgeInsets.all(5),
          child: SvgPicture.asset(
            Resources.assetsImagesDownloadSvg,
            colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
          ),
        );
        title = context.l10n.upgrade;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SelectItem(
        icon: SizedBox.square(dimension: 24, child: icon),
        title: Text(title),
        onTap: () {
          if (state.status == AppUpdateStatus.downloading) return;
          ref.read(appUpdateProvider.notifier).update();
        },
      ),
    );
  }
}

/// The button of the page that blocks the app when the server finds this
/// version too old (10006). That page covers the sidebar, so the button
/// installs the update itself when the updater has one, else it runs
/// [onNoUpdate], which opens the download page. After a failed install the
/// download page stays one click away, as a retry can keep failing.
class AppUpdateButton extends ConsumerWidget {
  const AppUpdateButton({required this.onNoUpdate, super.key});

  final VoidCallback onNoUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);
    final button = MixinButton(
      disable: state.status == AppUpdateStatus.downloading,
      onTap: state.status == AppUpdateStatus.none
          ? onNoUpdate
          : () => ref.read(appUpdateProvider.notifier).update(),
      child: Text(switch (state.status) {
        AppUpdateStatus.downloading =>
          '${context.l10n.upgrade} ${(state.progress * 100).floor()}%',
        AppUpdateStatus.failed => context.l10n.retry,
        AppUpdateStatus.none ||
        AppUpdateStatus.available => context.l10n.upgrade,
      }),
    );
    if (state.status != AppUpdateStatus.failed) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 8),
        MixinButton(
          backgroundTransparent: true,
          onTap: onNoUpdate,
          child: Text(context.l10n.download),
        ),
      ],
    );
  }
}
