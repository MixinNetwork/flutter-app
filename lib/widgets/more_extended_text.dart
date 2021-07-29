import 'package:extended_text/extended_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';


import '../utils/extension/extension.dart';
import '../utils/reg_exp_utils.dart';
import '../utils/uri_utils.dart';
import 'high_light_text.dart';
import 'interacter_decorated_box.dart';

class MoreExtendedText extends HookWidget {
  const MoreExtendedText(
    this.text, {
    Key? key,
    this.style,
  }) : super(key: key);

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final expand = useState(false);

    final style =
        useMemoized(() => this.style?.merge(const TextStyle(height: 1)));

    final textSpans = useMemoized(
      () {
        final highlightTextSpans = uriRegExp
            .allMatches(text)
            .map(
              (e) => HighlightTextSpan(
                e[0]!,
                style: TextStyle(
                  color: context.theme.accent,
                ),
                onTap: () => openUri(context, e[0]!),
              ),
            )
            .toList();
        return TextSpan(
          children: buildHighlightTextSpan(text, highlightTextSpans, style),
        );
      },
      [text, style],
    );

    return DefaultTextStyle(
      style: style ?? const TextStyle(),
      child: ExtendedText.rich(
        textSpans,
        joinZeroWidthSpace: !expand.value,
        maxLines: expand.value ? null : 3,
        overflow: TextOverflow.fade,
        textAlign: TextAlign.center,
        selectionEnabled: true,
        overflowWidget: TextOverflowWidget(
          child: InteractableDecoratedBox(
            cursor: SystemMouseCursors.click,
            onTap: () {
              expand.value = true;
            },
            child: Text(
              context.l10n.more,
              style: style?.merge(TextStyle(
                color: context.theme.accent,
              )),
            ),
          ),
        ),
      ),
    );
  }
}
