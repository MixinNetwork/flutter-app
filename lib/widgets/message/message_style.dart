import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/provider/setting_provider.dart';

final messageStyleProvider = Provider<MessageStyle>(
  (ref) =>
      MessageStyle.defaultStyle +
      ref.watch(settingProvider.notifier).chatFontSizeDelta,
);

class MessageStyleScope extends ConsumerWidget {
  const MessageStyleScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(messageStyleProvider);
    return _MessageStyleInherited(style: style, child: child);
  }
}

class _MessageStyleInherited extends InheritedWidget {
  const _MessageStyleInherited({
    required this.style,
    required super.child,
  });

  final MessageStyle style;

  static MessageStyle of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_MessageStyleInherited>();
    assert(inherited != null, 'MessageStyleScope is missing');
    return inherited!.style;
  }

  @override
  bool updateShouldNotify(_MessageStyleInherited oldWidget) =>
      style != oldWidget.style;
}

extension MessageStyleExt on BuildContext {
  MessageStyle get messageStyle => _MessageStyleInherited.of(this);
}

class MessageStyle {
  const MessageStyle({
    required this.primaryFontSize,
    required this.secondaryFontSize,
    required this.tertiaryFontSize,
    required this.statusFontSize,
  });

  static const MessageStyle defaultStyle = MessageStyle(
    primaryFontSize: 16,
    secondaryFontSize: 14,
    tertiaryFontSize: 12,
    statusFontSize: 10,
  );

  final double primaryFontSize;
  final double secondaryFontSize;
  final double tertiaryFontSize;
  final double statusFontSize;

  MessageStyle operator +(double delta) => MessageStyle(
    primaryFontSize: primaryFontSize + delta,
    secondaryFontSize: secondaryFontSize + delta,
    tertiaryFontSize: tertiaryFontSize + delta,
    statusFontSize: statusFontSize,
  );
}
