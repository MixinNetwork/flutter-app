import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/user/change_number_dialog.dart';
import '../provider/navigation/responsive_navigator_provider.dart';

class AccountPage extends HookConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: context.theme.background,
        appBar: MixinAppBar(
          title: Text(context.l10n.account),
        ),
        body: SingleChildScrollView(
          child: Container(
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                CellGroup(
                  cellBackgroundColor: context.theme.settingCellBackgroundColor,
                  child: CellItem(
                    title: Text(context.l10n.changeNumber),
                    onTap: () => showChangeNumberDialog(context),
                  ),
                ),
                CellGroup(
                  cellBackgroundColor: context.theme.settingCellBackgroundColor,
                  child: CellItem(
                    title: Text(context.l10n.deleteMyAccount),
                    onTap: () => ref
                        .read(responsiveNavigatorProvider.notifier)
                        .pushPage(
                            ResponsiveNavigatorStateNotifier.accountDeletePage),
                  ),
                )
              ],
            ),
          ),
        ),
      );
}
