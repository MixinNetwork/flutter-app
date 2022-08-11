import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import '../utils/logger.dart';

class Toast {
  factory Toast() => _singleton;

  Toast._internal();

  static final Toast _singleton = Toast._internal();

  static const shortDuration = Duration(seconds: 1);
  static const longDuration = Duration(seconds: 2);

  static OverlayState? overlayState;
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static Future<void> createView({
    required BuildContext context,
    required Widget child,
    Duration? duration = Toast.shortDuration,
  }) async {
    dismiss();
    _isVisible = true;

    overlayState = Overlay.of(context, rootOverlay: true);

    _overlayEntry = OverlayEntry(builder: (BuildContext context) => child);
    overlayState!.insert(_overlayEntry!);

    if (duration == null) return;
    await Future.delayed(duration);
    dismiss();
  }

  static void dismiss() {
    if (!_isVisible) {
      return;
    }
    _isVisible = false;
    _overlayEntry?.remove();
  }
}

class ToastWidget extends StatelessWidget {
  const ToastWidget({
    super.key,
    this.barrierColor = const Color(0x80000000),
    this.icon,
    required this.text,
  });

  final Color barrierColor;
  final Widget? icon;
  final String text;

  @override
  Widget build(BuildContext context) => Material(
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
      );
}

void showToastSuccessful(BuildContext context) => Toast.createView(
      context: context,
      child: ToastWidget(
        barrierColor: Colors.transparent,
        icon: const _Successful(),
        text: context.l10n.successful,
      ),
    );

class ToastError extends Error {
  ToastError(this.message);

  final String message;

  // ignore: avoid-unused-parameters
  static ToastError? fromError(Object? error) => null;
}

Future<void> showToastFailed(BuildContext context, Object? error) {
  String? message;
  if (error is ToastError) {
    message = error.message;
  } else if (error is MixinApiError) {
    message = (error.error as MixinError).description;
  } else {
    message = ToastError.fromError(error)?.message;
  }
  return Toast.createView(
    context: context,
    child: ToastWidget(
      barrierColor: Colors.transparent,
      icon: const _Failed(),
      text: message ?? context.l10n.failed,
    ),
  );
}

void showToastLoading(BuildContext context) => Toast.createView(
      context: context,
      child: ToastWidget(
        icon: const _Loading(),
        text: context.l10n.loading,
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

Future<bool> runFutureWithToast(
  BuildContext context,
  Future<dynamic> future,
) async {
  showToastLoading(context);
  try {
    await future;
  } catch (error, s) {
    e("runFutureWithToast's error: $error, $s");
    await showToastFailed(context, error);
    return false;
  }
  showToastSuccessful(context);

  return true;
}

Future<void> runWithLoading(
    BuildContext context, Future<void> Function() function) async {
  showToastLoading(context);
  try {
    await function();
    Toast.dismiss();
  } catch (error, s) {
    e("runWithLoading's error: $error, $s");
    await showToastFailed(context, error);
  }
}
