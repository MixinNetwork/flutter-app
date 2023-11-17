import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import 'package:overlay_support/overlay_support.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import '../utils/logger.dart';

class Toast {
  factory Toast() => _singleton;

  Toast._internal();

  static final Toast _singleton = Toast._internal();

  static const shortDuration = Duration(seconds: 1);
  static const longDuration = Duration(seconds: 2);

  static OverlaySupportEntry? _entry;

  static void createView({
    required WidgetBuilder builder,
    Duration? duration = Toast.shortDuration,
    BuildContext? context,
  }) {
    dismiss();
    _entry = showOverlay(
      context: context,
      (context, progress) => Opacity(
        opacity: progress,
        child: builder(context),
      ),
      duration: duration ?? Duration.zero,
    );
  }

  static void dismiss() {
    _entry?.dismiss();
    _entry = null;
  }
}

class ToastWidget extends StatelessWidget {
  const ToastWidget({
    required this.text,
    super.key,
    this.barrierColor = const Color(0x80000000),
    this.icon,
    this.ignoring = true,
  });

  final Color barrierColor;
  final Widget? icon;
  final String text;
  final bool ignoring;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: ignoring,
        child: Material(
          color: Colors.transparent,
          child: Container(
            color: barrierColor,
            alignment: Alignment.center,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 130,
              ),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: Color.fromRGBO(62, 65, 72, 0.7),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  if (icon != null)
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: icon,
                    ),
                  if (icon != null) const SizedBox(height: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
}

void showToastSuccessful() => Toast.createView(
      builder: (context) => ToastWidget(
        barrierColor: Colors.transparent,
        icon: const _Successful(),
        text: context.l10n.successful,
      ),
    );

class ToastError extends Error {
  factory ToastError(String message) => ToastError._internal(message: message);

  factory ToastError.builder(String Function(BuildContext context)? builder) =>
      ToastError._internal(messageBuilder: builder);

  ToastError._internal({this.message, this.messageBuilder});

  static String errorToString(BuildContext context, Object? error) {
    if (error is ToastError) {
      if (error.message != null) {
        return error.message!;
      } else if (error.messageBuilder != null) {
        return error.messageBuilder!(context);
      } else {
        return context.l10n.failed;
      }
    } else if (error is MixinApiError) {
      return (error.error! as MixinError).toDisplayString(context);
    } else if (error is MixinError) {
      return error.toDisplayString(context);
    } else if (error is String) {
      return error;
    } else {
      return error?.toString() ?? context.l10n.failed;
    }
  }

  final String? message;
  final String Function(BuildContext)? messageBuilder;
}

void showToastFailed(Object? error, {BuildContext? context}) =>
    Toast.createView(
      context: context,
      builder: (context) => ToastWidget(
        barrierColor: Colors.transparent,
        icon: const _Failed(),
        text: ToastError.errorToString(context, error),
      ),
    );

void showToast(String message) => Toast.createView(
      builder: (context) => ToastWidget(
        barrierColor: Colors.transparent,
        text: message,
      ),
    );

void showToastLoading() => Toast.createView(
      builder: (context) => ToastWidget(
        icon: const _Loading(),
        text: context.l10n.loading,
        ignoring: false,
      ),
      duration: null,
    );

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.white),
        strokeWidth: 3,
      );
}

class _Failed extends StatelessWidget {
  const _Failed();

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(Resources.assetsImagesFailedSvg);
}

class _Successful extends StatelessWidget {
  const _Successful();

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(Resources.assetsImagesSuccessfulSvg);
}

Future<bool> runFutureWithToast(Future<dynamic> future) async {
  showToastLoading();
  try {
    await future;
  } catch (error, s) {
    e("runFutureWithToast's error: $error, $s");
    showToastFailed(error);
    return false;
  }
  showToastSuccessful();

  return true;
}

Future<bool> runWithToast(FutureOr<void> Function() function) async {
  showToastLoading();
  try {
    await function();
  } catch (error, s) {
    e("runFutureWithToast's error: $error, $s");
    showToastFailed(error);
    return false;
  }
  showToastSuccessful();

  return true;
}

Future<void> runWithLoading(Future<void> Function() function) async {
  showToastLoading();
  try {
    await function();
    Toast.dismiss();
  } catch (error, s) {
    e("runWithLoading's error: $error, $s");
    showToastFailed(error);
  }
}
