import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
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
