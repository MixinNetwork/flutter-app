import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../account/session_key_value.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../buttons.dart';
import '../dialog.dart';
import '../toast.dart';

Future<bool> showPinVerificationDialog(
  BuildContext context, {
  required String title,
}) async {
  final ret = await showMixinDialog(
    context: context,
    child: _PinVerificationDialog(
      title: title,
    ),
    barrierDismissible: false,
  );
  return ret == true;
}

class _PinVerificationDialog extends StatelessWidget {
  const _PinVerificationDialog({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 400,
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  title,
                  style: TextStyle(
                    color: context.theme.text,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                const PinInputLayout(),
              ],
            ),
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(22),
                child: MixinCloseButton(),
              ),
            ),
          ],
        ),
      );
}

const _kPinCodeLength = 6;

class PinInputLayout extends StatefulWidget {
  const PinInputLayout({super.key});

  @override
  State<PinInputLayout> createState() => _PinInputLayoutState();
}

class _PinInputLayoutState extends State<PinInputLayout>
    implements TextInputClient {
  final focusNode = FocusNode(debugLabel: '_PinInputLayoutState');

  TextInputConnection? _textInputConnection;

  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  final _controller = TextEditingController();
  TextEditingValue? _lastKnownRemoteTextEditingValue;

  var _isVerifying = false;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChange);
    _controller.addListener(_didChangeTextEditingValue);
  }

  void _onFocusChange() {
    if (focusNode.hasFocus && focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else {
      _closeInputConnection();
    }
  }

  void _didChangeTextEditingValue() {
    _updateRemoteEditingValueIfNeeded();
    setState(() {});

    if (_controller.text.length == _kPinCodeLength) {
      _verifyPinCode(_controller.text);
    }
  }

  Future<void> _verifyPinCode(String code) async {
    if (_isVerifying) {
      return;
    }
    _isVerifying = true;
    _closeInputConnection();
    showToastLoading(context);
    try {
      d('verifying pin code: $code ${encryptPin(code)}');
      await context.accountServer.client.accountApi
          .verifyPin(encryptPin(code)!);
      Navigator.pop(context, true);
      Toast.dismiss();
    } catch (error, stacktrace) {
      await showToastFailed(context, error);
      e('_verifyPinCode: $error $stacktrace');
      _openInputConnection();
    } finally {
      _isVerifying = false;
      _controller.value = TextEditingValue.empty;
    }
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (!_hasInputConnection) {
      return;
    }
    final localValue = _controller.value;
    if (localValue == _lastKnownRemoteTextEditingValue) {
      return;
    }
    _textInputConnection!.setEditingState(localValue);
    _lastKnownRemoteTextEditingValue = localValue;
  }

  void _openInputConnection() {
    if (!_hasInputConnection) {
      _textInputConnection = TextInput.attach(
        this,
        TextInputConfiguration(
          inputType: TextInputType.number,
          obscureText: true,
          autocorrect: false,
          smartDashesType: SmartDashesType.disabled,
          enableSuggestions: false,
          enableInteractiveSelection: false,
          keyboardAppearance: MediaQuery.platformBrightnessOf(context),
          enableIMEPersonalizedLearning: false,
        ),
      )
        ..setEditingState(_controller.value)
        ..show();
      _lastKnownRemoteTextEditingValue = _controller.value;
    } else {
      _textInputConnection?.show();
    }
  }

  void _closeInputConnection() {
    if (_hasInputConnection) {
      _textInputConnection?.close();
      _textInputConnection = null;
    }
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    _closeInputConnection();
    _controller.removeListener(_didChangeTextEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputPinLength = _controller.text.length;
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      child: GestureDetector(
        onTap: _openInputConnection,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (var i = 0; i < inputPinLength; i++)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.theme.text,
                    shape: BoxShape.circle,
                  ),
                ),
              for (var i = inputPinLength; i < _kPinCodeLength; i++)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.theme.secondaryText,
                    ),
                  ),
                ),
            ].joinList(const SizedBox(width: 20)),
          ),
        ),
      ),
    );
  }

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
    }
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  TextEditingValue? get currentTextEditingValue => _controller.value;

  @override
  void insertTextPlaceholder(Size size) {
    // ignore
  }

  @override
  void performAction(TextInputAction action) {
    // ignore
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // ignore
  }

  @override
  void removeTextPlaceholder() {
    // ignore
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // ignore
  }

  @override
  void showToolbar() {
    // ignore
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    _lastKnownRemoteTextEditingValue = value;
    if (value == _controller.value) {
      return;
    }
    final textChanged = _controller.text != value.text;
    if (textChanged) {
      final inputFormatters = [
        LengthLimitingTextInputFormatter(_kPinCodeLength),
        FilteringTextInputFormatter.digitsOnly,
      ];

      _controller.value = inputFormatters.fold(
        value,
        (newValue, formatter) =>
            formatter.formatEditUpdate(_controller.value, newValue),
      );
    }
    _updateRemoteEditingValueIfNeeded();
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // ignore
  }
}
