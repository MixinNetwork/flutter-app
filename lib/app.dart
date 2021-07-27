import 'package:flutter/material.dart' hide AnimatedTheme;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'account/account_server.dart';
import 'account/notification_service.dart';
import 'bloc/bloc_converter.dart';
import 'bloc/keyword_cubit.dart';
import 'bloc/minute_timer_cubit.dart';
import 'bloc/setting_cubit.dart';
import 'constants/brightness_theme_data.dart';
import 'constants/resources.dart';
import 'generated/l10n.dart';
import 'ui/home/bloc/conversation_cubit.dart';
import 'ui/home/bloc/conversation_list_bloc.dart';
import 'ui/home/bloc/multi_auth_cubit.dart';
import 'ui/home/bloc/participants_cubit.dart';
import 'ui/home/bloc/slide_category_cubit.dart';
import 'ui/home/home.dart';
import 'ui/home/route/responsive_navigator_cubit.dart';
import 'ui/landing/landing.dart';
import 'utils/hook.dart';
import 'utils/logger.dart';
import 'widgets/brightness_observer.dart';
import 'widgets/default_text_editing_focusable_action_detector.dart';
import 'widgets/message/item/text/mention_builder.dart';
import 'widgets/window/move_window.dart';
import 'widgets/window/window_shortcuts.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    precacheImage(
        const AssetImage(Resources.assetsImagesChatBackgroundPng), context);
    return DefaultTextEditingFocusableActionDetector(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => MultiAuthCubit(),
          ),
          BlocProvider(create: (context) => SettingCubit()),
        ],
        child: BlocConverter<MultiAuthCubit, MultiAuthState, AuthState?>(
          converter: (state) => state.current,
          builder: (context, authState) {
            const app = _App();
            if (authState == null) return app;
            return FutureProvider<AccountServer?>(
              key: ValueKey(Tuple4(
                authState.account.userId,
                authState.account.sessionId,
                authState.account.identityNumber,
                authState.privateKey,
              )),
              create: (BuildContext context) async {
                final accountServer =
                    AccountServer(context.read<MultiAuthCubit>());
                try {
                  await accountServer.initServer(
                    authState.account.userId,
                    authState.account.sessionId,
                    authState.account.identityNumber,
                    authState.privateKey,
                  );
                } catch (e, s) {
                  w('accountServer.initServer error: $e, $s');
                  rethrow;
                }
                return accountServer;
              },
              initialData: null,
              builder: (BuildContext context, _) => Consumer<AccountServer?>(
                builder: (context, accountServer, child) {
                  if (accountServer != null) {
                    return _Providers(
                      app: Portal(
                        child: child!,
                      ),
                      accountServer: accountServer,
                    );
                  }
                  return child!;
                },
                child: app,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Providers extends StatelessWidget {
  const _Providers({
    Key? key,
    required this.app,
    required this.accountServer,
  }) : super(key: key);

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
                create: (BuildContext context) => ParticipantsCubit(
                  userDao: accountServer.database.userDao,
                  conversationCubit: context.read<ConversationCubit>(),
                  userId: accountServer.userId,
                ),
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
            ],
            child: Provider<NotificationService>(
              create: (BuildContext context) =>
                  NotificationService(context: context),
              lazy: false,
              dispose: (_, notificationService) => notificationService.close(),
              child: app,
            ),
          ),
        ),
      );
}

class _App extends StatelessWidget {
  const _App({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => WindowShortcuts(
        child: GlobalMoveWindow(
          child: MaterialApp(
            title: 'Mixin',
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
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
            builder: (context, child) {
              try {
                Provider.of<AccountServer>(context).language =
                    Localizations.localeOf(context).languageCode;
              } catch (_) {}
              return BrightnessObserver(
                lightThemeData: lightBrightnessThemeData,
                darkThemeData: darkBrightnessThemeData,
                forceBrightness: context.watch<SettingCubit>().brightness,
                child: child!,
              );
            },
            home: const _Home(),
          ),
        ),
      );
}

class _Home extends HookWidget {
  const _Home({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authAvailable =
        useBlocState<MultiAuthCubit, MultiAuthState>().current != null;
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
          ..initSticker()
          ..initCircles();
      }
    }, [signed]);

    if (signed) {
      BlocProvider.of<ConversationListBloc>(context)
        ..limit = MediaQuery.of(context).size.height ~/ 40
        ..init();
      return const HomePage();
    }
    return const LandingPage();
  }
}
