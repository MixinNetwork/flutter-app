// ignore_for_file: implementation_imports

import 'dart:math' as math;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl_phone_number_input/src/models/country_model.dart';
import 'package:intl_phone_number_input/src/providers/country_provider.dart';
import 'package:intl_phone_number_input/src/utils/phone_number/phone_number_util.dart';

import '../../constants/constants.dart';
import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/logger.dart';
import '../az_selection.dart';
import '../dialog.dart';

class PhoneNumberInputLayout extends HookConsumerWidget {
  const PhoneNumberInputLayout({required this.onNextStep, super.key});

  final void Function(String number) onNextStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries =
        useMemoizedFuture(() => compute(_getCountries, null), null).data;
    if (countries == null || countries.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: context.theme.accent),
      );
    }
    return _PhoneNumberInputScene(countries: countries, onNextStep: onNextStep);
  }
}

class _PhoneNumberInputScene extends HookConsumerWidget {
  const _PhoneNumberInputScene({
    required this.countries,
    required this.onNextStep,
  });

  final List<Country> countries;
  final void Function(String number) onNextStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneInputController = useTextEditingController();
    final countryMap = useMemoized(
      () => Map.fromEntries(countries.map((e) => MapEntry(e.alpha2Code, e))),
      [countries],
    );
    final defaultCountry = useMemoized(() {
      i('locale: ${PlatformDispatcher.instance.locale.countryCode}');
      return countryMap[PlatformDispatcher.instance.locale.countryCode] ??
          countries.first;
    });
    final selectedCountry = useState<Country>(defaultCountry);
    final portalVisibility = useState<bool>(false);

    final nextButtonEnable = useState<bool>(false);
    useEffect(() {
      Future<void> onChange() async {
        nextButtonEnable.value = false;
        try {
          final valid = await PhoneNumberUtil.isValidNumber(
            phoneNumber: phoneInputController.text,
            isoCode: selectedCountry.value.alpha2Code ?? '',
          );
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

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80),
        child: Column(
          children: [
            Text(
              context.l10n.enterYourPhoneNumber,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.theme.text,
              ),
            ),
            const SizedBox(height: 24),
            PortalTarget(
              visible: portalVisibility.value,
              portalFollower: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: Material(
                  color: context.theme.chatBackground,
                  elevation: 2,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
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
              anchor: const Aligned(
                follower: Alignment.topCenter,
                target: Alignment.bottomCenter,
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
              onTap: () {
                final dialCode = selectedCountry.value.dialCode;
                assert(
                  dialCode != null,
                  'dialCode is null. ${selectedCountry.value}',
                );
                if (dialCode == null) {
                  e('Invalid dial code: ${selectedCountry.value}');
                  return;
                }
                final mobileNumberStr = phoneInputController.text;
                if (mobileNumberStr.isEmpty) {
                  return;
                }
                final phoneNumber = dialCode + mobileNumberStr;
                onNextStep(phoneNumber);
              },
              child: Text(
                context.l10n.next,
                style: const TextStyle(fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileInput extends HookConsumerWidget {
  const _MobileInput({
    required this.controller,
    required this.country,
    required this.onCountryDiaClick,
    required this.countryPortalExpand,
  });

  final TextEditingController controller;
  final Country country;
  final VoidCallback onCountryDiaClick;
  final bool countryPortalExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextField(
    controller: controller,
    style: TextStyle(fontSize: 16, color: context.theme.text),
    textInputAction: TextInputAction.next,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(kDefaultTextInputLimit),
    ],
    autofillHints: const [AutofillHints.telephoneNumber],
    keyboardType: TextInputType.phone,
    decoration: InputDecoration(
      fillColor: context.theme.sidebarSelected,
      filled: true,
      hintStyle: TextStyle(fontSize: 16, color: context.theme.secondaryText),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide.none,
      ),
      prefixIcon: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        onTap: onCountryDiaClick,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 20),
            Text(
              country.dialCode ?? '',
              style: TextStyle(fontSize: 16, color: context.theme.text),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: countryPortalExpand ? -0.25 : 0.25,
              duration: const Duration(milliseconds: 200),
              child: SvgPicture.asset(
                Resources.assetsImagesIcArrowRightSvg,
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(
                  context.theme.secondaryText,
                  BlendMode.srcIn,
                ),
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

// for compute
// ignore: avoid-unused-parameters
List<Country> _getCountries(dynamic any) =>
    CountryProvider.getCountriesData(countries: null);

class _CountryPickPortal extends HookConsumerWidget {
  const _CountryPickPortal({
    required this.onSelected,
    required this.countries,
    required this.selected,
  });

  final void Function(Country country) onSelected;
  final List<Country> countries;
  final Country selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedCountries = useMemoized(
      () => countries.groupListsBy(
        (country) => country.alpha2Code?.substring(0, 1),
      ),
      [countries],
    );
    final countryList = useMemoized(
      () =>
          groupedCountries.entries
              .sortedBy<String>((element) => element.key ?? '')
              .map(
                (entry) => <dynamic>[
                  entry.key,
                  ...entry.value.sortedBy<String>((e) => e.name ?? ''),
                ],
              )
              .expand((element) => element)
              .toList(),
      [groupedCountries],
    );

    final items = [selected, ...countryList];

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
        ),
      ],
    );
  }
}

class _CharIndexItem extends StatelessWidget {
  const _CharIndexItem({required this.char});

  final String char;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Row(
      children: [
        const SizedBox(width: 20),
        Text(
          char,
          style: TextStyle(fontSize: 14, color: context.theme.secondaryText),
        ),
      ],
    ),
  );
}

class _CountryItem extends StatelessWidget {
  const _CountryItem({
    required this.country,
    required this.onTap,
    required this.isSelected,
  });

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
            SizedBox(width: 80, child: Text(country.dialCode ?? '')),
            Text(
              country.nameTranslations?[Localizations.localeOf(
                    context,
                  ).languageCode] ??
                  country.name ??
                  '',
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    ),
  );
}
