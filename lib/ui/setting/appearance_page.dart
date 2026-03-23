import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/message/item/text/text_message.dart';
import '../../widgets/message/message.dart';
import '../../widgets/radio.dart';
import '../home/controllers/blink_controller.dart';
import '../provider/setting_provider.dart';
import '../provider/ui_context_providers.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(title: Text(l10n.appearance)),
      body: const Align(alignment: Alignment.topCenter, child: _Body()),
    );
  }
}

class _Body extends HookConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 14),
              child: Text(
                l10n.theme,
                style: TextStyle(
                  color: theme.secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
            CellGroup(
              cellBackgroundColor: theme.settingCellBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CellItem(
                    title: RadioItem<Brightness?>(
                      title: Text(l10n.followSystem),
                      groupValue: ref.watch(settingProvider).brightness,
                      onChanged: (value) =>
                          ref.read(settingProvider.notifier).brightness = value,
                      value: null,
                    ),
                    trailing: null,
                  ),
                  CellItem(
                    title: RadioItem<Brightness?>(
                      title: Text(l10n.light),
                      groupValue: ref.watch(settingProvider).brightness,
                      onChanged: (value) =>
                          ref.read(settingProvider.notifier).brightness = value,
                      value: Brightness.light,
                    ),
                    trailing: null,
                  ),
                  CellItem(
                    title: RadioItem<Brightness?>(
                      title: Text(l10n.dark),
                      groupValue: ref.watch(settingProvider).brightness,
                      onChanged: (value) =>
                          ref.read(settingProvider.notifier).brightness = value,
                      value: Brightness.dark,
                    ),
                    trailing: null,
                  ),
                ],
              ),
            ),
            const _MessageAvatarSetting(),
            const _ChatTextSizeSetting(),
          ],
        ),
      ),
    );
  }
}

class _MessageAvatarSetting extends HookConsumerWidget {
  const _MessageAvatarSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final showAvatar = ref.watch(
      settingProvider.select((value) => value.messageShowAvatar),
    );
    final showIdentityNumber = ref.watch(
      settingProvider.select((value) => value.messageShowIdentityNumber),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 14, top: 22),
          child: Text(
            l10n.chats,
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 14,
            ),
          ),
        ),
        CellGroup(
          cellBackgroundColor: theme.settingCellBackgroundColor,
          child: Column(
            children: [
              CellItem(
                title: Text(l10n.showAvatar),
                trailing: Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    activeTrackColor: theme.accent,
                    value: showAvatar,
                    onChanged: (value) =>
                        ref.read(settingProvider.notifier).messageShowAvatar =
                            value,
                  ),
                ),
              ),
              CellItem(
                title: Text(l10n.showIdentityNumber),
                trailing: Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    activeTrackColor: theme.accent,
                    value: showIdentityNumber,
                    onChanged: (value) =>
                        ref
                                .read(settingProvider.notifier)
                                .messageShowIdentityNumber =
                            value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatTextSizeSetting extends HookConsumerWidget {
  const _ChatTextSizeSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final fontSize = ref.watch(
      settingProvider.select((value) => value.chatFontSizeDelta),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 14, top: 22),
            child: Text(
              l10n.chatTextSize,
              style: TextStyle(
                color: theme.secondaryText,
                fontSize: 14,
              ),
            ),
          ),
          const _ChatTextSizePreview(),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 10),
              Text(
                'A',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.text,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 4,
                    trackShape: RoundedRectSliderTrackShape(),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: fontSize,
                    min: -2,
                    divisions: 6,
                    max: 4,
                    onChanged: (value) {
                      debugPrint('fontSize: $value');
                      ref.read(settingProvider.notifier).chatFontSizeDelta =
                          value;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'A',
                style: TextStyle(
                  fontSize: 24,
                  color: theme.text,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }
}

MessageItem _buildFakeTextMessage(String content) {
  final messageId = const Uuid().v4();
  final createdAt = DateTime(2023, 1, 1, 8, 25);
  return MessageItem(
    messageId: messageId,
    conversationId: 'fake',
    type: 'PLAIN_TEXT',
    createdAt: createdAt,
    status: MessageStatus.read,
    userId: 'fake',
    userIdentityNumber: '0',
    pinned: false,
    isVerified: false,
    sharedUserIsVerified: false,
    content: content,
  );
}

class _ChatTextSizePreview extends HookConsumerWidget {
  const _ChatTextSizePreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final brightnessValue = ref.watch(brightnessValueProvider);
    final messageHi = useMemoized(
      () => _buildFakeTextMessage(l10n.sayHi),
      [l10n],
    );
    final messageAnswer = useMemoized(
      () => _buildFakeTextMessage(l10n.iAmGood),
      [l10n],
    );

    return TickerMode(
      enabled: ModalRoute.of(context)?.isCurrent ?? true,
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            color: theme.chatBackground,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            image: DecorationImage(
              image: const ExactAssetImage(
                Resources.assetsImagesChatBackgroundPng,
              ),
              fit: BoxFit.none,
              colorFilter: ColorFilter.mode(
                brightnessValue == 1.0
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.03),
                BlendMode.srcIn,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PreviewMessageDayTime(dateTime: DateTime(2023)),
              MessageContext(
                message: messageHi,
                isTranscriptPage: false,
                isPinnedPage: false,
                showNip: true,
                isCurrentUser: true,
                child: const TextMessage(),
              ),
              MessageContext(
                message: messageAnswer,
                isTranscriptPage: false,
                isPinnedPage: false,
                showNip: true,
                isCurrentUser: false,
                child: const TextMessage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewMessageDayTime extends ConsumerWidget {
  const _PreviewMessageDayTime({required this.dateTime});

  final DateTime dateTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: theme.dateTime,
          ),
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Text(
              DateFormat.yMMMd().format(dateTime.toLocal()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
