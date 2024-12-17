import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/app_lifecycle.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/local_notification_center.dart';
import '../../utils/uri_utils.dart';
import '../../widgets/animated_visibility.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../provider/setting_provider.dart';

class NotificationPage extends HookConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMessagePreview =
        ref.watch(settingProvider.select((value) => value.messagePreview));

    final appActive = useValueListenable(appActiveListener);
    final hasNotificationPermission = useMemoizedFuture(
        requestNotificationPermission, null,
        keys: [appActive]).data;

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Text(context.l10n.notifications),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CellGroup(
              padding: const EdgeInsets.only(right: 10, left: 10),
              cellBackgroundColor: context.theme.settingCellBackgroundColor,
              child: CellItem(
                title: Text(context.l10n.messagePreview),
                trailing: Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    activeTrackColor: context.theme.accent,
                    value: currentMessagePreview,
                    onChanged: (bool value) =>
                        context.settingChangeNotifier.messagePreview = value,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 14, top: 10),
              child: Text(
                context.l10n.messagePreviewDescription,
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
            if (Platform.isMacOS)
              AnimatedVisibility(
                visible: hasNotificationPermission == false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CellGroup(
                      padding: const EdgeInsets.only(right: 10, left: 10),
                      cellBackgroundColor:
                          context.theme.settingCellBackgroundColor,
                      child: CellItem(
                        title: Text(context.l10n.turnOnNotifications),
                        onTap: () => openUri(context,
                            'x-apple.systempreferences:com.apple.preference.notifications'),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 20, bottom: 14, top: 10),
                      child: Text(
                        context.l10n.notificationContent,
                        style: TextStyle(
                          color: context.theme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!Platform.isMacOS)
              AnimatedVisibility(
                visible: hasNotificationPermission == false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 14),
                  child: Text(
                    '${context.l10n.notificationPermissionManually}${context.l10n.notificationContent}',
                    style: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
