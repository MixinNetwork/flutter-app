import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/user/change_number_dialog.dart';
import '../provider/responsive_navigator_provider.dart';
import '../provider/ui_context_providers.dart';

class AccountPage extends HookConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(title: Text(l10n.account)),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              CellGroup(
                cellBackgroundColor: theme.settingCellBackgroundColor,
                child: CellItem(
                  title: Text(l10n.changeNumber),
                  onTap: () => showChangeNumberDialog(context, ref),
                ),
              ),
              CellGroup(
                cellBackgroundColor: theme.settingCellBackgroundColor,
                child: CellItem(
                  title: Text(l10n.deleteMyAccount),
                  onTap: () => ref
                      .read(responsiveNavigatorProvider.notifier)
                      .pushPage(
                        ResponsiveNavigatorStateNotifier.accountDeletePage,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
