import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/provider/setting_provider.dart';

final messageStyleProvider = Provider<MessageStyle>((ref) {
  final chatFontSizeDelta =
      ref.watch(settingProvider.select((value) => value.chatFontSizeDelta));
  return MessageStyle.defaultStyle + chatFontSizeDelta;
});

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
