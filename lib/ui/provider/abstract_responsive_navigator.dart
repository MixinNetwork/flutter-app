import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../utils/rivepod.dart';

class ResponsiveNavigatorState extends Equatable {
  const ResponsiveNavigatorState({
    this.pages = const [],
    this.routeMode = false,
  });

  final List<MaterialPage> pages;
  final bool routeMode;

  @override
  List<Object?> get props => [
    routeMode,
    ...pages.map((e) => (e.key, e.name, e.arguments, e.child.key)),
  ];

  ResponsiveNavigatorState copyWith({
    List<MaterialPage>? pages,
    bool? routeMode,
  }) => ResponsiveNavigatorState(
    pages: pages ?? this.pages,
    routeMode: routeMode ?? this.routeMode,
  );
}

abstract class AbstractResponsiveNavigatorStateNotifier
    extends DistinctStateNotifier<ResponsiveNavigatorState> {
  AbstractResponsiveNavigatorStateNotifier(super.initialState);

  void updateRouteMode(bool routeMode) =>
      Future(() => state = state.copyWith(routeMode: routeMode));

  void onPopPage() {
    final bool = state.pages.isNotEmpty;
    if (bool) {
      state = state.copyWith(pages: state.pages.toList()..removeLast());
    }
  }

  MaterialPage route(String name, Object? arguments);

  void pushPage(String name, {Object? arguments}) {
    final page = route(name, arguments);
    var index = -1;
    index = state.pages.indexWhere(
      (element) =>
          page.child.key != null && element.child.key == page.child.key,
    );
    if (state.pages.isNotEmpty && index == state.pages.length - 1) return;
    if (index != -1) state.pages.removeRange(max(index, 0), state.pages.length);
    state = state.copyWith(pages: state.pages.toList()..add(page));
  }

  void popUntil(bool Function(MaterialPage page) test) {
    final index = state.pages.indexWhere(test);
    if (index == -1) return;

    List<MaterialPage>? list;
    list =
        index == 0 ? [] : state.pages.toList()
          ..sublist(0, index);
    state = state.copyWith(pages: list);
  }

  void popWhere(bool Function(MaterialPage page) test) =>
      state = state.copyWith(pages: state.pages.toList()..removeWhere(test));

  void pop() =>
      state = state.copyWith(
        pages: state.pages.sublist(0, max(state.pages.length - 1, 0)).toList(),
      );

  Future<void> replace(String name, {Object? arguments}) async {
    popWhere((page) => page.name == name);
    await Future.delayed(Duration.zero);
    pushPage(name, arguments: arguments);
  }

  void clear() => state = state.copyWith(pages: []);
}
