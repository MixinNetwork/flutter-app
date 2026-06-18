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
    extends DistinctStateNotifier<ResponsiveNavigatorState>
    with ResponsiveNavigatorController {
  AbstractResponsiveNavigatorStateNotifier(super.initialState);

  @override
  ResponsiveNavigatorState get navigatorState => state;

  @override
  set navigatorState(ResponsiveNavigatorState value) => state = value;
}

mixin ResponsiveNavigatorController {
  ResponsiveNavigatorState get navigatorState;

  set navigatorState(ResponsiveNavigatorState value);

  MaterialPage route(String name, Object? arguments);

  void updateRouteMode(bool routeMode) {
    if (navigatorState.routeMode == routeMode) return;
    Future(
      () => navigatorState = navigatorState.copyWith(routeMode: routeMode),
    );
  }

  void onPopPage() {
    if (navigatorState.pages.isNotEmpty) {
      navigatorState = navigatorState.copyWith(
        pages: navigatorState.pages.toList()..removeLast(),
      );
    }
  }

  void pushPage(String name, {Object? arguments}) {
    final page = route(name, arguments);
    final pages = navigatorState.pages.toList();
    final index = pages.indexWhere(
      (element) =>
          page.child.key != null && element.child.key == page.child.key,
    );
    if (pages.isNotEmpty && index == pages.length - 1) return;
    if (index != -1) pages.removeRange(max(index, 0), pages.length);
    navigatorState = navigatorState.copyWith(pages: [...pages, page]);
  }

  void popUntil(bool Function(MaterialPage page) test) {
    final index = navigatorState.pages.indexWhere(test);
    if (index == -1) return;

    final list = index == 0
        ? <MaterialPage>[]
        : navigatorState.pages.sublist(0, index);
    navigatorState = navigatorState.copyWith(pages: list);
  }

  void popWhere(bool Function(MaterialPage page) test) =>
      navigatorState = navigatorState.copyWith(
        pages: navigatorState.pages.toList()..removeWhere(test),
      );

  void pop() => navigatorState = navigatorState.copyWith(
    pages: navigatorState.pages
        .sublist(0, max(navigatorState.pages.length - 1, 0))
        .toList(),
  );

  Future<void> replace(String name, {Object? arguments}) async {
    popWhere((page) => page.name == name);
    await Future.delayed(Duration.zero);
    pushPage(name, arguments: arguments);
  }

  void clear() => navigatorState = navigatorState.copyWith(pages: []);
}
