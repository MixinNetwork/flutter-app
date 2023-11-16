import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocConverter<C extends BlocBase<S>, S, T> extends StatefulWidget {
  const BlocConverter({
    required this.converter,
    super.key,
    this.cubit,
    this.when,
    this.builder,
    this.child,
    this.listener,
    this.immediatelyCallListener = false,
  })  : assert(builder != null || child != null),
        assert(!(builder != null && child != null));

  final C? cubit;
  final BlocBuilderCondition<T?>? when;
  final BlocConverterCondition<S, T> converter;

  final Widget? child;
  final BlocWidgetBuilder<T>? builder;
  final BlocWidgetListener<T>? listener;

  final bool immediatelyCallListener;

  @override
  State<StatefulWidget> createState() => _BlocConverterState<C, S, T>();
}

typedef BlocConverterCondition<S, T> = T Function(S state);

class _BlocConverterState<C extends BlocBase<S>, S, T>
    extends State<BlocConverter<C, S, T>> {
  StreamSubscription<T?>? _subscription;
  late T _previousState;
  late T _state;
  late C _cubit;

  T _converter(S state) => widget.converter(state);

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? context.read<C>();
    _previousState = _converter(_cubit.state);
    _state = _previousState;
    if (widget.immediatelyCallListener) widget.listener?.call(context, _state);
    _subscribe();
  }

  @override
  void didUpdateWidget(BlocConverter<C, S, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCubit = oldWidget.cubit ?? context.read<C>();
    final currentBloc = widget.cubit ?? oldCubit;
    if (oldCubit != currentBloc) {
      if (_subscription != null) {
        _unsubscribe();
        _cubit = widget.cubit ?? context.read<C>();
        _previousState = _converter(_cubit.state);
        _state = _previousState;
      }
      _subscribe();
    } else {
      final state = _converter(_cubit.state);
      if (_previousState != state) {
        _previousState = _state;
        _state = state;
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder?.call(context, _state) ?? widget.child!;

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _cubit.stream.map(_converter).listen((state) {
      if (_previousState == state) return;

      if (widget.when?.call(_previousState, state) ?? true) {
        widget.listener?.call(context, state);
        _state = state;

        if (widget.builder != null) setState(() {});
      }
      _previousState = state;
    });
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription?.cancel();
      _subscription = null;
    }
  }
}
