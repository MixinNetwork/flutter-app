import 'package:flutter/material.dart' hide AnimatedTheme;
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_bloc.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/ui/landing/landing.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';

import 'account/account_server.dart';
import 'constants/brightness_theme_data.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Portal(
        child: BlocProvider(
          create: (context) => MultiAuthCubit(),
          child: BlocConverter<MultiAuthCubit, MultiAuthState, AuthState>(
            converter: (state) => state.current,
            builder: (context, authState) {
              final app = MaterialApp(
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
                    Provider.of<AccountServer>(context)?.language =
                        Localizations.localeOf(context)?.languageCode;
                  } catch (_) {}
                  return BrightnessObserver(
                    child: child,
                    lightThemeData: lightBrightnessThemeData,
                    darkThemeData: darkBrightnessThemeData,
                  );
                },
                home: BlocConverter<MultiAuthCubit, MultiAuthState, bool>(
                  converter: (state) => state?.current != null,
                  builder: (context, authAvailable) {
                    AccountServer accountServer;
                    try {
                      accountServer = Provider.of<AccountServer>(context);
                    } catch (_) {}
                    if (authAvailable && accountServer != null) {
                      BlocProvider.of<ConversationListBloc>(context)
                        ..limit = MediaQuery.of(context).size.height ~/ 40
                        ..init();
                      accountServer.initSticker();
                      return HomePage();
                    }
                    return const LandingPage();
                  },
                ),
              );
              if (authState == null) return app;

              final slideCategoryCubit = SlideCategoryCubit();
              final draftCubit = DraftCubit();
              final responsiveNavigatorCubit = ResponsiveNavigatorCubit();

              return FutureBuilder(
                future: () async {
                  final accountServer = AccountServer();
                  await accountServer.initServer(
                    authState.account.userId,
                    authState.account.sessionId,
                    authState.account.identityNumber,
                    authState.privateKey,
                  );
                  return accountServer;
                }(),
                builder: (BuildContext context,
                        AsyncSnapshot<AccountServer> snapshot) =>
                    Provider<AccountServer>(
                  key: ValueKey(snapshot.data?.userId),
                  create: (context) => snapshot.data,
                  dispose:
                      (BuildContext context, AccountServer accountServer) =>
                          accountServer?.stop(),
                  child: Builder(
                    builder: (context) {
                      if (snapshot.connectionState == ConnectionState.done)
                        return MultiBlocProvider(
                          providers: [
                            BlocProvider(
                              create: (BuildContext context) =>
                                  slideCategoryCubit,
                            ),
                            BlocProvider(
                              create: (BuildContext context) => draftCubit,
                            ),
                            BlocProvider(
                              create: (BuildContext context) =>
                                  responsiveNavigatorCubit,
                            ),
                            BlocProvider(
                              create: (BuildContext context) =>
                                  ConversationListBloc(slideCategoryCubit,
                                      snapshot.data.database),
                            ),
                            BlocProvider(
                              create: (BuildContext context) =>
                                  ConversationCubit(draftCubit, snapshot.data),
                            ),
                          ],
                          child: app,
                        );
                      return app;
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
}
