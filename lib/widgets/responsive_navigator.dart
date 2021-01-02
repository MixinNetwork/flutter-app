import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ResponsiveNavigator extends StatefulWidget {
  const ResponsiveNavigator({
    Key key,
    @required this.leftPage,
    @required this.rightPage,
    @required this.switchWidth,
    @required this.pushPage,
  }) : super(key: key);

  final MaterialPage leftPage;
  final MaterialPage rightPage;
  final double switchWidth;
  final Page Function(String name, Object arguments) pushPage;

  @override
  ResponsiveNavigatorState createState() => ResponsiveNavigatorState();
}

class ResponsiveNavigatorState extends State<ResponsiveNavigator> {
  bool _showRight = false;
  final _pages = <Page>[];

  void showRightPage(bool value, bool force) {
    setState(() {
      _showRight = value;
      if (force) _pages.clear();
    });
  }

  void pushPage(
    String name,
    Object arguments,
  ) =>
      setState(() {
        _pages.add(widget.pushPage(name, arguments));
      });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, boxConstraints) {
      final navigationMode = boxConstraints.maxWidth < widget.switchWidth;
      return Row(
        children: [
          if (!navigationMode) widget.leftPage.child,
          Expanded(
            child: ClipRect(
              child: Navigator(
                transitionDelegate: const DefaultTransitionDelegate(),
                onPopPage: (Route<dynamic> route, dynamic result) {
                  final bool = _pages.isNotEmpty == true;
                  if (bool) setState(_pages.removeLast);
                  return bool;
                },
                pages: [
                  if (navigationMode) widget.leftPage,
                  if (!navigationMode || _showRight) widget.rightPage,
                  ..._pages,
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
  const DefaultTransitionDelegate() : super();

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
            !globalPageRouteChange(
                newPageRouteHistory, locationToExitingPageRoute)) {
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

  bool globalPageRouteChange(
    List<RouteTransitionRecord> newPageRouteHistory,
    Map<RouteTransitionRecord, RouteTransitionRecord>
        locationToExitingPageRoute,
  ) =>
      newPageRouteHistory.length == 1 &&
      locationToExitingPageRoute.length == 1 &&
      [...newPageRouteHistory, ...locationToExitingPageRoute.values].every(
        (element) {
          try {
            return (element.route.settings as dynamic).child.key is GlobalKey;
          } catch (e) {
            return false;
          }
        },
      );
}
