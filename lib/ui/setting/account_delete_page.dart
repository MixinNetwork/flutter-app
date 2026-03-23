import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide encryptPin;

import '../../account/session_key_value.dart';
import '../../constants/resources.dart';
import '../../utils/logger.dart';
import '../../utils/uri_utils.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../../widgets/high_light_text.dart';
import '../../widgets/toast.dart';
import '../../widgets/user/change_number_dialog.dart';
import '../../widgets/user/pin_verification_dialog.dart';
import '../../widgets/user/verification_dialog.dart';
import '../provider/account_server_provider.dart';
import '../provider/multi_auth_provider.dart';
import '../provider/ui_context_providers.dart';

class AccountDeletePage extends ConsumerWidget {
  const AccountDeletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(title: Text(l10n.deleteMyAccount)),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            children: [
              const _DeleteWarningWidget(),
              const SizedBox(height: 30),
              CellGroup(
                cellBackgroundColor: theme.settingCellBackgroundColor,
                child: CellItem(
                  title: Text(l10n.deleteMyAccount),
                  color: theme.red,
                  onTap: () async {
                    if (!SessionKeyValue.instance.checkPinToken()) {
                      showToastFailed(ToastError(l10n.errorNoPinToken));
                      return;
                    }

                    final accountServer = ref
                        .read(accountServerProvider)
                        .requireValue;
                    final user = ref.read(authAccountProvider);
                    assert(user != null, 'user is null');
                    if (user == null) {
                      return;
                    }
                    if (user.hasPin) {
                      final pin = await showPinVerificationDialog(
                        context,
                        title: l10n.enterYourPinToContinue,
                      );
                      if (pin == null) {
                        return;
                      }
                      final confirmed = await showConfirmMixinDialog(
                        context,
                        l10n.landingInvitationDialogContent(user.phone),
                        maxWidth: 440,
                        positiveText: l10n.continueText,
                      );
                      if (confirmed == null) return;
                      showToastLoading();
                      VerificationResponse? verificationResponse;

                      try {
                        verificationResponse = await requestVerificationCode(
                          phone: user.phone,
                          context: context,
                          purpose: VerificationPurpose.deactivated,
                          accountApi: accountServer.client.accountApi,
                        );
                        Toast.dismiss();
                      } catch (error, stacktrace) {
                        e('_requestVerificationCode $error, $stacktrace');
                        showToastFailed(error);
                        return;
                      }
                      final verificationId = await showVerificationDialog(
                        context,
                        phoneNumber: user.phone,
                        verificationResponse: verificationResponse,
                        reRequestVerification: () => requestVerificationCode(
                          phone: user.phone,
                          context: context,
                          purpose: VerificationPurpose.deactivated,
                          accountApi: accountServer.client.accountApi,
                        ),
                        onVerification: (code, response) async {
                          final result = await accountServer.client.accountApi
                              .deactivateVerification(response.id, code);
                          return result.data.id;
                        },
                      );
                      if (verificationId == null || verificationId.isEmpty) {
                        return;
                      }
                      final deleted = await _showDeleteAccountPinDialog(
                        context,
                        verificationId: verificationId,
                      );
                      if (deleted) {
                        w('account deleted');
                        await accountServer.signOutAndClear();
                        ref.read(multiAuthNotifierProvider.notifier).signOut();
                      }
                    } else {
                      e('delete account no pin');
                    }
                  },
                ),
              ),
              CellGroup(
                cellBackgroundColor: theme.settingCellBackgroundColor,
                child: CellItem(
                  title: Text(l10n.changeNumberInstead),
                  onTap: () => showChangeNumberDialog(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteWarningWidget extends ConsumerWidget {
  const _DeleteWarningWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    return Column(
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
              _WarningItem(title: l10n.deleteAccountHint),
              _WarningItem(title: l10n.deleteAccountDetailHint),
              _WarningItem(title: l10n.transactionsCannotBeDeleted),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarningItem extends ConsumerWidget {
  const _WarningItem({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(
      brightnessThemeDataProvider.select((value) => value.text),
    );
    return SizedBox(
      width: 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 7, right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(title, style: TextStyle(color: color, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

Future<bool> _showDeleteAccountPinDialog(
  BuildContext context, {
  required String verificationId,
}) async {
  final confirmed = await showMixinDialog<bool>(
    context: context,
    child: _DeleteAccountPinDialog(verificationId: verificationId),
    barrierDismissible: false,
  );
  return confirmed == true;
}

class _DeleteAccountPinDialog extends HookConsumerWidget {
  const _DeleteAccountPinDialog({required this.verificationId});

  final String verificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final textSpan = useMemoized(() {
      final content = l10n.settingDeleteAccountPinContent(
        DateFormat.yMMMd().format(DateTime.now().add(const Duration(days: 30))),
      );

      final index = content.indexOf(l10n.learnMore);
      if (index == -1) return TextSpan(text: content);

      return TextSpan(
        text: content.substring(0, index),
        children: [
          TextSpan(
            text: l10n.learnMore,
            style: TextStyle(color: theme.accent),
            recognizer: TapGestureRecognizer()
              ..onTap = () => openUri(
                context,
                l10n.settingDeleteAccountUrl,
                container: ref.container,
              ),
          ),
          TextSpan(
            text: content.substring(
              index + l10n.learnMore.length,
            ),
          ),
        ],
      );
    }, []);
    return SizedBox(
      width: 520,
      height: 326,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 72),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  l10n.enterPinToDeleteAccount,
                  style: TextStyle(color: theme.red, fontSize: 18),
                ),
                const SizedBox(height: 29),
                PinInputLayout(
                  doVerify: (pin) async {
                    await accountServer.client.accountApi.deactivate(
                      DeactivateRequest(encryptPin(pin)!, verificationId),
                    );
                    Navigator.pop(context, true);
                  },
                ),
                const SizedBox(height: 29),
                CustomText.rich(
                  textSpan,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.text,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(22),
              child: MixinCloseButton(),
            ),
          ),
        ],
      ),
    );
  }
}
