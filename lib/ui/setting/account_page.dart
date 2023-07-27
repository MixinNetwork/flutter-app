import 'package:flutter/material.dart';

import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/user/change_number_dialog.dart';
import '../home/route/responsive_navigator_cubit.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
                    onTap: () => context
                        .read<ResponsiveNavigatorCubit>()
                        .pushPage(ResponsiveNavigatorCubit.accountDeletePage),
                  ),
                )
              ],
            ),
          ),
        ),
      );
}
