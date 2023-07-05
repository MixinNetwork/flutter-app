import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pin_input_text_field/pin_input_text_field.dart'
    hide CirclePinDecoration;

import '../../account/account_server.dart';
import '../../account/security_key_value.dart';
import '../../constants/resources.dart';
import '../../ui/home/bloc/multi_auth_cubit.dart';
import '../../utils/app_lifecycle.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import 'circle_pin_decoration.dart';

const lockDuration = Duration(minutes: 1);

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
    final lock = useState(false);

    useEffect(() {
      Timer? timer;
      void dispose() {
        timer?.cancel();
        timer = null;
      }

      void listener() {
        if (lock.value) return;

        final needLock = !isAppActive;

        if (needLock) {
          timer = Timer(lockDuration, () {
            if (!hasPasscode) {
              lock.value = false;
              return;
            }

            lock.value = !isAppActive;
          });
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

      focusNode.addListener(listener);
      return () {
        focusNode.removeListener(listener);
      };
    }, [lock.value]);

    return Stack(
      children: [
        child,
        if (lock.value)
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 20,
              sigmaY: 20,
            ),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      Resources.assetsImagesLockSvg,
                      width: 68,
                      height: 68,
                      colorFilter:
                          ColorFilter.mode(context.theme.icon, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      // todo l10n
                      'Enter Passcode to unlock Mixin Messenger',
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
                      height: 14,
                      child: PinInputTextField(
                        controller: textEditingController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        autoFocus: true,
                        focusNode: focusNode,
                        decoration: CirclePinDecoration(
                          strokeColorBuilder:
                              FixedColorBuilder(context.theme.text),
                        ),
                        onChanged: (value) {
                          hasError.value = false;
                          if (value.length != 6) return;
                          textEditingController.text = '';
                          if (SecurityKeyValue.instance.passcode == value) {
                            lock.value = false;
                          } else {
                            hasError.value = true;
                          }
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
                        // todo l10n
                        'Passcode incorrect',
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
          )
      ],
    );
  }
}
