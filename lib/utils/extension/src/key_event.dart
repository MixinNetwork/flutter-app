part of '../extension.dart';

const letterKeys = [
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyB,
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.keyD,
  LogicalKeyboardKey.keyE,
  LogicalKeyboardKey.keyF,
  LogicalKeyboardKey.keyG,
  LogicalKeyboardKey.keyH,
  LogicalKeyboardKey.keyI,
  LogicalKeyboardKey.keyJ,
  LogicalKeyboardKey.keyK,
  LogicalKeyboardKey.keyL,
  LogicalKeyboardKey.keyM,
  LogicalKeyboardKey.keyN,
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyP,
  LogicalKeyboardKey.keyQ,
  LogicalKeyboardKey.keyR,
  LogicalKeyboardKey.keyS,
  LogicalKeyboardKey.keyT,
  LogicalKeyboardKey.keyU,
  LogicalKeyboardKey.keyV,
  LogicalKeyboardKey.keyW,
  LogicalKeyboardKey.keyX,
  LogicalKeyboardKey.keyY,
  LogicalKeyboardKey.keyZ,
];

const numberKeys = [
  LogicalKeyboardKey.digit0,
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
  LogicalKeyboardKey.numpad0,
  LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.numpad4,
  LogicalKeyboardKey.numpad5,
  LogicalKeyboardKey.numpad6,
  LogicalKeyboardKey.numpad7,
  LogicalKeyboardKey.numpad8,
  LogicalKeyboardKey.numpad9,
];

extension KeyEventExtension on KeyEvent {
  bool get firstInputable {
    if (HardwareKeyboard.instance.logicalKeysPressed.hasModifierKey) {
      return false;
    }
    return letterKeys.contains(logicalKey) ||
        numberKeys.contains(logicalKey) ||
        LogicalKeyboardKey.space == logicalKey;
  }
}

final _modifierKeys = {
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.capsLock,
  LogicalKeyboardKey.numLock,
  LogicalKeyboardKey.scrollLock,
  LogicalKeyboardKey.symbol,
  LogicalKeyboardKey.symbolLock,
  LogicalKeyboardKey.fn,
};

extension SetExtension on Set<LogicalKeyboardKey> {
  bool get hasModifierKey => any(_modifierKeys.contains);
}
