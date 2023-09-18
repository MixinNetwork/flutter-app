import 'dart:io';

import 'package:flutter/widgets.dart';

import '../emoji.dart';
import '../logger.dart';

// remove this once https://github.com/flutter/flutter/issues/111113 is fixed.
class TextInputActionHandler extends StatefulWidget {
  const TextInputActionHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<TextInputActionHandler> createState() => _TextInputActionHandlerState();
}

class _TextInputActionHandlerState extends State<TextInputActionHandler> {
  late final _actions = <Type, Action<Intent>>{
    DeleteCharacterIntent: makeAction<DeleteCharacterIntent>(context),
    ExtendSelectionByCharacterIntent:
        makeAction<ExtendSelectionByCharacterIntent>(context),
    ExtendSelectionVerticallyToAdjacentLineIntent:
        makeAction<ExtendSelectionVerticallyToAdjacentLineIntent>(context),
    SelectAllTextIntent: makeAction<SelectAllTextIntent>(context),
    PasteTextIntent: makeAction<PasteTextIntent>(context),
    RedoTextIntent: makeAction<RedoTextIntent>(context),
    UndoTextIntent: makeAction<UndoTextIntent>(context),
  };

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) {
      return widget.child;
    }
    return Actions(
      actions: _actions,
      child: widget.child,
    );
  }
}

Action<T> makeAction<T extends Intent>(BuildContext context) =>
    Action<T>.overridable(
      defaultAction: _CallbackContextAction(),
      context: context,
    );

class _CallbackContextAction<T extends Intent> extends ContextAction<T> {
  _CallbackContextAction();

  bool? _consumeKey;

  @override
  bool consumesKey(T intent) {
    final consumeKey = _consumeKey;
    _consumeKey = null;
    if (consumeKey != null) {
      return consumeKey;
    }
    return callingAction?.consumesKey(intent) ?? true;
  }

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    if (context == null) {
      e('No context provided to _CallbackContextAction');
      return callingAction?.invoke(intent);
    }
    final state = context.findAncestorStateOfType<EditableTextState>();
    if (state == null) {
      e('failed to find EditableTextState');
      return callingAction?.invoke(intent);
    }

    final composingRange = state.textEditingValue.composing;

    if (composingRange.isValid && !composingRange.isCollapsed) {
      _consumeKey = false;
      return null;
    }
    return callingAction?.invoke(intent);
  }
}

/// A [TextEditingController] that supports emojis.
class EmojiTextEditingController extends TextEditingController {
  EmojiTextEditingController({super.text});

  TextSpan _buildSpan({required String text, TextStyle? style}) {
    final children = <TextSpan>[];
    text.splitEmoji(onEmoji: (text) {
      children.add(
        TextSpan(
          text: text,
          style: style?.copyWith(fontFamily: kEmojiFontFamily) ??
              TextStyle(fontFamily: kEmojiFontFamily),
        ),
      );
    }, onText: (text) {
      children.add(TextSpan(text: text, style: style));
    });
    return TextSpan(children: children, style: style);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    assert(!value.composing.isValid ||
        !withComposing ||
        value.isComposingRangeValid);
    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    final composingRegionOutOfRange =
        !value.isComposingRangeValid || !withComposing;

    if (composingRegionOutOfRange) {
      return _buildSpan(text: value.text, style: style);
    }

    final composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
            const TextStyle(decoration: TextDecoration.underline);
    return TextSpan(
      style: style,
      children: <TextSpan>[
        _buildSpan(text: value.composing.textBefore(value.text)),
        _buildSpan(
          style: composingStyle,
          text: value.composing.textInside(value.text),
        ),
        _buildSpan(text: value.composing.textAfter(value.text)),
      ],
    );
  }
}
