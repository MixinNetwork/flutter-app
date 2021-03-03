import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';

import 'menu.dart';

class FullScreenPortal extends StatelessWidget {
  const FullScreenPortal({
    Key? key,
    required this.builder,
    required this.portalBuilder,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeOut,
  }) : super(key: key);

  final WidgetBuilder builder;
  final WidgetBuilder portalBuilder;

  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => BoolCubit(false),
      child: Builder(
        builder: (context) => Barrier(
          duration: duration,
          visible: context.read<BoolCubit>().state,
          onClose: () => context.read<BoolCubit>().emit(false),
          child: PortalEntry(
            closeDuration: duration,
            visible: context.read<BoolCubit>().state,
            portal: TweenAnimationBuilder<double>(
              duration: duration,
              tween:
                  Tween(begin: 0, end: context.read<BoolCubit>().state ? 1 : 0),
              curve: curve,
              builder: (context, progress, child) => Opacity(
                opacity: progress,
                child: child,
              ),
              child: portalBuilder(context),
            ),
            child: builder(context),
          ),
        ),
      ),
    );
  }

  static BoolCubit of(BuildContext context) => context.read<BoolCubit>();
}
