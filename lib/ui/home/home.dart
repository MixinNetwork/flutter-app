import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    hide ChangeNotifierProvider, Provider;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import '../../blaze/blaze.dart';
import '../../utils/audio_message_player/audio_message_service.dart';
import '../../utils/device_transfer/device_transfer_widget.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/platform.dart';
import '../../widgets/automatic_keep_alive_client_widget.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty.dart';
import '../../widgets/protocol_handler.dart';
import '../../widgets/toast.dart';
import '../provider/conversation_provider.dart';
import '../provider/multi_auth_provider.dart';
import '../provider/responsive_navigator_provider.dart';
import '../provider/setting_provider.dart';
import '../provider/slide_category_provider.dart';
import '../setting/setting_page.dart';

import 'command_palette_wrapper.dart';
import 'conversation/conversation_hotkey.dart';
import 'conversation/conversation_page.dart';
import 'route/responsive_navigator.dart';
import 'slide_page.dart';

// chat category list min width
const kSlidePageMinWidth = 64.0;
// chat category and chat list max width
const kSlidePageMaxWidth = 176.0;
// chat page min width, message list, setting page etc.
const kResponsiveNavigationMinWidth = 320.0;
// conversation list fixed width, conversation list, setting list etc.
const kConversationListWidth = 300.0;
// chat side page fixed width, chat info page etc.
const kChatSidePageWidth = 300.0;

final _conversationPageKey = GlobalKey();

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localTimeError = useMemoizedStream(
            () => context.accountServer.connectedStateStream
                .map((event) => event == ConnectedState.hasLocalTimeError)
                .distinct(),
            keys: [context.accountServer]).data ??
        false;

    final isEmptyUserName = ref.watch(authAccountProvider
        .select((value) => value?.fullName?.isEmpty ?? true));

    return DeviceTransferHandlerWidget(
      child: CommandPaletteWrapper(
        child: ConversationHotKey(
          child: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    _HomePage(
                  constraints: constraints,
                ),
              ),
              if (isEmptyUserName) const _SetupNameWidget(),
              if (localTimeError)
                HookBuilder(builder: (context) {
                  final loading = useState(false);
                  return Material(
                    color: context.theme.background,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.loadingTime,
                            style: TextStyle(
                              color: context.theme.text,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (loading.value)
                            CircularProgressIndicator(
                              color: context.theme.accent,
                            ),
                          if (!loading.value)
                            MixinButton(
                              onTap: () async {
                                loading.value = true;
                                try {
                                  await context.accountServer.reconnectBlaze();
                                } catch (_) {}

                                loading.value = false;
                              },
                              child: Text(context.l10n.continueText),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupNameWidget extends HookConsumerWidget {
  const _SetupNameWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textEditingController = useTextEditingController();
    final textEditingValue = useValueListenable(textEditingController);
    return Scaffold(
      backgroundColor: context.theme.background,
      body: Center(
        child: AlertDialogLayout(
          title: Text(context.l10n.whatsYourName),
          content: DialogTextField(
            textEditingController: textEditingController,
            hintText: context.l10n.name,
            maxLength: 40,
          ),
          actions: [
            MixinButton(
              disable: textEditingValue.text.trim().isEmpty,
              onTap: () async {
                showToastLoading();
                try {
                  await context.accountServer.updateAccount(
                    fullName: textEditingController.text.trim(),
                  );
                } on MixinApiError catch (error) {
                  final mixinError = error.error! as MixinError;
                  showToastFailed(
                    ToastError(mixinError.toDisplayString(context)),
                  );
                  return;
                } catch (error) {
                  showToastFailed(null);
                  return;
                }
                showToastSuccessful();
              },
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }
}

class HasDrawerValueNotifier extends ValueNotifier<bool> {
  HasDrawerValueNotifier(super.value);
}

class _HomePage extends HookConsumerWidget {
  const _HomePage({
    required this.constraints,
  });

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxWidth = constraints.maxWidth;
    final clampSlideWidth = (maxWidth - kResponsiveNavigationMinWidth)
        .clamp(kSlidePageMinWidth, kSlidePageMaxWidth);

    final userCollapse =
        ref.watch(settingProvider.select((value) => value.collapsedSidebar));

    final autoCollapse = clampSlideWidth < kSlidePageMaxWidth;
    final collapse = userCollapse || autoCollapse;

    var targetWidth = collapse ? kSlidePageMinWidth : kSlidePageMaxWidth;
    if (clampSlideWidth <= kSlidePageMinWidth || kPlatformIsIphone) {
      targetWidth = 0;
    }

    final hasDrawerValueNotifier =
        useMemoized(() => HasDrawerValueNotifier(targetWidth == 0));

    final hasDrawer = useListenable(hasDrawerValueNotifier);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: hasDrawerValueNotifier),
        Provider(
          create: (context) => AudioMessagePlayService(context.accountServer),
          dispose: (BuildContext context, AudioMessagePlayService service) =>
              service.dispose(),
        ),
      ],
      child: Scaffold(
        backgroundColor: context.theme.primary,
        drawerEnableOpenDragGesture: false,
        drawer: hasDrawer.value && targetWidth == 0
            ? Drawer(
                child: Container(
                  width: kSlidePageMaxWidth,
                  color: context.theme.primary,
                  child: const SlidePage(showCollapse: false),
                ),
              )
            : null,
        body: SafeArea(
          child: AppProtocolHandler(
            child: Row(
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(end: targetWidth),
                  duration: const Duration(milliseconds: 200),
                  onEnd: () => hasDrawerValueNotifier.value = targetWidth == 0,
                  builder:
                      (BuildContext context, double? value, Widget? child) =>
                          SizedBox(
                    width: value,
                    child: value == 0 ? null : child,
                  ),
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: kSlidePageMinWidth,
                    maxWidth: collapse ? kSlidePageMinWidth : clampSlideWidth,
                    child: SlidePage(showCollapse: !autoCollapse),
                  ),
                ),
                Expanded(
                  child: ResponsiveNavigator(
                    switchWidth:
                        kResponsiveNavigationMinWidth + kConversationListWidth,
                    leftPage: MaterialPage(
                      key: const ValueKey('center'),
                      name: 'center',
                      child: SizedBox(
                        key: _conversationPageKey,
                        width: kConversationListWidth,
                        child: const _CenterPage(),
                      ),
                    ),
                    rightEmptyPage: MaterialPage(
                      key: const ValueKey('empty'),
                      name: 'empty',
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.theme.chatBackground,
                        ),
                        child: Empty(text: context.l10n.pickAConversation),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterPage extends HookConsumerWidget {
  const _CenterPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSetting = ref.watch(slideCategoryStateProvider
        .select((value) => value.type == SlideCategoryType.setting));

    ref.listen(slideCategoryStateProvider, (previous, next) {
      final isSetting = next.type == SlideCategoryType.setting;

      final responsiveNavigatorNotifier =
          context.providerContainer.read(responsiveNavigatorProvider.notifier);

      responsiveNavigatorNotifier.popWhere((page) {
        if (responsiveNavigatorNotifier.state.routeMode) return true;

        return ResponsiveNavigatorStateNotifier.settingPageNameSet
            .contains(page.name);
      });

      if (isSetting && !responsiveNavigatorNotifier.state.routeMode) {
        ref.read(conversationProvider.notifier).unselected();
        responsiveNavigatorNotifier.pushPage(
            ResponsiveNavigatorStateNotifier.settingPageNameSet.first);
      }
    });

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.theme.primary,
          border: Border(
            right: BorderSide(
              color: context.theme.divider,
            ),
          ),
        ),
        child: IndexedStack(
          index: isSetting ? 1 : 0,
          sizing: StackFit.expand,
          children: const [
            AutomaticKeepAliveClientWidget(
              child: ConversationPage(),
            ),
            AutomaticKeepAliveClientWidget(child: SettingPage()),
          ],
        ),
      ),
    );
  }
}
