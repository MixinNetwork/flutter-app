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

import 'account/account_key_value.dart';
import 'account/account_server.dart';
import 'account/notification_service.dart';
import 'bloc/keyword_cubit.dart';
import 'bloc/minute_timer_cubit.dart';
import 'constants/brightness_theme_data.dart';
import 'constants/resources.dart';
import 'generated/l10n.dart';
import 'ui/home/bloc/conversation_cubit.dart';
import 'ui/home/bloc/conversation_filter_unseen_cubit.dart';
import 'ui/home/bloc/conversation_list_bloc.dart';
import 'ui/home/bloc/recall_message_bloc.dart';
import 'ui/home/bloc/slide_category_cubit.dart';
import 'ui/home/conversation/conversation_page.dart';
import 'ui/home/home.dart';
import 'ui/home/route/responsive_navigator_cubit.dart';
import 'ui/landing/landing.dart';
import 'ui/landing/landing_failed.dart';
import 'ui/provider/database_provider.dart';
import 'ui/provider/multi_auth_provider.dart';
import 'ui/provider/setting_provider.dart';
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
import 'widgets/message/item/text/mention_builder.dart';
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
      child = _LoginApp(authState: authState);
    }

    return FocusHelper(child: child);
  }
}

class _LoginApp extends ConsumerWidget {
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
    return FutureProvider<AsyncSnapshot<AccountServer>?>(
      key: ValueKey((
        authState.account.userId,
        authState.account.sessionId,
        authState.account.identityNumber,
        authState.privateKey,
      )),
      create: (BuildContext context) async {
        try {
          final accountServer = AccountServer(
            ref.read(multiAuthNotifierProvider),
            ref.read(settingProvider),
            database: database.requireValue,
          );
          await accountServer.initServer(
            authState.account.userId,
            authState.account.sessionId,
            authState.account.identityNumber,
            authState.privateKey,
          );
          return AsyncSnapshot<AccountServer>.withData(
              ConnectionState.done, accountServer);
        } catch (e, s) {
          w('accountServer.initServer error: $e, $s');
          return AsyncSnapshot<AccountServer>.withError(
              ConnectionState.done, e, s);
        }
      },
      initialData: null,
      builder: (BuildContext context, _) =>
          Consumer<AsyncSnapshot<AccountServer>?>(
        builder: (context, result, child) {
          if (result != null) {
            if (result.data != null) {
              return _Providers(
                app: child!,
                accountServer: result.requireData,
              );
            } else {
              return Provider<AsyncSnapshot<AccountServer>?>.value(
                value: result,
                child: child,
              );
            }
          }
          return child!;
        },
        child: const _App(home: _Home()),
      ),
    );
  }
}

class _Providers extends StatelessWidget {
  const _Providers({
    required this.app,
    required this.accountServer,
  });

  final Widget app;
  final AccountServer accountServer;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider<AccountServer>(
            key: ValueKey(accountServer.userId),
            create: (context) => accountServer,
            dispose: (BuildContext context, AccountServer accountServer) =>
                accountServer.stop(),
          ),
          Provider(
            create: (context) => MentionCache(accountServer.database.userDao),
          ),
        ],
        child: Builder(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (BuildContext context) => SlideCategoryCubit(),
              ),
              BlocProvider(
                create: (BuildContext context) => ResponsiveNavigatorCubit(),
              ),
              BlocProvider(
                create: (BuildContext context) => ConversationCubit(
                  accountServer: accountServer,
                  responsiveNavigatorCubit:
                      context.read<ResponsiveNavigatorCubit>(),
                ),
              ),
              BlocProvider(
                create: (context) => ConversationFilterUnseenCubit(),
              ),
              BlocProvider(
                create: (BuildContext context) => KeywordCubit(),
              ),
              BlocProvider(
                create: (BuildContext context) => MinuteTimerCubit(),
              ),
              BlocProvider(
                create: (BuildContext context) => ConversationListBloc(
                  context.read<SlideCategoryCubit>(),
                  accountServer.database,
                  context.read<MentionCache>(),
                ),
              ),
              BlocProvider(create: (context) => RecallMessageReeditCubit()),
            ],
            child: Provider<NotificationService>(
              create: (BuildContext context) =>
                  NotificationService(context: context),
              lazy: false,
              dispose: (_, notificationService) => notificationService.close(),
              child: PortalProviders(child: app),
            ),
          ),
        ),
      );
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
            themeMode: ref.read(settingProvider).themeMode,
            builder: (context, child) {
              try {
                context.accountServer.language =
                    Localizations.localeOf(context).languageCode;
              } catch (_) {}
              final mediaQueryData = MediaQuery.of(context);
              return BrightnessObserver(
                lightThemeData: lightBrightnessThemeData,
                darkThemeData: darkBrightnessThemeData,
                forceBrightness: ref.read(settingProvider).brightness,
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
    final authAvailable =
        ref.watch(authProvider.select((value) => value != null));
    AccountServer? accountServer;
    try {
      accountServer = context.read<AccountServer?>();
    } catch (_) {}
    final signed = authAvailable && accountServer != null;
    useEffect(() {
      if (signed) {
        accountServer!
          ..refreshSelf()
          ..refreshFriends()
          ..refreshSticker()
          ..initCircles()
          ..checkMigration();
      }
    }, [signed]);

    useEffect(() {
      Future<void> effect() async {
        if (!signed || accountServer == null) return;

        try {
          final currentDeviceId = await getDeviceId();
          if (currentDeviceId == 'unknown') return;

          final deviceId = AccountKeyValue.instance.deviceId;

          if (deviceId == null) {
            await AccountKeyValue.instance.setDeviceId(currentDeviceId);
            return;
          }

          if (deviceId != currentDeviceId) {
            final multiAuthCubit = context.multiAuthChangeNotifier;
            await accountServer.signOutAndClear();
            multiAuthCubit.signOut();
          }
        } catch (e) {
          w('checkDeviceId error: $e');
        }
      }

      effect();
    }, [signed]);

    if (signed) {
      BlocProvider.of<ConversationListBloc>(context)
        ..limit = MediaQuery.sizeOf(context).height ~/
            (ConversationPage.conversationItemHeight / 1.75)
        ..init();
      return const HomePage();
    }
    return const LandingPage();
  }
}
