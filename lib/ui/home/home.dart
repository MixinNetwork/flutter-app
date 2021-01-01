import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';

import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/home/slide_page.dart';

class HomePage extends StatelessWidget {
  static const slidePageWidth = 200.0;
  static const conversationPageMinWidth = 260.0;
  static const conversationPageDefaultWidth = 300.0;
  static const chatPageMinWidth = 480.0;
  static const chatPageDefaultWidth = 780.0;

  final _conversationPageKey = GlobalKey();
  final _chatPageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double chatPageWidth;
          var conversationPageWidth =
              constraints.maxWidth - slidePageWidth - chatPageMinWidth;
          var hideConversation = false;
          if (conversationPageWidth < conversationPageMinWidth) {
            hideConversation = true;
          }
          if (hideConversation) {
            chatPageWidth = constraints.maxWidth - slidePageWidth;
          } else {
            conversationPageWidth =
                min(conversationPageWidth, conversationPageDefaultWidth);
            chatPageWidth =
                constraints.maxWidth - slidePageWidth - conversationPageWidth;
          }

          final conversationPage = ConversationPage(key: _conversationPageKey);
          return BlocConverter<ConversationCubit, Conversation, bool>(
            converter: (state) => state != null,
            builder: (context, showChatPage) {
              return Row(
                children: [
                  SlidePage(),
                  if (!hideConversation)
                    SizedBox(
                      width: conversationPageWidth,
                      child: conversationPage,
                    ),
                  SizedBox(
                    width: chatPageWidth,
                    child: ClipRect(
                      child: Navigator(
                        transitionDelegate: const DefaultTransitionDelegate(),
                        onPopPage: (Route<dynamic> route, dynamic result) =>
                            true,
                        pages: [
                          if (hideConversation)
                            MaterialPage(
                              key: const Key('conversation'),
                              name: 'conversation',
                              child: conversationPage,
                            ),
                          if (!hideConversation || showChatPage)
                            MaterialPage(
                              key: const Key('chatPage'),
                              name: 'chatPage',
                              child: ChatPage(key: _chatPageKey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
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
