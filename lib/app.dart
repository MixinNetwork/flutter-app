import 'package:flutter/material.dart' hide AnimatedTheme;
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/ui/home/bloc/auth_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/ui/landing/landing.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

ResponsiveNavigatorCubit responsiveNavigatorCubit;

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final slideCategoryCubit = SlideCategoryCubit();
    final draftCubit = DraftCubit();
    final authCubit = AuthCubit();
    responsiveNavigatorCubit ??= ResponsiveNavigatorCubit();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (BuildContext context) => slideCategoryCubit,
        ),
        BlocProvider(
          create: (BuildContext context) =>
              ConversationListCubit(slideCategoryCubit),
        ),
        BlocProvider(
          create: (BuildContext context) => ConversationCubit(draftCubit),
        ),
        BlocProvider(
          create: (BuildContext context) => draftCubit,
        ),
        BlocProvider(
          create: (BuildContext context) => authCubit,
        ),
        BlocProvider(
          create: (BuildContext context) => responsiveNavigatorCubit,
        ),
      ],
      child: MaterialApp(
        title: 'Mixin',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => BrightnessObserver(
          child: child,
        ),
        home: BlocConverter<AuthCubit, AuthState, bool>(
          cubit: authCubit,
          converter: (state) =>
              state?.account != null && state?.privateKey != null,
          builder: (context, authAvailable) {
            if (authAvailable) return HomePage();
            return const LandingPage();
          },
        ),
      ),
    );
  }
}
