import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ResponsiveNavigator extends StatefulWidget {
  const ResponsiveNavigator({
    Key key,
    @required this.leftPage,
    @required this.rightEmptyPage,
    @required this.switchWidth,
    @required this.pushPage,
  }) : super(key: key);

  final MaterialPage leftPage;
  final MaterialPage rightEmptyPage;
  final double switchWidth;
  final MaterialPage Function(String name, Object arguments) pushPage;

  @override
  ResponsiveNavigatorState createState() => ResponsiveNavigatorState();
}

class ResponsiveNavigatorState extends State<ResponsiveNavigator> {
  final _pages = <MaterialPage>[];
  bool navigationMode;

  void pushPage(String name, {Object arguments}) => setState(() {
        final page = widget.pushPage(name, arguments);
        var index = -1;
        index = _pages.indexWhere(
            (element) => identical(element.child.key, page.child.key));
        if (index != -1) _pages.removeRange(max(index, 0), _pages.length);
        _pages.add(page);
      });

  void popWhere(bool Function(MaterialPage page) test) =>
      setState(() => _pages.removeWhere(test));

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, boxConstraints) {
        navigationMode = boxConstraints.maxWidth < widget.switchWidth;
        return Row(
          children: [
            if (!navigationMode) widget.leftPage.child,
            Expanded(
              child: ClipRect(
                child: Navigator(
                  transitionDelegate: DefaultTransitionDelegate(
                    routeWithoutAnimation: {
                      widget.leftPage.name,
                      widget.rightEmptyPage.name,
                    },
                  ),
                  onPopPage: (Route<dynamic> route, dynamic result) {
                    final bool = _pages.isNotEmpty == true;
                    if (bool) setState(_pages.removeLast);
                    return route.didPop(result);
                  },
                  pages: [
                    if (navigationMode) widget.leftPage,
                    if (!navigationMode && _pages.isEmpty)
                      widget.rightEmptyPage,
                    ..._pages,
                  ],
                ),
              ),
            ),
          ],
        );
      });
}

class DefaultTransitionDelegate<T> extends TransitionDelegate<T> {
  /// Creates a default transition delegate.
  const DefaultTransitionDelegate({this.routeWithoutAnimation}) : super();

  final Set<String> routeWithoutAnimation;

  @override
  Iterable<RouteTransitionRecord> resolve({
    List<RouteTransitionRecord> newPageRouteHistory,
    Map<RouteTransitionRecord, RouteTransitionRecord>
        locationToExitingPageRoute,
    Map<RouteTransitionRecord, List<RouteTransitionRecord>>
        pageRouteToPagelessRoutes,
  }) {
    final results = <RouteTransitionRecord>[];
    // This method will handle the exiting route and its corresponding pageless
    // route at this location. It will also recursively check if there is any
    // other exiting routes above it and handle them accordingly.
    void handleExitingRoute(RouteTransitionRecord location, bool isLast) {
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
          for (final pagelessRoute in pagelessRoutes) {
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
      Map<RouteTransitionRecord, RouteTransitionRecord>
          locationToExitingPageRoute) {
    final routes = {
      pageRoute,
      ...locationToExitingPageRoute.keys,
      ...locationToExitingPageRoute.values
    }
        .map((e) => e?.route?.settings?.name)
        .where((element) => element != null)
        .toSet();
    return !setEquals(routeWithoutAnimation, routes);
  }
}
