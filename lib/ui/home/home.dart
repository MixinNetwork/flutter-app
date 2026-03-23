import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    hide ChangeNotifierProvider, Provider;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../blaze/blaze.dart';
import '../../utils/device_transfer/device_transfer_widget.dart';
import '../../utils/extension/extension.dart';
import '../../utils/platform.dart';
import '../../utils/system/package_info.dart';
import '../../utils/system/text_input.dart';
import '../../widgets/automatic_keep_alive_client_widget.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty.dart';
import '../../widgets/protocol_handler.dart';
import '../../widgets/toast.dart';
import '../landing/landing.dart';
import '../provider/account_server_provider.dart';
import '../provider/conversation_provider.dart';
import '../provider/multi_auth_provider.dart';
import '../provider/responsive_navigator_provider.dart';
import '../provider/setting_provider.dart';
import '../provider/slide_category_provider.dart';
import '../provider/ui_context_providers.dart';
import '../setting/setting_page.dart';

import 'command_palette_wrapper.dart';
import 'conversation/conversation_hotkey.dart';
import 'conversation/conversation_page.dart';
import 'providers/home_scope_providers.dart';
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
final _updateRequiredProvider = StreamProvider.autoDispose<bool>((ref) {
  final accountServer = ref.watch(accountServerProvider).value;
  if (accountServer == null) {
    return Stream.value(false);
  }
  return accountServer.isUpdateRequired;
});

final _packageInfoProvider = FutureProvider.autoDispose(
  (ref) => getPackageInfo(),
);

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localTimeError = ref.watch(
      appRuntimeHubProvider.select(
        (value) => value.connectedState == ConnectedState.hasLocalTimeError,
      ),
    );

    final isEmptyUserName = ref.watch(
      authAccountProvider.select((value) => value?.fullName?.isEmpty ?? true),
    );

    final updateRequired = ref.watch(_updateRequiredProvider).value ?? false;

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

class _RequiredUpdateWidget extends HookConsumerWidget {
  const _RequiredUpdateWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final info = ref.watch(_packageInfoProvider).value;
    return Material(
      color: theme.background,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.updateMixin,
                  style: TextStyle(color: theme.text, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.updateMixinDescription(info?.version ?? ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.text, fontSize: 14),
                ),
                const SizedBox(height: 32),
                MixinButton(
                  onTap: () async {
                    await launchUrlString('https://mixin.one/messenger');
                  },
                  child: Text(l10n.upgrade),
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

class _LocalTimeError extends HookConsumerWidget {
  const _LocalTimeError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final loading = useState(false);
    return Material(
      color: theme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.loadingTime,
              style: TextStyle(color: theme.text, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (loading.value) CircularProgressIndicator(color: theme.accent),
            if (!loading.value)
              MixinButton(
                onTap: () async {
                  loading.value = true;
                  try {
                    await ref
                        .read(accountServerProvider)
                        .requireValue
                        .reconnectBlaze();
                  } catch (_) {}

                  loading.value = false;
                },
                child: Text(l10n.continueText),
              ),
          ],
        ),
      ),
    );
  }
}

class _SetupNameWidget extends HookConsumerWidget {
  const _SetupNameWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final textEditingController = useMemoized(EmojiTextEditingController.new);
    final textEditingValue = useValueListenable(textEditingController);
    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: AlertDialogLayout(
          title: Text(l10n.whatsYourName),
          content: DialogTextField(
            textEditingController: textEditingController,
            hintText: l10n.name,
            maxLength: 40,
          ),
          actions: [
            MixinButton(
              disable: textEditingValue.text.trim().isEmpty,
              onTap: () async {
                showToastLoading();
                try {
                  await ref
                      .read(accountServerProvider)
                      .requireValue
                      .updateAccount(
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
              child: Text(l10n.confirm),
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
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final maxWidth = constraints.maxWidth;
    final clampSlideWidth = (maxWidth - kResponsiveNavigationMinWidth).clamp(
      kSlidePageMinWidth,
      kSlidePageMaxWidth,
    );

    final userCollapse = ref.watch(
      settingProvider.select((value) => value.collapsedSidebar),
    );

    final autoCollapse = clampSlideWidth < kSlidePageMaxWidth;
    final collapse = userCollapse || autoCollapse;

    var targetWidth = collapse ? kSlidePageMinWidth : kSlidePageMaxWidth;
    if (clampSlideWidth <= kSlidePageMinWidth || kPlatformIsIphone) {
      targetWidth = 0;
    }

    final hasDrawer = targetWidth == 0;

    return Scaffold(
      backgroundColor: theme.primary,
      drawerEnableOpenDragGesture: false,
      drawer: hasDrawer
          ? Drawer(
              child: Container(
                width: kSlidePageMaxWidth,
                color: theme.primary,
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
                builder: (context, value, child) => SizedBox(
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
                      child: _CenterPage(hasDrawer: hasDrawer),
                    ),
                  ),
                  rightEmptyPage: MaterialPage(
                    key: const ValueKey('empty'),
                    name: 'empty',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.chatBackground,
                      ),
                      child: Empty(text: l10n.pickAConversation),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterPage extends HookConsumerWidget {
  const _CenterPage({
    required this.hasDrawer,
  });

  final bool hasDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final isSetting = ref.watch(
      slideCategoryProvider.select(
        (value) => value.type == SlideCategoryType.setting,
      ),
    );

    ref.listen(slideCategoryProvider, (previous, next) {
      final isSetting = next.type == SlideCategoryType.setting;

      final responsiveNavigatorNotifier = ref.read(
        responsiveNavigatorProvider.notifier,
      );

      responsiveNavigatorNotifier.popWhere((page) {
        if (responsiveNavigatorNotifier.state.routeMode) return true;

        return ResponsiveNavigatorStateNotifier.settingPageNameSet.contains(
          page.name,
        );
      });

      if (isSetting && !responsiveNavigatorNotifier.state.routeMode) {
        ref.read(conversationProvider.notifier).unselected();
        responsiveNavigatorNotifier.pushPage(
          ResponsiveNavigatorStateNotifier.settingPageNameSet.first,
        );
      }
    });

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.primary,
          border: Border(right: BorderSide(color: theme.divider)),
        ),
        child: IndexedStack(
          index: isSetting ? 1 : 0,
          sizing: StackFit.expand,
          children: [
            AutomaticKeepAliveClientWidget(
              child: ConversationPage(hasDrawer: hasDrawer),
            ),
            AutomaticKeepAliveClientWidget(
              child: SettingPage(hasDrawer: hasDrawer),
            ),
          ],
        ),
      ),
    );
  }
}
