import 'package:flutter/material.dart' hide AnimatedTheme;
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_bloc.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/bloc/participants_cubit.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/ui/landing/landing.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'account/account_server.dart';
import 'bloc/keyword_cubit.dart';
import 'constants/brightness_theme_data.dart';

class App extends StatelessWidget {
  final accountServer = AccountServer();

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => MultiAuthCubit(),
          ),
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
                await accountServer.initServer(
                  authState.account.userId,
                  authState.account.sessionId,
                  authState.account.identityNumber,
                  authState.privateKey,
                );
                return accountServer;
              },
              initialData: null,
              builder: (BuildContext context, _) => Consumer<AccountServer?>(
                builder: (context, accountServer, child) {
                  if (accountServer != null)
                    return _Providers(
                      app: Portal(
                        child: child!,
                      ),
                      accountServer: accountServer,
                    );
                  return child!;
                },
                child: app,
              ),
            );
          },
        ),
      );
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
  Widget build(BuildContext context) => Provider<AccountServer>(
        key: ValueKey(accountServer.userId),
        create: (context) => accountServer,
        dispose: (BuildContext context, AccountServer accountServer) =>
            accountServer.stop(),
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
                  conversationCubit:
                      context.read<ConversationCubit>(),
                  userId: accountServer.userId,
                ),
              ),
              BlocProvider(
                create: (BuildContext context) => KeywordCubit(),
              ),
            ],
            child: Builder(
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (BuildContext context) => ConversationListBloc(
                      context.read<SlideCategoryCubit>(),
                      accountServer.database,
                    ),
                  ),
                ],
                child: app,
              ),
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
  Widget build(BuildContext context) => MaterialApp(
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
        builder: (context, child) {
          try {
            Provider.of<AccountServer>(context).language =
                Localizations.localeOf(context).languageCode;
          } catch (_) {}
          return BrightnessObserver(
            child: child!,
            lightThemeData: lightBrightnessThemeData,
            darkThemeData: darkBrightnessThemeData,
          );
        },
        home: const _Home(),
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
          ..initSticker()
          ..initCircles();
      }
    }, [signed]);

    if (signed) {
      BlocProvider.of<ConversationListBloc>(context)
        ..limit = MediaQuery.of(context).size.height ~/ 40
        ..init();
      return HomePage();
    }
    return const LandingPage();
  }
}
