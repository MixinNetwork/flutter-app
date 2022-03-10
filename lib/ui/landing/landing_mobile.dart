import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/dialog.dart';
import 'bloc/landing_mobile_cubit.dart';
import 'landing.dart';

class LoginWithMobileWidget extends HookWidget {
  const LoginWithMobileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => BlocProvider<LandingMobileCubit>(
        create: (_) => LandingMobileCubit(),
        child: const _LoginWithMobileWidget(),
      );
}

class _LoginWithMobileWidget extends HookWidget {
  const _LoginWithMobileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phoneInputController = useTextEditingController();
    final captchaInputController = useTextEditingController();
    return Column(
      children: [
        const SizedBox(height: 70),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: _MobileInput(controller: phoneInputController),
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

class _MobileInput extends StatelessWidget {
  const _MobileInput({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
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
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 20),
              Text(
                '+91',
                style: TextStyle(
                  fontSize: 16,
                  color: context.theme.text,
                ),
              ),
              const SizedBox(width: 8),
              Transform.rotate(
                angle: math.pi / 2,
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
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Text(
                context.l10n.getCaptcha,
                style: TextStyle(
                  fontSize: 14,
                  color: context.theme.secondaryText,
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      );
}
