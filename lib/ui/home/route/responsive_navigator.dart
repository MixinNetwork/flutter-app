import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

abstract class AbstractResponsiveNavigatorCubit
    extends Cubit<ResponsiveNavigatorState> {
  AbstractResponsiveNavigatorCubit(ResponsiveNavigatorState initialState)
      : super(initialState);

  void updateNavigationMode(bool navigationMode);

  void onPopPage();
}

class ResponsiveNavigator extends HookWidget {
  const ResponsiveNavigator({
    Key? key,
    required this.leftPage,
    required this.rightEmptyPage,
    required this.switchWidth,
    required this.responsiveNavigatorCubit,
  }) : super(key: key);

  final MaterialPage leftPage;
  final MaterialPage rightEmptyPage;
  final double switchWidth;
  final AbstractResponsiveNavigatorCubit responsiveNavigatorCubit;

  @override
  Widget build(BuildContext context) {
    final responsiveNavigatorState =
        useBlocState(bloc: responsiveNavigatorCubit);
    return LayoutBuilder(builder: (context, boxConstraints) {
      final navigationMode = boxConstraints.maxWidth < switchWidth;
      responsiveNavigatorCubit.updateNavigationMode(navigationMode);
      return Row(
        children: [
          if (!navigationMode) leftPage.child,
          Expanded(
            child: ClipRect(
              child: Navigator(
                transitionDelegate: DefaultTransitionDelegate(
                  routeWithoutAnimation: {
                    leftPage.name,
                    rightEmptyPage.name,
                  },
                ),
                onPopPage: (Route<dynamic> route, dynamic result) {
                  responsiveNavigatorCubit.onPopPage();
                  return route.didPop(result);
                },
                pages: [
                  if (navigationMode) leftPage,
                  if (!navigationMode && responsiveNavigatorState.pages.isEmpty)
                    rightEmptyPage,
                  ...responsiveNavigatorState.pages,
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class DefaultTransitionDelegate<T> extends TransitionDelegate<T> {
  /// Creates a default transition delegate.
  const DefaultTransitionDelegate({
    required this.routeWithoutAnimation,
  }) : super();

  final Set<String?> routeWithoutAnimation;

  @override
  Iterable<RouteTransitionRecord> resolve(
      {required List<RouteTransitionRecord> newPageRouteHistory,
      required Map<RouteTransitionRecord?, RouteTransitionRecord>
          locationToExitingPageRoute,
      required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
          pageRouteToPagelessRoutes}) {
    final results = <RouteTransitionRecord>[];
    // This method will handle the exiting route and its corresponding pageless
    // route at this location. It will also recursively check if there is any
    // other exiting routes above it and handle them accordingly.
    void handleExitingRoute(RouteTransitionRecord? location, bool isLast) {
      final exitingPageRoute = locationToExitingPageRoute[location];
      if (exitingPageRoute == null) return;
      if (exitingPageRoute.isWaitingForExitingDecision) {
        final hasPagelessRoute =
            pageRouteToPagelessRoutes.containsKey(exitingPageRoute);
        final isLastExitingPageRoute =
            isLast && !locationToExitingPageRoute.containsKey(exitingPageRoute);
        if (isLastExitingPageRoute && !hasPagelessRoute) {
          exitingPageRoute.markForPop(exitingPageRoute.route.currentResult);
        } else {
          exitingPageRoute
              .markForComplete(exitingPageRoute.route.currentResult);
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
                pagelessRoute
                    .markForComplete(pagelessRoute.route.currentResult);
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
          locationToExitingPageRoute) {
    final routes = {
      pageRoute,
      ...locationToExitingPageRoute.keys,
      ...locationToExitingPageRoute.values
    }
        .map((e) => e?.route.settings.name)
        .where((element) => element != null)
        .toSet();
    return !setEquals(routeWithoutAnimation, routes);
  }
}
