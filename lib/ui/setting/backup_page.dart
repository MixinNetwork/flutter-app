import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/resources.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../provider/ui_context_providers.dart';

class BackupPage extends HookConsumerWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(title: Text(l10n.chatBackup)),
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            SvgPicture.asset(
              Resources.assetsImagesChatBackupSvg,
              width: 88,
              height: 58,
              colorFilter: ColorFilter.mode(
                theme.secondaryText.withValues(alpha: 0.4),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 500,
              child: Text(
                l10n.settingBackupTips,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: theme.secondaryText),
              ),
            ),
            const SizedBox(height: 30),
            CellGroup(
              cellBackgroundColor: theme.settingCellBackgroundColor,
              child: CellItem(title: Text(l10n.backup)),
            ),
            CellGroup(
              cellBackgroundColor: theme.settingCellBackgroundColor,
              child: Column(
                children: [
                  CellItem(
                    title: Text(l10n.autoBackup),
                    trailing: Transform.scale(
                      scale: 0.7,
                      child: CupertinoSwitch(
                        activeTrackColor: theme.accent,
                        value: true,
                        onChanged: (value) {},
                      ),
                    ),
                  ),
                  CellItem(
                    title: Text(l10n.includeFiles),
                    trailing: Transform.scale(
                      scale: 0.7,
                      child: CupertinoSwitch(
                        activeTrackColor: theme.accent,
                        value: true,
                        onChanged: (value) {},
                      ),
                    ),
                  ),
                  CellItem(
                    title: Text(l10n.includeVideos),
                    trailing: Transform.scale(
                      scale: 0.7,
                      child: CupertinoSwitch(
                        activeTrackColor: theme.accent,
                        value: true,
                        onChanged: (value) {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
