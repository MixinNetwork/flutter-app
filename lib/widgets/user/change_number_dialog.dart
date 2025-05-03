import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide encryptPin;

import '../../account/session_key_value.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../../utils/platform.dart';
import '../../utils/system/package_info.dart';
import '../dialog.dart';
import '../toast.dart';
import 'phone_number_input.dart';
import 'pin_verification_dialog.dart';
import 'verification_dialog.dart';

Future<void> showChangeNumberDialog(BuildContext context) async {
  final pinCode = await showPinVerificationDialog(
    context,
    title: context.l10n.verifyPin,
  );
  if (pinCode == null) {
    i('showChangeNumberDialog: Pin verification failed');
    return;
  }
  final phoneNumber = await _showPhoneNumberInputDialog(context);
  if (phoneNumber == null) {
    i('showChangeNumberDialog: Phone number input canceled');
    return;
  }

  VerificationResponse? response;
  try {
    showToastLoading();
    response = await requestVerificationCode(
      phone: phoneNumber,
      context: context,
      purpose: VerificationPurpose.phone,
    );
    Toast.dismiss();
  } catch (error, stacktrace) {
    e('showChangeNumberDialog: $error $stacktrace');
    showToastFailed(error);
    return;
  }

  final account = await showVerificationDialog(
    context,
    phoneNumber: phoneNumber,
    verificationResponse: response,
    reRequestVerification:
        () => requestVerificationCode(
          phone: phoneNumber,
          context: context,
          purpose: VerificationPurpose.phone,
        ),
    onVerification: (code, response) async {
      final packageInfo = await getPackageInfo();
      final platformVersion = await getPlatformVersion();
      final result = await context.accountServer.client.accountApi.create(
        response.id,
        AccountRequest(
          purpose: VerificationPurpose.phone,
          platform: 'Android',
          platformVersion: platformVersion,
          appVersion: packageInfo.version,
          packageName: 'one.mixin.messenger',
          pin: encryptPin(pinCode),
          code: code,
        ),
      );
      return result.data;
    },
  );
  if (account == null) {
    i('showChangeNumberDialog: Verification failed');
    return;
  }
  context.multiAuthChangeNotifier.updateAccount(account);
  showToastSuccessful();
}

Future<String?> _showPhoneNumberInputDialog(BuildContext context) =>
    showMixinDialog<String>(
      context: context,
      child: SizedBox(
        width: 520,
        height: 402,
        child: Column(
          children: [
            const SizedBox(height: 56),
            Expanded(
              child: Builder(
                builder:
                    (context) => PhoneNumberInputLayout(
                      onNextStep:
                          (phoneNumber) => Navigator.pop(context, phoneNumber),
                    ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
