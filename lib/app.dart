import 'package:flutter/material.dart' hide AnimatedTheme;
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final slideCategoryCubit = SlideCategoryCubit();
    final draftCubit = DraftCubit();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (BuildContext context) {
            return slideCategoryCubit;
          },
        ),
        BlocProvider(
          create: (BuildContext context) => ConversationListCubit(slideCategoryCubit),
        ),
        BlocProvider(
          create: (BuildContext context) => ConversationCubit(draftCubit),
        ),
        BlocProvider(
          create: (BuildContext context) {
            return draftCubit;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Mixin',
        builder: (context, child) => BrightnessObserver(
          child: child,
        ),
        home: HomePage(),
      ),
    );
  }
}
