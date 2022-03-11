// ignore_for_file: implementation_imports

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl_phone_number_input/src/models/country_model.dart';
import 'package:intl_phone_number_input/src/providers/country_provider.dart';
import 'package:intl_phone_number_input/src/utils/phone_number/phone_number_util.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/logger.dart';
import '../../widgets/az_selection.dart';
import '../../widgets/dialog.dart';
import 'bloc/landing_cubit.dart';
import 'landing.dart';

class LoginWithMobileWidget extends HookWidget {
  const LoginWithMobileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = useMemoized(() => Localizations.localeOf(context));
    return BlocProvider<LandingMobileCubit>(
      create: (_) => LandingMobileCubit(context.multiAuthCubit, locale),
      child: HookBuilder(builder: (context) {
        final counties =
            useMemoizedFuture(() => compute(_getCountries, null), null).data;
        if (counties == null || counties.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: context.theme.accent,
            ),
          );
        }
        return _LoginWithMobileWidget(countries: counties);
      }),
    );
  }
}

class _LoginWithMobileWidget extends HookWidget {
  _LoginWithMobileWidget({
    Key? key,
    required this.countries,
  })  : assert(countries.isNotEmpty),
        super(key: key);

  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    final phoneInputController = useTextEditingController();
    final captchaInputController = useTextEditingController();
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
    return Column(
      children: [
        const SizedBox(height: 70),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: _MobileInput(
              controller: phoneInputController,
              country: selectedCountry.value,
              countryPortalExpand: portalVisibility.value,
              onCountryDiaClick: () {
                portalVisibility.value = !portalVisibility.value;
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: _CaptchaInput(controller: captchaInputController),
        ),
        const SizedBox(height: 48),
        MixinButton(
          padding: const EdgeInsets.symmetric(
            horizontal: 60,
            vertical: 14,
          ),
          onTap: () {},
          child: Text(
            context.l10n.login,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        const Spacer(),
        const LandingModeSwitchButton(),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _CaptchaInput extends StatelessWidget {
  const _CaptchaInput({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        style: TextStyle(
          fontSize: 16,
          color: context.theme.text,
        ),
        decoration: InputDecoration(
          fillColor: context.theme.sidebarSelected,
          filled: true,
          hintText: context.l10n.captchaHint,
          hintStyle: TextStyle(
            fontSize: 16,
            color: context.theme.secondaryText,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          prefixIcon: SizedBox(
            width: 108,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  context.l10n.captcha,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.theme.text,
                  ),
                ),
              ),
            ),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      );
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
        decoration: InputDecoration(
          fillColor: context.theme.sidebarSelected,
          filled: true,
          hintText: context.l10n.loginMobileInputHint,
          hintStyle: TextStyle(
            fontSize: 16,
            color: context.theme.secondaryText,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onCountryDiaClick,
              child: SizedBox(
                width: 78,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      country.dialCode ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.theme.text,
                      ),
                    ),
                    const Spacer(),
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
                  ],
                ),
              ),
            ),
          ),
          suffixIcon: _GetVerificationCodeButton(
              controller: controller, country: country),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      );
}

class _GetVerificationCodeButton extends StatelessWidget {
  const _GetVerificationCodeButton({
    Key? key,
    required this.controller,
    required this.country,
  }) : super(key: key);

  final TextEditingController controller;
  final Country country;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              final mobileNumberStr = controller.text;
              if (mobileNumberStr.isEmpty) {
                return;
              }
              try {
                final valid = await PhoneNumberUtil.isValidNumber(
                    phoneNumber: mobileNumberStr,
                    isoCode: country.alpha2Code ?? '');
                if (valid != true) {
                  return;
                }
              } catch (error) {
                e('Phone number validation error: $error');
                return;
              }
              final dialCode = country.dialCode;
              assert(dialCode != null, 'dialCode is null. $country');
              if (dialCode == null) {
                e('Invalid dial code: $country');
                return;
              }
              final request = VerificationRequest(
                phone: dialCode + mobileNumberStr,
                purpose: VerificationPurpose.session,
              );
              try {
                final cubit = context.read<LandingMobileCubit>();
                final response =
                    await cubit.client.accountApi.verification(request);
                cubit.onVerified(mobileNumberStr, response.data);
              } on MixinApiError catch (error) {
                e('Verification api error: $error');
                final mixinError = error.error as MixinError;
                if (mixinError.code == needCaptcha) {
                  // TODO: show captcha
                }
              } catch (error) {
                e('Verification error: $error');
                return;
              }
            },
            child: Text(
              context.l10n.getCaptcha,
              style: TextStyle(
                fontSize: 14,
                color: context.theme.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      );
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
