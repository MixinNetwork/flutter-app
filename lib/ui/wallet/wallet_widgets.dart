import 'package:flutter/material.dart';

import '../../utils/extension/extension.dart';

// Material 3 short durations and easing, which fit small desktop changes. A
// leaving thing is faster, so that the rows that move up hide it.
const kWalletMotion = Durations.short3;
const kWalletLeaveMotion = Durations.short1;
const kWalletCurve = Easing.standard;

const kWalletCondensedFont = 'MixinCondensed';

class WalletCard extends StatelessWidget {
  const WalletCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.all(Radius.circular(8)),
    child: ColoredBox(
      color: context.theme.settingCellBackgroundColor,
      child: child,
    ),
  );
}

/// Cross-fades the text in place when it changes.
class FadeText extends StatelessWidget {
  const FadeText(
    this.text, {
    required this.style,
    this.alignment = AlignmentDirectional.centerStart,
    super.key,
  });

  final String text;
  final TextStyle style;
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: kWalletMotion,
    switchInCurve: kWalletCurve,
    switchOutCurve: kWalletCurve,
    layoutBuilder: (current, previous) => Stack(
      alignment: alignment,
      children: [...previous, ?current],
    ),
    child: Text(
      text,
      key: ValueKey(text),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    ),
  );
}

/// The 24h change as on iOS: floored to two decimals, a minus sign only.
String formatChange(String changeUsd) {
  final value = (double.tryParse(changeUsd) ?? 0) * 100;
  final floored = (value.abs() * 100).floor() / 100;
  final text = floored.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '${value < 0 && floored > 0 ? '-' : ''}$text%';
}

/// Lays out rows of one height. The first rows show at once. When the rows
/// change, every row moves to its new place in one motion, a new row fades in,
/// and a removed row fades out.
// shortcut: builds every row, fine for a wallet's few tokens; use a sliver
// list if a user can hold thousands.
class AnimatedRows<T> extends StatefulWidget {
  const AnimatedRows({
    required this.items,
    required this.idOf,
    required this.rowHeight,
    required this.itemBuilder,
    super.key,
  });

  final List<T> items;
  final Object Function(T item) idOf;
  final double rowHeight;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  State<AnimatedRows<T>> createState() => _AnimatedRowsState<T>();
}

class _AnimatedRowsState<T> extends State<AnimatedRows<T>> {
  final _leaving = <Object, (T, int)>{};
  var _built = false;

  @override
  void didUpdateWidget(AnimatedRows<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _built = true;
    final ids = widget.items.map(widget.idOf).toSet();
    for (final (index, item) in oldWidget.items.indexed) {
      final id = widget.idOf(item);
      if (!ids.contains(id)) _leaving[id] = (item, index);
    }
    _leaving.removeWhere((id, _) => ids.contains(id));
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: kWalletMotion,
    curve: kWalletCurve,
    height: widget.items.length * widget.rowHeight,
    child: Stack(
      children: [
        // Under the other rows, so that the rows that move up cover them.
        for (final MapEntry(key: id, value: (item, index)) in _leaving.entries)
          _AnimatedRow(
            key: ValueKey(id),
            top: index * widget.rowHeight,
            height: widget.rowHeight,
            leaving: true,
            onGone: () => setState(() => _leaving.remove(id)),
            child: widget.itemBuilder(context, item),
          ),
        for (final (index, item) in widget.items.indexed)
          _AnimatedRow(
            key: ValueKey(widget.idOf(item)),
            top: index * widget.rowHeight,
            height: widget.rowHeight,
            leaving: false,
            appear: _built,
            child: widget.itemBuilder(context, item),
          ),
      ],
    ),
  );
}

class _AnimatedRow extends StatefulWidget {
  const _AnimatedRow({
    required this.top,
    required this.height,
    required this.leaving,
    required this.child,
    this.appear = true,
    this.onGone,
    super.key,
  });

  final double top;
  final double height;
  final bool leaving;
  final bool appear;
  final Widget child;
  final VoidCallback? onGone;

  @override
  State<_AnimatedRow> createState() => _AnimatedRowState();
}

class _AnimatedRowState extends State<_AnimatedRow>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: kWalletMotion,
    reverseDuration: kWalletLeaveMotion,
    value: widget.appear ? 0 : 1,
  )..forward();
  late final _opacity = CurvedAnimation(
    parent: _controller,
    curve: Easing.emphasizedDecelerate,
    reverseCurve: Easing.emphasizedAccelerate,
  );

  @override
  void didUpdateWidget(_AnimatedRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving == oldWidget.leaving) return;
    if (widget.leaving) {
      _controller.reverse().whenComplete(() {
        if (mounted && widget.leaving) widget.onGone?.call();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _opacity.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedPositioned(
    duration: kWalletMotion,
    curve: kWalletCurve,
    top: widget.top,
    left: 0,
    right: 0,
    height: widget.height,
    child: FadeTransition(
      opacity: _opacity,
      child: IgnorePointer(ignoring: widget.leaving, child: widget.child),
    ),
  );
}
