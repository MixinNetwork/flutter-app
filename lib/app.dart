import 'dart:io';

import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide AnimatedTheme;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    hide Provider, FutureProvider, Consumer;
import 'package:provider/provider.dart';

import 'account/notification_service.dart';
import 'constants/brightness_theme_data.dart';
import 'constants/resources.dart';
import 'generated/l10n.dart';
import 'ui/home/bloc/conversation_list_bloc.dart';
import 'ui/home/conversation/conversation_page.dart';
import 'ui/home/home.dart';
import 'ui/landing/landing.dart';
import 'ui/landing/landing_failed.dart';
import 'ui/landing/landing_initialize.dart';
import 'ui/provider/account/account_server_provider.dart';
import 'ui/provider/account/multi_auth_provider.dart';
import 'ui/provider/database_provider.dart';
import 'ui/provider/hive_key_value_provider.dart';
import 'ui/provider/mention_cache_provider.dart';
import 'ui/provider/setting_provider.dart';
import 'ui/provider/slide_category_provider.dart';
import 'utils/extension/extension.dart';
import 'utils/logger.dart';
import 'utils/platform.dart';
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
        const AssetImage(Resources.assetsImagesChatBackgroundPng), context);

    final authState = ref.watch(authProvider);

    Widget child;
    if (authState == null) {
      child = const _App(home: LandingPage());
    } else {
      child = const _LoginApp();
    }

    return FocusHelper(child: child);
  }
}

class _LoginApp extends HookConsumerWidget {
  const _LoginApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    final accountServer = ref.watch(accountServerProvider);

    if (database.isLoading || accountServer.isLoading) {
      return const _App(home: AppInitializingPage());
    }
    if (database.hasError) {
      var error = database.error;
      if (error is DriftRemoteException) {
        error = error.remoteCause;
      }
      if (error is SqliteException) {
        return _App(
          home: DatabaseOpenFailedPage(error: error),
        );
      } else {
        return _App(
          home: LandingFailedPage(
              title: context.l10n.unknowError,
              message: error.toString(),
              actions: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text(context.l10n.exit),
                )
              ]),
        );
      }
    }

    return const _Providers(app: _App(home: _Home()));
  }
}

class _Providers extends HookConsumerWidget {
  const _Providers({
    required this.app,
  });

  final Widget app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccountServer = ref.watch(accountServerProvider);
    if (!asyncAccountServer.hasValue) return app;
    final accountServer = asyncAccountServer.requireValue;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          key: ValueKey(accountServer),
          create: (BuildContext context) => ConversationListBloc(
            ref.read(slideCategoryStateProvider.notifier),
            accountServer.database,
            ref.read(mentionCacheProvider),
          ),
        ),
      ],
      child: Provider<NotificationService>(
        create: (BuildContext context) => NotificationService(
          context: context,
          accountServer: accountServer,
          ref: ref,
        ),
        lazy: false,
        dispose: (_, notificationService) => notificationService.close(),
        child: PortalProviders(child: app),
      ),
    );
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
            supportedLocales: [
              ...Localization.delegate.supportedLocales,
            ],
            theme: ThemeData(
              colorScheme:
                  ColorScheme.light(primary: lightBrightnessThemeData.text),
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: lightBrightnessThemeData.accent,
              ),
              useMaterial3: true,
            ).withFallbackFonts(),
            darkTheme: ThemeData(
              colorScheme:
                  ColorScheme.dark(primary: darkBrightnessThemeData.text),
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: darkBrightnessThemeData.accent,
              ),
              useMaterial3: true,
            ).withFallbackFonts(),
            themeMode: ref.watch(settingProvider).themeMode,
            builder: (context, child) {
              final mediaQueryData = MediaQuery.of(context);
              return BrightnessObserver(
                lightThemeData: lightBrightnessThemeData,
                darkThemeData: darkBrightnessThemeData,
                forceBrightness: ref.watch(settingProvider).brightness,
                child: MediaQuery(
                  data: mediaQueryData.copyWith(
                    // Different linux distro change the value, e.g. 1.2
                    textScaler: Platform.isLinux
                        ? TextScaler.noScaling
                        : mediaQueryData.textScaler,
                  ),
                  child: SystemTrayWidget(
                    child: TextInputActionHandler(
                      child: AuthGuard(
                        child: child!,
                      ),
                    ),
                  ),
                ),
              );
            },
            home: MixinAppActions(child: MacosMenuBar(child: home)),
          ),
        ),
      );
}

class _Home extends HookConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServer =
        ref.watch(accountServerProvider.select((value) => value.valueOrNull));

    useEffect(() {
      accountServer?.refreshSelf();
      accountServer?.refreshFriends();
      accountServer?.refreshSticker();
      accountServer?.initCircles();
      accountServer?.checkMigration();
    }, [accountServer]);

    useEffect(() {
      Future<void> effect() async {
        if (accountServer == null) return;

        try {
          final currentDeviceId = await getDeviceId();
          if (currentDeviceId == 'unknown') return;

          final accountKeyValue =
              await ref.read(currentAccountKeyValueProvider.future);
          if (accountKeyValue == null) {
            w('checkDeviceId error: accountKeyValue is null');
            return;
          }
          final deviceId = accountKeyValue.deviceId;
          if (deviceId == null) {
            await accountKeyValue.setDeviceId(currentDeviceId);
            return;
          }

          if (deviceId.toLowerCase() != currentDeviceId.toLowerCase()) {
            final multiAuthCubit = context.multiAuthChangeNotifier;
            await accountServer.signOutAndClear();
            multiAuthCubit.signOut();
          }
        } catch (e) {
          w('checkDeviceId error: $e');
        }
      }

      effect();
    }, [accountServer]);

    if (accountServer != null) {
      BlocProvider.of<ConversationListBloc>(context)
        ..limit = MediaQuery.sizeOf(context).height ~/
            (ConversationPage.conversationItemHeight / 1.75)
        ..init();
      return const HomePage();
    }
    return const LandingPage();
  }
}
