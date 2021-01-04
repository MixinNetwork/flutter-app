import 'package:flutter/material.dart' hide AnimatedTheme;
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/ui/setting/bloc/setting_selected_cubit.dart';
import 'package:flutter_app/ui/landing/landing.dart';
import 'package:flutter_app/utils/Preferences.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mixin_client.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final slideCategoryCubit = SlideCategoryCubit();
    final draftCubit = DraftCubit();
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
          create: (BuildContext context) => SettingSelectedCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Mixin',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => BrightnessObserver(
          child: child,
        ),
        home: _getHomePage(),
      ),
    );
  }

  Widget _getHomePage() {
    final account = Preferences().getAccount();
    final privateKey = Preferences().getPrivateKey();
    if (account != null || privateKey != null) {
      MixinClient().client.initMixin(
          account.userId,
          account.sessionId,
          privateKey,
          'PROFILE:READ PROFILE:WRITE PHONE:READ PHONE:WRITE CONTACTS:READ CONTACTS:WRITE MESSAGES:READ MESSAGES:WRITE ASSETS:READ SNAPSHOTS:READ CIRCLES:READ CIRCLES:WRITE');
      return HomePage();
    } else {
      return const LandingPage();
    }
  }
}
