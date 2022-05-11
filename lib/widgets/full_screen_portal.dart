import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';

import '../bloc/simple_cubit.dart';
import '../utils/hook.dart';
import 'menu.dart';

class FullScreenVisibleCubit extends SimpleCubit<bool> {
  FullScreenVisibleCubit(bool state) : super(state);
}

class FullScreenPortal extends HookWidget {
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
    final visibleBloc =
        useBloc<FullScreenVisibleCubit>(() => FullScreenVisibleCubit(false));
    final visible =
        useBlocState<FullScreenVisibleCubit, bool>(bloc: visibleBloc);
    return BlocProvider.value(
      value: visibleBloc,
      child: Barrier(
        duration: duration,
        visible: visible,
        onClose: () => visibleBloc.emit(false),
        child: PortalTarget(
          closeDuration: duration,
          visible: visible,
          portalFollower: TweenAnimationBuilder<double>(
            duration: duration,
            tween: Tween(begin: 0, end: visible ? 1 : 0),
            curve: curve,
            builder: (context, progress, child) => Opacity(
              opacity: progress,
              child: child,
            ),
            child: visible ? Builder(builder: portalBuilder) : const SizedBox(),
          ),
          child: Builder(builder: builder),
        ),
      ),
    );
  }
}
