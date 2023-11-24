import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../constants/resources.dart';
import '../ui/provider/account/multi_auth_provider.dart';
import '../ui/provider/account/security_key_value_provider.dart';
import '../utils/app_lifecycle.dart';
import '../utils/authentication.dart';
import '../utils/extension/extension.dart';
import '../utils/logger.dart';
import 'dialog.dart';

final securityLockProvider = StateNotifierProvider<LockStateNotifier, bool>(
  LockStateNotifier.new,
);

class LockStateNotifier extends StateNotifier<bool> {
  LockStateNotifier(this.ref) : super(false) {
    _initialize();
  }

  final Ref ref;

  Timer? _inactiveTimer;

  SecurityKeyValue get securityKeyValue => ref.read(securityKeyValueProvider);

  bool get signed => ref.read(authProvider) != null;

  Future<void> _initialize() async {
    await securityKeyValue.initialize;
    if (securityKeyValue.hasPasscode && signed) {
      lock();
    }
    appActiveListener.addListener(_onAppActiveChanged);
    ref.listen(multiAuthStateNotifierProvider, (previous, next) {
      if (next.auths.isEmpty) {
        unlock();
        // remove passcode
        securityKeyValue
          ..passcode = null
          ..lockDuration = null;
      }
    });
  }

  void _onAppActiveChanged() {
    if (state) {
      // already locked
      return;
    }

    void clearTimer() {
      _inactiveTimer?.cancel();
      _inactiveTimer = null;
    }

    clearTimer();

    final needLock = !isAppActive && securityKeyValue.hasPasscode && signed;
    if (!needLock) {
      return;
    }
    final lockDuration = securityKeyValue.lockDuration;
    if (lockDuration.inMinutes > 0) {
      d('schedule lock after ${lockDuration.inMinutes} minutes');
      _inactiveTimer = Timer(lockDuration, () {
        if (securityKeyValue.hasPasscode && signed) {
          lock();
          clearTimer();
        }
      });
    }
  }

  void lock() {
    if (!signed) {
      throw Exception('not signed');
    }
    if (!securityKeyValue.hasPasscode) {
      throw Exception('no passcode');
    }
    state = true;
  }

  // for unlock by biometric
  void unlock() {
    state = false;
  }

  bool unlockWithPin(String input) {
    assert(securityKeyValue.hasPasscode, 'no passcode');
    if (securityKeyValue.passcode == input) {
      state = false;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _inactiveTimer?.cancel();
    appActiveListener.removeListener(_onAppActiveChanged);
    super.dispose();
  }
}

class AuthGuard extends HookConsumerWidget {
  const AuthGuard({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final textEditingController = useTextEditingController();

    final enableBiometric =
        ref.watch(securityKeyValueProvider.select((value) => value.biometric));

    final hasError = useState(false);
    final lock = ref.watch(securityLockProvider);

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
    }, [lock]);

    return Stack(
      children: [
        child,
        if (lock)
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
                              if (!ref
                                  .read(securityLockProvider.notifier)
                                  .unlockWithPin(value)) {
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
                                  ref
                                      .read(securityLockProvider.notifier)
                                      .unlock();
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
          )
      ],
    );
  }
}
