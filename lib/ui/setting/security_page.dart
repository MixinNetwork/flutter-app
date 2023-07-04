import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pin_input_text_field/pin_input_text_field.dart';

import '../../account/security_key_value.dart';
import '../../utils/extension/extension.dart';
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
        appBar: const MixinAppBar(
          // todo l10n
          title: Text('Security'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: const SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 40),
                _Passcode(),
              ],
            ),
          ),
        ),
      );
}

class _Passcode extends HookWidget {
  const _Passcode();

  @override
  Widget build(BuildContext context) {
    final hasPasscode =
        useStream(SecurityKeyValue.instance.watchHasPasscode()).data ?? false;

    return CellGroup(
      child: CellItem(
        // todo l10n
        title: const Text('Passcode'),
        trailing: Transform.scale(
          scale: 0.7,
          child: CupertinoSwitch(
            activeColor: context.theme.accent,
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
    );
  }
}

class _InputPasscode extends HookWidget {
  const _InputPasscode();

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();

    final passcode = useState<String?>(null);
    final confirmPasscode = useState<String?>(null);

    useEffect(() {
      if (passcode.value == null) return;
      if (confirmPasscode.value == null) return;

      if (passcode.value != confirmPasscode.value) {
        // todo l10n
        showToastFailed('Passcode not match', context: context);

        passcode.value = null;
        confirmPasscode.value = null;
        textEditingController.text = '';
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
            // todo l10n
            passcode.value != null
                ? 'Enter again to confirm the passcode'
                : 'Set Passcode to unlock Mixin Messenger',
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
            child: PinInputTextField(
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autoFocus: true,
              decoration: UnderlineDecoration(
                gapSpace: 25,
                textStyle: TextStyle(
                  color: context.theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                colorBuilder: FixedColorBuilder(
                  context.theme.listSelected,
                ),
              ),
              controller: textEditingController,
              onChanged: (value) {
                if (value.length != 6) return;

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
