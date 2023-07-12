import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rxdart/rxdart.dart';

import '../account/account_server.dart';
import '../account/security_key_value.dart';
import '../constants/resources.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../utils/app_lifecycle.dart';
import '../utils/event_bus.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';

const _lockDuration = Duration(minutes: 1);

enum LockEvent { lock, unlock }

class AuthGuard extends HookWidget {
  const AuthGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final authAvailable =
        useBlocState<MultiAuthCubit, MultiAuthState>().current != null;
    AccountServer? accountServer;
    try {
      accountServer = context.read<AccountServer?>();
    } catch (_) {}
    final signed = authAvailable && accountServer != null;

    if (signed) return _AuthGuard(child: child);

    return child;
  }
}

class _AuthGuard extends HookWidget {
  const _AuthGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final textEditingController = useTextEditingController();
    final hasPasscode =
        useMemoizedStream(SecurityKeyValue.instance.watchHasPasscode).data ??
            SecurityKeyValue.instance.hasPasscode;

    final hasError = useState(false);
    final lock = useState(SecurityKeyValue.instance.hasPasscode);

    useEffect(() {
      final listen =
          EventBus.instance.on.whereType<LockEvent>().listen((event) {
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
              filter: ImageFilter.blur(
                sigmaX: 20,
                sigmaY: 20,
              ),
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
                              context.theme.icon, BlendMode.srcIn),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          context.l10n.unlockWithWasscode,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.theme.text,
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
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            pinTheme: PinTheme(
                              activeColor: context.theme.text,
                              inactiveColor: context.theme.text,
                              selectedColor: context.theme.text,
                              fieldWidth: 15,
                              borderWidth: 1,
                              shape: PinCodeFieldShape.circle,
                            ),
                            obscureText: true,
                            autoDisposeControllers: false,
                            obscuringWidget: Container(
                                decoration: BoxDecoration(
                              color: context.theme.text,
                              shape: BoxShape.circle,
                            )),
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
                            context.l10n.passcodeIncorrect,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.theme.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }
}
