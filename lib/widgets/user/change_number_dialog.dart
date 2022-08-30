import 'package:flutter/widgets.dart';

import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../dialog.dart';
import 'captcha_web_view_dialog.dart';
import 'phone_number_input.dart';
import 'pin_verification_dialog.dart';

Future<void> showChangeNumberDialog(BuildContext context) async {
  final verified =
      await showPinVerificationDialog(context, title: context.l10n.verifyPin);
  if (!verified) {
    i('showChangeNumberDialog: Pin verification failed');
    return;
  }
  final phoneNumber = await _showPhoneNumberInputDialog(context);
  if (phoneNumber == null) {
    i('showChangeNumberDialog: Phone number input canceled');
    return;
  }

  showCaptchaWebViewDialog(context)
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
                builder: (context) => PhoneNumberInputLayout(
                  onNextStep: (phoneNumber) => Navigator.pop(context),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
