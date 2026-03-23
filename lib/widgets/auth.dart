import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rxdart/rxdart.dart';

import '../account/security_key_value.dart';
import '../constants/resources.dart';
import '../ui/provider/account_server_provider.dart';
import '../ui/provider/ui_context_providers.dart';
import '../utils/app_lifecycle.dart';
import '../utils/authentication.dart';
import '../utils/event_bus.dart';
import 'dialog.dart';

const _lockDuration = Duration(minutes: 1);

enum LockEvent { lock, unlock }

final _hasPasscodeProvider = StreamProvider.autoDispose<bool>(
  (ref) => SecurityKeyValue.instance.watchHasPasscode(),
);

final _biometricEnabledProvider = StreamProvider.autoDispose<bool>(
  (ref) => SecurityKeyValue.instance.watchBiometric(),
);

class AuthGuard extends HookConsumerWidget {
  const AuthGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signed = ref.watch(
      accountServerProvider.select((value) => value.hasValue),
    );

    if (signed) return _AuthGuard(child: child);

    return child;
  }
}

class _AuthGuard extends HookConsumerWidget {
  const _AuthGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    final focusNode = useFocusNode();
    final textEditingController = useTextEditingController();

    final hasPasscode =
        ref.watch(_hasPasscodeProvider).value ??
        SecurityKeyValue.instance.hasPasscode;

    final enableBiometric =
        ref.watch(_biometricEnabledProvider).value ??
        SecurityKeyValue.instance.biometric;

    final hasError = useState(false);
    final lock = useState(SecurityKeyValue.instance.hasPasscode);

    useEffect(() {
      final listen = EventBus.instance.on.whereType<LockEvent>().listen((
        event,
      ) {
        lock.value = event == LockEvent.lock;
      });

      return listen.cancel;
    }, []);

    useEffect(() {
      Timer? timer;
      void dispose() {
        timer?.cancel();
        timer = null;
      }

      void listener() {
        if (lock.value) return;

        final needLock = !isAppActive;

        final lockDuration =
            SecurityKeyValue.instance.lockDuration ?? _lockDuration;
        if (needLock) {
          if (lockDuration.inMinutes > 0) {
            timer = Timer(lockDuration, () {
              if (!hasPasscode) {
                lock.value = false;
                return;
              }

              lock.value = !isAppActive;
            });
          }
        } else {
          dispose();
          lock.value = needLock;
        }
      }

      listener();
      appActiveListener.addListener(listener);
      return () {
        dispose();
        appActiveListener.removeListener(listener);
      };
    }, [hasPasscode]);

    useEffect(() {
      focusNode.requestFocus();
      void listener() {
        if (focusNode.hasFocus) return;
        focusNode.requestFocus();
      }

      bool handler(KeyEvent _) {
        listener();
        return false;
      }

      FocusManager.instance.addListener(listener);
      appActiveListener.addListener(listener);
      ServicesBinding.instance.keyboard.addHandler(handler);
      return () {
        appActiveListener.removeListener(listener);
        FocusManager.instance.removeListener(listener);
        ServicesBinding.instance.keyboard.removeHandler(handler);
      };
    }, [lock.value]);

    return Stack(
      children: [
        child,
        if (lock.value)
          GestureDetector(
            onTap: focusNode.requestFocus,
            behavior: HitTestBehavior.translucent,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: MaterialApp(
                color: Colors.transparent,
                home: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          Resources.assetsImagesLockSvg,
                          width: 68,
                          height: 68,
                          colorFilter: ColorFilter.mode(
                            brightnessTheme.icon,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.unlockWithWasscode,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: brightnessTheme.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 204,
                          // height: 14,
                          child: PinCodeTextField(
                            appContext: context,
                            length: 6,
                            controller: textEditingController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            pinTheme: PinTheme(
                              activeColor: brightnessTheme.text,
                              inactiveColor: brightnessTheme.text,
                              selectedColor: brightnessTheme.text,
                              fieldWidth: 15,
                              borderWidth: 1,
                              shape: PinCodeFieldShape.circle,
                            ),
                            obscureText: true,
                            autoDisposeControllers: false,
                            obscuringWidget: Container(
                              decoration: BoxDecoration(
                                color: brightnessTheme.text,
                                shape: BoxShape.circle,
                              ),
                            ),
                            autoFocus: true,
                            focusNode: focusNode,
                            showCursor: false,
                            onCompleted: (value) {
                              textEditingController.text = '';
                              if (SecurityKeyValue.instance.passcode == value) {
                                lock.value = false;
                              } else {
                                hasError.value = true;
                              }
                            },
                            onChanged: (value) {
                              hasError.value = false;
                            },
                          ),
                        ),
                        const SizedBox(height: 28),
                        Visibility(
                          visible: hasError.value,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Text(
                            l10n.passcodeIncorrect,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: brightnessTheme.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        if (enableBiometric)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: MixinButton(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.all(24),
                              onTap: () async {
                                if (await authenticate()) {
                                  lock.value = false;
                                  return;
                                }
                              },
                              child: Text(
                                l10n.useBiometric,
                                style: TextStyle(
                                  color: brightnessTheme.accent,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
