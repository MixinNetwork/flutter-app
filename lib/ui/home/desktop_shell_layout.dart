import 'package:flutter/widgets.dart';

enum DesktopShellLayoutMode { drawer, compactRail, fullRail }

// chat category list min width
const kSlidePageMinWidth = 64.0;
// chat category and chat list max width
const kSlidePageMaxWidth = 176.0;
// chat page min width, message list, setting page etc.
const kResponsiveNavigationMinWidth = 320.0;
// conversation list fixed width, conversation list, setting list etc.
const kConversationListWidth = 300.0;
// chat side page fixed width, chat info page etc.
const kChatSidePageWidth = 300.0;

class DesktopShellLayout {
  const DesktopShellLayout({
    required this.mode,
    required this.slideWidth,
    required this.availableSlideWidth,
    required this.autoCollapse,
    required this.userCollapse,
  });

  static const mainRouteSwitchWidth =
      kResponsiveNavigationMinWidth + kConversationListWidth;
  static const chatSideRouteSwitchWidth =
      kResponsiveNavigationMinWidth + kChatSidePageWidth;

  final DesktopShellLayoutMode mode;
  final double slideWidth;
  final double availableSlideWidth;
  final bool autoCollapse;
  final bool userCollapse;

  bool get hasDrawer => mode == DesktopShellLayoutMode.drawer;

  bool get collapse =>
      mode == DesktopShellLayoutMode.drawer ||
      mode == DesktopShellLayoutMode.compactRail;

  bool get showCollapseControl => !autoCollapse;

  double get slideMaxWidth =>
      collapse ? kSlidePageMinWidth : availableSlideWidth;

  static DesktopShellLayout resolve({
    required double maxWidth,
    required bool userCollapse,
    required bool isPhone,
  }) {
    final availableSlideWidth = (maxWidth - kResponsiveNavigationMinWidth)
        .clamp(kSlidePageMinWidth, kSlidePageMaxWidth);

    final autoCollapse = availableSlideWidth < kSlidePageMaxWidth;
    final collapse = userCollapse || autoCollapse;
    final hasDrawer = availableSlideWidth <= kSlidePageMinWidth || isPhone;
    final mode = hasDrawer
        ? DesktopShellLayoutMode.drawer
        : collapse
        ? DesktopShellLayoutMode.compactRail
        : DesktopShellLayoutMode.fullRail;

    return DesktopShellLayout(
      mode: mode,
      slideWidth: switch (mode) {
        DesktopShellLayoutMode.drawer => 0,
        DesktopShellLayoutMode.compactRail => kSlidePageMinWidth,
        DesktopShellLayoutMode.fullRail => kSlidePageMaxWidth,
      },
      availableSlideWidth: availableSlideWidth,
      autoCollapse: autoCollapse,
      userCollapse: userCollapse,
    );
  }

  static bool useMainRouteMode(double width) => width < mainRouteSwitchWidth;

  static bool useChatSideRouteMode(double width) =>
      width < chatSideRouteSwitchWidth;

  static int chatSideMediaColumnCount({required bool routeMode}) =>
      routeMode ? 4 : 3;

  static int chatSideMediaPageSize({
    required double maxHeight,
    required bool routeMode,
  }) =>
      (maxHeight / 90 * 2).toInt() *
      chatSideMediaColumnCount(routeMode: routeMode);

  static Widget mainRouteMode({
    required bool routeMode,
    required Widget child,
  }) => _MainRouteMode(routeMode: routeMode, child: child);

  static Widget chatSideRouteMode({
    required bool routeMode,
    required Widget child,
  }) => _ChatSideRouteMode(routeMode: routeMode, child: child);

  static bool mainRouteModeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MainRouteMode>()?.routeMode ??
      false;

  static bool chatSideRouteModeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ChatSideRouteMode>()
          ?.routeMode ??
      false;
}

class _MainRouteMode extends InheritedWidget {
  const _MainRouteMode({
    required this.routeMode,
    required super.child,
  });

  final bool routeMode;

  @override
  bool updateShouldNotify(_MainRouteMode oldWidget) =>
      routeMode != oldWidget.routeMode;
}

class _ChatSideRouteMode extends InheritedWidget {
  const _ChatSideRouteMode({
    required this.routeMode,
    required super.child,
  });

  final bool routeMode;

  @override
  bool updateShouldNotify(_ChatSideRouteMode oldWidget) =>
      routeMode != oldWidget.routeMode;
}
