import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../bloc/setting_cubit.dart';
import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/message/item/text/text_message.dart';
import '../../widgets/message/message.dart';
import '../../widgets/message/message_day_time.dart';
import '../../widgets/radio.dart';
import '../home/bloc/blink_cubit.dart';
import '../home/chat/chat_page.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.theme.background,
        appBar: MixinAppBar(
          title: Text(context.l10n.appearance),
        ),
        body: const Align(
          alignment: Alignment.topCenter,
          child: _Body(),
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 14),
                child: Text(
                  context.l10n.theme,
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ),
              CellGroup(
                cellBackgroundColor: context.dynamicColor(
                  Colors.white,
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(context.l10n.followSystem),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.settingCubit.brightness = value,
                        value: null,
                      ),
                      trailing: null,
                    ),
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(context.l10n.light),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.settingCubit.brightness = value,
                        value: Brightness.light,
                      ),
                      trailing: null,
                    ),
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(context.l10n.dark),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.settingCubit.brightness = value,
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

class _MessageAvatarSetting extends HookWidget {
  const _MessageAvatarSetting();

  @override
  Widget build(BuildContext context) {
    final showAvatar = useBlocStateConverter<SettingCubit, SettingState, bool>(
      converter: (style) => style.messageShowAvatar,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 14, top: 22),
          child: Text(
            context.l10n.avatar,
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 14,
            ),
          ),
        ),
        CellGroup(
          cellBackgroundColor: context.dynamicColor(
            Colors.white,
            darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
          ),
          child: CellItem(
            title: Text(context.l10n.showAvatar),
            trailing: Transform.scale(
                scale: 0.7,
                child: CupertinoSwitch(
                  activeColor: context.theme.accent,
                  value: showAvatar,
                  onChanged: (bool value) =>
                      context.settingCubit.messageShowAvatar = value,
                )),
          ),
        )
      ],
    );
  }
}

class _ChatTextSizeSetting extends HookWidget {
  const _ChatTextSizeSetting();

  @override
  Widget build(BuildContext context) {
    final fontSize = useBlocStateConverter<SettingCubit, SettingState, double>(
      converter: (style) => style.chatFontSizeDelta,
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
              context.l10n.chatTextSize,
              style: TextStyle(
                color: context.theme.secondaryText,
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
                  color: context.theme.text,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 4,
                    trackShape: RoundedRectSliderTrackShape(),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: fontSize,
                    min: -2,
                    divisions: 6,
                    max: 4,
                    onChanged: (value) {
                      debugPrint('fontSize: $value');
                      context.settingCubit.chatFontSizeDelta = value;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'A',
                style: TextStyle(
                  fontSize: 24,
                  color: context.theme.text,
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
    content: content,
  );
}

class _ChatTextSizePreview extends HookWidget {
  const _ChatTextSizePreview();

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final blinkCubit = useMemoized(() => BlinkCubit(
          tickerProvider,
          context.theme.accent.withOpacity(0.5),
        ));
    final chatSideCubit = useBloc(ChatSideCubit.new);
    final searchConversationKeywordCubit = useBloc(
      () => SearchConversationKeywordCubit(chatSideCubit: chatSideCubit),
    );

    final messageHi =
        useMemoized(() => _buildFakeTextMessage(context.l10n.sayHi));
    final messageAnswer =
        useMemoized(() => _buildFakeTextMessage(context.l10n.iAmGood));

    return MultiProvider(
      providers: [
        BlocProvider.value(value: searchConversationKeywordCubit),
        Provider<BlinkCubit>.value(value: blinkCubit),
        BlocProvider(create: (_) => HiddenMessageDayTimeBloc()),
      ],
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
          decoration: BoxDecoration(
            color: context.theme.chatBackground,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            image: DecorationImage(
              image: const ExactAssetImage(
                Resources.assetsImagesChatBackgroundPng,
              ),
              fit: BoxFit.none,
              colorFilter: ColorFilter.mode(
                context.brightnessValue == 1.0
                    ? Colors.white.withOpacity(0.02)
                    : Colors.black.withOpacity(0.03),
                BlendMode.srcIn,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MessageDayTime(dateTime: DateTime(2023)),
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
