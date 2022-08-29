import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../action_button.dart';
import '../interactive_decorated_box.dart';
import '../toast.dart';

class VerificationCodeInputLayout extends HookWidget {
  const VerificationCodeInputLayout({
    super.key,
    required this.phoneNumber,
    required this.initialVerificationResponse,
    required this.reRequestVerification,
    required this.onVerification,
  });

  final String phoneNumber;
  final VerificationResponse initialVerificationResponse;

  final Future<VerificationResponse> Function() reRequestVerification;

  final Future<void> Function(String code, VerificationResponse response)
      onVerification;

  @override
  Widget build(BuildContext context) {
    final codeInputController = useTextEditingController();

    final verification =
        useRef<VerificationResponse>(initialVerificationResponse);

    Future<void> performLogin(String code) async {
      d('Code input complete: $code');
    }

    useListenable(codeInputController);
    return Material(
      color: context.theme.popUp,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 12),
                ActionButton(
                  name: Resources.assetsImagesIcBackSvg,
                  color: context.theme.icon,
                  onTap: () => Navigator.maybePop(context),
                ),
                const Spacer(),
              ],
            ),
          ),
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              keyboardType: TextInputType.number,
              onCompleted: performLogin,
              useHapticFeedback: true,
              pinTheme: PinTheme(
                activeColor: context.theme.accent,
                inactiveColor: context.theme.secondaryText,
                fieldWidth: 15,
                borderWidth: 2,
              ),
              textStyle: TextStyle(
                fontSize: 18,
                color: context.theme.text,
              ),
              onChanged: (String value) {},
            ),
          ),
          const SizedBox(height: 0),
          _ResendCodeWidget(
            onResend: () async {
              showToastLoading(context);
              try {
                final response = await reRequestVerification();
                Toast.dismiss();
                verification.value = response;
                return true;
              } on MixinApiError catch (error) {
                e('Error requesting verification code: $error');
                final mixinError = error.error as MixinError;
                await showToastFailed(
                  context,
                  ToastError(mixinError.toDisplayString(context)),
                );
                return false;
              } catch (error) {
                e('Error requesting verification code: $error');
                await showToastFailed(context, null);
                return false;
              }
            },
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _ResendCodeWidget extends HookWidget {
  const _ResendCodeWidget({required this.onResend});

  final Future<bool> Function() onResend;

  @override
  Widget build(BuildContext context) {
    final nextDuration = useState(60);
    useEffect(() {
      final timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          if (nextDuration.value > 0) {
            nextDuration.value = math.max(0, nextDuration.value - 1);
          }
        },
      );
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
