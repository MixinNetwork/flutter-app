import 'dart:io';

import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide AnimatedTheme;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    hide FutureProvider, Provider;

import 'constants/brightness_theme_data.dart';
import 'constants/resources.dart';
import 'generated/l10n.dart';
import 'ui/home/conversation/conversation_page.dart';
import 'ui/home/home.dart';
import 'ui/home/providers/home_scope_providers.dart';
import 'ui/landing/landing.dart';
import 'ui/landing/landing_failed.dart';
import 'ui/provider/account_server_provider.dart';
import 'ui/provider/database_provider.dart';
import 'ui/provider/multi_auth_provider.dart';
import 'ui/provider/setting_provider.dart';
import 'ui/provider/ui_context_providers.dart';
import 'utils/extension/extension.dart';
import 'utils/system/system_fonts.dart';
import 'utils/system/text_input.dart';
import 'utils/system/tray.dart';
import 'widgets/actions/actions.dart';
import 'widgets/auth.dart';
import 'widgets/brightness_observer.dart';
import 'widgets/focus_helper.dart';
import 'widgets/portal_providers.dart';
import 'widgets/window/menus.dart';
import 'widgets/window/move_window.dart';
import 'widgets/window/window_shortcuts.dart';

final rootRouteObserver = RouteObserver<ModalRoute>();

class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    precacheImage(
      const AssetImage(Resources.assetsImagesChatBackgroundPng),
      context,
    );

    final authState = ref.watch(authProvider);

    Widget child;
    if (authState == null) {
      child = const _App(home: LandingPage());
    } else {
      child = _LoginApp(authState: authState);
    }
    return FocusHelper(child: child);
  }
}

class _LoginApp extends HookConsumerWidget {
  const _LoginApp({required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    if (database.isLoading) {
      return const _App(home: LandingPage());
    }
    if (database.hasError) {
      var error = database.error;
      if (error is DriftRemoteException) {
        error = error.remoteCause;
      }
      if (error is SqliteException) {
        return _App(home: DatabaseOpenFailedPage(error: error));
      } else {
        return _App(
          home: Consumer(
            builder: (context, ref, child) {
              final l10n = ref.watch(localizationProvider);
              return LandingFailedPage(
                title: l10n.unknowError,
                message: error.toString(),
                actions: [
                  ElevatedButton(onPressed: () {}, child: Text(l10n.exit)),
                ],
              );
            },
          ),
        );
      }
    }

    return const _Providers(app: _App(home: _Home()));
  }
}

class _Providers extends ConsumerWidget {
  const _Providers({required this.app});

  final Widget app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccountServer = ref.watch(accountServerProvider);
    if (!asyncAccountServer.hasValue) return app;
    return PortalProviders(child: app);
  }
}

class _App extends HookConsumerWidget {
  const _App({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) => WindowShortcuts(
    child: GlobalMoveWindow(
      child: MaterialApp(
        title: 'Mixin',
        navigatorObservers: [rootRouteObserver],
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          Localization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [...Localization.delegate.supportedLocales],
        theme: ThemeData(
          colorScheme: ColorScheme.light(
            primary: lightBrightnessThemeData.text,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: lightBrightnessThemeData.accent,
          ),
          useMaterial3: true,
        ).withFallbackFonts(),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: darkBrightnessThemeData.text,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: darkBrightnessThemeData.accent,
          ),
          useMaterial3: true,
        ).withFallbackFonts(),
        themeMode: ref.watch(settingProvider).themeMode,
        builder: (context, child) => BrightnessObserver(
          lightThemeData: lightBrightnessThemeData,
          darkThemeData: darkBrightnessThemeData,
          forceBrightness: ref.watch(settingProvider).brightness,
          child: UiContextScope(
            child: Consumer(
              builder: (context, ref, _) {
                try {
                  ref.read(accountServerProvider).value?.language = ref
                      .read(localeProvider)
                      .languageCode;
                } catch (_) {}
                final mediaQueryData = ref.watch(mediaQueryDataProvider);
                return MediaQuery(
                  data: mediaQueryData.copyWith(
                    // Different linux distro change the value, e.g. 1.2
                    textScaler: Platform.isLinux
                        ? TextScaler.noScaling
                        : mediaQueryData.textScaler,
                  ),
                  child: SystemTrayWidget(
                    child: TextInputActionHandler(
                      child: AuthGuard(child: child!),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        home: MixinAppActions(child: MacosMenuBar(child: home)),
      ),
    ),
  );
}

class _Home extends HookConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServer = ref.watch(
      accountServerProvider.select((value) => value.value),
    );

    if (accountServer != null) {
      final mediaQueryData = ref.watch(mediaQueryDataProvider);
      final notifier = ref.read(conversationListControllerProvider.notifier);
      // Defer state modifications to after widget build completes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier
          ..limit =
              mediaQueryData.size.height ~/
              (ConversationPage.conversationItemHeight / 1.75)
          ..init();
      });
      return const PortalProviders(child: HomePage());
    }
    return const LandingPage();
  }
}
