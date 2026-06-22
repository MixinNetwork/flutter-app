import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    hide ChangeNotifierProvider, Provider;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../blaze/blaze.dart';
import '../../utils/audio_message_player/audio_message_service.dart';
import '../../utils/device_transfer/device_transfer_widget.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/platform.dart';
import '../../utils/system/package_info.dart';
import '../../utils/system/text_input.dart';
import '../../widgets/automatic_keep_alive_client_widget.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty.dart';
import '../../widgets/protocol_handler.dart';
import '../../widgets/toast.dart';
import '../landing/landing.dart';
import '../provider/conversation_provider.dart';
import '../provider/major_navigation_provider.dart';
import '../provider/multi_auth_provider.dart';
import '../provider/setting_provider.dart';
import '../provider/slide_category_provider.dart';
import '../setting/setting_page.dart';

import 'command_palette_wrapper.dart';
import 'conversation/conversation_hotkey.dart';
import 'conversation/conversation_page.dart';
import 'desktop_shell_layout.dart';
import 'left_rail_controller.dart';
import 'route/major_navigator.dart';
import 'slide_page.dart';

final _conversationPageKey = GlobalKey();

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localTimeError =
        useMemoizedStream(
          () => context.accountServer.connectedStateStream
              .map((event) => event == ConnectedState.hasLocalTimeError)
              .distinct(),
          keys: [context.accountServer],
        ).data ??
        false;

    final isEmptyUserName = ref.watch(
      authAccountProvider.select((value) => value?.fullName?.isEmpty ?? true),
    );

    final updateRequired =
        useMemoizedStream(
          () => context.accountServer.isUpdateRequired,
          keys: [context.accountServer],
        ).data ??
        false;

    return DeviceTransferHandlerWidget(
      child: CommandPaletteWrapper(
        child: ConversationHotKey(
          child: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) =>
                    _HomePage(constraints: constraints),
              ),
              if (isEmptyUserName) const _SetupNameWidget(),
              if (localTimeError) const _LocalTimeError(),
              if (updateRequired) const _RequiredUpdateWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequiredUpdateWidget extends HookWidget {
  const _RequiredUpdateWidget();

  @override
  Widget build(BuildContext context) {
    final info = useMemoizedFuture(getPackageInfo, null).data;
    return Material(
      color: context.theme.background,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.updateMixin,
                  style: TextStyle(color: context.theme.text, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.updateMixinDescription(info?.version ?? ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.theme.text, fontSize: 14),
                ),
                const SizedBox(height: 32),
                MixinButton(
                  onTap: () async {
                    await launchUrlString('https://mixin.one/messenger');
                  },
                  child: Text(context.l10n.upgrade),
                ),
              ],
            ),
          ),
          const Positioned(bottom: 16, right: 16, child: VersionInfoWidget()),
        ],
      ),
    );
  }
}

class _LocalTimeError extends StatelessWidget {
  const _LocalTimeError();

  @override
  Widget build(BuildContext context) => HookBuilder(
    builder: (context) {
      final loading = useState(false);
      return Material(
        color: context.theme.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.loadingTime,
                style: TextStyle(color: context.theme.text, fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (loading.value)
                CircularProgressIndicator(color: context.theme.accent),
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
    },
  );
}

class _SetupNameWidget extends HookConsumerWidget {
  const _SetupNameWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textEditingController = useMemoized(EmojiTextEditingController.new);
    final textEditingValue = useValueListenable(textEditingController);
    return Scaffold(
      backgroundColor: context.theme.background,
      body: Center(
        child: AlertDialogLayout(
          title: Text(context.l10n.editName),
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

class _HomePage extends HookConsumerWidget {
  const _HomePage({required this.constraints});

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCollapse = ref.watch(
      settingProvider.select((value) => value.collapsedSidebar),
    );

    final shellLayout = DesktopShellLayout.resolve(
      maxWidth: constraints.maxWidth,
      userCollapse: userCollapse,
      isPhone: kPlatformIsIphone,
    );

    final leftRailController = useMemoized(
      () => LeftRailController(shellLayout),
    );

    final hasDrawer = useListenable(leftRailController);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: leftRailController),
        Provider(
          create: (context) => AudioMessagePlayService(context.accountServer),
          dispose: (context, service) => service.dispose(),
        ),
      ],
      child: Scaffold(
        backgroundColor: context.theme.primary,
        drawerEnableOpenDragGesture: false,
        drawer: hasDrawer.value && shellLayout.hasDrawer
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
                  tween: Tween<double>(end: shellLayout.slideWidth),
                  duration: const Duration(milliseconds: 200),
                  onEnd: () => leftRailController.sync(shellLayout),
                  builder: (context, value, child) => SizedBox(
                    width: value,
                    child: value == 0 ? null : child,
                  ),
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: kSlidePageMinWidth,
                    maxWidth: shellLayout.slideMaxWidth,
                    child: SlidePage(
                      showCollapse: shellLayout.showCollapseControl,
                    ),
                  ),
                ),
                Expanded(
                  child: MajorNavigator(
                    switchWidth: DesktopShellLayout.mainRouteSwitchWidth,
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
    final isSetting = ref.watch(
      slideCategoryStateProvider.select(
        (value) => value.type == SlideCategoryType.setting,
      ),
    );

    ref.listen(slideCategoryStateProvider, (previous, next) {
      final isSetting = next.type == SlideCategoryType.setting;

      final majorNavigationNotifier = context.providerContainer.read(
        majorNavigationProvider.notifier,
      );

      if (majorNavigationNotifier.syncSettingCategory(isSetting)) {
        ref.read(conversationProvider.notifier).unselected();
      }
    });

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.theme.primary,
          border: Border(right: BorderSide(color: context.theme.divider)),
        ),
        child: IndexedStack(
          index: isSetting ? 1 : 0,
          sizing: StackFit.expand,
          children: const [
            AutomaticKeepAliveClientWidget(child: ConversationPage()),
            AutomaticKeepAliveClientWidget(child: SettingPage()),
          ],
        ),
      ),
    );
  }
}
