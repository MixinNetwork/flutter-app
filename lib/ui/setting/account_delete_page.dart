import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../account/session_key_value.dart';
import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/toast.dart';
import '../../widgets/user/pin_verification_dialog.dart';
import '../home/bloc/multi_auth_cubit.dart';

class AccountDeletePage extends StatelessWidget {
  const AccountDeletePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.theme.background,
        appBar: MixinAppBar(
          title: Text(context.l10n.deleteMyAccount),
        ),
        body: SingleChildScrollView(
          child: Container(
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                const _DeleteWarningWidget(),
                const SizedBox(height: 30),
                CellGroup(
                  cellBackgroundColor: context.dynamicColor(
                    Colors.white,
                    darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                  ),
                  child: CellItem(
                    title: Text(context.l10n.deleteMyAccount),
                    color: context.theme.red,
                    onTap: () async {
                      if (!SessionKeyValue.instance.checkPinToken()) {
                        await showToastFailed(
                          context,
                          ToastError(context.l10n.errorNoPinToken),
                        );
                        return;
                      }

                      final user =
                          context.read<MultiAuthCubit>().state.currentUser;
                      assert(user != null, 'user is null');
                      if (user == null) {
                        return;
                      }
                      if (user.hasPin) {
                        final verified = await showPinVerificationDialog(
                          context,
                          title: context.l10n.enterYourPinToContinue,
                        );
                        if (!verified) {
                          return;
                        }
                      } else {
                        i('delete account no pin');
                      }
                    },
                  ),
                ),
                CellGroup(
                  cellBackgroundColor: context.dynamicColor(
                    Colors.white,
                    darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                  ),
                  child: CellItem(
                    title: Text(context.l10n.changeNumberInstead),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DeleteWarningWidget extends StatelessWidget {
  const _DeleteWarningWidget();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SvgPicture.asset(
            Resources.assetsImagesDeleteAccountSvg,
            width: 70,
            height: 72,
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WarningItem(title: context.l10n.deleteAccountHint),
                _WarningItem(title: context.l10n.deleteAccountDetailHint),
                _WarningItem(title: context.l10n.transactionsCannotBeDeleted),
              ],
            ),
          ),
        ],
      );
}

class _WarningItem extends StatelessWidget {
  const _WarningItem({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.text;
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
