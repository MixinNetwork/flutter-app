import 'dart:async';
import 'dart:convert';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../account/session_key_value.dart';
import '../../constants/resources.dart';
import '../../crypto/signal/signal_protocol.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../../utils/mixin_api_client.dart';
import '../../utils/platform.dart';
import '../../utils/system/package_info.dart';
import '../../widgets/action_button.dart';
import '../../widgets/dialog.dart';
import '../../widgets/toast.dart';
import '../../widgets/user/captcha_web_view_dialog.dart';
import '../../widgets/user/phone_number_input.dart';
import '../../widgets/user/verification_dialog.dart';
import '../provider/hive_key_value_provider.dart';
import '../provider/multi_auth_provider.dart';
import 'landing.dart';

final _mobileClientProvider = Provider.autoDispose<Client>(
  (ref) => createLandingClient(),
);

class LoginWithMobileWidget extends HookConsumerWidget {
  const LoginWithMobileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // keep client provider alive in mobile widget.
    ref.watch(_mobileClientProvider);
    return Navigator(
      onPopPage: (_, __) => true,
      pages: const [
        MaterialPage(
          child: _PhoneNumberInputScene(),
        ),
      ],
    );
  }
}

class _PhoneNumberInputScene extends ConsumerWidget {
  const _PhoneNumberInputScene();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        children: [
          const SizedBox(height: 56),
          Expanded(
            child: PhoneNumberInputLayout(onNextStep: (phoneNumber) async {
              final ret = await showConfirmMixinDialog(
                context,
                context.l10n.landingInvitationDialogContent(phoneNumber),
                maxWidth: 440,
              );
              if (ret == null) return;
              showToastLoading();
              try {
                final response = await _requestVerificationCode(
                  phone: phoneNumber,
                  context: context,
                  client: ref.read(_mobileClientProvider),
                );
                Toast.dismiss();
                if (response.deactivatedAt?.isNotEmpty ?? false) {
                  final date =
                      DateTime.parse(response.deactivatedAt!).toLocal();
                  final continueLogin = await showConfirmMixinDialog(
                    context,
                    context.l10n.loginAndAbortAccountDeletion,
                    description: context.l10n.landingDeleteContent(
                      DateFormat().format(date),
                    ),
                    maxWidth: 440,
                    positiveText: context.l10n.continueText,
                    negativeText: context.l10n.cancel,
                    barrierDismissible: false,
                  );
                  if (continueLogin == null) {
                    i('User canceled login and deactivatedAt is not empty');
                    return;
                  }
                }
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _CodeInputScene(
                      phoneNumber: phoneNumber,
                      initialVerificationResponse: response,
                    ),
                  ),
                );
              } on MixinApiError catch (error) {
                e('Error requesting verification code: $error');
                final mixinError = error.error! as MixinError;
                showToastFailed(
                  ToastError(mixinError.toDisplayString(context)),
                );
                return;
              } catch (error) {
                e('Error requesting verification code: $error');
                showToastFailed(null);
                return;
              }
            }),
          ),
          const SizedBox(height: 30),
          const LandingModeSwitchButton(),
          const SizedBox(height: 40),
        ],
      );
}

class _CodeInputScene extends HookConsumerWidget {
  const _CodeInputScene({
    required this.phoneNumber,
    required this.initialVerificationResponse,
  });

  final String phoneNumber;
  final VerificationResponse initialVerificationResponse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeInputController = useTextEditingController();

    final verification =
        useRef<VerificationResponse>(initialVerificationResponse);

    Future<void> performLogin(String code) async {
      assert(code.length == 4, 'Invalid code length: $code');
      showToastLoading();
      try {
        final registrationId = generateRegistrationId(false);

        final sessionKey = ed.generateKey();
        final sessionSecret = base64Encode(sessionKey.publicKey.bytes);

        final packageInfo = await getPackageInfo();
        final platformVersion = await getPlatformVersion();

        final accountRequest = AccountRequest(
          code: code,
          registrationId: registrationId,
          purpose: VerificationPurpose.session,
          platform: 'Android',
          platformVersion: platformVersion,
          appVersion: packageInfo.version,
          packageName: 'one.mixin.messenger',
          sessionSecret: sessionSecret,
          pin: '',
        );
        final client = ref.read(_mobileClientProvider);
        final response = await client.accountApi.create(
          verification.value.id,
          accountRequest,
        );

        final identityNumber = response.data.identityNumber;
        await SignalProtocol.initSignal(identityNumber, registrationId, null);

        final privateKey = base64Encode(sessionKey.privateKey.bytes);

        final cryptoKeyValue =
            await ref.read(cryptoKeyValueProvider(identityNumber).future);
        cryptoKeyValue.localRegistrationId = registrationId;

        await SessionKeyValue.instance.init(identityNumber);
        SessionKeyValue.instance.pinToken = base64Encode(decryptPinToken(
          response.data.pinToken,
          sessionKey.privateKey,
        ));
        context.multiAuthChangeNotifier
            .signIn(AuthState(account: response.data, privateKey: privateKey));
        Toast.dismiss();
      } catch (error) {
        e('login account error: $error');
        if (error is MixinApiError) {
          final mixinError = error.error! as MixinError;
          showToastFailed(
            ToastError(mixinError.toDisplayString(context)),
          );
        } else {
          showToastFailed(null);
        }
        return;
      }
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
          ResendCodeWidget(
            onResend: () async {
              showToastLoading();
              try {
                final response = await _requestVerificationCode(
                  phone: phoneNumber,
                  context: context,
                  client: ref.read(_mobileClientProvider),
                );
                Toast.dismiss();
                verification.value = response;
                return true;
              } on MixinApiError catch (error) {
                e('Error requesting verification code: $error');
                final mixinError = error.error! as MixinError;
                showToastFailed(
                  ToastError(mixinError.toDisplayString(context)),
                );
                return false;
              } catch (error) {
                e('Error requesting verification code: $error');
                showToastFailed(null);
                return false;
              }
            },
          ),
          const Spacer(),
          MixinButton(
            disable: codeInputController.text.length < 4,
            padding: const EdgeInsets.symmetric(
              horizontal: 60,
              vertical: 14,
            ),
            onTap: () => performLogin(codeInputController.text),
            child: Text(context.l10n.signIn),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

Future<VerificationResponse> _requestVerificationCode({
  required String phone,
  required BuildContext context,
  required Client client,
  (CaptchaType, String)? captcha,
}) async {
  final request = VerificationRequest(
    phone: phone,
    purpose: VerificationPurpose.session,
    packageName: 'one.mixin.messenger',
    gRecaptchaResponse:
        captcha?.$1 == CaptchaType.gCaptcha ? captcha?.$2 : null,
    hCaptchaResponse: captcha?.$1 == CaptchaType.hCaptcha ? captcha?.$2 : null,
  );
  try {
    final response = await client.accountApi.verification(request);
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
        return _requestVerificationCode(
          phone: phone,
          context: context,
          client: client,
          captcha: (type, token),
        );
      }
    }
    rethrow;
  } catch (error) {
    rethrow;
  }
}
