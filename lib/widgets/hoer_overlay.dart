import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:tuple/tuple.dart';

class _HoverOverlayCubit extends Cubit<Tuple2<bool, bool>> {
  _HoverOverlayCubit() : super(const Tuple2(false, false));

  void childHovering() => emit(state.withItem1(true));

  void childExited() => emit(state.withItem1(false));

  void portalHovering() => emit(state.withItem2(true));

  void portalExited() => emit(state.withItem2(false));
}

class HoverOverlay extends StatelessWidget {
  const HoverOverlay({
    Key key,
    @required this.closeDuration,
    @required this.child,
    this.childAnchor,
    this.portalAnchor,
    @required this.portal,
    @required this.duration,
    this.closeWaitDuration = Duration.zero,
    this.inCurve = Curves.linear,
    this.outCurve = Curves.linear,
    this.portalBuilder,
  }) : super(key: key);

  final Alignment portalAnchor;
  final Alignment childAnchor;
  final Widget portal;
  final Widget child;
  final Duration closeDuration;
  final Duration duration;
  final Duration closeWaitDuration;
  final Curve inCurve;
  final Curve outCurve;
  final ValueWidgetBuilder portalBuilder;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => _HoverOverlayCubit(),
        child: Builder(
          builder: (BuildContext context) =>
              BlocConverter<_HoverOverlayCubit, Tuple2<bool, bool>, bool>(
            converter: (state) => state.item1 || state.item2,
            builder: (context, visible) {
              final wait = closeWaitDuration.inMicroseconds;
              final totalClose = (wait + closeDuration.inMicroseconds);
              return PortalEntry(
                visible: visible,
                childAnchor: childAnchor,
                portalAnchor: portalAnchor,
                closeDuration: Duration(microseconds: totalClose),
                portal: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: visible ? 1 : 0),
                  curve: Interval(
                    visible ? 0 : (wait / totalClose),
                    1,
                    curve: visible ? inCurve : outCurve,
                  ),
                  duration:
                      visible ? duration : Duration(microseconds: totalClose),
                  builder: (context, progress, child) =>
                      portalBuilder?.call(context, progress, child) ?? child,
                  child: MouseRegion(
                    onEnter: (_) => BlocProvider.of<_HoverOverlayCubit>(context)
                        .portalHovering(),
                    onHover: (_) => BlocProvider.of<_HoverOverlayCubit>(context)
                        .portalHovering(),
                    onExit: (_) => BlocProvider.of<_HoverOverlayCubit>(context)
                        .portalExited(),
                    child: portal,
                  ),
                ),
                child: MouseRegion(
                  onEnter: (_) => BlocProvider.of<_HoverOverlayCubit>(context)
                      .childHovering(),
                  onHover: (_) => BlocProvider.of<_HoverOverlayCubit>(context)
                      .childHovering(),
                  onExit: (_) => BlocProvider.of<_HoverOverlayCubit>(context)
                      .childExited(),
                  child: child,
                ),
              );
            },
          ),
        ),
      );
}
