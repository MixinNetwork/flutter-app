import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocConverter<C extends Cubit<S>, S, T>
    extends BlocConverterBase<C, S, T> {
  const BlocConverter({
    Key key,
    C cubit,
    BlocBuilderCondition<T> buildWhen,
    @required BlocConverterCondition<S, T> converter,
    @required this.builder,
  })  : assert(converter != null),
        assert(builder != null),
        super(
        key: key,
        cubit: cubit,
        buildWhen: buildWhen,
        converter: converter,
      );

  final BlocWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context, T state) => builder(context, state);
}

typedef BlocConverterCondition<S, T> = T Function(S state);

abstract class BlocConverterBase<C extends Cubit<S>, S, T>
    extends StatefulWidget {
  const BlocConverterBase({
    Key key,
    this.cubit,
    this.buildWhen,
    @required this.converter,
  })  : assert(converter != null),
        super(key: key);

  final C cubit;

  final BlocBuilderCondition<T> buildWhen;

  final BlocConverterCondition<S, T> converter;

  Widget build(BuildContext context, T state);

  @override
  State<BlocConverterBase<C, S, T>> createState() =>
      _BlocBuilderBaseState<C, S, T>();
}

class _BlocBuilderBaseState<C extends Cubit<S>, S, T>
    extends State<BlocConverterBase<C, S, T>> {
  StreamSubscription<T> _subscription;
  T _previousState;
  T _state;
  C _cubit;

  T _converter(S state) {
    try {
      return widget.converter(state);
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? context.read<C>();
    _previousState = _converter(_cubit?.state);
    _state = _previousState;
    _subscribe();
  }

  @override
  void didUpdateWidget(BlocConverterBase<C, S, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCubit = oldWidget.cubit ?? context.read<C>();
    final currentBloc = widget.cubit ?? oldCubit;
    if (oldCubit != currentBloc) {
      if (_subscription != null) {
        _unsubscribe();
        _cubit = widget.cubit ?? context.read<C>();
        _previousState = _converter(_cubit?.state);
        _state = _previousState;
      }
      _subscribe();
    } else {
      final state = _converter(_cubit?.state);
      if (_previousState != state) {
        _previousState = _state;
        _state = state;
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _state);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (_cubit != null) {
      _subscription = _cubit.map(_converter).listen((state) {
        if (_previousState == state) return;

        if (widget.buildWhen?.call(_previousState, state) ?? true) {
          setState(() {
            _state = state;
          });
        }
        _previousState = state;
      });
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }
}
