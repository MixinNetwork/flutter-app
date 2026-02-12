import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../account/security_key_value.dart';
import '../../utils/authentication.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../../widgets/toast.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.theme.background,
    appBar: MixinAppBar(title: Text(context.l10n.security)),
    body: ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: const SingleChildScrollView(
        child: Column(children: [SizedBox(height: 40), _Passcode()]),
      ),
    ),
  );
}

class _Passcode extends HookConsumerWidget {
  const _Passcode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalKey = useMemoized(
      GlobalKey<PopupMenuButtonState<Duration>>.new,
      [],
    );

    final hasPasscode =
        useMemoizedStream(SecurityKeyValue.instance.watchHasPasscode).data ??
        SecurityKeyValue.instance.hasPasscode;

    final enableBiometric =
        useMemoizedStream(SecurityKeyValue.instance.watchBiometric).data ??
        SecurityKeyValue.instance.biometric;

    final minutes = useStream(
      SecurityKeyValue.instance.watchLockDuration().map(
        (event) => event.inMinutes,
      ),
    ).data;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CellGroup(
          cellBackgroundColor: context.theme.settingCellBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CellItem(
                title: Text(context.l10n.screenPasscode),
                trailing: Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    activeTrackColor: context.theme.accent,
                    value: hasPasscode,
                    onChanged: (value) {
                      if (!value) {
                        SecurityKeyValue.instance.passcode = null;
                        return;
                      }
                      showMixinDialog(
                        context: context,
                        child: const _InputPasscode(),
                      );
                    },
                  ),
                ),
              ),
              if (hasPasscode)
                CellItem(
                  description: PopupMenuButton(
                    key: globalKey,
                    color: Color.alphaBlend(
                      context.theme.listSelected,
                      context.theme.background,
                    ),
                    itemBuilder: (context) =>
                        [
                              PopupMenuItem(
                                value: Duration.zero,
                                child: Text(context.l10n.disabled),
                              ),
                              PopupMenuItem(
                                value: const Duration(minutes: 1),
                                child: Text(context.l10n.minute(1, 1)),
                              ),
                              PopupMenuItem(
                                value: const Duration(minutes: 5),
                                child: Text(context.l10n.minute(5, 5)),
                              ),
                              PopupMenuItem(
                                value: const Duration(hours: 1),
                                child: Text(context.l10n.hour(1, 1)),
                              ),
                              PopupMenuItem(
                                value: const Duration(hours: 5),
                                child: Text(context.l10n.hour(5, 5)),
                              ),
                            ]
                            .map(
                              (e) => PopupMenuItem(
                                value: e.value,
                                child: DefaultTextStyle.merge(
                                  child: e.child ?? const SizedBox(),
                                  style: TextStyle(
                                    color: context.theme.text,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onSelected: (value) =>
                        SecurityKeyValue.instance.lockDuration = value,
                    child: Text(
                      (minutes == null || minutes == 0)
                          ? context.l10n.disabled
                          : minutes < 60
                          ? context.l10n.minute(minutes, minutes)
                          : context.l10n.hour(minutes ~/ 60, minutes ~/ 60),
                    ),
                  ),
                  title: Text(context.l10n.autoLock),
                  onTap: () => globalKey.currentState?.showButtonMenu(),
                ),
            ],
          ),
        ),
        if (hasPasscode)
          CellGroup(
            cellBackgroundColor: context.theme.settingCellBackgroundColor,
            child: CellItem(
              title: Text(context.l10n.biometric),
              trailing: Transform.scale(
                scale: 0.7,
                child: CupertinoSwitch(
                  activeTrackColor: context.theme.accent,
                  value: enableBiometric,
                  onChanged: (value) async {
                    if (!await checkAuthenticateAvailable()) {
                      showToastFailed(context.l10n.notSupportBiometric);
                      return;
                    }

                    SecurityKeyValue.instance.biometric = value;
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InputPasscode extends HookConsumerWidget {
  const _InputPasscode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
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
    }, []);

    final textEditingController = useTextEditingController();

    final passcode = useState<String?>(null);
    final confirmPasscode = useState<String?>(null);

    useEffect(() {
      if (passcode.value == null) return;
      if (confirmPasscode.value == null) return;

      if (passcode.value != confirmPasscode.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showToastFailed(context.l10n.passcodeIncorrect);
        });

        passcode.value = null;
        confirmPasscode.value = null;
        textEditingController.text = '';
        return;
      }

      SecurityKeyValue.instance.passcode = passcode.value;
      Navigator.maybePop(context);
    });

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Spacer(),
              Padding(
                padding: EdgeInsets.only(right: 12, top: 12),
                child: MixinCloseButton(),
              ),
            ],
          ),
          Text(
            passcode.value != null
                ? context.l10n.confirmPasscodeDesc
                : context.l10n.setPasscodeDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.theme.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 215,
            child: PinCodeTextField(
              appContext: context,
              length: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autoFocus: true,
              keyboardType: TextInputType.number,
              useHapticFeedback: true,
              pinTheme: PinTheme(
                activeColor: context.theme.text,
                inactiveColor: context.theme.text,
                selectedColor: context.theme.text,
                fieldWidth: 15,
                borderWidth: 2,
              ),
              textStyle: TextStyle(fontSize: 18, color: context.theme.text),
              autoDisposeControllers: false,
              focusNode: focusNode,
              controller: textEditingController,
              showCursor: false,
              onCompleted: (value) {
                if (passcode.value != null) {
                  confirmPasscode.value = value;
                } else {
                  passcode.value = value;
                  textEditingController.text = '';
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
