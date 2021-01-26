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
import 'package:provider/provider.dart';

import 'account/account_server.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
            builder: (context, child) => BrightnessObserver(
              child: child,
            ),
            home: BlocConverter<MultiAuthCubit, MultiAuthState, bool>(
              converter: (state) => state?.current != null,
              builder: (context, authAvailable) {
                if (authAvailable)
                  return Builder(builder: (context) {
                    BlocProvider.of<ConversationListBloc>(context, listen: true)
                      ..limit = MediaQuery.of(context).size.height ~/ 40
                      ..init();
                    return HomePage();
                  });
                return const LandingPage();
              },
            ),
          );
          if (authState == null) return app;

          final slideCategoryCubit = SlideCategoryCubit();
          final draftCubit = DraftCubit();
          final responsiveNavigatorCubit = ResponsiveNavigatorCubit();
          final accountServer = AccountServer()
            ..initServer(
              authState.account.userId,
              authState.account.sessionId,
              authState.account.identityNumber,
              authState.privateKey,
            )
            ..start();
          return Provider<AccountServer>(
            key: ValueKey(authState?.account?.userId),
            create: (context) => accountServer,
            dispose: (BuildContext context, AccountServer value) =>
                value.stop(),
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (BuildContext context) => slideCategoryCubit,
                ),
                BlocProvider(
                  create: (BuildContext context) => draftCubit,
                ),
                BlocProvider(
                  create: (BuildContext context) => responsiveNavigatorCubit,
                ),
                BlocProvider(
                  create: (BuildContext context) => ConversationListBloc(
                      slideCategoryCubit, accountServer.database),
                ),
                BlocProvider(
                  create: (BuildContext context) =>
                      ConversationCubit(draftCubit, accountServer),
                ),
              ],
              child: app,
            ),
          );
        },
      ),
    );
  }
}
