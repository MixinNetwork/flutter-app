import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../provider/abstract_responsive_navigator.dart';
import '../../provider/responsive_navigator_provider.dart';

abstract class AbstractResponsiveNavigatorCubit
    extends Cubit<ResponsiveNavigatorState> {
  AbstractResponsiveNavigatorCubit(super.initialState);

  void updateRouteMode(bool routeMode) =>
      emit(state.copyWith(routeMode: routeMode));

  void onPopPage() {
    final bool = state.pages.isNotEmpty;
    if (bool) {
      emit(state.copyWith(pages: state.pages.toList()..removeLast()));
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
    emit(state.copyWith(pages: state.pages.toList()..add(page)));
  }

  void popUntil(bool Function(MaterialPage page) test) {
    final index = state.pages.indexWhere(test);
    if (index == -1) return;

    List<MaterialPage>? list;
    list = index == 0 ? [] : state.pages.toList()
      ..sublist(0, index);
    emit(state.copyWith(pages: list));
  }

  void popWhere(bool Function(MaterialPage page) test) =>
      emit(state.copyWith(pages: state.pages.toList()..removeWhere(test)));

  void pop() => emit(
    state.copyWith(
      pages: state.pages.sublist(0, max(state.pages.length - 1, 0)).toList(),
    ),
  );

  Future<void> replace(String name, {Object? arguments}) async {
    popWhere((page) => page.name == name);
    await Future.delayed(Duration.zero);
    pushPage(name, arguments: arguments);
  }

  void clear() => emit(state.copyWith(pages: []));
}

class ResponsiveNavigator extends HookConsumerWidget {
  const ResponsiveNavigator({
    required this.leftPage,
    required this.rightEmptyPage,
    required this.switchWidth,
    super.key,
  });

  final MaterialPage leftPage;
  final MaterialPage rightEmptyPage;
  final double switchWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsiveNavigatorNotifier = ref.watch(
      responsiveNavigatorProvider.notifier,
    );
    final responsiveNavigatorState = ref.watch(responsiveNavigatorProvider);

    return LayoutBuilder(
      builder: (context, boxConstraints) {
        final routeMode = boxConstraints.maxWidth < switchWidth;
        responsiveNavigatorNotifier.updateRouteMode(routeMode);
        return Row(
          children: [
            if (!routeMode) leftPage.child,
            Expanded(
              child: ClipRect(
                child: Navigator(
                  transitionDelegate: WithoutAnimationDelegate(
                    routeWithoutAnimation: {leftPage.name, rightEmptyPage.name},
                  ),
                  onDidRemovePage: (Page<dynamic> page) {},
                  pages: [
                    if (routeMode) leftPage,
                    if (!routeMode && responsiveNavigatorState.pages.isEmpty)
                      rightEmptyPage,
                    ...responsiveNavigatorState.pages,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class WithoutAnimationDelegate<T> extends TransitionDelegate<T> {
  /// Creates a default transition delegate.
  const WithoutAnimationDelegate({required this.routeWithoutAnimation})
    : super();

  final Set<String?> routeWithoutAnimation;

  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
    locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
    pageRouteToPagelessRoutes,
  }) {
    final results = <RouteTransitionRecord>[];
    // This method will handle the exiting route and its corresponding pageless
    // route at this location. It will also recursively check if there is any
    // other exiting routes above it and handle them accordingly.
    void handleExitingRoute(RouteTransitionRecord? location, bool isLast) {
      final exitingPageRoute = locationToExitingPageRoute[location];
      if (exitingPageRoute == null) return;
      if (exitingPageRoute.isWaitingForExitingDecision) {
        final hasPagelessRoute = pageRouteToPagelessRoutes.containsKey(
          exitingPageRoute,
        );
        final isLastExitingPageRoute =
            isLast && !locationToExitingPageRoute.containsKey(exitingPageRoute);
        if (isLastExitingPageRoute && !hasPagelessRoute) {
          exitingPageRoute.markForPop(exitingPageRoute.route.currentResult);
        } else {
          exitingPageRoute.markForComplete(
            exitingPageRoute.route.currentResult,
          );
        }
        if (hasPagelessRoute) {
          final pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute];
          for (final pagelessRoute in pagelessRoutes!) {
            // It is possible that a pageless route that belongs to an exiting
            // page-based route does not require exiting decision. This can
            // happen if the page list is updated right after a Navigator.pop.
            if (pagelessRoute.isWaitingForExitingDecision) {
              if (isLastExitingPageRoute &&
                  pagelessRoute == pagelessRoutes.last) {
                pagelessRoute.markForPop(pagelessRoute.route.currentResult);
              } else {
                pagelessRoute.markForComplete(
                  pagelessRoute.route.currentResult,
                );
              }
            }
          }
        }
      }
      results.add(exitingPageRoute);

      // It is possible there is another exiting route above this exitingPageRoute.
      handleExitingRoute(exitingPageRoute, isLast);
    }

    // Handles exiting route in the beginning of list.
    handleExitingRoute(null, newPageRouteHistory.isEmpty);

    for (final pageRoute in newPageRouteHistory) {
      final isLastIteration = newPageRouteHistory.last == pageRoute;
      if (pageRoute.isWaitingForEnteringDecision) {
        if (!locationToExitingPageRoute.containsKey(pageRoute) &&
            isLastIteration &&
            showAnimation(pageRoute, locationToExitingPageRoute)) {
          pageRoute.markForPush();
        } else {
          pageRoute.markForAdd();
        }
      }
      results.add(pageRoute);
      handleExitingRoute(pageRoute, isLastIteration);
    }
    return results;
  }

  bool showAnimation(
    RouteTransitionRecord pageRoute,
    Map<RouteTransitionRecord?, RouteTransitionRecord>
    locationToExitingPageRoute,
  ) {
    final routes =
        {
              pageRoute,
              ...locationToExitingPageRoute.keys,
              ...locationToExitingPageRoute.values,
            }
            .map((e) => e?.route.settings.name)
            .where((element) => element != null)
            .toSet();
    return !setEquals(routeWithoutAnimation, routes);
  }
}
