import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../dialog.dart';
import '../interactive_decorated_box.dart';
import '../toast.dart';
import 'captcha_web_view_dialog.dart';

// return: verification id.
Future<T?> showVerificationDialog<T>(
  BuildContext context, {
  required String phoneNumber,
  required VerificationResponse verificationResponse,
  required RequestVerification reRequestVerification,
  required VerifyPhoneCode<T> onVerification,
}) => showMixinDialog<T>(
  context: context,
  child: _VerificationCodeDialog(
    phoneNumber: phoneNumber,
    initialVerificationResponse: verificationResponse,
    reRequestVerification: reRequestVerification,
    onVerification: onVerification,
  ),
);

typedef RequestVerification = Future<VerificationResponse> Function();
typedef VerifyPhoneCode<T> =
    Future<T> Function(String code, VerificationResponse response);

class _VerificationCodeDialog<T> extends StatelessWidget {
  const _VerificationCodeDialog({
    required this.phoneNumber,
    required this.initialVerificationResponse,
    required this.reRequestVerification,
    required this.onVerification,
  });

  final String phoneNumber;
  final VerificationResponse initialVerificationResponse;
  final RequestVerification reRequestVerification;

  final VerifyPhoneCode<T> onVerification;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 520,
    height: 326,
    child: Column(
      children: [
        const SizedBox(height: 56),
        Material(
          color: context.theme.popUp,
          child: VerificationCodeInputLayout(
            phoneNumber: phoneNumber,
            initialVerificationResponse: initialVerificationResponse,
            reRequestVerification: reRequestVerification,
            onVerification: (code, response) async {
              showToastLoading();
              try {
                final result = await onVerification(code, response);
                d('_VerificationCodeDialog: result: $result');
                Navigator.pop(context, result);
                Toast.dismiss();
              } catch (error, stacktrace) {
                e('_VerificationCodeDialog error: $error $stacktrace');
                showToastFailed(error);
              }
            },
          ),
        ),
        const SizedBox(height: 77),
      ],
    ),
  );
}

Future<VerificationResponse> requestVerificationCode({
  required String phone,
  required BuildContext context,
  required VerificationPurpose purpose,
  (CaptchaType, String)? captcha,
  AccountApi? accountApi,
}) async {
  final request = VerificationRequest(
    phone: phone,
    purpose: purpose,
    packageName: 'one.mixin.messenger',
    gRecaptchaResponse: captcha?.$1 == CaptchaType.gCaptcha
        ? captcha?.$2
        : null,
    hCaptchaResponse: captcha?.$1 == CaptchaType.hCaptcha ? captcha?.$2 : null,
  );
  final api = accountApi ?? context.accountServer.client.accountApi;
  try {
    final response = await api.verification(request);
    return response.data;
  } on MixinApiError catch (error) {
    final mixinError = error.error! as MixinError;
    if (mixinError.code == needCaptcha) {
      Toast.dismiss();
      final result = await showCaptchaWebViewDialog(context);
      if (result != null) {
        assert(result.length == 2, 'Invalid result length');
        final type = result.first as CaptchaType;
        final token = result[1] as String;
        d('Captcha type: $type, token: $token');
        return requestVerificationCode(
          phone: phone,
          context: context,
          captcha: (type, token),
          purpose: purpose,
          accountApi: api,
        );
      }
    }
    rethrow;
  } catch (error) {
    rethrow;
  }
}

class VerificationCodeInputLayout extends HookConsumerWidget {
  const VerificationCodeInputLayout({
    required this.phoneNumber,
    required this.initialVerificationResponse,
    required this.reRequestVerification,
    required this.onVerification,
    super.key,
  });

  final String phoneNumber;
  final VerificationResponse initialVerificationResponse;

  final RequestVerification reRequestVerification;

  final void Function(String, VerificationResponse) onVerification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeInputController = useTextEditingController();
    final verification = useRef<VerificationResponse>(
      initialVerificationResponse,
    );
    useListenable(codeInputController);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 125),
          child: Text(
            context.l10n.landingValidationTitle(phoneNumber),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.theme.text,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 135,
          child: PinCodeTextField(
            autoFocus: true,
            length: 4,
            autoDisposeControllers: false,
            controller: codeInputController,
            appContext: context,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            onCompleted: (code) => onVerification(code, verification.value),
            useHapticFeedback: true,
            pinTheme: PinTheme(
              activeColor: context.theme.accent,
              inactiveColor: context.theme.secondaryText,
              fieldWidth: 15,
              borderWidth: 2,
            ),
            textStyle: TextStyle(fontSize: 18, color: context.theme.text),
            onChanged: (String value) {},
          ),
        ),
        const SizedBox(height: 0),
        ResendCodeWidget(
          onResend: () async {
            showToastLoading();
            try {
              final response = await reRequestVerification();
              Toast.dismiss();
              verification.value = response;
              return true;
            } on MixinApiError catch (error) {
              e('Error requesting verification code: $error');
              final mixinError = error.error! as MixinError;
              showToastFailed(ToastError(mixinError.toDisplayString(context)));
              return false;
            } catch (error) {
              e('Error requesting verification code: $error');
              showToastFailed(null);
              return false;
            }
          },
        ),
      ],
    );
  }
}

class ResendCodeWidget extends HookConsumerWidget {
  const ResendCodeWidget({required this.onResend, super.key});

  final Future<bool> Function() onResend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextDuration = useState(60);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (nextDuration.value > 0) {
          nextDuration.value = math.max(0, nextDuration.value - 1);
        }
      });
      return timer.cancel;
    }, [nextDuration]);

    return nextDuration.value > 0
        ? Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              context.l10n.resendCodeIn(nextDuration.value),
              style: TextStyle(
                fontSize: 14,
                color: context.theme.secondaryText,
              ),
            ),
          )
        : InteractiveDecoratedBox(
            onTap: () async {
              if (await onResend()) {
                nextDuration.value = 60;
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                context.l10n.resendCode,
                style: TextStyle(fontSize: 14, color: context.theme.accent),
              ),
            ),
          );
  }
}
