import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../bloc/simple_cubit.dart';
import '../utils/hook.dart';
import 'menu.dart';

class FullScreenVisibleCubit extends SimpleCubit<bool> {
  FullScreenVisibleCubit(super.state);
}

class FullScreenPortal extends HookConsumerWidget {
  const FullScreenPortal({
    required this.builder,
    required this.portalBuilder,
    super.key,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeOut,
  });

  final WidgetBuilder builder;
  final WidgetBuilder portalBuilder;

  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleBloc = useBloc<FullScreenVisibleCubit>(
      () => FullScreenVisibleCubit(false),
    );
    final visible = useBlocState<FullScreenVisibleCubit, bool>(
      bloc: visibleBloc,
    );
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
            builder:
                (context, progress, child) =>
                    Opacity(opacity: progress, child: child),
            child: visible ? Builder(builder: portalBuilder) : const SizedBox(),
          ),
          child: Builder(builder: builder),
        ),
      ),
    );
  }
}
