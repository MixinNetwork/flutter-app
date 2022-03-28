// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl_phone_number_input/src/models/country_model.dart';
import 'package:intl_phone_number_input/src/providers/country_provider.dart';
import 'package:intl_phone_number_input/src/utils/phone_number/phone_number_util.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../account/account_key_value.dart';
import '../../constants/resources.dart';
import '../../crypto/crypto_key_value.dart';
import '../../crypto/signal/signal_protocol.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/logger.dart';
import '../../utils/platform.dart';
import '../../utils/system/package_info.dart';
import '../../widgets/action_button.dart';
import '../../widgets/az_selection.dart';
import '../../widgets/dialog.dart';
import '../../widgets/interactive_decorated_box.dart';
import '../../widgets/toast.dart';
import '../home/bloc/multi_auth_cubit.dart';
import 'bloc/landing_cubit.dart';
import 'landing.dart';

class LoginWithMobileWidget extends HookWidget {
  const LoginWithMobileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = useMemoized(() => Localizations.localeOf(context));
    final userAgent = useMemoizedFuture(
      () async => generateUserAgent(await getPackageInfo()),
      null,
    ).data;
    final deviceId = useMemoizedFuture(
      getDeviceId,
      null,
    ).data;

    if (userAgent == null || deviceId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return BlocProvider<LandingMobileCubit>(
      create: (_) => LandingMobileCubit(context.multiAuthCubit, locale,
          userAgent: userAgent, deviceId: deviceId),
      child: Navigator(
        onPopPage: (_, __) => true,
        pages: [
          MaterialPage(
            child: HookBuilder(builder: (context) {
              final counties =
                  useMemoizedFuture(() => compute(_getCountries, null), null)
                      .data;
              if (counties == null || counties.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.theme.accent,
                  ),
                );
              }
              return _PhoneNumberInputScene(countries: counties);
            }),
          ),
        ],
      ),
    );
  }
}

class _PhoneNumberInputScene extends HookWidget {
  const _PhoneNumberInputScene({
    Key? key,
    required this.countries,
  }) : super(key: key);
  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    final phoneInputController = useTextEditingController();
    final countryMap = useMemoized(
        () => Map.fromEntries(countries.map((e) => MapEntry(e.alpha2Code, e))),
        [countries]);
    final defaultCountry = useMemoized(
      () {
        i('locale: ${WidgetsBinding.instance.window.locale.countryCode}');
        return countryMap[WidgetsBinding.instance.window.locale.countryCode] ??
            countries.first;
      },
    );
    final selectedCountry = useState<Country>(defaultCountry);
    final portalVisibility = useState<bool>(false);

    final nextButtonEnable = useState<bool>(false);
    useEffect(() {
      Future<void> onChange() async {
        nextButtonEnable.value = false;
        try {
          final valid = await PhoneNumberUtil.isValidNumber(
              phoneNumber: phoneInputController.text,
              isoCode: selectedCountry.value.alpha2Code ?? '');
          if (valid != true) {
            return;
          }
        } catch (error) {
          e('Phone number validation error: $error');
          return;
        }
        nextButtonEnable.value = true;
      }

      phoneInputController.addListener(onChange);
      return () {
        phoneInputController.removeListener(onChange);
      };
    }, [phoneInputController, selectedCountry.value]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Column(
        children: [
          const SizedBox(height: 56),
          Text(
            context.l10n.enterYourPhoneNumber,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.theme.text,
            ),
          ),
          const SizedBox(height: 24),
          PortalEntry(
            visible: portalVisibility.value,
            portal: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Material(
                color: context.theme.chatBackground,
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 360,
                  height: 400,
                  child: SizedBox.fromSize(
                    size: const Size(360, 400),
                    child: _CountryPickPortal(
                      countries: countries,
                      selected: selectedCountry.value,
                      onSelected: (country) {
                        selectedCountry.value = country;
                        portalVisibility.value = false;
                      },
                    ),
                  ),
                ),
              ),
            ),
            portalAnchor: Alignment.topCenter,
            childAnchor: Alignment.bottomCenter,
            child: _MobileInput(
              controller: phoneInputController,
              country: selectedCountry.value,
              countryPortalExpand: portalVisibility.value,
              onCountryDiaClick: () {
                portalVisibility.value = !portalVisibility.value;
              },
            ),
          ),
          const Spacer(),
          MixinButton(
            disable: !nextButtonEnable.value,
            padding: const EdgeInsets.symmetric(
              horizontal: 60,
              vertical: 14,
            ),
            onTap: () async {
              final dialCode = selectedCountry.value.dialCode;
              assert(dialCode != null,
                  'dialCode is null. ${selectedCountry.value}');
              if (dialCode == null) {
                e('Invalid dial code: ${selectedCountry.value}');
                return;
              }
              final mobileNumberStr = phoneInputController.text;
              if (mobileNumberStr.isEmpty) {
                return;
              }
              final phoneNumber = dialCode + mobileNumberStr;
              final ret = await showConfirmMixinDialog(
                context,
                context.l10n.sendCodeConfirm(phoneNumber),
                maxWidth: 440,
              );
              if (!ret) {
                return;
              }

              showToastLoading(context);
              try {
                final response = await _requestVerificationCode(
                  phone: phoneNumber,
                  context: context,
                );
                Toast.dismiss();
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
                final mixinError = error.error as MixinError;
                await showToastFailed(
                  context,
                  ToastError(mixinError.toDisplayString(context)),
                );
                return;
              } catch (error) {
                e('Error requesting verification code: $error');
                await showToastFailed(context, null);
                return;
              }
            },
            child: Text(
              context.l10n.next,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          const SizedBox(height: 20),
          const LandingModeSwitchButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _CodeInputScene extends HookWidget {
  const _CodeInputScene({
    Key? key,
    required this.phoneNumber,
    required this.initialVerificationResponse,
  }) : super(key: key);

  final String phoneNumber;
  final VerificationResponse initialVerificationResponse;

  @override
  Widget build(BuildContext context) {
    final codeInputController = useTextEditingController();

    final verification =
        useRef<VerificationResponse>(initialVerificationResponse);

    Future<void> performLogin(String code) async {
      d('Code input complete: $code');
      assert(code.length == 4, 'Invalid code length: $code');
      showToastLoading(context);
      try {
        await CryptoKeyValue.instance.init();
        await AccountKeyValue.instance.init();

        await SignalProtocol.initSignal(null);

        final registrationId = CryptoKeyValue.instance.localRegistrationId;
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
        final client = context.read<LandingMobileCubit>().client;
        final response = await client.accountApi.create(
          verification.value.id,
          accountRequest,
        );
        final privateKey = base64Encode(sessionKey.privateKey.bytes);
        context.multiAuthCubit.signIn(
          AuthState(account: response.data, privateKey: privateKey),
        );
        Toast.dismiss();
      } catch (error) {
        e('login account error: $error');
        if (error is MixinApiError) {
          final mixinError = error.error as MixinError;
          await showToastFailed(
            context,
            ToastError(mixinError.toDisplayString(context)),
          );
        } else {
          await showToastFailed(context, null);
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
              context.l10n.enterVerificationCode(phoneNumber),
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
                final response = await _requestVerificationCode(
                  phone: phoneNumber,
                  context: context,
                );
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
          const Spacer(),
          MixinButton(
            disable: codeInputController.text.length < 4,
            padding: const EdgeInsets.symmetric(
              horizontal: 60,
              vertical: 14,
            ),
            onTap: () => performLogin(codeInputController.text),
            child: Text(context.l10n.login),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _ResendCodeWidget extends HookWidget {
  const _ResendCodeWidget({
    Key? key,
    required this.onResend,
  }) : super(key: key);

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

    if (nextDuration.value > 0) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          context.l10n.resendCodeIn(nextDuration.value),
          style: TextStyle(
            fontSize: 14,
            color: context.theme.secondaryText,
          ),
        ),
      );
    } else {
      return InteractiveDecoratedBox(
        onTap: () async {
          if (await onResend()) {
            nextDuration.value = 60;
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            context.l10n.resendCode,
            style: TextStyle(
              fontSize: 14,
              color: context.theme.accent,
            ),
          ),
        ),
      );
    }
  }
}

class _MobileInput extends HookWidget {
  const _MobileInput({
    Key? key,
    required this.controller,
    required this.country,
    required this.onCountryDiaClick,
    required this.countryPortalExpand,
  }) : super(key: key);

  final TextEditingController controller;
  final Country country;
  final VoidCallback onCountryDiaClick;
  final bool countryPortalExpand;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        style: TextStyle(
          fontSize: 16,
          color: context.theme.text,
        ),
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        autofillHints: const [
          AutofillHints.telephoneNumber,
        ],
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          fillColor: context.theme.sidebarSelected,
          filled: true,
          hintStyle: TextStyle(
            fontSize: 16,
            color: context.theme.secondaryText,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          prefixIcon: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onCountryDiaClick,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 20),
                Text(
                  country.dialCode ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.theme.text,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: countryPortalExpand ? -0.25 : 0.25,
                  duration: const Duration(milliseconds: 200),
                  child: SvgPicture.asset(
                    Resources.assetsImagesIcArrowRightSvg,
                    width: 30,
                    height: 30,
                    color: context.theme.secondaryText,
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      );
}

Future<VerificationResponse> _requestVerificationCode({
  required String phone,
  required BuildContext context,
  Tuple2<_CaptchaType, String>? captcha,
}) async {
  final request = VerificationRequest(
    phone: phone,
    purpose: VerificationPurpose.session,
    packageName: 'one.mixin.messenger',
    gRecaptchaResponse:
        captcha?.item1 == _CaptchaType.gCaptcha ? captcha?.item2 : null,
    hCaptchaResponse:
        captcha?.item1 == _CaptchaType.hCaptcha ? captcha?.item2 : null,
  );
  try {
    final cubit = context.read<LandingMobileCubit>();
    final response = await cubit.client.accountApi.verification(request);
    return response.data;
  } on MixinApiError catch (error) {
    final mixinError = error.error as MixinError;
    if (mixinError.code == needCaptcha) {
      final result = await showMixinDialog<List<dynamic>>(
        context: context,
        child: const _CaptchaWebViewDialog(),
      );
      if (result != null) {
        assert(result.length == 2, 'Invalid result length');
        final type = result[0] as _CaptchaType;
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

List<Country> _getCountries(dynamic any) =>
    CountryProvider.getCountriesData(countries: null);

class _CountryPickPortal extends HookWidget {
  const _CountryPickPortal({
    Key? key,
    required this.onSelected,
    required this.countries,
    required this.selected,
  }) : super(key: key);

  final void Function(Country country) onSelected;
  final List<Country> countries;
  final Country selected;

  @override
  Widget build(BuildContext context) {
    final groupedCountries = useMemoized(
      () => countries
          .groupListsBy((country) => country.alpha2Code?.substring(0, 1)),
      [countries],
    );
    final countryList = useMemoized(
        () => groupedCountries.entries
            .sortedBy<String>((element) => element.key ?? '')
            .map((entry) => <dynamic>[
                  entry.key,
                  ...entry.value.sortedBy<String>((e) => e.name ?? '')
                ])
            .expand((element) => element)
            .toList(),
        [groupedCountries]);

    final items = [
      selected,
      ...countryList,
    ];

    final controller = useScrollController();

    final animatedTarget = useStreamController<String>();

    useEffect(() {
      final subscription = animatedTarget.stream
          .distinct()
          .throttleTime(const Duration(milliseconds: 300))
          .listen((char) {
        final stopwatch = Stopwatch()..start();
        final offset = math.max<double>(40.0 * items.indexOf(char), 0);
        controller.position.jumpTo(offset);
        d('scroll to $char ${stopwatch.elapsedMilliseconds}');
      });
      return subscription.cancel;
    }, [animatedTarget]);

    return Stack(
      fit: StackFit.expand,
      children: [
        MediaQuery.removePadding(
          removeTop: true,
          context: context,
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.only(top: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is Country) {
                return _CountryItem(
                  country: item,
                  onTap: () => onSelected(item),
                  isSelected: item == selected,
                );
              } else if (item is String) {
                return _CharIndexItem(char: item);
              }
              assert(false, 'Invalid item: $item');
              return const SizedBox();
            },
            itemCount: items.length,
          ),
        ),
        Positioned(
          right: 0,
          top: 20,
          bottom: 20,
          width: 20,
          child: AZSelection(
            textStyle: TextStyle(
              fontSize: 10,
              color: context.theme.secondaryText,
            ),
            onSelection: animatedTarget.add,
          ),
        )
      ],
    );
  }
}

class _CharIndexItem extends StatelessWidget {
  const _CharIndexItem({
    Key? key,
    required this.char,
  }) : super(key: key);

  final String char;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Text(
              char,
              style: TextStyle(
                fontSize: 14,
                color: context.theme.secondaryText,
              ),
            ),
          ],
        ),
      );
}

class _CountryItem extends StatelessWidget {
  const _CountryItem({
    Key? key,
    required this.country,
    required this.onTap,
    required this.isSelected,
  }) : super(key: key);

  final Country country;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? context.theme.accent : context.theme.text,
          ),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  child: Text(country.dialCode ?? ''),
                ),
                Text(country.nameTranslations?[
                        Localizations.localeOf(context).languageCode] ??
                    country.name ??
                    ''),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      );
}

class _CaptchaWebViewDialog extends HookWidget {
  const _CaptchaWebViewDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timer = useRef<Timer?>(null);
    final controllerRef = useRef<WebViewController?>(null);
    final captcha = useRef<_CaptchaType>(_CaptchaType.gCaptcha);
    useEffect(
      () => () {
        timer.value?.cancel();
      },
      [],
    );

    void loadFallback() {
      if (captcha.value == _CaptchaType.gCaptcha) {
        captcha.value = _CaptchaType.hCaptcha;
        _loadCaptcha(controllerRef.value!, _CaptchaType.hCaptcha);
      } else {
        controllerRef.value!.loadUrl('about:blank');
        showToastFailed(
          context,
          ToastError(context.l10n.errorRecaptchaTimeout),
        );
        Navigator.pop(context);
      }
    }

    return SizedBox(
      width: 400,
      height: 520,
      child: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (controller) {
          controllerRef.value = controller;
          _loadCaptcha(controller, captcha.value);
        },
        onPageStarted: (url) {
          timer.value = Timer(const Duration(seconds: 15), loadFallback);
        },
        onPageFinished: (url) {
          timer.value?.cancel();
          timer.value = null;
        },
        javascriptChannels: {
          JavascriptChannel(
            name: 'MixinContextTokenCallback',
            onMessageReceived: (message) {
              timer.value?.cancel();
              timer.value = null;
              final token = message.message;
              Navigator.pop(context, [captcha.value, token]);
            },
          ),
          JavascriptChannel(
            name: 'MixinContextErrorCallback',
            onMessageReceived: (message) {
              e('on captcha error: ${message.message}');
              timer.value?.cancel();
              timer.value = null;
              loadFallback();
            },
          ),
        },
      ),
    );
  }
}

enum _CaptchaType {
  gCaptcha,
  hCaptcha,
}

const _kRecaptchaKey = '';
const _hCaptchaKey = '';

Future<void> _loadCaptcha(
  WebViewController controller,
  _CaptchaType type,
) async {
  i('load captcha: $type');
  final html = await rootBundle.loadString(Resources.assetsCaptchaHtml);
  final String apiKey;
  final String src;
  switch (type) {
    case _CaptchaType.gCaptcha:
      apiKey = _kRecaptchaKey;
      src = 'https://www.recaptcha.net/recaptcha/api.js'
          '?onload=onGCaptchaLoad&render=explicit';
      break;
    case _CaptchaType.hCaptcha:
      apiKey = _hCaptchaKey;
      src = 'https://hcaptcha.com/1/api.js'
          '?onload=onHCaptchaLoad&render=explicit';
      break;
  }
  final htmlWithCaptcha =
      html.replaceAll('#src', src).replaceAll('#apiKey', apiKey);

  await controller.clearCache();
  await controller.loadHtmlString(
    htmlWithCaptcha,
    baseUrl: 'https://mixin.one',
  );
}
