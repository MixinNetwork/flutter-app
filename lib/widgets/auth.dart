import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;

import '../account/security_key_value.dart';
import '../constants/resources.dart';
import '../ui/provider/account_server_provider.dart';
import '../utils/app_lifecycle.dart';
import '../utils/authentication.dart';
import '../utils/event_bus.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import 'dialog.dart';
import 'pin_field.dart';

const _lockDuration = Duration(minutes: 1);

enum LockEvent { lock, unlock }

/// Whether the main window shows the lock screen, for views outside it.
final appLocked = ValueNotifier(false);

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
    final focusNode = useFocusNode();
    final textEditingController = useTextEditingController();
    final pinController = usePinInputController(
      textController: textEditingController,
      focusNode: focusNode,
    );

    final hasPasscode =
        useMemoizedStream(SecurityKeyValue.instance.watchHasPasscode).data ??
        SecurityKeyValue.instance.hasPasscode;

    final enableBiometric =
        useMemoizedStream(SecurityKeyValue.instance.watchBiometric).data ??
        SecurityKeyValue.instance.biometric;

    final hasError = useState(false);
    final lock = useState(SecurityKeyValue.instance.hasPasscode);

    useEffect(() {
      appLocked.value = lock.value;
      return null;
    }, [lock.value]);

    // A cleanup of the effect above would run after the next effect, and so
    // would mark the app as unlocked on each lock.
    useEffect(
      () =>
          () => appLocked.value = false,
      const [],
    );

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
                          renderingStrategy: RenderingStrategy.raster,
                          width: 68,
                          height: 68,
                          colorFilter: ColorFilter.mode(
                            context.theme.icon,
                            BlendMode.srcIn,
                          ),
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
                          child: MaterialPinField(
                            length: 6,
                            pinController: pinController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            theme: borderPinTheme(
                              borderColor: context.theme.text,
                              focusedBorderColor: context.theme.text,
                              filledBorderColor: context.theme.text,
                              borderWidth: 1,
                              // (204 - 6 * 15) / 5
                              spacing: 22.8,
                              shape: MaterialPinShape.circle,
                            ),
                            obscureText: true,
                            blinkWhenObscuring: false,
                            enableHapticFeedback: false,
                            obscuringWidget: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: context.theme.text,
                                shape: BoxShape.circle,
                              ),
                            ),
                            autoFocus: true,
                            onCompleted: (value) {
                              // Clearing inside the callback would leave the
                              // field thinking it is still complete.
                              scheduleMicrotask(pinController.clear);
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
                                context.l10n.useBiometric,
                                style: TextStyle(color: context.theme.accent),
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
