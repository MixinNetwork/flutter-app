import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout(
      {Key key,
      @required this.largeScreen,
      this.mediumScreen,
      this.smallScreen})
      : super(key: key);

  final Widget largeScreen;
  final Widget mediumScreen;
  final Widget smallScreen;

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width <= 600;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600 &&
        MediaQuery.of(context).size.width < 800;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return largeScreen;
        } else if (constraints.maxWidth < 800 && constraints.maxWidth > 600) {
          return mediumScreen ?? largeScreen;
        } else {
          return smallScreen ?? largeScreen;
        }
      },
    );
  }
}
