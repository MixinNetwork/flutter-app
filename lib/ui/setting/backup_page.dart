import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';

import '../../widgets/cell.dart';

class BackupPage extends HookWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.theme.background,
        appBar: MixinAppBar(
          title: Text(context.l10n.chatBackup),
        ),
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
                  context.theme.secondaryText.withOpacity(0.4),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 500,
                child: Text(
                  context.l10n.settingBackupTips,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.theme.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              CellGroup(
                cellBackgroundColor: context.theme.settingCellBackgroundColor,
                child: CellItem(
                  title: Text(context.l10n.backup),
                ),
              ),
              CellGroup(
                cellBackgroundColor: context.theme.settingCellBackgroundColor,
                child: Column(
                  children: [
                    CellItem(
                      title: Text(context.l10n.autoBackup),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: context.theme.accent,
                            value: true,
                            onChanged: (bool value) {},
                          )),
                    ),
                    CellItem(
                      title: Text(context.l10n.includeFiles),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: context.theme.accent,
                            value: true,
                            onChanged: (bool value) {},
                          )),
                    ),
                    CellItem(
                      title: Text(context.l10n.includeVideos),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: context.theme.accent,
                            value: true,
                            onChanged: (bool value) {},
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
