import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:overlay_support/overlay_support.dart' show OverlaySupport;
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/brightness_theme_data.dart';
import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart' hide Offset;
import '../../../generated/l10n.dart';
import '../../../ui/provider/setting_provider.dart';
import '../../../widgets/auth.dart' show appLocked;
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/brightness_observer.dart';
import '../../../widgets/conversation/badges_widget.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/user/user_dialog.dart';
import '../../extension/extension.dart';
import '../../hook.dart';
import '../../system/system_fonts.dart';
import '../forward_web_page.dart';
import 'bot_window.dart';

/// Renders the `•••` menu of every browser window into the Flutter view the
/// runner created for it. The views share the main engine, so the sheet reads
/// the same account, database and providers as the main window.
///
/// Mount it above the main window's [MaterialApp]: each menu has its own
/// navigator for the menu and bot profile; sharing uses the main window.
class BotWindowPopupHost extends StatefulWidget {
  const BotWindowPopupHost({required this.child, super.key});

  final Widget child;

  @override
  State<BotWindowPopupHost> createState() => _BotWindowPopupHostState();
}

class _BotWindowPopupHostState extends State<BotWindowPopupHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Views are added and removed natively; either may arrive before or after
  // BotWindow.popups changes.
  @override
  void didChangeMetrics() => setState(() {});

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Map<int, BotWindow>>(
        valueListenable: BotWindow.popups,
        child: widget.child,
        builder: (context, popups, child) {
          final dispatcher = WidgetsBinding.instance.platformDispatcher;
          final views = [
            for (final MapEntry(key: viewId, value: window) in popups.entries)
              if (dispatcher.view(id: viewId) case final view?)
                View(
                  key: ValueKey(viewId),
                  view: view,
                  child: _PopupApp(window: window),
                ),
          ];
          return ViewAnchor(
            view: views.isEmpty ? null : ViewCollection(views: views),
            child: child!,
          );
        },
      );
}

class _PopupApp extends HookConsumerWidget {
  const _PopupApp({required this.window});

  final BotWindow window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      localizationsDelegates: const [
        Localization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [...Localization.delegate.supportedLocales],
      theme: ThemeData(
        colorScheme: ColorScheme.light(primary: lightBrightnessThemeData.text),
        useMaterial3: true,
      ).withFallbackFonts(),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(primary: darkBrightnessThemeData.text),
        useMaterial3: true,
      ).withFallbackFonts(),
      themeMode: settings.themeMode,
      builder: (context, child) => BrightnessObserver(
        lightThemeData: lightBrightnessThemeData,
        darkThemeData: darkBrightnessThemeData,
        forceBrightness: settings.brightness,
        child: OverlaySupport.local(child: child!),
      ),
      home: _PopupLayer(window: window),
    );
  }
}

/// Animates the menu in and out with [BotWindow.popupVisible]. Empty once
/// dismissed, so a hidden view keeps no stale frame.
class _PopupLayer extends StatefulWidget {
  const _PopupLayer({required this.window});

  final BotWindow window;

  @override
  State<_PopupLayer> createState() => _PopupLayerState();
}

class _PopupLayerState extends State<_PopupLayer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 100),
  )..addStatusListener(_onStatusChanged);

  BotWindow get _window => widget.window;

  @override
  void initState() {
    super.initState();
    _window.popupVisible.addListener(_onVisibleChanged);
    appLocked.addListener(_onLocked);
    _onVisibleChanged();
  }

  @override
  void dispose() {
    _window.popupVisible.removeListener(_onVisibleChanged);
    appLocked.removeListener(_onLocked);
    _controller.dispose();
    _window.popupDismissed();
    super.dispose();
  }

  void _onVisibleChanged() {
    if (_window.popupVisible.value) {
      _controller.forward();
      return;
    }
    _controller.reverse();
    // The bot profile is a route of this view's navigator and would outlive
    // a popup dismissed from outside, then show over the next menu.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // The menu and the bot profile are outside the main window's lock screen.
  void _onLocked() {
    if (appLocked.value) unawaited(_window.hidePopup());
  }

  void _onStatusChanged(AnimationStatus status) {
    // Rebuild to mount or drop the page.
    setState(() {});
    if (status.isDismissed) _window.popupDismissed();
  }

  @override
  Widget build(BuildContext context) => _controller.isDismissed
      ? const SizedBox.shrink()
      : _PopupPage(window: _window, animation: _controller);
}

/// A desktop menu hanging from the capsule, over a transparent barrier that
/// closes it on any click outside.
class _PopupPage extends StatefulWidget {
  const _PopupPage({required this.window, required this.animation});

  final BotWindow window;
  final Animation<double> animation;

  @override
  State<_PopupPage> createState() => _PopupPageState();
}

class _PopupPageState extends State<_PopupPage> {
  // About replaces the menu with the bot's profile.
  var _menuShown = true;

  BotWindow get _window => widget.window;

  Future<void> _about(App app) async {
    setState(() => _menuShown = false);
    await showMixinDialog<void>(
      context: context,
      child: UserDialog(
        userId: app.appId,
        showMainWindow: _window.showMainWindow,
      ),
    );
    await _window.hidePopup();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final anchor = _window.popupAnchor;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            unawaited(_window.hidePopup()),
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Absorbs every pointer event, also while animating, so nothing
            // behind the menu reacts.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(_window.hidePopup()),
            ),
            if (_menuShown)
              Positioned(
                // On Linux the view starts below the title bar, at the
                // capsule's bottom.
                top: (anchor.bottom + 4).clamp(0, double.infinity),
                right: MediaQuery.sizeOf(context).width - anchor.right,
                child: FadeTransition(
                  opacity: curve,
                  child: ScaleTransition(
                    alignment: Alignment.topRight,
                    scale: Tween<double>(
                      begin: 0.95,
                      end: 1,
                    ).animate(curve),
                    child: _Menu(window: _window, onAbout: _about),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The app's context menu, headed by what the window shows.
class _Menu extends StatelessWidget {
  const _Menu({required this.window, required this.onAbout});

  final BotWindow window;
  final void Function(App app) onAbout;

  @override
  Widget build(BuildContext context) {
    final app = window.app;
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: context.theme.divider,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: ContextMenuPage(
        menus: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: app != null
                ? _BotHeader(app: app)
                : _PageHeader(window: window),
          ),
          divider,
          ContextMenu(
            icon: Resources.assetsImagesShareSvg,
            title: context.l10n.forward,
            onTap: () => _forward(window),
          ),
          ContextMenu(
            icon: Resources.assetsImagesInviteRefreshSvg,
            title: context.l10n.refresh,
            onTap: () {
              unawaited(window.webview.reload());
              unawaited(window.hidePopup());
            },
          ),
          if (app != null) ...[
            divider,
            ContextMenu(
              icon: Resources.assetsImagesInformationSvg,
              title: context.l10n.about,
              onTap: () => onAbout(app),
            ),
          ] else ...[
            ContextMenu(
              icon: Resources.assetsImagesCopySvg,
              title: context.l10n.copyLink,
              onTap: () async {
                final url = window.webview.navigationState.value.url;
                if (url != null) {
                  await Clipboard.setData(ClipboardData(text: url));
                }
                await window.hidePopup();
              },
            ),
            ContextMenu(
              icon: Resources.assetsImagesExternalLinkSvg,
              title: context.l10n.openInBrowser,
              onTap: () {
                final url = window.webview.navigationState.value.url;
                final uri = url == null ? null : Uri.tryParse(url);
                if (uri != null) unawaited(launchUrl(uri));
                unawaited(window.hidePopup());
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _BotHeader extends HookConsumerWidget {
  const _BotHeader({required this.app});

  final App app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = useMemoizedStream(
      () => context.database.userDao.userById(app.appId).watchSingleOrNull(),
      keys: [app.appId],
    ).data;
    return Row(
      children: [
        AvatarWidget(
          size: 32,
          avatarUrl: app.iconUrl,
          userId: app.appId,
          name: app.name,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.theme.text, fontSize: 14),
                    ),
                  ),
                  BadgesWidget(
                    verified: user?.isVerified ?? false,
                    isBot: true,
                    membership: user?.membership,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.contactMixinId(app.appNumber),
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.window});

  final BotWindow window;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: window.webview.navigationState,
    builder: (context, state, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.theme.text, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          state.url ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.theme.secondaryText, fontSize: 12),
        ),
      ],
    ),
  );
}

/// Picks the conversation in the main window, like a forward from a chat.
Future<void> _forward(BotWindow window) async {
  final state = window.webview.navigationState.value;
  final url = state.url;
  if (url == null) return;
  final context = await window.showMainWindow();
  if (context == null || !context.mounted) return;
  await forwardWebPage(
    context,
    url: url,
    title: state.title,
    app: window.app,
    appCardData: window.appCardData,
  );
}
