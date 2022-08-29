import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:tuple/tuple.dart';

import '../../account/session_key_value.dart';
import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../../widgets/toast.dart';
import '../../widgets/user/captcha_web_view_dialog.dart';
import '../../widgets/user/pin_verification_dialog.dart';
import '../../widgets/user/verification_dialog.dart';
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
                        d('verified');
                        final confirmed = await showConfirmMixinDialog(
                          context,
                          context.l10n
                              .landingInvitationDialogContent(user.phone),
                          maxWidth: 440,
                          positiveText: context.l10n.continueText,
                        );
                        if (!confirmed) {
                          return;
                        }
                        showToastLoading(context);
                        VerificationResponse? verificationResponse;

                        try {
                          verificationResponse = await _requestVerificationCode(
                            phone: user.phone,
                            context: context,
                          );
                        } catch (error, stacktrace) {
                          e('_requestVerificationCode $error, $stacktrace');
                          await showToastFailed(context, error);
                          return;
                        }
                        final result = await showVerificationDialog(
                          context,
                          phoneNumber: user.phone,
                          verificationResponse: verificationResponse,
                        );
                      } else {
                        e('delete account no pin');
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

Future<bool> showVerificationDialog(
  BuildContext context, {
  required String phoneNumber,
  required VerificationResponse verificationResponse,
}) async {
  final ret = await showMixinDialog<bool>(
      context: context,
      child: _VerificationCodeDialog(
        phoneNumber,
        verificationResponse,
      ));
  return ret == true;
}

class _VerificationCodeDialog extends StatelessWidget {
  const _VerificationCodeDialog(
    this.phoneNumber,
    this.initialVerificationResponse,
  );

  final String phoneNumber;
  final VerificationResponse initialVerificationResponse;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 520,
        child: VerificationCodeInputLayout(
          phoneNumber: phoneNumber,
          initialVerificationResponse: initialVerificationResponse,
          reRequestVerification: () => _requestVerificationCode(
            context: context,
            phone: phoneNumber,
          ),
          onVerification: (code, response) async {
            try {
              final result = await context.accountServer.client.accountApi
                  .deactiveVerification(response.id, code);
              d('deactiveVerification result: $result');
            } catch (error, stacktrace) {
              e('de-active Verification error: $error $stacktrace');
              await showToastFailed(context, error);
            }
          },
        ),
      );
}

Future<VerificationResponse> _requestVerificationCode({
  required String phone,
  required BuildContext context,
  Tuple2<CaptchaType, String>? captcha,
}) async {
  final request = VerificationRequest(
    phone: phone,
    purpose: VerificationPurpose.deactivated,
    packageName: 'one.mixin.messenger',
    gRecaptchaResponse:
        captcha?.item1 == CaptchaType.gCaptcha ? captcha?.item2 : null,
    hCaptchaResponse:
        captcha?.item1 == CaptchaType.hCaptcha ? captcha?.item2 : null,
  );
  try {
    final response =
        await context.accountServer.client.accountApi.verification(request);
    return response.data;
  } on MixinApiError catch (error) {
    final mixinError = error.error as MixinError;
    if (mixinError.code == needCaptcha) {
      Toast.dismiss();
      final result = await showCaptchaWebViewDialog(context);
      if (result != null) {
        assert(result.length == 2, 'Invalid result length');
        final type = result.first as CaptchaType;
        final token = result[1] as String;
        d('Captcha type: $type, token: $token');
        return _requestVerificationCode(
          phone: phone,
          context: context,
          captcha: Tuple2(type, token),
        );
      }
    }
    rethrow;
  } catch (error) {
    rethrow;
  }
}
